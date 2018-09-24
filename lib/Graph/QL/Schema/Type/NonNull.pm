package Graph::QL::Schema::Type::NonNull;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_does';
use Graph::QL::Util::AST;

use Graph::QL::Schema::Type::Named;

use Graph::QL::AST::Node::NonNullType;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Schema::Type';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?     => _ast,
    of_type? => of_type,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        throw('The `of_type` must be an instance that does the role(Graph::QL::Schema::Type), not %s', $params->{of_type})
            unless assert_does( $params->{of_type}, 'Graph::QL::Schema::Type' );

        $self->{_ast} = Graph::QL::AST::Node::NonNullType->new(
            type => $params->{of_type}->ast
        );
    }
}

sub ast : ro(_);

sub name    ($self) { $self->of_type->name . '!' }
sub of_type ($self) {
    return Graph::QL::Util::AST::ast_type_to_schema_type( $self->ast->type );
}

1;

__END__

=pod

=cut
