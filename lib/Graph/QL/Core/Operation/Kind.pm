package Graph::QL::Core::Operation::Kind;
# ABSTRACT: Enumeration for the OperationKind
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

# create the Enum so we can introspect it ...
our %OPERATION_KINDS; BEGIN {
    %OPERATION_KINDS = (
        QUERY        => 'query',
        MUTATION     => 'mutation',
        SUBSCRIPTION => 'subscription',
    );

    use constant ();
    foreach my $kind ( keys %OPERATION_KINDS ) {
        constant->import( $kind, $OPERATION_KINDS{ $kind } )
    }
}

sub is_operation_kind ($class, $kind) { !! exists $OPERATION_KINDS{ uc $kind } }

1;

__END__

=pod

=cut
