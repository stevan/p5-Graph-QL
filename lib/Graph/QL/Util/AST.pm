package Graph::QL::Util::AST;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.01';

use constant NULL_LOCATION => +{
    start => { line => 0, column => 0 },
    end   => { line => 0, column => 0 },
};

sub null_out_source_locations ( $ast, @paths ) {

    $ast->{loc}         = NULL_LOCATION if $ast->{loc};
    $ast->{name}->{loc} = NULL_LOCATION if $ast->{name};

    foreach my $path ( @paths ) {
        my ($start, @rest) = split /\./ => $path;

        if ( Ref::Util::is_arrayref( $ast->{ $start } ) ) {
            foreach my $sub_ast ( $ast->{ $start }->@* ) {
                null_out_source_locations( $sub_ast, join '.' => @rest );
            }
        }
        else {
            null_out_source_locations( $ast->{ $start }, @rest );
        }
    }
}

1;

__END__

=pod

=cut



