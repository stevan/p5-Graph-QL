package Graph::QL::Execution::QueryValidator;
# ABSTRACT: GraphQL in Perl
use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Graph::QL::Util::Errors     'throw';
use Graph::QL::Util::Assertions 'assert_isa', 'assert_does';

use constant DEBUG => $ENV{GRAPHQL_QUERY_VALIDATOR_DEBUG} // 0;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    schema  => sub {},
    query   => sub {},
    # internals ...
    _errors => sub { +[] }
);

sub BUILDARGS : strict(
    schema => schema,
    query  => query,
);

sub BUILD ($self, $params) {
    throw('The `schema` must be of an instance of `Graph::QL::Schema`, not `%s`', $self->{schema})
        unless assert_isa( $self->{schema}, 'Graph::QL::Schema' );

    throw('The `query` must be of an instance that does the `Graph::QL::Operation::Query` role, not `%s`', $self->{query})
        unless assert_isa( $self->{query}, 'Graph::QL::Operation::Query' );
}

sub has_errors ($self) { !! scalar $self->{_errors}->@* }
sub get_errors ($self) {           $self->{_errors}->@* }

## ...
# once they've run, there is no sense in running them again,
# so we make them private, to say, don't touch these ...

sub validate ($self, $name=undef) {

    # find the Query type within the schema ...
    my $root_type = $self->{schema}->lookup_root_type( $self->{query} );
    # get the root field from the query Op ...
    my $query_field = $self->{query}->selections->[0];

    $self->_add_error(
        'The `schema.root(%s) type must be present in the schema', $self->{query}->operation_kind
    ) unless assert_isa( $root_type, 'Graph::QL::Schema::Object' );

    $self->_add_error(
        'The `query.field` must be an instance of `Graph::QL::Operation::Field`, not `%s`', $query_field
    ) unless assert_isa( $query_field, 'Graph::QL::Operation::Field' );

    # if we accumulated an error in
    # the last two statements, we
    # cannot go on from here ...
    return if $self->has_errors;

    # and use it to find the field in the (schema) Query object ...
    my $schema_field = $root_type->lookup_field( $query_field );

    return $self->_add_error(
        'Unable to find the `query.field(%s)` in the `schema.root(%s)` type', $query_field->name, $self->{query}->operation_kind
    ) unless defined $schema_field;

    $self->_validate_field( $schema_field, $query_field );
    return;
}

sub _validate_field ($self, $schema_field, $query_field, $recursion_depth=0) {

    $self->_add_error(
        'The `query.field` must be of type `Graph::QL::Operation::Field`, not `%s`', $query_field
    ) unless assert_isa( $query_field, 'Graph::QL::Operation::Field' );

    $self->_add_error(
        'The `schema.field` must be of type `Graph::QL::Schema::Field`, not `%s`', $schema_field
    ) unless assert_isa( $schema_field, 'Graph::QL::Schema::Field' );

    # if we accumulated an error in
    # the last two statements, we
    # cannot go on from here ...
    return if $self->has_errors;

    $self->_debug_log(
        $recursion_depth,
        'Validating schema.field(%s) and query.field(%s)' => $schema_field->name, $query_field->name
    ) if DEBUG;

    # make sure the name of field name
    # matches, otherwise we stop here
    return $self->_add_error(
        'The `schema.field.name` and `query.field.name` must match, got `%s` and `%s`', $schema_field->name, $query_field->name
    ) unless $schema_field->name eq $query_field->name;

    $self->_validate_args( $schema_field, $query_field, $recursion_depth + 1 );
    $self->_validate_selections( $schema_field, $query_field, $recursion_depth + 1 );
    return;
}

