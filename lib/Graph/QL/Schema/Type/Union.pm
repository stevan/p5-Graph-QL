package Graph::QL::Schema::Type::Union;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type::Scalar';
use slots (
    kind           => sub { Graph::QL::Schema::Type->Kind->UNION },
    possible_types => sub { die 'You must specify the `possible_types`' },
);

sub BUILDARGS : strict(
    possible_types => possible_types,
    name           => super(name),
    description?   => super(description),
);

sub BUILD ($self, $params) {

    Carp::confess('The `possible_types` value must be an ARRAY ref')
        unless defined $self->{possible_types}
            && ref $self->{possible_types} eq 'ARRAY';

    Carp::confess('The `possible_types` value must be one or more types')
        unless scalar $self->{possible_types}->@* >= 1;

    foreach ( $self->{possible_types}->@* ) {
        Carp::confess('The values in `possible_types` value must be an instance of `Graph::QL::Schema::Type::Object`, not '.$_)
            unless Scalar::Util::blessed( $_ )
                && $_->isa('Graph::QL::Schema::Type::Object');
    }
}

sub possible_types : ro;

# input/output type methods
sub is_input_type  { 0 }
sub is_output_type { 1 }

## ...

sub to_type_language ($self) {
    # TODO:
    # handle the `description`
    return sprintf 'union %s = %s' => $self->{name}, (join ' | ' => map $_->name, $self->{possible_types}->@*);
}

1;

__END__

=pod

=cut
