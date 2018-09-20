package Graph::QL::Execution::ExecuteQuery;
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
    schema    => sub {}, # Graph::QL::Schema
    query     => sub {}, # Graph::QL::Operation::Query
    resolvers => sub { +{} }, # a mapping of TypeName to Resolver instance
    # internals ...
    _data     => sub { +{} },
    _errors   => sub { +[] },
);

sub BUILDARGS : strict(
    schema     => schema,
    query      => query,
    resolvers? => resolvers,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

    throw('The `query` must be of an instance that does the `Graph::QL::Operation` role, not `%s`', $self->{query})
        unless assert_isa( $self->{query}, 'Graph::QL::Operation::Query' );

    # TODO:
    # - handle `initial-value`
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
sub query  : ro;

sub has_errors ($self) { !! scalar $self->{_errors}->@* }
sub get_errors ($self) {           $self->{_errors}->@* }

sub has_data ($self) { !! scalar keys $self->{_data}->%* }
sub get_data ($self) {                $self->{_data}->%* }

## ...

sub execute ($self) {

    # this will validate that the query supplied
    # can be executed by the schema supplied
    my $v = Graph::QL::Validation::QueryValidator->new(
        schema => $self->{schema},
        query  => $self->{query},
    );

    # if the validation fails ...
    if ( $v->has_errors ) {
        $self->_absorb_errors( 'The `operation` did not pass validation.' => $v );
        # What do we do when we have an error?
    }

    # TODO:
    # the rest ...
}

## ...

sub _add_error ($self, $msg, @args) {
    $msg = sprintf $msg => @args if @args;
    push $self->{_errors}->@* => $msg;
    return;
}

sub _absorb_errors ($self, $msgs, $e) {
    push $self->{_errors}->@* => $msgs, $e->get_errors;
    return;
}

sub _add_data_key ($self, $key, $value) {
    $self->{_data}->{ $key } = $value;
    return;
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
