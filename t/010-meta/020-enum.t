#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Meta::Type::Enum');
    use_ok('Graph::QL::Meta::EnumValue');
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

    my $Direction = Graph::QL::Meta::Type::Enum->new(
        name        => 'Direction',
        enum_values => [
            Graph::QL::Meta::EnumValue->new( name => 'NORTH' ),
            Graph::QL::Meta::EnumValue->new( name => 'EAST'  ),
            Graph::QL::Meta::EnumValue->new( name => 'SOUTH' ),
            Graph::QL::Meta::EnumValue->new( name => 'WEST'  ),
        ]
    );

    #warn $schema->to_type_language;

    eq_or_diff($Direction->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');
};

done_testing;
