package Graph::QL::Meta::Type::NonNull;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

our $VERSION = '0.01';

use parent 'Graph::QL::Meta::Type';
use slots (
    kind    => sub { Graph::QL::Type->Kind->NON_NULL },
    of_type => sub { die 'You must supply an `on_type`' },
);

sub BUILDARGS : strict(
    of_type => of_type,
);

sub BUILD ($self, $params) {
    Carp::confess('The `of_type` value must be an instance of `Graph::QL::Meta::Type`, not '.$self->{of_type})
        unless Scalar::Util::blessed( $self->{of_type} )
            && $self->{of_type}->isa('Graph::QL::Meta::Type');
}

sub of_type : ro;

# input/output type methods
sub is_input_type  ($self) { $self->of_type->is_input_type  }
sub is_output_type ($self) { $self->of_type->is_output_type }

1;

__END__

=pod

=cut
