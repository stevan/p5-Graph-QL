package Graph::QL::Resolvers::TypeResolver;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

use constant DEBUG => $ENV{GRAPHQL_RESOLVERS_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name   => sub {},
    fields => sub {},
);

## ...

sub BUILDARGS : strict(
	name   => name,
	fields => fields,
);

sub BUILD ($self, $) {

	throw('You must pass a defined value to `name`')
        unless defined $self->{name};

    throw('The `fields` value must be an ARRAY ref')
        unless assert_arrayref( $self->{fields} );

    foreach ( $self->{fields}->@* ) {
        throw('The fields in `fields` must all be of type(Graph::QL::Resolvers::FieldResolver), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::Resolvers::FieldResolver');
    }
}

## ...

sub name : ro;

sub get_field ($self, $name) {
    (grep $_->name eq $name, $self->{fields}->@*)[0] // undef
}

1;

__END__

=pod

=cut
