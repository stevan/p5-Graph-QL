package Graph::QL::AST::Node::Role::Definition;
# ABSTRACT: Abstract AST Node for GraphQL in Perl
use v5.24;
use warnings;

our $VERSION = '0.01';

1;

__END__

=pod

This role is consumed by the following classes:

=over 4

=item C<Graph::QL::AST::Node::DirectiveDefinition>

=item C<Graph::QL::AST::Node::EnumTypeDefinition>

=item C<Graph::QL::AST::Node::FragmentDefinition>

=item C<Graph::QL::AST::Node::InputObjectTypeDefinition>

=item C<Graph::QL::AST::Node::InterfaceTypeDefinition>

=item C<Graph::QL::AST::Node::ObjectTypeDefinition>

=item C<Graph::QL::AST::Node::OperationDefinition>

=item C<Graph::QL::AST::Node::ScalarTypeDefinition>

=item C<Graph::QL::AST::Node::SchemaDefinition>

=item C<Graph::QL::AST::Node::TypeExtensionDefinition>

=item C<Graph::QL::AST::Node::UnionTypeDefinition>

=back

=cut
