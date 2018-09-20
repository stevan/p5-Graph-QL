package Graph::QL::AST::Node::NonNullType;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Type';
use slots (
    type => sub { die 'You must supply a `type`'},
);

sub BUILDARGS : strict(
    type      => type,
    location? => super(location),
);

sub BUILD ($self, $params) {

    throw('The `type` must be of type(Graph::QL::AST::Node::Role::Type), not `%s`', $self->{type})
        unless assert_does( $self->{type}, 'Graph::QL::AST::Node::Role::Type');
    
}

sub type : ro;

1;

__END__

=pod

=cut
