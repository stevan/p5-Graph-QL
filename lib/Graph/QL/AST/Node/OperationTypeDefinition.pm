package Graph::QL::AST::Node::OperationTypeDefinition;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    operation => sub { die 'You must supply a `operation`'},
    type      => sub { die 'You must supply a `type`'},
);

sub BUILDARGS : strict(
    operation => operation,
    type      => type,
    location  => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `operation` value must be an `OperationKind`')
        unless defined $self->{operation};
    
    Carp::confess('The `type` value must be an instance of `Graph::QL::AST::Node::NamedType`, not '.$self->{type})
        unless Scalar::Util::blessed( $self->{type} )
            && $self->{type}->isa('Graph::QL::AST::Node::NamedType');
    
}

sub operation : ro;
sub type      : ro;

1;

__END__

=pod

=cut
