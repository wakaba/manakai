
=head1 NAME

Message::Field::Address Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 address related C<field>s.

=cut

package Message::Field::Address;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%REG $VERSION);
$VERSION = '1.00';

use overload '@{}' => sub {shift->{address}},
             '""' => sub {shift->stringify};

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]+|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{dot_atom} = qr/$REG{atext}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext})*/;
$REG{dot_word} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext}|$REG{quoted_string}))*/;
$REG{phrase} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{atext}|$REG{quoted_string}|\.|$REG{FWS})*/;
$REG{obs_route} = qr/(?:\x40$REG{FWS}(?:$REG{dot_word}|$REG{domain_literal})(?:$REG{FWS},?$REG{FWS}\x40$REG{FWS}(?:$REG{dot_word}|$REG{domain_literal}))*):/;
$REG{addr_spec} = qr/$REG{dot_word}$REG{FWS}\x40$REG{FWS}(?:$REG{dot_atom}|$REG{domain_literal})/;
$REG{mailbox} = qr/(?:(?:$REG{phrase})?<$REG{FWS}(?:$REG{obs_route})?$REG{FWS}$REG{addr_spec}$REG{FWS}>|$REG{addr_spec})/;
$REG{mailbox_list} = qr/$REG{mailbox}(?:$REG{FWS},(?:$REG{FWS}$REG{mailbox})?)*/;
$REG{address} = qr/(?:(?:$REG{phrase})?(?:<$REG{FWS}(?:$REG{obs_route})?$REG{FWS}$REG{addr_spec}$REG{FWS}>|:$REG{FWS}(?:$REG{mailbox_list}$REG{FWS})?;)|$REG{addr_spec})/;
$REG{address_list} = qr/$REG{address}(?:$REG{FWS},(?:$REG{FWS}$REG{address})?)*/;
$REG{M_group} = qr/($REG{phrase}):/;
$REG{M_mailbox} = qr/(?:($REG{phrase})?<$REG{FWS}($REG{obs_route})?$REG{FWS}($REG{addr_spec})$REG{FWS}>|($REG{addr_spec}))/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;

$REG{NON_atom} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;

=head2 Message::Field::Address->new ()

Return empty address object.

=cut

sub new ($) {
  bless {type => '_ROOT'}, shift;
}

=head2 Message::Field::Address->parse ($unfolded_field_body)

Parse structured C<field-body> contain of C<address-list>.

=cut

sub parse ($$) {
  my $self = bless {}, shift;
  my $field_body = shift;
  $field_body = $self->delete_comment ($field_body);
  my %addr = $self->parse_address_list ($field_body);
  $self->{address} = $addr{address};
  $self->{type}    = $addr{type};
  $self;
}

=head2 $self->address ()

Return address list in the format described in
L<$self-E<gt>parse_address_list ()>.

=cut

sub address ($) {@{shift->{address}}}

=head2 $self->add ($addr_spec, [%option])

Add an mail address to C<$self> (address object).
%option = (name => C<display-name>, route => C<route>, 
           group => C<display-name> of C<group>)

Note that this method (and other methods) does not check
$addr_spec and $option{route} is valid or not.

=cut

sub add ($$;%) {
  my $self = shift;
  my ($addr, %option) = @_;
  my $name = $option{name} || $option{display_name};
  unless ($option{group}) {
    push @{$self->{address}}, {type => 'mailbox',
         addr_spec => $addr, display_name => $name, route => $option{route}};
  } else {
    for my $i (@{$self->{address}}) {
      if ($i->{type} eq 'group' && $i->{display_name} eq $option{group}) {
        push @{$i->{address}}, {type => 'mailbox',
             addr_spec => $addr, display_name => $name, route => $option{route}};
        return $self;
      }
    }
    push @{$self->{address}}, {type => 'group', display_name => $option{group},
         address => [
           {type => 'mailbox',
            addr_spec => $addr, display_name => $name, route => $option{route}}
         ]};
  }
  $self;
}

