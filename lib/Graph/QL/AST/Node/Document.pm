package Graph::QL::AST::Node::Document;
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
    definitions => sub { +[] },
);

sub BUILDARGS : strict(
    definitions?  => definitions,
    location?     => super(location),
);

sub BUILD ($self, $params) {

    throw('The `definitions` value must be an ARRAY ref')
        unless assert_arrayref( $self->{definitions} );
    
    foreach ( $self->{definitions}->@* ) {
        throw('The values in `definitions` must all be of type(Graph::QL::AST::Node::Role::Definition), not `%s`', $_ )
            unless assert_does( $_, 'Graph::QL::AST::Node::Role::Definition' );
    }
    
}

sub definitions : ro;

1;

__END__

=pod

=cut
