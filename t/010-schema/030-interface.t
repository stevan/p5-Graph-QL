#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Interface');
    use_ok('Graph::QL::Schema::Type::Named');
    use_ok('Graph::QL::Schema::Field');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-ab5e5
    my $expected_type_language =
q[interface NamedEntity {
    name : String
    type : EntityType
}];

    my $EntityType = Graph::QL::Schema::Type::Named->new( name => 'EntityType' );
    my $String     = Graph::QL::Schema::Type::Named->new( name => 'String' );

    my $NamedEntity = Graph::QL::Schema::Interface->new(
        name   => 'NamedEntity',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name', type => $String ),
            Graph::QL::Schema::Field->new( name => 'type', type => $EntityType ),
        ]
    );
    isa_ok($NamedEntity, 'Graph::QL::Schema::Interface');

    subtest '... checking the interface details' => sub {
        is($NamedEntity->name, 'NamedEntity', '... got the name we expect');

        my $name = $NamedEntity->lookup_field('name');
        my $type = $NamedEntity->lookup_field('type');

        isa_ok($name, 'Graph::QL::Schema::Field');
        isa_ok($type, 'Graph::QL::Schema::Field');

        is($name->name, 'name', '... got the name we expect');
        is($type->name, 'type', '... got the name we expect');

        is($name->type->name, $String->name, '... got the type we expect');
        is($type->type->name, $EntityType->name, '... got the type we expect');
    };

    #warn $NamedEntity->to_type_language;

    eq_or_diff($NamedEntity->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        #warn Dumper $expected_ast;

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast );

        #warn Dumper $expected_ast;

        eq_or_diff($NamedEntity->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
