package Graph::QL::Meta::Type::Scalar;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'Graph::QL::Meta::Type';
use slots (
    kind        => sub { Graph::QL::Meta::Type->Kind->SCALAR },
    name        => sub { die 'You must supply a `name`' },
    description => sub {},
);

sub BUILDARGS : strict(
    name         => name,
    description? => description,
);

sub BUILD ($self, $params) {
    Carp::confess('The `name` must be a defined value')
        unless defined $self->{name};

    if ( exists $params->{description} ) {
        Carp::confess('The `description` must be a defined value')
            unless defined $self->{description};
    }
}

sub name            : ro;
sub description     : ro;
sub has_description : predicate;

# input/output type methods
sub is_input_type  { 1 }
sub is_output_type { 1 }

# ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return sprintf 'scalar %s' => $self->{name};
}

1;

__END__

=pod

=cut
