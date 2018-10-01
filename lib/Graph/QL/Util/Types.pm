package Graph::QL::Util::Types;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

## base types ...

use constant OBJECT  => 'Object';
use constant ENUM    => 'Enum';
use constant BOOLEAN => 'Boolean';
use constant FLOAT   => 'Float';
use constant INT     => 'Int';
use constant STRING  => 'String';
use constant NULL    => 'Null';

1;

__END__

=pod

=cut

