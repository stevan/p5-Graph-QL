package Graph::QL::Resolvers::FieldResolver;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_coderef';

use constant DEBUG => $ENV{GRAPHQL_RESOLVERS_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name => sub {},
    code => sub {},
);

## ...

sub BUILDARGS : strict(
	name => name,
	code => code,
);

sub BUILD ($self, $) {

	throw('You must pass a defined value to `name`')
        unless defined $self->{name};

	throw('The `code` value must be an CODE ref')
        unless assert_coderef( $self->{code} );

}

## ...

sub name : ro;
sub code : ro;

sub resolve ($self, $source, $args, $context, $info) {
    # source  => any source data, either it is root_value (from Context) or a decendant
    # args    => arguments in case the field takes them
    # context => the context (from Context), usually a hash-ref with callbacks
    # info    => information about the field (name, parent_type, schema, etc.)
    return $self->{code}->( $source, $args, $context, $info );
}

1;

__END__

=pod

=cut
