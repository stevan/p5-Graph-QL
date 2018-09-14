package Graph::QL::Schema::Type::NonNull;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Schema::Type::Named;

use Graph::QL::AST::Node::NonNullType;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?     => _ast,
    of_type? => of_type,
);

sub BUILD ($self, $params) {
    # TODO:
    # verify that the type is an instance of:
    # - Graph::QL::Schema::Type::Named
    # - Graph::QL::Schema::Type::NonNull
    # - Graph::QL::Schema::Type::List
    $self->{_ast} //= Graph::QL::AST::Node::NonNullType->new(
        type => $params->{of_type}->ast
    );
}

sub ast : ro(_);

sub name    ($self) { $self->of_type->name . '!' }
sub of_type ($self) {
    # TODO:
    # handle this being (does => Graph::QL::AST::Node::Role::Type), meaning
    # - Graph::QL::AST::Node::NamedType
    # - Graph::QL::AST::Node::NonNullType
    # - Graph::QL::AST::Node::ListType
    # and wrap it with my class accordingly
    # but for now, we can punt ...
    Graph::QL::Schema::Type::Named->new( ast => $self->ast->type )
}

1;

__END__

=pod

=cut
