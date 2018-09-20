package Graph::QL::Util::Assertions;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Ref::Util ();

our $VERSION = '0.01';

our @EXPORT_OK; BEGIN {
    @EXPORT_OK = (
        'assert_isa',
        'assert_does',
        'assert_arrayref',
        'assert_hashref',
        'assert_non_empty',
    );
}

# ...

sub import      ($class, @args) { $class->import_into( scalar caller, @args ) }
sub import_into ($class, $into, @exports) {
    state $ok_to_export = +{ map { $_ => 1 } @EXPORT_OK };

    if ( scalar @exports == 1 && $exports[0] eq ':all' ) {
        @exports = @EXPORT_OK;
    }

    $ok_to_export->{ $_ } or throw('The symbol (%s), it is not exported by this module', $_)
        foreach @exports;
    no strict 'refs';
    *{$into.'::'.$_} = \&{$_} foreach @exports;
}

# ...

sub assert_isa  ($o, $c) { Ref::Util::is_blessed_ref($o) && $o->isa( $c ) }
sub assert_does ($o, $r) { Ref::Util::is_blessed_ref($o) && $o->roles::DOES( $r ) }

sub assert_arrayref ($a) { Ref::Util::is_arrayref( $a ) }
sub assert_hashref  ($h) { Ref::Util::is_hashref( $h )  }

sub assert_non_empty ($t) {
    return !! keys   $t->%* if Ref::Util::is_hashref( $t );
    return !! scalar $t->@* if Ref::Util::is_arrayref( $t );
    return;
}

1;

__END__

=pod

=cut
