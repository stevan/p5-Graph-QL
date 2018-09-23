package Graph::QL::Execution::ExecuteQuery;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions ':all';

use Graph::QL::Execution::QueryValidator;

use constant DEBUG => $ENV{GRAPHQL_EXECUTOR_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema    => sub {}, # Graph::QL::Schema
    query     => sub {}, # Graph::QL::Operation::Query
    resolvers => sub {}, # a mapping of TypeName to Resolver instance
    # internals ...
    _errors   => sub { +[] },
);

sub BUILDARGS : strict(
    schema    => schema,
    query     => query,
    resolvers => resolvers,
);

sub BUILD ($self, $params) {

    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

    throw('The `query` must be of an instance that does the `Graph::QL::Operation` role, not `%s`', $self->{query})
        unless assert_isa( $self->{query}, 'Graph::QL::Operation::Query' );

    # TODO:
    # - handle `initial-value`
    # - handle `variables`
    # - handle `context-value`

    throw('The `resolvers` must be a HASH ref, not `%s`', $self->{resolvers})
        unless assert_hashref( $self->{resolvers} );

    throw('The `resolvers` HASH can not be empty')
        unless assert_non_empty( $self->{resolvers} );
}

sub schema : ro;
sub query  : ro;

sub has_errors ($self) { !! scalar $self->{_errors}->@* }
sub get_errors ($self) {           $self->{_errors}->@* }

sub get_resolver_for_type ($self, $type) {
    return $self->{resolvers}->{ $type };
}

## ...

sub validate ($self) {
    # this will validate that the query supplied
    # can be executed by the schema supplied
    my $v = Graph::QL::Execution::QueryValidator->new(
        schema => $self->{schema},
        query  => $self->{query},
    );

    # validate the schema ...
    $v->validate;

    # if the validation succeeds,
    # there are no errors ...
    return 1 unless $v->has_errors;
    # if the validation fails, then
    # we absorb the errors and ...
    $self->_absorb_validation_errors( 'The `operation` did not pass validation.' => $v );
    # and return false
    return 0;
}

sub execute ($self) {

    throw("You cannot execute a query that has errors:\n%s" => join "\n" => $self->get_errors)
        if $self->has_errors;

    my $root_type = $self->{schema}->lookup_root_type( $self->{query} );

    my $data = $self->execute_selections(
        $root_type,
        $self->{query}->selections,
        $self->get_resolver_for_type( $root_type->name ),
        {},
    );

    return $data;
}

sub execute_selections ($self, $schema_type, $selections, $resolvers, $initial_value) {

    my %results;
    foreach my $selection ( $selections->@* ) {
        my $response_key = $selection->has_alias ? $selection->alias : $selection->name;
        my $schema_field = $schema_type->lookup_field( $selection );

        $results{ $response_key } = $self->execute_field(
            $schema_field,
            $selection,
            $resolvers->{ $schema_field->name },
            $initial_value
        );
    }

    return \%results;
}

sub execute_field ($self, $schema_field, $selection, $resolver, $initial_value) {

    my %field_args = map { $_->name => $_->value } $selection->args->@*;
    my $resolved   = $resolver->( $initial_value, \%field_args );

    my $schema_field_type = $self->{schema}->lookup_type(
        $self->_find_base_schema_type( $schema_field->type )
    );

    if ( $selection->has_selections ) {

        my $selections = $selection->selections;
        my $resolvers  = $self->get_resolver_for_type( $schema_field_type->name );

        if ( $schema_field->type->isa('Graph::QL::Schema::Type::Named') ) {
            $resolved = $self->execute_selections(
                $schema_field_type,
                $selections,
                $resolvers,
                $resolved,
            );
        }
        else {
            if ( $schema_field->type->isa('Graph::QL::Schema::Type::List') ) {
                $resolved = [
                    map {
                        $self->execute_selections(
                            $schema_field_type,
                            $selections,
                            $resolvers,
                            $_,
                        )
                    } $resolved->@*
                ]
            }
            elsif ( $schema_field->type->isa('Graph::QL::Schema::Type::NonNull') ) {

            }
        }
    }

    return $resolved;
}

## ...

sub _find_base_schema_type ($self, $schema_type) {
    $schema_type = $schema_type->of_type
        while $schema_type->isa('Graph::QL::Schema::Type::NonNull')
           || $schema_type->isa('Graph::QL::Schema::Type::List');
    return $schema_type;
}

sub _add_error ($self, $msg, @args) {
    $msg = sprintf $msg => @args if @args;
    push $self->{_errors}->@* => $msg;
    return;
}

sub _absorb_validation_errors ($self, $msgs, $e) {
    push $self->{_errors}->@* => $msgs, map "[VALIDATION] $_", $e->get_errors;
    return;
}

1;

__END__

=pod

=head1 DESCRIPTION

This object contains the data that must be available at all points
during query execution.

Namely, schema of the type system that is currently executing, and
the fragments defined in the query document.

=cut
