package Graph::QL::Schema;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use slots (
    typemap   => sub { die 'You must supply a `typemap`' },
    resolvers => sub { die 'You must supply a set of `resolvers`' },
);

sub new_from_typed_resolvers ($self, $typed_resolvers) {

    my %typemap;
    foreach my $type ( keys $typed_resolvers->%* ) {
        my $resolver_fields = $typed_resolvers->{ $type };
        $typemap{ $type } ||= {};
        foreach my $field_name ( keys $resolver_fields->%* ) {
            $typemap{ $type }->{ $field_name } = (
                MOP::Method->new(
                    body => $resolver_fields->{ $field_name }
                )->get_code_attributes('Type')
            )[0]->args->[0];
        }
    }

    return $self->new(
        typemap   => \%typemap,
        resolvers => $typed_resolvers,
    );
}

sub resolve ( $self, $root_type, $input ) {

    my %output;
    foreach my $field ( keys $self->{typemap}->{ $root_type }->%* ) {
        my $type     = $self->{typemap}->{ $root_type }->{ $field };
        my $resolver = $self->{resolvers}->{ $root_type }->{ $field };
        # if we have a definition for this subtype, ...
        if ( exists $self->{typemap}->{ $type } ) {
            # then we call our resolver and then
            # pass it only the subtype resolver
            $output{ $field } = $self->resolve( $type, $resolver->( $input ) );
        }
        else {
            # if we do not know about this type
            # then we can just call the resolver
            $output{ $field } = $resolver->( $input );
        }
    }

    return \%output;
}

1;

__END__

=pod

=cut
