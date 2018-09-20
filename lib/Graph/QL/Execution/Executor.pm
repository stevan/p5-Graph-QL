package Graph::QL::Execution::Executor;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

use Graph::QL::Validation::QueryValidator;

use constant DEBUG => $ENV{GRAPHQL_EXECUTOR_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema     => sub {}, # Graph::QL::Schema
    operation  => sub {}, # Graph::QL::Operation
    root_value => sub { +{} }, # root object for execution result
    variables  => sub { +{} }, # any variables passed to execution
    resolvers  => sub { +{} }, # a mapping of TypeName to Resolver instance
    # internals ...
    _context   => sub { +{} }, # the context arg (3rd) to any resolver funtions
    _errors    => sub { +[] }, # a place for errors to accumulate
);

sub BUILDARGS : strict(
    schema      => schema,
    operation   => operation,
    root_value? => root_value,
    variables?  => variables,
    resovlers?  => resolvers,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless Ref::Util::is_blessed_ref( $self->{schema} )
            && $self->{schema}->isa('Graph::QL::Schema');

    throw('The `schema` must be of an instance that does the `Graph::QL::Operation` role, not `%s`', $self->{operation})
        unless Ref::Util::is_blessed_ref( $self->{operation} )
            && $self->{operation}->roles::DOES('Graph::QL::Operation');

    if ( exists $params->{root_value} ) {
        throw('The `root_value` must be a HASH ref, not `%s`', $self->{root_value})
            unless Ref::Util::is_hashref( $self->{root_value} );
    }

    if ( exists $params->{variables} ) {
        throw('The `variables` must be a HASH ref, not `%s`', $self->{variables})
            unless Ref::Util::is_hashref( $self->{variables} );
    }

    if ( exists $params->{resolvers} ) {
        throw('The `resolvers` must be a HASH ref, not `%s`', $self->{resolvers})
            unless Ref::Util::is_hashref( $self->{resolvers} );

        foreach ( values $self->{resolvers}->%* ) {
             throw('The values in `resolvers` must all be of type(Graph::QL::Execution::FieldResovler), not `%s`', $_ )
                unless Ref::Util::is_blessed_ref( $_ )
                    && $_->isa('Graph::QL::Execution::FieldResovler');
        }
    }
}

sub schema    : ro;
sub operation : ro;
sub validate ($self) {
    Graph::QL::Validation::QueryValidator->new(
        schema => $self->{schema},
    )->validate( $self->{operation} );
}

sub root_value : ro;
sub variables  : ro;

1;

__END__

=pod

=head1 DESCRIPTION

This object contains the data that must be available at all points
during query execution.

Namely, schema of the type system that is currently executing, and
the fragments defined in the query document.

=cut
