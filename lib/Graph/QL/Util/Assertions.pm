package Graph::QL::Util::Assertions;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Ref::Util                 ();
use Graph::QL::Util::Literals ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

our @EXPORT_OK; BEGIN {
    @EXPORT_OK = (
        # General checks ...
        'assert_isa',
        'assert_does',
        'assert_arrayref',
        'assert_hashref',
        'assert_coderef',
        'assert_non_empty',
        # check GraphQL stuff ...
        'assert_type_language_literal',
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
sub assert_coderef  ($c) { Ref::Util::is_coderef( $c )  }

sub assert_non_empty ($t) {
    return !! keys   $t->%* if Ref::Util::is_hashref( $t );
    return !! scalar $t->@* if Ref::Util::is_arrayref( $t );
    return;
}

sub assert_type_language_literal ($o, $t) {
    return Graph::QL::Util::Literals::validate_string( $o )  if $t eq 'string';
    return Graph::QL::Util::Literals::validate_boolean( $o ) if $t eq 'boolean';
    return Graph::QL::Util::Literals::validate_int( $o )     if $t eq 'int';
    return Graph::QL::Util::Literals::validate_float( $o )   if $t eq 'float';
    die 'Do not recognize type('.$t.')';
}

1;

__END__

=pod

=cut
