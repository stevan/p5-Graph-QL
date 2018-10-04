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
use slots (
    _ast        => sub {},
    _name       => sub {},
    _type       => sub {},
    _args       => sub {},
    _directives => sub {},
);

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => _name,
    type?       => _type,
    args?       => _args,
    directives? => _directives,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::FieldDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::FieldDefinition' );

        $self->{_name} = $self->{_ast}->name->value;
        $self->{_type} = Graph::QL::Util::AST::ast_type_to_schema_type( $self->{_ast}->type );
        if ( $self->{_ast}->arguments->@* ) {
            $self->{_args} = [
                map Graph::QL::Schema::InputObject::InputValue->new( ast => $_ ), $self->{_ast}->arguments->@*
            ];
        }

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

        if ( exists $params->{_args} ) {
            throw('The `args` value must be an ARRAY ref')
                unless assert_arrayref( $self->{_args} );

            foreach ( $self->{_args}->@* ) {
                throw('The values in `args` must all be of type(Graph::QL::Schema::InputObject::InputValue), not `%s`', $_ )
                    unless assert_isa( $_, 'Graph::QL::Schema::InputObject::InputValue');
            }
        }

        if ( exists $params->{_directives} ) {
            throw('The `directives` value must be an ARRAY ref')
                unless assert_arrayref( $self->{_directives} );

            foreach ( $self->{_directives}->@* ) {
                throw('The values in `directives` must all be of type(Graph::QL::Directive), not `%s`', $_ )
                    unless assert_isa( $_, 'Graph::QL::Directive');
            }
        }

        $self->{_ast} = Graph::QL::AST::Node::FieldDefinition->new(
            name      => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            type      => $self->{_type}->ast,
            (exists $params->{_args}
                ? (arguments => [ map $_->ast, $self->{_args}->@* ])
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

sub args     : ro(_);
sub has_args ($self) { $self->{_args} && scalar $self->{_args}->@* }
sub arity    ($self) {                   scalar $self->{_args}->@* }

sub has_directives : predicate(_);
sub directives     : ro(_);

## ...

sub to_type_language ($self) {
    my $out;
    if ( $self->has_args ) {
        $out = $self->name.'('.(join ', ' => map $_->to_type_language, $self->args->@*).') : '.$self->type->name;
    }
    else {
        $out = $self->name.' : '.$self->type->name;
    }

    if ($self->has_directives) {
        $out .= ' '.(join ' ' => map $_->to_type_language, $self->directives->@*);
    }

    return $out;
}


1;

__END__

=pod

=cut
