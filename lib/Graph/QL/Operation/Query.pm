package Graph::QL::Operation::Query;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does', 'assert_non_empty';

use Graph::QL::AST::Node::OperationDefinition;
use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::SelectionSet;

use Graph::QL::Operation::Field;
use Graph::QL::Operation::Fragment::Spread;

use Graph::QL::Core::OperationKind;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast        => sub {},
    _name       => sub {},
    _selections => sub {},
);

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => _name,
    selections? => _selections,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::OperationDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::OperationDefinition' );

        if ( $self->{_ast}->name ) {
            $self->{_name} = $self->{_ast}->name->value;
        }

        $self->{_selections} = [
            map {
                $_->isa('Graph::QL::AST::Node::FragmentSpread')
                    ? Graph::QL::Operation::Fragment::Spread->new( ast => $_ )
                    : Graph::QL::Operation::Field->new( ast => $_ )
            } $self->{_ast}->selection_set->selections->@*
        ];
    }
    else {

        throw('There must be at least one `selection`, not `%s`', scalar $self->{_selections}->@* )
            unless assert_non_empty( $self->{_selections} );

        foreach ( $self->{_selections}->@* ) {
           throw('Every member of `selections` must be an instance that does `Graph::QL::Core::Selection`, not `%s`', $_)
                unless assert_does( $_, 'Graph::QL::Core::Selection' );
        }

        # TODO:
        # handle `variable_definitions` with Graph::QL::AST::Node::VariableDefinition
        # handle `directives`

        $self->{_ast} = Graph::QL::AST::Node::OperationDefinition->new(
            operation     => Graph::QL::Core::OperationKind->QUERY,
            selection_set => Graph::QL::AST::Node::SelectionSet->new(
                selections => [ map $_->ast, $self->{_selections}->@* ]
            ),
            ($params->{_name}
                ? (name => Graph::QL::AST::Node::Name->new( value => $self->{_name} ))
                : ()),
        );
    }
}

sub ast        : ro(_);
sub has_name   : predicate(_);
sub name       : ro(_);
sub selections : ro(_);

sub operation_kind ($self) { $self->{_ast}->operation }

## ...

sub to_type_language ($self) {

    my $selections = join "\n    " => (
        map { join "\n    " => split /\n/ => $_  }
        map $_->to_type_language,
            $self->selections->@*
    );

    return $self->operation_kind.' '.($self->has_name ? $self->name.' ' : '')."{\n    ".$selections."\n}";
}

1;

__END__

=pod

=cut

