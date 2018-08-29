package Graph::QL::Resolver;

use v5.24;
use warnings;
use experimental 'signatures';
use decorators ':accessors';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    body => sub { die 'You must supply at `body`' },
);

sub body : ro;

1;

__END__

=pod

=cut
