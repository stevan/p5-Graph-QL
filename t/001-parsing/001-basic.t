#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Test::More;
use Test::Differences;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Type::List');
    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Scalar');

    use_ok('Graph::QL::Schema::Field');
    use_ok('Graph::QL::Schema::InputObject::InputValue');

    use_ok('Graph::QL::Operation::Query');
    use_ok('Graph::QL::Operation::Field');
    use_ok('Graph::QL::Operation::Field::Argument');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');

    use_ok('Graph::QL::Execution::ExecuteQuery');
}

subtest '... testing it all together' => sub {

## specify the schema and query in the type language ...

    my $schema_as_type_lang = q[
type BirthEvent {
    year : Int
    place : String
}

type DeathEvent {
    year : Int
    place : String
}

type Person {
    name : String
    nationality : String
    gender : String
    birth : BirthEvent
    death : DeathEvent
}

type Query {
    findPerson(name : String) : [Person]
}

schema {
    query : Query
}
];

    my $query_as_type_lang =
q[query findAllBobs {
    findPerson(name : "Bob") {
        name
        birth {
            year
        }
        death {
            year
        }
    }
}];

## Construct the object versions ...

    my $BirthEvent = Graph::QL::Schema::Object->new(
        name   => 'BirthEvent',
        fields => [
            Graph::QL::Schema::Field->new( name => 'year',  type => Graph::QL::Schema::Type::Named->new( name => 'Int'    ) ),
            Graph::QL::Schema::Field->new( name => 'place', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
        ]
    );

    my $DeathEvent = Graph::QL::Schema::Object->new(
        name   => 'DeathEvent',
        fields => [
            Graph::QL::Schema::Field->new( name => 'year',  type => Graph::QL::Schema::Type::Named->new( name => 'Int'    ) ),
            Graph::QL::Schema::Field->new( name => 'place', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
        ]
    );

    my $Person = Graph::QL::Schema::Object->new(
        name   => 'Person',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name',        type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
            Graph::QL::Schema::Field->new( name => 'nationality', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
            Graph::QL::Schema::Field->new( name => 'gender',      type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
            Graph::QL::Schema::Field->new( name => 'birth',       type => Graph::QL::Schema::Type::Named->new( name => 'BirthEvent' ) ),
            Graph::QL::Schema::Field->new( name => 'death',       type => Graph::QL::Schema::Type::Named->new( name => 'DeathEvent' ) ),
        ]
    );

    my $Query = Graph::QL::Schema::Object->new(
        name   => 'Query',
        fields => [
            Graph::QL::Schema::Field->new(
                name => 'findPerson',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name => 'name',
                        type => Graph::QL::Schema::Type::Named->new( name => 'String' )
                    )
                ],
                type => Graph::QL::Schema::Type::List->new(
                    of_type => Graph::QL::Schema::Type::Named->new(
                        name => 'Person'
                    )
                ),
            )
        ]
    );

    my $schema_as_object = Graph::QL::Schema->new(
        query_type => Graph::QL::Schema::Type::Named->new( name => 'Query' ),
        types => [
            $BirthEvent,
            $DeathEvent,
            $Person,
            $Query
        ]
    );

    my $query_as_object = Graph::QL::Operation::Query->new(
        name       => 'findAllBobs',
        selections => [
            Graph::QL::Operation::Field->new(
                name       => 'findPerson',
                args       => [ Graph::QL::Operation::Field::Argument->new( name => 'name', value => 'Bob' ) ],
                selections => [
                    Graph::QL::Operation::Field->new( name => 'name' ),
                    Graph::QL::Operation::Field->new(
                        name       => 'birth',
                        selections => [
                            Graph::QL::Operation::Field->new( name => 'year' ),
                        ]
                    ),
                    Graph::QL::Operation::Field->new(
                        name       => 'death',
                        selections => [
                            Graph::QL::Operation::Field->new( name => 'year' ),
                        ]
                    ),
                ]
            )
        ]
    );

## test that the type language pretty printing works

    eq_or_diff($schema_as_object->to_type_language, $schema_as_type_lang, '... got the pretty printed schema as expected');
    eq_or_diff($query_as_object->to_type_language, $query_as_type_lang, '... got the pretty printed query as expected');

## now test that we produced valid ASTs from the object versions

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_schema_ast = Graph::QL::Parser->parse_raw( $schema_as_type_lang );
        my $expected_query_ast  = Graph::QL::Parser->parse_raw( $query_as_type_lang );

        Graph::QL::Util::AST::null_out_source_locations(
            $expected_schema_ast,
            # just clean it all out ... :P
            'definitions.types',
            'definitions.operationTypes.type',
            'definitions.fields.type',
            'definitions.fields.type.type',
            'definitions.fields.arguments.type',
            'definitions.fields.arguments.defaultValue'
        );

        Graph::QL::Util::AST::null_out_source_locations(
            $expected_query_ast,
            # just clean it all out ... :P
            'definitions.selectionSet.selections.arguments.value',
            'definitions.selectionSet.selections.selectionSet.selections.arguments.value',
            'definitions.selectionSet.selections.selectionSet.selections.selectionSet.selections.arguments.value',
        );

        eq_or_diff($schema_as_object->ast->TO_JSON, $expected_schema_ast, '... got the expected schema ast');
        eq_or_diff($query_as_object->ast->TO_JSON, $expected_query_ast, '... got the expected query ast');
    };
};

done_testing;
