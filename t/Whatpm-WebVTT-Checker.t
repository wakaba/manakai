package test::Whatpm::WebVTT::Checker;
use strict;
use warnings;
no warnings 'utf8';
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Test::HTCT::Parser;
use Whatpm::WebVTT::Parser;
use Whatpm::WebVTT::Checker;
use Whatpm::HTML::Dumper qw/dumptree/;
use Message::DOM::DOMImplementation;

## Most tests are found in Whatpm-WebVTT-Parser.t.

sub parse_webvtt ($) {
  my $s = shift;
  return Whatpm::WebVTT::Parser->new->parse_char_string ($s);
} # parse_webvtt

sub _check_track_id_syntax : Test(3) {
  for my $id (
    "abc --> def",
    "abc \x0A def",
    "abc def\x0D",
  ) {
    my $track = parse_webvtt "WEBVTT\x0A\x0A00:01.000 --> 00:02.000\x0Aa";
    my $cue = $track->manakai_all_cues->[0];
    $cue->id ($id);
    
    my @error;
    my $checker = Whatpm::WebVTT::Checker->new;
    $checker->onerror (sub {
      push @error, {@_};
    });
    $checker->check_track ($track);
    
    eq_or_diff \@error, [
      {type => 'webvtt:id:syntax',
       level => 'm',
       line => 3, column => 1},
    ];
  }
} # _check_track_id_syntax

sub _check_track_text_syntax : Test(5) {
  for my $text (
    "abc \x0A\x0A--> def",
    "\x0Aabc",
    "abc\x0D",
    "\x0D\x0A",
    "\x0A",
  ) {
    my $track = parse_webvtt "WEBVTT\x0A\x0A00:01.000 --> 00:02.000\x0Aa";
    my $cue = $track->manakai_all_cues->[0];
    $cue->text ($text);
    
    my @error;
    my $checker = Whatpm::WebVTT::Checker->new;
    $checker->onerror (sub {
      push @error, {@_};
    });
    $checker->check_track ($track);
    
    eq_or_diff \@error, [
      {type => 'webvtt:text:syntax',
       level => 'm',
       line => 3, column => 1},
    ];
  }
} # _check_track_text_syntax

sub _check_track_text_syntax_ok : Test(4) {
  for my $text (
    "abc \x0A def",
    "aa --> de",
    "",
    "\x0C",
  ) {
    my $track = parse_webvtt "WEBVTT\x0A\x0A00:01.000 --> 00:02.000\x0Aa";
    my $cue = $track->manakai_all_cues->[0];
    $cue->text ($text);
    
    my @error;
    my $checker = Whatpm::WebVTT::Checker->new;
    $checker->onerror (sub {
      push @error, {@_};
    });
    $checker->check_track ($track);
    
    eq_or_diff \@error, [];
  }
} # _check_track_text_syntax_ok

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
