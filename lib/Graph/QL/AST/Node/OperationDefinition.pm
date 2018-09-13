package Graph::QL::AST::Node::OperationDefinition;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `operation` must be of type(OperationKind), not `%s`', $self->{operation})
        unless defined $self->{operation};
    
    if ( exists $params->{name} ) {
        throw('The `name` must be of type(Graph::QL::AST::Node::Name), not `%s`', $self->{name})
            unless Ref::Util::is_blessed_ref( $self->{name} )
                && $self->{name}->isa('Graph::QL::AST::Node::Name');
    }
    
    throw('The `variable_definitions` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{variable_definitions} );
    
    foreach ( $self->{variable_definitions}->@* ) {
         throw('The values in `variable_definitions` must all be of type(Graph::QL::AST::Node::VariableDefinition), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::AST::Node::VariableDefinition');
    }
    
    throw('The `directives` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{directives} );
    
    foreach ( $self->{directives}->@* ) {
         throw('The values in `directives` must all be of type(Graph::QL::AST::Node::Directive), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::AST::Node::Directive');
    }
    
    throw('The `selection_set` must be of type(Graph::QL::AST::Node::SelectionSet), not `%s`', $self->{selection_set})
        unless Ref::Util::is_blessed_ref( $self->{selection_set} )
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
