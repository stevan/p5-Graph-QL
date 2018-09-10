package Graph::QL::AST::Node::Document;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    definitions => sub { +[] },
);

sub BUILDARGS : strict(
    definitions? => definitions,
    location     => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `definitions` value must be an ARRAY ref')
        unless ref $self->{definitions} eq 'ARRAY';
    
    if ( $self->{definitions}->@* ) {
        foreach ( $self->{definitions}->@* ) {
            Carp::confess('The values in `definitions` value must be an instance of `Graph::QL::AST::Node::Role::Definition`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->roles::DOES('Graph::QL::AST::Node::Role::Definition');
        }
    }
    
}

sub definitions : ro;

1;

__END__

=pod

=cut
