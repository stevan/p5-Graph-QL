package Graph::QL::AST::Node::TypeExtensionDefinition;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Definition';
use slots (
    definition => sub { die 'You must supply a `definition`'},
);

sub BUILDARGS : strict(
    definition => definition,
    location   => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `definition` value must be an instance of `Graph::QL::AST::Node::ObjectTypeDefinition`, not '.$self->{definition})
        unless Scalar::Util::blessed( $self->{definition} )
            && $self->{definition}->isa('Graph::QL::AST::Node::ObjectTypeDefinition');
    
}

sub definition : ro;

1;

__END__

=pod

=cut
