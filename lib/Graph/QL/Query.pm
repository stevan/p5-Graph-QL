package Graph::QL::Query;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::AST::Node::OperationDefinition;
use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::SelectionSet;

use Graph::QL::Query::Field;

our $VERSION = '0.01';

use constant ANON_NAME => '__ANON__';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Core::Operation';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => name,
    selections? => selections,
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {
        $params->{name} ||= ANON_NAME;

        # TODO:
        # check `selections` is Graph::QL::Query::Field

        # TODO:
        # handle `variable_definitions` with Graph::QL::AST::Node::VariableDefinition
        # handle `directives`

        $self->{_ast} = Graph::QL::AST::Node::OperationDefinition->new(
            operation     => Graph::QL::Core::Operation->Kind->QUERY,
            name          => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            selection_set => Graph::QL::AST::Node::SelectionSet->new(
                selections => [ map $_->ast, $params->{selections}->@* ]
            )
        );
    }
}

sub ast : ro(_);

sub operation_kind ($self) { $self->ast->operation }

sub name    ($self) { $self->ast->name->value  }
sub is_anon ($self) { $self->name eq ANON_NAME }

sub has_selections ($self) { !! scalar $self->ast->selection_set->selections->@* }
sub selections ($self) {
    [ map Graph::QL::Query::Field->new( ast => $_ ), $self->ast->selection_set->selections->@* ]
}

## ...

sub to_type_language ($self) {

    my $selections = join "\n    " => map { join "\n    " => split /\n/ => $_ } map $_->to_type_language, $self->selections->@*;

    return $self->operation_kind.' '.($self->is_anon ? '' : $self->name.' ')."{\n    ".$selections."\n}";
}

1;

__END__

=pod

=cut

