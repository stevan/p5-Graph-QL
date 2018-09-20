package Graph::QL::Schema::InputObject::InputValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_does';

use Graph::QL::Util::AST;
use Graph::QL::AST::Node::InputValueDefinition;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?           => _ast,
    name?          => name,
    type?          => type,
    default_value? => default_value,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {
        throw('The `type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $params->{type})
            unless assert_does( $params->{type}, 'Graph::QL::Schema::Type' );

        $self->{_ast} = Graph::QL::AST::Node::InputValueDefinition->new(
            name          => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            type          => $params->{type}->ast,
            (exists $params->{default_value}
                ? (default_value => Graph::QL::Util::AST::literal_to_ast_node( $params->{default_value}, $params->{type} ))
                : ())
        );
    }
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }
sub type ($self) {
    return Graph::QL::Util::AST::ast_type_to_schema_type( $self->ast->type );
}

sub has_default_value ($self) { !! $self->ast->default_value }
sub default_value ($self) {
    if ( my $default_value = $self->ast->default_value ) {
        return Graph::QL::Util::AST::ast_node_to_literal( $default_value );
    }
    return;
}

## ...

sub to_type_language ($self) {
    return $self->name
          .' : '
          .$self->type->name
          .($self->has_default_value
                ? (' = '.Graph::QL::Util::AST::ast_node_to_type_language( $self->ast->default_value ))
                : '');
}

1;

__END__

=pod

=cut
