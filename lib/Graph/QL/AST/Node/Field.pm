package Graph::QL::AST::Node::Field;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Selection';
use slots (
    alias         => sub {},
    name          => sub { die 'You must supply a `name`'},
    arguments     => sub { +[] },
    directives    => sub { +[] },
    selection_set => sub {},
);

sub BUILDARGS : strict(
    alias?         => alias,
    name           => name,
    arguments?     => arguments,
    directives?    => directives,
    selection_set? => selection_set,
    location       => super(location),
);

sub BUILD ($self, $params) {

    if ( exists $params->{alias} ) {
        Carp::confess('The `alias` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{alias})
            unless Scalar::Util::blessed( $self->{alias} )
                && $self->{alias}->isa('Graph::QL::AST::Node::Name');
    }
    
    Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
        unless Scalar::Util::blessed( $self->{name} )
            && $self->{name}->isa('Graph::QL::AST::Node::Name');
    
    Carp::confess('The `arguments` value must be an ARRAY ref')
        unless ref $self->{arguments} eq 'ARRAY';
    
    if ( $self->{arguments}->@* ) {
        foreach ( $self->{arguments}->@* ) {
            Carp::confess('The values in `arguments` value must be an instance of `Graph::QL::AST::Node::Argument`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::Argument');
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
    
    if ( exists $params->{selection_set} ) {
        Carp::confess('The `selection_set` value must be an instance of `Graph::QL::AST::Node::SelectionSet`, not '.$self->{selection_set})
            unless Scalar::Util::blessed( $self->{selection_set} )
                && $self->{selection_set}->isa('Graph::QL::AST::Node::SelectionSet');
    }
    
}

sub alias         : ro;
sub name          : ro;
sub arguments     : ro;
sub directives    : ro;
sub selection_set : ro;

1;

__END__

=pod

=cut
