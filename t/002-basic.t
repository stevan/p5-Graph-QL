#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Test::More;
use Test::Differences;
use Test::Fatal;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');
    use_ok('Graph::QL::Schema');
    use_ok('Graph::QL::Operation');
    use_ok('Graph::QL::Resolver::SchemaResolver');
    use_ok('Graph::QL::Execution::ExecuteQuery');
}

package MyApp::Schema::Query {
    use v5.24;
    use warnings;
    use decorators 'Graph::QL::Util::Decorators';

    sub findPerson : Arguments( name : String ) Field( [Person] ) {
        my (undef, $args, $context) = @_;
        my $name = $args->{name};
        return [ grep { $_->{displayname} =~ /$name/ } $context->{people}->@* ]
    }
}

package MyApp::Schema::Date {
    use v5.24;
    use warnings;
    use decorators 'Graph::QL::Util::Decorators';

    sub year  : Field(Int)    { $_[0]->year      }
    sub month : Field(String) { $_[0]->fullmonth }
    sub day   : Field(String) { $_[0]->mday      }
}

package MyApp::Schema::BirthEvent {
    use v5.24;
    use warnings;
    use decorators 'Graph::QL::Util::Decorators';

    use Time::Piece;

    sub date  : Field(Date)   { Time::Piece->strptime( $_[0]->{datebegin}, '%B %d, %Y' ) }
    sub place : Field(String) { $_[0]->{birthplace} }
}

package MyApp::Schema::DeathEvent {
    use v5.24;
    use warnings;
    use decorators 'Graph::QL::Util::Decorators';

    use Time::Piece;

    sub date  : Field(Date)   { Time::Piece->strptime( $_[0]->{dateend}, '%B %d, %Y' ) }
    sub place : Field(String) { $_[0]->{deathplace} }
}

package MyApp::Schema::Person {
    use v5.24;
    use warnings;
    use decorators 'Graph::QL::Util::Decorators';

    sub name        : Field(String)     { $_[0]->{displayname} }
    sub nationality : Field(String)     { $_[0]->{culture}     }
    sub gender      : Field(String)     { $_[0]->{gender}      }
    sub birth       : Field(BirthEvent) { $_[0] }
    sub death       : Field(DeathEvent) { $_[0] }
}

my $schema    = Graph::QL::Schema->new_from_namespace( 'MyApp::Schema' );
my $resolvers = Graph::QL::Resolver::SchemaResolver->new_from_namespace( 'MyApp::Schema' );
my $operation = Graph::QL::Operation->new_from_source(qq[
    {
        findPerson(name:"Jackson Pollock") {
            name
            nationality
            gender
            birth {
                ...BirthYearAndPlace
            }
            death {
                ...DeathPlace
            }
        }
    }

    fragment BirthYearAndPlace on BirthEvent {
        place
        date { year }
    }

    fragment DeathPlace on DeathEvent {
        place
    }
]);

#warn $schema->to_type_language;

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
                name        => 'Jackson Pollock',
                nationality => 'United States',
                gender      => 'Male',
                birth => {
                    date  => { year  => 1912 },
                    place => 'Cody, Wyoming, U.S.',
                },
                death => {
                    place => 'Springs, New York, U.S.'
                }
            }
        ]
    },
    '... got the exected results'
);

#warn Dumper $result;

done_testing;

