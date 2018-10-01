#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

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

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}


subtest '... testing my schema' => sub {

    my $expected_type_language = q[
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

    my $schema = Graph::QL::Schema->new(
        query_type => Graph::QL::Schema::Type::Named->new( name => 'Query' ),
        types => [
            $BirthEvent,
            $DeathEvent,
            $Person,
            $Query
        ]
    );

    #warn $schema->to_type_language;

    eq_or_diff($schema->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language );
        my @definitions  = $expected_ast->{definitions}->@*;

        #warn Dumper $expected_ast;
        Graph::QL::Util::AST::null_out_source_locations(
            $_,
            # just clean it all out ... :P
            'types',
            'operationTypes.type',
            'fields.type',
            'fields.type.type',
            'fields.arguments.type',
            'fields.arguments.defaultValue'
        ) foreach @definitions, $expected_ast;

        my $schema_def = pop @definitions;
        my ($birth_event_def,
            $death_event_def,
            $person_def,
            $query_def,
        ) = @definitions;

        eq_or_diff($schema->ast->TO_JSON, $expected_ast, '... got the expected ast');
        eq_or_diff($schema->_schema_definition->TO_JSON, $schema_def, '... got the expected AST');
        eq_or_diff($BirthEvent->ast->TO_JSON, $birth_event_def, '... got the expected AST');
        eq_or_diff($DeathEvent->ast->TO_JSON, $death_event_def, '... got the expected AST');
        eq_or_diff($Person->ast->TO_JSON, $person_def, '... got the expected AST');
        eq_or_diff($Query->ast->TO_JSON, $query_def, '... got the expected AST');
    };

};

subtest '... testing another schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-e2969
    my $expected_type_language = q[
type MyQueryRootType {
    someField : String
}

type MyMutationRootType {
    setSomeField(to : String) : String
}

schema {
    query : MyQueryRootType
    mutation : MyMutationRootType
}
];

    my $MyQueryRootType = Graph::QL::Schema::Object->new(
        name   => 'MyQueryRootType',
        fields => [
            Graph::QL::Schema::Field->new( name => 'someField',  type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
        ]
    );

    my $MyMutationRootType = Graph::QL::Schema::Object->new(
        name   => 'MyMutationRootType',
        fields => [
            Graph::QL::Schema::Field->new(
                name => 'setSomeField',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name => 'to',
                        type => Graph::QL::Schema::Type::Named->new( name => 'String' )
                    )
                ],
                type => Graph::QL::Schema::Type::Named->new( name => 'String' ),
            ),
        ]
    );

    my $schema = Graph::QL::Schema->new(
        query_type    => Graph::QL::Schema::Type::Named->new( name => 'MyQueryRootType' ),
        mutation_type => Graph::QL::Schema::Type::Named->new( name => 'MyMutationRootType' ),
        types => [
            $MyQueryRootType,
            $MyMutationRootType,
        ]
    );

    #warn $schema->to_type_language;

    eq_or_diff($schema->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language );
        my @definitions  = $expected_ast->{definitions}->@*;

        #warn Dumper $expected_ast;
        Graph::QL::Util::AST::null_out_source_locations(
                $_,
                # just clean it all out ... :P
                'types',
                'operationTypes.type',
                'fields.type',
                'fields.arguments.type',
                'fields.arguments.defaultValue'
        ) foreach @definitions, $expected_ast;

        my $schema_def = pop @definitions;
        my ($my_query_root_type_def, $my_mutation_root_type_def) = @definitions;

        eq_or_diff($schema->ast->TO_JSON, $expected_ast, '... got the expected ast');
        eq_or_diff($schema->_schema_definition->TO_JSON, $schema_def, '... got the expected AST');
        eq_or_diff($MyQueryRootType->ast->TO_JSON, $my_query_root_type_def, '... got the expected AST');
        eq_or_diff($MyMutationRootType->ast->TO_JSON, $my_mutation_root_type_def, '... got the expected AST');
    };

};

done_testing;
