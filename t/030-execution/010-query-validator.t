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
    use_ok('Graph::QL::Operation::Selection::Field');
    use_ok('Graph::QL::Operation::Selection::Field::Argument');

    use_ok('Graph::QL::Execution::QueryValidator');
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
                selections => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'findPerson',
                        args       => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'name', value => 'Bob' ) ],
                        selections => [
                            Graph::QL::Operation::Selection::Field->new( name => 'name' ),
                            Graph::QL::Operation::Selection::Field->new(
                                name       => 'birth',
                                selections => [
                                    Graph::QL::Operation::Selection::Field->new( name => 'year' ),
                                ]
                            ),
                            Graph::QL::Operation::Selection::Field->new(
                                name       => 'death',
                                selections => [
                                    Graph::QL::Operation::Selection::Field->new( name => 'year' ),
                                ]
                            ),
                        ]
                    )
                ]
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok(!$v->has_errors, '... no errors to be found');
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'locatePerson',
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'Unable to find the `query.field(locatePerson)` in the `schema.type(Query)` type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findPerson',
                args => [],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findPerson)` and `query.field(findPerson)` both must expect arguments, not `yes` and `no`',
            'The `query.field(findPerson)` must have selections, because `schema.type(Person)` is an object type',
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findPerson',
                args => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'id', value => 'Bob' ) ],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findPerson).arg.name` and `query.field(findPerson).arg.name` must match, got `name` and `id`',
            'The `query.field(findPerson)` must have selections, because `schema.type(Person)` is an object type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findPerson',
                args => [
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'id',       value => 10 ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'other_id', value => 20 )
                ],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findPerson).arity` and `query.field(findPerson).arity` must match, not `1` and `2`',
            'The `query.field(findPerson)` must have selections, because `schema.type(Person)` is an object type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findPerson',
                args => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'id', value => 10 ) ],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findPerson).arg.name` and `query.field(findPerson).arg.name` must match, got `name` and `id`',
            'The `query.field(findPerson)` must have selections, because `schema.type(Person)` is an object type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findExactPerson',
                args => [
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'foo', value => 10 ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'bar', value => 10 ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'baz', value => 10.5 ),
                ],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findExactPerson).arg.name` and `query.field(findExactPerson).arg.name` must match, got `name` and `foo`',
            'The `schema.field(findExactPerson).arg.name` and `query.field(findExactPerson).arg.name` must match, got `gender` and `bar`',
            'The `schema.field(findExactPerson).arg.name` and `query.field(findExactPerson).arg.name` must match, got `nationality` and `baz`',
            'The `query.field(findExactPerson)` must have selections, because `schema.type(Person)` is an object type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findExactPerson',
                args => [
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'name', value => "Bob" ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'gender', value => 10 ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'nationality', value => "Murican" ),
                ],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findExactPerson).arg(gender).type` and `query.field(findExactPerson).arg(gender).type` , not `String` and `Int`',
            'The `query.field(findExactPerson)` must have selections, because `schema.type(Person)` is an object type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findExactPerson',
                args => [
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'name', value => "Bob" ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'gender', value => 10 ),
                    Graph::QL::Operation::Selection::Field::Argument->new( name => 'honk', value => "Murican" ),
                ],
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'The `schema.field(findExactPerson).arg(gender).type` and `query.field(findExactPerson).arg(gender).type` , not `String` and `Int`',
            'The `schema.field(findExactPerson).arg.name` and `query.field(findExactPerson).arg.name` must match, got `nationality` and `honk`',
            'The `query.field(findExactPerson)` must have selections, because `schema.type(Person)` is an object type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        name       => 'findAllBobs',
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name       => 'findPerson',
                args       => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'name', value => 'Bob' ) ],
                selections => [
                    Graph::QL::Operation::Selection::Field->new( name => 'foo' ),
                ]
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'Unable to find the `query.selection.field(foo)` in the `schema.object(Person)` type'
        ],
        '... got the expected validation errors'
    );
};

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        name       => 'findAllBobs',
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name       => 'findPerson',
                args       => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'name', value => 'Bob' ) ],
                selections => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'birth',
                        selections => [
                            Graph::QL::Operation::Selection::Field->new( name => 'years' ),
                        ]
                    ),
                ]
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'Unable to find the `query.selection.field(years)` in the `schema.object(BirthEvent)` type'
        ],
        '... got the expected validation errors'
    );
};

## test the $name arg in validate

subtest '... validating the query against the schema' => sub {

    my $query = Graph::QL::Operation::Query->new(
        selections => [
            Graph::QL::Operation::Selection::Field->new(
                name => 'findAllBobs',
            ),
            Graph::QL::Operation::Selection::Field->new(
                name => 'findOneAlice',
            )
        ]
    );

    my $v = Graph::QL::Execution::QueryValidator->new( schema => $schema, query => $query );
    isa_ok($v, 'Graph::QL::Execution::QueryValidator');

    is(exception { $v->validate }, undef, '... validation happened without incident');

    ok($v->has_errors, '... no errors to be found');
    eq_or_diff(
        [ $v->get_errors ],
        [
            'Unable to find the `query.field(findAllBobs)` in the `schema.type(Query)` type',
            'Unable to find the `query.field(findOneAlice)` in the `schema.type(Query)` type',
        ],
        '... got the expected validation errors'
    );
};


done_testing;
