package Graph::QL::Introspection;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa';

use Graph::QL::Util::Schemas;

use Graph::QL::Introspection::Resolvers;

use Graph::QL::Schema::Object;
use Graph::QL::Schema::Field;
use Graph::QL::Schema::Type::NonNull;
use Graph::QL::Schema::Type::List;
use Graph::QL::Schema::Type::Named;
use Graph::QL::Schema::Enum;
use Graph::QL::Schema::Enum::EnumValue;
use Graph::QL::Schema::InputObject::InputValue;

our $VERSION = '0.01';

sub enable_for_schema ($class, $schema, %opts) {

    throw('The schema provided must be an instance of `Graph::QL::Schema`, not `%s`', $schema)
        unless assert_isa( $schema, 'Graph::QL::Schema' );

    my @types = $schema->all_types->@*;

    my $query_type        = $schema->get_query_type;
    my $mutation_type     = $schema->get_mutation_type;
    my $subscription_type = $schema->get_subscription_type;

    return Graph::QL::Schema->new(
        # optional ...
        ($mutation_type     ? (mutation_type     => $mutation_type    ) : ()),
        ($subscription_type ? (subscription_type => $subscription_type) : ()),
        # ...
        query_type => $query_type,
        types => [
            get_introspection_objects_for_schema(),
            @types
        ]
    );
}

sub enable_for_resolvers ($class, $resolvers, %opts) {

    my @types = $resolvers->all_types->@*;

    # add the introspection types ...
    push @types => Graph::QL::Resolver::SchemaResolver
                        ->new_from_namespace('Graph::QL::Introspection::Resolvers')
                        ->all_types
                        ->@*;

    return Graph::QL::Resolver::SchemaResolver->new( types => \@types );
}

## fetch the implicit things ...

sub get_introspection_fields_for_query () {

    ## ...
    # extend type Query {
    #     __schema    : __Schema!
    #     __type (name : String!) : __Type
    # }

    state $__schema = Graph::QL::Schema::Field->new(
        name => '__schema',
        type => Graph::QL::Util::Schemas::construct_type_from_name('__Schema!')
    );

    state $__type = Graph::QL::Schema::Field->new(
        name => '__type',
        type => Graph::QL::Util::Schemas::construct_type_from_name('__Type'),
        args => [
            Graph::QL::Schema::InputObject::InputValue->new(
                name => 'name',
                type => Graph::QL::Util::Schemas::construct_type_from_name('String!')
            )
        ]
    );

    return ($__schema, $__type);
}

sub get_introspection_field_resolvers_to_query_resolver () {

    state $__schema = Graph::QL::Resolver::FieldResolver->new(
        name => '__schema',
        code => sub ($, $, $, $info) { $info->{schema} }
    );

    my $__type = Graph::QL::Resolver::FieldResolver->new(
        name => '__type',
        code => sub ($, $args, $, $info) { $info->{schema}->lookup_type( $args->{name} ) }
    );

    return ($__schema, $__type);
}

