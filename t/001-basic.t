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

my @People = (
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
);

my $e = Graph::QL::Execution::ExecuteQuery->new(
    schema    => $schema,
    query     => $query,
    resolvers => {
        Query => {
            getAllPeople => sub ($, $) { [ @People ] },
            findPerson   => sub ($, $args) {
                my $name = $args->{name};
                return [ grep { $_->{displayname} =~ /$name/ } @People ]
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
            date  => sub ($data, $) { Time::Piece->strptime( $data->{datebegin}, '%B %d, %Y' ) },
            place => sub ($data, $) { $data->{birthplace} },
        },
        DeathEvent => {
            date  => sub ($data, $) { Time::Piece->strptime( $data->{dateend}, '%B %d, %Y' ) },
            place => sub ($data, $) { $data->{deathplace} },
        },
        Date => {
            day   => sub ($data, $) { $data->mday      },
            month => sub ($data, $) { $data->fullmonth },
            year  => sub ($data, $) { $data->year      },
        }
    }
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
