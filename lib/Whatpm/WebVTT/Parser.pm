package Whatpm::WebVTT::Parser;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '1.0';
use Encode qw(decode);

my $DefaultErrorHandler = sub {
  my %args = @_;
  warn sprintf "[%s] %s at Line %d Column %d\n",
      $args{level},
      $args{type}
          . (defined $args{text} ? ' ' . $args{text} : '')
          . (defined $args{value} ? ' ' . $args{value} : ''),
      $args{line}, $args{column};
}; # $DefaultErrorHandler

sub new ($) {
  return bless {
    onerror => $DefaultErrorHandler,
  }, $_[0];
} # new

sub onerror ($;$) {
  if (@_ > 1) {
    $_[0]->{onerror} = $_[1] || $DefaultErrorHandler;
  } 
  return $_[0]->{onerror};
} # onerror

sub init ($) {
  my $self = shift;
  
  $self->{state} = 'signature';
  $self->{l} = 0;
  $self->{c} = 0;
  
  require Message::DOM::TextTrack;
  require Message::DOM::WebVTTCue;
  require Message::DOM::TextTrackCueList;
  $self->{parsed} = Message::DOM::TextTrack->____new_from_hashref
      ({
          kind => 'subtitles', ## Default for <track kind>
          mode => 'hidden', ## Random default
          all_cues => Message::DOM::TextTrackCueList
              ->____new_from_arrayref ([]),
       });
} # init

sub parse_byte_string ($$) {
  my $self = $_[0];
  $self->init;
  
  my @line = split /(\x0D\x0A?|\x0A)/, $_[1], -1;
  if (@line) {
    # XXX Web UTF-8

    $line[0] =~ s/^\xEF\xBB\xBF//; # U+FEFF BOM

    while (@line) {
      my ($line, $eol) = (shift @line, shift @line);
      $self->feed_line ((decode 'utf-8', $line), $eol);
    }
  } else {
    $self->feed_line ('', undef);
  }

  return $self->{parsed};
} # parse_byte_string

sub parse_char_string ($$) {
  my $self = $_[0];
  $self->init;
  
  my @line = split /(\x0D\x0A?|\x0A)/, $_[1], -1;
  if (@line) {
    while (@line) {
      my ($line, $eol) = (shift @line, shift @line);
      $self->feed_line ($line, $eol);
    }
  } else {
    $self->feed_line ('', undef);
  }

  return $self->{parsed};
} # parse_char_string

