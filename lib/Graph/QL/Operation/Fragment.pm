package Graph::QL::Operation::Fragment;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does', 'assert_non_empty';

use Graph::QL::AST::Node::FragmentDefinition;
use Graph::QL::AST::Node::Name;

use Graph::QL::Operation::Field;
use Graph::QL::Operation::Fragment::Spread;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _ast            => sub {},
    _name           => sub {},
    _type_condition => sub {},
    _selections     => sub {},
);

sub BUILDARGS : strict(
    ast?            => _ast,
    name?           => _name,
    type_condition? => _type_condition,
    selections?     => _selections,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::FragmentDefinition`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::FragmentDefinition' );

        $self->{_name}           = $self->{_ast}->name->value;
        $self->{_type_condition} = Graph::QL::Schema::Type::Named->new(
            ast => $self->{_ast}->type_condition
        );

        $self->{_selections} = [
            map {
                $_->isa('Graph::QL::AST::Node::FragmentSpread')
                    ? Graph::QL::Operation::Fragment::Spread->new( ast => $_ )
                    : Graph::QL::Operation::Field->new( ast => $_ )
            } $self->_operation_definition->selection_set->selections->@*
        ];
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        throw('The `type_condition` must be an instance of `Graph::QL::Schema::Type::Named`, not `%s`', $_)
                unless assert_isa( $self->{_type_condition}, 'Graph::QL::Schema::Type::Named' );

        throw('There must be at least one `selection`, not `%s`', scalar $self->{_selections}->@* )
            unless assert_non_empty( $self->{_selections} );

        foreach ( $self->{_selections}->@* ) {
           throw('Every member of `selections` must be an instance that does `Graph::QL::Core::Selection`, not `%s`', $_)
                unless assert_does( $_, 'Graph::QL::Core::Selection' );
        }

        $self->{_ast} = Graph::QL::AST::Node::FragmentDefinition->new(
            name           => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            type_condition => $self->{_type_condition}->ast,
            selection_set  => Graph::QL::AST::Node::SelectionSet->new( selections => [ map $_->ast, $self->{_selections}->@* ] ),
            # directives?      => directives,     Graph::QL::AST::Node::Directive
        );
    }
}

sub ast            : ro(_);
sub name           : ro(_);
sub type_condition : ro(_);
sub selections     : ro(_);

## ...

sub to_type_language ($self) {

    my $selections = join "\n    " => (
        map { join "\n    " => split /\n/ => $_  }
        map $_->to_type_language,
            $self->selections->@*
    );

    return 'fragment '.$self->name.' on '.$self->type_condition->name." {\n    ".$selections."\n}";
}


1;

__END__

=pod

=cut

