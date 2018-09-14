#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Schema');

    use_ok('Graph::QL::Schema::Enum');
    use_ok('Graph::QL::Schema::InputObject');
    use_ok('Graph::QL::Schema::Interface');
    use_ok('Graph::QL::Schema::Object');
    use_ok('Graph::QL::Schema::Scalar');
    use_ok('Graph::QL::Schema::Union');

    use_ok('Graph::QL::Schema::Field');

    use_ok('Graph::QL::Schema::Type::List');
    use_ok('Graph::QL::Schema::Type::NonNull');
    use_ok('Graph::QL::Schema::Type::Named');

    use_ok('Graph::QL::Schema::Enum::EnumValue');
    use_ok('Graph::QL::Schema::InputObject::InputValue');
}

done_testing;
