package Graph::QL::AST::Node::ObjectTypeDefinition;

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
    interfaces => sub { +[] },
    directives => sub { +[] },
    fields     => sub { +[] },
);

sub BUILDARGS : strict(
    name        => name,
    interfaces? => interfaces,
    directives? => directives,
    fields?     => fields,
    location    => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
    Carp::confess('The `interfaces` value must be an ARRAY ref')
        unless ref $self->{interfaces} eq 'ARRAY';
    
    if ( $self->{interfaces}->@* ) {
        foreach ( $self->{interfaces}->@* ) {
            Carp::confess('The values in `interfaces` value must be an instance of `Graph::QL::AST::Node::NamedType`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::NamedType');
        }
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
    
    Carp::confess('The `fields` value must be an ARRAY ref')
        unless ref $self->{fields} eq 'ARRAY';
    
    if ( $self->{fields}->@* ) {
        foreach ( $self->{fields}->@* ) {
            Carp::confess('The values in `fields` value must be an instance of `Graph::QL::AST::Node::FieldDefinition`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::FieldDefinition');
        }
    }
    
}

sub name       : ro;
sub interfaces : ro;
sub directives : ro;
sub fields     : ro;

1;

__END__

=pod

=cut
