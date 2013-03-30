package Message::DOM::WebVTTCue;
use strict;
use warnings;
our $VERSION = '1.0';
use Message::DOM::TextTrackCue;
push our @ISA, qw(Message::DOM::TextTrackCue);
use Message::DOM::DOMException;

## Spec: <http://dev.w3.org/html5/webvtt/#webvttcue>.

# XXX constructor

sub vertical ($;$) {
  if (@_ > 1) {
    if ($_[1] eq '' or $_[1] eq 'rl' or $_[1] eq 'lr') {
      $_[0]->{writing_direction} = $_[1] . '';
    } else {
      # XXX error reporting
      report Message::DOM::DOMException
          #-object => $_[0],
          -type => 'SYNTAX_ERR';
    }
  }
  return $_[0]->{writing_direction};
} # vertical

sub snap_to_lines ($;$) {
  if (@_ > 1) {
    $_[0]->{snap_to_lines} = !!$_[1];
  }
  return $_[0]->{snap_to_lines};
} # snap_to_lines

sub line ($;$) {
  if (@_ > 1) {
    if (not $_[0]->{snap_to_lines} and
        ($_[1] < 0 or $_[1] > 100)) {
      # XXX error reporting
      report Message::DOM::DOMException
          #-object => $_[0],
          -type => 'INDEX_SIZE_ERR';
    }
    $_[0]->{line_position} = int $_[1];
    return unless defined wantarray;
  }

  ## Text track cue computed line position
  ## <http://www.whatwg.org/specs/web-apps/current-work/#text-track-cue-computed-line-position>.
  if (defined $_[0]->{line_position}) {
    return $_[0]->{line_position};
  } else {
    if (not $_[0]->{snap_to_lines}) {
      return 100;
    } else {
      ## Step 1
      my $cue = $_[0];

      ## Step 3
      my $track = $cue->track;
      
      ## Step 2
      unless ($track) {
        return -1;
      }

      ## Step 4
      # XXX
      my $n = 0;
      
      ## Step 5-7
      return -($n + 1);
    }
  }
} # line

sub position ($;$) {
  if (@_ > 1) {
    if ($_[1] < 0 or $_[1] > 100) {
      # XXX error reporting
      report Message::DOM::DOMException
          #-object => $_[0],
          -type => 'INDEX_SIZE_ERR';
    }
    $_[0]->{text_position} = int $_[1];
  }
  return $_[0]->{text_position};
} # position

sub size ($;$) {
  if (@_ > 1) {
    if ($_[1] < 0 or $_[1] > 100) {
      # XXX error reporting
      report Message::DOM::DOMException
          #-object => $_[0],
          -type => 'INDEX_SIZE_ERR';
    }
    $_[0]->{size} = int $_[1];
  }
  return $_[0]->{size};
} # size

sub align ($;$) {
  if (@_ > 1) {
    if ($_[1] eq 'start' or $_[1] eq 'middle' or $_[1] eq 'end') {
      $_[0]->{align} = $_[1];
    } else {
      # XXX error reporting
      report Message::DOM::DOMException
          #-object => $_[0],
          -type => 'SYNTAX_ERR';
    }
  }
  return $_[0]->{align};
} # align

sub text ($;$) {
  if (@_ > 1) {
    $_[0]->{text} = $_[1] . '';
  }
  return $_[0]->{text};
} # text

sub get_cue_as_html ($) {
  
  # XXX
  die "Not implemented yet";

} # get_cue_as_html

1;

=head1 LICENSE

Copyright 2012-2013 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
