package Graph::QL::Schema;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does';
use Graph::QL::Util::AST;

use Graph::QL::Core::OperationKind;

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

sub new_from_source ($class, $source) {
    require Graph::QL::Parser;
    $class->new( ast => Graph::QL::Parser->parse_schema( $source ) )
}

sub BUILDARGS : strict(
    ast?               => _ast,
    types?             => types,
    query_type?        => query_type,
    mutation_type?     => mutation_type,
    subscription_type? => subscription_type,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        if ( exists $params->{query_type} ) {
            throw('The `query_type` must be an instance that does the role(Graph::QL::Schema::Type::Named), not %s', $params->{query_type})
                unless assert_isa( $params->{query_type}, 'Graph::QL::Schema::Type::Named' );
        }

        if ( exists $params->{mutation_type} ) {
            throw('The `mutation_type` must be an instance that does the role(Graph::QL::Schema::Type::Named), not %s', $params->{mutation_type})
                unless assert_isa( $params->{mutation_type}, 'Graph::QL::Schema::Type::Named' );
        }

        if ( exists $params->{subscription_type} ) {
            throw('The `subscription_type` must be an instance that does the role(Graph::QL::Schema::Type::Named), not %s', $params->{subscription_type})
                unless assert_isa( $params->{subscription_type}, 'Graph::QL::Schema::Type::Named' );
        }

        # TODO:
        # - check for `query` (and `mutation`, `subscription`) types being defined
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
                    operation => Graph::QL::Core::OperationKind->QUERY,
                    type      => $params->{query_type}->ast
                ),
                ($params->{mutation_type} ?
                    Graph::QL::AST::Node::OperationTypeDefinition->new(
                        operation => Graph::QL::Core::OperationKind->MUTATION,
                        type      => $params->{mutation_type}->ast
                    ) : ()),
                ($params->{subscription_type} ?
                    Graph::QL::AST::Node::OperationTypeDefinition->new(
                        operation => Graph::QL::Core::OperationKind->SUBSCRIPTION,
                        type      => $params->{subscription_type}->ast
                    ) : ()),
            ]
        );

        $self->{_ast} = Graph::QL::AST::Node::Document->new(
            definitions => \@definitions
        );
    }

}

sub ast : ro(_);

## ...

sub all_types ($self) {
    return [ map Graph::QL::Util::AST::ast_type_def_to_schema_type_def( $_ ), $self->_type_definitions->@* ]
}

sub lookup_type ($self, $name) {

    # coerce named types into strings ...
    $name = $name->name        if assert_isa( $name, 'Graph::QL::Schema::Type::Named' );
    $name = $name->name->value if assert_isa( $name, 'Graph::QL::AST::Node::NamedType' );

    my ($type_def) = grep $_->name->value eq $name, $self->_type_definitions->@*;
    return unless defined $type_def;

    return Graph::QL::Util::AST::ast_type_def_to_schema_type_def( $type_def );
}

sub lookup_root_type ($self, $op_kind) {

    # coerce operation objects into strings ...
    $op_kind = $op_kind->operation_kind if assert_does( $op_kind, 'Graph::QL::Operation' );
    $op_kind = $op_kind->operation      if assert_isa( $op_kind, 'Graph::QL::AST::Node::OperationDefinition' );

    throw('The kind(%s) is not a valid Operation::Kind', $op_kind)
        unless Graph::QL::Core::OperationKind->is_operation_kind( $op_kind );

    my $type;
    $type = $self->_get_query_type        if $op_kind eq Graph::QL::Core::OperationKind->QUERY;
    $type = $self->_get_mutation_type     if $op_kind eq Graph::QL::Core::OperationKind->MUTATION;
    $type = $self->_get_subscription_type if $op_kind eq Graph::QL::Core::OperationKind->SUBSCRIPTION;

    return unless $type;
    return $self->lookup_type( $type );
}

## ...

sub to_type_language ($self) {
    my $query        = $self->_get_query_type;
    my $mutation     = $self->_get_mutation_type;
    my $subscription = $self->_get_subscription_type;

    return ($self->_has_type_definitions # print the types first ...
        ? ("\n".(join "\n\n" => map $_->to_type_language, $self->all_types->@*)."\n\n")
        : ''). # followed by the base `schema` object
        'schema {'."\n".
        ($query        ? ('    '.Graph::QL::Core::OperationKind->QUERY.' : '.$query->name->value."\n") : '').
        ($mutation     ? ('    '.Graph::QL::Core::OperationKind->MUTATION.' : '.$mutation->name->value."\n") : '').
        ($subscription ? ('    '.Graph::QL::Core::OperationKind->SUBSCRIPTION.' : '.$subscription->name->value."\n") : '').
        '}'.($self->_has_type_definitions ? "\n" : '');
}

## ...

sub _schema_definition    ($self) { ( grep  $_->isa('Graph::QL::AST::Node::SchemaDefinition'), $self->ast->definitions->@* )[0] }
sub _type_definitions     ($self) { [ grep !$_->isa('Graph::QL::AST::Node::SchemaDefinition'), $self->ast->definitions->@* ]    }
sub _has_type_definitions ($self) { (scalar $self->ast->definitions->@*) > 2 }

sub _get_query_type        ($self) { if ( my $op = $self->_schema_definition->operation_types->[0] ) { return $op->type } return; }
sub _get_mutation_type     ($self) { if ( my $op = $self->_schema_definition->operation_types->[1] ) { return $op->type } return; }
sub _get_subscription_type ($self) { if ( my $op = $self->_schema_definition->operation_types->[2] ) { return $op->type } return; }

1;

__END__

=pod

=cut
