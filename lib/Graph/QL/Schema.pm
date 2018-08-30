package Graph::QL::Schema;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors';

use Graph::QL::Field;
use Graph::QL::Resolver;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use slots (
    types => sub { die 'You must supply a set of `types`' },
);

sub new_from_typed_resolvers ($self, $typed_resolvers) {

    # inflate decorated code references to be resolver objects
    my %types;
    foreach my $type ( keys $typed_resolvers->%* ) {
        my $resolver_fields = $typed_resolvers->{ $type };
        $types{ $type }    = {};
        foreach my $field_name ( keys $resolver_fields->%* ) {
            my $meta = MOP::Method->new( body => $resolver_fields->{ $field_name } );
            # TODO: die if there is no Type attribute ...
            $types{ $type }->{ $field_name } = Graph::QL::Field->new(
                type     => ($meta->get_code_attributes('Type'))[0]->args->[0],
                resolver => Graph::QL::Resolver->new( body => $resolver_fields->{ $field_name } ),
            );
        }
    }

    return $self->new( types => \%types );
}

# accessors

sub types : ro;

sub has_type ($self, $name) { exists $self->{types}->{$name} }
sub get_type ($self, $name) {        $self->{types}->{$name} }

# ...

my %cache;

sub flush_cache { %cache = () }

sub resolve ( $self, $root_type, $input, $query ) {

    #warn "Resolving $root_type with input: $input\n";
    #warn "Looking for $cache_key in cache [" . (join ', ' => keys %cache)  . "]\n";

    my $cache_key = $root_type.':'.$input.':'.$query;

    return do {
        #warn 'found something in the cache!!!!!!!!!!!!';
        #use Data::Dumper;
        #warn Dumper $cache{ $cache_key };
        $cache{ $cache_key };
    } if exists $cache{ $cache_key };

    my %errors;
    my %output;

    $cache{ $cache_key } = \%output;

    foreach my $field_name ( sort keys $query->%* ) {
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
        if ( ref $query->{ $field_name } eq 'HASH' && exists $self->{types}->{ $field->type } ) {

            if ( $field->is_array ) {
                # then we call our resolver and then
                # pass it only the subtype resolver
                $output{ $field_name } = [ map $self->resolve( $field->type, $_, $query->{ $field_name } ), $result->@* ];
            }
            else {
                # then we call our resolver and then
                # pass it only the subtype resolver
                $output{ $field_name } = $self->resolve( $field->type, $result, $query->{ $field_name } );
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
