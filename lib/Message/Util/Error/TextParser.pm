
=head1 NAME

Message::Util::Error::TextParser --- manakai: Common error handler wrapper for formatted-text parser

=head1 DESCRIPTION

This module provides common error handler (error reporting wrapper
module) for formatted-text parser.  With this module, flexible error 
reporting method can be easily implemented.  In addition to the base
module of Message::Util::Error, this module implements line/position
counting method so that error occured position in the parsed plain-text
based data can be reported.

This module is part of manakai.

=cut

package Message::Util::Error::TextParser;
require Message::Util::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.3.2.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub new ($;%) {
  my $self = bless {}, shift;
  $self->{option} = {@_, newline => qr/\x0A|\x0D\x0A?/};
  $self;
}

sub set_position ($$;%) {
  no warnings 'uninitialized';
  my ($self, $s, %opt) = @_;
  return if $self->{__set_position} and not $opt{moved};
  my $pos = $self->{pos}->{$s} ||= {};
  my $length = pos ($$s) - $pos->{pos};
  if ($opt{diff}) {
    $length < $opt{diff} ?
      $length  = 0:
      $length -= $opt{diff};
  }
  my $t = substr ($$s, $pos->{pos}, $length > 0 ? $length : 0);
  ++$pos->{line} and $pos->{char} = 0 
    while $t =~ /^.+?$self->{option}->{newline}/os;
  $pos->{char} += length $t;
  $pos->{pos} += $length;
  $self->{__set_position} = 1;
}

sub get_position ($$;%) {
  no warnings 'uninitialized';
  my ($self, $s, %opt) = @_;
  (0 + $self->{pos}->{$s}->{line}, 0 + $self->{pos}->{$s}->{char});
}

sub reset_position ($$;%) {
  my ($self, $s, %opt) = @_;
  $self->{pos}->{$s} = {
    pos => pos $$s, line => 0, char => 0,
    %opt,
  };
}

sub fork_position ($$$;%) {
  my ($self, $s => $t, %opt) = @_;
  $self->{pos}->{$t} = {
    %{$self->{pos}->{$s}||{}},
    pos => pos $$t,
    %opt,
  };
}

sub report ($%) {
  my ($self, %opt) = @_;
  local $Error::Depth = $Error::Depth + 1;
  local $self->{__set_position} = 0;
  ($self->{option}->{package}.($opt{-class}?'::'.$opt{-class}:''))
        ->report (%opt, -object => $self);
}

sub ___report_error ($$) {
  my ($self, $err) = @_;
  local $Error::Depth = $Error::Depth + 1;
  $self->{option}->{report} ?
    $self->{option}->{report}->($err):
    $self->{option}->{package}->___report_error ($err);
}

package Message::Util::Error::TextParser::error;
push our @ISA, 'Message::Util::Error';

sub _FORMATTER_PACKAGE_ () { 'Message::Util::Error::TextParser::formatter' }

sub ___report_error ($$) {
  $_[1]->throw;
}

package Message::Util::Error::TextParser::formatter;
push our @ISA, 'Message::Util::Error::formatter';

sub ___rule_def () {+{
  err_line => {
    after => sub {
      my ($self, $name, $p, $o) = @_;
      $o->{-object}->set_position ($o->{source}, diff => $o->{position_diff});
      $p->{-result} .= 1 + ($o->{-object}->get_position ($o->{source}))[0];
    },
  },
  err_char => {
    after => sub {
      my ($self, $name, $p, $o) = @_;
      $o->{-object}->set_position ($o->{source}, diff => $o->{position_diff});
      $p->{-result} .= 1 + ($o->{-object}->get_position ($o->{source}))[1];
    },
  },
  err_at => {
    after => sub {
      my ($self, $name, $p, $o) = @_;
      my $pos = pos ${$o->{source}};
      if ($pos == length ${$o->{source}}) {
        $p->{-result} .= $p->{end_of} || '** end of string **';
        return;
      } elsif ($pos == 0) {
        $p->{-result} .= $p->{beginning_of} || '** beginning of string **';
        return;
      }
      my $before = $p->{before};
      if ($before) {
        $before = $pos if $pos < $before;
      }
      $p->{-result} .= substr (${$o->{source}}, $pos - $before, $before)
                     . ($p->{here} || ' ** here ** ')
                     . substr (${$o->{source}}, $pos, $p->{after});
    },
  },
}}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/02/24 07:29:31 $
