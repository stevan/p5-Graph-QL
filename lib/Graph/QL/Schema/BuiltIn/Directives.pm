package Graph::QL::Schema::BuiltIn::Directives;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Util::Errors 'throw';

use Graph::QL::Schema::Directive;

our $VERSION = '0.01';

# TODO:
# http://facebook.github.io/graphql/June2018/#sec-Type-System.Directives
# Need to implement:
#
# directive @skip(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT
#
# directive @include(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT
#
# directive @deprecated(
#   reason: String = "No longer supported"
# ) on FIELD_DEFINITION | ENUM_VALUE
#
# ...

sub has_directive ($, $name) {}
sub get_directive ($, $name) {}

1;

__END__

=pod

=cut

