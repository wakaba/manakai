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
