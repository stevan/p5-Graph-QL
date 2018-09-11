package Graph::QL::Meta::Type;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors';

use Carp ();

our $VERSION = '0.01';

use enumerable Kind => qw[
     SCALAR
     OBJECT
     INTERFACE
     UNION
     ENUM
     INPUT_OBJECT
     LIST
     NON_NULL
];

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    kind => sub { die 'You must supply a `kind`' }
);

sub BUILD ($self, $params) {
    Carp::confess('The `kind` must be a value from the Graph::QL::Meta::Type->Kind enumeration, not '.$self->{kind})
        unless $self->Kind->has_value_for( $self->{kind} );
}

sub kind : ro;

# input/output abstract methods ...

sub is_input_type;
sub is_output_type;

1;

__END__

=pod


# NOTE:
# the __Type schema wants everything to return null
# even if the field is not relevant ...

sub kind           {}
sub name           {}
sub description    {}
sub enum_values    {} # for Type::Enum only
sub input_fields   {} # for Type::InputObject only
sub interfaces     {} # for Type::Object only
sub fields         {} # for Type::Interface & Type::Object only
sub possible_types {} # for Type::Interface & Type::Union only
sub of_type        {} # for Type::List & Type::NonNull

=cut
