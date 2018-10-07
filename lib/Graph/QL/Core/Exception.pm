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
    _skip_frames => sub { 5 },
    _stack_trace => sub {},
);

## constructor

sub BUILDARGS : strict(
    message?     => '_message',
    msg?         => '_message',
    skip_frames? => '_skip_frames',
);

sub BUILD ($self, $params) {
    $self->{_stack_trace} = Devel::StackTrace->new(
        skip_frames => $self->{_skip_frames},
        indent      => 1,
    );
}

## accessor

sub message        : ro(_);
sub stack_trace    : ro(_);
sub frames_skipped : ro(_skip_frames);

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

