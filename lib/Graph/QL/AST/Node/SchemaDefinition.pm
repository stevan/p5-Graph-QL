package Graph::QL::AST::Node::SchemaDefinition;

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
    directives      => sub { +[] },
    operation_types => sub { +[] },
);

sub BUILDARGS : strict(
    directives?      => directives,
    operation_types? => operation_types,
    location         => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `directives` value must be an ARRAY ref')
        unless ref $self->{directives} eq 'ARRAY';
    
    if ( $self->{directives}->@* ) {
        foreach ( $self->{directives}->@* ) {
            Carp::confess('The values in `directives` value must be an instance of `Graph::QL::AST::Node::Directive`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::Directive');
        }
    }
    
    Carp::confess('The `operation_types` value must be an ARRAY ref')
        unless ref $self->{operation_types} eq 'ARRAY';
    
    if ( $self->{operation_types}->@* ) {
        foreach ( $self->{operation_types}->@* ) {
            Carp::confess('The values in `operation_types` value must be an instance of `Graph::QL::AST::Node::OperationTypeDefinition`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::OperationTypeDefinition');
        }
    }
    
}

sub directives      : ro;
sub operation_types : ro;

1;

__END__

=pod

=cut
