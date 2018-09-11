package Graph::QL::AST::Util;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use String::CamelCase ();

our $VERSION = '0.01';

sub camel_to_snake ($string) {
    join '_' => map lc, String::CamelCase::wordsplit( $string )
}

sub snake_to_camel ($string) {
    my ($first, @rest) = String::CamelCase::wordsplit( $string );
    join '' => $first, map ucfirst, @rest;
}

1;

__END__

=pod

=cut



