package Graph::QL::Introspection::Resolvers::__Type;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Schema::TypeKind;

our $VERSION = '0.01';

sub kind ($type, $, $, $info) {
    if ( $type->isa('Graph::QL::Schema::Type::Named') ) {
        $type = $info->{schema}->lookup_type( $type->name );

        return unless $type;
    }

    return Graph::QL::Schema::TypeKind->get_type_kind_for_schema_type( $type )
}

sub name        ($type, $, $, $) { $type->name }
sub description ($type, $, $, $) { return } # TODO

sub interfaces ($type, $, $, $) {
    return unless $type->can('interfaces');
    return $type->interfaces;
}

sub possibleTypes ($type, $, $, $) { return } # TODO
sub inputFields   ($type, $, $, $) { return } # TODO

sub ofType ($type, $, $, $) {
    return unless $type->can('of_type');
    return $type->of_type;
}

sub fields ($type, $args, $, $) {
    return unless $type->can('all_fields');
    # ignore the includeDeprecated arg for now ...
    return $type->all_fields;
}

sub enumValues ($type, $args, $, $) {
    return unless $type->isa('Graph::QL::Schema::Enum');
    # ignore the includeDeprecated arg for now ...
    return $type->values;
}

1;

__END__

=pod

type __Type {
    kind          : __TypeKind!
    name          : String
    description   : String
    interfaces    : [__Type!]
    possibleTypes : [__Type!]
    inputFields   : [__InputValue!]
    ofType        : __Type
    fields     (includeDeprecated : Boolean = false) : [__Field!]
    enumValues (includeDeprecated : Boolean = false) : [__EnumValue!]
}

=cut
