package Graph::QL::Execution::Executor;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

use Graph::QL::Validation::QueryValidator;

use constant DEBUG => $ENV{GRAPHQL_EXECUTOR_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema     => sub {}, # Graph::QL::Schema
    # optionals ...
    root_value => sub { +{} }, # root object for execution result
    resolvers  => sub { +{} }, # a mapping of TypeName to Resolver instance
    # internals ...
);

sub BUILDARGS : strict(
    schema      => schema,
    root_value? => root_value,
    resolvers?  => resolvers,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

    if ( exists $params->{root_value} ) {
        throw('The `root_value` must be a HASH ref, not `%s`', $self->{root_value})
            unless assert_hashref( $self->{root_value} );
    }

    # TODO:
    # - handle `variables`
    # - handle `context-value`

    if ( exists $params->{resolvers} ) {
        throw('The `resolvers` must be a HASH ref, not `%s`', $self->{resolvers})
            unless assert_non_empty( $self->{resolvers} );

        foreach ( values $self->{resolvers}->%* ) {
             throw('The values in `resolvers` must all be of type(Graph::QL::Execution::FieldResolver), not `%s`', $_ )
                unless assert_isa( $_, 'Graph::QL::Execution::FieldResolver' );
        }
    }
}

sub schema : ro;

sub execute ($self, $operation) {

    $self->validate_operation( $operation );

    # TODO:
    # the rest ...
}

sub validate_operation ($self, $operation) {

    throw('The `operation` must be of an instance that does the `Graph::QL::Operation` role, not `%s`', $operation)
        unless assert_does( $operation, 'Graph::QL::Operation' );

    my $v = Graph::QL::Validation::QueryValidator->new( schema => $self->{schema} );

    $v->validate( $operation ) or throw(
        'The `operation` did not pass validation, got the following errors:'."\n    %s",
        join "\n    " => $v->get_errors
    );
}


1;

__END__

=pod

=head1 DESCRIPTION

This object contains the data that must be available at all points
during query execution.

Namely, schema of the type system that is currently executing, and
the fragments defined in the query document.

=cut
