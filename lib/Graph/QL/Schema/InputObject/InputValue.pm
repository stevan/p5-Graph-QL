package Graph::QL::Schema::InputObject::InputValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_does', 'assert_isa', 'assert_arrayref';

use Graph::QL::Util::AST;
use Graph::QL::AST::Node::InputValueDefinition;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast        => sub {},
    _name       => sub {},
    _type       => sub {},
    _directives => sub {},
);

sub BUILDARGS : strict(
    ast?           => _ast,
    name?          => _name,
    type?          => _type,
    default_value? => _default_value,
    directives?    => _directives,

);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {

        throw('The `ast` must be an instance of `Graph::QL::AST::Node::InputValueDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::InputValueDefinition' );

        $self->{_name} = $self->{_ast}->name->value;
        $self->{_type} = Graph::QL::Util::AST::ast_type_to_schema_type( $self->{_ast}->type );

        if ( $self->{_ast}->directives->@* ) {
            $self->{_directives} = [
                map Graph::QL::Directive->new( ast => $_ ), $self->{_ast}->directives->@*
            ];
        }
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        throw('The `type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $self->{_type})
            unless assert_does( $self->{_type}, 'Graph::QL::Schema::Type' );

        if ( exists $params->{_directives} ) {
            throw('The `directives` value must be an ARRAY ref')
                unless assert_arrayref( $self->{_directives} );

            foreach ( $self->{_directives}->@* ) {
                throw('The values in `directives` must all be of type(Graph::QL::Directive), not `%s`', $_ )
                    unless assert_isa( $_, 'Graph::QL::Directive');
            }
        }

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
                : ()),
            (exists $params->{_directives}
                ? (directives => [ map $_->ast, $self->{_directives}->@* ])
                : ()),
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

sub has_directives : predicate(_);
sub directives     : ro(_);

## ...

sub to_type_language ($self) {
    return $self->name
          .' : '
          .$self->type->name
          .($self->has_default_value
                ? (' = '.Graph::QL::Util::AST::ast_node_to_type_language( $self->ast->default_value ))
                : '')
          .($self->has_directives
                ? (' '.(join ' ' => map $_->to_type_language, $self->directives->@*))
                : '');
}

1;

__END__

=pod

=cut
