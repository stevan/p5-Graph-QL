package Graph::QL::AST::Node::ObjectValue;

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
    fields => sub { +[] },
);

sub BUILDARGS : strict(
    fields?   => fields,
    location  => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `fields` value must be an ARRAY ref')
        unless ref $self->{fields} eq 'ARRAY';
    
    if ( $self->{fields}->@* ) {
        foreach ( $self->{fields}->@* ) {
            Carp::confess('The values in `fields` value must be an instance of `Graph::QL::AST::Node::ObjectField`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::ObjectField');
        }
    }
    
}

sub fields : ro;

1;

__END__

=pod

=cut
