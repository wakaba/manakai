package Message::DOM::EventTarget;
use strict;
push our @ISA, 'Message::IF::EventTarget';

sub add_event_listener ($$$;$) {
  push @{$_[0]->{event_listener}->{''}->{''.$_[1]}->[$_[3] ? 1 : 0] or []},
      $_[2];
} # add_event_listener

sub add_event_listener_ns ($$$$;$) {
  push @{$_[0]->{event_listener}->{
    defined $_[1] ? $_[1] : ''
  }->{''.$_[2]}->[$_[4] ? 1 : 0] or []}, $_[3];
} # add_event_listener_ns

require Message::DOM::EventException;
use Char::Class::XML qw/InXMLNCNameStartChar11 InXMLNCNameChar11/;

sub dispatch_event ($$) {
  unless (UNIVERSAL::isa ($_[1], 'Message::DOM::Event')) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_SUPPORTED_ERR',
        -subtype => 'EXTERNAL_EVENT_ERR';
  }

  if ($_[1]->{manakai_dispatched}) {
    report Message::DOM::EventException
        -object => $_[0],
        -type => 'DISPATCH_REQUEST_ERR';
  }

  my $type = $_[1]->{type};
  if (not defined $type or $type eq '') {
    report Message::DOM::EventException
        -object => $_[0],
        -type => 'UNSPECIFIED_EVENT_TYPE_ERR';
  } elsif ($type =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*\z/) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'INVALID_CHARACTER_ERR',
        -subtype => 'MALFORMED_EVENT_TYPE_ERR';
  }

  local $Error::Depth = $Error::Depth + 1;
  return $_[0]->__dispatch_event ($_[1]);
} # dispatch_event

sub __dispatch_event {
  ## NOTE: MUST be implemented by subclass.
  die "Not implemented";
} # __dispatch_event

## TODO: multiple registration... then, remove them
## TODO: <http://www.w3.org/2006/webapi/track/issues/77>

sub remove_event_listener ($$$;$) {
  my $list = $_[0]->{event_listener}->{''}->{''.$_[1]}->[$_[3] ? 1 : 0] || [];
  for my $i (0..$#$list) {
    if ($list->[$i] eq $_[2]) {
      splice @$list, $i, 1, ();
      last;
    }
  }
} # remove_event_listener

sub remove_event_listener_ns ($$$$;$) {
  my $list = $_[0]->{event_listener}->{
    defined $_[1] ? $_[1] : ''
  }->{''.$_[2]}->[$_[4] ? 1 : 0] || [];
  for my $i (0..$#$list) {
    if ($list->[$i] eq $_[3]) {
      splice @$list, $i, 1, ();
      last;
    }
  }
} # remove_event_listener_ns

package Message::IF::EventTarget;

1;
