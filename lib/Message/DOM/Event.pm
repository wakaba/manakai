package Message::DOM::Event;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::Event';

## The |Event| interface - constants

## |PhaseType|

sub CAPTURING_PHASE () { 1 }
sub AT_TARGET () { 2 }
sub BUBBLING_PHASE () { 3 }

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    'Message::DOM::Event::bubbles' => 1,
    'Message::DOM::Event::cancelable' => 1,
    'Message::DOM::Event::current_target' => 1,
    'Message::DOM::Event::default_prevented' => 1,
    'Message::DOM::Event::manakai_dispatched' => 1,
    'Message::DOM::Event::event_phase' => 1,
    'Message::DOM::Event::manakai_immediate_propagation_stopped' => 1,
    'Message::DOM::Event::namespace_uri' => 1,
    'Message::DOM::Event::manakai_propagation_stopped' => 1,
    'Message::DOM::Event::target' => 1,
    'Message::DOM::Event::time_stamp' => 1,
    'Message::DOM::Event::type' => 1,
 
    'Message::DOM::Event::CustomEvent::detail' => 1,
  }->{$AUTOLOAD}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        return \${\$_[0]}->{$method_name};
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## The |Event| interface - attributes

sub bubbles ($);

sub cancelable ($);

sub current_target ($);

sub default_prevented ($);

## TODO: documentation
sub manakai_dispatched ($);

sub event_phase ($);

## TODO: documentation
sub manakai_immediate_propagation_stopped ($);

sub namespace_uri ($);

## TODO: documentation
sub manakai_propagation_stopped ($);

sub target ($);

sub time_stamp ($);

sub type ($);

## The |Event| interface - methods

sub init_event ($$;$$) {
  my $self = $_[0];
  unless ($self->{manakai_dispatched}) {
    delete $self->{namespace_uri};
    $self->{type} = ''.$_[1];
    $self->{bubbles} = $_[2];
    $self->{cancelable} = $_[3];
  }
} # init_event

sub init_event_ns ($$;$$) {
  my $self = $_[0];
  unless ($self->{manakai_dispatched}) {
    unless (not defined $_[1] or $_[1] eq '') {
      $self->{namespace_uri} = $_[1];
    } else {
      delete $self->{namespace_uri};
    }
    $self->{type} = ''.$_[2];
    $self->{bubbles} = $_[3];
    $self->{cancelable} = $_[4];
  }
} # init_event_ns

sub prevent_default ($) {
  if ($_[0]->{cancelable}) {
    $_[0]->{default_prevented} = 1;
  }
} # prevent_default

sub stop_immediate_propagation ($) {
  $_[0]->{manakai_immediate_propagation_stopped} = 1;
  $_[0]->{manakai_propagation_stopped} = 1;
} # stop_immediate_propagation

sub stop_propagation ($) {
  $_[0]->{manakai_propagation_stopped} = 1;
} # stop_propagation

package Message::DOM::Event::CustomEvent;
push our @ISA, 'Message::DOM::Event', 'Message::IF::CustomEvent';

## The |CustomEvent| interface - attribute

sub detail ($);

## The |CustomEvent| interface - method

sub init_custom_event_ns ($$$;$$$) {
  my $self = $_[0];
  unless ($self->{manakai_dispatched}) {
    unless (not defined $_[1] or $_[1] eq '') {
      $self->{namespace_uri} = $_[1];
    } else {
      delete $self->{namespace_uri};
    }
    $self->{type} = ''.$_[2];
    $self->{bubbles} = $_[3];
    $self->{cancelable} = $_[4];
    $self->{detail} = $_[5];
  }
} # init_custom_event_ns

package Message::IF::Event;
package Message::IF::CustomEvent;
                     
1;
