
=head1 NAME

Message::Util::Error --- manakai: Common error handler wrapper

=head1 DESCRIPTION

This module provides common error handler (error reporting wrapper
module).  With this module, flexible error reporting method
can be easily implemented.

This module is part of manakai.

=cut

package Message::Util::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.10 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Error;
push our @ISA, 'Error';

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
             description => '"%name;": Unknown error',
             level       => 'fatal',
            },
}}

sub ___get_error_def ($$) {
  my ($self, $name) = @_;
  my $err;
  $err = $self->___error_def->{$name} if $self->can ('___error_def');
  return $err if $err;
  no strict 'refs';
  for my $SUPER (@{(ref ($self) || $self).'::ISA'}) {
    if ($SUPER->can ('___get_error_def')) {
      return $SUPER->___get_error_def ($name);
    }
  }
  return undef;
}

sub new ($;%) {
  my $class = shift;
  my %opt = @_;
  $opt{-def} = $class->___get_error_def ($opt{-type})
            || $class->___get_error_def ('UNKNOWN')
            or die qq(Error definition for "$opt{-type}" not found);
#  local $Error::Depth = $Error::Depth + 1;
  $class->SUPER::new (%opt);
}

sub text {
  my $self = shift;
  $self->_FORMATTER_PACKAGE_->new
       ->replace ($self->{-def}->{description}, param => $self);
}

sub stringify {
  my $self = shift;
  my $text = $self->text;
  $text .= sprintf " at %s line %d.\n", $self->file, $self->line
    unless $text =~ /\n$/s;
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

=head1 ERROR MESSAGE CONSTRUCTING

Human readable error message text, returned by C<text> method,
is generated from C<description> parameter of error definition.

Format defined by L<Message::Util::Formatter> is used to specify
C<description> parameter and it is processed by the formatter.

=over 4

=item sub ERROR_SUBCLASS::_FORMATTER_PACKAGE_ { return $class_name }

Subclass can define C<_FORMATTER_PACKAGE_> method
to define class name of the formatter.  Defaulted to
C<Message::Util::Error::formatter>.

Unless you wish to use additional rules in template text 
(C<description> parameter), you don't need to define this
method in your subclass.

Class returned by this method MUST be a subclass (descender class) of
C<Message::Util::Formatter::Base>.

=cut

sub _FORMATTER_PACKAGE_ () { 'Message::Util::Error::formatter' }

=back

=head2 Formatter Message::Util::Error::formatter

In addition to rules defined in C<Message::Util::Formatter::Text>,
formatter C<Message::Util::Error::formatter> defines some rules:

=over 4

=item %name;

Error type name (C<-type> parameter specified when error is thrown)

=item %t (name => parameter-name);

Parameter value specified when error is thrown

=back

=cut

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

=head1 EXAMPLE

To make a new error class:

  package SomeExceptionClass;
  use Message::Util::Error;
  push our @ISA, 'Message::Util::Error';
  
  ## [REQUIRED] Error types
  sub ___error_def {
    ## Returns a reference to hash defining error type
    return {
      ERROR_NAME => {
        description => q(%name;: %t (name => what); is bad),
        level => 'fatal',
        ...
      },
      WARNING_NAME => {
        description => q(%name;: %t (name => what); might be bad),
        level => 'warn',
        ...
      },
      ...
    };
  }
  
  ## [OPTIONAL] Package name of formatter constructing error message
  ##            (Default: Message::Util::Error::formatter)
  sub _FORMATTER_PACKAGE_ () { 'SomeFormatterClass' }

Throwing exception:

  use SomeExceptionClass;
  ...
  do something;
  ...
  throw SomeExceptionClass -type => 'ERROR_NAME',
                           what => 'Example';

If you implements an object-oriented class:

  package SomeModule;
  use SomeExceptionClass;
  
  sub some_method {
    my $self = shift;
    ...
    report SomeExceptionClass
      -type => 'ERROR_NAME',
      what => 'Non-oo programing',
      -object => $self, method => 'some_method'
        unless $oo;
    ...
    report SomeExceptionClass
      -type => 'WARNING_NAME',
      what => 'This module',
      -object => $self, method => 'some_method';
    ...
  }
  
  ## If you use "report", you must implements this internal method
  sub ___report_error ($$;%) {
    my ($self, $err, %option) = @_;
    ## Throwing if fatal
    if ($err->{def}->{level} eq 'fatal') {
      $err->throw;
      print "This text never printed";
    ## Otherwise warning only
    } else {
      warn $err->stringify;
      print "This text IS printed";
    }
  }

=head1 LICENSE

Copyright 2003-2005 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/01/05 12:19:39 $
