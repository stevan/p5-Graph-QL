#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Type::List');
    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Scalar');

    use_ok('Graph::QL::Schema::Field');
    use_ok('Graph::QL::Schema::InputObject::InputValue');

    use_ok('Graph::QL::Query');
    use_ok('Graph::QL::Query::Field');
    use_ok('Graph::QL::Query::Argument');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}

subtest '... testing it all together' => sub {

## specify the schema and query in the type language ...

    my $schema_as_type_lang = q[
scalar Int

scalar String

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

    my $Int    = Graph::QL::Schema::Scalar->new( name => 'Int' );
    my $String = Graph::QL::Schema::Scalar->new( name => 'String' );

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
            $Int,
            $String,
            $BirthEvent,
            $DeathEvent,
            $Person,
            $Query
        ]
    );

    my $query_as_object = Graph::QL::Query->new(
        name       => 'findAllBobs',
        selections => [
            Graph::QL::Query::Field->new(
                name       => 'findPerson',
                args       => [ Graph::QL::Query::Argument->new( name => 'name', value => 'Bob' ) ],
                selections => [
                    Graph::QL::Query::Field->new( name => 'name' ),
                    Graph::QL::Query::Field->new(
                        name       => 'birth',
                        selections => [
                            Graph::QL::Query::Field->new( name => 'year' ),
                        ]
                    ),
                    Graph::QL::Query::Field->new(
                        name       => 'death',
                        selections => [
                            Graph::QL::Query::Field->new( name => 'year' ),
                        ]
                    ),
                ]
            )
        ]
    );

    subtest '... reherse the type check and field selection' => sub {

        # find the Query type within the schema ...
        my $Query = $schema_as_object->lookup_root_type( $query_as_object );
        isa_ok($Query, 'Graph::QL::Schema::Object');

        # get the root field from the query Op ...
        my $query_field = $query_as_object->selections->[0];
        isa_ok($query_field, 'Graph::QL::Query::Field');

        # and use it to find the field in the (schema) Query object ...
        my $schema_field = $Query->lookup_field( $query_field );
        isa_ok($schema_field, 'Graph::QL::Schema::Field');

        # check the args
        foreach my $i ( 0 .. $#{ $schema_field->args } ) {
            my $schema_arg = $schema_field->args->[ $i ];
            my $query_arg  = $query_field->args->[ $i ];

            isa_ok($schema_arg, 'Graph::QL::Schema::InputObject::InputValue');
            isa_ok($query_arg, 'Graph::QL::Query::Argument');

            # make sure the name of each arg matches ...
            is($schema_arg->name, $query_arg->name, '... the args are the same name');

            # get the type of the arg from the
            # perspective of the schema ....
            my $schema_arg_type = $schema_arg->type;
            isa_ok($schema_arg_type, 'Graph::QL::Schema::Type::Named');

            # now get the type of the arg that the
            # query is sending us ...
            my $query_arg_type = Graph::QL::Util::AST::ast_value_to_schema_type( $query_arg->ast->value );
            isa_ok($query_arg_type, 'Graph::QL::Schema::Type::Named');

            # are they the same name type? ... yes!
            is($query_arg_type->name, $schema_arg_type->name, '... these are the same type');
        }


        # find the return type of all this ...
        my $schema_field_return_type = $schema_field->type;
        isa_ok($schema_field_return_type, 'Graph::QL::Schema::Type::List');

        is($schema_field_return_type->name, '[Person]', '... got the name we expected');

        # look at the of-type ...
        my $schema_field_return_inner_type = $schema_field_return_type->of_type;
        isa_ok($schema_field_return_inner_type, 'Graph::QL::Schema::Type::Named');
        is($schema_field_return_inner_type->name, 'Person', '... got the name we expected');

        # find the Person type within the schema ...
        my ($schema_person) = $schema_as_object->lookup_type( $schema_field_return_inner_type );
        isa_ok($schema_person, 'Graph::QL::Schema::Object');

        # verify that the selection will work,
        # foreach of the selected fields, we must ...
        foreach my $query_field ( $query_field->selections->@* ) {
            isa_ok($query_field, 'Graph::QL::Query::Field');

            # find the field from the schema object ...
            my ($schema_field) = $schema_person->lookup_field( $query_field );
            isa_ok($schema_field, 'Graph::QL::Schema::Field');

            # then check to see if this query has any sub-selections ...
            if ( $query_field->has_selections ) {

                # if so, grab the type of the field ...
                my $schema_field_type = $schema_field->type;
                isa_ok($schema_field_type, 'Graph::QL::Schema::Type::Named');

                # then find the object for that type ...
                my ($schema_field_object) = $schema_as_object->lookup_type( $schema_field_type );
                isa_ok($schema_field_object, 'Graph::QL::Schema::Object');

                # then lets look through the sub-selections ...
                foreach my $sub_query_field ( $query_field->selections->@* ) {
                    isa_ok($sub_query_field, 'Graph::QL::Query::Field');

                    # and make sure that there is a field in the sub-object
                    # for all the sub-selected fields
                    my ($schema_sub_field) = $schema_field_object->lookup_field( $sub_query_field );
                    isa_ok($schema_sub_field, 'Graph::QL::Schema::Field');
                }

            }
        }
    };

## test that the type language pretty printing works

    eq_or_diff($schema_as_object->to_type_language, $schema_as_type_lang, '... got the pretty printed schema as expected');
    eq_or_diff($query_as_object->to_type_language, $query_as_type_lang, '... got the pretty printed query as expected');

## now test that we produced valid ASTs from the object versions

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_schema_ast = Graph::QL::Parser->parse_raw( $schema_as_type_lang );
        my $expected_query_ast  = Graph::QL::Parser->parse_raw( $query_as_type_lang )->{definitions}->[0];

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
            'selectionSet.selections.arguments.value',
            'selectionSet.selections.selectionSet.selections.arguments.value',
            'selectionSet.selections.selectionSet.selections.selectionSet.selections.arguments.value',
        );

        eq_or_diff($schema_as_object->ast->TO_JSON, $expected_schema_ast, '... got the expected schema ast');
        eq_or_diff($query_as_object->ast->TO_JSON, $expected_query_ast, '... got the expected query ast');
    };
};

done_testing;