sub stringify ($) {
  my $self = shift;
  my @return;
  for my $address (@{$self->{address}}) {
    my $return = '';
    next if !$address->{addr_spec} && $address->{type} ne 'group';
    if ($address->{display_name}) {
      $return = $self->quote_unsafe_string ($address->{display_name})
        .($address->{type} eq 'group'? ': ': ' ');
    }
    if ($address->{type} ne 'group') {
      $return .= '<'.$address->{route}.$address->{addr_spec}.'>';
    } else {
      my (@g_return);
      for my $mailbox (@{$address->{address}}) {
        next unless $mailbox->{addr_spec};
        my $g_return = '';
        $g_return = $self->quote_unsafe_string ($mailbox->{display_name}) .' '
          if $mailbox->{display_name};
        $g_return .= '<'.$mailbox->{route}.$mailbox->{addr_spec}.'>';
        push @g_return, $g_return;
      }
      $return .= join ', ', @g_return;
      $return .= ';' if $address->{type} eq 'group';
    }
    push @return, $return;
  }
  join ', ', @return;
}

sub quote_unsafe_string ($$) {
  my $self = shift;
  my $string = shift;
  if ($string =~ /$REG{NON_atom}/ || $string =~ /$REG{WSP}$REG{WSP}+/) {
    $string =~ s/([\x22\x5C])/\x5C$1/g;
    $string = '"'.$string.'"';
  }
  $string;
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

=head2 $self->parse_mailbox ($mailbox)

Parse C<mailbox> and return array of C<addr-spec>,
C<display-name> and C<route> (aka C<obs-route> of RFC 2822).
This method is intended for internal use.

=cut

sub parse_mailbox ($$) {
  my $self = shift;
  my $mailbox = shift;
  if ($mailbox =~ /$REG{M_mailbox}/) {
    my ($display_name, $route, $addr_spec) = ($1, $2, $3 || $4);
    $display_name =~ s/$REG{WSP}+$//;
    $display_name = $self->unquote_quoted_string ($display_name);
    $addr_spec =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{WSP}}{$1}go;
    $route =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{WSP}}{$1}go;
    return ($addr_spec, $display_name, $route);
  }
}

=head2 $self->parse_address_list ($address_list)

Parse C<address-list> and return hash.
This method is intended for internal use.

=head3 Structure of hash returned by parse_address_list

%address = (

  type	=> '_ROOT',
  address	=> [
  
    ## mailbox
    {
      type	=> 'mailbox',
      display_name	=> 'Foo H. Bar',
      addr_spec	=> 'foo@bar.example',
      route	=> '@hoge.example:',
    },
    
    ## group
    {
      type	=> 'group',
      display_name	=> 'The committee',
      address	=> [
        
        ## mailbox
        {
          type	=> 'mailbox',
          display_name	=> 'Tom (Director)',
          addr_spec	=> 'tom@committee.example',
          route	=> '',
        }
        
      ],
    },
  
  ],

);

=cut

sub parse_address_list ($$) {
  my $self = shift;
  my $address_list = shift;
  my %r_addr = (type => '_ROOT');
  $address_list =~ s{($REG{address})}{
    my $address = $1;
    if ($address =~ /^$REG{M_group}/) {
      my %r_group = (type => 'group', display_name => $1);
      $r_group{display_name} =~ s/$REG{WSP}+$//;
      $r_group{display_name} = $self->unquote_quoted_string ($r_group{display_name});
      $address =~ s{($REG{mailbox})}{
        my ($addr, $name, $route) = $self->parse_mailbox ($1);
        push @{$r_group{address}}, {type => 'mailbox',
           display_name => $name, route => $route, addr_spec => $addr};
      }goex;
      push @{$r_addr{address}}, \%r_group;
    } else {
      my ($addr, $name, $route) = $self->parse_mailbox ($address);
      push @{$r_addr{address}}, {type => 'mailbox',
           display_name => $name, route => $route, addr_spec => $addr};
    }
  }goex;
  %r_addr;
}

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
$Date: 2002/03/16 01:26:30 $

=cut

1;
