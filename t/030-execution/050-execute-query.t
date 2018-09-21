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

    use_ok('Graph::QL::Execution::QueryValidator');
    use_ok('Graph::QL::Execution::ExecuteQuery');
}

my $schema = Graph::QL::Schema->new(
    query_type => Graph::QL::Schema::Type::Named->new( name => 'Query' ),
    types => [
        Graph::QL::Schema::Scalar->new( name => 'Int' ),
        Graph::QL::Schema::Scalar->new( name => 'String' ),
        Graph::QL::Schema::Object->new(
            name   => 'BirthEvent',
            fields => [
                Graph::QL::Schema::Field->new( name => 'year',  type => Graph::QL::Schema::Type::Named->new( name => 'Int'    ) ),
                Graph::QL::Schema::Field->new( name => 'place', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
            ]
        ),
        Graph::QL::Schema::Object->new(
            name   => 'DeathEvent',
            fields => [
                Graph::QL::Schema::Field->new( name => 'year',  type => Graph::QL::Schema::Type::Named->new( name => 'Int'    ) ),
                Graph::QL::Schema::Field->new( name => 'place', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
            ]
        ),
        Graph::QL::Schema::Object->new(
            name   => 'Person',
            fields => [
                Graph::QL::Schema::Field->new( name => 'name',        type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
                Graph::QL::Schema::Field->new( name => 'nationality', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
                Graph::QL::Schema::Field->new( name => 'gender',      type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
                Graph::QL::Schema::Field->new( name => 'birth',       type => Graph::QL::Schema::Type::Named->new( name => 'BirthEvent' ) ),
                Graph::QL::Schema::Field->new( name => 'death',       type => Graph::QL::Schema::Type::Named->new( name => 'DeathEvent' ) ),
            ]
        ),
        Graph::QL::Schema::Object->new(
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
                ),
                Graph::QL::Schema::Field->new(
                    name => 'findExactPerson',
                    args => [
                        Graph::QL::Schema::InputObject::InputValue->new(
                            name => 'name',
                            type => Graph::QL::Schema::Type::Named->new( name => 'String' )
                        ),
                        Graph::QL::Schema::InputObject::InputValue->new(
                            name => 'gender',
                            type => Graph::QL::Schema::Type::Named->new( name => 'String' )
                        ),
                        Graph::QL::Schema::InputObject::InputValue->new(
                            name => 'nationality',
                            type => Graph::QL::Schema::Type::Named->new( name => 'String' )
                        ),
                    ],
                    type => Graph::QL::Schema::Type::Named->new(
                        name => 'Person'
                    ),
                )
            ]
        )
    ]
);

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
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

    my $e = Graph::QL::Execution::ExecuteQuery->new( schema => $schema, query => $query );
    isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

    is(exception { $e->execute }, undef, '... no exceptions while validating');
    ok(!$e->has_errors, '... no errors have been be found');
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Field->new(
                name => 'findPerson',
                args => [],
            )
        ]
    );

    my $e = Graph::QL::Execution::ExecuteQuery->new( schema => $schema, query => $query );
    isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

    is(exception { $e->execute }, undef, '... no exceptions while validating');
    ok($e->has_errors, '... errors have been be found');
    eq_or_diff(
        [ $e->get_errors ],
        [
            'The `operation` did not pass validation.',
            'The `schema.field(findPerson)` and `query.field(findPerson)` both must expect arguments, not `yes` and `no`'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Field->new(
                name => 'findExactPerson',
                args => [
                    Graph::QL::Operation::Field::Argument->new( name => 'name', value => "Bob" ),
                    Graph::QL::Operation::Field::Argument->new( name => 'gender', value => 10 ),
                    Graph::QL::Operation::Field::Argument->new( name => 'honk', value => "Murican" ),
                ],
            )
        ]
    );

    my $e = Graph::QL::Execution::ExecuteQuery->new( schema => $schema, query => $query );
    isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

    is(exception { $e->execute }, undef, '... no exceptions while validating');
    ok($e->has_errors, '... errors have been found');
    eq_or_diff(
        [ $e->get_errors ],
        [
            'The `operation` did not pass validation.',
            'The `schema.field(findExactPerson).arg(gender).type` and `query.field(findExactPerson).arg(gender).type` , not `String` and `Int`',
            'The `schema.field(findExactPerson).arg.name` and `query.field(findExactPerson).arg.name` must match, got `nationality` and `honk`',
        ],
        '... got the expected validation errors'
    );
};

done_testing;
