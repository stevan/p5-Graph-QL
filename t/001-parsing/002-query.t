#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');
    use_ok('Graph::QL::AST::Builder');
}

use Parser::GraphQL::XS;
use JSON::MaybeXS;

my $schema = q[
query queryName {
    find(id: 4) {
        id
        name
    }
}
];

my $parser = Parser::GraphQL::XS->new;
my $json   = $parser->parse_string( $schema );
my $ast    = JSON::MaybeXS->new->decode( $json );

my $node = Graph::QL::AST::Builder->build_from_ast( $ast );

#warn Dumper $node->TO_JSON;

eq_or_diff($node->TO_JSON, $ast, '... round-tripped the ast');

done_testing;