sub get_introspection_objects_for_schema () {
    ## ...
    # type __Schema {
    #     types            : [__Type!]!
    #     queryType        : __Type!
    #     mutationType     : __Type!
    #     subscriptionType : __Type!
    #     directives       : [__Directive!]!
    # }
    state $__Schema = Graph::QL::Schema::Object->new(
        name => '__Schema',
        fields => [
            Graph::QL::Schema::Field->new( name => 'types',            type => Graph::QL::Util::Schemas::construct_type_from_name('[__Type!]!') ),
            Graph::QL::Schema::Field->new( name => 'queryType',        type => Graph::QL::Util::Schemas::construct_type_from_name('__Type!') ),
            Graph::QL::Schema::Field->new( name => 'mutationType',     type => Graph::QL::Util::Schemas::construct_type_from_name('__Type') ),
            Graph::QL::Schema::Field->new( name => 'subscriptionType', type => Graph::QL::Util::Schemas::construct_type_from_name('__Type') ),
            Graph::QL::Schema::Field->new( name => 'directives',       type => Graph::QL::Util::Schemas::construct_type_from_name('[__Directive!]!') ),
        ]
    );


    ## ...
    # type __Type {
    #     kind          : __TypeKind!
    #     name          : String
    #     description   : String
    #     interfaces    : [__Type!]
    #     possibleTypes : [__Type!]
    #     inputFields   : [__InputValue!]
    #     ofType        : __Type
    #     fields     (includeDeprecated : Boolean = false) : [__Field!]
    #     enumValues (includeDeprecated : Boolean = false) : [__EnumValue!]
    # }
    state $__Type = Graph::QL::Schema::Object->new(
        name => '__Type',
        fields => [
            Graph::QL::Schema::Field->new( name => 'kind',          type => Graph::QL::Util::Schemas::construct_type_from_name('__TypeKind!') ),
            Graph::QL::Schema::Field->new( name => 'name',          type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
            Graph::QL::Schema::Field->new( name => 'description',   type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
            Graph::QL::Schema::Field->new(
                name => 'fields',
                type => Graph::QL::Util::Schemas::construct_type_from_name('[__Field!]'),
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name => 'includeDeprecated',
                        type => Graph::QL::Util::Schemas::construct_type_from_name('Boolean'),
                        default_value => 'false'
                    )
                ],
            ),
            Graph::QL::Schema::Field->new( name => 'interfaces',    type => Graph::QL::Util::Schemas::construct_type_from_name('[__Type!]') ),
            Graph::QL::Schema::Field->new( name => 'possibleTypes', type => Graph::QL::Util::Schemas::construct_type_from_name('[__Type!]') ),
            Graph::QL::Schema::Field->new(
                name => 'enumValues',
                type => Graph::QL::Util::Schemas::construct_type_from_name('[__EnumValue!]'),
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name => 'includeDeprecated',
                        type => Graph::QL::Util::Schemas::construct_type_from_name('Boolean'),
                        default_value => 'false'
                    )
                ],
            ),
            Graph::QL::Schema::Field->new( name => 'inputFields',   type => Graph::QL::Util::Schemas::construct_type_from_name('[__InputValue!]') ),
            Graph::QL::Schema::Field->new( name => 'ofType',        type => Graph::QL::Util::Schemas::construct_type_from_name('__Type') ),

        ]
    );


    ## ...
    # type __Field {
    #     name              : String!
    #     description       : String
    #     args              : [__InputValue!]!
    #     type              : __Type!
    #     isDeprecated      : Boolean!
    #     deprecationReason : String
    # }
    state $__Field = Graph::QL::Schema::Object->new(
        name => '__Field',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name',              type => Graph::QL::Util::Schemas::construct_type_from_name('String!') ),
            Graph::QL::Schema::Field->new( name => 'description',       type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
            Graph::QL::Schema::Field->new( name => 'args',              type => Graph::QL::Util::Schemas::construct_type_from_name('[__InputValue!]!') ),
            Graph::QL::Schema::Field->new( name => 'type',              type => Graph::QL::Util::Schemas::construct_type_from_name('__Type!') ),
            Graph::QL::Schema::Field->new( name => 'isDeprecated',      type => Graph::QL::Util::Schemas::construct_type_from_name('Boolean!') ),
            Graph::QL::Schema::Field->new( name => 'deprecationReason', type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
        ]
    );


    ## ...
    # type __InputValue {
    #     name         : String!
    #     description  : String
    #     type         : __Type!
    #     defaultValue : String
    # }
    state $__InputValue = Graph::QL::Schema::Object->new(
        name => '__InputValue',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name',         type => Graph::QL::Util::Schemas::construct_type_from_name('String!') ),
            Graph::QL::Schema::Field->new( name => 'description',  type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
            Graph::QL::Schema::Field->new( name => 'type',         type => Graph::QL::Util::Schemas::construct_type_from_name('__Type!') ),
            Graph::QL::Schema::Field->new( name => 'defaultValue', type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
        ]
    );


    ## ...
    # type __EnumValue {
    #     name              : String!
    #     description       : String
    #     isDeprecated      : Boolean!
    #     deprecationReason : String
    # }
    state $__EnumValue = Graph::QL::Schema::Object->new(
        name => '__EnumValue',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name',              type => Graph::QL::Util::Schemas::construct_type_from_name('String!') ),
            Graph::QL::Schema::Field->new( name => 'description',       type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
            Graph::QL::Schema::Field->new( name => 'isDeprecated',      type => Graph::QL::Util::Schemas::construct_type_from_name('Boolean!') ),
            Graph::QL::Schema::Field->new( name => 'deprecationReason', type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
        ]
    );

    ## ...
    # enum __TypeKind {
    #     SCALAR
    #     OBJECT
    #     INTERFACE
    #     UNION
    #     ENUM
    #     INPUT_OBJECT
    #     LIST
    #     NON_NULL
    # }
    state $__TypeKind = Graph::QL::Schema::Enum->new(
        name => '__TypeKind',
        values => [
            Graph::QL::Schema::Enum::EnumValue->new( name => 'SCALAR' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'OBJECT' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'INTERFACE' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'UNION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'ENUM' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'INPUT_OBJECT' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'LIST' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'NON_NULL' ),
        ]
    );

    ## ...
    # type __Directive {
    #   name: String!
    #   description: String
    #   locations: [__DirectiveLocation!]!
    #   args: [__InputValue!]!
    # }
    state $__Directive = Graph::QL::Schema::Object->new(
        name => '__Directive',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name',        type => Graph::QL::Util::Schemas::construct_type_from_name('String!') ),
            Graph::QL::Schema::Field->new( name => 'description', type => Graph::QL::Util::Schemas::construct_type_from_name('String') ),
            Graph::QL::Schema::Field->new( name => 'locations',   type => Graph::QL::Util::Schemas::construct_type_from_name('[__DirectiveLocation!]!') ),
            Graph::QL::Schema::Field->new( name => 'args',        type => Graph::QL::Util::Schemas::construct_type_from_name('[__InputValue!]!') ),
        ]
    );

    ## ...
    # enum __DirectiveLocation {
    #   QUERY
    #   MUTATION
    #   SUBSCRIPTION
    #   FIELD
    #   FRAGMENT_DEFINITION
    #   FRAGMENT_SPREAD
    #   INLINE_FRAGMENT
    #   SCHEMA
    #   SCALAR
    #   OBJECT
    #   FIELD_DEFINITION
    #   ARGUMENT_DEFINITION
    #   INTERFACE
    #   UNION
    #   ENUM
    #   ENUM_VALUE
    #   INPUT_OBJECT
    #   INPUT_FIELD_DEFINITION
    # }
    state $__DirectiveLocation = Graph::QL::Schema::Enum->new(
        name => '__DirectiveLocation',
        values => [
            Graph::QL::Schema::Enum::EnumValue->new( name => 'QUERY' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'MUTATION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'SUBSCRIPTION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'FIELD' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'FRAGMENT_DEFINITION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'FRAGMENT_SPREAD' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'INLINE_FRAGMENT' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'SCHEMA' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'SCALAR' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'OBJECT' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'FIELD_DEFINITION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'ARGUMENT_DEFINITION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'INTERFACE' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'UNION' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'ENUM' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'ENUM_VALUE' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'INPUT_OBJECT' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'INPUT_FIELD_DEFINITION' ),
        ]
    );


    return (
        $__Schema,
        $__Type,
        $__TypeKind,
        $__Field,
        $__InputValue,
        $__EnumValue,
        $__Directive,
        $__DirectiveLocation,
    );
}

1;

__END__

=pod

=cut
