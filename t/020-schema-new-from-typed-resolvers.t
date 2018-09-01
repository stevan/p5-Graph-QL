#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');
    use_ok('Graph::QL::Field');
    use_ok('Graph::QL::Resolver');
    use_ok('Graph::QL::Query');
}

use decorators 'Graph::QL::Decorators';

my $schema = Graph::QL::Schema->new_from_typed_resolvers(
    {
        BirthEvent => {
            date  => sub ($data) : Type(String!) { $data->{datebegin}  },
            place => sub ($data) : Type(String!) { $data->{birthplace} },
        },
        DeathEvent => {
            date  => sub ($data) : Type(String!) { $data->{dateend}    },
            place => sub ($data) : Type(String!) { $data->{deathplace} },
        },
        Person => {
            name        => sub ($data) : Type(String!)     { $data->{displayname} },
            gender      => sub ($data) : Type(String!)     { $data->{gender}      },
            nationality => sub ($data) : Type(String!)     { $data->{culture}     },
            birth       => sub ($data) : Type(BirthEvent!) { $data },
            death       => sub ($data) : Type(DeathEvent!) { $data },
            friends     => sub ($data) : Type([Person]!)   { $data->{friends} },
        }
    }
);

my $query = Graph::QL::Query->new(
    name   => 'lookup_artist',
    fields => {
        name    => 1,
        friends => {
            name  => 1,
            birth => { date => 1, place => 1 },
            death => { date => 1 }
        },
        birth => { date => 1, place => 1 },
        death => { date => 1 },
    }
);

my $de_kooning = {
    displayname => 'Willem De Kooning',
    gender      => 'Male',
    culture     => 'Dutch',
    datebegin   => 'April 24, 1904',
    birthplace  => 'Rotterdam, Netherlands',
    dateend     => 'March 19, 1997',
    deathplace  => 'East Hampton, New York, U.S.',
    friends     => [],
};

my $pollock = {
    displayname => 'Jackson Pollock',
    gender      => 'Male',
    culture     => 'United States',
    datebegin   => 'January 28, 1912',
    birthplace  => 'Cody, Wyoming, United States',
    dateend     => 'August 11, 1956',
    deathplace  => 'Springs, New York, United States',
    friends     => [],
};

$de_kooning->{friends}->[0] = $pollock;
$pollock->{friends}->[0] = $de_kooning;

my $transform = $schema->resolve( 'Person', $de_kooning, $query );

# diag 'START:';
# diag Dumper $de_kooning;
# diag 'END:';
# diag Dumper $transform;

my $result = {
    name        => 'Willem De Kooning',
    # gender      => 'Male',
    # nationality => 'Dutch',
    friends     => [
        {
            name        => 'Jackson Pollock',
            # gender      => 'Male',
            # nationality => 'United States',
            # friends     => [],
            birth       => {
                date  => 'January 28, 1912',
                place => 'Cody, Wyoming, United States',
            },
            death       => {
                date   => 'August 11, 1956',
                # place  => 'Springs, New York, United States',,
            },
        }
    ],
    birth => {
        date  => 'April 24, 1904',
        place => 'Rotterdam, Netherlands',
    },
    death => {
        date  => 'March 19, 1997',
        # place => 'East Hampton, New York, U.S.',
    },
};

# use Data::Dumper;
# warn Dumper $result;
# warn Dumper $transform;

is_deeply(
    $transform,
    $result,
    '... transformed the input into the expeted output'
);

done_testing;
