package Graph::QL::Schema::Object;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Schema::Field;
use Graph::QL::Schema::Type::Named;

use Graph::QL::AST::Node::ObjectTypeDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?         => _ast,
    name?        => name,
    fields?      => fields,
    interfaces?  => interfaces,
);

sub BUILD ($self, $params) {

    $self->{_ast} //= Graph::QL::AST::Node::ObjectTypeDefinition->new(
        name       => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
        fields     => [ map $_->ast, $params->{fields}->@*     ],
        interfaces => [ map $_->ast, $params->{interfaces}->@* ],
    );

    # TODO:
    # An object type must be a super‐set of all interfaces it implements:
    #     The object type must include a field of the same name for every field defined in an interface.
    #         The object field must be of a type which is equal to or a sub‐type of the interface field (covariant).
    #             An object field type is a valid sub‐type if it is equal to (the same type as) the interface field type.
    #             An object field type is a valid sub‐type if it is an Object type and the interface field type is either an Interface type or a Union type and the object field type is a possible type of the interface field type.
    #             An object field type is a valid sub‐type if it is a List type and the interface field type is also a List type and the list‐item type of the object field type is a valid sub‐type of the list‐item type of the interface field type.
    #             An object field type is a valid sub‐type if it is a Non‐Null variant of a valid sub‐type of the interface field type.
    #     The object field must include an argument of the same name for every argument defined in the interface field.
    #         The object field argument must accept the same type (invariant) as the interface field argument.
    #     The object field may include additional arguments not defined in the interface field, but any additional argument must not be required, e.g. must not be of a non‐nullable type.
}

sub ast : ro(_);

sub name   ($self) { $self->ast->name->value }
sub fields ($self) {
    [ map Graph::QL::Schema::Field->new( ast => $_ ), $self->ast->fields->@* ]
}

sub interfaces ($self) {
    [ map Graph::QL::Schema::Type::Named->new( ast => $_ ), $self->ast->interfaces->@* ]
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `directives`
    my $interfaces = '';
    if ( $self->interfaces->@* ) {
        $interfaces = ' implements '.(join ' & ' => map $_->name, $self->interfaces->@*);
    }
    return 'type '.$self->name.$interfaces.' {'."\n    ".
        (join "\n    " => map $_->to_type_language, $self->fields->@*)."\n".
    '}';
}

1;

__END__

=pod

=cut
