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
    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Field');
    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Util::JSON');
    use_ok('Graph::QL::Schema::Type::Named');
    use_ok('Graph::QL::Schema::InputObject::InputValue');
}

my $source = q[
type Test {
	foo(
		bar : ComplexType = { 
			foo   : 10, 
			bar   : "hello",
			baz   : [ 1, 2, "three" ],
			gorch : { test : [], things: 10.5 },
			bing  : false,
			bong  : true
		}
	) : Int
}
];

my $node = Graph::QL::Parser->parse_raw( $source );
Graph::QL::Util::AST::prune_source_locations( $node );

my $type = Graph::QL::Schema::Object->new(
    name       => 'Test',
    fields     => [
        Graph::QL::Schema::Field->new(
            name => 'foo',
            type => Graph::QL::Schema::Type::Named->new( name => 'Int' ),
            args => [ 
            	Graph::QL::Schema::InputObject::InputValue->new( 
            		name          => 'bar', 
            		type          => Graph::QL::Schema::Type::Named->new( name => 'ComplexType' ),
            		default_value => {
						bar   => "hello",
						baz   => [ 1, 2, "three" ],
                        bing  => Graph::QL::Util::JSON->FALSE,
                        bong  => Graph::QL::Util::JSON->TRUE,                        
                        foo   => 10, 
						gorch => { test => [], things => 10.5 },
            		}
            	) 
            ],
        )
    ]
);
isa_ok($type, 'Graph::QL::Schema::Object');

my $result = $type->ast->TO_JSON;
Graph::QL::Util::AST::prune_source_locations( $result );

my $node_result = $node->{definitions}->[0];

#use Data::Dumper;
#warn Dumper $node_result;

$node_result->{fields}->[0]->{arguments}->[0]->{defaultValue}->{fields}->@* = sort { 
    $a->{name}->{value} cmp $b->{name}->{value}
} $node_result->{fields}->[0]->{arguments}->[0]->{defaultValue}->{fields}->@*;

#warn Dumper $node_result;

eq_or_diff_data($result, $node_result, '... the type language roundtripped');

done_testing;
