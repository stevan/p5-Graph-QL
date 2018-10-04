package Graph::QL::Directive;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_arrayref';

# TO THINK ABOUT:
# consider moving this class to
# be `Graph::QL::Operation::Argument`
# or `Graph::QL::Core::Argument`
# so that we aren't reaching into
# a namespace we don't own
# - SL
use Graph::QL::Operation::Field::Argument;

use Graph::QL::AST::Node::Directive;
use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::Argument;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast  => sub {},
    _name => sub {},
    _args => sub {},
);

sub BUILDARGS : strict(
    ast?  => _ast,
    name? => _name,
    args? => _args,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::Directive`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::Directive' );

        $self->{_name} = $self->{_ast}->name->value;
        if ( $self->{_ast}->arguments->@* ) {
            $self->{_args} = [
                map Graph::QL::Operation::Field::Argument->new( ast => $_ ), $self->{_ast}->arguments->@*
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
                throw('The values in `args` must all be of type(Graph::QL::Operation::Field::Argument), not `%s`', $_ )
                    unless assert_isa( $_, 'Graph::QL::Operation::Field::Argument');
            }
        }

        $self->{_ast} = Graph::QL::AST::Node::Directive->new(
            name => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            (exists $params->{_args}
                ? (arguments => [ map $_->ast, $self->{_args}->@* ])
                : ()),
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);
sub args : ro(_);
sub has_args ($self) { $self->{_args} && scalar $self->{_args}->@* }

## ...

sub to_type_language ($self) {
    '@'.$self->name.
        ($self->has_args
            ? ('('.(join ', ' => map $_->to_type_language, $self->args->@*).')')
            : '')
}

1;

__END__

=pod

=cut
