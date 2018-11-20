package Graph::QL::Util::Literals;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';
use Graph::QL::Util::JSON;

our $VERSION = '0.01';

our @EXPORT_OK; BEGIN {
    @EXPORT_OK = (
        'validate_boolean',
        'validate_string',
        'validate_int',
        'validate_float',
        'parse_boolean',
        'parse_string',
        'parse_int',
        'parse_float',
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

sub validate_boolean ($v) {
    return unless defined $v;
    return $v == Graph::QL::Util::JSON::TRUE
        || $v == Graph::QL::Util::JSON::FALSE;
}

sub validate_string ($v) {
    return defined $v;
}

sub validate_int ($v) {
    return unless defined $v;
    return $v =~ /\d+/;
}

sub validate_float ($v) {
    return unless defined $v;
    return $v =~ /\d+\.\d+/;
}

# ...

sub parse_boolean ($v) {
    throw('Unable to parse boolean value from undefined value')
        unless defined $v;
    throw('Unable to parse boolean value from (%s)', $v)
        unless validate_boolean( $v );
    return $v == Graph::QL::Util::JSON::TRUE ? 1 : 0;
}

sub parse_string ($v) {
    throw('Unable to parse string value from undefined value')
        unless validate_string( $v );
    return $v;
}

sub parse_int ($v) {
    throw('Unable to parse int value from undefined value')
        unless defined $v;
    throw('Unable to parse int value from (%s)', $v)
        unless validate_int( $v );
    return $v+0;
}

sub parse_float ($v) {
    throw('Unable to parse float value from undefined value')
        unless defined $v;
    throw('Unable to parse float value from (%s)', $v)
        unless validate_float( $v );
    return $v+0.0;
}

1;

__END__

=pod

=cut
