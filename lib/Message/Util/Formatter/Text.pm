
=head1 NAME

Message::Util::Formatter::Text --- Manakai : Plain-text formatter

=head1 DESCRIPTION

This module is an application of Message::Util::Formatter mechanism,
used to generate formatted plain text (fragment) with given formatting
rule text and formatting functions.

This module is part of manakai.

=cut

package Message::Util::Formatter::Text;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util::Formatter::Base;
our @ISA = 'Message::Util::Formatter::Base';

sub rule_def () {+{
    -bare_text => {
      after => sub {
        my ($self, $name, $p, $o, $key => $val) = @_;
        $p->{-result} .= $p->{-bare_text};
      },
    },
    -undef     => {
      post => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-result} = qq([undef: $name]);
      },             
    },
    -default   => {
      pre => sub { 
        my ($self, $name, $p, $o, %opt) = @_;
        $p->{-result} = '';
        $self->call ($name, 'before', $p, $o, %opt);
      },
      post => sub { 
        my ($self, $name, $p, $o, %opt) = @_;
        $self->call ($name, 'after', $p, $o, %opt);
        if (length $p->{-result} and 
          (defined $p->{prefix} or defined $p->{suffix})) {
          $p->{-result} = $p->{prefix} . $p->{-result} . $p->{suffix};
        }
      },
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        if ($opt{-value_flag} and index ($opt{-value_flag}, 'p') > -1) {
          $val = $self->replace ($val, param => $o);
        }
        $p->{$key} = $val;
      },                 
      before => sub {
      },
      after => sub {
      },
    },
    -entire    => {
      pre => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-result} = '';
      },
      attr => sub {
        my ($self, $name, $p, $o, $key => $val) = @_;
        $p->{-result} .= $val->{-result};
      },
    },
    percent => {
      after => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-result} = '%';
      },
    },
}}

sub new ($;%) {
  my ($class, %opt) = @_;
  my $rule = $opt{rule};
  $opt{rule} = sub {
    $_[0]->rule_def->{$_[1]}
      or
    __PACKAGE__->rule_def->{$_[1]}
  };
  $class->SUPER::new (%opt);
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/11/16 11:44:16 $
