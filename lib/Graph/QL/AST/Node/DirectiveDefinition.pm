package Graph::QL::AST::Node::DirectiveDefinition;
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
    name      => sub { die 'You must supply a `name`'},
    arguments => sub { +[] },
    locations => sub { +[] },
);

sub BUILDARGS : strict(
    name        => name,
    arguments?  => arguments,
    locations?  => locations,
    location?   => super(location),
);

sub BUILD ($self, $params) {

    throw('The `name` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{name})
        unless assert_isa( $self->{name}, 'Graph::QL::AST::Node::Name' );
    
    throw('The `arguments` value must be an ARRAY ref')
        unless assert_arrayref( $self->{arguments} );
    
    foreach ( $self->{arguments}->@* ) {
        throw('The values in `arguments` must all be of type(Graph::QL::AST::Node::InputValueDefinition), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::InputValueDefinition' );
    }
    
    throw('The `locations` value must be an ARRAY ref')
        unless assert_arrayref( $self->{locations} );
    
    foreach ( $self->{locations}->@* ) {
        throw('The values in `locations` must all be of type(Graph::QL::AST::Node::Name), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::Name' );
    }
    
}

sub name      : ro;
sub arguments : ro;
sub locations : ro;

1;

__END__

=pod

=cut
