package Graph::QL::AST::Node::SchemaDefinition;

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
    directives      => sub { +[] },
    operation_types => sub { +[] },
);

sub BUILDARGS : strict(
    directives?      => directives,
    operation_types? => operation_types,
    location         => super(location),
);

sub BUILD ($self, $params) {

    throw('The `directives` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{directives} );
    
    foreach ( $self->{directives}->@* ) {
         throw('The values in `directives` must all be of type(Graph::QL::AST::Node::Directive), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::AST::Node::Directive');
    }
    
    throw('The `operation_types` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{operation_types} );
    
    foreach ( $self->{operation_types}->@* ) {
         throw('The values in `operation_types` must all be of type(Graph::QL::AST::Node::OperationTypeDefinition), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::AST::Node::OperationTypeDefinition');
    }
    
}

sub directives      : ro;
sub operation_types : ro;

1;

__END__

=pod

=cut
