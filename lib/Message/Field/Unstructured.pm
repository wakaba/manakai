
=head1 NAME

Message::Field::Address Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 address related C<field>s.
$Id: Unstructured.pm,v 1.1 2002/03/16 01:26:31 wakaba Exp $

=cut

package Message::Field::Unstructured;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%REG $VERSION);
$VERSION = '1.00';

use overload '""' => sub {shift->stringify};

=head2 Message::Field::Address->new ()

Return empty address object.

=cut

sub new ($) {
  bless {}, shift;
}

=head2 Message::Field::Address->parse ($unfolded_field_body)

Parse structured C<field-body> contain of C<address-list>.

=cut

sub parse ($$) {
  my $self = bless {}, shift;
  my $field_body = shift;
  $self->{field_body} = $field_body;
  $self;
}

sub stringify ($) {
  my $self = shift;
  $self->{field_body};
}

sub as_plain_string ($) {
  my $self = shift;
  $self->{field_body};
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

=cut

1;
