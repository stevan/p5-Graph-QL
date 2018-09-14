package Graph::QL::Core::Exception;

use v5.24;
use warnings;
use experimental 'signatures', 'postderef';
use decorators ':accessors', ':constructor';

use Devel::StackTrace;

our $VERSION = '0.01';

use overload   '""' => 'to_string';

use parent 'UNIVERSAL::Object::Immutable';
use slots (
    _message     => sub { 'An error has occurred:' },
    _stack_trace => sub { Devel::StackTrace->new( skip_frames => 4, indent => 1 ) },
);

## constructor

sub BUILDARGS : strict(
    message? => '_message',
    msg?     => '_message',
);

## accessor

sub message     : ro(_);
sub stack_trace : ro(_);

## methods

sub throw ($self) { die $self }

## overloads

sub to_string ($self, @) {
    join "\n" => $self->{_message}, $self->{_stack_trace}->as_string;
}

1;

__END__

=pod

=cut

