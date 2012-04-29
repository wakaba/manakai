package test::Message::DOM::TextTrackCueList;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::TextTrackCue;
use Message::DOM::TextTrackCueList;

sub new_cue (;%) {
  return Message::DOM::TextTrackCue->____new_from_hashref
      ({id => '', @_});
} # new_cue

sub new_cue_list (@) {
  return Message::DOM::TextTrackCueList->____new_from_arrayref ([@_]);
} # new_cue_list

sub _length_empty : Test(1) {
  my $list = new_cue_list;
  is $list->length, 0;
} # _length_empty

sub _length_not_empty : Test(2) {
  my $list = new_cue_list new_cue, new_cue;
  is $list->length, 2;
  
  push @$list, new_cue;
  is $list->length, 3;
} # _length_not_empty

sub _index_empty : Test(4) {
  my $list = new_cue_list;
  is $list->[0], undef;
  is $list->[100], undef;
  is $list->length, 0;
  dies_ok {
    ok $list->[-1];
  };
} # _index_empty

sub _index_not_empty : Test(4) {
  my $cue1 = new_cue;
  my $cue2 = new_cue;
  my $list = new_cue_list $cue1, $cue2;
  is $list->[0], $cue1;
  is $list->[1], $cue2;
  is $list->[2], undef;
  pop @$list;
  is $list->[1], undef;
} # _index_not_empty

sub _get_cue_by_id_empty : Test(4) {
  my $list = new_cue_list;
  is $list->get_cue_by_id ('abc'), undef;
  is $list->get_cue_by_id (undef), undef;
  is $list->get_cue_by_id (''), undef;
  is $list->get_cue_by_id (120), undef;
} # _get_cue_by_id_empty

sub _get_cue_by_id_found : Test(3) {
  my $cue = new_cue id => 'abc def  ';
  my $cue2 = new_cue id => 'abc def  ';
  my $list = new_cue_list new_cue, new_cue, $cue, $cue2, new_cue, $cue;
  is $list->get_cue_by_id ('abc def  '), $cue;
  is $list->get_cue_by_id ('abc def  '), $cue;
  is $list->get_cue_by_id ('abc def'), undef;
} # _get_cue_by_id_found

sub _get_cue_by_id_empty_string : Test(2) {
  my $cue = new_cue id => '';
  my $list = new_cue_list $cue, $cue;
  is $list->get_cue_by_id (''), undef;
  is $list->get_cue_by_id (0), undef;
} # _get_cue_by_id_empty_string

sub _get_cue_by_id_not_found : Test(2) {
  my $cue = new_cue id => 'abc';
  my $list = new_cue_list $cue;
  is $list->get_cue_by_id ('abcd'), undef;
  is $list->get_cue_by_id ('ABC'), undef;
} # _get_cue_by_id_not_found

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
