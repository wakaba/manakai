package test::Whatpm::WebVTT::Serializer;
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
use Whatpm::WebVTT::Serializer;
use Message::DOM::DOMImplementation;

my $test_d = file (__FILE__)->dir->subdir ('data')->subdir ('webvtt');

sub _track_to_char_string_inputs : Tests {
  my $parser = Whatpm::WebVTT::Parser->new;

  for_each_test ($test_d->file ($_)->stringify, {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    parsed => {is_prefixed => 1},
    serialized => {is_prefixed => 1},
  }, sub {
    my $test = shift;
    return unless $test->{serialized};
    
    my $track = $parser->parse_char_string ($test->{data}->[0]);

    my $actual = Whatpm::WebVTT::Serializer->track_to_char_string
        ($track);
    my $expected = $test->{serialized}->[0];

    eq_or_diff $actual, $expected;

    my $track2 = $parser->parse_char_string ($actual);
    my $actual2 = Whatpm::WebVTT::Serializer->track_to_char_string
        ($track2);
    eq_or_diff $actual2, $actual;
  }) for qw(
    parse-1.dat
    parse-2.dat
    parse-timings-1.dat
    parse-settings-1.dat
  );
} # _parse_char_string_inputs

sub _text_to_dom_inputs : Tests {
  my $parser = Whatpm::WebVTT::Parser->new;
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  for_each_test ($test_d->file ($_)->stringify, {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    document => {is_prefixed => 1},
  }, sub {
    my $test = shift;
    return unless $test->{serialized};

    my $df = $parser->text_to_dom ($test->{data}->[0] => $doc);

    my $actual = Whatpm::WebVTT::Serializer->dom_to_text ($df);
    my $expected = $test->{serialized}->[0];

    eq_or_diff $actual, $expected;
  }) for qw(
    cue-text-1.dat
    cue-text-2.dat
    cue-text-3.dat
    cue-text-4.dat
  );
} # _text_to_dom_inputs

sub _track_to_char_string_id_1 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->id ("abc --> def");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\nabc --&gt; def\n00:12:22.000 --> 12:21:44.000\naaa\n};
} # track_to_char_string_id_1

sub _track_to_char_string_id_2 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->id ("abc\n");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\nabc \n00:12:22.000 --> 12:21:44.000\naaa\n};
} # track_to_char_string_id_2

sub _track_to_char_string_id_3 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->id ("abc\n\n\nxxx");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\nabc xxx\n00:12:22.000 --> 12:21:44.000\naaa\n};
} # track_to_char_string_id_3

sub _track_to_char_string_text_1 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->text ("abc --> xxx");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\n00:12:22.000 --> 12:21:44.000\nabc --&gt; xxx\n};
} # track_to_char_string_text_1

sub _track_to_char_string_text_2 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->text ("abc \n\n xxx");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\n00:12:22.000 --> 12:21:44.000\nabc \n xxx\n};
} # track_to_char_string_text_2

sub _track_to_char_string_text_3 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->text ("abc \x0D");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\n00:12:22.000 --> 12:21:44.000\nabc \n};
} # track_to_char_string_text_3

sub _track_to_char_string_text_4 : Test(1) {
  my $track = Whatpm::WebVTT::Parser->new->parse_char_string
      ("WEBVTT\n\n00:12:22.000 --> 12:21:44.000\naaa");
  $track->manakai_all_cues->[0]->text ("\x0Aabc ");
  
  my $serialized = Whatpm::WebVTT::Serializer->track_to_char_string
      ($track);
  eq_or_diff $serialized,
      qq{WEBVTT\n\n00:12:22.000 --> 12:21:44.000\nabc \n};
} # track_to_char_string_text_4

sub _dom_to_text_title_1 : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  my $el = $doc->create_element ('div');
  $el->inner_html (q{<span title="ab&#xa;bd&#xc;">foo</span>});
  
  my $text = Whatpm::WebVTT::Serializer->dom_to_text ($el);
  eq_or_diff $text, qq{<v ab\x0Abd\x0C>foo</v>};
} # _dom_to_text_title_1

sub _dom_to_text_title_2 : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  my $el = $doc->create_element ('div');
  $el->inner_html (q{<span title="ab<&>b">foo</span>});
  
  my $text = Whatpm::WebVTT::Serializer->dom_to_text ($el);
  eq_or_diff $text, qq{<v ab&lt;&amp;&gt;b>foo</v>};
} # _dom_to_text_title_2

sub _dom_to_text_class_1 : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  my $el = $doc->create_element ('div');
  $el->inner_html (q{<span class="&#xc; ab<&>b aa x.y dd">foo</span>});
  
  my $text = Whatpm::WebVTT::Serializer->dom_to_text ($el);
  eq_or_diff $text, qq{<c.aa.dd>foo</c>};
} # _dom_to_text_class_1

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
