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
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Type::Interface');
    use_ok('Graph::QL::Schema::Type::Named');

    use_ok('Graph::QL::Schema::Field');
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

    my $NamedEntity = Graph::QL::Schema::Type::Interface->new(
        name   => 'NamedEntity',
        fields => [
            Graph::QL::Schema::Field->new( name => 'name', type => $String ),
            Graph::QL::Schema::Field->new( name => 'type', type => $EntityType ),
        ]
    );

    #warn $NamedEntity->to_type_language;

    eq_or_diff($NamedEntity->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = JSON::MaybeXS->new->decode(
            Parser::GraphQL::XS->new->parse_string( $expected_type_language )
        )->{definitions}->[0];

        #warn Dumper $expected_ast;

        Graph::QL::Util::AST::null_out_source_locations(
            $expected_ast,
            'fields.type',
        );

        #warn Dumper $expected_ast;

        eq_or_diff($NamedEntity->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