sub feed_line ($$$) {
  my ($self, $line, $eol) = @_;
  $self->{l}++;

  STATE: {
    if ($self->{state} eq 'signature') {
      ## NOTE: BOM (U+FEFF) must be dropped when bytes-chars
      ## convertion is done.

      if ($line =~ /\AWEBVTT(?:[\x20\x09]([^\x0D\x0A]*))?\z/) {
        #$self->{parsed}->{signature_trailer} = $1;
        #$self->{parsed}->{signature_trailer} =~ tr/\x00/\x{FFFD}/
        #    if defined $self->{parsed}->{signature_trailer};
        $self->{state} = 'header';
      } else {
        $self->{parsed}->{invalid} = 1;
        $self->{onerror}->(type => 'webvtt:no signature',
                           level => 'm',
                           line => $self->{l}, column => 1);
        return;
      }
    } elsif ($self->{state} eq 'header') {
      if ($line =~ /-->/ and defined $eol) {
        $self->{onerror}->(type => 'webvtt:no header end',
                           level => 'm',
                           line => $self->{l}, column => 1);
        $self->{state} = 'before cue';
        redo STATE;
      } elsif ($line eq '' and defined $eol) {
        $self->{state} = 'before cue';
      } else {
        if (not @{$self->{parsed}->{headers} || []}) {
          $self->{onerror}->(type => 'webvtt:headers',
                             level => 'm',
                             line => $self->{l}, column => 1);
        }
        $line =~ tr/\x00/\x{FFFD}/;
        push @{$self->{parsed}->{headers} ||= []}, $line if length $line;
        $self->{state} = 'end' if not defined $eol;
      }
    } elsif ($self->{state} eq 'before cue') {
      if ($line eq '' and defined $eol) {
        #
      } elsif ($line eq '' and not defined $eol) {
        $self->{state} = 'end';
      } else {
        $self->{new_cue} = {
          id => '',
          writing_direction => '', # horizontal
          snap_to_lines => 1,
          text_position => 50,
          size => 100,
          align => 'middle',
          text => '',
          line => $self->{l},
          column => 1,
        };
        if ($line =~ /-->/) {
          $self->{state} = 'timings';
          redo STATE;
        } else {
          if (defined $eol) {
            $line =~ tr/\x00/\x{FFFD}/;
            $self->{new_cue}->{id} = $line;
            $self->{state} = 'before timings';
          } else {
            $self->{onerror}->(type => 'webvtt:no timings',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + length $line);
            #push @{$self->{parsed}->{invalid_cues} ||= []}, $line;
            $self->{state} = 'end';
          }
        }
      }
    } elsif ($self->{state} eq 'before timings') {
      if ($line eq '' or
          (not defined $eol and not $line =~ /-->/)) {
        $self->{onerror}->(type => 'webvtt:no timings',
                           level => 'm',
                           line => $self->{l},
                           column => 1 + length $line);
        #push @{$self->{parsed}->{invalid_cues} ||= []},
        #    join "\x0A",
        #        @{$self->{new_cue}->{invalid_ids} ||= []},
        #        $self->{new_cue}->{id},
        #        length $line ? $line : ();
        $self->{state} = defined $eol ? 'before cue' : 'end';
      } else {
        if ($line =~ /-->/) {
          $self->{state} = 'timings';
          redo STATE;
        } else {
          $self->{onerror}->(type => 'webvtt:id:multiple',
                             level => 'm',
                             line => $self->{l} - 1, column => 1);
          #push @{$self->{new_cue}->{invalid_ids} ||= []},
          #    $self->{new_cue}->{id};
          $line =~ tr/\x00/\x{FFFD}/;
          $self->{new_cue}->{id} = $line;
        }
      }
    } elsif ($self->{state} eq 'timings') {
      {
        if ($line =~ s/\A(
          ## \x0A\x0D will never appear
          [\x09\x0A\x0C\x0D\x20]*
          ([0-9]+):([0-9]{2})(?::([0-9]{2}))?\.([0-9]{3})
          [\x09\x0A\x0C\x0D\x20]* --> [\x09\x0A\x0C\x0D\x20]*
          ([0-9]+):([0-9]{2})(?::([0-9]{2}))?\.([0-9]{3})
        )//x) {
          ## Timestamps
          my ($all, $sh, $sm, $ss, $sf, $eh, $em, $es, $ef)
              = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
          my @p = @+;
          my @m = @-;
          if (not defined $ss) {
            if (2 == length $sh and $sh < 60) {
              ($sh, $sm, $ss) = (0, $sh, $sm);
            } else {
              $self->{onerror}->(type => 'webvtt:bad timestamp',
                                 level => 'm',
                                 line => $self->{l},
                                 column => 1 + $m[2]);
              last;
            }
          } elsif (1 == length $sh) {
            $self->{onerror}->(type => 'webvtt:timestamp:hour',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + $m[2]);
          }
          if (not defined $es) {
            if (2 == length $eh and $eh < 60) {
              ($eh, $em, $es) = (0, $eh, $em);
            } else {
              $self->{onerror}->(type => 'webvtt:bad timestamp',
                                 level => 'm',
                                 line => $self->{l},
                                 column => 1 + $m[6]);
              last;
            }
          } elsif (1 == length $eh) {
            $self->{onerror}->(type => 'webvtt:timestamp:hour',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + $m[6]);
          }
          if ($sm > 59 or $ss > 59) {
            $self->{onerror}->(type => 'webvtt:bad timestamp',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + $m[2]);
            last;
          }
          if ($em > 59 or $es > 59) {
            $self->{onerror}->(type => 'webvtt:bad timestamp',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + $m[6]);
            last;
          }

          if ($all =~ /^[^0-9]/) {
            $self->{onerror}->(type => 'webvtt:timings:leading space',
                               level => 'm',
                               line => $self->{l}, column => 1);
          }
          if ($all =~ /\x0C/) {
            my $col = 1 + index $all, "\x0C";
            $self->{onerror}->(type => 'form feed',
                               level => 'm',
                               line => $self->{l}, column => $col);
          }
          if ($all =~ /[0-9]-->/) {
            $self->{onerror}->(type => 'webvtt:timings:no space',
                               level => 'm',
                               line => $self->{l}, column => 2 + $p[5]);
          }
          if ($all =~ /-->[0-9]/) {
            $self->{onerror}->(type => 'webvtt:timings:no space',
                               level => 'm',
                               line => $self->{l}, column => 1 + $m[6]);
          }

          $self->{new_cue}->{start_time} = $sh*60*60 + $sm * 60 + "$ss.$sf";
          $self->{new_cue}->{end_time} = $eh*60*60 + $em * 60 + "$es.$ef";

          $self->{c} = length $all;
          $self->parse_settings ($line => $self->{new_cue});
          
          if (defined $eol) {
            $self->{state} = 'cue text 1';
          } else {
            $self->{onerror}->(type => 'webvtt:no text',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + length $_[1]);
            push @{$self->{parsed}->{all_cues}},
                Message::DOM::WebVTTCue->____new_from_hashref
                    ($self->{new_cue});
            $self->{state} = 'end';
          }
          last STATE;
        } else {
          $self->{onerror}->(type => 'webvtt:bad timestamp',
                             level => 'm',
                             line => $self->{l}, column => 1);
        }
      }

      #push @{$self->{parsed}->{invalid_cues} ||= []}, $_[1];
      #if ($self->{new_cue} and length $self->{new_cue}->{id}) {
      #  $self->{parsed}->{invalid_cues}->[-1]
      #      = $self->{new_cue}->{id} . "\x0A" . $_[1];
      #}
      $self->{state} = 'bad cue';
    } elsif ($self->{state} eq 'cue text 1') {
      if ($line eq '') {
        push @{$self->{parsed}->{all_cues}},
            Message::DOM::WebVTTCue->____new_from_hashref
                ($self->{new_cue});
        $self->{state} = 'cue text 1 blank';
      } else {
        $self->{state} = 'cue text';
        redo STATE;
      }
    } elsif ($self->{state} eq 'cue text 1 blank') {
      if ($line eq '') {
        $self->{state} = 'before cue';
        redo STATE;
      } else {
        $self->{onerror}->(type => 'webvtt:no cue separator',
                           level => 'm',
                           line => $self->{l},
                           column => 1);
        $self->{state} = 'before cue';
        redo STATE;
      }
    } elsif ($self->{state} eq 'cue text') {
      if ($line =~ /-->/) {
        $self->{onerror}->(type => 'webvtt:no cue separator',
                           level => 'm',
                           line => $self->{l},
                           column => 1);
      } elsif ($line eq '') {
        $self->{new_cue}->{text_line} ||= $self->{l};
      } else {
        $self->{new_cue}->{text_line} ||= $self->{l};
        $self->{new_cue}->{text} .= "\x0A"
            if length $self->{new_cue}->{text};
        $self->{new_cue}->{text} .= $line;
      }

      if ($line =~ /-->/ or $line eq '' or not defined $eol) {
        $self->{new_cue}->{text} =~ tr/\x00/\x{FFFD}/;
        push @{$self->{parsed}->{all_cues}},
            Message::DOM::WebVTTCue->____new_from_hashref
                ($self->{new_cue});
        $self->{state} = defined $eol ? 'before cue' : 'end';
        redo STATE if defined $eol;
      }
    } elsif ($self->{state} eq 'bad cue') {
      if (not defined $eol) {
        #$self->{parsed}->{invalid_cues}->[-1] .= "\x0A" . $line
        #    if length $line;
        $self->{state} = 'end';
      } elsif ($line =~ /-->/ or $line eq '') {
        $self->{state} = 'before cue';
        redo STATE;
      } else {
        #$self->{parsed}->{invalid_cues}->[-1] .= "\x0A" . $line;
      }
    } elsif ($self->{state} eq 'end') {
      #
    } else {
      die "Unknown state: |$self->{state}|";
    }
  }
} # feed_line

