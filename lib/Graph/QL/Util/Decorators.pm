package Graph::QL::Util::Decorators;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use decorators ':for_providers';

our $VERSION = '0.01';

sub Field     : Decorator : TagMethod {}
sub Arguments : Decorator : TagMethod {}

1;

__END__

=pod

=cut

