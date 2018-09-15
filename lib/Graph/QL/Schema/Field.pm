package Graph::QL::Schema::Field;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';
use Graph::QL::Util::AST;

use Graph::QL::Schema::Type::Named;

use Graph::QL::AST::Node::FieldDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?  => _ast,
    name? => name,
    type? => type,
    args? => args,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {
        throw('The `type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $params->{type})
            unless Ref::Util::is_blessed_ref( $params->{type} )
                && $params->{type}->roles::DOES('Graph::QL::Schema::Type');

        # TODO:
        # - check `args`

        $self->{_ast} = Graph::QL::AST::Node::FieldDefinition->new(
            name      => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            type      => $params->{type}->ast,
            arguments => [ map $_->ast, $params->{args}->@* ],
        );
    }
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }
sub type ($self) {
    return Graph::QL::Util::AST::ast_type_to_schema_type( $self->ast->type );
}

sub has_args ($self) { !! scalar $self->ast->arguments->@* }
sub args ($self) {
    [ map Graph::QL::Schema::InputObject::InputValue->new( ast => $_ ), $self->ast->arguments->@* ]
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    # handle the `args` form
    if ( $self->has_args ) {
        return $self->name.'('.(join ', ' => map $_->to_type_language, $self->args->@*).') : '.$self->type->name;
    }
    else {
        return $self->name.' : '.$self->type->name;
    }
}

1;

__END__

=pod

=cut
