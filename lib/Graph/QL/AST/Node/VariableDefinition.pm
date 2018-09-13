package Graph::QL::AST::Node::VariableDefinition;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `variable` must be of type(Graph::QL::AST::Node::Variable), not `%s`', $self->{variable})
        unless Ref::Util::is_blessed_ref( $self->{variable} )
            && $self->{variable}->isa('Graph::QL::AST::Node::Variable');
    
    throw('The `type` must be of type(Graph::QL::AST::Node::Role::Type), not `%s`', $self->{type})
        unless Ref::Util::is_blessed_ref( $self->{type} )
            && $self->{type}->roles::DOES('Graph::QL::AST::Node::Role::Type');
    
    if ( exists $params->{default_value} ) {
        throw('The `default_value` must be of type(Graph::QL::AST::Node::Role::Value), not `%s`', $self->{default_value})
            unless Ref::Util::is_blessed_ref( $self->{default_value} )
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
