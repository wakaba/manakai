
=head1 NAME

Message::MIME::EncodedWord Perl module

=head1 DESCRIPTION

Perl module for MIME C<encoded-word>.

=cut

package Message::MIME::EncodedWord;
use strict;
use vars qw(%ENCODER %DECODER %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::MIME::Charset;

$REG{WSP} = qr/[\x09\x20]/;
$REG{FWS} = qr/[\x09\x20]*/;

$REG{atext_dot} = qr/[\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{attribute_char} = qr/[\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
$REG{M_encoded_word} = qr/=\x3F($REG{attribute_char})(?:\x2A($REG{attribute_char}))?\x3F($REG{attribute_char})\x3F([\x21-\x3E\x40-\x7E]+)\x3F=/;
$REG{S_encoded_word} = qr/=\x3F$REG{atext_dot}\x3F=/;

%DECODER = (
  '*DEFAULT'	=> sub {$_[1]},
  b	=> sub {require MIME::Base64; MIME::Base64::decode ($_[1])},
  q	=> sub {my $s = $_[1]; $s =~ tr/_/\x20/; 
    $s=~ s/=([0-9A-Fa-f]{2})/pack("C", hex($1))/ge; $s},
);

sub decode ($$) {
  my ($s) = (shift);
  $s =~ s{(?:\G|$REG{WSP}+)$REG{M_encoded_word}(?:(?=$REG{WSP}+$REG{S_encoded_word})|$REG{WSP}+|$)}{
    my ($charset, $lang, $encoding, $etext) = ($1, $2, lc $3, $4);
    $charset = Message::MIME::Charset::name_normalize ($charset);
    my ($r,$s) = ('', -1);
    if (ref $DECODER{$encoding}) {
      $r = &{$DECODER{$encoding}} ($encoding, $etext);
      ($r,$s) = Message::MIME::Charset::decode ($charset, $r);
    }
    $r = $& unless ($s>0);
    $r;
  }goex;
  $s;
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
$Date: 2002/03/25 10:17:05 $

=cut

1;
