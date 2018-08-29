#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');
}

use decorators 'Graph::QL::Decorators';

my $schema = Graph::QL::Schema->new_from_typed_resolvers(
    {
        BirthEvent => {
            date  => sub ($parent) : Type(String!) { $parent->{datebegin}  },
            place => sub ($parent) : Type(String!) { $parent->{birthplace} },
        },
        DeathEvent => {
            date  => sub ($parent) : Type(String!) { $parent->{dateend}    },
            place => sub ($parent) : Type(String!) { $parent->{deathplace} },
        },
        Person => {
            name        => sub ($parent) : Type(String!)     { $parent->{displayname} },
            gender      => sub ($parent) : Type(String!)     { $parent->{gender}      },
            nationality => sub ($parent) : Type(String!)     { $parent->{culture}     },
            birth       => sub ($parent) : Type(BirthEvent!) { $parent },
            death       => sub ($parent) : Type(DeathEvent!) { $parent },
            friends     => sub ($parent) : Type([Person]!)   { $parent->{friends} },
        }
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

my $transform = $schema->resolve( 'Person', $de_kooning );

# diag 'START:';
# diag Dumper $de_kooning;
# diag 'END:';
# diag Dumper $transform;

my $result = {
    name        => 'Willem De Kooning',
    gender      => 'Male',
    nationality => 'Dutch',
    friends     => [
        {
            name        => 'Jackson Pollock',
            gender      => 'Male',
            nationality => 'United States',
            friends     => [],
            birth       => {
                date  => 'January 28, 1912',
                place => 'Cody, Wyoming, United States',
            },
            death       => {
                date   => 'August 11, 1956',
                place  => 'Springs, New York, United States',,
            },
        }
    ],
    birth => {
        date  => 'April 24, 1904',
        place => 'Rotterdam, Netherlands',
    },
    death => {
        date  => 'March 19, 1997',
        place => 'East Hampton, New York, U.S.',
    },
};

$result->{friends}->[0]->{friends}->[0] = $result;

#use Data::Dumper;
#warn Dumper $result;
#warn Dumper $transform;

is_deeply(
    $transform,
    $result,
    '... transformed the input into the expeted output'
);

done_testing;
