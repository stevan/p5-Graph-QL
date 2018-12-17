package Graph::QL::Util::AST::Literals;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';
use Graph::QL::Util::JSON;

our $VERSION = '0.01';

# ...

sub validate_json_boolean ($v) {
    return unless defined $v;
    return Scalar::Util::blessed( $v )
        && $v->isa('JSON::PP::Boolean');
}

sub validate_perl_boolean ($v) {
    return unless defined $v;
    return if ref $v;
    return $v eq '' || $v =~ /^1$/ || $v =~ /^0$/;
}

sub validate_boolean ($v) {
    return unless defined $v;
    return ref $v 
        ? validate_json_boolean( $v )
        : validate_perl_boolean( $v );
}

sub validate_string ($v) {
    return defined $v && not ref $v ;
}

sub validate_int ($v) {
    return unless defined $v;
    return if ref $v;
    return $v =~ /\d+/;
}

sub validate_float ($v) {
    return unless defined $v;
    return if ref $v;
    return $v =~ /\d+\.\d+/;
}

sub validate_list ($v) {
    return unless defined $v;
    return ref $v eq 'ARRAY';
}

sub validate_object ($v) {
    return unless defined $v;
    return ref $v eq 'HASH';
}

# ...

sub parse_boolean ($v) {
    throw('Unable to parse boolean value from undefined value')
        unless defined $v;
    throw('Unable to parse boolean value from (%s)', $v)
        unless validate_boolean( $v );
    return $v ? 1 : 0;
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
