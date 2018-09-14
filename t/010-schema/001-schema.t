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
}


subtest '... testing my schema' => sub {

    my $expected_type_language = q[
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

    my $schema = Graph::QL::Schema->new(
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

    #warn $schema->to_type_language;

    eq_or_diff($schema->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');
};

subtest '... testing another schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-e2969
    my $expected_type_language = q[
scalar String

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

    my $String = Graph::QL::Schema::Scalar->new( name => 'String' );

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
            $String,
            $MyQueryRootType,
            $MyMutationRootType,
        ]
    );

    #warn $schema->to_type_language;

    eq_or_diff($schema->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');
};

done_testing;
