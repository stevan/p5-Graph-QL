#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Meta::Schema');

    use_ok('Graph::QL::Meta::Type::List');
    use_ok('Graph::QL::Meta::Type::Object');
    use_ok('Graph::QL::Meta::Type::Scalar');

    use_ok('Graph::QL::Meta::Field');
    use_ok('Graph::QL::Meta::InputValue');
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

    my $Int    = Graph::QL::Meta::Type::Scalar->new( name => 'Int' );
    my $String = Graph::QL::Meta::Type::Scalar->new( name => 'String' );

    my $BirthEvent = Graph::QL::Meta::Type::Object->new(
        name   => 'BirthEvent',
        fields => [
            Graph::QL::Meta::Field->new( name => 'year',  type => $Int    ),
            Graph::QL::Meta::Field->new( name => 'place', type => $String ),
        ]
    );

    my $DeathEvent = Graph::QL::Meta::Type::Object->new(
        name   => 'DeathEvent',
        fields => [
            Graph::QL::Meta::Field->new( name => 'year',  type => $Int    ),
            Graph::QL::Meta::Field->new( name => 'place', type => $String ),
        ]
    );

    my $Person = Graph::QL::Meta::Type::Object->new(
        name   => 'Person',
        fields => [
            Graph::QL::Meta::Field->new( name => 'name',        type => $String ),
            Graph::QL::Meta::Field->new( name => 'nationality', type => $String ),
            Graph::QL::Meta::Field->new( name => 'gender',      type => $String ),
            Graph::QL::Meta::Field->new( name => 'birth',       type => $BirthEvent ),
            Graph::QL::Meta::Field->new( name => 'death',       type => $DeathEvent ),
        ]
    );

    my $Query = Graph::QL::Meta::Type::Object->new(
        name   => 'Query',
        fields => [
            Graph::QL::Meta::Field->new(
                name => 'findPerson',
                args => [ Graph::QL::Meta::InputValue->new( name => 'name', type => $String ) ],
                type => Graph::QL::Meta::Type::List->new( of_type => $Person ),
            )
        ]
    );

    my $schema = Graph::QL::Meta::Schema->new(
        query_type => $Query,
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

    my $String = Graph::QL::Meta::Type::Scalar->new( name => 'String' );

    my $MyQueryRootType = Graph::QL::Meta::Type::Object->new(
        name   => 'MyQueryRootType',
        fields => [
            Graph::QL::Meta::Field->new( name => 'someField',  type => $String ),
        ]
    );

    my $MyMutationRootType = Graph::QL::Meta::Type::Object->new(
        name   => 'MyMutationRootType',
        fields => [
            Graph::QL::Meta::Field->new(
                name => 'setSomeField',
                args => [ Graph::QL::Meta::InputValue->new( name => 'to', type => $String ) ],
                type => $String,
            ),
        ]
    );

    my $schema = Graph::QL::Meta::Schema->new(
        query_type    => $MyQueryRootType,
        mutation_type => $MyMutationRootType,
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
