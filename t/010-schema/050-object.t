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
    isa_ok($Person, 'Graph::QL::Schema::Object');

    subtest '... checking the object details' => sub {
        is($Person->name, 'Person', '... got the name we expect');

        my $name = $Person->lookup_field('name');
        my $age  = $Person->lookup_field('age');

        isa_ok($name, 'Graph::QL::Schema::Field');
        isa_ok($age,  'Graph::QL::Schema::Field');

        is($name->name, 'name', '... got the name we expect');
        is($age->name,  'age',  '... got the name we expect');

        is($name->type->name, $String->name, '... got the type we expect');
        is($age->type->name, $Int->name, '... got the type we expect');

        ok($age->has_args, '... the age has args');
    };

    #warn $Person->to_type_language;

    eq_or_diff($Person->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        #warn Dumper $expected_ast;

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast );

        #warn Dumper $expected_ast;

        eq_or_diff($Person->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
