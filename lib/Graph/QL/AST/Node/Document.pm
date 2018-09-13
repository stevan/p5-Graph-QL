package Graph::QL::AST::Node::Document;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `definitions` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{definitions} );
    
    foreach ( $self->{definitions}->@* ) {
         throw('The values in `definitions` must all be of type(Graph::QL::AST::Node::Role::Definition), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->roles::DOES('Graph::QL::AST::Node::Role::Definition');
    }
    
}

sub definitions : ro;

1;

__END__

=pod

=cut
