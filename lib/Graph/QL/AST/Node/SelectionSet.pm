package Graph::QL::AST::Node::SelectionSet;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

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

    throw('The `selections` value must be an ARRAY ref')
        unless Ref::Util::is_arrayref( $self->{selections} );
    
    foreach ( $self->{selections}->@* ) {
         throw('The values in `selections` must all be of type(Graph::QL::AST::Node::Role::Selection), not `%s`', $_ )
            unless Ref::Util::is_blessed_ref( $_ )
                && $_->roles::DOES('Graph::QL::AST::Node::Role::Selection');
    }
    
}

sub selections : ro;

1;

__END__

=pod

=cut
