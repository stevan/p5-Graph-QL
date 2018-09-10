package Graph::QL::AST::Node::InlineFragment;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'Graph::QL::AST::Node';
use roles  'Graph::QL::AST::Node::Role::Selection';
use slots (
    type_condition => sub {},
    directives     => sub { +[] },
    selection_set  => sub { die 'You must supply a `selection_set`'},
);

sub BUILDARGS : strict(
    type_condition? => type_condition,
    directives?     => directives,
    selection_set   => selection_set,
    location        => super(location),
);

sub BUILD ($self, $params) {

    if ( exists $params->{type_condition} ) {
        Carp::confess('The `type_condition` value must be an instance of `Graph::QL::AST::Node::NamedType`, not '.$self->{type_condition})
            unless Scalar::Util::blessed( $self->{type_condition} )
                && $self->{type_condition}->isa('Graph::QL::AST::Node::NamedType');
    }
    
    Carp::confess('The `directives` value must be an ARRAY ref')
        unless ref $self->{directives} eq 'ARRAY';
    
    if ( $self->{directives}->@* ) {
        foreach ( $self->{directives}->@* ) {
            Carp::confess('The values in `directives` value must be an instance of `Graph::QL::AST::Node::Directive`, not '.$_)
                unless Scalar::Util::blessed( $_ )
                    && $_->isa('Graph::QL::AST::Node::Directive');
        }
    }
    
    Carp::confess('The `selection_set` value must be an instance of `Graph::QL::AST::Node::SelectionSet`, not '.$self->{selection_set})
        unless Scalar::Util::blessed( $self->{selection_set} )
            && $self->{selection_set}->isa('Graph::QL::AST::Node::SelectionSet');
    
}

sub type_condition : ro;
sub directives     : ro;
sub selection_set  : ro;

1;

__END__

=pod

=cut
