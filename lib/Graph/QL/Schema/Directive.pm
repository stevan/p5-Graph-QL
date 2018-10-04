package Graph::QL::Schema::Directive;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

use Graph::QL::Core::ExecutableDirectiveLocation;
use Graph::QL::Core::TypeSystemDirectiveLocation;

use Graph::QL::Schema::InputObject::InputValue;

use Graph::QL::AST::Node::DirectiveDefinition;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast       => sub {},
    _name      => sub {},
    _args      => sub {},
    _locations => sub {},
);

sub BUILDARGS : strict(
    ast?       => _ast,
    name?      => _name,
    args?      => _args,
    locations? => _locations,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::DirectiveDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::DirectiveDefinition' );

        $self->{_name} = $self->{_ast}->name->value;
        $self->{_locations} = [ map $_->value, $self->{_ast}->locations->@* ];
        if ( $self->{_ast}->arguments->@* ) {
            $self->{_args} = [
                map Graph::QL::Schema::InputObject::InputValue->new( ast => $_ ), $self->{_ast}->arguments->@*
            ];
        }

    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        if ( exists $params->{_args} ) {
            throw('The `args` value must be an ARRAY ref')
                unless assert_arrayref( $self->{_args} );

            foreach ( $self->{_args}->@* ) {
                throw('The values in `args` must all be of type(Graph::QL::Schema::InputObject::InputValue), not `%s`', $_ )
                    unless assert_isa( $_, 'Graph::QL::Schema::InputObject::InputValue');
            }
        }

        throw('The `locations` value must be an ARRAY ref')
            unless assert_arrayref( $self->{_locations} );

        foreach ( $self->{_locations}->@* ) {
            throw('The values in `locations` must all be either a TypeSystemDirectiveLocation or ExecutableDirectiveLocation, not `%s`', $_ )
                unless Graph::QL::Core::TypeSystemDirectiveLocation->is_type_system_directive_location( $_ )
                    || Graph::QL::Core::ExecutableDirectiveLocation->is_executable_directive_location( $_ );
        }

        $self->{_ast} = Graph::QL::AST::Node::DirectiveDefinition->new(
            name => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            (exists $params->{_args}
                ? (arguments => [ map $_->ast, $self->{_args}->@* ])
                : ()),
            locations => [
                map Graph::QL::AST::Node::Name->new( value => $_ ), $self->{_locations}->@*
            ]
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);
sub args : ro(_);
sub has_args ($self) { $self->{_args} && scalar $self->{_args}->@* }
sub arity    ($self) {                   scalar $self->{_args}->@* }

sub locations : ro(_);

## ...

sub to_type_language ($self) {
    'directive @'.$self->name.
        ($self->has_args
            ? ('('.(join ', ' => map $_->to_type_language, $self->args->@*).')')
            : '').' on '.(join ' | ' => $self->locations->@*)
}

1;

__END__

=pod

=cut