sub _validate_args ($self, $schema_field, $query_field, $recursion_depth=0) {

    # we can skip this if there are no args ...
    return if not($schema_field->has_args) && not($query_field->has_args);

    $self->_debug_log(
        $recursion_depth,
        'Validating schema.field(%s).args and query.field(%s).args' => $schema_field->name, $query_field->name
    ) if DEBUG;

    return $self->_add_error(
        'The `schema.field(%s)` and `query.field(%s)` both must expect arguments, not `%s` and `%s`',
        $schema_field->name, $query_field->name,
        (map { $_->has_args ? 'yes' : 'no' } $schema_field, $query_field)
    ) if     $schema_field->has_args  && not($query_field->has_args)
      || not($schema_field->has_args) &&     $query_field->has_args;

    return $self->_add_error(
        'The `schema.field(%s).arity` and `query.field(%s).arity` must match, not `%d` and `%d`',
        $schema_field->name, $query_field->name,
        $schema_field->arity, $query_field->arity
    ) unless $schema_field->arity == $query_field->arity;

    foreach my $i ( 0 .. $#{ $schema_field->args } ) {
        my $schema_arg = $schema_field->args->[ $i ];
        my $query_arg  = $query_field->args->[ $i ];

        $self->_add_error(
            'The `schema.field(%s).arg` must be of type `Graph::QL::Schema::InputObject::InputValue`, not `%s`',
            $schema_field->name, $schema_arg
        ), next
            unless assert_isa( $schema_arg, 'Graph::QL::Schema::InputObject::InputValue' );

        $self->_add_error(
            'The `query.field(%s).arg` must be of type `Graph::QL::Operation::Field::Argument`, not `%s`',
            $query_field->name, $query_arg
        ), next
            unless assert_isa( $query_arg, 'Graph::QL::Operation::Field::Argument' );

        $self->_debug_log(
            ($recursion_depth + 1),
            'Validating schema.field(%s).arg(%s) and query.field(%s).arg(%s)' => (
                $schema_field->name,
                $schema_arg->name,
                $query_field->name,
                $query_arg->name,
            )
        ) if DEBUG;

        # make sure the name of each arg matches ...
        $self->_add_error(
            'The `schema.field(%s).arg.name` and `query.field(%s).arg.name` must match, got `%s` and `%s`',
            $schema_field->name, $query_field->name,
            $schema_arg->name, $query_arg->name
        ), next
            unless $schema_arg->name eq $query_arg->name;

        # get the type of the arg from the
        # perspective of the schema ....
        my $schema_arg_type = $schema_arg->type;

        # now get the type of the arg that the
        # query is sending us ...
        my $query_arg_type = Graph::QL::Util::AST::ast_value_to_schema_type( $query_arg->ast->value );

        $self->_add_error(
            'Unable to determine `query.field(%s).arg(%s).type` for value `%s`',
            $query_field->name,
            $query_arg->name,
            $query_arg->ast->value
        ), next
            unless assert_isa( $query_arg_type, 'Graph::QL::Schema::Type::Named' );

        $self->_debug_log(
            ($recursion_depth + 1),
            'Validating schema.field(%s).type(%s) and query.field(%s).type(%s)' => (
                $schema_field->name,
                $schema_arg_type->name,
                $query_field->name,
                $query_arg_type->name
            )
        ) if DEBUG;

        # are they the same name type? ... yes!
        $self->_add_error(
            'The `schema.field(%s).arg(%s).type` and `query.field(%s).arg(%s).type` , not `%s` and `%s`',
            $schema_field->name, $schema_arg->name,
            $query_field->name, $query_arg->name,
            $schema_arg_type->name, $query_arg_type->name,
        ), next
            unless $schema_arg_type->name eq $query_arg_type->name;
    }

    return;
}

sub _validate_selections ($self, $schema_field, $query_field, $recursion_depth=0) {

    # we can skip this if there are no selections ...
    return unless $query_field->has_selections;

    # NOTE:
    # if it has a selection, that means that the
    # underlying field type must be an Object,
    # so we check it here ...

    $self->_debug_log(
        $recursion_depth,
        'Validating schema.field(%s).selections and query.field(%s).selections' => $schema_field->name, $query_field->name
    ) if DEBUG;

    my $schema_field_type = $self->_find_base_type( $schema_field->type );

    return $self->_add_error(
        'The `schema.field.type` must be of type `Graph::QL::Schema::Type`, not `%s`', $schema_field_type
    ) unless assert_does( $schema_field_type, 'Graph::QL::Schema::Type' );

    my $schema_object = $self->{schema}->lookup_type( $schema_field_type );

    return $self->_add_error(
        'The `schema.field.object` must exist, unable to find `%s`', $schema_field_type->name
    ) unless assert_isa( $schema_object, 'Graph::QL::Schema::Object' );

    # verify that the selection will work,
    # foreach of the selected fields, we must ...
    foreach my $query_selection_field ( $query_field->selections->@* ) {
        # find the field from the schema object ...
        my $selected_schema_field = $schema_object->lookup_field( $query_selection_field );

        return $self->_add_error(
            'Unable to find the `query.selection.field(%s)` in the `schema.object(%s)` type', $query_selection_field->name, $schema_object->name
        ) unless defined $selected_schema_field;

        # and then validate ...
        if ( not $self->_validate_field( $selected_schema_field, $query_selection_field, ($recursion_depth + 1) ) ) {
            # if one of them fails to validate, then
            # it pretty much means they all fail, so
            # can just return ...
            next;
        }
    }

    return;
}

## ...

sub _add_error ($self, $msg, @args) {
    $msg = sprintf $msg => @args if @args;
    push $self->{_errors}->@* => $msg;
    return;
}

sub _find_base_type ($self, $type) {
    $type = $type->of_type
        while $type->isa('Graph::QL::Schema::Type::NonNull')
           || $type->isa('Graph::QL::Schema::Type::List');
    return $type;
}

sub _debug_log ($self, $depth, $msg, @args) {
    my $indent = '    ' x $depth;
    $msg = sprintf $msg => @args if @args;
    warn "${indent}${msg}\n";
}

1;

__END__

=pod

=head1 DESCRIPTION

=cut
