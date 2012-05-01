package test::Whatpm::WebVTT::Parser;
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
use Whatpm::HTML::Dumper qw/dumptree/;
use Message::DOM::DOMImplementation;

my $test_d = file (__FILE__)->dir->subdir ('data')->subdir ('webvtt');

sub dump_text_track ($) {
  my $track = shift;
  my $result = '';

  if ($track->manakai_is_invalid) {
    $result .= "invalid\x0A";
  }

  #if (defined (my $trailer = $track->manakai_signature_trailer)) {
  #  $result .= qq{sigline "$trailer"\x0A};
  #}

  #if (length (my $headers = $track->manakai_headers)) {
  #  $result .= qq{headers "$headers"\x0A};
  #}

  for my $cue (@{$track->manakai_all_cues}) {
    my $start_time = $cue->start_time;
    $start_time = sprintf '%02d:%02d:%02d.%03d',
        int ($start_time / 60 / 60),
        int ($start_time / 60 % 60),
        int ($start_time % 60),
        int ($start_time * 1000 % 1000);
    my $end_time = $cue->end_time;
    $end_time = sprintf '%02d:%02d:%02d.%03d',
        int ($end_time / 60 / 60),
        int ($end_time / 60 % 60),
        int ($end_time % 60),
        int ($end_time * 1000 % 1000);
    $result .= "<$start_time> <$end_time>\x0A";

    #for (@{$cue->manakai_invalid_ids}) {
    #  $result .= "  invalid #" . $_ . "\x0A";
    #}
    if (length $cue->id) {
      $result .= "  #" . $cue->id . "\x0A";
    }

    if (length $cue->vertical) {
      $result .= "  writing direction " . $cue->vertical . "\x0A";
    }

    if ($cue->line != -1) {
      $result .= "  line position " . $cue->line . "\x0A";
    }

    unless ($cue->snap_to_lines) {
      $result .= "  not snap-to-lines\x0A";
    }

    if ($cue->position != 50) {
      $result .= "  text position " . $cue->position . "%\x0A";
    }

    if ($cue->size != 100) {
      $result .= "  size " . $cue->size . "%\x0A";
    }

    if ($cue->align ne 'middle') {
      $result .= "  align " . $cue->align . "\x0A";
    }

    my $text = $cue->text;
    $result .= qq<  "$text"\x0A>;
  }

  #for (@{$track->manakai_invalid_cues}) {
  #  $result .= qq<invalid "$_"\x0A>;
  #}
  
  return $result;
} # dump_text_track

sub _parse_char_string_inputs : Tests {
  my $parser = Whatpm::WebVTT::Parser->new;

  for_each_test ($test_d->file ($_)->stringify, {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    parsed => {is_prefixed => 1},
  }, sub {
    my $test = shift;

    my @error;
    local $parser->{onerror} = sub {
      my %args = @_;
      push @error, join ';', map { defined $_ ? $_ : '' } 
          $args{line}, $args{column}, $args{level},
          $args{type}, $args{text}, $args{value};
    };
    
    my $track = $parser->parse_char_string ($test->{data}->[0]);
    my $actual = dump_text_track $track;
    my $expected = $test->{parsed}->[0];
    $expected .= "\x0A" if length $expected;

    eq_or_diff $actual, $expected;
    eq_or_diff [sort { $a cmp $b } @error],
               [sort { $a cmp $b } @{$test->{errors}->[0]}];
  }) for qw(
    parse-1.dat
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

    my @error;
    local $parser->{onerror} = sub {
      my %args = @_;
      push @error, join ';', map { defined $_ ? $_ : '' } 
          $args{line}, $args{column}, $args{level},
          $args{type}, $args{text}, $args{value};
    };

    my $df = $parser->text_to_dom ($test->{data}->[0] => $doc);
    isa_ok $df, 'Message::DOM::DocumentFragment';
    is $df->owner_document, $doc;

    my $actual = dumptree $df;
    my $expected = $test->{document}->[0];
    $expected .= "\x0A" if length $expected;

    eq_or_diff $actual, $expected;
    eq_or_diff [sort { $a cmp $b } split /\n/, join "\n", @error],
               [sort { $a cmp $b } split /\n/, join "\n", @{$test->{errors}->[0]}];
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
