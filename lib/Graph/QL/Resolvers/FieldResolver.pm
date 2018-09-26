package Graph::QL::Resolvers::FieldResolver;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name => sub {},
    code => sub {},
);

sub name : ro;

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
