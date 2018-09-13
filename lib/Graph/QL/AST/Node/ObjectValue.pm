package Graph::QL::AST::Node::ObjectValue;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';
use slots (
    fields => sub { +[] },
);

sub BUILDARGS : strict(
    fields?   => fields,
    location  => super(location),
);

sub BUILD ($self, $params) {

    throw('The `fields` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{fields} );
    
    foreach ( $self->{fields}->@* ) {
         throw('The values in `fields` must all be of type(Graph::QL::AST::Node::ObjectField), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->isa('Graph::QL::AST::Node::ObjectField');
    }
    
}

sub fields : ro;

1;

__END__

=pod

=cut
