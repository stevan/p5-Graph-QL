package Graph::QL::Core::ExecutableDirectiveLocation;
# ABSTRACT: Enumeration for the ExecutableDirectiveLocation
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

# create the Enum so we can introspect it ...
our %EXECUTABLE_DIRECTIVE_LOCATION; BEGIN {
    %EXECUTABLE_DIRECTIVE_LOCATION = map { $_ => $_ } qw(
        QUERY
        MUTATION
        SUBSCRIPTION
        FIELD
        FRAGMENT_DEFINITION
        FRAGMENT_SPREAD
        INLINE_FRAGMENT
    );

    use constant ();
    foreach my $location ( keys %EXECUTABLE_DIRECTIVE_LOCATION ) {
        constant->import( $location, $EXECUTABLE_DIRECTIVE_LOCATION{ $location } )
    }
}

sub executable_directive_locations ($) { sort values %EXECUTABLE_DIRECTIVE_LOCATION }

sub is_executable_directive_location ($, $location) { !! exists $EXECUTABLE_DIRECTIVE_LOCATION{ uc $location } }

1;

__END__

=pod

=cut
