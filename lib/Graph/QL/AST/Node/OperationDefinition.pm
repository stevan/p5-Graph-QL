package Graph::QL::AST::Node::OperationDefinition;

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
    operation            => sub { die 'You must supply a `operation`'},
    name                 => sub {},
    variable_definitions => sub { +[] },
    directives           => sub { +[] },
    selection_set        => sub { die 'You must supply a `selection_set`'},
);

sub BUILDARGS : strict(
    operation             => operation,
    name?                 => name,
    variable_definitions? => variable_definitions,
    directives?           => directives,
    selection_set         => selection_set,
    location              => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `operation` value must be an `OperationKind`')
        unless defined $self->{operation};
    
    if ( exists $params->{name} ) {
        Carp::confess('The `name` value must be an instance of `Graph::QL::AST::Node::Name`, not '.$self->{name})
            unless Scalar::Util::blessed( $self->{name} )
                && $self->{name}->isa('Graph::QL::AST::Node::Name');
    }
    
    Carp::confess('The `variable_definitions` value must be an ARRAY ref')
        unless ref $self->{variable_definitions} eq 'ARRAY';
    
    if ( $self->{variable_definitions}->@* ) {
        foreach ( $self->{variable_definitions}->@* ) {
            Carp::confess('The values in `variable_definitions` value must be an instance of `Graph::QL::AST::Node::VariableDefinition`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::VariableDefinition');
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
    
    Carp::confess('The `selection_set` value must be an instance of `Graph::QL::AST::Node::SelectionSet`, not '.$self->{selection_set})
        unless Scalar::Util::blessed( $self->{selection_set} )
            && $self->{selection_set}->isa('Graph::QL::AST::Node::SelectionSet');
    
}

sub operation            : ro;
sub name                 : ro;
sub variable_definitions : ro;
sub directives           : ro;
sub selection_set        : ro;

1;

__END__

=pod

=cut
