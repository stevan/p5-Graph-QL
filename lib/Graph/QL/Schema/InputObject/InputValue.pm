package Graph::QL::Schema::InputObject::InputValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_does', 'assert_isa';

use Graph::QL::Util::AST;
use Graph::QL::AST::Node::InputValueDefinition;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast  => sub {},
    _name => sub {},
    _type => sub {},
);

sub BUILDARGS : strict(
    ast?           => _ast,
    name?          => _name,
    type?          => _type,
    default_value? => _default_value,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {

        throw('The `ast` must be an instance of `Graph::QL::AST::Node::InputValueDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::InputValueDefinition' );

        $self->{_name} = $self->{_ast}->name->value;
        $self->{_type} = Graph::QL::Util::AST::ast_type_to_schema_type( $self->{_ast}->type );
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        throw('The `type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $self->{_type})
            unless assert_does( $self->{_type}, 'Graph::QL::Schema::Type' );

        # NOTE:
        # no need to test default_value,
        # it can be undef and so we can let
        # the `literal_to_ast_node` to work
        # it out.

        $self->{_ast} = Graph::QL::AST::Node::InputValueDefinition->new(
            name          => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            type          => $self->{_type}->ast,
            (exists $params->{_default_value}
                ? (default_value => Graph::QL::Util::AST::literal_to_ast_node( $params->{_default_value}, $self->{_type} ))
                : ())
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);
sub type : ro(_);

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
