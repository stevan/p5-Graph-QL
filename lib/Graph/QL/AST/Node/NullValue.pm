package Graph::QL::AST::Node::NullValue;
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
use slots;

sub BUILDARGS : strict(
    location? => super(location),
);


sub parsed_value ($self) { GraphQL::Util::Literals::parse_( $self->value ) }

1;

__END__

=pod

=cut
