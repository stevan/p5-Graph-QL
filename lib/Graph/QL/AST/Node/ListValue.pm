package Graph::QL::AST::Node::ListValue;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';
use slots (
    values => sub { +[] },
);

sub BUILDARGS : strict(
    values?   => values,
    location  => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `values` value must be an ARRAY ref')
        unless ref $self->{values} eq 'ARRAY';
    
    if ( $self->{values}->@* ) {
        foreach ( $self->{values}->@* ) {
            Carp::confess('The values in `values` value must be an instance of `Graph::QL::AST::Node::Role::Value`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->roles::DOES('Graph::QL::AST::Node::Role::Value');
        }
    }
    
}

sub values : ro;

1;

__END__

=pod

=cut
