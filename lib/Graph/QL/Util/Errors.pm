package Graph::QL::Util::Errors;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';

use Graph::QL::Core::Exception;

our $VERSION = '0.01';

our @EXPORT_OK; BEGIN { @EXPORT_OK = ('throw') }

# ...

sub import      ($class, @args) { $class->import_into( scalar caller, @args ) }
sub import_into ($class, $into, @exports) {
    state $ok_to_export = +{ map { $_ => 1 } @EXPORT_OK };
    $ok_to_export->{ $_ } or throw('The symbol (%s), it is not exported by this module', $_)
        foreach @exports;
    no strict 'refs';
    *{$into.'::'.$_} = \&{$_} foreach @exports;
}

# ...

sub throw ($msg, @args) {
    # if we have args, assume
    # that we need to sprintf
    $msg = sprintf $msg, @args if @args;

    Graph::QL::Core::Exception->new( message => $msg )->throw
}

1;

__END__

=pod

=cut
