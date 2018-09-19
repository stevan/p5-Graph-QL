package Graph::QL::Execution::Context;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema     => sub {},
    operation  => sub {}, # Graph::QL::Core::Operation
    root_value => sub { +{} },
    variables  => sub { +{} },
    # internals ...
    _errors    => sub { +[] },

    # TODO:
    # contextValue: mixed,
    # fieldResolver: GraphQLFieldResolver<any, any>,
);

sub BUILDARGS : strict(
    schema      => schema,
    operation   => operation,
    root_value? => root_value,
    variables?  => variables
);

sub BUILD ($self, $params) {

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
