package test::Message::DOM::TextTrackCue;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::TextTrackCue;

sub new_cue (;%) {
  return Message::DOM::TextTrackCue->____new_from_hashref ({@_});
} # new_cue

sub _track_not_associated : Test(1) {
  my $cue = new_cue;
  is $cue->track, undef;
} # _track_not_associated

sub _track_associated : Test(3) {
  my $obj = bless {}, 'test::dummy';
  my $cue = new_cue track => $obj;
  isa_ok $cue->track, ref $obj;
  is $cue->track, $obj;
  is $cue->track, $cue->track;
} # _track_associated

sub _line_column_none : Test(2) {
  my $cue = new_cue;
  is $cue->manakai_line, -1;
  is $cue->manakai_column, -1;
} # _line_column_none

sub _line_column_specified : Test(2) {
  my $cue = new_cue line => 12, column => 31;
  is $cue->manakai_line, 12;
  is $cue->manakai_column, 31;
} # _line_column_specified

sub _id_none : Test(1) {
  my $cue = new_cue id => '';
  is $cue->id, '';
} # _id_none

sub _id_found : Test(1) {
  my $cue = new_cue id => "hoge fuga\x{1000}";
  is $cue->id, "hoge fuga\x{1000}";
} # _id_found

sub _id_set : Test(4) {
  my $cue = new_cue;
  $cue->id (0);
  is $cue->id, "0";
  
  $cue->id ("");
  is $cue->id, "";
  
  $cue->id ("ab  cd\x09");
  is $cue->id, "ab  cd\x09";

  $cue->id (undef);
  is $cue->id, "";
} # _id_set

sub _start_time : Test(4) {
  my $cue = new_cue start_time => -10.213;
  is $cue->start_time, "-10.213";

  $cue->start_time (0);
  is $cue->start_time, 0;

  $cue->start_time ("102abc");
  is $cue->start_time, 102;

  $cue->start_time (-1241.3331);
  is $cue->start_time, "-1241.3331";
} # _start_time

sub _end_time : Test(4) {
  my $cue = new_cue end_time => -10.213;
  is $cue->end_time, "-10.213";

  $cue->end_time (0);
  is $cue->end_time, 0;

  $cue->end_time ("102abc");
  is $cue->end_time, 102;

  $cue->end_time (-1241.3331);
  is $cue->end_time, "-1241.3331";
} # _end_time

sub _pause_on_exit : Test(3) {
  my $cue = new_cue;
  ng $cue->pause_on_exit;

  $cue->pause_on_exit (1);
  ok $cue->pause_on_exit;

  $cue->pause_on_exit (undef);
  ng $cue->pause_on_exit;
} # _pause_on_exit

sub _pause_on_exit_specified : Test(1) {
  my $cue = new_cue pause_on_exit => 1;
  ok $cue->pause_on_exit;
} # _pause_on_exit_specified

sub _manakai_clone_cue : Test(6) {
  my $cue = new_cue
      text => 'abc<v hoge>fuga abc',
      track => 'ab dce ',
      start_time => 4242,
      end_time => 4143,
      size => 21,
      align => 'end';
  my $cue2 = $cue->manakai_clone_cue;
  isnt $cue2, $cue;
  is ref $cue2, ref $cue;
  is $cue2->pause_on_exit, $cue->pause_on_exit;
  is $cue2->start_time, $cue->start_time;
  is $cue2->end_time, $cue->end_time;
  is $cue2->track, undef;
} # _manakai_clone_cue

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012-2013 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
