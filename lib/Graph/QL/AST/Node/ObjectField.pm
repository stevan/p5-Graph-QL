package Graph::QL::AST::Node::ObjectField;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    name  => sub { die 'You must supply a `name`'},
    value => sub { die 'You must supply a `value`'},
);

sub BUILDARGS : strict(
    name     => name,
    value    => value,
    location => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
    Carp::confess('The `value` value must be an instance of `Graph::QL::AST::Node::Role::Value`, not '.$self->{value})
        unless Scalar::Util::blessed( $self->{value} )
            && $self->{value}->roles::DOES('Graph::QL::AST::Node::Role::Value');
    
}

sub name  : ro;
sub value : ro;

1;

__END__

=pod

=cut
