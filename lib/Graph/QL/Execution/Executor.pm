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
    schema    => sub {}, # Graph::QL::Schema
    resolvers => sub { +{} }, # a mapping of TypeName to Resolver instance
    # internals ...
    _errors   => sub { +[] },
);

sub BUILDARGS : strict(
    schema     => schema,
    resolvers? => resolvers,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

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

sub has_errors ($self) { !! scalar $self->{_errors}->@* }
sub get_errors ($self) {           $self->{_errors}->@* }

sub execute ($self, $operation) {

    $self->validate_operation( $operation );

    # What do we do when we have an error?

    # TODO:
    # the rest ...
}

sub validate_operation ($self, $operation) {

    throw('The `operation` must be of an instance that does the `Graph::QL::Operation` role, not `%s`', $operation)
        unless assert_does( $operation, 'Graph::QL::Operation' );

    my $v = Graph::QL::Validation::QueryValidator->new(
        schema    => $self->{schema},
        operation => $operation,
    );

    # if the validation fails ...
    if ( not $v->validate ) {
        $self->_add_error('The `operation` did not pass validation.');
        $self->_add_error( $_ ) foreach $v->get_errors; # tranfer errors ...
    }

    return $v;
}

## ...

sub _add_error ($self, $msg, @args) {
    $msg = sprintf $msg => @args if @args;
    push $self->{_errors}->@* => $msg;
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
