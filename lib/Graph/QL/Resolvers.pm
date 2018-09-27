package Graph::QL::Resolvers;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Resolvers::TypeResolver;
use Graph::QL::Resolvers::FieldResolver;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots ( types => sub {} );

sub new_from_namespace ($class, $root_namespace) {

	$root_namespace = $root_namespace.'::' unless $root_namespace =~ /\:\:$/;

	my @namespaces;
	{
		no strict 'refs';
		@namespaces = map s/\:\:$//r => grep /\:\:$/ => keys %{ $root_namespace };
	}

	my @types;
	foreach my $namespace ( @namespaces ) {
		my $r = MOP::Role->new( "${root_namespace}${namespace}" );

		my @fields = map Graph::QL::Resolvers::FieldResolver->new(
			name => $_->name,
			code => $_->body,
		) => $r->methods;

		push @types => Graph::QL::Resolvers::TypeResolver->new(
			name   => $namespace,
			fields => \@fields
		);
	}

	return $class->new( types => \@types );
}

sub get_type ($self, $name) {
    (grep $_->name eq $name, $self->{types}->@*)[0]
}

1;

__END__

=pod

=cut
