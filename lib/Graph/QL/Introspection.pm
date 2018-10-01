package Graph::QL::Introspection;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa';

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
            _get_introspection_schema_objects(),
            (map {
                $_->name eq $query_type->name
                    ? _add_introspection_fields_to_query( $_ )
                    : $_
            } @types)
        ]
    );
}

sub enable_for_query ($class, $query, %opts) {

    throw('The query provided must be an instance of `Graph::QL::Schema::Object`, not `%s`', $query)
        unless assert_isa( $query, 'Graph::QL::Schema::Object' );

    return _add_introspection_fields_to_query( $query )
}

sub enable_for_resolvers ($class, $resolvers, %opts) {

    my $query_type_name = $opts{query_type} || 'Query';

    my @types = map {
        $_->name eq $query_type_name
            ? _add_introspection_field_resolvers_to_query_resolver( $_ )
            : $_
    } $resolvers->all_types->@*;

    # add the introspection types ...
    push @types => Graph::QL::Resolvers
                        ->new_from_namespace('Graph::QL::Introspection::Resolvers')
                        ->all_types
                        ->@*;

    return Graph::QL::Resolvers->new( types => \@types );
}

## -------------------------------
## Setup simple type library
## -------------------------------
## these will be initialized in a
## BEGIN block below, but can be
## used in the subs without worry.
my (
                              $String_t, # String
                      $nonNull_String_t, # String!
                             $Boolean_t, # Boolean
                     $nonNull_Boolean_t, # Boolean!
                            $__Schema_t, # __Schema
                     $nonNull__Schema_t, # __Schema!
                              $__Type_t, # __Type
                       $nonNull__Type_t, # __Type!
                  $List_nonNull__Type_t, # [__Type!]
          $nonNull_List_nonNull__Type_t, # [__Type!]!
                          $__TypeKind_t, # __TypeKind
                   $nonNull__TypeKind_t, # __TypeKind!
                        $__InputValue_t, # __InputValue
                 $nonNull__InputValue_t, # __InputValue!
            $List_nonNull__InputValue_t, # [__InputValue!]
    $nonNull_List_nonNull__InputValue_t, # [__InputValue!]!
                             $__Field_t, # __Field
                      $nonNull__Field_t, # __Field!
                 $List_nonNull__Field_t, # [__Field!]
                         $__EnumValue_t, # __EnumValue
                  $nonNull__EnumValue_t, # __EnumValue!
             $List_nonNull__EnumValue_t, # [__EnumValue!]
);

## ...

sub _add_introspection_field_resolvers_to_query_resolver ( $type_resolver ) {

    return Graph::QL::Resolvers::TypeResolver->new(
        name => $type_resolver->name,
        fields => [
            $type_resolver->all_fields->@*,
            # __schema    : __Schema!
            Graph::QL::Resolvers::FieldResolver->new( name => '__schema',  code => sub ($, $, $, $info) { $info->{schema} } ),
            # __type (name : String!) : __Type
            Graph::QL::Resolvers::FieldResolver->new(
                name => '__type',
                code => sub ($, $args, $, $info) { $info->{schema}->lookup_type( $args->{name} ) }
            ),
        ]
    )
}

## ...

sub _add_introspection_fields_to_query ($query) {

    ## ...
    # extend type Query {
    #     __schema    : __Schema!
    #     __type (name : String!) : __Type
    # }
    return Graph::QL::Schema::Object->new(
        name   => $query->name,
        fields => [
            $query->all_fields->@*,
            Graph::QL::Schema::Field->new( name => '__schema', type => $nonNull__Schema_t ),
            Graph::QL::Schema::Field->new(
                name => '__type',
                type => $__Type_t,
                args => [ Graph::QL::Schema::InputObject::InputValue->new( name => 'name', type => $nonNull_String_t ) ]
            )
        ],
        # carry over the interfaces if needed
        ($query->has_interfaces ? (interfaces => $query->interfaces) : ()),
    );
}


