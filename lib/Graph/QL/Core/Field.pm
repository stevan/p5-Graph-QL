package Graph::QL::Core::Field;
# ABSTRACT: Enumeration for the OperationKind
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

sub name;
sub arity;
sub has_args;
sub args;

1;

__END__

=pod

=cut
