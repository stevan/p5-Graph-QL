package Graph::QL::Schema::Field;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_does', 'assert_isa', 'assert_arrayref';
use Graph::QL::Util::AST;

use Graph::QL::Schema::Type::Named;
use Graph::QL::Schema::InputObject::InputValue;

use Graph::QL::AST::Node::FieldDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Core::Field';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?  => _ast,
    name? => name,
    type? => type,
    args? => args,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        throw('You must pass a defined value to `name`')
            unless defined $params->{name};

        throw('The `type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $params->{type})
            unless assert_does( $params->{type}, 'Graph::QL::Schema::Type' );

        if ( exists $params->{args} ) {
           throw('The `args` value must be an ARRAY ref')
                unless assert_arrayref( $params->{args} );

            foreach ( $params->{args}->@* ) {
                throw('The values in `args` must all be of type(Graph::QL::Schema::InputObject::InputValue), not `%s`', $_ )
                    unless assert_isa( $_, 'Graph::QL::Schema::InputObject::InputValue');
            }
        }

        $self->{_ast} = Graph::QL::AST::Node::FieldDefinition->new(
            name      => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            type      => $params->{type}->ast,
            (exists $params->{args}
                ? (arguments => [ map $_->ast, $params->{args}->@* ])
                : ()),
        );
    }
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }
sub type ($self) {
    return Graph::QL::Util::AST::ast_type_to_schema_type( $self->ast->type );
}

sub arity ($self) { scalar $self->ast->arguments->@* }

sub has_args ($self) { !! scalar $self->ast->arguments->@* }
sub args ($self) {
    [ map Graph::QL::Schema::InputObject::InputValue->new( ast => $_ ), $self->ast->arguments->@* ]
}

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
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
