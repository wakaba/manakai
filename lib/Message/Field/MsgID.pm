
=head1 NAME

Message::Field::MsgID Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 Message-ID C<field>.

This module supports message ID C<field-body>s defined
by : RFC 822, RFC 2822, RFC 850, RFC 1036, son-of-RFC1036,
RFC 1341, RFC 1521, RFC 2045, but does not support: 
RFC 724, RFC 733.

=cut

package Message::Field::MsgID;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%OPTION %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload '@{}' => sub {shift->{id}},
             '""' => sub {shift->stringify};

use Message::Field::MsgID::MsgID;
$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]+|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{dot_atom} = qr/$REG{atext}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext})*/;
$REG{dot_word} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext}|$REG{quoted_string}))*/;
$REG{phrase} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{atext}|$REG{quoted_string}|\.|$REG{FWS})*/;
$REG{addr_spec} = qr/$REG{dot_word}$REG{FWS}\x40$REG{FWS}(?:$REG{dot_atom}|$REG{domain_literal})/;
$REG{msg_id} = qr/<$REG{FWS}$REG{addr_spec}$REG{FWS}>/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_addr_spec} = qr/($REG{dot_word})$REG{FWS}\x40$REG{FWS}($REG{dot_atom}|$REG{domain_literal})/;

$REG{NON_atom} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E\x2E]/;

%OPTION = (
  one_id	=> -1,
  field_name	=> 'message-id',
  reduce_first	=> 1,
  reduce_last	=> 3,
  reduce_max	=> 21,
);

sub _init_option ($$) {
  my $self = shift;
  my $field_name = shift;
  if ($field_name eq 'message-id' || $field_name eq 'content-id') {
    $self->{option}->{one_id} = 1;
  }
  $self;
}

=head2 Message::Field::MsgID->new ()

Returns new MsgID object.

=cut

sub new ($;%) {
  my $self = bless {}, shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{id} = [];
  $self->{option} = \%option;
  $self->_init_option ($self->{option}->{field_name});
  $self;
}

=head2 Message::Field::MsgID->parse ($unfolded_field_body)

Parses C<field-body>.

=cut

sub parse ($$;%) {
  my $self = bless {}, shift;
  my $field_body = shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{id} = [];
  $self->{option} = \%option;
  $self->_init_option ($self->{option}->{field_name});
  $field_body = $self->delete_comment ($field_body);
  @{$self->{id}} = $self->parse_msgid_list ($field_body);
  $self;
}

sub parse_msgid_list ($$) {
  my $self = shift;
  my $fb = shift;
  my @ids;
  $fb =~ s{($REG{msg_id})}{
    push @ids, Message::Field::MsgID::MsgID->parse ($1);
  }goex;
  @ids;
}

=head2 $self->id ()

Return address list in the format described in
L<$self-E<gt>parse_address_list ()>.

=cut

sub id ($) {
  my $self = shift;
  wantarray? @{$self->{id}}: $self->{id}->[0];
}

=head2 $self->add ($msg_id, [%option])

Adds an msg-id to C<$self>.

Note that this method (and other methods) does not check
whether $msg_id is valid or not (It is only checked
if C<msg-id> is sorounded by angle blankets).

=cut

sub add ($;$%) {
  my $self = shift;
  my ($msg_id, %option) = @_;
  if (!ref $msg_id) {
    $msg_id = Message::Field::MsgID::MsgID->parse ($msg_id, %option);
  }
  push @{$self->{id}}, $msg_id;
  $self;
}

sub add_new ($;%) {
  my $self = shift;
  my (%option) = @_;
  my $msg_id = Message::Field::MsgID::MsgID->new (%option);
  push @{$self->{id}}, $msg_id if length $msg_id;
  $self;
}

sub reduce ($;%) {
  my $self = shift;
  my %option = @_;
  $option{reduce_max} ||= $self->{option}->{reduce_max};
  $option{reduce_first} ||= $self->{option}->{reduce_first};
  $option{reduce_last} ||= $self->{option}->{reduce_last};
  return $self if $#{$self->{id}}+1 <= $option{reduce_max};
  return $self if $#{$self->{id}}+1 <= $option{reduce_top}+$option{reduce_last};
  my @nid;
  push @nid, @{$self->{id}}[0..$option{reduce_first}-1];
  push @nid, @{$self->{id}}[-$option{reduce_last}..-1];
  $self->{id} = \@nid;
  $self;
}

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;  
  $option{one_id} ||= $self->{option}->{one_id};
  $self->_delete_empty ();
  if ($option{one_id}>0) {
    $self->{id}->[0] || '';
  } else {
    join ' ', @{$self->{id}};
  }
}

=head2 $self->option ($option_name, [$option_value])

Set/gets new value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
}

sub _delete_empty ($) {
  my $self = shift;
  my @nid;
  for my $id (@{$self->{id}}) {push @nid, $id if $id}
  $self->{id} = \@nid;
}


=head2 $self->unquote_quoted_string ($string)

Unquote C<quoted-string>.  Get rid of C<DQUOTE>s and
C<REVERSED SOLIDUS> included in C<quoted-pair>.
This method is intended for internal use.

=cut

sub unquote_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

=head2 $self->delete_comment ($field_body)

Remove all C<comment> in given strictured C<field-body>.
This method is intended to be used for internal process.

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
$Date: 2002/03/31 13:11:55 $

=cut

1;
