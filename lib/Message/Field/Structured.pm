
=head1 NAME

Message::Field::Structured Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 structured C<field>s.

=cut

package Message::Field::Structured;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;

use overload '""' => sub {shift->stringify};

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*)\x29/;

$REG{NON_atom} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;

%DEFAULT = (
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
);

=head2 Message::Field::Structured->new ()

Return empty Message::Field::Structured object.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Field::Structured->parse ($unfolded_field_body)

Parse structured C<field-body>.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  my $field_body = $self->_decode_qcontent (shift);
  $self->{field_body} = $field_body;
  $self;
}

=head2 $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($) {
  my $self = shift;
  $self->_encode_qcontent ($self->{field_body});
}

=head2 $self->as_plain_string ()

Returns C<field-body> contents as a plain text fragment.
C<quoted-string> and C<quoted-pair> in C<comment> are
unquoted, so return value of this method can be invalid
as a part of the C<field>.

=cut

sub as_plain_string ($) {
  my $self = shift;
  $self->unquote_quoted_string ($self->unquote_comment ($self->{field_body}));
}

## Decode C<qcontent> (content of C<quoted-string>).
sub _decode_qcontent ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my ($qtext) = ($1);
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $qtext,
                type => 'phrase/quoted');
      $s{value} =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
      '"'.$s{value}.'"';
  }goex;
  $quoted_string;
}

## Encode C<qcontent> (content of C<quoted-string>).
sub _encode_qcontent ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my ($qtext) = ($1);
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$self->{option}->{hook_encode_string}} ($self, $qtext,
                type => 'phrase/quoted');
      $s{value} =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
      '"'.$s{value}.'"';
  }goex;
  $quoted_string;
}

sub quote_unsafe_string ($$) {
  my $self = shift;
  my $string = shift;
  if ($string =~ /$REG{NON_atom}/ || $string =~ /$REG{WSP}$REG{WSP}+/) {
    $string =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
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

sub unquote_comment ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_comment}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    '('.$qtext.')';
  }goex;
  $quoted_string;
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

  use Message::Field::Structured;
  
  my $field_body = '"This is an example of <\"> (quotation mark)."
                    (Comment within \q\u\o\t\e\d\-\p\a\i\r\(\s\))';
  my $field = Message::Field::Structured->parse ($field_body);
  
  print $field->as_plain_string;

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
