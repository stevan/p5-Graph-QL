#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Type::Named');

    use_ok('Graph::QL::Schema::Field');
    use_ok('Graph::QL::Schema::InputObject::InputValue');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-ab5e5
    my $expected_type_language =
q[type Person {
    name : String
    age(in_months : Int = 0) : Int
}];

    my $Int    = Graph::QL::Schema::Type::Named->new( name => 'Int' );
    my $String = Graph::QL::Schema::Type::Named->new( name => 'String' );

    my $Person = Graph::QL::Schema::Object->new(
        name   => 'Person',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name', type => $String ),
            Graph::QL::Schema::Field->new(
                name => 'age',
                type => $Int,
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name          => 'in_months',
                        type          => $Int,
                        default_value => 0
                    )
                ]
            ),
        ]
    );

    #warn $Person->to_type_language;

    eq_or_diff($Person->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        #warn Dumper $expected_ast;

        Graph::QL::Util::AST::null_out_source_locations(
            $expected_ast,
            'fields.type',
            'fields.arguments.type',
            'fields.arguments.defaultValue',
        );

        #warn Dumper $expected_ast;

        eq_or_diff($Person->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
