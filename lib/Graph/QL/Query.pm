package Graph::QL::Query;

use v5.24;
use warnings;
use experimental 'signatures';
use decorators ':accessors';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    name   => sub { '__ANON__' },
    type   => sub { 'Any' },
    fields => sub { +{} },
    parent => sub {},
);

sub name   : ro;
sub type   : ro;
sub fields : ro;
sub parent : ro;

sub new_from_field ($self, $field_name) {
    my $field = $self->{fields}->{ $field_name };
    return $self->new(
        name   => ($self->{name}.'.'.$field_name),
        #type   => $field->type, # we need to be connected to the schema ...
        fields => $field,
        parent => $self,
    );
}

1;

__END__

=pod

=cut
