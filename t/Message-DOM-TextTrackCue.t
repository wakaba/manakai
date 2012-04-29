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

sub _vertical : Test(7) {
  my $cue = new_cue writing_direction => '';
  is $cue->vertical, '';
  
  $cue->vertical ('rl');
  is $cue->vertical, 'rl';

  $cue->vertical ('lr');
  is $cue->vertical, 'lr';

  $cue->vertical ('');
  is $cue->vertical, '';

  $cue->vertical (undef);
  is $cue->vertical, '';

  dom_exception_ok {
    $cue->vertical ('abc');
  } 'SyntaxError';
  $cue->vertical, '';

  dom_exception_ok {
    $cue->vertical ('rl2');
  } 'SyntaxError';
  $cue->vertical, '';
} # _vertical

sub _vertical_specified : Test(1) {
  my $cue = new_cue writing_direction => 'rl';
  is $cue->vertical, 'rl';
} # _vertical_specified

sub snap_to_lines : Test(3) {
  my $cue = new_cue snap_to_lines => 1;
  ok $cue->snap_to_lines;

  $cue->snap_to_lines (0);
  ng $cue->snap_to_lines;

  $cue->snap_to_lines (1);
  ok $cue->snap_to_lines;
} # snap_to_lines

sub _line_line_position_specified : Test(1) {
  my $cue = new_cue line_position => 30;
  is $cue->line, 30;
} # _line_line_position_specified

sub _line_line_position_auto_not_snap_to_lines : Test(1) {
  my $cue = new_cue line_position => undef, snap_to_lines => 0;
  is $cue->line, 100;
} # _line_line_position_auto_not_snap_to_lines

sub _line_line_position_auto_snap_to_lines_no_track : Test(1) {
  my $cue = new_cue line_position => undef, snap_to_lines => 1;
  is $cue->line, -1;
} # _line_line_position_auto_snap_to_lines_no_track

# XXX with associated track

sub _line_setter_snap_to_lines : Test(3) {
  my $cue = new_cue snap_to_lines => 1;

  $cue->line (120);
  is $cue->line, 120;

  $cue->line (-12.12);
  is $cue->line, -12;

  $cue->line ("abc");
  is $cue->line, 0;
} # _line_setter_snap_to_lines

sub _line_setter_not_snap_to_lines : Test(8) {
  my $cue = new_cue;

  $cue->line (12);
  is $cue->line, 12;

  $cue->line (98.112);
  is $cue->line, 98;

  dom_exception_ok {
    $cue->line (-12);
  } 'IndexSizeError';

  dom_exception_ok {
    $cue->line (101);
  } 'IndexSizeError';

  is $cue->line, 98;

  $cue->line (100);
  is $cue->line, 100;

  $cue->line ("abc");
  is $cue->line, 0;

  $cue->line (undef);
  is $cue->line, 0;
} # _line_setter_not_snap_to_lines

sub _position : Test(9) {
  my $cue = new_cue text_position => 12;
  is $cue->position, 12;

  $cue->position (45);
  is $cue->position, 45;

  $cue->position (98.1224);
  is $cue->position, 98;

  $cue->position ("12.abc");
  is $cue->position, 12;

  $cue->position (undef);
  is $cue->position, 0;

  dom_exception_ok {
    $cue->position (-1);
  } 'IndexSizeError';

  dom_exception_ok {
    $cue->position (101);
  } 'IndexSizeError';

  is $cue->position, 0;

  $cue->position (100);
  is $cue->position, 100;
} # _position

sub _size : Test(9) {
  my $cue = new_cue size => 12;
  is $cue->size, 12;

  $cue->size (45);
  is $cue->size, 45;

  $cue->size (98.1224);
  is $cue->size, 98;

  $cue->size ("12.abc");
  is $cue->size, 12;

  $cue->size (undef);
  is $cue->size, 0;

  dom_exception_ok {
    $cue->size (-1);
  } 'IndexSizeError';

  dom_exception_ok {
    $cue->size (101);
  } 'IndexSizeError';

  is $cue->size, 0;

  $cue->size (100);
  is $cue->size, 100;
} # _size

sub _align : Test(6) {
  my $cue = new_cue align => 'start';
  is $cue->align, 'start';
  
  $cue->align ('middle');
  is $cue->align, 'middle';

  $cue->align ('end');
  is $cue->align, 'end';

  $cue->align ('start');
  is $cue->align, 'start';

  dom_exception_ok {
    $cue->align ('Start');
  } 'SyntaxError';

  is $cue->align, 'start';
} # _align

sub _text : Test(5) {
  my $cue = new_cue text => 'abc<v hoge>fuga abc';
  is $cue->text, 'abc<v hoge>fuga abc';

  $cue->text (0);
  is $cue->text, "0";

  $cue->text ("\x{4000}abc");
  is $cue->text, "\x{4000}abc";

  $cue->text (undef);
  is $cue->text, '';

  $cue->text ("<>abc");
  is $cue->text, "<>abc";
} # _text

# XXX get_cue_as_html

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
