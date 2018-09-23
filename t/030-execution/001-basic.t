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

our @DATASET = (
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
        birthplace  => 'Cody, Wyoming, United States',
        dateend     => 'August 11, 1956',
        deathplace  => 'Springs, New York, United States',
    }
);

my $strptime = '%B %d, %Y';

my $resolvers = {
    Query => {
        getAllPeople => sub ($, $) { [ @DATASET ] },
        findPerson   => sub ($, $args) {
            my $name = $args->{name};
            return [ grep { $_->{displayname} =~ /$name/ } @DATASET ]
        },
    },
    Person => {
        name        => sub ($data, $) { $data->{displayname} },
        nationality => sub ($data, $) { $data->{culture}     },
        gender      => sub ($data, $) { $data->{gender}      },
        birth       => sub ($data, $) { $data },
        death       => sub ($data, $) { $data },
    },
    BirthEvent => {
        date  => sub ($data, $) { Time::Piece->strptime( $data->{datebegin}, $strptime ) },
        place => sub ($data, $) { $data->{birthplace} },
    },
    DeathEvent => {
        date  => sub ($data, $) { Time::Piece->strptime( $data->{dateend}, $strptime ) },
        place => sub ($data, $) { $data->{deathplace} },
    },
    Date => {
        day   => sub ($data, $) { $data->mday      },
        month => sub ($data, $) { $data->fullmonth },
        year  => sub ($data, $) { $data->year      },
    }
};

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

    my $query = Graph::QL::Operation::Query->new(
        name       => 'findPersonNamedWill',
        selections => [
            Graph::QL::Operation::Field->new(
                name       => 'findPerson',
                args       => [ Graph::QL::Operation::Field::Argument->new( name => 'name', value => 'Will' ) ],
                selections => [
                    Graph::QL::Operation::Field->new( name => 'name' ),
                    Graph::QL::Operation::Field->new(
                        name       => 'birth',
                        selections => [
                            Graph::QL::Operation::Field->new(
                                name       => 'date',
                                selections => [
                                    Graph::QL::Operation::Field->new( name => 'day' ),
                                    Graph::QL::Operation::Field->new( name => 'month' ),
                                    Graph::QL::Operation::Field->new( name => 'year' ),
                                ]
                            ),
                        ]
                    ),
                    Graph::QL::Operation::Field->new(
                        name       => 'death',
                        selections => [
                            Graph::QL::Operation::Field->new(
                                name       => 'date',
                                selections => [
                                    Graph::QL::Operation::Field->new( name => 'year' ),
                                ]
                            ),
                        ]
                    ),
                ]
            ),
            Graph::QL::Operation::Field->new(
                name       => 'getAllPeople',
                selections => [
                    Graph::QL::Operation::Field->new( name => 'name' ),
                    Graph::QL::Operation::Field->new( name => 'gender' ),
                    Graph::QL::Operation::Field->new(
                        name       => 'death',
                        selections => [
                            Graph::QL::Operation::Field->new(
                                name       => 'date',
                                selections => [
                                    Graph::QL::Operation::Field->new( name => 'year' ),
                                ]
                            ),
                        ]
                    ),
                ]
            )
        ]
    );

    my $e = Graph::QL::Execution::ExecuteQuery->new(
        schema    => $schema,
        query     => $query,
        resolvers => $resolvers,
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
