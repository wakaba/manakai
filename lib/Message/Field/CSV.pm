
=head1 NAME

Message::Field::CSV Perl module

=head1 DESCRIPTION

Perl module for comma separated C<field>.

This module supports a number of fields that contains
(or does not contain:-)) of comma separated values,
such as C<Keywords:>, C<Newsgroups:>, C<Content-Type>,
C<Content-Transfer-Encoding:>, and so on.

=cut

package Message::Field::CSV;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%OPTION %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload '@{}' => sub {[shift->value]},
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
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{NON_atom} = qr/[^\x09\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E\x2E]/;

## Keywords: foo, bar, "and so on"
## Newsgroups: local.test,local.foo,local.bar
## Content-Type: text/plain; charset=us-ascii
## Content-Transfer-Encoding: base64
## Accept: text/html; q=1.0, text/plain; q=0.03; *; q=0.01

%OPTION = (
  field_name	=> 'keywords',
  is_quoted_string	=> 1,
  separator	=> ', ',
  max	=> -1,
);

sub _init_option ($$) {
  my $self = shift;
  my %field_type = qw(accept-charset accept accept-encoding accept 
     accept-language accept
     content-disposition content-type
     content-language keywords content-transfer-encoding content-type
     followup-to newsgroups
     x-brother accept x-daughter accept x-face-type content-type x-moe accept 
     x-respect accept x-syster accept x-wife accept);
  my $field_name = lc shift;
  $field_name = $field_type{$field_name} || $field_name;
  if ($field_name eq 'content-type') {
    $self->{option}->{is_quoted_string} = -1;
    $self->{option}->{max} = 1;
  } elsif ($field_name eq 'newsgroups') {
    $self->{option}->{is_quoted_string} = -1;
    $self->{option}->{separator} = ',';
  } elsif ($field_name eq 'accept') {
    $self->{option}->{is_quoted_string} = -1;
  } elsif ($field_name eq 'encrypted') {
    $self->{option}->{max} = 2;
  }
  $self;
}

=head2 Message::Field::CSV->new ()

Returns new CSV field body.

=cut

sub new ($;%) {
  my $self = bless {}, shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{option} = \%option;
  $self->_init_option ($self->{option}->{field_name});
  $self;
}

=head2 Message::Field::CSV->parse ($unfolded_field_body)

Parses C<field-body>.

=cut

sub parse ($$;%) {
  my $self = bless {}, shift;
  my $field_body = shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{option} = \%option;
  $self->_init_option ($self->{option}->{field_name});
  $field_body = $self->_delete_comment ($field_body);
  @{$self->{value}} = $self->_parse_list ($field_body);
  $self;
}

sub _parse_list ($$) {
  my $self = shift;
  my $fb = shift;
  my @ids;
  $fb =~ s{((?:$REG{quoted_string}|$REG{domain_literal}|[^\x22\x2C\x5B])+)}{
    my $s = $1;  $s =~ s/^$REG{WSP}+//;  $s =~ s/$REG{WSP}+$//;
    if ($self->{option}->{is_quoted_string}>0) {
      push @ids, $self->_unquote_quoted_string ($s);
    } else {
      push @ids, $s;
    }
  }goex;
  @ids;
}

=head2 $self->value ()

Returns value list.

=cut

sub value ($) {@{shift->{value}}}

=head2 $self->add ($value, [%option])

Adds new value.

=cut

sub add ($;$%) {
  my $self = shift;
  my ($value, %option) = @_;
  push @{$self->{value}}, $value;
  $self;
}

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{separator} ||= $self->{option}->{separator};
  $option{max} ||= $self->{option}->{max};
  $option{is_quoted_string} ||= $self->{option}->{is_quoted_string};
  $self->_delete_empty ();
  $option{max}--;
  $option{max} = $#{$self->{value}} if $option{max}<0;
  $option{max} = $#{$self->{value}} if $#{$self->{value}}<$option{max};
  join $option{separator}, 
    map {$option{is_quoted_string}>0?$self->_quote_unsafe_string ($_):$_}
    @{$self->{value}}[0..$option{max}];
}

sub _delete_empty ($) {
  my $self = shift;
  my @nid;
  for my $id (@{$self->{value}}) {push @nid, $id if length $id}
  $self->{value} = \@nid;
}

sub _quote_unsafe_string ($$) {
  my $self = shift;
  my $string = shift;
  if ($string =~ /$REG{NON_atom}/ || $string =~ /$REG{WSP}$REG{WSP}+/) {
    $string =~ s/([\x22\x5C])/\x5C$1/g;
    $string = '"'.$string.'"';
  }
  $string;
}


=head2 $self->_unquote_quoted_string ($string)

Unquote C<quoted-string>.  Get rid of C<DQUOTE>s and
C<REVERSED SOLIDUS> included in C<quoted-pair>.
This method is intended for internal use.

=cut

sub _unquote_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

=head2 $self->_delete_comment ($field_body)

Remove all C<comment> in given strictured C<field-body>.
This method is intended to be used for internal process.

=cut

sub _delete_comment ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

=head1 EXAMPLE


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
$Date: 2002/03/21 04:18:38 $

=cut

1;
