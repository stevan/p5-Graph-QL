package Graph::QL::Web;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':constructor';

use Plack::Request;

use Graph::QL::Operation;
use Graph::QL::Introspection;
use Graph::QL::Execution::ExecuteQuery;

use Graph::QL::Util::JSON;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable',
           'Plack::Component';
use slots (
    _schema    => sub {},
    _resolvers => sub {},
);

sub BUILDARGS : strict(
    schema    => _schema,
    resolvers => _resolvers,
);

sub BUILD ($self, $) {

    # TODO:
    # type check the schema and resolvers

    # NOTE:
    # make sure to enable introspection features
    # but this will need to change when we fix the
    # Introspection system
    # - SL
    $self->{_schema}    = Graph::QL::Introspection->enable_for_schema( $self->{_schema} );
    $self->{_resolvers} = Graph::QL::Introspection->enable_for_resolvers( $self->{_resolvers} );
}

sub call ($self, $env) {
    my $r = Plack::Request->new( $env );

    my $query = $r->param('query');

    if ( not $query ) {
        $query = Graph::QL::Util::JSON::decode( $r->content )->{query};
    }

    my $operation = Graph::QL::Operation->new_from_source( $query );

    my $e = Graph::QL::Execution::ExecuteQuery->new(
        schema    => $self->{_schema},
        resolvers => $self->{_resolvers},
        operation => $operation,
    );

    $e->validate;
    if ( $e->has_errors ) {
        return [ 500, [], [ Graph::QL::Util::JSON::encode( { errors => [ $e->get_errors ] } ) ]];
    }
    else {
        my $result = $e->execute;
        return [ 200, [], [ Graph::QL::Util::JSON::encode( { data => $result } ) ]]
    }
}

1;

__END__

=pod

=cut
