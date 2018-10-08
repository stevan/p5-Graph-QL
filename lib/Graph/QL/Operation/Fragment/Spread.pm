package Graph::QL::Operation::Fragment::Spread;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_non_empty';

use Graph::QL::AST::Node::FragmentSpread;
use Graph::QL::AST::Node::Name;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use roles  'Graph::QL::Operation::Selection';
use slots (
    _ast        => sub {},
    _name       => sub {},
);

sub BUILDARGS : strict(
    ast?        => _ast,
    name?       => _name,
);

sub BUILD ($self, $params) {

    if ( exists $params->{_ast} ) {
        throw('The `ast` must be an instance of `Graph::QL::AST::Node::FragmentSpread`, not `%s`', $self->{_ast})
            unless assert_isa( $self->{_ast}, 'Graph::QL::AST::Node::FragmentSpread' );

        $self->{_name} = $self->{_ast}->name->value;

        # ...
    }
    else {

        throw('You must pass a defined value to `name`')
            unless defined $self->{_name};

        $self->{_ast} = Graph::QL::AST::Node::FragmentSpread->new(
            name => Graph::QL::AST::Node::Name->new( value => $self->{_name} ),
            # ...
            # directives?      => directives,     Graph::QL::AST::Node::Directive
        );
    }
}

sub ast  : ro(_);
sub name : ro(_);

## ...

sub to_type_language ($self) { '...'.$self->name }


1;

__END__

=pod

=cut

