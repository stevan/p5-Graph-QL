package Graph::QL::AST::Node::UnionTypeDefinition;

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
    types      => sub { +[] },
);

sub BUILDARGS : strict(
    name        => name,
    directives? => directives,
    types?      => types,
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
    
    Carp::confess('The `types` value must be an ARRAY ref')
        unless ref $self->{types} eq 'ARRAY';
    
    if ( $self->{types}->@* ) {
        foreach ( $self->{types}->@* ) {
            Carp::confess('The values in `types` value must be an instance of `Graph::QL::AST::Node::NamedType`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::NamedType');
        }
    }
    
}

sub name       : ro;
sub directives : ro;
sub types      : ro;

1;

__END__

=pod

=cut
