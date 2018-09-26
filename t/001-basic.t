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
    use_ok('Graph::QL::Operation::Query');
    use_ok('Graph::QL::Execution::ExecuteQuery');

    use_ok('Graph::QL::Resolvers');
    use_ok('Graph::QL::Resolvers::TypeResolver');
    use_ok('Graph::QL::Resolvers::FieldResolver');
}

my $schema = Graph::QL::Schema->new_from_source(q[
    scalar Int
    scalar String

    type Date {
        day   : String
        month : String
        year  : Int
    }

    type BirthEvent {
        date  : Date
        place : String
    }

    type DeathEvent {
        date  : Date
        place : String
    }

    type Person {
        name        : String
        nationality : String
        gender      : String
        birth       : BirthEvent
        death       : DeathEvent
    }

    type Query {
        findPerson( name : String ) : [Person]
        getAllPeople : [Person]
    }

    schema {
        query : Query
    }
]);

my $query = Graph::QL::Operation::Query->new_from_source(q[
    query TestQuery {
        findPerson( name : "Will" ) {
            name
            birth {
                date {
                    day
                    month
                    year
                }
            }
            death {
                date {
                    year
                }
            }
        }
        getAllPeople {
            name
            gender
            death {
                date {
                    year
                }
            }
        }
    }
]);

my $e = Graph::QL::Execution::ExecuteQuery->new(
    schema    => $schema,
    query     => $query,
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
    },
    resolvers => Graph::QL::Resolvers->new(
        types => [
            Graph::QL::Resolvers::TypeResolver->new(
                name   => 'Query',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'getAllPeople', code => sub ($, $, $context, $) { $context->{people} } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'findPerson',   code => sub ($, $args, $context, $) {
                        my $name = $args->{name};
                        return [ grep { $_->{displayname} =~ /$name/ } $context->{people}->@* ]
                    }),
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => 'Person',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'name',        code => sub ($data, $, $, $) { $data->{displayname} } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'nationality', code => sub ($data, $, $, $) { $data->{culture}     } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'gender',      code => sub ($data, $, $, $) { $data->{gender}      } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'birth',       code => sub ($data, $, $, $) { $data } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'death',       code => sub ($data, $, $, $) { $data } ),
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => 'BirthEvent',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'date',  code => sub ($data, $, $, $) { Time::Piece->strptime( $data->{datebegin}, '%B %d, %Y' ) } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'place', code => sub ($data, $, $, $) { $data->{birthplace} } ),
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => 'DeathEvent',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'date',  code => sub ($data, $, $, $) { Time::Piece->strptime( $data->{dateend}, '%B %d, %Y' ) } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'place', code => sub ($data, $, $, $) { $data->{deathplace} } ),
                ]
            ),
            Graph::QL::Resolvers::TypeResolver->new(
                name   => 'Date',
                fields => [
                    Graph::QL::Resolvers::FieldResolver->new( name => 'day',   code => sub ($data, $, $, $) { $data->mday      } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'month', code => sub ($data, $, $, $) { $data->fullmonth } ),
                    Graph::QL::Resolvers::FieldResolver->new( name => 'year',  code => sub ($data, $, $, $) { $data->year      } ),
                ]
            )
        ]
    )
);
isa_ok($e, 'Graph::QL::Execution::ExecuteQuery');

ok($e->validate, '... the schema and query validated correctly');
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



done_testing;
