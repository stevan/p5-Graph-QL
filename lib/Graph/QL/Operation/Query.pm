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
use slots ( 
    _ast        => sub {},
    _name       => sub {},
    _selections => sub {},
);

sub new_from_source ($class, $source) {
    require Graph::QL::Parser;
    $class->new( ast => Graph::QL::Parser->parse_operation( $source ) )
}

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => _name,
    selections? => _selections,
);
#   fragments?  => fragments, # TODO

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::Document`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::Document' );

        if ( $self->_operation_definition->name ) {
            $self->{_name} = $self->_operation_definition->name->value;
        }

        $self->{_selections} = [ 
            map Graph::QL::Operation::Field->new( ast => $_ ), 
                $self->_operation_definition->selection_set->selections->@* 
        ];
    }
    else {

        throw('There must be at least one `selection`, not `%s`', scalar $self->{_selections}->@* )
            unless assert_non_empty( $self->{_selections} );

        foreach ( $self->{_selections}->@* ) {
           throw('Every member of `selections` must be an instance of `Graph::QL::Operation::Field`, not `%s`', $_)
                unless assert_isa( $_, 'Graph::QL::Operation::Field' );
        }

        # TODO:
        # handle `variable_definitions` with Graph::QL::AST::Node::VariableDefinition
        # handle `directives`

        $self->{_ast} = Graph::QL::AST::Node::Document->new(
            definitions => [
                Graph::QL::AST::Node::OperationDefinition->new(
                    operation     => Graph::QL::Core::OperationKind->QUERY,
                    selection_set => Graph::QL::AST::Node::SelectionSet->new(
                        selections => [ map $_->ast, $self->{_selections}->@* ]
                    ),
                    ($params->{_name}
                        ? (name => Graph::QL::AST::Node::Name->new( value => $self->{_name} ))
                        : ()),
                ),
                # TODO;
                # handle $params->{fragments} ...
            ]
        );
    }
}

sub ast        : ro(_);
sub has_name   : predicate(_);
sub name       : ro(_);
sub selections : ro(_);

sub operation_kind ($self) { $self->_operation_definition->operation }

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

