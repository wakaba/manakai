
=head1 NAME

Message::Util::Formatter::Boolean - Boolean-result "formatter"

=head1 DESCRIPTION

This module is an application of Message::Util::Formatter mechanism,
returning a boolean (true or non-undef-false or undef) value.

This module is part of manakai.

=cut

package Message::Util::Formatter::Boolean;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util::Formatter::Base;
our @ISA = 'Message::Util::Formatter::Base';

sub ___rule_def () {+{
    -bare_text => {
      post => sub {
        my ($self, $name, $p, $o, $key => $val) = @_;
        $p->{-result} = $p->{-bare_text} ? 1 : 0;
      },
    },
    -undef     => {
      post => sub {
        my ($self, $name, $p, $o, $key => $val) = @_;
        $p->{-result} = undef;
      },
    },
    -default   => {
      pre => sub { 
        my ($self, $name, $p, $o,) = @_;
        $p->{-result} = undef;
      },
      post => sub { 
      },
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        if ($key eq '-boolean') {
          $p->{$val} = 1;
        } else {
          if ($opt{-value_flag} and index ($opt{-value_flag}, 'p') > -1) {
            $val = $self->replace ($val, param => $o);
          }
          $p->{$key} = $val;
        }
      },                 
    },
    -entire    => {
      pre => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-result} = undef;
      },
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        return if $p->{-formatter}->{-has_attr} and not $p->{-result};
        $p->{-formatter}->{-has_attr} = 1;
        $p->{-result} = defined $val->{-result} ?
                          $val->{-result} ? 1 : 0 : undef;
      },
      post => sub {},
    },
    and => {
      pre => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-result} = undef;
      },
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        return if $p->{-has_attr} and not $p->{-result};
        $p->{-has_attr} = 1;
        if ($key eq '-boolean') {
          if ($opt{-name_flag} and index ($opt{-name_flag}, 'p') > -1) {
            $val = $self->replace ($val, param => $o);
          }
          $p->{-result} = defined $val ? $val ? 1 : 0 : undef;
        }
      },
      post => sub {},
    },
    or => {
      pre => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-result} = undef;
      },
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        return if $p->{-result};
        return if $p->{-has_attr} and not defined $p->{-result};
        $p->{-has_attr} = 1;
        if ($key eq '-boolean') {
          if ($opt{-name_flag} and index ($opt{-name_flag}, 'p') > -1) {
            $val = $self->replace ($val, param => $o);
          }
          $p->{-result} = defined $val ? $val ? 1 : 0 : undef;
        }
      },
      post => sub {},
    },
    not => {
      pre => sub {},
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        if ($key eq '-boolean') {
          if ($opt{-name_flag} and index ($opt{-name_flag}, 'p') > -1) {
            $val = $self->replace ($val, param => $o);
          }
          $p->{-result} = defined $val ? $val ? 0 : 1 : undef;
        }
      },
      post => sub {},
    },
}}

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/01/17 08:28:25 $
