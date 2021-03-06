package test::Message::DOM::TextTrack;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::TextTrack;
use Message::DOM::TextTrackCue;
use Message::DOM::TextTrackCueList;

sub new_track (;%) {
  return Message::DOM::TextTrack->____new_from_hashref ({@_});
} # new_track

sub new_cue (;%) {
  return Message::DOM::TextTrackCue->____new_from_hashref
      ({id => '', @_});
} # new_cue

sub new_cue_list (@) {
  return Message::DOM::TextTrackCueList->____new_from_arrayref ([@_]);
} # new_cue_list

sub _manakai_is_invalid : Test(1) {
  my $track = new_track;
  ng $track->manakai_is_invalid;
} # _manakai_is_invalid

sub _manakai_is_invalid_yes : Test(1) {
  my $track = new_track invalid => 1;
  ok $track->manakai_is_invalid;
} # _manakai_is_invalid_yes

sub _kind : Test(1) {
  my $track = new_track kind => 'captions';
  is $track->kind, 'captions';
} # _kind

sub _label : Test(1) {
  my $track = new_track label => '';
  is $track->label, '';
} # _label

sub _label_value : Test(1) {
  my $track = new_track label => '0';
  is $track->label, '0';
} # _label_value

sub _language : Test(1) {
  my $track = new_track language => '';
  is $track->language, '';
} # _language

sub _language_value : Test(1) {
  my $track = new_track language => 'ja-JP';
  is $track->language, 'ja-JP';
} # _language_value

sub _mode : Test(6) {
  my $track = new_track mode => 'hidden';
  is $track->mode, 'hidden';

  $track->mode ('disabled');
  is $track->mode, 'disabled';
  
  $track->mode ('hidden');
  is $track->mode, 'hidden';

  $track->mode ('showing');
  is $track->mode, 'showing';

  dies_ok {
    $track->mode ('abc');
  };

  is $track->mode, 'showing';
} # _mode

# XXX cues

# XXX active_cues

sub _manakai_all_cues : Test(3) {
  my $list = new_cue_list;
  my $track = new_track all_cues => $list;
  
  my $list2 = $track->manakai_all_cues;
  is $list2, $list;
  is $track->manakai_all_cues, $list;

  my $cue = new_cue;
  $track->add_cue ($cue);

  is $list2->[0], $cue;
} # _manakai_all_cues

sub _add_cue_added : Test(8) {
  my $cue = new_cue;
  my $list = new_cue_list;
  my $track = new_track all_cues => $list;

  $track->add_cue ($cue);

  is $cue->track, $track;
  is $track->manakai_all_cues->[0], $cue;

  dom_exception_ok {
    $track->add_cue ($cue);
  } 'InvalidStateError';

  my $list2 = new_cue_list;
  my $track2 = new_track all_cues => $list2;
  dom_exception_ok {
    $track2->add_cue ($cue);
  } 'InvalidStateError';

  is $track->manakai_all_cues->[0], $cue;
  is $track->manakai_all_cues->length, 1;
  is $cue->track, $track;

  is $track2->manakai_all_cues->length, 0;
} # _add_cue_added

sub _remove_cue : Test(2) {
  my $cue = new_cue;
  my $list = new_cue_list;
  my $track = new_track all_cues => $list;
  $track->add_cue ($cue);

  $track->remove_cue ($cue);

  is $cue->track, undef;
  is $track->manakai_all_cues->length, 0;
} # _remove_cue

sub _remove_cue_not_added : Test(3) {
  my $cue = new_cue;
  my $list = new_cue_list;
  my $track = new_track all_cues => $list;

  dom_exception_ok {
    $track->remove_cue ($cue);
  } 'InvalidStateError';

  is $cue->track, undef;
  is $track->manakai_all_cues->length, 0;
} # _remove_cue_not_added

sub _remove_cue_not_added_but_associated : Test(3) {
  my $cue = new_cue;
  my $list = new_cue_list;
  my $track = new_track all_cues => $list;
  $cue->{track} = $track; # broken

  dom_exception_ok {
    $track->remove_cue ($cue);
  } 'NotFoundError';

  is $cue->track, $track;
  is $track->manakai_all_cues->length, 0;
} # _remove_cue_not_added_but_not_associated

sub _remove_cue_another_list : Test(4) {
  my $cue = new_cue;
  my $list = new_cue_list;
  my $list2 = new_cue_list;
  my $track = new_track all_cues => $list;
  my $track2 = new_track all_cues => $list2;

  $track2->add_cue ($cue);

  dom_exception_ok {
    $track->remove_cue ($cue);
  } 'InvalidStateError';

  is $cue->track, $track2;
  is $track2->manakai_all_cues->length, 1;
  is $track->manakai_all_cues->length, 0;
} # _remove_cue_another_list

sub _manakai_clone_track : Test(16) {
  my $cue1 = new_cue id => 'abc';
  my $cue2 = new_cue id => 'xyz';
  my $list = new_cue_list;
  my $track = new_track all_cues => $list, label => 'abc',
      mode => 'disabled', language => 'en', kind => 'subtitles';
  $track->add_cue ($cue1);
  $track->add_cue ($cue2);

  my $track2 = $track->manakai_clone_track;
  isnt $track2, $track;
  is ref $track2, ref $track;
  is $track2->kind, $track->kind;
  is $track2->label, $track->label;
  is $track2->mode, $track->mode;
  is $track2->language, $track->language;
  isnt $track2->manakai_all_cues, $track->manakai_all_cues;
  is $track2->cues, undef;
  is $track2->active_cues, undef;
  is $track2->manakai_is_invalid, $track->manakai_is_invalid;
  isa_ok $track2->manakai_all_cues, 'Message::DOM::TextTrackCueList';
  isnt $track2->manakai_all_cues->[0], $track->manakai_all_cues->[0];
  isnt $track2->manakai_all_cues->[1], $track->manakai_all_cues->[1];
  is $track2->manakai_all_cues->length, 2;
  is $track2->manakai_all_cues->[0]->id,
      $track->manakai_all_cues->[0]->id;
  is $track2->manakai_all_cues->[1]->id,
      $track->manakai_all_cues->[1]->id;
} # _manakai_clone_track

__PACKAGE__->runtests;

our $DetectLeak = 1;

sub Message::DOM::TextTrack::DESTROY
    { die ref ($_[0]) . ": Leak detected" if $DetectLeak }
sub Message::DOM::TextTrackCue::DESTROY
    { die ref ($_[0]) . ": Leak detected" if $DetectLeak }
sub Message::DOM::TextTrackCueList::DESTROY
    { die ref ($_[0]) . ": Leak detected" if $DetectLeak }

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
