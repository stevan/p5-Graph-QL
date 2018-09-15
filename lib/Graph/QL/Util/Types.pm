package Graph::QL::Util::Types;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

# Literal types ...

use constant BOOLEAN => 'Boolean';
use constant FLOAT   => 'Float';
use constant INT     => 'Int';
use constant STRING  => 'String';

1;

__END__

=pod

=cut

