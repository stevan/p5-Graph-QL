package Graph::QL::AST::Node::ObjectValue;
# ABSTRACT: AST Node for GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';
use slots (
    fields => sub { +[] },
);

sub BUILDARGS : strict(
    fields?    => fields,
    location?  => super(location),
);

sub BUILD ($self, $params) {

    throw('The `fields` value must be an ARRAY ref')
        unless assert_arrayref( $self->{fields} );
    
    foreach ( $self->{fields}->@* ) {
        throw('The values in `fields` must all be of type(Graph::QL::AST::Node::ObjectField), not `%s`', $_ )
            unless assert_isa( $_, 'Graph::QL::AST::Node::ObjectField' );
    }
    
}

sub fields : ro;

sub parsed_value ($self) { GraphQL::Util::Literals::parse_ObjectField( $self->value ) }

1;

__END__

=pod

=cut
