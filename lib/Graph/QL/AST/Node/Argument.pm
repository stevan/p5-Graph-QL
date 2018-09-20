package Graph::QL::AST::Node::Argument;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    name  => sub { die 'You must supply a `name`'},
    value => sub { die 'You must supply a `value`'},
);

sub BUILDARGS : strict(
    name      => name,
    value     => value,
    location? => super(location),
);

sub BUILD ($self, $params) {

    throw('The `name` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{name})
        unless assert_isa( $self->{name}, 'Graph::QL::AST::Node::Name');
    
    throw('The `value` must be of type(Graph::QL::AST::Node::Role::Value), not `%s`', $self->{value})
        unless assert_does( $self->{value}, 'Graph::QL::AST::Node::Role::Value');
    
}

sub name  : ro;
sub value : ro;

1;

__END__

=pod

=cut
