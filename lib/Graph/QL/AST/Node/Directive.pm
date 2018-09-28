package Graph::QL::AST::Node::Directive;
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
    name      => sub { die 'You must supply a `name`'},
    arguments => sub { +[] },
);

sub BUILDARGS : strict(
    name        => name,
    arguments?  => arguments,
    location?   => super(location),
);

sub BUILD ($self, $params) {

    throw('The `name` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{name})
        unless assert_isa( $self->{name}, 'Graph::QL::AST::Node::Name');
    
    throw('The `arguments` value must be an ARRAY ref')
        unless assert_arrayref( $self->{arguments} );
    
    foreach ( $self->{arguments}->@* ) {
        throw('The values in `arguments` must all be of type(Graph::QL::AST::Node::Argument), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::Argument');
    }
    
}

sub name      : ro;
sub arguments : ro;

1;

__END__

=pod

=cut
