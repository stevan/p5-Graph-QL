package Graph::QL::AST::Node::FragmentDefinition;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Definition';
use slots (
    name           => sub { die 'You must supply a `name`'},
    type_condition => sub { die 'You must supply a `type_condition`'},
    directives     => sub { +[] },
    selection_set  => sub { die 'You must supply a `selection_set`'},
);

sub BUILDARGS : strict(
    name             => name,
    type_condition   => type_condition,
    directives?      => directives,
    selection_set    => selection_set,
    location?        => super(location),
);

sub BUILD ($self, $params) {

    throw('The `name` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{name})
        unless assert_isa( $self->{name}, 'Graph::QL::AST::Node::Name');
    
    throw('The `type_condition` must be of type(Graph::QL::AST::Node::NamedType), not `%s`', $self->{type_condition})
        unless assert_isa( $self->{type_condition}, 'Graph::QL::AST::Node::NamedType');
    
    throw('The `directives` value must be an ARRAY ref')
        unless assert_arrayref( $self->{directives} );
    
    foreach ( $self->{directives}->@* ) {
        throw('The values in `directives` must all be of type(Graph::QL::AST::Node::Directive), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::Directive');
    }
    
    throw('The `selection_set` must be of type(Graph::QL::AST::Node::SelectionSet), not `%s`', $self->{selection_set})
        unless assert_isa( $self->{selection_set}, 'Graph::QL::AST::Node::SelectionSet');
    
}

sub name           : ro;
sub type_condition : ro;
sub directives     : ro;
sub selection_set  : ro;

1;

__END__

=pod

=cut
