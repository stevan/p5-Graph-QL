package Graph::QL::Introspection::Resolvers::__EnumValue;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::JSON;

our $VERSION = '0.01';

sub name        ($value, $, $, $) { $value->name }
sub description ($value, $, $, $) { return } # TODO

sub isDeprecated      ($field, $, $, $) { Graph::QL::Util::JSON->FALSE } # TODO
sub deprecationReason ($field, $, $, $) { return } # TODO

1;

__END__

=pod

type __EnumValue {
    name              : String!
    description       : String
    isDeprecated      : Boolean!
    deprecationReason : String
}

=cut
