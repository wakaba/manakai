
=head1 NAME

Message::Field::Received Perl module

=head1 DESCRIPTION

Perl module for RFC 821/822/2821/2822 Received C<field>.

=cut

package Message::Field::Received;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%OPTION %REG $VERSION);
$VERSION = '1.00';

use Message::Field::Date;
use overload '@{}' => sub {shift->_delete_empty_item->{item}},
             '""' => sub {shift->stringify};

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]+|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{dot_atom} = qr/$REG{atext}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext})*/;
$REG{dot_word} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext}|$REG{quoted_string}))*/;
$REG{domain} = qr/(?:$REG{dot_atom}|$REG{domain_literal})/;
$REG{addr_spec} = qr/$REG{dot_word}$REG{FWS}\x40$REG{FWS}$REG{domain}/;
$REG{msg_id} = qr/<$REG{FWS}$REG{addr_spec}$REG{FWS}>/;
$REG{item_name} = qr/[A-Za-z][0-9A-Za-z-]*[0-9A-Za-z]/;
	## strictly, item-name = ALPHA *(["-"] (ALPHA / DIGIT))
$REG{M_name_val_pair} = qr/($REG{item_name})$REG{FWS}($REG{msg_id}|$REG{addr_spec}|$REG{domain}|$REG{atext})/;
$REG{date_time} = qr/(?:[A-Za-z]+$REG{FWS},$REG{FWS})?[0-9]+$REG{WSP}*[A-Za-z]+$REG{WSP}*[0-9]+$REG{WSP}+[0-9]+$REG{FWS}:$REG{WSP}*[0-9]+(?:$REG{FWS}:$REG{WSP}*[0-9]+)?$REG{FWS}(?:[A-Za-z]+|[+-]$REG{WSP}*[0-9]+)/;
$REG{asctime} = qr/[A-Za-z]+$REG{WSP}*[A-Za-z]+$REG{WSP}*[0-9]+$REG{WSP}+[0-9]+$REG{FWS}:$REG{WSP}*[0-9]+$REG{FWS}:$REG{WSP}*[0-9]+$REG{WSP}+[0-9]+/;

%OPTION = (
);

=head2 Message::Field::Received->new ()

Return empty received object.

=cut

sub new ($;%) {
  my $self = bless {}, shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{option} = \%option;
  $self->{date_time} = new Message::Field::Date;
  $self;
}

=head2 Message::Field::Received->parse ($unfolded_field_body)

Parse Received: C<field-body>.

=cut

sub parse ($$;%) {
  my $self = bless {}, shift;
  my $field_body = shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{option} = \%option;
  $field_body = $self->delete_comment ($field_body);
  $field_body =~ s{;$REG{FWS}($REG{date_time})$REG{FWS}$}{
    $self->{date_time} = Message::Field::Date->parse ($1);
    '';
  }ex;
  unless ($self->{date_time}) {
    if ($field_body =~ /($REG{asctime})/) {	## old USENET format
      $self->{date_time} = Message::Field::Date->parse ($1);
      return $self;
    } else {	## broken!
      $field_body =~ s/;[^;]+$//;
      $self->{date_time} = new Message::Field::Date (unknown => 1);
    }
  }
  $field_body =~ s{$REG{M_name_val_pair}$REG{FWS}}{
    my ($name, $value) = (lc $1, $2);
    $name =~ tr/-/_/;
    push @{$self->{item}}, [$name => $value];
    ''
  }goex;
  $self;
}

=head2 $self->items ()

Return item list hash that contains of C<name-val-list>
array references.

=cut

sub items ($) {@{shift->{item}}}

sub item_name ($$) {
  my $self = shift;
  my $i = shift;
  $self->{item}->[$i]->[0];
}

sub item_value ($$) {
  my $self = shift;
  my $i = shift;
  $self->{item}->[$i]->[1];
}

sub item ($$) {
  my $self = shift;
  my $name = lc shift;
  my @ret;
  for my $item (@{$self->{item}}) {
    if ($item->[0] eq $name) {
      unless (wantarray) {
        return $item->[1];
      } else {
        push @ret, $item->[1];
      }
    }
  }
  @ret;
}

