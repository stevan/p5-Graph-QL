package Graph::QL::Operation::Query;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_non_empty';

use Graph::QL::AST::Node::Document;
use Graph::QL::AST::Node::OperationDefinition;
use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::SelectionSet;

use Graph::QL::Operation::Field;

use Graph::QL::Core::OperationKind;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Operation';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => name,
    selections? => selections,
);
#   fragments?  => fragments, # TODO

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        throw('There must be at least one `selection`, not `%s`', scalar $params->{selections}->@* )
            unless assert_non_empty( $params->{selections} );

        foreach my $selection ( $params->{selections}->@* ) {
            throw('Every member of `selections` must be an instance of `Graph::QL::Operation::Field`, not `%s`', $selection)
                unless assert_isa( $selection, 'Graph::QL::Operation::Field' );
        }

        # TODO:
        # handle `variable_definitions` with Graph::QL::AST::Node::VariableDefinition
        # handle `directives`

        $self->{_ast} = Graph::QL::AST::Node::Document->new(
            definitions => [
                Graph::QL::AST::Node::OperationDefinition->new(
                    operation     => Graph::QL::Core::OperationKind->QUERY,
                    selection_set => Graph::QL::AST::Node::SelectionSet->new(
                        selections => [ map $_->ast, $params->{selections}->@* ]
                    ),
                    ($params->{name}
                        ? (name => Graph::QL::AST::Node::Name->new( value => $params->{name} ))
                        : ()),
                ),
                # TODO;
                # handle $params->{fragments} ...
            ]
        );
    }
}

sub ast : ro(_);

sub operation_kind ($self) { $self->_operation_definition->operation }

sub has_name ($self) { !! $self->_operation_definition->name }
sub name     ($self) { $self->_operation_definition->name->value }

sub selections ($self) {
    [ map Graph::QL::Operation::Field->new( ast => $_ ), $self->_operation_definition->selection_set->selections->@* ]
}

## ...

sub to_type_language ($self) {

    my $selections = join "\n    " => map { join "\n    " => split /\n/ => $_ } map $_->to_type_language, $self->selections->@*;

    return $self->operation_kind.' '.($self->has_name ? $self->name.' ' : '')."{\n    ".$selections."\n}";
}

## ...

sub _operation_definition     ($self) { ( grep  $_->isa('Graph::QL::AST::Node::OperationDefinition'), $self->ast->definitions->@* )[0] }
sub _fragment_definitions     ($self) { [ grep !$_->isa('Graph::QL::AST::Node::OperationDefinition'), $self->ast->definitions->@* ]    }
sub _has_fragment_definitions ($self) { (scalar $self->ast->definitions->@*) > 2 }

1;

__END__

=pod

=cut

