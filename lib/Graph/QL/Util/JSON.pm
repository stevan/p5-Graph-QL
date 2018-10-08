package Graph::QL::Util::JSON;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use JSON::MaybeXS;

our $VERSION = '0.01';

sub TRUE  { JSON::MaybeXS->true  }
sub FALSE { JSON::MaybeXS->false }

our $JSON = JSON::MaybeXS->new->pretty->canonical->utf8;

sub encode { $JSON->encode( @_ ) }
sub decode { $JSON->decode( @_ ) }

1;

__END__

=pod

=cut
