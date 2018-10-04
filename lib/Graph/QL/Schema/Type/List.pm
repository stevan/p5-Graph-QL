package Graph::QL::Schema::Type::List;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_does', 'assert_isa';
use Graph::QL::Util::AST;

use Graph::QL::Schema::Type::Named;

use Graph::QL::AST::Node::ListType;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Schema::Type';
use slots (
    _ast     => sub {},
    _of_type => sub {},
);

sub BUILDARGS : strict(
    ast?     => _ast,
    of_type? => _of_type,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {

        throw('The `ast` must be an instance of `Graph::QL::AST::Node::ListType`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::ListType' );

        $self->{_of_type} = Graph::QL::Util::AST::ast_type_to_schema_type( $self->{_ast}->type );
    }
    else {

        throw('The `of_type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $self->{_of_type})
            unless assert_does( $self->{_of_type}, 'Graph::QL::Schema::Type' );

        $self->{_ast} = Graph::QL::AST::Node::ListType->new(
            type => $self->{_of_type}->ast
        );
    }
}

sub ast     : ro(_);
sub of_type : ro(_);

sub name ($self) { '[' . $self->of_type->name . ']' }

1;

__END__

=pod

=cut
