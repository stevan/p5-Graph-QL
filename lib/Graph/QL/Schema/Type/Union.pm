package Graph::QL::Schema::Type::Union;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

use Graph::QL::Schema::Type;

use Graph::QL::AST::Node::UnionTypeDefinition;
use Graph::QL::AST::Node::NamedType;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

#use parent 'Graph::QL::Schema::Type::Scalar';
use parent 'UNIVERSAL::Object::Immutable';
use slots (
    kind => sub { Graph::QL::Schema::Type->Kind->UNION },
    _ast => sub {},
);

sub BUILDARGS : strict(
    ast?   => _ast,
    name?  => name,
    types? => types,
);

sub BUILD ($self, $params) {
    $self->{_ast} //= Graph::QL::AST::Node::UnionTypeDefinition->new(
        name  => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
        types => [
            map Graph::QL::AST::Node::NamedType->new(
                name => Graph::QL::AST::Node::Name->new(
                    value => $_->name
                )
            ), $params->{types}->@*
        ]
    );
}

sub ast : ro(_);

sub name       ($self) { $self->ast->name->value }
sub type_names ($self) { [ map $_->name->value, $self->ast->types->@* ] }


## ...

sub to_type_language ($self) {
    return sprintf 'union %s = %s' => $self->name, (join ' | ' => $self->type_names->@*);
}

1;

__END__

=pod

=cut
