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
    use_ok('Graph::QL::Operation::Selection::Field');
    use_ok('Graph::QL::Operation::Selection::Field::Argument');

    use_ok('Graph::QL::AST::Node::Document');
    use_ok('Graph::QL::AST::Node::OperationDefinition');
    use_ok('Graph::QL::AST::Node::Name');
    use_ok('Graph::QL::AST::Node::SelectionSet');
    use_ok('Graph::QL::AST::Node::Field');
    use_ok('Graph::QL::AST::Node::Argument');
    use_ok('Graph::QL::AST::Node::IntValue');
}

my $schema = q[
query queryName {
    find(id: 4) {
        id
        name
    }
}
];

my $node = Graph::QL::Parser->parse( $schema );
my $ast  = JSON::MaybeXS->new->decode( Parser::GraphQL::XS->new->parse_string( $schema ) );

#warn Dumper $node->TO_JSON;

eq_or_diff($node->TO_JSON, $ast, '... round-tripped the ast');

Graph::QL::Util::AST::null_out_source_locations( $ast );

my $node_2 = Graph::QL::AST::Node::OperationDefinition->new(
    operation     => 'query',
    name          => Graph::QL::AST::Node::Name->new( value => 'queryName' ),
    selection_set => Graph::QL::AST::Node::SelectionSet->new(
        selections => [
            Graph::QL::AST::Node::Field->new(
                name      => Graph::QL::AST::Node::Name->new( value => 'find' ),
                arguments => [
                    Graph::QL::AST::Node::Argument->new(
                        name => Graph::QL::AST::Node::Name->new( value => 'id' ),
                        value => Graph::QL::AST::Node::IntValue->new( value => 4 ),
                    )
                ],
                selection_set => Graph::QL::AST::Node::SelectionSet->new(
                    selections => [
                        Graph::QL::AST::Node::Field->new( name => Graph::QL::AST::Node::Name->new( value => 'id' ) ),
                        Graph::QL::AST::Node::Field->new( name => Graph::QL::AST::Node::Name->new( value => 'name' ) ),
                    ]
                )
            )
        ]
    )
);

eq_or_diff($node_2->TO_JSON, $ast->{definitions}->[0], '... round-tripped the ast');

my $query = Graph::QL::Operation::Query->new(
    name       => 'queryName',
    selections => [
        Graph::QL::Operation::Selection::Field->new(
            name       => 'find',
            args       => [ Graph::QL::Operation::Selection::Field::Argument->new( name => 'id', value => 4 ) ],
            selections => [
                Graph::QL::Operation::Selection::Field->new( name => 'id' ),
                Graph::QL::Operation::Selection::Field->new( name => 'name' ),
            ]
        )
    ]
);

isa_ok($query, 'Graph::QL::Operation::Query');

eq_or_diff($query->ast->TO_JSON, $ast->{definitions}->[0], '... round-tripped the ast');

done_testing;
