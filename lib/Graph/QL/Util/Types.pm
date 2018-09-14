package Graph::QL::Util::Types;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';

use constant BOOLEAN => 'Boolean';
use constant FLOAT   => 'Float';
use constant INT     => 'Int';
use constant STRING  => 'String';
use constant NULL    => 'Null';

our $VERSION = '0.01';

sub ast_type_to_schema_type ($ast) {
    if ( $ast->isa('Graph::QL::AST::Node::NamedType') ) {
        require Graph::QL::Schema::Type::Named;
        return Graph::QL::Schema::Type::Named->new( ast => $ast );
    }
    elsif ( $ast->isa('Graph::QL::AST::Node::NonNullType') ) {
        require Graph::QL::Schema::Type::NonNull;
        return Graph::QL::Schema::Type::NonNull->new( ast => $ast );
    }
    elsif ( $ast->isa('Graph::QL::AST::Node::ListType') ) {
        require Graph::QL::Schema::Type::List;
        return Graph::QL::Schema::Type::List->new( ast => $ast );
    }
    else {
        throw('Do not recognize the ast type(%s), unable to convert to schema type', $ast);
    }
}

sub literal_to_ast_node ($literal, $type) {

    if ( not defined $literal ) {
        require Graph::QL::AST::Node::NullValue;
        return Graph::QL::AST::Node::NullValue->new;
    }
    elsif ( $type->name eq BOOLEAN ) {
        require Graph::QL::AST::Node::BooleanValue;
        return Graph::QL::AST::Node::BooleanValue->new( value => $literal );
    }
    elsif ( $type->name eq FLOAT ) {
        require Graph::QL::AST::Node::FloatValue;
        return Graph::QL::AST::Node::FloatValue->new( value => $literal );
    }
    elsif ( $type->name eq INT ) {
        require Graph::QL::AST::Node::IntValue;
        return Graph::QL::AST::Node::IntValue->new( value => $literal );
    }
    elsif ( $type->name eq STRING ) {
        require Graph::QL::AST::Node::StringValue;
        return Graph::QL::AST::Node::StringValue->new( value => $literal );
    }
    else {
        throw('Do not recognize the expected type(%s), unable to convert to ast-node', $type->name);
    }
}

sub ast_node_to_literal ($ast_node) {
    # TODO:
    # type check $ast_node does (Graph::QL::AST::Node::Role::Value)

    return undef if $ast_node->isa('Graph::QL::AST::Node::NullValue');
    return $ast_node->value;
}

sub ast_node_to_type_language ($ast_node) {

    if ( $ast_node->isa('Graph::QL::AST::Node::NullValue') ) {
        return 'null';
    }
    elsif ( $ast_node->isa('Graph::QL::AST::Node::BooleanValue') ) {
        return $ast_node->value ? 'true' : 'false';
    }
    elsif ( $ast_node->isa('Graph::QL::AST::Node::FloatValue') || $ast_node->isa('Graph::QL::AST::Node::IntValue') ) {
        return $ast_node->value;
    }
    elsif ( $ast_node->isa('Graph::QL::AST::Node::StringValue') ) {
        return '"'.$ast_node->value.'"';
    }
    else {
        throw('Do not recognize the expected ast-node(%s), unable to convert to type-language', $ast_node);
    }
}

1;

__END__

=pod

=cut

