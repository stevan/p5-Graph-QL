package Graph::QL::Schema::Type::Scalar;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors 'throw';

our $VERSION = '0.01';

use parent 'Graph::QL::Schema::Type';
use slots (
    kind        => sub { Graph::QL::Schema::Type->Kind->SCALAR },
    name        => sub { die 'You must supply a `name`' },
    description => sub {},
);

sub BUILDARGS : strict(
    name         => name,
    description? => description,
);

sub BUILD ($self, $params) {
    throw('The `name` must be a defined value')
        unless defined $self->{name};

    if ( exists $params->{description} ) {
        throw('The `description` must be a defined value')
            unless defined $self->{description};
    }
}

sub name            : ro;
sub description     : ro;
sub has_description : predicate;

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
