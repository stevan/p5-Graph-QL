#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Util::Schemas');
}

my                        $FOO = 'Foo';
my               $NON_NULL_FOO = 'Foo!';
my          $LIST_NON_NULL_FOO = '[Foo!]';
my $NON_NULL_LIST_NON_NULL_FOO = '[Foo!]!';

my $non_null_list_non_null_Foo = Graph::QL::Util::Schemas::construct_type_from_name($NON_NULL_LIST_NON_NULL_FOO);
isa_ok($non_null_list_non_null_Foo, 'Graph::QL::Schema::Type::NonNull');
is($non_null_list_non_null_Foo->name, $NON_NULL_LIST_NON_NULL_FOO, '... got the name we expected');
is(
    $non_null_list_non_null_Foo,
    Graph::QL::Util::Schemas::construct_type_from_name($NON_NULL_LIST_NON_NULL_FOO),
    '... got the same underlying ASTs'
);

my $list_non_null_Foo = $non_null_list_non_null_Foo->of_type;
isa_ok($list_non_null_Foo, 'Graph::QL::Schema::Type::List');
is($list_non_null_Foo->name, $LIST_NON_NULL_FOO, '... got the name we expected');
is(
    $list_non_null_Foo,
    Graph::QL::Util::Schemas::construct_type_from_name($LIST_NON_NULL_FOO),
    '... got the same underlying ASTs'
);

my $non_null_Foo = $list_non_null_Foo->of_type;
isa_ok($non_null_Foo, 'Graph::QL::Schema::Type::NonNull');
is($non_null_Foo->name, $NON_NULL_FOO, '... got the name we expected');
is(
    $non_null_Foo,
    Graph::QL::Util::Schemas::construct_type_from_name($NON_NULL_FOO),
    '... got the same underlying ASTs'
);

my $Foo = $non_null_Foo->of_type;
isa_ok($Foo, 'Graph::QL::Schema::Type::Named');
is($Foo->name, $FOO, '... got the name we expected');
is(
    $Foo,
    Graph::QL::Util::Schemas::construct_type_from_name($FOO),
    '... got the same underlying ASTs'
);

done_testing;
