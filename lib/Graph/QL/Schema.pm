package Graph::QL::Schema;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';
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
                ($params->{mutation_type} ?
                    Graph::QL::AST::Node::OperationTypeDefinition->new(
                        operation => 'mutation',
                        type      => $params->{mutation_type}->ast
                    ) : ()),
                ($params->{subscription_type} ?
                    Graph::QL::AST::Node::OperationTypeDefinition->new(
                        operation => 'subscription',
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
    $name = $name->name
        if Ref::Util::is_blessed_ref( $name )
        && $name->isa('Graph::QL::Schema::Type::Named');

    $name = $name->name->value
        if Ref::Util::is_blessed_ref( $name )
        && $name->isa('Graph::QL::AST::Node::NamedType');

    my ($type_def) = grep $_->name->value eq $name, $self->_type_definitions->@*;
    return unless defined $type_def;

    return Graph::QL::Util::AST::ast_type_def_to_schema_type_def( $type_def );
}

sub lookup_root_type ($self, $op_kind) {
    # TODO:
    # validate $op_kind against OperationKind

    my $type;
    $type = $self->_get_query_type        if $op_kind eq 'query';
    $type = $self->_get_mutation_type     if $op_kind eq 'mutation';
    $type = $self->_get_subscription_type if $op_kind eq 'subscription';
    # NOTE:
    # we should have validated the $op_kind so
    # that it cannot have any other values then
    # the three we tested.
    # - SL

    return unless $type;
    return $self->lookup_type( $type );
}

## ...

sub to_type_language ($self) {
    my $query        = $self->lookup_root_type( 'query' );
    my $mutation     = $self->lookup_root_type( 'mutation' );
    my $subscription = $self->lookup_root_type( 'subscription' );

    return ($self->_has_type_definitions # print the types first ...
        ? ("\n".(join "\n\n" => map $_->to_type_language, $self->all_types->@*)."\n\n")
        : ''). # followed by the base `schema` object
        'schema {'."\n".
        ($query        ? ('    query : '.$query->name."\n") : '').
        ($mutation     ? ('    mutation : '.$mutation->name."\n") : '').
        ($subscription ? ('    subscription : '.$subscription->name."\n") : '').
        '}'.($self->_has_type_definitions ? "\n" : '');
}

## ...

sub _schema_definition    ($self) { $self->ast->definitions->[-1] }
sub _type_definitions     ($self) { [ $self->ast->definitions->@[ 0 .. $#{ $self->ast->definitions } - 1 ] ] }
sub _has_type_definitions ($self) { (scalar $self->ast->definitions->@*) > 1 }

sub _get_query_type        ($self) { if ( my $op = $self->_schema_definition->operation_types->[0] ) { return $op->type } return; }
sub _get_mutation_type     ($self) { if ( my $op = $self->_schema_definition->operation_types->[1] ) { return $op->type } return; }
sub _get_subscription_type ($self) { if ( my $op = $self->_schema_definition->operation_types->[2] ) { return $op->type } return; }

1;

__END__

=pod

=cut
