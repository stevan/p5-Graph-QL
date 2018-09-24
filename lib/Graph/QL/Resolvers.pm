package Graph::QL::Resolvers;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( types => sub {} );

sub get_type ($self, $name) {
    (grep $_->name eq $name, $self->{types}->@*)[0]
}

1;

__END__

=pod

=cut
