package Graph::QL::Parser;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Parser::GraphQL::XS;
use JSON::MaybeXS;

use Graph::QL::Util::AST;

our $VERSION = '0.01';

sub parse ($class, $string) {
    my $ast  = $class->parse_raw( $string );
    my $node = Graph::QL::Util::AST::build_from_ast( $ast );

    return $node;
}

sub parse_raw ($class, $string) {
    state $JSON = JSON::MaybeXS->new->utf8;

    my $parser = Parser::GraphQL::XS->new;
    my $json   = $parser->parse_string( $string );
    my $ast    = $JSON->decode( $json );

    return $ast;
}

1;

__END__

=pod

=cut