sub parse_settings ($$$) {
  my $self = $_[0];
  my $cue = $_[2];

  if ($_[1] =~ /\x0C/) {
    my $col = $self->{c} + 1 + index $_[1], "\x0C";
    $self->{onerror}->(type => 'form feed',
                       level => 'm',
                       line => $self->{l}, column => $col);
  }

  my @setting = split /([\x09\x0A\x0C\x0D\x20]+)/, $_[1], -1;
  if (@setting >= 2 and $setting[0] eq '') {
    $self->{c} += length $setting[1];
    shift @setting;
    shift @setting;
  }

  my %last_pos;
  for my $setting (@setting) {
    if ($setting =~ /[\x09\x0A\x0C\x0D\x20]/) {
      next;
    }
    my ($name, $value) = split /:/, $setting, 2;
    if (not defined $name or $name eq '') {
      $self->{onerror}->(type => 'webvtt:setting:empty name',
                         level => 'm',
                         line => $self->{l},
                         column => $self->{c} + 1);
      next;
    } elsif (not defined $value) {
      $self->{onerror}->(type => 'webvtt:setting:no value',
                         level => 'm',
                         value => $name,
                         line => $self->{l},
                         column => $self->{c} + 1 + length $name);
      next;
    } elsif ($value eq '') {
      $self->{onerror}->(type => 'webvtt:setting:empty value',
                         level => 'm',
                         value => $name,
                         line => $self->{l},
                         column => $self->{c} + 2 + length $name);
      next;
    }

    if ($name eq 'vertical') {
      if ($value eq 'rl' or $value eq 'lr') {
        $cue->{writing_direction} = $value;
        if ($last_pos{$name}) {
          $self->{onerror}->(type => 'webvtt:setting:duplicate',
                             level => 'm',
                             value => $name,
                             line => $self->{l},
                             column => $last_pos{$name});
        }
        $last_pos{$name} = $self->{c} + 1;
        next;
      }
    } elsif ($name eq 'line') {
      if ($value =~ /\A((-?)[0-9]+)(%?)\z/) {
        unless ($3 and (not (0 <= $1 and $1 <= 100) or $2)) {
          $cue->{line_position} = 0+$1;
          $cue->{snap_to_lines} = !$3;
          if ($last_pos{$name}) {
            $self->{onerror}->(type => 'webvtt:setting:duplicate',
                               level => 'm',
                               value => $name,
                               line => $self->{l},
                               column => $last_pos{$name});
          }
          $last_pos{$name} = $self->{c} + 1;
          next;
        }
      }
    } elsif ($name eq 'position') {
      if ($value =~ /\A([0-9]+)%\z/) {
        if (0 <= $1 and $1 <= 100) {
          $cue->{text_position} = 0+$1;
          if ($last_pos{$name}) {
            $self->{onerror}->(type => 'webvtt:setting:duplicate',
                               level => 'm',
                               value => $name,
                               line => $self->{l},
                               column => $last_pos{$name});
          }
          $last_pos{$name} = $self->{c} + 1;
          next;
        }
      }
    } elsif ($name eq 'size') {
      if ($value =~ /\A([0-9]+)%\z/) {
        if (0 <= $1 and $1 <= 100) {
          $cue->{size} = 0+$1;
          if ($last_pos{$name}) {
            $self->{onerror}->(type => 'webvtt:setting:duplicate',
                               level => 'm',
                               value => $name,
                               line => $self->{l},
                               column => $last_pos{$name});
          }
          $last_pos{$name} = $self->{c} + 1;
          next;
        }
      }
    } elsif ($name eq 'align') {
      if ($value =~ /\A(?:start|middle|end)\z/) {
        $cue->{align} = $value;
        if ($last_pos{$name}) {
          $self->{onerror}->(type => 'webvtt:setting:duplicate',
                             level => 'm',
                             value => $name,
                             line => $self->{l},
                             column => $last_pos{$name});
        }
        $last_pos{$name} = $self->{c} + 1;
        next;
      }
    } else {
      $self->{onerror}->(type => 'webvtt:setting:invalid',
                         level => 'm',
                         value => $name,
                         line => $self->{l},
                         column => $self->{c} + 1);
      next;
    }
    
    $self->{onerror}->(type => 'webvtt:setting:invalid value',
                       level => 'm',
                       text => $name,
                       value => $value,
                       line => $self->{l},
                       column => $self->{c} + 2 + length $name);
  } continue {
    $self->{c} += length $setting;
  }
} # parse_settings

