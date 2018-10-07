#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema::Directive');
    use_ok('Graph::QL::Schema::InputObject::InputValue');
    use_ok('Graph::QL::Util::Schemas');
    use_ok('Graph::QL::Parser');
}

subtest '... testing my schema' => sub {

    my $expected_type_language = q[directive @example(foo : Int = 10) on FIELD | QUERY];

    my $ExampleDirective = Graph::QL::Schema::Directive->new(
        name => 'example',
        args => [
            Graph::QL::Schema::InputObject::InputValue->new(
                name          => 'foo',
                type          => Graph::QL::Util::Schemas::construct_type_from_name('Int'),
                default_value => 10,
            )
        ],
        locations => [ 'FIELD', 'QUERY' ],
    );
    isa_ok($ExampleDirective, 'Graph::QL::Schema::Directive');

    eq_or_diff($ExampleDirective->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        #warn Dumper $expected_ast;

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast );

        #warn Dumper $expected_ast;

        eq_or_diff($ExampleDirective->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
