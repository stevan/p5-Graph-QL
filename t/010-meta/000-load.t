#!/usr/bin/env perl

use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Graph::QL::Meta::Schema');

    use_ok('Graph::QL::Meta::Directive');
    use_ok('Graph::QL::Meta::Type');

    use_ok('Graph::QL::Meta::Type::Enum');
    use_ok('Graph::QL::Meta::Type::InputObject');
    use_ok('Graph::QL::Meta::Type::Interface');
    use_ok('Graph::QL::Meta::Type::List');
    use_ok('Graph::QL::Meta::Type::NonNull');
    use_ok('Graph::QL::Meta::Type::Object');
    use_ok('Graph::QL::Meta::Type::Scalar');
    use_ok('Graph::QL::Meta::Type::Union');

    use_ok('Graph::QL::Meta::Field');
    use_ok('Graph::QL::Meta::EnumValue');
    use_ok('Graph::QL::Meta::InputValue');
}

done_testing;
