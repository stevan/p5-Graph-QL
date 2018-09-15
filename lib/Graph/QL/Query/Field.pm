package Graph::QL::Query::Field;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::Field;
use Graph::QL::AST::Node::SelectionSet;

use Graph::QL::Query::Argument;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( _ast => sub {} );

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => name,
    alias?      => alias,
    args?       => args,
    selections? => selections
);

sub BUILD ($self, $params) {

    if ( not exists $params->{_ast} ) {

        # TODO:
        # check `selections` is Graph::QL::Query::Field
        # check `args` is Graph::QL::Query::Argument

        $self->{_ast} = Graph::QL::AST::Node::Field->new(
            name => Graph::QL::AST::Node::Name->new( value => $params->{name} ),
            ($params->{alias} ? (alias => Graph::QL::AST::Node::Name->new( value => $params->{alias} )) : ()),
            ($params->{selections}
                ? (selection_set => Graph::QL::AST::Node::SelectionSet->new( selections => [ map $_->ast, $params->{selections}->@* ] ))
                : ()),
            ($params->{args}
                ? (arguments => [ map $_->ast, $params->{args}->@* ])
                : ()),
        );
    }
}

sub ast : ro(_);

sub name ($self) { $self->ast->name->value }

sub has_alias ($self) { !! $self->ast->alias        }
sub alias     ($self) {    $self->ast->alias->value }

sub has_args ($self) { !! scalar $self->ast->arguments->@* }
sub args ($self) {
    [ map Graph::QL::Query::Argument->new( ast => $_ ), $self->ast->arguments->@* ]
}

sub has_selections ($self) { !! $self->ast->selection_set && scalar $self->ast->selection_set->selections->@* }
sub selections ($self) {
    return [] unless $self->has_selections;
    return [ map Graph::QL::Query::Field->new( ast => $_ ), $self->ast->selection_set->selections->@* ];
}

## ...

sub to_type_language ($self) {

    my $name       = ($self->has_alias      ? ($self->alias.' : ') : '').$self->name;
    my $args       = ($self->has_args       ? ('('.(join ', ' => map $_->to_type_language, $self->args->@*).')') : '');
    my $selections = ($self->has_selections ? (" {\n    ".(join "\n    " => map {join "\n    " => split /\n/ => $_ } map $_->to_type_language, $self->selections->@*)."\n}"):'');

    return $name.$args.$selections;
}


1;

__END__

=pod

=cut

