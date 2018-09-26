#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Test::Fatal;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');
    use_ok('Graph::QL::Operation::Query');
    use_ok('Graph::QL::Execution::ExecuteQuery');

    use_ok('Graph::QL::Resolvers');
    use_ok('Graph::QL::Resolvers::TypeResolver');
    use_ok('Graph::QL::Resolvers::FieldResolver');
    use_ok('Graph::QL::Schema::TypeKind');
}

my $schema = Graph::QL::Schema->new_from_source(q[

scalar String
scalar Boolean

type __Schema {
    types            : [__Type!]!
    queryType        : __Type!
    mutationType     : __Type!
    subscriptionType : __Type!
}

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

type __Field {
    name              : String!
    description       : String
    args              : [__InputValue!]!
    type              : __Type!
    isDeprecated      : Bool!
    deprecationReason : String
}

type __InputValue {
    name         : String!
    description  : String
    type         : __Type!
    defaultValue : String
}

type __EnumValue {
    name              : String!
    description       : String
    isDeprecated      : Bool!
    deprecationReason : String
}

enum TypeKind {
    SCALAR
    OBJECT
    INTERFACE
    UNION
    ENUM
    INPUT_OBJECT
    LIST
    NON_NULL
}

type Query {
    __schema    : __Schema!
    __typename  : String!
    __type (name : String!) : __Type
}

schema {
    query : Query
}

]);

my $query = Graph::QL::Operation::Query->new_from_source(q[
    query TestQuery {
        __schema {
            types {
                kind
                name
                fields(includeDeprecated : true) {
                    name
                    type {
                        kind
                        name
                    }
                }
            }
        }
    }
]);

my $e = Graph::QL::Execution::ExecuteQuery->new(
    schema    => $schema,
    query     => $query,
    resolvers => Graph::QL::Resolvers->new(
        types => [
            Graph::QL::Resolvers::TypeResolver->new(
                name   => 'Query',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => '__schema', code => sub ($, $, $, $) { $schema } )
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => '__Schema',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'types', code => sub ($schema, $, $, $) { $schema->all_types } )
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => '__Type',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new(
                        name => 'kind',
                        code => sub ($type, $, $, $) {
                            if ( $type->isa('Graph::QL::Schema::Type::Named') ) {
                                $type = $schema->lookup_type( $type->name );
                            }

                            Graph::QL::Schema::TypeKind->get_type_kind_for_schema_type( $type )
                        }
                    ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'name', code => sub ($type, $, $, $) { $type->name } ),
                    Graph::QL::Resolvers::FieldResolver->new(
                        name => 'fields',
                        code => sub ($type, $args, $, $) {
                            # ignore the includeDeprecated arg for now ...
                            if ( $type->can('all_fields') ) {
                                return $type->all_fields;
                            }
                            else {
                                return [];
                            }
                        }
                    ),
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => '__Field',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'name', code => sub ($field, $, $, $) { $field->name } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'type', code => sub ($field, $, $, $) { $field->type } ),
                ]
            )
        ]
    )
);
isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

ok($e->validate, '... the schema and query validated correctly');
ok(!$e->has_errors, '... no errors have been be found');

my $result = $e->execute;

ok($result, '... we got a defined result');

# warn Dumper $result;

done_testing;
