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
    }

    Graph::QL::Schema::TypeKind->get_type_kind_for_schema_type( $type )
}

sub name ($type, $, $, $) { $type->name }

sub fields ($type, $args, $, $) {
    # ignore the includeDeprecated arg for now ...
    if ( $type->can('all_fields') ) {
        return $type->all_fields;
    }
    else {
        return [];
    }
}

sub enumValues ($type, $args, $, $) {
    # ignore the includeDeprecated arg for now ...
    if ( $type->isa('Graph::QL::Schema::Enum') ) {
        return $type->values;
    }
    else {
        return [];
    }
}

1;

__END__

=pod

=cut
