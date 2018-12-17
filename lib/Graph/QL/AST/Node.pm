package Graph::QL::AST::Node;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_hashref';
use Graph::QL::Util::Strings;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    location => sub {
        # this is not really sensible, but
        # without a parse, nothing would
        # actually make sense anyway, ...
        #  ¯\_(ツ)_/¯
        return +{
            start => { line => 0, column => 0 },
            end   => { line => 0, column => 0 },
        }
    },
);

sub BUILD ($self, $) {

    my $loc = $self->{location};

    throw('The `location` field must be a HASH ref')
        unless assert_hashref( $loc );

    throw('The `location` HASH ref must have both a `start` and `end` entry')
        unless exists $loc->{start}
            && exists $loc->{end};

    my ($start, $end) = $loc->@{'start', 'end'};

    throw('The `start` entry in the `location` HASH ref must have both a `line` and `column` entry')
        unless assert_hashref( $start )
            && exists $start->{line}
            && exists $start->{column};

    throw('The `end` entry in the `location` HASH ref must have both a `line` and `column` entry')
        unless assert_hashref( $end )
            && exists $end->{line}
            && exists $end->{column};

}

sub location : ro;


# TODO:
# Fix this to not violate encapsulation
# so horribly, which means adding this
# into the AST class generator script.
# - SL
sub TO_JSON ($self, @) {
    my %json = $self->%*;
    my $loc  = delete $json{location};
    foreach my $key ( keys %json ) {

        if ( $key =~ /_/ ) {
            my $new_key = Graph::QL::Util::Strings::snake_to_camel( $key );
            $json{ $new_key } = delete $json{ $key };
            $key = $new_key;
        }

        if ( ref $json{ $key } eq 'ARRAY' ) {
            # FIXME:
            # the hack for the 'values' key is to make sure that
            # the ListValue types work correctly, this will likely 
            # come back to bit us.
            # - SL
            if ( scalar $json{ $key }->@* == 0 && $key ne 'values' ) {
                $json{ $key } = undef;
            }
            else {
                $json{ $key } = [ map $_->TO_JSON, $json{ $key }->@* ];
            }
        }

        if ( Scalar::Util::blessed( $json{ $key } ) ) {
            $json{ $key } = $json{ $key }->isa('JSON::PP::Boolean')
                ? $json{ $key }
                : $json{ $key }->TO_JSON;
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
