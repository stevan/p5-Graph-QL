package Graph::QL::AST::Node::FloatValue;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';
use slots (
    value => sub { die 'You must supply a `value`'},
);

sub BUILDARGS : strict(
    value     => value,
    location? => super(location),
);

sub BUILD ($self, $params) {

    throw('The `value` must be of type(string), not `%s`', $self->{value})
        unless defined $self->{value};
    
}

sub value : ro;

1;

__END__

=pod

=cut
