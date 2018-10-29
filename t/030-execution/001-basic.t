#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Test::More;
use Test::Differences;
use Test::Fatal;
use Data::Dumper;
use Time::Piece;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Util::Schemas');

    use_ok('Graph::QL::Schema::Type::List');
    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Scalar');

    use_ok('Graph::QL::Schema::Field');
    use_ok('Graph::QL::Schema::InputObject::InputValue');

    use_ok('Graph::QL::Operation');
    use_ok('Graph::QL::Operation::Query');
    use_ok('Graph::QL::Operation::Fragment');
    use_ok('Graph::QL::Operation::Selection::Field');
    use_ok('Graph::QL::Operation::Selection::Field::Argument');
    use_ok('Graph::QL::Operation::Selection::FragmentSpread');

    use_ok('Graph::QL::Execution::QueryValidator');
    use_ok('Graph::QL::Execution::ExecuteQuery');

    use_ok('Graph::QL::Resolver::SchemaResolver');
    use_ok('Graph::QL::Resolver::TypeResolver');
    use_ok('Graph::QL::Resolver::FieldResolver');
}

my $resolvers = Graph::QL::Resolver::SchemaResolver->new(
    types => [
        Graph::QL::Resolver::TypeResolver->new(
            name   => 'Query',
            fields => [
                Graph::QL::Resolver::FieldResolver->new( name => 'getAllPeople', code => sub ($, $, $context, $) { $context->{people} } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'findPerson',   code => sub ($, $args, $context, $) {
                    my $name = $args->{name};
                    return [ grep { $_->{displayname} =~ /$name/ } $context->{people}->@* ]
                }),
            ]
        ),
        Graph::QL::Resolver::TypeResolver->new(
            name   => 'Person',
            fields => [
                Graph::QL::Resolver::FieldResolver->new( name => 'name',        code => sub ($data, $, $ ,$) { $data->{displayname} } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'nationality', code => sub ($data, $, $ ,$) { $data->{culture}     } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'gender',      code => sub ($data, $, $ ,$) { $data->{gender}      } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'birth',       code => sub ($data, $, $ ,$) { $data } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'death',       code => sub ($data, $, $ ,$) { $data } ),
            ]
        ),
        Graph::QL::Resolver::TypeResolver->new(
            name   => 'BirthEvent',
            fields => [
                Graph::QL::Resolver::FieldResolver->new( name => 'date',  code => sub ($data, $, $ ,$) { Time::Piece->strptime( $data->{datebegin}, '%B %d, %Y' ) } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'place', code => sub ($data, $, $ ,$) { $data->{birthplace} } ),
            ]
        ),
        Graph::QL::Resolver::TypeResolver->new(
            name   => 'DeathEvent',
            fields => [
                Graph::QL::Resolver::FieldResolver->new( name => 'date',  code => sub ($data, $, $ ,$) { Time::Piece->strptime( $data->{dateend}, '%B %d, %Y' ) } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'place', code => sub ($data, $, $ ,$) { $data->{deathplace} } ),
            ]
        ),
        Graph::QL::Resolver::TypeResolver->new(
            name   => 'Date',
            fields => [
                Graph::QL::Resolver::FieldResolver->new( name => 'day',   code => sub ($data, $, $ ,$) { $data->mday      } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'month', code => sub ($data, $, $ ,$) { $data->fullmonth } ),
                Graph::QL::Resolver::FieldResolver->new( name => 'year',  code => sub ($data, $, $ ,$) { $data->year      } ),
            ]
        )
    ]
);

my $schema = Graph::QL::Schema->new(
    query_type => Graph::QL::Schema::Type::Named->new( name => 'Query' ),
    types => [
        Graph::QL::Schema::Scalar->new( name => 'Int' ),
        Graph::QL::Schema::Scalar->new( name => 'String' ),
        Graph::QL::Schema::Object->new(
            name   => 'Date',
            fields => [
                Graph::QL::Schema::Field->new( name => 'day',   type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
                Graph::QL::Schema::Field->new( name => 'month', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
                Graph::QL::Schema::Field->new( name => 'year',  type => Graph::QL::Schema::Type::Named->new( name => 'Int'    ) ),
            ]
        ),
        Graph::QL::Schema::Object->new(
            name   => 'BirthEvent',
            fields => [
                Graph::QL::Schema::Field->new( name => 'date',  type => Graph::QL::Schema::Type::Named->new( name => 'Date'   ) ),
                Graph::QL::Schema::Field->new( name => 'place', type => Graph::QL::Schema::Type::Named->new( name => 'String' ) ),
            ]
        ),
        Graph::QL::Schema::Object->new(
            name   => 'DeathEvent',
            fields => [
                Graph::QL::Schema::Field->new( name => 'date',  type => Graph::QL::Schema::Type::Named->new( name => 'Date'   ) ),
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
                    )
                ),
                Graph::QL::Schema::Field->new(
                    name => 'getAllPeople',
                    type => Graph::QL::Schema::Type::List->new(
                        of_type => Graph::QL::Schema::Type::Named->new(
                            name => 'Person'
                        )
                    )
                )
            ]
        )
    ]
);

