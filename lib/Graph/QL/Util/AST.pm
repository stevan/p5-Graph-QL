package Graph::QL::Util::AST;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Module::Runtime ();

use Graph::QL::Util::Strings;

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

        #warn "PATH: $path";
        #warn "START: $start";
        #warn "REST: ". (join ', ' => @rest);

        #use Data::Dumper;
        #use Carp;
        #Carp::confess(Dumper [ $ast, \@paths ]) unless defined $start;

        if ( Ref::Util::is_arrayref( $ast->{ $start } ) ) {
            foreach my $sub_ast ( $ast->{ $start }->@* ) {
                null_out_source_locations( $sub_ast, @rest ? (join '.' => @rest) : () );
            }
        }
        else {
            null_out_source_locations( $ast->{ $start }, @rest ? (join '.' => @rest) : () );
        }
    }
}

sub build_from_ast ($ast) {

    my $node_kind  = $ast->{kind};
    my $node_loc   = $ast->{loc};
    my $node_class = 'Graph::QL::AST::Node::'.$node_kind;

    Module::Runtime::use_module($node_class);

    my %args;
    foreach my $key ( keys $ast->%* ) {

        next if $key eq 'kind' or $key eq 'loc';

        next unless defined $ast->{ $key };

        my $slot = Graph::QL::Util::Strings::camel_to_snake( $key );

        if ( ref $ast->{ $key } eq 'ARRAY' ) {
            $args{ $slot } = [ map build_from_ast( $_ ), $ast->{ $key }->@* ];
        }
        elsif ( ref $ast->{ $key } eq 'HASH' ) {
            $args{ $slot } = build_from_ast( $ast->{ $key } );
        }
        else {
            $args{ $slot } = $ast->{ $key };
        }
    }

    return $node_class->new( %args, location => $node_loc );
}

1;

__END__

=pod

=cut



