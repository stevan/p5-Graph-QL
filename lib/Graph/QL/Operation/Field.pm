package Graph::QL::Operation::Field;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_non_empty';

use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::Field;
use Graph::QL::AST::Node::SelectionSet;

use Graph::QL::Operation::Field::Argument;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Core::Field';
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

        throw('You must pass a defined value to `name`')
            unless defined $params->{name};

        if ( exists $params->{alias} ) {
           throw('You must pass a defined value to `alias`')
                unless defined $params->{alias};
        }

        if ( exists $params->{selections} ) {

           throw('There must be at least one `selection`, not `%s`', scalar $params->{selections}->@* )
                unless assert_non_empty( $params->{selections} );

            foreach my $selection ( $params->{selections}->@* ) {
               throw('Every member of `selections` must be an instance of `Graph::QL::Operation::Field`, not `%s`', $selection)
                    unless assert_isa( $selection, 'Graph::QL::Operation::Field' );
            }
        }

        if ( exists $params->{args} ) {
            foreach my $arg ( $params->{args}->@* ) {
               throw('Every member of `args` must be an instance of `Graph::QL::Operation::Field::Argument`, not `%s`', $arg)
                    unless assert_isa( $arg, 'Graph::QL::Operation::Field::Argument' );
            }
        }

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

sub arity ($self) { scalar $self->ast->arguments->@* }

sub has_args ($self) { !! scalar $self->ast->arguments->@* }
sub args ($self) {
    [ map Graph::QL::Operation::Field::Argument->new( ast => $_ ), $self->ast->arguments->@* ]
}

sub has_selections ($self) { !! $self->ast->selection_set && scalar $self->ast->selection_set->selections->@* }
sub selections ($self) {
    return [] unless $self->has_selections;
    return [ map Graph::QL::Operation::Field->new( ast => $_ ), $self->ast->selection_set->selections->@* ];
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

