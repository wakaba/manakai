
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
our $VERSION = do{my @r=(q$Revision: 1.3.2.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub new ($;%) {
  my $self = bless {}, shift;
  $self->{option} = {@_, newline => qr/\x0A|\x0D\x0A?/};
  $self;
}

sub reset ($;%) {
  my ($self, %opt) = @_;
  for (keys %$self) {
    delete $self->{$_} unless $_ eq 'option';
  }
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
  if ($length > 0) {
    my $t = substr ($$s, $pos->{pos}, $length);
    ++$pos->{line} and $pos->{char} = 0 
      while $t =~ s/^.*?$self->{option}->{newline}//s;
    $pos->{char} += length $t;
    $pos->{pos} += $length;
  }
  $self->{__set_position} = 1;
}

sub get_position ($$;%) {
  no warnings 'uninitialized';
  my ($self, $s, %opt) = @_;
  (0 + $self->{pos}->{$s}->{line}, 0 + $self->{pos}->{$s}->{char});
}

sub reset_position ($$;%) {
  my ($self, $s, %opt) = @_;
  if ($opt{preserve_flag}) {
    $self->{pos}->{$s} = {
      %{$self->{pos}->{$s}||{}},
      pos => pos $$s, line => 0, char => 0,
      %opt,
    };
  } else {
    $self->{pos}->{$s} = {
      pos => pos $$s, line => 0, char => 0,
      %opt,
    };
  }
}

sub fork_position ($$$;%) {
  my ($self, $s => $t, %opt) = @_;
  $self->{pos}->{$t} = {
    %{$self->{pos}->{$s}||{}},
    pos => pos $$t,
    %opt,
  };
  ## ISSUE: Should references be recursively forked?
#  $self->{flag}->{$t} = {%{$self->{flag}->{$s}||{}}};
}

sub set_flag ($$$$;%) {
  my ($self, $s, $name => $value, %opt) = @_;
  unless (defined $value) {
    delete $self->{pos}->{$s}->{$name};
  } else {
    $self->{pos}->{$s}->{$name} = $value;
  }
}

=item $err->default_flag ($src, $name => $value, %option)

Set new value iif that flag has no value.

=cut

sub default_flag ($$$$;%) {
  my ($self, $s, $name => $value, %opt) = @_;
  unless (exists $self->{pos}->{$s}->{$name}) {
    $self->{pos}->{$s}->{$name} = $value;
  }
}

sub get_flag ($$$;%) {
  my ($self, $s, $name, %opt) = @_;
  $self->{pos}->{$s}->{$name};
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
      my $pos = pos ${$o->{source}} || 0;
      $o->{position_diff} ||= 0;
      $pos = $pos - $o->{position_diff} > 0 ? $pos - $o->{position_diff} : 0;
      my $before = $p->{before};
      if ($before) {
        $before = $pos if $pos < $before;
      }
      if ($pos == length ${$o->{source}}) {
        $p->{-result} .= substr (${$o->{source}}, $pos - $before, $before)
                       . ($p->{end_of} || ' ** end of string **');
        return;
      } elsif ($pos == 0) {
        $p->{-result} .= ($p->{beginning_of} || '** beginning of string ** ')
                       . substr (${$o->{source}}, $pos, $p->{after});
        return;
      }
      $p->{-result} .= substr (${$o->{source}}, $pos - $before, $before)
                     . ($p->{here} || ' ** here ** ')
                     . substr (${$o->{source}}, $pos, $p->{after});
    },
  },
}}

=head1 WARNING

This module uses stringified value of scalar reference (e.g. C<SCALAR(0xI<...>)>)
to distinglish variables each other.  This might cause difficult
situation when Perl reallocate memory area to another variable
(once after first variable is to be unreferred from anywhere).

In most case, refreshing states and flags before variable is in use
with TextParser (by C<< ->reset_position >> or C<< ->fork_position >>)
removes this possible confliction.  That is, correct use of
this module will not cause any problem.

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/07/30 05:01:03 $
