package Graph::QL::Schema;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::AST;

use Graph::QL::AST::Node::Document;
use Graph::QL::AST::Node::SchemaDefinition;
use Graph::QL::AST::Node::OperationTypeDefinition;
use Graph::QL::AST::Node::NamedType;
use Graph::QL::AST::Node::Name;

use Graph::QL::Schema::Type::Named;
use Graph::QL::Schema::Enum;
use Graph::QL::Schema::Union;
use Graph::QL::Schema::InputObject;
use Graph::QL::Schema::Interface;
use Graph::QL::Schema::Object;
use Graph::QL::Schema::Scalar;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?               => _ast,
    types?             => types,
    query_type?        => query_type,
    mutation_type?     => mutation_type,
    subscription_type? => subscription_type,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        # set up some defaults ...
        $params->{query_type}        ||= Graph::QL::Schema::Type::Named->new( name => 'Query' );
        $params->{mutation_type}     ||= Graph::QL::Schema::Type::Named->new( name => 'Mutation' );
        $params->{subscription_type} ||= Graph::QL::Schema::Type::Named->new( name => 'Subscription' );

        my @definitions;

        # So converting these is simple, just
        # as for the ast, ... getting them back
        # happens in the `types` method below
        foreach my $type ( $params->{types}->@* ) {
            push @definitions => $type->ast;
        }

        push @definitions => Graph::QL::AST::Node::SchemaDefinition->new(
            operation_types => [
                Graph::QL::AST::Node::OperationTypeDefinition->new(
                    operation => 'query',
                    type      => $params->{query_type}->ast
                ),
                Graph::QL::AST::Node::OperationTypeDefinition->new(
                    operation => 'mutation',
                    type      => $params->{mutation_type}->ast
                ),
                Graph::QL::AST::Node::OperationTypeDefinition->new(
                    operation => 'subscription',
                    type      => $params->{subscription_type}->ast
                )
            ]
        );

        $self->{_ast} = Graph::QL::AST::Node::Document->new(
            definitions => \@definitions
        );
    }

}

sub ast : ro(_);

sub has_types ($self) { $self->_has_type_definitions }
sub types ($self) {
    [ map Graph::QL::Util::AST::ast_type_def_to_schema_type_def( $_ ), $self->_type_definitions->@* ]
}



sub _schema_definition    ($self) { $self->ast->definitions->[-1] }

sub _type_definitions     ($self) { [ $self->ast->definitions->@[ 0 .. $#{ $self->ast->definitions } - 1 ] ] }
sub _has_type_definitions ($self) { (scalar $self->ast->definitions->@*) > 1 }

sub query_type        ($self) { Graph::QL::Schema::Type::Named->new( ast => $self->_schema_definition->operation_types->[0]->type ) }
sub mutation_type     ($self) { Graph::QL::Schema::Type::Named->new( ast => $self->_schema_definition->operation_types->[1]->type ) }
sub subscription_type ($self) { Graph::QL::Schema::Type::Named->new( ast => $self->_schema_definition->operation_types->[2]->type ) }

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `directives`
    return ($self->has_types # print the types first ...
        ? ("\n".(join "\n\n" => map $_->to_type_language, $self->types->@*)."\n\n")
        : ''). # followed by the base `schema` object
        'schema {'."\n".
        '    query : '.$self->query_type->name."\n".
        '    mutation : '.$self->mutation_type->name."\n".
        '    subscription : '.$self->subscription_type->name."\n".
        '}'.($self->has_types ? "\n" : '');
}

1;

__END__

=pod

=cut
