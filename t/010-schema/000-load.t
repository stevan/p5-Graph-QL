#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Directive');
    use_ok('Graph::QL::Schema::Type');

    use_ok('Graph::QL::Schema::Type::Enum');
    use_ok('Graph::QL::Schema::Type::InputObject');
    use_ok('Graph::QL::Schema::Type::Interface');
    use_ok('Graph::QL::Schema::Type::List');
    use_ok('Graph::QL::Schema::Type::NonNull');
    use_ok('Graph::QL::Schema::Type::Object');
    use_ok('Graph::QL::Schema::Type::Scalar');
    use_ok('Graph::QL::Schema::Type::Union');

    use_ok('Graph::QL::Schema::Field');
    use_ok('Graph::QL::Schema::EnumValue');
    use_ok('Graph::QL::Schema::InputValue');
}

done_testing;
