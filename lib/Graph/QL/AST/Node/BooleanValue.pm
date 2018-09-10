package Graph::QL::AST::Node::BooleanValue;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Value';
use slots (
    value => sub { die 'You must supply a `value`'},
);

sub BUILDARGS : strict(
    value    => value,
    location => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `value` value must be an `boolean`')
        unless defined $self->{value};
    
}

sub value : ro;

1;

__END__

=pod

=cut
