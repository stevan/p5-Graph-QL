package Graph::QL::Schema;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does', 'assert_arrayref';
use Graph::QL::Util::AST;
use Graph::QL::Util::Schemas;

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
use Graph::QL::Schema::InputObject::InputValue;
use Graph::QL::Schema::Interface;
use Graph::QL::Schema::Object;
use Graph::QL::Schema::Scalar;
use Graph::QL::Schema::Field;

use Graph::QL::Schema::BuiltIn::Scalars;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast               => sub {},
    _types             => sub {},
    _query_type        => sub {},
    _mutation_type     => sub {},
    _subscription_type => sub {},
);

sub new_from_source ($class, $source) {
    require Graph::QL::Parser;
    $class->new( ast => Graph::QL::Parser->parse_schema( $source ) )
}

sub new_from_namespace ($class, $root_namespace) {

    $root_namespace = $root_namespace.'::' unless $root_namespace =~ /\:\:$/;

    my @namespaces;
    {
        no strict 'refs';
        @namespaces = map s/\:\:$//r => grep /\:\:$/ => keys %{ $root_namespace };
    }

    throw('Cannot find any types within the namespace (%s), perhaps you forgot to load them', $root_namespace)
        unless @namespaces;

    my @types;
    foreach my $namespace ( @namespaces ) {
        my $r = MOP::Role->new( "${root_namespace}${namespace}" );

        my @fields =
            map {
                my ($field) = $_->get_code_attributes('Field');

                my @args;
                if ( $_->has_code_attributes('Arguments') ) {
                    my ($arguments) = $_->get_code_attributes('Arguments');

                    foreach my $arg ( $arguments->args->@* ) {
                        my ($name, $type) = split /\s*\:\s*/ => $arg;
                        push @args => Graph::QL::Schema::InputObject::InputValue->new(
                            name => $name,
                            type => Graph::QL::Util::Schemas::construct_type_from_name( $type ),
                        );
                    }
                }

                Graph::QL::Schema::Field->new(
                    name => $_->name,
                    type => Graph::QL::Util::Schemas::construct_type_from_name( $field->args->[0] ),
                    (@args ? (args => \@args) : ())
                );
            } grep {
                $_->has_code_attributes('Field')
            } $r->methods;

        push @types => Graph::QL::Schema::Object->new(
            name   => $namespace,
            fields => \@fields
        );
    }

    my ($query_type) = grep $_->name eq 'Query', @types;

    return $class->new(
        types      => \@types,
        query_type => Graph::QL::Util::Schemas::construct_type_from_name( $query_type->name ),
    );
}

