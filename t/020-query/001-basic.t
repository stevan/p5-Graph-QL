#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL');

    use_ok('Graph::QL::Parser');

    use_ok('Graph::QL::Operation::Query');
    use_ok('Graph::QL::Operation::Field');
    use_ok('Graph::QL::Operation::Field::Argument');
    use_ok('Graph::QL::Operation::Fragment::Spread');
}

subtest '... single root query' => sub {

    my $source =
q[query queryName {
    find(id : 4) {
        id
        name
        ...OtherUserDetails
    }
}];

    my $query = Graph::QL::Operation::Query->new(
        name       => 'queryName',
        selections => [
            Graph::QL::Operation::Field->new(
                name       => 'find',
                args       => [ Graph::QL::Operation::Field::Argument->new( name => 'id', value => 4 ) ],
                selections => [
                    Graph::QL::Operation::Field->new( name => 'id' ),
                    Graph::QL::Operation::Field->new( name => 'name' ),
                    Graph::QL::Operation::Fragment::Spread->new( name => 'OtherUserDetails' ),
                ]
            )
        ]
    );
    isa_ok($query, 'Graph::QL::Operation::Query');

    ok($query->has_name, '... this is not an ANON query');
    is($query->name, 'queryName', '... got the name');

    ok(Graph::QL::Core::OperationKind->is_operation_kind($query->operation_kind), '... we have a valid operation kind');
    is($query->operation_kind, Graph::QL::Core::OperationKind->QUERY, '... and it is the operation kind we expected');

    eq_or_diff($query->to_type_language, $source, '... got the expected type language');

    subtest '... now parse the expected string and strip the location from the AST' => sub {
        my $expected_ast = Graph::QL::Parser->parse_raw( $source );

        Graph::QL::Util::AST::null_out_source_locations( $expected_ast );

        eq_or_diff($query->ast->TO_JSON, $expected_ast, '... got the expected AST');
    };
};

done_testing;
