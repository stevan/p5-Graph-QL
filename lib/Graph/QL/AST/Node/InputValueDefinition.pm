package Graph::QL::AST::Node::InputValueDefinition;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    name          => sub { die 'You must supply a `name`'},
    type          => sub { die 'You must supply a `type`'},
    default_value => sub {},
    directives    => sub { +[] },
);

sub BUILDARGS : strict(
    name           => name,
    type           => type,
    default_value? => default_value,
    directives?    => directives,
    location       => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
    Carp::confess('The `type` value must be an instance of `Graph::QL::AST::Node::Role::Type`, not '.$self->{type})
        unless Scalar::Util::blessed( $self->{type} )
            && $self->{type}->roles::DOES('Graph::QL::AST::Node::Role::Type');
    
    if ( exists $params->{default_value} ) {
        Carp::confess('The `default_value` value must be an instance of `Graph::QL::AST::Node::Role::Value`, not '.$self->{default_value})
            unless Scalar::Util::blessed( $self->{default_value} )
                && $self->{default_value}->roles::DOES('Graph::QL::AST::Node::Role::Value');
    }
    
    Carp::confess('The `directives` value must be an ARRAY ref')
        unless ref $self->{directives} eq 'ARRAY';
    
    if ( $self->{directives}->@* ) {
        foreach ( $self->{directives}->@* ) {
            Carp::confess('The values in `directives` value must be an instance of `Graph::QL::AST::Node::Directive`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::Directive');
        }
    }
    
}

sub name          : ro;
sub type          : ro;
sub default_value : ro;
sub directives    : ro;

1;

__END__

=pod

=cut
