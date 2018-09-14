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

my $expected_ast = $ast->{definitions}->[0];
Graph::QL::Util::AST::null_out_source_locations(
    $expected_ast,
    # just clean it all out ... :P
    'selectionSet.selections.arguments.value',
    'selectionSet.selections.selectionSet.selections.arguments.value',
);

=pod

my $query = Graph::QL::Query->new(
    name       => 'queryName',
    selections => [
        Graph::QL::Query::Field->new(
            name       => 'find',
            arguments  => [ Graph::QL::Query::Argument->new( name => 'id', value => 4 ) ],
            selections => [
                Graph::QL::Query::Field->new( name => 'id' ),
                Graph::QL::Query::Field->new( name => 'name' ),
            ]
        )
    ]
);

=cut

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

eq_or_diff($node_2->TO_JSON, $expected_ast, '... round-tripped the ast');

done_testing;
