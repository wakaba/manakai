
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
our $VERSION = do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Error;
our @ISA = 'Error';

sub import {
  shift;
  local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
  if (@_) {
    Error::subs->import(@_);
  } else {
    Error::subs->import (':try');
  }
}

sub ___errors ($) {{
 UNKNOWN => {
             description => '"%name;": Unknown error',
             level       => 'fatal',
            },
}}

sub ___get_error_def ($$) {
  my ($self, $name) = @_;
  return $self->___errors->{$name}
    or 
  $self->SUPER::can ('___get_error_def') ?
    return $self->SUPER::___get_error_def ($name)
      :
    return undef
  ;
}

sub new ($;%) {
  local $Error::Depth = $Error::Depth + 1;
  my $class = shift;
  my %opt = @_;
  $opt{def} = $class->___get_error_def ($opt{type})
           || $class->___get_error_def ('UNKNOWN')
           or die qq(Error definition for "$opt{type}" not found);
  $class->SUPER::new (%opt);
}

sub text {
  my $self = shift;
  $self->_FORMATTER_PACKAGE_->new
       ->replace ($self->{def}->{description}, param => $self);
}

sub stringify {
  my $self = shift;
  my $text = $self->text;
  $text .= sprintf " at %s line %d.\n", $self->file, $self->line
    unless $text =~ /\n$/s;
  $text;
}

sub _FORMATTER_PACKAGE_ () { 'Message::Util::Error::formatter' }

package Message::Util::Error::formatter;
use Message::Util::Formatter::Text;
our @ISA = q(Message::Util::Formatter::Text);
sub rule_def () {+{
  name => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{-result} = $o->{type};
    },
  },
  t => {
    after => sub {
      my ($f, $name, $p, $o) = @_;
      $p->{name} =~ tr/-/_/;
      $p->{-result} = $o->{'-' . $p->{name}};
    },
  },
}}

=head1 EXAMPLE

  require Message::Util::Error;
  my $err = new Message::Util::Error ({
    OPEN_DB => {
      level => 'fatal',
      description => q(%s: Can't open database (%s)),
    },
    CLOSE_DB => {
      level => 'warn',
      description => q(%s: Can't close database (%s)),
    },
    UNKNOWN => {
      level => 'fatal',
      description => 'Unknown error happend',
    },
    -error_handler => sub {
      my ($self, $err_def, $err_msg, $err_argv) = @_;
      if ($err_def->{level} eq 'fatal') {
        die $err_msg;
      } else {
        warn $err_msg;
      }
    },
  );
    
  open DB, $db_name or $err->raise (type => 'OPEN_DB', t => [$db_name, $!]);

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/11/16 11:44:44 $
