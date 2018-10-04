package Graph::QL::Core::OperationKind;
# ABSTRACT: Enumeration for the OperationKind
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

# create the Enum so we can introspect it ...
our %OPERATION_KINDS; BEGIN {
    %OPERATION_KINDS = map { $_ => lc($_) } qw[
        QUERY
        MUTATION
        SUBSCRIPTION
    ];

    use constant ();
    foreach my $kind ( keys %OPERATION_KINDS ) {
        constant->import( $kind, $OPERATION_KINDS{ $kind } )
    }
}

sub operation_kinds ($) { sort values %OPERATION_KINDS }

sub is_operation_kind ($, $kind) { !! exists $OPERATION_KINDS{ uc $kind } }

1;

__END__

=pod

=cut
