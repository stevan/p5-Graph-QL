package Graph::QL::Schema::InputObject::InputValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

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

    # TODO:
    # verify that the type is an instance of:
    # - Graph::QL::Schema::Type::Named
    # - Graph::QL::Schema::Type::NonNull
    # - Graph::QL::Schema::Type::List

    $self->{_ast} //= Graph::QL::AST::Node::InputValueDefinition->new(
        name => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
        type => $params->{type}->ast,
        # TODO: handle default value ...
    );
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }
sub type ($self) {
    # TODO:
    # handle this being (does => Graph::QL::AST::Node::Role::Type), meaning
    # - Graph::QL::AST::Node::NamedType
    # - Graph::QL::AST::Node::NonNullType
    # - Graph::QL::AST::Node::ListType
    # and wrap it with my class accordingly
    # but for now, we can punt ...
    Graph::QL::Schema::Type::Named->new( ast => $self->ast->type )
}

sub default_value;

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    # handle the `default_value`
    return $self->name.' : '.$self->type->name;
}

1;

__END__

=pod

=cut
