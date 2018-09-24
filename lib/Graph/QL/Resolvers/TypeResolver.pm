package Graph::QL::Resolvers::TypeResolver;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name   => sub {},
    fields => sub {},
);

sub name : ro;

sub get_field ($self, $name) {
    (grep $_->name eq $name, $self->{fields}->@*)[0]
}

1;

__END__

=pod

=cut
