package Graph::QL::AST::Node::TypeExtensionDefinition;
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
    definition => sub { die 'You must supply a `definition`'},
);

sub BUILDARGS : strict(
    definition  => definition,
    location?   => super(location),
);

sub BUILD ($self, $params) {

    throw('The `definition` must be of type(Graph::QL::AST::Node::ObjectTypeDefinition), not `%s`', $self->{definition})
        unless Ref::Util::is_blessed_ref( $self->{definition} )
            && $self->{definition}->isa('Graph::QL::AST::Node::ObjectTypeDefinition');
    
}

sub definition : ro;

1;

__END__

=pod

=cut
