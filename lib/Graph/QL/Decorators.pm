package Graph::QL::Decorators;

use v5.24;
use warnings;
use experimental 'signatures';

our $VERSION = '0.01';

use decorators ':for_providers';

sub Type : Decorator TagMethod {
    my ($meta, $method, $type) = @_;
    # ...
}

1;

__END__

=pod

=cut
