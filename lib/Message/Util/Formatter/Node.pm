
=head1 NAME

Message::Util::Formatter::Node --- Manakai : Generating Node tree with formatting rule

=head1 DESCRIPTION

This module is an application of Message::Util::Formatter mechanism,
used to generate a node tree (fragment) with given formatting
rule text and formatting functions.

Although this module is intended to be used in combination with 
Message::Markup::XML::Node, it can be useful as a base class for
other node module interface.

This module is part of manakai.

=cut

package Message::Util::Formatter::Node;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util::Formatter::Base;
our @ISA = 'Message::Util::Formatter::Base';

sub ___rule_def () {+{
    -attr_bare_text => {
      main => sub {
        my ($self, $name, $p, $o, %opt) = @_;
        return ref $opt{-parent} ?
                 $opt{-parent}->append_text ($opt{-attr_bare_text})
               : $opt{-class}->new (type => '#text',
                                    value => $opt{-attr_bare_text});
      },
    },
    -bare_text => {
      main => sub {
        my ($self, $name, $p, $o, %opt) = @_;
        return $p->{-parent}->append_text ($p->{-bare_text});
      },
    },
    -undef     => {
      main => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-parent}->append_text ("[undef: $name]");
      },             
    },
    -default   => {
      pre => sub { 
#        my ($self, $name, $p, $o, %opt) = @_;
#        local $p->{-parent} = $o->{-result};
      },
      post => sub { 
        my ($self, $name, $p, $o, %opt) = @_;
        local $p->{-parent} = $o->{-result};
        $self->call ($name, 'main', $p, $o, %opt);
      },
      attr => sub {
        my ($self, $name, $p, $o, $key, $val, %opt) = @_;
        if ($key eq '-boolean') {
          $p->{$val} = 1;
        } else {
          if ($opt{-value_flag} and index ($opt{-value_flag}, 'p') > -1) {
            $p->{-parse_flag}->{$key} = 1;
          }
          $p->{$key} = $val;
        }
      },                 
      main => sub {
      },
    },
    -entire    => {
      pre => sub {
        my ($self, $name, $p, $o, %opt) = @_;
        if (ref $opt{option}->{-parent}) {
          $o->{-result} = $opt{option}->{-parent};
        } else {
          $o->{-result} = $opt{option}->{-class}->new
            (type => '#fragment');
        }
      },
      post => sub {
      },
      attr => sub {
      },
    },
    percent => {
      main => sub {
        my ($self, $name, $p, $o) = @_;
        $p->{-parent}->append_text ('%');
      },
    },
}}

sub parse_attr ($$$$;%) {
  my ($self, $p, $name, $o, %opt) = @_;
  if ($p->{-parse_flag}->{$name} and $p->{-parse_flag}->{$name} > 0) {
    $p->{-parse_flag}->{$name} = -1;
    $p->{$name} = $self->replace ($p->{$name},
                                  %{$opt{option}}, param => $o,
                                  -parent => $opt{-parent});
  } elsif ($p->{-parse_flag}->{$name} and $p->{-parse_flag}->{$name} < 0) {
    $p->{$name};
  } elsif ($opt{-non_parsed_to_node}) {
    $p->{$name} = $self->call (-attr_bare_text => 'main', $p, $o,
                               %{$opt{option}},
                               -attr_bare_text => $p->{$name},
                               -parent => $opt{-parent});
  } else {
    undef;
  }
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/02/14 11:05:57 $
