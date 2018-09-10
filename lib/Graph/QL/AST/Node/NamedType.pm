package Graph::QL::AST::Node::NamedType;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Type';
use slots (
    name => sub { die 'You must supply a `name`'},
);

sub BUILDARGS : strict(
    name     => name,
    location => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
}

sub name : ro;

1;

__END__

=pod

=cut
