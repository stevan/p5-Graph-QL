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
    # typemap => {
    #     BirthEvent => {
    #         date  => 'Scalar',
    #         place => 'Scalar',
    #     },
    #     DeathEvent => {
    #         date  => 'Scalar',
    #         place => 'Scalar',
    #     },
    #     Person => {
    #         name        => 'Scalar',
    #         gender      => 'Scalar',
    #         nationality => 'Scalar',
    #         birth       => 'BirthEvent',
    #         death       => 'DeathEvent',
    #     }
    # },
    # resolvers =>
    {
        BirthEvent => {
            date  => sub ($parent) : Type(Scalar) { $parent->{datebegin}  },
            place => sub ($parent) : Type(Scalar) { $parent->{birthplace} },
        },
        DeathEvent => {
            date  => sub ($parent) : Type(Scalar) { $parent->{dateend}    },
            place => sub ($parent) : Type(Scalar) { $parent->{deathplace} },
        },
        Person => {
            name        => sub ($parent) : Type(Scalar)     { $parent->{displayname} },
            gender      => sub ($parent) : Type(Scalar)     { $parent->{gender}      },
            nationality => sub ($parent) : Type(Scalar)     { $parent->{culture}     },
            birth       => sub ($parent) : Type(BirthEvent) { $parent },
            death       => sub ($parent) : Type(DeathEvent) { $parent },
        }
    }
);


my $start = {
    displayname => 'Willem De Kooning',
    gender      => 'Male',
    culture     => 'Dutch',
    datebegin   => 'April 24, 1904',
    birthplace  => 'Rotterdam, Netherlands',
    dateend     => 'March 19, 1997',
    deathplace  => 'East Hampton, New York, U.S.',
};

my $transform = $schema->resolve( 'Person', $start );

diag 'START:';
diag Dumper $start;
diag 'END:';
diag Dumper $transform;

is_deeply(
    $transform,
    {
        name        => 'Willem De Kooning',
        gender      => 'Male',
        nationality => 'Dutch',
        birth       => {
            date  => 'April 24, 1904',
            place => 'Rotterdam, Netherlands',
        },
        death       => {
            date   => 'March 19, 1997',
            place  => 'East Hampton, New York, U.S.',
        }
    },
    '... transformed the input into the expeted output'
);

done_testing;
