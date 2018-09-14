#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema::Enum');
    use_ok('Graph::QL::Schema::Enum::EnumValue');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-36555
    my $expected_type_language =
'enum Direction {
    NORTH
    EAST
    SOUTH
    WEST
}';

    my $Direction = Graph::QL::Schema::Enum->new(
        name   => 'Direction',
        values => [
            Graph::QL::Schema::Enum::EnumValue->new( name => 'NORTH' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'EAST'  ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'SOUTH' ),
            Graph::QL::Schema::Enum::EnumValue->new( name => 'WEST'  ),
        ]
    );

    #warn $Direction->to_type_language;
    #warn Dumper $Direction->ast->TO_JSON;

    eq_or_diff($Direction->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast, 'values' );

        eq_or_diff($Direction->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };
};

done_testing;
