package Graph::QL::Operation::Field::Argument;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa';

use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::Argument;

use Graph::QL::Util::AST;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast   => sub {},
    _name  => sub {},
    _value => sub {},
);

sub BUILDARGS : strict(
    ast?   => _ast,
    name?  => _name,
    value? => _value,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::Argument`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::Argument' );

        $self->{_name} = $self->{_ast}->name->value;
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        $self->{_ast} = Graph::QL::AST::Node::Argument->new(
            name  => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            value => Graph::QL::Util::AST::guess_literal_to_ast_node( $self->{_value} ),
        );
    }
}

sub ast   : ro(_);
sub name  : ro(_);

sub value ($self) {
    if ( my $value = $self->ast->value ) {
        return Graph::QL::Util::AST::ast_node_to_literal( $value );
    }
    return;
}

sub to_type_language ($self) {
    return $self->name.' : '.Graph::QL::Util::AST::ast_node_to_type_language( $self->ast->value );
}

1;

__END__

=pod

=cut

