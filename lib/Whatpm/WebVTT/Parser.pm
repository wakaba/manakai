package Whatpm::WebVTT::Parser;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '1.0';

sub new ($) {
  my $self = bless {
    onerror => sub {
      my %args = @_;
      warn sprintf "%s: %s at Line %d Column %d\n",
          $args{level},
          $args{type}
              . (defined $args{text} ? $args{text} : '')
              . (defined $args{value} ? $args{value} : ''),
          $args{line}, $args{column};
    }, # onerror
  }, $_[0];
  return $self;
} # new

sub init ($) {
  my $self = shift;
  
  $self->{state} = 'signature';
  $self->{l} = 0;
  $self->{c} = 0;
  
  require Message::DOM::TextTrack;
  require Message::DOM::TextTrackCue;
  require Message::DOM::TextTrackCueList;
  $self->{parsed} = Message::DOM::TextTrack->____new_from_hashref
      ({
          kind => 'subtitles', ## Default for <track kind>
          mode => 'hidden', ## Random default
          all_cues => Message::DOM::TextTrackCueList
              ->____new_from_arrayref ([]),
       });
} # init

sub parse_char_string ($;$) {
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
  
  $self->feed_eof;

  return $self->{parsed};
} # parse_char_string

sub feed_line ($$$) {
  my ($self, $line, $eol) = @_;
  $self->{l}++;

  STATE: {
    if ($self->{state} eq 'signature') {
      if ($line =~ /\A\x{FEFF}?WEBVTT(?:[\x20\x09]([^\x0D\x0A]*))?\z/) {
        $self->{parsed}->{signature_trailer} = $1;
        $self->{parsed}->{signature_trailer} =~ tr/\x00/\x{FFFD}/
            if defined $self->{parsed}->{signature_trailer};
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
        };
        if ($line =~ /-->/) {
          $self->{state} = 'timings';
          redo STATE;
        } else {
          if (defined $eol) {
            $self->{new_cue}->{id} = $line;
            $self->{state} = 'before timings';
          } else {
            $self->{onerror}->(type => 'webvtt:no timings',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + length $line);
            push @{$self->{parsed}->{invalid_cues} ||= []}, $line;
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
        push @{$self->{parsed}->{invalid_cues} ||= []},
            join "\x0A",
                @{$self->{new_cue}->{invalid_ids} ||= []},
                $self->{new_cue}->{id},
                length $line ? $line : ();
        $self->{state} = defined $eol ? 'before cue' : 'end';
      } else {
        if ($line =~ /-->/) {
          $self->{state} = 'timings';
          redo STATE;
        } else {
          $self->{onerror}->(type => 'webvtt:id:duplicate',
                             level => 'm',
                             line => $self->{l} - 1, column => 1);
          push @{$self->{new_cue}->{invalid_ids} ||= []},
              $self->{new_cue}->{id};
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
            $self->{onerror}->(type => 'webvtt:ff',
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
            $self->{state} = 'cue text';
          } else {
            $self->{onerror}->(type => 'webvtt:no text',
                               level => 'm',
                               line => $self->{l},
                               column => 1 + length $_[1]);
            push @{$self->{parsed}->{all_cues}},
                Message::DOM::TextTrackCue->____new_from_hashref
                    ($self->{new_cue});
            $self->{state} = 'end';
          }
          last STATE;
        } else {
          $self->{onerror}->(type => 'webvtt:bad timings',
                             level => 'm',
                             line => $self->{l}, column => 1);
        }
      }

      push @{$self->{parsed}->{invalid_cues} ||= []}, $_[1];
      if ($self->{new_cue} and length $self->{new_cue}->{id}) {
        $self->{parsed}->{invalid_cues}->[-1]
            = $self->{new_cue}->{id} . "\x0A" . $_[1];
      }
      $self->{state} = 'bad cue';
    } elsif ($self->{state} eq 'cue text') {
      if (not $line eq '' and not $line =~ /-->/) {
        $self->{new_cue}->{text} .= "\x0A"
            if length $self->{new_cue}->{text};
        $self->{new_cue}->{text} .= $line;
      }

      if ($line =~ /-->/ or $line eq '' or not defined $eol) {
        $self->{new_cue}->{text} =~ tr/\x00/\x{FFFD}/;
        push @{$self->{parsed}->{all_cues}},
            Message::DOM::TextTrackCue->____new_from_hashref
                ($self->{new_cue});
        $self->{state} = defined $eol ? 'before cue' : 'end';
        redo STATE if defined $eol;
      }
    } elsif ($self->{state} eq 'bad cue') {
      if (not defined $eol) {
        $self->{parsed}->{invalid_cues}->[-1] .= "\x0A" . $line
            if length $line;
        $self->{state} = 'end';
      } elsif ($line =~ /-->/ or $line eq '') {
        $self->{state} = 'before cue';
        redo STATE;
      } else {
        $self->{parsed}->{invalid_cues}->[-1] .= "\x0A" . $line;
      }
    } elsif ($self->{state} eq 'end') {
      #
    } else {
      die "Unknown state: |$self->{state}|";
    }
  }
} # feed_line

sub feed_eof ($) {
  my $self = shift;
return;

  if ($self->{state} eq 'end') {
    #
  } elsif ($self->{state} eq 'cue text') {
    $self->feed_line ('', undef);
  } elsif ($self->{state} eq 'signature') {
    #
  } elsif ($self->{state} eq 'header') {
    #
  } elsif ($self->{state} eq 'bad cue') {
    #
  } elsif ($self->{state} eq 'before cue') {
    # never
  } elsif ($self->{state} eq 'before timings') {
    # never
  } elsif ($self->{state} eq 'timings') {
    # never
  } else {
    die "Unknown state: |$self->{state}|";
  }
} # feed_eof

sub parse_settings ($$$) {
  my $self = $_[0];
  my $cue = $_[2];

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
                       value => $value,
                       line => $self->{l},
                       column => $self->{c} + 2 + length $name);
  } continue {
    $self->{c} += length $setting;
  }
} # parse_settings

1;
