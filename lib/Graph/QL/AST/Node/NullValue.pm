package Graph::QL::AST::Node::NullValue;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';


1;

__END__

=pod

=cut
