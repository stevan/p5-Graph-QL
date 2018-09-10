package Graph::QL::AST::Node;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    location => sub { die 'You must supply a `location` for the Node' },
);

sub BUILD ($self, $) {

    my $loc = $self->{location};

    Carp::confess('The `location` field must be a HASH ref')
        unless ref $loc eq 'HASH';

    Carp::confess('The `location` HASH ref must have both a `start` and `end` entry')
        unless exists $loc->{start}
            && exists $loc->{end};

    my ($start, $end) = $loc->%{'start', 'end'};

    Carp::confess('The `start` entry in the `location` HASH ref must have both a `line` and `column` entry')
        unless ref $start eq 'HASH'
            && exists $start->{line}
            && exists $start->{column};

    Carp::confess('The `end` entry in the `location` HASH ref must have both a `line` and `column` entry')
        unless ref $end eq 'HASH'
            && exists $end->{line}
            && exists $end->{column};

}

sub location : ro;

1;

__END__

=pod

=cut
