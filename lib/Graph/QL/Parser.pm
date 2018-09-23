package Graph::QL::Parser;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Parser::GraphQL::XS;
use JSON::MaybeXS;

use Graph::QL::Util::Errors 'throw';
use Graph::QL::Util::AST;

our $VERSION = '0.01';

sub parse_schema ($class, $source) {
    my $document = $class->parse( $source );

    throw('Unable to find the SchemaDefinition node, not a schema')
        if 0 == scalar grep $_->isa('Graph::QL::AST::Node::SchemaDefinition'), $document->definitions->@*;

    return $document;
}

sub parse_operation ($class, $source) {
    my $document = $class->parse( $source );

    throw('Unable to find the OperationDefinition node, not an operation')
        if 0 == scalar grep $_->isa('Graph::QL::AST::Node::OperationDefinition'), $document->definitions->@*;

    return $document;
}

sub parse ($class, $source) {
    my $ast  = $class->parse_raw( $source );
    my $node = Graph::QL::Util::AST::build_from_ast( $ast );
    return $node;
}

sub parse_raw ($class, $source) {
    state $JSON = JSON::MaybeXS->new->utf8;

    my $ast;
    eval {
        my $json = Parser::GraphQL::XS->new->parse_string( $source );
           $ast  = $JSON->decode( $json );
        1;
    } or do {
        throw('Parsing failed because:[ %s ]', $@);
    };

    return $ast;
}

1;

__END__

=pod

=cut

