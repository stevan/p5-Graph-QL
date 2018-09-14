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

    use_ok('Graph::QL::Schema::Type::Union');
    use_ok('Graph::QL::Schema::Type::Named');

    use_ok('Graph::QL::Schema::Field');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-255de
    my $expected_type_language = q[union SearchResult = Photo | Person];

    my $Person = Graph::QL::Schema::Type::Named->new( name => 'Person' );
    my $Photo  = Graph::QL::Schema::Type::Named->new( name => 'Photo' );

    my $SearchResult = Graph::QL::Schema::Type::Union->new(
        name  => 'SearchResult',
        types => [ $Photo, $Person ]
    );

    is_deeply($SearchResult->name, 'SearchResult', '... got the expected name');
    is_deeply($SearchResult->types, [ $Photo, $Person ], '... got the expected types');

    #warn $SearchResult->to_type_language;

    eq_or_diff($SearchResult->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');


    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = JSON::MaybeXS->new->decode(
            Parser::GraphQL::XS->new->parse_string( $expected_type_language )
        )->{definitions}->[0];

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast, 'types' );

        #warn Dumper $expected_ast;

        eq_or_diff($SearchResult->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
