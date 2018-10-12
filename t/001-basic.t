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
    use_ok('Graph::QL::Operation');
    use_ok('Graph::QL::Execution::ExecuteQuery');

    use_ok('Graph::QL::Resolver::SchemaResolver');
    use_ok('Graph::QL::Resolver::TypeResolver');
    use_ok('Graph::QL::Resolver::FieldResolver');
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

package My::Schema::Resolvers::Query {
    use v5.24;
    use warnings;
    use experimental 'signatures', 'postderef';

    sub getAllPeople ($, $, $context, $) {
        $context->{people}
    }

    sub findPerson ($, $args, $context, $) {
        my $name = $args->{name};
        return [ grep { $_->{displayname} =~ /$name/ } $context->{people}->@* ]
    }
}

package My::Schema::Resolvers::Person {
    use v5.24;
    use warnings;
    use experimental 'signatures', 'postderef';

    sub name        ($data, $, $, $) { $data->{displayname} }
    sub nationality ($data, $, $, $) { $data->{culture}     }
    sub gender      ($data, $, $, $) { $data->{gender}      }
    sub birth       ($data, $, $, $) { $data }
    sub death       ($data, $, $, $) { $data }
}

package My::Schema::Resolvers::BirthEvent {
    use v5.24;
    use warnings;
    use experimental 'signatures', 'postderef';

    sub date  ($data, $, $, $) { Time::Piece->strptime( $data->{datebegin}, '%B %d, %Y' ) }
    sub place ($data, $, $, $) { $data->{birthplace} }
}

package My::Schema::Resolvers::DeathEvent {
    use v5.24;
    use warnings;
    use experimental 'signatures', 'postderef';

    sub date  ($data, $, $, $) { Time::Piece->strptime( $data->{dateend}, '%B %d, %Y' ) }
    sub place ($data, $, $, $) { $data->{deathplace} }
}

package My::Schema::Resolvers::Date {
    use v5.24;
    use warnings;
    use experimental 'signatures', 'postderef';

    sub day   ($data, $, $, $) { $data->mday      }
    sub month ($data, $, $, $) { $data->fullmonth }
    sub year  ($data, $, $, $) { $data->year      }
}

my $operation = Graph::QL::Operation->new_from_source(q[
    query TestQuery {
        findPerson( name : "Will" ) {
            name
            birth_date: birth {
                ...Birthday
            }
            death_year: death {
                ...YearOfDeath
            }
        }
        getAllPeople {
            name
            gender
            death {
                ...YearOfDeath
            }
        }
    }

    fragment YearOfDeath on DeathEvent {
        date { year }
    }

    fragment Birthday on BirthEvent {
        date { day, month, year }
    }
]);

my $e = Graph::QL::Execution::ExecuteQuery->new(
    schema    => $schema,
    operation => $operation,
    resolvers => Graph::QL::Resolver::SchemaResolver->new_from_namespace('My::Schema::Resolvers'),
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
                birth_date => {
                    date => {
                        day   => 24,
                        month => 'April',
                        year  => 1904,
                    }
                },
                death_year => {
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
