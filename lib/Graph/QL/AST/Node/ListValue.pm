package Graph::QL::AST::Node::ListValue;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';
use slots (
    values => sub { +[] },
);

sub BUILDARGS : strict(
    values?    => values,
    location?  => super(location),
);

sub BUILD ($self, $params) {

    throw('The `values` value must be an ARRAY ref')
        unless assert_arrayref( $self->{values} );
    
    foreach ( $self->{values}->@* ) {
        throw('The values in `values` must all be of type(Graph::QL::AST::Node::Role::Value), not `%s`', $_ )
            unless assert_does( $_, 'Graph::QL::AST::Node::Role::Value' );
    }
    
}

sub values : ro;

sub parsed_value ($self) { GraphQL::Util::Literals::parse_Value( $self->value ) }

1;

__END__

=pod

=cut
