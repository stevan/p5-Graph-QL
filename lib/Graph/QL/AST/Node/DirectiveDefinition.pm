package Graph::QL::AST::Node::DirectiveDefinition;

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
    name      => sub { die 'You must supply a `name`'},
    arguments => sub { +[] },
    locations => sub { +[] },
);

sub BUILDARGS : strict(
    name       => name,
    arguments? => arguments,
    locations? => locations,
    location   => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
    Carp::confess('The `arguments` value must be an ARRAY ref')
        unless ref $self->{arguments} eq 'ARRAY';
    
    if ( $self->{arguments}->@* ) {
        foreach ( $self->{arguments}->@* ) {
            Carp::confess('The values in `arguments` value must be an instance of `Graph::QL::AST::Node::InputValueDefinition`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::InputValueDefinition');
        }
    }
    
    Carp::confess('The `locations` value must be an ARRAY ref')
        unless ref $self->{locations} eq 'ARRAY';
    
    if ( $self->{locations}->@* ) {
        foreach ( $self->{locations}->@* ) {
            Carp::confess('The values in `locations` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::Name');
        }
    }
    
}

sub name      : ro;
sub arguments : ro;
sub locations : ro;

1;

__END__

=pod

=cut
