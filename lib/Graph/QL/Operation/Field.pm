package Graph::QL::Operation::Field;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does', 'assert_non_empty';

use Graph::QL::AST::Node::Name;
use Graph::QL::AST::Node::Field;
use Graph::QL::AST::Node::SelectionSet;

use Graph::QL::Operation::Fragment::Spread;
use Graph::QL::Operation::Field::Argument;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Core::Selection';
use slots (
    _ast        => sub {},
    _name       => sub {},
    _alias      => sub {},
    _args       => sub {},
    _selections => sub {},
);

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => _name,
    alias?      => _alias,
    args?       => _args,
    selections? => _selections
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::Field`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::Field' );

        $self->{_name} = $self->{_ast}->name->value;

        if ( my $alias = $self->ast->alias ) {
            $self->{_alias} = $alias->value;
        }

        $self->{_args} = [
            map Graph::QL::Operation::Field::Argument->new( ast => $_ ), $self->{_ast}->arguments->@*
        ];

        if ( $self->{_ast}->selection_set ) {
            $self->{_selections} = [
                map {
                    $_->isa('Graph::QL::AST::Node::FragmentSpread')
                        ? Graph::QL::Operation::Fragment::Spread->new( ast => $_ )
                        : Graph::QL::Operation::Field->new( ast => $_ )
                } $self->{_ast}->selection_set->selections->@*
            ];
        }

    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        if ( exists $params->{_alias} ) {
           throw('You must pass a defined value to `alias`')
                unless defined $self->{_alias};
        }

        if ( exists $params->{_selections} ) {

           throw('There must be at least one `selection`, not `%s`', scalar $self->{_selections}->@* )
                unless assert_non_empty( $self->{_selections} );

            foreach ( $self->{_selections}->@* ) {
               throw('Every member of `selections` must be an instance that does `Graph::QL::Core::Selection`, not `%s`', $_)
                    unless assert_does( $_, 'Graph::QL::Core::Selection' );
            }
        }

        if ( exists $params->{_args} ) {
            foreach ( $self->{_args}->@* ) {
               throw('Every member of `args` must be an instance of `Graph::QL::Operation::Field::Argument`, not `%s`', $_)
                    unless assert_isa( $_, 'Graph::QL::Operation::Field::Argument' );
            }
        }

        $self->{_ast} = Graph::QL::AST::Node::Field->new(
            name => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            ($params->{_alias} ? (alias => Graph::QL::AST::Node::Name->new( value => $self->{_alias} )) : ()),
            ($params->{_selections}
                ? (selection_set => Graph::QL::AST::Node::SelectionSet->new( selections => [ map $_->ast, $self->{_selections}->@* ] ))
                : ()),
            ($params->{_args}
                ? (arguments => [ map $_->ast, $self->{_args}->@* ])
                : ()),
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);

sub has_alias : predicate(_);
sub alias     : ro(_);

sub args     : ro(_);
sub has_args ($self) { $self->{_args} && scalar $self->{_args}->@* }
sub arity    ($self) {                   scalar $self->{_args}->@* }

sub selections : ro(_);
sub has_selections ($self) { $self->{_selections} && scalar $self->{_selections}->@* }

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

