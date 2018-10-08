#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');
    use_ok('Graph::QL::Util::Schemas');

    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::InputObject::InputValue');

    use_ok('Graph::QL::Directive');
    use_ok('Graph::QL::Operation::Selection::Field::Argument');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}


subtest '... testing my schema' => sub {

    my $expected_type_language =
q[type AnnotatedObject @onObject(arg : "value") {
    annotatedField(arg : String = "default" @onArg) : Type @onField
}];

    my $AnnotatedObject = Graph::QL::Schema::Object->new(
        name   => 'AnnotatedObject',
        fields => [
            Graph::QL::Schema::Field->new(
                name => 'annotatedField',
                args => [
                    Graph::QL::Schema::InputObject::InputValue->new(
                        name          => 'arg',
                        type          => Graph::QL::Util::Schemas::construct_type_from_name('String'),
                        default_value => 'default',
                        directives    => [ Graph::QL::Directive->new( name => 'onArg' ) ]
                    )
                ],
                type       => Graph::QL::Util::Schemas::construct_type_from_name('Type'),
                directives => [ Graph::QL::Directive->new( name => 'onField' ) ]
            ),
        ],
        directives => [
            Graph::QL::Directive->new(
                name => 'onObject',
                args => [
                    Graph::QL::Operation::Selection::Field::Argument->new(
                        name  => 'arg',
                        value => 'value',
                    )
                ]
            )
        ]
    );
    isa_ok($AnnotatedObject, 'Graph::QL::Schema::Object');

    #warn $AnnotatedObject->to_type_language;

    eq_or_diff($AnnotatedObject->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        #warn Dumper $expected_ast;

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast );

        #warn Dumper $expected_ast;

        eq_or_diff($AnnotatedObject->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
