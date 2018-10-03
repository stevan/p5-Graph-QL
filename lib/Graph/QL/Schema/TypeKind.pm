package Graph::QL::Schema::TypeKind;
# ABSTRACT: Enumeration for the TypeKind for Schemas
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

# create the Enum so we can introspect it ...
our %TYPE_KINDS; BEGIN {
    %TYPE_KINDS = (
        SCALAR       => 'SCALAR',
        OBJECT       => 'OBJECT',
        INTERFACE    => 'INTERFACE',
        UNION        => 'UNION',
        ENUM         => 'ENUM',
        INPUT_OBJECT => 'INPUT_OBJECT',
        LIST         => 'LIST',
        NON_NULL     => 'NON_NULL',
    );

    use constant ();
    foreach my $kind ( keys %TYPE_KINDS ) {
        constant->import( $kind, $TYPE_KINDS{ $kind } )
    }
}

sub type_kinds ($) { sort values %TYPE_KINDS }

sub is_type_kind ($, $kind) { !! exists $TYPE_KINDS{ uc $kind } }

sub get_type_kind_for_schema_type ($, $schema_type) {
    if ( $schema_type->isa('Graph::QL::Schema::Scalar') ) {
        return SCALAR;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::Object') ) {
        return OBJECT;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::Interface') ) {
        return INTERFACE;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::Union') ) {
        return UNION;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::Enum') ) {
        return ENUM;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::InputObject') ) {
        return INPUT_OBJECT;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::Type::List') ) {
        return LIST;
    }
    elsif ( $schema_type->isa('Graph::QL::Schema::Type::NonNull') ) {
        return NON_NULL;
    }
}

1;

__END__

=pod

=cut
