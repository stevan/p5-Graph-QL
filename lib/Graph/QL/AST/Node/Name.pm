package Graph::QL::AST::Node::Name;
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
    value => sub { die 'You must supply a `value`'},
);

sub BUILDARGS : strict(
    value     => value,
    location? => super(location),
);

sub BUILD ($self, $params) {

    throw('The `value` must be of type(string), not `%s`', $self->{value})
        unless assert_type_language_literal( $self->{value}, 'string' );
    
}

sub value : ro;

1;

__END__

=pod

=cut
