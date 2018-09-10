package Graph::QL::AST::Node;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors';

use Carp         ();
use Scalar::Util ();

use Graph::QL::AST::Util;

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

    my ($start, $end) = $loc->@{'start', 'end'};

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

sub TO_JSON ($self, @) {
    my %json = $self->%*;
    my $loc  = delete $json{location};
    foreach my $key ( keys %json ) {

        if ( $key =~ /_/ ) {
            my $new_key = Graph::QL::AST::Util::snake_to_camel( $key );
            $json{ $new_key } = delete $json{ $key };
            $key = $new_key;
        }

        if ( ref $json{ $key } eq 'ARRAY' ) {
            if ( scalar $json{ $key }->@* == 0 ) {
                $json{ $key } = undef;
            }
            else {
                $json{ $key } = [ map $_->TO_JSON, $json{ $key }->@* ];
            }
        }

        if ( Scalar::Util::blessed( $json{ $key } ) ) {
            $json{ $key } = $json{ $key }->TO_JSON;
        }

    }
    $json{loc} = $loc;
    ($json{kind}) = (Scalar::Util::blessed($self) =~ m/^Graph\:\:QL\:\:AST\:\:Node\:\:(.*)/);
    return \%json;
}

1;

__END__

=pod

=cut
