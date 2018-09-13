package Graph::QL::AST::Node::ListValue;
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
    values => sub { +[] },
);

sub BUILDARGS : strict(
    values?    => values,
    location?  => super(location),
);

sub BUILD ($self, $params) {

    throw('The `values` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{values} );
    
    foreach ( $self->{values}->@* ) {
         throw('The values in `values` must all be of type(Graph::QL::AST::Node::Role::Value), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->roles::DOES('Graph::QL::AST::Node::Role::Value');
    }
    
}

sub values : ro;

1;

__END__

=pod

=cut
