package Message::DOM::Node;
use strict;
require Message::DOM::Node;
require Message::DOM::EventTarget;
push our @ISA, 'Message::DOM::EventTarget';

sub __dispatch_event ($$) {
  my $ev = $_[1];

  $ev->{target} = $_[0];
  $ev->{manakai_dispatched} = 1;

  my @target = ($_[0]);
  while (defined (my $p = $target[0]->parent_node)) {
    unshift @target, $p;
  }

  my $evns = $ev->{namespace_uri};
  $evns = '' unless defined $evns;
  my $evln = $ev->{local_name};
  local $Error::Depth = $Error::Depth + 1;

  {
    $ev->{event_phase} = 1; # CAPTURE_PHASE
    for my $ct (@target[0..$#target-1]) {
      $ev->{current_target} = $ct;
      ## ISSUE: {event_handler} mutation
      for (@{$ct->{event_handler}->{$evns}->{$evln}->[1] or []}) {
        $_->($ev);
      }
    }
  }

  {
    $ev->{event_phase} = 2; # AT_TARGET
    {
      my $ct = $target[-1];
      $ev->{current_target} = $ct;
      ## ISSUE: {event_handler} mutation
      for (@{$ct->{event_handler}->{$evns}->{$evln}->[0] or []}) {
        $_->($ev);
      } 
    }   
  }

  if ($ev->{bubbles}) {
    $ev->{event_phase} = 3; # BUBBLE_PHASE
    for my $ct (reverse @target[0..$#target-1]) {
      $ev->{current_phase} = $ct;
      ## ISSUE: {event_handler} mutation
      for (@{$ct->{event_handler}->{$evns}->{$evln}->[0] or []}) {
        $_->($ev);
      }
    }
  }

  ## TODO: stop_propagation
  
  ## ISSUE: Should we remove {current_target}?

  return not $ev->{default_prevented};
} # __dispatch_event

package Message::DOM::Document;
push our @ISA, 'Message::IF::DocumentEvent';

sub can_dispatch ($$$) {
  ## ISSUE: What should we do??
  return 1;
} # can_dispatch

sub create_event ($$) {
  ## ISSUE: Case-sensitivity in implementations?
  my $mc = {
    Event => ['Message::DOM::Event', 'Message::DOM::Event'],
    ## ISSUE: Events?
    CustomEvents => ['Message::DOM::Event',
                     'Message::DOM::Event::CustomEvent'],
    HTMLEvents => ['Message::DOM::Event', 'Message::DOM::Event'],
    ## TODO: MouseEvents
    ## TODO: MutationEvents
    ## TODO: UIEvents
  }->{$_[1]};
  
  unless (defined $mc) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_SUPPORTED_ERR',
        -subtype => 'EVENT_INTERFACE_NOT_SUPPORTED_ERR';
  }

  eval qq{ require $mc->[0]; 1 } or die $@;
  ## TODO: Should we provide an option to use Time::HiRes?
  return bless {time_stamp => time}, $mc->[1];

  ## ISSUE: What value should be set to attributes?
} # create_event

package Message::IF::DocumentEvent;

1;