sub date_time ($) {
  my $self = shift;
  $self->{date_time};
}

=head2 $self->add ($item_name, $item_value)

Add an C<nama-val-pair>.

Note that this method (and other methods) does not check
C<item-val-pair> is valid as RFC (2)82[12] definition or not.
(But only C<item-name> is changed when C<stringify>.)

=cut

sub add ($$$) {
  my $self = shift;
  my ($name, $value) = @_;
  push @{$self->{item}}, [$name, $value];
  $self;
}

sub replace ($$$) {
  my $self = shift;
  my ($name => $value) = (lc shift => shift);
  for my $item (@{$self->{item}}) {
    if ($item->[0] eq $name) {
      $item->[1] = $value;
      return $self;
    }
  }
  push @{$self->{item}}, [$name => $value];
  $self;
}

=head2 $self->delete ($item_name, [$index])

Deletes C<name-val-pair> named as $item_name.
If $index is specified, only $index'th C<name-val-pair> is deleted.
If not, ($index == 0), all C<name-val-pair>s that have the C<item-name>
$item_name are deleted.

=cut

sub delete ($$;$) {
  my $self = shift;
  my ($name, $index) = (lc shift, shift);
  my $i = 0;
  for my $item (@{$self->{item}}) {
    if ($item->[0] eq $name) {
      $i++;
      if ($index == 0 || $i == $index) {
        undef $item;
        return $self if $i == $index;
      }
    }
  }
  $self;
}

=head2 $self->count ([$item_name])

Returns the number of times the given C<item-name>'ed 
C<name-val-pair> appears.
If no $item_name is given, returns the number
of fields.  (Same as $#$self+1)

=cut

sub count ($;$) {
  my $self = shift;
  my ($name) = (lc shift);
  unless ($name) {
    $self->_delete_empty_item ();
    return $#{$self->{item}}+1;
  }
  my $count = 0;
  for my $item (@{$self->{item}}) {
    if ($item->[0] eq $name) {
      $count++;
    }
  }
  $count;
}

sub _delete_empty_item ($) {
  my $self = shift;
  my @ret;
  for my $item (@{$self->{item}}) {
    push @ret, $item if $item->[0];
  }
  $self->{item} = \@ret;
  $self;
}



sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  my @return;
  $self->_delete_empty_item;
  for my $item (@{$self->{item}}) {
    push @return, $item->[0], $item->[1] if $item->[0] =~ /^$REG{item_name}$/;
  }
  join (' ', @return).'; '.$self->{date_time}->as_rfc2822_time;
}

sub as_string ($;%) {shift->stringify (@_)}

=head2 $self->delete_comment ($field_body)

Remove all C<comment> in given strictured C<field-body>.
This method is intended for internal use.

=cut

sub delete_comment ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

=head1 EXAMPLE

  ## Compose field-body for To: field.
  
  use Message::Field::Address;
  my $addr = new Message::Field::Address;
  $addr->add ('foo@example.org', name => 'Mr. foo bar');
  $addr->add ('webmaster@example.org', group => 'administrators');
  $addr->add ('postmaster@example.org', group => 'administrators');
  
  my $field_body = $addr->stringify ();


  ## Output parsed address-list tree.
  
  use Message::Field::Address;
  my $addr = Message::Field::Address->parse ($field_body);
  
  for my $i (@$addr) {
    if ($i->{type} eq 'group') {
      print "\x40 $i->{display_name}: \n";
      for my $j (@{$i->{address}}) {
        print "\t- $j->{display_name} <$j->{route}$j->{addr_spec}>\n";
      }
    } else {
      print "- $i->{display_name} <$i->{route}$i->{addr_spec}>\n";
    }
  }

=head1 LICENSE

Copyright 2002 wakaba E<lt>w@suika.fam.cxE<gt>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=head1 CHANGE

See F<ChangeLog>.
$Date: 2002/03/20 09:56:26 $

=cut

1;
