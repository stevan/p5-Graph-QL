package Graph::QL::Core::TypeSystemDirectiveLocation;
# ABSTRACT: Enumeration for the TypeSystemDirectiveLocation
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

# create the Enum so we can introspect it ...
our %TYPE_SYSTEM_DIRECTIVE_LOCATION; BEGIN {
    %TYPE_SYSTEM_DIRECTIVE_LOCATION = map { $_ => $_ } qw(
        SCHEMA
        SCALAR
        OBJECT
        FIELD_DEFINITION
        ARGUMENT_DEFINITION
        INTERFACE
        UNION
        ENUM
        ENUM_VALUE
        INPUT_OBJECT
        INPUT_FIELD_DEFINITION
    );

    use constant ();
    foreach my $location ( keys %TYPE_SYSTEM_DIRECTIVE_LOCATION ) {
        constant->import( $location, $TYPE_SYSTEM_DIRECTIVE_LOCATION{ $location } )
    }
}

sub type_system_directive_locations ($) { sort values %TYPE_SYSTEM_DIRECTIVE_LOCATION }

sub is_type_system_directive_location ($, $location) { !! exists $TYPE_SYSTEM_DIRECTIVE_LOCATION{ uc $location } }

1;

__END__

=pod

=cut
