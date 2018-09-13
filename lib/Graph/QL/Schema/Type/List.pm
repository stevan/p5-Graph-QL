package Graph::QL::Schema::Type::List;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Ref::Util ();

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type';
use slots (
    kind    => sub { Graph::QL::Schema::Type->Kind->LIST },
    of_type => sub { die 'You must supply an `on_type`' },
);

sub BUILDARGS : strict(
    of_type => of_type,
);

sub BUILD ($self, $params) {
    throw('The `of_type` value must be an instance of `Graph::QL::Schema::Type`, not '.$self->{of_type})
        unless Ref::Util::is_blessed_ref( $self->{of_type} )
            && $self->{of_type}->isa('Graph::QL::Schema::Type');
}

sub of_type : ro;

sub name ($self) {
    return '['.$self->{of_type}->name.']';
}

# input/output type methods
sub is_input_type  ($self) { $self->of_type->is_input_type  }
sub is_output_type ($self) { $self->of_type->is_output_type }

1;

__END__

=pod

=cut
