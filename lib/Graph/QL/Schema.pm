package Graph::QL::Schema;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors';

use Graph::QL::Query;
use Graph::QL::Field;
use Graph::QL::Resolver;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use slots (
    types => sub { die 'You must supply a set of `types`' },
);

# accessors

sub types : ro;

sub has_type ($self, $name) { exists $self->{types}->{$name} }
sub get_type ($self, $name) {        $self->{types}->{$name} }

# ...

sub resolve ( $self, $root_type, $input, $query ) {

    my %errors;
    my %output;

    foreach my $field_name ( sort keys $query->fields->%* ) {
        my $field = $self->{types}->{ $root_type }->{ $field_name };

        # TODO:
        # this call need to be checked
        # - first to see if there is actually a resolver
        # - then that it returns something that works
        #   with the expectations of $field->is_non_nullable
        my $result = $field->resolver->body->( $input );

        #use Data::Dumper;
        #warn Dumper [ $field_name, $query, $field, $result ];

        # if we have a subquery and we have a definition for this subtype, ...
        if ( ref $query->fields->{ $field_name } eq 'HASH' && exists $self->{types}->{ $field->type } ) {

            if ( $field->is_array ) {
                # then we call our resolver and then
                # pass it only the subtype resolver
                $output{ $field_name } = [ map $self->resolve( $field->type, $_, $query->new_from_field( $field_name ) ), $result->@* ];
            }
            else {
                # then we call our resolver and then
                # pass it only the subtype resolver
                $output{ $field_name } = $self->resolve( $field->type, $result, $query->new_from_field( $field_name ) );
            }
        }
        else {
            # if we do not know about this type
            # then we can just call the resolver
            $output{ $field_name } = $result;
        }

        if ( $field->is_non_nullable ) {
            $errors{ $root_type.'.'.$field_name }++ unless defined $output{ $field_name };
        }
    }

    die 'Errors in the following fields: '.(join ', ' => keys %errors) if %errors;

    return \%output;
}

1;

__END__

=pod

=cut
