#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');
}

use Parser::GraphQL::XS;
use JSON::MaybeXS;

my $schema = q[
    type Query {
        findPerson(name: String) : [Person]
    }

    type BirthEvent {
        year  : Int
        place : String
    }

    type DeathEvent {
        year  : Int
        place : String
    }

    type Person {
        name        : String
        nationality : String
        gender      : String
        birth       : BirthEvent
        death       : DeathEvent
    }
];

my $parser = Parser::GraphQL::XS->new;
my $json   = $parser->parse_string( $schema );
my $ast    = JSON::MaybeXS->new->decode( $json );





warn Dumper $ast;

done_testing;