subtest '... validating the query against the schema' => sub {

    my $operation = Graph::QL::Operation->new(
        definitions => [
            Graph::QL::Operation::Fragment->new(
                name           => 'BirthDay',
                type_condition => Graph::QL::Util::Schemas::construct_type_from_name('BirthEvent'),
                selections     => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'date',
                        selections => [
                            Graph::QL::Operation::Selection::Field->new( name => 'day' ),
                            Graph::QL::Operation::Selection::Field->new( name => 'month' ),
                            Graph::QL::Operation::Selection::Field->new( name => 'year' ),
                        ]
                    ),
                ]
            ),
            Graph::QL::Operation::Fragment->new(
                name           => 'YearOfDeath',
                type_condition => Graph::QL::Util::Schemas::construct_type_from_name('DeathEvent'),
                selections     => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'date',
                        selections => [
                            Graph::QL::Operation::Selection::Field->new( name => 'year' ),
                        ]
                    ),
                ]
            ),
            Graph::QL::Operation::Fragment->new(
                name           => 'BirthInfo',
                type_condition => Graph::QL::Util::Schemas::construct_type_from_name('Person'),
                selections     => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'birth',
                        selections => [
                            Graph::QL::Operation::Selection::FragmentSpread->new( name => 'BirthDay' ),
                        ]
                    )
                ]
            ),
            Graph::QL::Operation::Fragment->new(
                name           => 'DeathInfo',
                type_condition => Graph::QL::Util::Schemas::construct_type_from_name('Person'),
                selections     => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'death',
                        selections => [
                            Graph::QL::Operation::Selection::FragmentSpread->new( name => 'YearOfDeath' ),
                        ]
                    ),
                ]
            ),
            Graph::QL::Operation::Query->new(
                name       => 'findPersonNamedWill',
                selections => [
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'findPerson',
                        args       => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'name', value => 'Will' ) ],
                        selections => [
                            Graph::QL::Operation::Selection::Field->new( name => 'name' ),
                            Graph::QL::Operation::Selection::FragmentSpread->new( name => 'BirthInfo' ),
                            Graph::QL::Operation::Selection::FragmentSpread->new( name => 'DeathInfo' ),
                        ]
                    ),
                    Graph::QL::Operation::Selection::Field->new(
                        name       => 'getAllPeople',
                        selections => [
                            Graph::QL::Operation::Selection::Field->new( name => 'name' ),
                            Graph::QL::Operation::Selection::Field->new( name => 'gender' ),
                            Graph::QL::Operation::Selection::FragmentSpread->new( name => 'DeathInfo' ),
                        ]
                    )
                ]
            )
        ]
    );

    my $e = Graph::QL::Execution::ExecuteQuery->new(
        schema    => $schema,
        operation => $operation,
        resolvers => $resolvers,
        context   => {
            people => [
                {
                    displayname => 'Willem De Kooning',
                    gender      => 'Male',
                    culture     => 'Dutch',
                    datebegin   => 'April 24, 1904',
                    birthplace  => 'Rotterdam, Netherlands',
                    dateend     => 'March 19, 1997',
                    deathplace  => 'East Hampton, New York, U.S.',
                },
                {
                    displayname => 'Jackson Pollock',
                    gender      => 'Male',
                    culture     => 'United States',
                    datebegin   => 'January 28, 1912',
                    birthplace  => 'Cody, Wyoming, U.S.',
                    dateend     => 'August 11, 1956',
                    deathplace  => 'Springs, New York, U.S.',
                }
            ]
        }
    );
    isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

    is(exception { $e->validate }, undef, '... no exceptions while validating');
    ok(!$e->has_errors, '... no errors have been be found');

    my $result = $e->execute;

    eq_or_diff(
        $result,
        {
            findPerson => [
                {
                    name  => 'Willem De Kooning',
                    birth => {
                        date => {
                            day   => 24,
                            month => 'April',
                            year  => 1904,
                        }
                    },
                    death => {
                        date => {
                            year => 1997
                        }
                    },
                }
            ],
            getAllPeople => [
                {
                    name   => 'Willem De Kooning',
                    gender => 'Male',
                    death  => {
                        date => {
                            year => 1997
                        }
                    }
                },
                {
                    name   => 'Jackson Pollock',
                    gender => 'Male',
                    death  => {
                        date => {
                            year => 1956
                        }
                    }
                }
            ]
        },
        '... got the expected results of the query'
    );
};



done_testing;
