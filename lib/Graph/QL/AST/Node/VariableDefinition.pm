package Graph::QL::AST::Node::VariableDefinition;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    variable      => sub { die 'You must supply a `variable`'},
    type          => sub { die 'You must supply a `type`'},
    default_value => sub {},
);

sub BUILDARGS : strict(
    variable       => variable,
    type           => type,
    default_value? => default_value,
    location       => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `variable` value must be an instance of `Graph::QL::AST::Node::Variable`, not '.$self->{variable})
        unless Scalar::Util::blessed( $self->{variable} )
            && $self->{variable}->isa('Graph::QL::AST::Node::Variable');
    
    Carp::confess('The `type` value must be an instance of `Graph::QL::AST::Node::Role::Type`, not '.$self->{type})
        unless Scalar::Util::blessed( $self->{type} )
            && $self->{type}->roles::DOES('Graph::QL::AST::Node::Role::Type');
    
    if ( exists $params->{default_value} ) {
        Carp::confess('The `default_value` value must be an instance of `Graph::QL::AST::Node::Role::Value`, not '.$self->{default_value})
            unless Scalar::Util::blessed( $self->{default_value} )
                && $self->{default_value}->roles::DOES('Graph::QL::AST::Node::Role::Value');
    }
    
}

sub variable      : ro;
sub type          : ro;
sub default_value : ro;

1;

__END__

=pod

=cut
