package Graph::QL::AST::Node::OperationTypeDefinition;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

use Graph::QL::Core::OperationKind;

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    operation => sub { die 'You must supply a `operation`'},
    type      => sub { die 'You must supply a `type`'},
);

sub BUILDARGS : strict(
    operation  => operation,
    type       => type,
    location?  => super(location),
);

sub BUILD ($self, $params) {

    throw('The `operation` must be of type(OperationKind), not `%s`', $self->{operation})
        unless Graph::QL::Core::OperationKind->is_operation_kind( $self->{operation} );
    
    throw('The `type` must be of type(Graph::QL::AST::Node::NamedType), not `%s`', $self->{type})
        unless assert_isa( $self->{type}, 'Graph::QL::AST::Node::NamedType' );
    
}

sub operation : ro;
sub type      : ro;

1;

__END__

=pod

=cut
