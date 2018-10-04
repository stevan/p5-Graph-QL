package Graph::QL::Core::ScalarType;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

## scalar types

our %SCALAR_TYPES; BEGIN {
    %SCALAR_TYPES = map { uc($_) => $_ } qw[
        Boolean
        Float
        Int
        String
        ID
    ];

    use constant ();
    foreach my $type ( keys %SCALAR_TYPES ) {
        constant->import( $type, $SCALAR_TYPES{ $type } )
    }
}

sub scalar_types ($) { sort values %SCALAR_TYPES }

sub is_scalar_type ($, $type) { !! exists $SCALAR_TYPES{ uc $type } }

1;

__END__

=pod

=cut

