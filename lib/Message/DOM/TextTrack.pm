package Message::DOM::TextTrack;
use strict;
use warnings;
our $VERSION = '1.0';
use Scalar::Util qw(weaken);
use Message::DOM::DOMException;

## Spec:
## <http://www.whatwg.org/specs/web-apps/current-work/#texttrack>,
## <http://suika.fam.cx/~wakaba/wiki/sw/n/manakai%20DOM%20Extensions#anchor-59>.

# XXX EventTarget

sub ____new_from_hashref ($$) {
  return bless $_[1], $_[0];
} # ____new_from_hashref

sub manakai_is_invalid ($) {
  return $_[0]->{invalid};
} # manakai_is_invalid

sub kind ($) {
  return $_[0]->{kind};
} # kind

sub label ($) {
  return $_[0]->{label};
} # label

sub language ($) {
  return $_[0]->{language};
} # language

sub mode ($) {
  if (@_ > 1) {
    if ($_[1] eq 'disabled' or $_[1] eq 'hidden' or $_[1] eq 'showing') {
      $_[0]->{mode} = $_[1] . '';
    } else {
      die "XXX WebIDL TypeError";
    }
  }
  return $_[0]->{mode};
} # mode

sub cues ($) {
  if ($_[0]->mode eq 'disabled') {
    return undef;
  } else {
    # XXX
    die "Not implemented yet";
  }
} # cues

sub active_cues ($) {
  if ($_[0]->mode eq 'disabled') {
    return undef;
  } else {
    # XXX
    die "Not implemented yet";
  }
} # active_cues

sub manakai_all_cues ($) {
  return $_[0]->{all_cues};
} # manakai_all_cues

sub add_cue ($$) {
  if ($_[1]->track or grep { $_ eq $_[1] } @{$_[0]->{all_cues}}) {
    # XXX error reporting
    report Message::DOM::DOMException
        #-object => $_[0],
        -type => 'INVALID_STATE_ERR';
  }

  push @{$_[0]->{all_cues}}, $_[1];
  weaken ($_[1]->{track} = $_[0]);
} # add_cue

sub remove_cue ($$) {
  if (not $_[1]->track or $_[1]->track ne $_[0]) {
    # XXX error reporting
    report Message::DOM::DOMException
        #-object => $_[0],
        -type => 'INVALID_STATE_ERR';
  } elsif (not grep { $_ eq $_[1] } @{$_[0]->{all_cues}}) {
    # XXX error reporting
    report Message::DOM::DOMException
        #-object => $_[0],
        -type => 'NOT_FOUND_ERR';
  }

  @{$_[0]->{all_cues}} = grep { $_ ne $_[1] } @{$_[0]->{all_cues}};
  delete $_[1]->{track};
} # remove_cue

sub manakai_clone_track ($) {
  my $self = shift;
  require Message::DOM::TextTrackCueList;

  my $clone = (ref $self)->____new_from_hashref ({%{$self}});
  $clone->{all_cues} = Message::DOM::TextTrackCueList
      ->____new_from_arrayref ([]);
  for (@{$self->{all_cues}}) {
    $clone->add_cue ($_->manakai_clone_cue);
  }

  return $clone;
} # manakai_clone_track

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