sub HTML_NS () { q<http://www.w3.org/1999/xhtml> }

sub text_to_dom ($$$;%) {
  my $self = $_[0];
  
  my $tokens = $self->tokenize_text ($_[1], @_[3..$#_]);
  return $self->construct_dom_from_tokens ($tokens => $_[2]);
} # text_to_dom

sub tokenize_text ($$;%) {
  my $self = shift;
  my @s = split //, shift;
  my %args = @_;

  my $line = $args{line} || 1;
  my $column = $args{column} || 1;

  my $tokenizer_state = 'data';
  my $result = '';
  my $buffer = '';
  my $classes = [];

  my $start_line = $line;
  my $start_column = $column;
  my $annotation_line = $line;
  my $annotation_column = $column;
  my $annotation_error;
  my $tokens = [];
  
  LOOP: for my $position (0..@s) {
    my $c = $position <= $#s ? ord $s[$position] : -1;
    if ($tokenizer_state eq 'data') {
      if ($c == 0x26) { # &
        $buffer = $s[$position];
        $tokenizer_state = 'escape';
        next LOOP;
      } elsif ($c == 0x3C) { # <
        if ($result ne '') {
          push @$tokens, {type => 'string', value => $result,
                          line => $start_line, column => $start_column};
          $result = '';
          ($start_line, $start_column) = ($line, $column);
        }

        $tokenizer_state = 'tag';
        next LOOP;
      } elsif ($c == -1) { # EOF
        push @$tokens, {type => 'string', value => $result,
                        line => $start_line, column => $start_column}
            if length $result;
        last;
      } else {
        $result .= $s[$position];
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'escape') {
      if ($c == 0x26) { # &
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $result .= $buffer;
        $buffer = $s[$position];
        next LOOP;
      } elsif ((0x30 <= $c and $c <= 0x39) or # 0-9
               (0x41 <= $c and $c <= 0x5A) or # A-Z
               (0x61 <= $c and $c <= 0x7A)) { # a-z
        $buffer .= $s[$position];
        next LOOP;
      } elsif ($c == 0x3B) { # ;
        $result .= {
          '&amp' => '&',
          '&lt' => '<',
          '&gt' => '>',
          '&lrm' => "\x{200E}",
          '&rlm' => "\x{200F}",
          '&nbsp' => "\xA0",
        }->{$buffer} || do {
          $self->{onerror}->(type => 'entity not declared',
                             level => 'm',
                             value => (substr $buffer, 1),
                             line => $line,
                             column => $column - length $buffer);
          $buffer . ';';
        };
        $tokenizer_state = 'data';
        next LOOP;
      } elsif ($c == 0x003C) { # <
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $result .= $buffer;
        push @$tokens, {type => 'string', value => $result,
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column);
        $result = '';
        $tokenizer_state = 'tag';
        next;
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $result .= $buffer;
        push @$tokens, {type => 'string', value => $result,
                        line => $start_line, column => $start_column};
        last;
      } else {
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $result .= $buffer . $s[$position];
        $tokenizer_state = 'data';
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'tag') {
      if ($c == 0x0009 or
          $c == 0x000A or
          $c == 0x000C or
          $c == 0x000D or ## Not in the spec (a willful violation)
          $c == 0x0020) {
        $self->{onerror}->(type => 'empty start tag',
                           level => 'm',
                           line => $line,
                           column => $column);
        $tokenizer_state = 'start tag annotation';
        ($annotation_line, $annotation_column) = ($line, $column);
        $annotation_error = 1;
        $buffer = '';
        next LOOP;
      } elsif ($c == 0x002E) { # .
        $self->{onerror}->(type => 'empty start tag',
                           level => 'm',
                           line => $line,
                           column => $column);
        $tokenizer_state = 'start tag class';
        $classes = [];
        next LOOP;
      } elsif ($c == 0x002F) { # /
        $tokenizer_state = 'end tag';
        $result = '';
        next LOOP;
      } elsif (0x0030 <= $c and $c <= 0x0039) { # 0..9
        $result = $s[$position];
        $tokenizer_state = 'timestamp tag';
        next LOOP;
      } elsif ($c == 0x003E) { # >
        push @$tokens, {type => 'start tag', tag_name => '',
                        classes => [],
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column + 1);
        $tokenizer_state = 'data';
        next;
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'bare stago',
                           level => 'm',
                           line => $start_line,
                           column => $start_column);
        push @$tokens, {type => 'start tag', tag_name => '',
                        classes => [],
                        line => $start_line, column => $start_column};
        last;
      } else {
        $result = $s[$position];
        $tokenizer_state = 'start tag';
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'start tag') {
      if ($c == 0x0009 or
          $c == 0x000C or
          $c == 0x0020) {
        if ($c == 0x000C) {
          $self->{onerror}->(type => 'form feed',
                             level => 'm',
                             line => $line, column => $column);
          $annotation_error = 1;
        } else {
          $annotation_error = 0;
        }
        $tokenizer_state = 'start tag annotation';
        ($annotation_line, $annotation_column) = ($line, $column);
        $buffer = '';
        next LOOP;
      } elsif ($c == 0x000A or
               $c == 0x000D) { ## Not in the spec (a willful violation)
        $self->{onerror}->(type => 'newline not allowed',
                           level => 'm',
                           line => $line, column => $column);
        $buffer = $s[$position];
        $tokenizer_state = 'start tag annotation';
        ($annotation_line, $annotation_column) = ($line, $column);
        $annotation_error = 1;
        next LOOP;
      } elsif ($c == 0x002E) {
        $tokenizer_state = 'start tag class';
        $classes = [];
        next LOOP;
      } elsif ($c == 0x003E) { # >
        push @$tokens, {type => 'start tag', tag_name => $result,
                        classes => [],
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column + 1);
        $result = '';
        $tokenizer_state = 'data';
        next;
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'unclosed tag',
                           level => 'm',
                           line => $line, column => $column);
        push @$tokens, {type => 'start tag', tag_name => $result,
                        classes => [],
                        line => $start_line, column => $start_column};
        last;
      } else {
        $result .= $s[$position];
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'start tag class') {
      if ($c == 0x0009 or
          $c == 0x000C or ## Spec syntax is wrong (parsing rule is correct)
          $c == 0x0020) {
        if ($buffer eq '') {
          $self->{onerror}->(type => 'empty class',
                             level => 'm',
                             line => $line, column => $column);
          $annotation_error = 1;
        } elsif ($c == 0x000C) {
          $self->{onerror}->(type => 'form feed',
                             level => 'm',
                             line => $line, column => $column);
          $annotation_error = 1;
        } else {
          $annotation_error = 0;
        }
        push @$classes, $buffer;
        $buffer = '';
        $tokenizer_state = 'start tag annotation';
        ($annotation_line, $annotation_column) = ($line, $column);
        next LOOP;
      } elsif ($c == 0x000A or
               $c == 0x000D) { # Not in the spec (a willful violation)
        if ($buffer eq '') {
          $self->{onerror}->(type => 'empty class',
                             level => 'm',
                             line => $line, column => $column);
        } else {
          $self->{onerror}->(type => 'newline not allowed',
                             level => 'm',
                             line => $line, column => $column);
        }
        push @$classes, $buffer;
        $buffer = $s[$position];
        $tokenizer_state = 'start tag annotation';
        ($annotation_line, $annotation_column) = ($line, $column);
        $annotation_error = 1;
        next LOOP;
      } elsif ($c == 0x002E) { # .
        if ($buffer eq '') {
          $self->{onerror}->(type => 'empty class',
                             level => 'm',
                             line => $line, column => $column);
        }
        push @$classes, $buffer;
        $buffer = '';
        next LOOP;
      } elsif ($c == 0x003E) { # >
        if ($buffer eq '') {
          $self->{onerror}->(type => 'empty class',
                             level => 'm',
                             line => $line, column => $column);
        }
        push @$classes, $buffer;
        push @$tokens, {type => 'start tag', tag_name => $result,
                        classes => $classes,
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column + 1);
        $result = '';
        $tokenizer_state = 'data';
        next;
      } elsif ($c == -1) { # EOF
        if ($buffer eq '') {
          $self->{onerror}->(type => 'empty class',
                             level => 'm',
                             line => $line, column => $column);
        }
        $self->{onerror}->(type => 'unclosed tag',
                           level => 'm',
                           line => $line, column => $column);
        push @$classes, $buffer;
        push @$tokens, {type => 'start tag', tag_name => $result,
                        classes => $classes,
                        line => $start_line, column => $start_column};
        last;
      } else {
        $buffer .= $s[$position];
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'start tag annotation') {
      if ($c == 0x003E) { # >
        $buffer = $self->parse_annotation
            ($buffer,
             line => $annotation_line, column => $annotation_column + 1,
             has_error => $annotation_error);
        push @$tokens, {type => 'start tag', tag_name => $result,
                        classes => $classes, annotation => $buffer,
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column + 1);
        $result = '';
        $tokenizer_state = 'data';
        next LOOP;
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'unclosed tag',
                           level => 'm',
                           line => $line, column => $column);
        $buffer = $self->parse_annotation
            ($buffer,
             line => $annotation_line, column => $annotation_column + 1,
             has_error => $annotation_error);
        push @$tokens, {type => 'start tag', tag_name => $result,
                        classes => $classes, annotation => $buffer,
                        line => $start_line, column => $start_column};
        last;
      } else {
        $buffer .= $s[$position];
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'end tag') {
      if ($c == 0x003E) { # >
        push @$tokens, {type => 'end tag', tag_name => $result,
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column + 1);
        $result = '';
        $tokenizer_state = 'data';
        next;
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'unclosed tag',
                           level => 'm',
                           line => $line, column => $column);
        push @$tokens, {type => 'end tag', tag_name => $result,
                        line => $start_line, column => $start_column};
        next;
      } else {
        $result .= $s[$position];
        next LOOP;
      }
    } elsif ($tokenizer_state eq 'timestamp tag') {
      if ($c == 0x003E) { # >
        push @$tokens, {type => 'timestamp tag', tag_name => $result,
                        line => $start_line, column => $start_column};
        ($start_line, $start_column) = ($line, $column + 1);
        $result = '';
        $tokenizer_state = 'data';
        next;
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'unclosed tag',
                           level => 'm',
                           line => $line, column => $column);
        push @$tokens, {type => 'timestamp tag', tag_name => $result,
                        line => $start_line, column => $start_column};
        last;
      } else {
        $result .= $s[$position];
        next LOOP;
      }
    } else {
      die "Unknown tokenizer state: |$tokenizer_state|";
    }
  } continue {
    if (($position <= $#s and $s[$position] eq "\x0A") or
        ($position + 1 <= $#s and $s[$position] eq "\x0D" and
         $s[$position + 1] ne "\x0A") or
        ($position == $#s and $s[$position] eq "\x0D")) {
      $line++;
      $column = 1;
    } else {
      $column++;
    }
  } # LOOP

  push @$tokens, {type => 'eof', line => $line, column => $column};

  return $tokens;
} # tokenize_text

sub parse_annotation ($$;%) {
  my $self = shift;
  my @s = split //, shift;
  my %args = @_;

  my $line = $args{line} || 1;
  my $column = $args{column} || 1;

  ## Replace white space characters.
  ## Replace character references (not in the spec).

  my $state = $args{has_error} ? 'before word error'
                               : 'before word';

  my @word;
  my $buffer;
  for my $i (0..@s) {
    my $c = $i <= $#s ? ord $s[$i] : -1;
    
    if ($state eq 'before word') {
      if ($c == 0x0009 or
          $c == 0x0020) {
        #
      } elsif ($c == 0x000A or
               $c == 0x000D) {
        $self->{onerror}->(type => 'newline not allowed',
                           level => 'm',
                           line => $line, column => $column);
        $state = 'before word error';
      } elsif ($c == 0x000C) {
        $self->{onerror}->(type => 'form feed',
                           level => 'm',
                           line => $line, column => $column);
        $state = 'before word error';
      } elsif ($c == 0x0026) { # &
        push @word, '';
        $buffer = '&';
        $state = 'escape';
      } elsif ($c == -1) {
        #
      } else {
        push @word, $s[$i];
        $state = 'word';
      }
    } elsif ($state eq 'before word error') {
      if ($c == 0x0009 or
          $c == 0x000A or
          $c == 0x000C or
          $c == 0x000D or
          $c == 0x0020 or
          $c == -1) {
        #
      } elsif ($c == 0x0026) { # &
        push @word, '';
        $buffer = '&';
        $state = 'escape';
      } else {
        push @word, $s[$i];
        $state = 'word';
      }
    } elsif ($state eq 'word') {
      if ($c == 0x0009 or $c == 0x0020) {
        $state = 'before word';
      } elsif ($c == 0x000A or
               $c == 0x000D) {
        $self->{onerror}->(type => 'newline not allowed',
                           level => 'm',
                           line => $line, column => $column);
        $state = 'before word error';
      } elsif ($c == 0x000C) {
        $self->{onerror}->(type => 'form feed',
                           level => 'm',
                           line => $line, column => $column);
        $state = 'before word error';
      } elsif ($c == 0x0026) {
        $buffer = '&';
        $state = 'escape';
      } elsif ($c == -1) {
        #
      } else {
        $word[-1] .= $s[$i];
      }
    } elsif ($state eq 'escape') {
      if ($c == 0x26) { # &
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $word[-1] .= $buffer;
        $buffer = '&';
      } elsif ((0x30 <= $c and $c <= 0x39) or # 0-9
               (0x41 <= $c and $c <= 0x5A) or # A-Z
               (0x61 <= $c and $c <= 0x7A)) { # a-z
        $buffer .= $s[$i];
      } elsif ($c == 0x3B) { # ;
        $word[-1] .= {
          '&amp' => '&',
          '&lt' => '<',
          '&gt' => '>',
          '&lrm' => "\x{200E}",
          '&rlm' => "\x{200F}",
          '&nbsp' => "\xA0",
        }->{$buffer} || do {
          $self->{onerror}->(type => 'entity not declared',
                             level => 'm',
                             line => $line,
                             column => $column - length $buffer);
          $buffer . ';';
        };
        $state = 'word';
      } elsif ($c == -1) { # EOF
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $word[-1] .= $buffer;
      } else {
        $self->{onerror}->(type => 'bare ero',
                           level => 'm',
                           line => $line,
                           column => $column - length $buffer);
        $word[-1] .= $buffer . $s[$i];
        $state = 'word';
      }
    } else {
      die "Unknown state: |$state|";
    }
  } continue {
    if (($i <= $#s and $s[$i] eq "\x0A") or
        ($i + 1 <= $#s and $s[$i] eq "\x0D" and
         $s[$i + 1] ne "\x0A") or
        ($i == $#s and $s[$i] eq "\x0D")) {
      $line++;
      $column = 1;
    } else {
      $column++;
    }
  }

  return join ' ', @word;
} # parse_annotation

sub construct_dom_from_tokens ($$$) {
  my ($self, $tokens => $doc) = @_;

  my $result = $doc->create_document_fragment;
  my $current = $result;

  LOOP: while (@$tokens) {
    my $token = shift @$tokens;
    if ($token->{type} eq 'string') {
      my $text = $current->append_child
          ($doc->create_text_node ($token->{value}));
      $text->set_user_data (manakai_source_line => $token->{line});
      $text->set_user_data (manakai_source_column => $token->{column});
    } elsif ($token->{type} eq 'start tag') {
      if ($token->{tag_name} eq 'c') {
        $current = $current->append_child
            ($doc->create_element_ns (HTML_NS, [undef, 'span']));
        my @class = grep { length } @{$token->{classes}};
        $current->class_name (join ' ', @class) if @class;
        if (defined $token->{annotation}) {
          $self->{onerror}->(type => 'webvtt:annotation not allowed',
                             level => 'm',
                             text => $token->{tag_name},
                             line => $token->{line},
                             column => $token->{column});
        }
        $current->set_user_data
            (manakai_source_line => $token->{line});
        $current->set_user_data
            (manakai_source_column => $token->{column});
      } elsif ($token->{tag_name} eq 'i' or
               $token->{tag_name} eq 'b' or
               $token->{tag_name} eq 'u' or
               $token->{tag_name} eq 'ruby') {
        $current = $current->append_child
            ($doc->create_element_ns
                 (HTML_NS, [undef, $token->{tag_name}]));
        my @class = grep { length } @{$token->{classes}};
        $current->class_name (join ' ', @class) if @class;
        if (defined $token->{annotation}) {
          $self->{onerror}->(type => 'webvtt:annotation not allowed',
                             level => 'm',
                             text => $token->{tag_name},
                             line => $token->{line},
                             column => $token->{column});
        }
        $current->set_user_data
            (manakai_source_line => $token->{line});
        $current->set_user_data
            (manakai_source_column => $token->{column});
      } elsif ($token->{tag_name} eq 'rt') {
        if ($current->node_type == $current->ELEMENT_NODE and 
            $current->manakai_local_name eq 'ruby') {
          $current = $current->append_child
              ($doc->create_element_ns
                   (HTML_NS, [undef, $token->{tag_name}]));
          my @class = grep { length } @{$token->{classes}};
          $current->class_name (join ' ', @class) if @class;
          if (defined $token->{annotation}) {
            $self->{onerror}->(type => 'webvtt:annotation not allowed',
                               level => 'm',
                               text => $token->{tag_name},
                               line => $token->{line},
                               column => $token->{column});
          }
          $current->set_user_data
              (manakai_source_line => $token->{line});
          $current->set_user_data
              (manakai_source_column => $token->{column});
        } else {
          $self->{onerror}->(type => 'start tag not allowed',
                             text => $token->{tag_name},
                             level => 'm',
                             line => $token->{line},
                             column => $token->{column});
        }
      } elsif ($token->{tag_name} eq 'v') {
        $current = $current->append_child
            ($doc->create_element_ns (HTML_NS, [undef, 'span']));
        my @class = grep { length } @{$token->{classes}};
        $current->class_name (join ' ', @class) if @class;
        ## Also reported by Checker
        #unless (defined $token->{annotation}) {
        #  $self->{onerror}->(type => 'webvtt:no annotation',
        #                     text => 'v',
        #                     level => 'm',
        #                     line => $token->{line},
        #                     column => $token->{column});
        #}
        $current->title
            (defined $token->{annotation} ? $token->{annotation} : '');
        $current->set_user_data
            (manakai_source_line => $token->{line});
        $current->set_user_data
            (manakai_source_column => $token->{column});
      } else {
        $self->{onerror}->(type => 'start tag not allowed',
                           text => $token->{tag_name},
                           level => 'm',
                           line => $token->{line},
                           column => $token->{column});
      }
    } elsif ($token->{type} eq 'end tag') {
      my $current_tag_name = $current->manakai_local_name || '';
      if (not length $token->{tag_name}) {
        $self->{onerror}->(type => 'empty end tag',
                           level => 'm',
                           line => $token->{line},
                           column => $token->{column});
      } elsif ($token->{tag_name} eq 'c' and
               $current_tag_name eq 'span' and
               not defined $current->get_attribute ('title')) {
        $current = $current->parent_node;
      } elsif ($token->{tag_name} eq 'v' and
               $current_tag_name eq 'span' and
               defined $current->get_attribute ('title')) {
        $current = $current->parent_node;
      } elsif ($token->{tag_name} eq 'span') {
        $self->{onerror}->(type => 'unmatched end tag',
                           text => $token->{tag_name},
                           level => 'm',
                           line => $token->{line},
                           column => $token->{column});
      } elsif (defined $current_tag_name and
               $token->{tag_name} eq $current_tag_name) {
        $current = $current->parent_node;
      } elsif ($token->{tag_name} eq 'ruby' and
               $current_tag_name eq 'rt') {
        $current = $current->parent_node->parent_node;
      } else {
        $self->{onerror}->(type => 'unmatched end tag',
                           text => $token->{tag_name},
                           level => 'm',
                           line => $token->{line},
                           column => $token->{column});
      }
    } elsif ($token->{type} eq 'timestamp tag') {
      my $input = $token->{tag_name};
      if ($input =~ /\A([0-9]+):([0-9]{2})(?::([0-9]{2}))?\.([0-9]{3})\z/) {
        my ($h, $m, $s, $f) = ($1, $2, $3, $4);
        if (not defined $s) {
          if (2 == length $h and $h < 60) {
            ($h, $m, $s) = (0, $h, $m);
          } else {
            $self->{onerror}->(type => 'webvtt:bad timestamp',
                               level => 'm',
                               line => $token->{line},
                               column => $token->{column});
            next;
          }
        }
        if ($m > 59 or $s > 59) {
          $self->{onerror}->(type => 'webvtt:bad timestamp',
                             level => 'm',
                             line => $token->{line},
                             column => $token->{column});
          next;
        }
        my $pi = $doc->create_processing_instruction
            ('timestamp',
             sprintf '%02d:%02d:%02d.%03d', 0+$h, $m, $s, $f);
        $current->append_child ($pi);
        $pi->set_user_data
            (manakai_source_line => $token->{line});
        $pi->set_user_data
            (manakai_source_column => $token->{column});
      } else {
        $self->{onerror}->(type => 'webvtt:bad timestamp',
                           level => 'm',
                           line => $token->{line},
                           column => $token->{column});
      }
    } elsif ($token->{type} eq 'eof') {
      if ($current->node_type == $current->ELEMENT_NODE) {
        my $ln = $current->manakai_local_name;
        if ($ln eq 'span' and $current->has_attribute ('title')) { # <v>
          #
        } elsif ($ln eq 'span') { # <c>
          $self->{onerror}->(type => 'not closed',
                             text => 'c',
                             level => 'm',
                             line => $token->{line},
                             column => $token->{column});
        } elsif ($ln eq 'rt') {
          $self->{onerror}->(type => 'not closed',
                             text => 'ruby',
                             level => 'm',
                             line => $token->{line},
                             column => $token->{column});
        } else {
          $self->{onerror}->(type => 'not closed',
                             text => $current->manakai_local_name,
                             level => 'm',
                             line => $token->{line},
                             column => $token->{column});
        }
      }
    } else {
      die "Unknown token type: |$token->{state}|";
    }
  } # LOOP
  
  return $result;
} # construct_dom_from_tokens

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
