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
}

my $schema = Graph::QL::Schema->new(
    types => {
        BirthEvent => {
            date  => Graph::QL::Field->new( type => 'String!', resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{datebegin}  } ) ),
            place => Graph::QL::Field->new( type => 'String!', resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{birthplace} } ) ),
        },
        DeathEvent => {
            date  => Graph::QL::Field->new( type => 'String!', resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{dateend}    } ) ),
            place => Graph::QL::Field->new( type => 'String!', resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{deathplace} } ) ),
        },
        Person => {
            name        => Graph::QL::Field->new( type => 'String!',     resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{displayname} } ) ),
            gender      => Graph::QL::Field->new( type => 'String!',     resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{gender}      } ) ),
            nationality => Graph::QL::Field->new( type => 'String!',     resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent->{culture}     } ) ),
            birth       => Graph::QL::Field->new( type => 'BirthEvent!', resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent } ) ),
            death       => Graph::QL::Field->new( type => 'DeathEvent!', resolver => Graph::QL::Resolver->new( body => sub ($parent) { $parent } ) ),
            friends     => Graph::QL::Field->new( type => '[Person]!',   resolver => Graph::QL::Resolver->new( body => sub ($parent) { [ $parent->{friends}->@* ] } ) ),
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
