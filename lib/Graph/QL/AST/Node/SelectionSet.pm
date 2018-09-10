package Graph::QL::AST::Node::SelectionSet;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use slots (
    selections => sub { +[] },
);

sub BUILDARGS : strict(
    selections? => selections,
    location    => super(location),
);

sub BUILD ($self, $params) {

    Carp::confess('The `selections` value must be an ARRAY ref')
        unless ref $self->{selections} eq 'ARRAY';
    
    if ( $self->{selections}->@* ) {
        foreach ( $self->{selections}->@* ) {
            Carp::confess('The values in `selections` value must be an instance of `Graph::QL::AST::Node::Role::Selection`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->roles::DOES('Graph::QL::AST::Node::Role::Selection');
        }
    }
    
}

sub selections : ro;

1;

__END__

=pod

=cut
