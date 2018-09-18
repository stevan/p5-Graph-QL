#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;

use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Union');
    use_ok('Graph::QL::Schema::Type::Named');

    use_ok('Graph::QL::Schema::Field');

    use_ok('Graph::QL::Util::AST');
    use_ok('Graph::QL::Parser');
}

subtest '... testing my schema' => sub {

    # http://facebook.github.io/graphql/June2018/#example-255de
    my $expected_type_language = q[union SearchResult = Photo | Person];

    my $Person = Graph::QL::Schema::Type::Named->new( name => 'Person' );
    my $Photo  = Graph::QL::Schema::Type::Named->new( name => 'Photo' );

    my $SearchResult = Graph::QL::Schema::Union->new(
        name  => 'SearchResult',
        types => [ $Photo, $Person ]
    );

    is_deeply($SearchResult->name, 'SearchResult', '... got the expected name');
    is_deeply($SearchResult->all_types, [ $Photo, $Person ], '... got the expected types');

    #warn $SearchResult->to_type_language;
    eq_or_diff($SearchResult->to_type_language, $expected_type_language, '... got the pretty printed schema as expected');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $expected_type_language )->{definitions}->[0];

        #warn Dumper $expected_ast;
        Graph::QL::Util::AST::null_out_source_locations( $expected_ast, 'types' );

        eq_or_diff($SearchResult->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };

};

done_testing;
