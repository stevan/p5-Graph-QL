package Graph::QL::Operation::Field::Argument;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors 'throw';

use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::Argument;

use Graph::QL::Util::AST;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?   => _ast,
    name?  => name,
    value? => value,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        throw('You must pass a defined value to `name`')
            unless defined $params->{name};

        $self->{_ast} = Graph::QL::AST::Node::Argument->new(
            name  => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            value => Graph::QL::Util::AST::guess_literal_to_ast_node( $params->{value} ),
        );
    }
}

sub ast : ro(_);

sub name  ($self) { $self->ast->name->value }
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

