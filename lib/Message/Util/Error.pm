package Message::Util::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.13 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Error;
push our @ISA, 'Error';
our $DEBUG;
our $VERBOSE;

sub import {
  shift;
  local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
  if (@_) {
    Error::subs->import(@_);
  } else {
    Error::subs->import (':try');
  }
}

sub ___error_def () {+{
 UNKNOWN => {
             -code => 0,
             -description => '"%name;": Unknown error',
            },
}}

sub ___get_error_def ($$) {
  my ($self, $name) = @_;
  my $err;
  warn ((ref $self or $self)."->___get_error_def ('$name')\n") if $DEBUG;
  $err = $self->___error_def->{$name} if $self->can ('___error_def');
  return $err if $err;
  no strict 'refs';
  for my $SUPER (@{(ref ($self) || $self).'::ISA'}) {
    if ($SUPER->can ('___get_error_def')) {
      $err = $SUPER->___get_error_def ($name);
      return $err if $err;
    }
  }
  return undef;
}

sub new ($;%) {
  my $class = shift;
  my %opt = @_;
  die qq(Error type is not specified) unless defined $opt{-type};
  $opt{-def} = $class->___get_error_def ($opt{-type})
            || $class->___get_error_def ('UNKNOWN')
            or die qq(Error definition for "$opt{-type}" not found);
#  local $Error::Depth = $Error::Depth + 1;
  my $err = $class->SUPER::new (%opt);
  if ($Error::Debug or $DEBUG) {
    require Carp;
    #local $Carp::CarpLevel = $Error::Depth;
    local $Carp::CarpLevel = 1;
    $err->{-stacktrace_} = Carp::longmess ();
  } elsif ($VERBOSE) {
    require Carp;
    local $Carp::CarpLevel = $Error::Depth - 1;
    $err->{-stacktrace_} = Carp::longmess ();
  }
  return $err;
}

sub text {
  my $self = shift;
  my $template;
  if (defined $self->{-subtype}) {
    my $subtype_def = $self->{-def}->{-subtype}->{$self->{-subtype}};
    if (defined $subtype_def) {
      $template = $subtype_def->{-description};
    }
  }
  unless (defined $template) {
    $template = $self->{-def}->{-description};
  }
  unless (defined $template) {
    return $self->SUPER::text;
  }
  return $self->_FORMATTER_PACKAGE_->new->replace ($template, param => $self);
} # text

sub value ($) {
  my $self = shift;
  if (defined $self->{-def}->{-code}) {
    return $self->{-def}->{-code};
  } else {
    return $self->SUPER::value;
  }
} # value

sub code ($) {
  return shift->{-def}->{-code} || 0;
} # code

sub type ($) {
  return shift->{-type};
} # type

sub subtype ($) {
  return shift->{-subtype};
} # subtype

sub type_def ($) {
  return shift->{-def};
} # type_def

sub stringify {
  my $self = shift;
  my $text = $self->text;
  unless ($text =~ /\n$/s) {
    if ($Error::Debug or $DEBUG or $VERBOSE) {
      $text = defined $self->{-stacktrace_} ? $text . $self->{-stacktrace_}
                                            : Carp::longmess ($text);
    } else {
      $text .= sprintf " at %s line %d.\n", $self->file, $self->line;
    }
  }
  $text;
}

sub report ($;%) {
  my ($self, %opt) = @_;
  if (ref $opt{-object}) {
    local $Error::Depth = $Error::Depth + 3;
      # => obj->{method}
      # => mue->report
      # => err->new
    my $err;
    {
      local $@;
      $err = $self->new (%opt);
    }
    $opt{-object}->___report_error ($err);
  } else {
    local $Error::Depth = $Error::Depth + 2;
      # => {-object}->{method}
      # (=> ->report)
    throw $self %opt;
  }
}

sub throw ($@) {
  my $self = shift;
  local $Error::Depth = $Error::Depth + 2;
  $self->SUPER::throw (@_);
}

## Disables since Error::associate makes looping reference
sub associate {}

sub _FORMATTER_PACKAGE_ () { 'Message::Util::Error::formatter' }

package Message::Util::Error::formatter;
use Message::Util::Formatter::Text;
push our @ISA, q(Message::Util::Formatter::Text);
sub ___rule_def () {+{
  name => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} = $o->{-type};
    },
  },
  ## "t" is obsolete; use "p"
  t => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{name} =~ tr/-/_/;
      my $val = $o->{$p->{name}};
      if (defined $val) {
        if (length $val) {
          $p->{-result} = $val;
        } else {
          $p->{-result} = defined $p->{empty} ? $p->{empty} : '<empty>';
        }
      } else {
        $p->{-result} = defined $p->{undef} ? $p->{undef} : '<undef>';
      }
    },
  },
  p => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      my $val = $o->{$p->{name}};
      if (defined $val) {
        if (length $val) {
          $p->{-result} = $val;
        } else {
          $p->{-result} = defined $p->{empty} ? $p->{empty} : '<empty>';
        }
      } elsif (exists $o->{$p->{name}}) {
        $p->{-result} = defined $p->{undef} ? $p->{undef} : '<undef>';
      }
    },
  },
}}

=head1 LICENSE

Copyright 2003-2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2007/06/16 05:30:37 $
