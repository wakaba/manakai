
=head1 NAME

Message::MIME::EncodedWord Perl module

=head1 DESCRIPTION

Perl module for MIME C<encoded-word>.

=cut

package Message::MIME::EncodedWord;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%ENCODER %DECODER %OPTION %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::MIME::Charset;

$REG{WSP} = qr/[\x09\x20]/;
$REG{FWS} = qr/[\x09\x20]*/;
$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;

$REG{atext_dot} = qr/[\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{attribute_char} = qr/[\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
$REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*)\x29/;
$REG{M_encoded_word} = qr/=\x3F($REG{attribute_char})(?:\x2A($REG{attribute_char}))?\x3F($REG{attribute_char})\x3F([\x21-\x3E\x40-\x7E]+)\x3F=/;
$REG{S_encoded_word} = qr/=\x3F$REG{atext_dot}\x3F=/;

=head1 OPTIONS

=cut

%OPTION = (
	forcedecode	=> 0,
);

=over 4

=item $Message::MIME::EncodedWord::OPTION{forcedecode} = 1/0

When no charset decoder (See L<Message::MIME::Charset>)
for C<ISO-8859-I<n>> is defined, and this option is TRUE, 
decoding C<encoded-word> functions attempt to decode
ASCII part of these charset.

RFC 2047 says to support ASCII part of C<ISO-8859-I<n>> at least.
This requirement is convinient for human users who see final rendering
result.  But it is not appropriate to process message.

Defalt value is C<1>, force decoding is enabled.

=back

=head2 Note

Before you set new value for these options,
C<Message::MIME::EncodedWord> should be loaded (C<require>ed).
Other modules which use C<Message::MIME::EncodedWord>
will automatically require this module, and this module
will set initial (default) option value.

Bad example:

  #! perl
  $Message::MIME::EncodedWord::OPTION{forcedecode} = 0;
  use Message::Field::Subject;
  my $subject = Message::Field::Subject->parse ($ARGV[0]);
  	## At this time, M::F::Subject call M::M::EWord,
  	## and $OPTION{forcedecode} is set C<1>, default value.

Shold be:

  #! perl
  require Message::MIME::EncodedWord;
  $Message::MIME::EncodedWord::OPTION{forcedecode} = 0;
  use Message::Field::Subject;
  my $subject = Message::Field::Subject->parse ($ARGV[0]);
  	## At this time, M::F::Subject call M::M::EWord,
  	## but perl takes no action since it has already loaded.

=cut

%DECODER = (
  '*DEFAULT'	=> sub {$_[1]},
  b	=> sub {require MIME::Base64; MIME::Base64::decode ($_[1])},
  q	=> sub {my $s = $_[1]; $s =~ tr/_/\x20/; 
    $s=~ s/=([0-9A-Fa-f]{2})/pack("C", hex($1))/ge; $s},
);

sub decode ($) {
  my $s = shift;
  my (@s, @r) = ();
  $s =~ s{\G([\x09\x20]*[^\x09\x20]+)}{push @s, $1}goex;
  for my $i (0..$#s) {
    $r[$i] = 0;
    if ($s[$i] =~ /^($REG{FWS})$REG{M_encoded_word}$/) {
      my ($t, $w) = ('', $1);
      ($t, $r[$i]) = (_decode_eword ($2, $3, $4, $5));
      if ($r[$i]) {
        $s[$i] = $t;
        if ($i == 0 || $r[$i-1] == 0) {
          $s[$i] = $w.$s[$i];
        }
      }
    }
  }
  join '', @s;
}

sub decode_ccontent ($$) {
  my $s = shift;  my $yourself = shift;
  my (@s, @r) = ();
  my ($i, @t) = (-1);
  $s =~ s{$REG{FWS}$REG{comment}}{$i++; $t[$i] = $&; "\x28${i}\x29"}gex;
  $s =~ s{($REG{FWS}(?:\x5C[\x00-\xFF]
                     |[\x00-\x08\x0A-\x1F\x21-\x27\x2A-\x5B\x5D-\xFF])+)
         |(\x28[0-9]+\x29)}{my ($t,$c) = ($1, $2);
     if ($t) {$i++; $t[$i] = $t; "\x28${i}\x29"}
     else {$c}}gex;
  $s =~ s{\x28([0-9]+)\x29}{push @s, $t[$1]; ''}gex;
  push @s, $s if length $s;
  for my $i (0..$#s) {
    if ($s[$i] =~ /^($REG{FWS})$REG{M_encoded_word}$/) {
      my ($t, $w) = ('', $1);
      ($t, $r[$i]) = (_decode_eword ($2, $3, $4, $5));
      if ($r[$i]) {
        $s[$i] = $t;
        if ($i == 0 || $r[$i-1] == 0) {
          $s[$i] = $w.$s[$i];
        }
      }
    } elsif ($s[$i] =~ /^($REG{FWS})$REG{M_comment}$/) {
      $s[$i] = $1.'('.&decode_ccontent ($2, $yourself).')';
    } else {
      $s[$i] =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$yourself->{option}->{hook_decode_string}} ($yourself, $s[$i],
                type => 'ccontent/quoted');
      $s[$i] = $s{value};
    }
  }
  join '', @s;
}

sub _decode_eword ($$$$) {
  my ($charset, $lang, $encoding, $etext) = (shift, shift, lc shift, shift);
  $charset = Message::MIME::Charset::name_normalize ($charset);
  my ($r,$s) = ('', 0);
  if (ref $DECODER{$encoding}) {	## decode TE
    $r = &{$DECODER{$encoding}} ($encoding, $etext);
    ($r,$s) = Message::MIME::Charset::decode ($charset, $r);
    if (!$s && $OPTION{forcedecode} && $charset =~ /^iso-8859-([0-9]+(?:-[ie])?)$/) {
      my $n = $1;
      $r =~ s{([\x09\x0A\x0D\x20]*[\x80-\xFF]+[\x09\x0A\x0D\x20]*)}{
        my $t = $1;
        $t =~ s/([\x09\x0A\x0D\x80-\xFF])/sprintf('=%02X', ord $1)/ge;
        $t =~ tr/\x20/_/;
        sprintf ' =?iso-8859-%s?q?%s?= ', $n.($lang?'*'.$lang:''), $t;
      }goex;
      $s = 1;
    }
  }
  ($r, $s);
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
$Date: 2002/05/25 09:53:24 $

=cut

1;
