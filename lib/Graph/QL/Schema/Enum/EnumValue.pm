package Graph::QL::Schema::Enum::EnumValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::AST::Node::EnumValueDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?  => _ast,
    name? => name,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {
        $self->{_ast} = Graph::QL::AST::Node::EnumValueDefinition->new(
            name => Graph::QL::AST::Node::Name->new(
                value => $params->{name}
            )
        );
    }
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }

## ...

sub to_type_language ($self) {
    # TODO:
    # handle `directives`
    return $self->name;
}

1;

__END__

=pod

=cut