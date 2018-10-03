package Graph::QL::Schema::BuiltIn::Scalars;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';

use Graph::QL::Schema::Scalar;
use Graph::QL::Util::Types::ScalarType;

our $VERSION = '0.01';

sub has_scalar ($, $scalar_type) { !! Graph::QL::Util::Types::ScalarType->is_scalar_type( $scalar_type ) }
sub get_scalar ($, $scalar_type) {
    state $scalars = {};

    throw('Expected one of built in scalar types [%s], not `%s`', 
        (join ', ' => Graph::QL::Util::Types::ScalarType->scalar_types),
        $scalar_type
    ) unless Graph::QL::Util::Types::ScalarType->is_scalar_type( $scalar_type );
    
    return $scalars->{ $scalar_type } //= Graph::QL::Schema::Scalar->new( name => $scalar_type );
}

1;

__END__

=pod

=cut

