#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

use Parser::GraphQL::XS;
use JSON::MaybeXS;

use Graph::QL::Util::AST;


BEGIN {
    use_ok('Graph::QL::Schema::InputObject');
    use_ok('Graph::QL::Schema::InputObject::InputValue');
    use_ok('Graph::QL::Schema::Type::Named');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-45e4e
    my $expected_type_language =
'input Point2D {
    x : Float
    y : Float
}';

    my $Float = Graph::QL::Schema::Type::Named->new( name => 'Float' );

    my $Point2D = Graph::QL::Schema::InputObject->new(
        name   => 'Point2D',
        fields => [
            Graph::QL::Schema::InputObject::InputValue->new( name => 'x', type => $Float ),
            Graph::QL::Schema::InputObject::InputValue->new( name => 'y', type => $Float ),
        ]
    );

    #warn $Point2D->to_type_language;

    eq_or_diff($Point2D->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = JSON::MaybeXS->new->decode(
            Parser::GraphQL::XS->new->parse_string( $expected_type_language )
        )->{definitions}->[0];

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast, 'fields.type' );
        #warn Dumper $expected_ast;

        eq_or_diff($Point2D->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };
};

done_testing;
