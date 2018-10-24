package Graph::QL::Operation;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does', 'assert_non_empty';

use Graph::QL::AST::Node::Document;

use Graph::QL::Util::AST;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast         => sub {},
    _definitions => sub {},
);

sub new_from_source ($class, $source) {
    require Graph::QL::Parser;
    $class->new( ast => Graph::QL::Parser->parse_operation( $source ) )
}

sub BUILDARGS : strict(
    ast?         => _ast,
    definitions? => _definitions,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::Document`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::Document' );

        $self->{_definitions} = [
            map Graph::QL::Util::AST::ast_def_to_operation_def( $_ ),
                $self->{_ast}->definitions->@*
        ];
    }
    else {

        throw('There must be at least one `definition`, not `%s`', scalar $self->{_definitions}->@* )
            unless assert_non_empty( $self->{_definitions} );

        foreach ( $self->{_definitions}->@* ) {
           throw('Every member of `definitions` must be an instance that does `Graph::QL::Operation::*`, not `%s`', $_)
                unless assert_isa( $_, 'Graph::QL::Operation::Query' )
                    || assert_isa( $_, 'Graph::QL::Operation::Fragment' );
                  # TODO: make a polymorphic subtype to encapsulation all these
                  # ||  assert_does( $_, 'Graph::QL::Operation::Mutation' )
                  # ||  assert_does( $_, 'Graph::QL::Operation::Subscription' );
        }

        $self->{_ast} = Graph::QL::AST::Node::Document->new(
            definitions => [ map $_->ast, $self->{_definitions}->@* ]
        );
    }
}

sub ast         : ro(_);
sub definitions : ro(_);

sub has_fragments ($self) { !! scalar grep $_->isa('Graph::QL::Operation::Fragment'), $self->{_definitions}->@* }
sub get_fragments ($self) {           grep $_->isa('Graph::QL::Operation::Fragment'), $self->{_definitions}->@* }

# FIXME:
# the code below makes the assumption that the
# query is going to always be at index 0, which
# shouldn't need to be the case.
#
# All this should be fixed, probably within the
# BUILD method actually. hmmm.
# - SL

sub has_query ($self) { !! scalar grep $_->isa('Graph::QL::Operation::Query'), $self->{_definitions}->@*     }
sub get_query ($self) {          (grep $_->isa('Graph::QL::Operation::Query'), $self->{_definitions}->@*)[0] }

# TODO:
# sub get_mutation     ($self) { grep !$_->isa('Graph::QL::Operation::Mutation'),     $self->definitions->@* }
# sub get_subscription ($self) { grep !$_->isa('Graph::QL::Operation::Subscription'), $self->definitions->@* }

sub lookup_fragment ($self, $name) {

    # coerce named types into strings ...
    $name = $name->name if assert_isa( $name, 'Graph::QL::Operation::Selection::FragmentSpread' );

    my ($fragment) = grep $_->name eq $name, $self->get_fragments;

    return $fragment;
}

## ...

sub to_type_language ($self) {
    return join '' => map $_->to_type_language, $self->definitions->@*;
}

## ...

1;

__END__

=pod

=cut

