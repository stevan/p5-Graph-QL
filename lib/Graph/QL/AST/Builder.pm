package Graph::QL::AST::Builder;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Carp            ();
use Scalar::Util    ();
use Module::Runtime ();

use Graph::QL::AST::Util;

our $VERSION = '0.01';

sub build_from_ast ($class, $ast) {

    my $node_kind  = $ast->{kind};
    my $node_loc   = $ast->{loc};
    my $node_class = 'Graph::QL::AST::Node::'.$node_kind;

    Module::Runtime::use_module($node_class);

    my %args;
    foreach my $key ( keys $ast->%* ) {

        next if $key eq 'kind' or $key eq 'loc';

        next unless defined $ast->{ $key };

        my $slot = Graph::QL::AST::Util::camel_to_snake( $key );

        if ( ref $ast->{ $key } eq 'ARRAY' ) {
            $args{ $slot } = [ map $class->build_from_ast( $_ ), $ast->{ $key }->@* ];
        }
        elsif ( ref $ast->{ $key } eq 'HASH' ) {
            $args{ $slot } = $class->build_from_ast( $ast->{ $key } );
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
