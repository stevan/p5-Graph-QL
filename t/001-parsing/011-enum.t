#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');
    use_ok('Graph::QL::Parser');
}

my $schema = q[
enum Directions {
    NORTH
    SOUTH
    EAST
    WEST
}
];

my $node = Graph::QL::Parser->parse( $schema );
my $ast  = JSON::MaybeXS->new->decode( Parser::GraphQL::XS->new->parse_string( $schema ) );

#warn Dumper $node->TO_JSON;

eq_or_diff($node->TO_JSON, $ast, '... round-tripped the ast');

done_testing;
