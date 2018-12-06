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
    use_ok('Graph::QL::Util::AST');
}

my $source = q[
type Test {
	foo(
		bar : ComplexType = { 
			foo   : 10, 
			bar   : "hello",
			baz   : [ 1, 2, "three" ],
			gorch : { test : [], things: 10.5 }
		}
	) : Int
}
];

my $node = Graph::QL::Parser->parse_raw( $source );
Graph::QL::Util::AST::prune_source_locations( $node );

warn Dumper $node; 

done_testing;