sub BUILDARGS : strict(
    ast?               => _ast,
    types?             => _types,
    query_type?        => _query_type,
    mutation_type?     => _mutation_type,
    subscription_type? => _subscription_type,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {

        throw('The `ast` must be an instance of `Graph::QL::AST::Node::Document`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::Document' );

        # if we just got the AST, then we need to inflate
        # any of our sub-objects to be our wrappers ...

        if ( my $ast = $self->_get_query_type ) {
            $self->{_query_type} = Graph::QL::Schema::Type::Named->new( ast => $ast );
        }
        if ( my $ast = $self->_get_mutation_type ) {
            $self->{_mutation_type} = Graph::QL::Schema::Type::Named->new( ast => $ast );
        }
        if ( my $ast = $self->_get_subscription_type ) {
            $self->{_subscription_type} = Graph::QL::Schema::Type::Named->new( ast => $ast );
        }

        $self->{_types} = [
            map Graph::QL::Util::AST::ast_type_def_to_schema_type_def( $_ ), $self->_type_definitions->@*
        ];
    }
    else {
        # otherwise we need to make sure that we've been
        # given the write objects, so we can construct the
        # AST as well ...

        throw('The `query_type` must be an instance that does the role(Graph::QL::Schema::Type::Named), not %s', $self->{_query_type})
            unless assert_isa( $self->{_query_type}, 'Graph::QL::Schema::Type::Named' );

        if ( exists $params->{_mutation_type} ) {
           throw('The `mutation_type` must be an instance that does the role(Graph::QL::Schema::Type::Named), not %s', $self->{_mutation_type})
                unless assert_isa( $self->{_mutation_type}, 'Graph::QL::Schema::Type::Named' );
        }

        if ( exists $params->{_subscription_type} ) {
           throw('The `subscription_type` must be an instance that does the role(Graph::QL::Schema::Type::Named), not %s', $self->{_subscription_type})
                unless assert_isa( $self->{_subscription_type}, 'Graph::QL::Schema::Type::Named' );
        }

        # start with the base scalar types ...
        my @definitions;

        # So converting these is simple, just
        # as for the ast, ... getting them back
        # happens in the `types` method below
        foreach my $type ( $self->{_types}->@* ) {
            # TODO:
            # - check for `query` (and `mutation`, `subscription`) types being defined
            push @definitions => $type->ast;
        }

        push @definitions => Graph::QL::AST::Node::SchemaDefinition->new(
            operation_types => [
                Graph::QL::AST::Node::OperationTypeDefinition->new(
                    operation => Graph::QL::Core::OperationKind->QUERY,
                    type      => $self->{_query_type}->ast
                ),
                ($params->{_mutation_type} ?
                    Graph::QL::AST::Node::OperationTypeDefinition->new(
                        operation => Graph::QL::Core::OperationKind->MUTATION,
                        type      => $self->{_mutation_type}->ast
                    ) : ()),
                ($params->{_subscription_type} ?
                    Graph::QL::AST::Node::OperationTypeDefinition->new(
                        operation => Graph::QL::Core::OperationKind->SUBSCRIPTION,
                        type      => $self->{_subscription_type}->ast
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

sub get_query_type        : ro(_query_type);
sub get_mutation_type     : ro(_mutation_type);
sub get_subscription_type : ro(_subscription_type);

## ...

sub all_types : ro(_types);

sub lookup_type ($self, $name) {

    # coerce named types into strings ...
    $name = $name->name        if assert_isa( $name, 'Graph::QL::Schema::Type::Named' );
    $name = $name->name->value if assert_isa( $name, 'Graph::QL::AST::Node::NamedType' );

    my ($type_def) = grep $_->name eq $name, $self->all_types->@*;

    # look up in the built-in types ...
    if ( (not defined $type_def) && Graph::QL::Schema::BuiltIn::Scalars->has_scalar( $name ) ) {
        $type_def = Graph::QL::Schema::BuiltIn::Scalars->get_scalar( $name );
    }

    return $type_def;
}

sub lookup_root_type ($self, $op_kind) {

    # coerce operation objects into strings ...
    $op_kind = $op_kind->operation_kind if assert_isa( $op_kind, 'Graph::QL::Operation::Query' );
    $op_kind = $op_kind->operation      if assert_isa( $op_kind, 'Graph::QL::AST::Node::OperationDefinition' );

    throw('The kind(%s) is not a valid Operation::Kind', $op_kind)
        unless Graph::QL::Core::OperationKind->is_operation_kind( $op_kind );

    my $type;
    $type = $self->_get_query_type        if $op_kind eq Graph::QL::Core::OperationKind->QUERY;
    $type = $self->_get_mutation_type     if $op_kind eq Graph::QL::Core::OperationKind->MUTATION;
    $type = $self->_get_subscription_type if $op_kind eq Graph::QL::Core::OperationKind->SUBSCRIPTION;

    return undef unless $type;
    return $self->lookup_type( $type );
}

## ...

sub to_type_language ($self) {
    my $query        = $self->get_query_type;
    my $mutation     = $self->get_mutation_type;
    my $subscription = $self->get_subscription_type;

    return ($self->_has_type_definitions # print the types first ...
        ? ("\n".(join "\n\n" => map $_->to_type_language, $self->all_types->@*)."\n\n")
        : ''). # followed by the base `schema` object
        'schema {'."\n".
        ($query        ? ('    '.Graph::QL::Core::OperationKind->QUERY.' : '.$query->name."\n") : '').
        ($mutation     ? ('    '.Graph::QL::Core::OperationKind->MUTATION.' : '.$mutation->name."\n") : '').
        ($subscription ? ('    '.Graph::QL::Core::OperationKind->SUBSCRIPTION.' : '.$subscription->name."\n") : '').
        '}'.($self->_has_type_definitions ? "\n" : '');
}

## ...

# FIXME:
# There are some dangerous assumptions encoded below,
# such as the location of the schema defintion always
# being at index 0, and the order of the operations
# within the schema definiton being query, mutation,
# subscription, in that exact order.
#
# All this should be fixed, probably within the
# BUILD method actually. hmmm.
# - SL

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