sub _get_introspection_schema_objects () {
    ## ...
    # type __Schema {
    #     types            : [__Type!]!
    #     queryType        : __Type!
    #     mutationType     : __Type!
    #     subscriptionType : __Type!
    # }
    state $__Schema = Graph::QL::Schema::Object->new(
        name => '__Schema',
        fields => [
            Graph::QL::Schema::Field->new( name => 'types',            type => $nonNull_List_nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'queryType',        type => $nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'mutationType',     type => $nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'subscriptionType', type => $nonNull__Type_t ),
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
            Graph::QL::Schema::Field->new( name => 'kind',          type => $nonNull__TypeKind_t ),
            Graph::QL::Schema::Field->new( name => 'name',          type => $String_t ),
            Graph::QL::Schema::Field->new( name => 'description',   type => $String_t ),
            Graph::QL::Schema::Field->new( name => 'interfaces',    type => $List_nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'possibleTypes', type => $List_nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'inputFields',   type => $List_nonNull__InputValue_t ),
            Graph::QL::Schema::Field->new( name => 'ofType',        type => $__Type_t ),
            Graph::QL::Schema::Field->new(
                name => 'fields',
                type => $List_nonNull__Field_t,
             args => [ Graph::QL::Schema::InputObject::InputValue->new( name => 'includeDeprecated', type => $Boolean_t, default_value => \0 ) ],
            ),
            Graph::QL::Schema::Field->new(
                name => 'enumValues',
                type => $List_nonNull__EnumValue_t,
             args => [ Graph::QL::Schema::InputObject::InputValue->new( name => 'includeDeprecated', type => $Boolean_t, default_value => \0 ) ],
            ),
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
            Graph::QL::Schema::Field->new( name => 'name',              type => $nonNull_String_t ),
            Graph::QL::Schema::Field->new( name => 'description',       type => $String_t ),
            Graph::QL::Schema::Field->new( name => 'args',              type => $nonNull_List_nonNull__InputValue_t ),
            Graph::QL::Schema::Field->new( name => 'type',              type => $nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'isDeprecated',      type => $nonNull_Boolean_t ),
            Graph::QL::Schema::Field->new( name => 'deprecationReason', type => $String_t ),
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
            Graph::QL::Schema::Field->new( name => 'name',         type => $nonNull_String_t ),
            Graph::QL::Schema::Field->new( name => 'description',  type => $String_t ),
            Graph::QL::Schema::Field->new( name => 'type',         type => $nonNull__Type_t ),
            Graph::QL::Schema::Field->new( name => 'defaultValue', type => $String_t ),
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
            Graph::QL::Schema::Field->new( name => 'name',              type => $nonNull_String_t ),
            Graph::QL::Schema::Field->new( name => 'description',       type => $String_t ),
            Graph::QL::Schema::Field->new( name => 'isDeprecated',      type => $nonNull_Boolean_t ),
            Graph::QL::Schema::Field->new( name => 'deprecationReason', type => $String_t ),
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

    return (
        $__Schema,
        $__Type,
        $__Field,
        $__InputValue,
        $__EnumValue,
        $__TypeKind
    );
}


## -------------------------------
## Initialize the type library
## -------------------------------
## We are just initializing these
## objects here, see above
BEGIN {
## ...
                              $String_t = Graph::QL::Schema::Type::Named->new( name => 'String' );
                      $nonNull_String_t = Graph::QL::Schema::Type::NonNull->new( of_type => $String_t );
                             $Boolean_t = Graph::QL::Schema::Type::Named->new( name => 'Boolean' );
                     $nonNull_Boolean_t = Graph::QL::Schema::Type::NonNull->new( of_type => $Boolean_t );
## ...
                            $__Schema_t = Graph::QL::Schema::Type::Named->new( name => '__Schema' );
                     $nonNull__Schema_t = Graph::QL::Schema::Type::NonNull->new( of_type => $__Schema_t );
## ...
                              $__Type_t = Graph::QL::Schema::Type::Named->new( name => '__Type' );
                       $nonNull__Type_t = Graph::QL::Schema::Type::NonNull->new( of_type => $__Type_t );
                  $List_nonNull__Type_t = Graph::QL::Schema::Type::List->new( of_type => $nonNull__Type_t );
          $nonNull_List_nonNull__Type_t = Graph::QL::Schema::Type::NonNull->new( of_type => $List_nonNull__Type_t );
## ...
                          $__TypeKind_t = Graph::QL::Schema::Type::Named->new( name => '__TypeKind' );
                   $nonNull__TypeKind_t = Graph::QL::Schema::Type::NonNull->new( of_type => $__TypeKind_t );
## ...
                        $__InputValue_t = Graph::QL::Schema::Type::Named->new( name => '__InputValue' );
                 $nonNull__InputValue_t = Graph::QL::Schema::Type::NonNull->new( of_type => $__InputValue_t );
            $List_nonNull__InputValue_t = Graph::QL::Schema::Type::List->new( of_type => $nonNull__InputValue_t );
    $nonNull_List_nonNull__InputValue_t = Graph::QL::Schema::Type::NonNull->new( of_type => $List_nonNull__InputValue_t );
## ...
                             $__Field_t = Graph::QL::Schema::Type::Named->new( name => '__Field' );
                      $nonNull__Field_t = Graph::QL::Schema::Type::NonNull->new( of_type => $__Field_t );
                 $List_nonNull__Field_t = Graph::QL::Schema::Type::List->new( of_type => $nonNull__Field_t );
## ...
                         $__EnumValue_t = Graph::QL::Schema::Type::Named->new( name => '__EnumValue' );
                  $nonNull__EnumValue_t = Graph::QL::Schema::Type::NonNull->new( of_type => $__EnumValue_t );
             $List_nonNull__EnumValue_t = Graph::QL::Schema::Type::List->new( of_type => $nonNull__EnumValue_t );
}

1;

__END__

=pod

=cut
