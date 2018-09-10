package Graph::QL::AST::Node::EnumTypeDefinition;

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
    name       => sub { die 'You must supply a `name`'},
    directives => sub { +[] },
    values     => sub { +[] },
);

sub BUILDARGS : strict(
    name        => name,
    directives? => directives,
    values?     => values,
    location    => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
    Carp::confess('The `directives` value must be an ARRAY ref')
        unless ref $self->{directives} eq 'ARRAY';
    
    if ( $self->{directives}->@* ) {
        foreach ( $self->{directives}->@* ) {
            Carp::confess('The values in `directives` value must be an instance of `Graph::QL::AST::Node::Directive`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::Directive');
        }
    }
    
    Carp::confess('The `values` value must be an ARRAY ref')
        unless ref $self->{values} eq 'ARRAY';
    
    if ( $self->{values}->@* ) {
        foreach ( $self->{values}->@* ) {
            Carp::confess('The values in `values` value must be an instance of `Graph::QL::AST::Node::EnumValueDefinition`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::EnumValueDefinition');
        }
    }
    
}

sub name       : ro;
sub directives : ro;
sub values     : ro;

1;

__END__

=pod

=cut
