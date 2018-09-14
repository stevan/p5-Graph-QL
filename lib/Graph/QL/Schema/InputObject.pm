package Graph::QL::Schema::InputObject;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::AST::Node::InputObjectTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?    => _ast,
    name?   => name,
    fields? => fields,
);

sub BUILD ($self, $params) {

    $self->{_ast} //= Graph::QL::AST::Node::InputObjectTypeDefinition->new(
        name   => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
        fields => [ map $_->ast, $params->{fields}->@* ]
    )
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }

sub fields ($self) {
    [ map Graph::QL::Schema::InputObject::InputValue->new( ast => $_ ), $self->ast->fields->@* ]
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return 'input '.$self->name.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->fields->@*)."\n".
    '}';
}


1;

__END__

=pod

=cut
