
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
$VERSION=do{my @r=(q$Revision: 1.12 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

RFC 2047 says that ASCII part of C<ISO-8859-I<n>> be at least
supported.  This requirement is convinience for human user who 
sees final rendering result.  But it is not appropriate to process message.

Defalt value is C<0>, force decoding is disenabled.

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
  '*DEFAULT'	=> sub { $_[1] },
  '7'	=> sub { $_[1] },
  '8'	=> sub { $_[1] },
  b	=> sub {require MIME::Base64; MIME::Base64::decode ($_[1])},
  q	=> sub {my $s = $_[1]; $s =~ tr/_/\x20/; 
    $s=~ s/=([0-9A-Fa-f]{2})/pack("C", hex($1))/ge; $s},
);

%ENCODER = (
  b	=> sub {require MIME::Base64; my $b = MIME::Base64::encode ($_[1]); $b =~ tr/\x00-\x20//d; ($b, {-encoded => 1})},
  q	=> \&_encode_q_encoding,
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
  my $yourself = shift;  my $s = shift;
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
      $s[$i] = $1.'('. &decode_ccontent ($yourself, $2) .')';
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
  my ($r,%s) = ('');
  if (ref $DECODER{$encoding}) {	## decode TE
    $r = &{$DECODER{$encoding}} ($encoding, $etext);
    ($r,%s) = Message::MIME::Charset::decode ($charset, $r);
    if (!$s{success} && $OPTION{forcedecode} && $charset =~ /^iso-8859-([0-9]+(?:-[ie])?)$/) {
      my $n = $1;
      $r =~ s{([\x09\x0A\x0D\x20]*[\x80-\xFF]+[\x09\x0A\x0D\x20]*)}{
        my $t = $1;
        $t =~ s/([\x09\x0A\x0D\x80-\xFF])/sprintf('=%02X', ord $1)/ge;
        $t =~ tr/\x20/_/;
        sprintf ' =?iso-8859-%s?q?%s?= ', $n.($lang?'*'.$lang:''), $t;
      }goex;
      $s{success} = 1;
    }
  }
  ($r, $s{success});
}

=head1 $encoded_words = Message::MIME::EncodedWord::encode ($string, %option)

Encode given string as encoded-words if necessary.

Available options:

=over 4

=item -charset => charset (default: 'us-ascii')

Charset name (in lower cases) to be used to encode the output string.
(Currently 'us-ascii', 'iso-8859-1' and 'us-ascii' is supported.
'iso-2022-int', 'euc-jp' or other charsets are unable to co-exist with
encoded-words, in current implemention.)

=item -context => 'default' (default) / 'comment' / 'phrase' / 'quoted_string'

Context in which given string is embeded.

=item -ebcdic_safe => 0/1 (default)

Encode additional ASCII characters (shown in RFC 2047) that
are not safe in EBCDIC transports.  This option is meaningful only when
"Q" encoding is used.

=item -encode_char => 1*CHAR / '' (default)

The list of ASCII characters should be encoded in encoded-word
in addition to non-ASCII characters and special ASCII characters
determined by C<-context> and C<-ebcdic_safe> options.

=item -encode_encoded_word_like => 0/1 (default)

Encode encoded-word-like tokens in given string or not.

=item -preserve_wsp => 0/1 (default)

If true, 2*WSP is encoded in encoded-word.  Unless string is the content
of comment or quoted-string, this option value should be true.

=item -q_encode_char => 1*CHAR / '' (default)

The list of ASCII characters should be encoded in q encoding of encoded-word
in addition to non-ASCII characters and special ASCII characters
determined by C<-context> and C<-ebcdic_safe> options.

=item -quoted_pair => 1*CHAR / qr|(:: pattern ::)| '' (default)

A character list or a Regexp pattern for characters to be quoted as
the quoted-pairs.  When '', no character is quoted.
Quoting is performed to characters NOT encoded as encoded-words.
This option should be useful if given string is to be a content
of a comment or quoted-string.  Usually, "\" is also included in
the character list to represent "\" itself as "\\".

=item -source_charset => charset (default = *internal)

Charset name (in lower case) of given string.

=item -token_maxlength => 1*DIGIT / 0 (default)

Maximal length of a string (1*l<OCTET except WSP>) that can be represented
as a non-encoded-word.  If 0, no length limit is implied.
Note that this option does NOT change maximal length of encoded-word.
(Maximal length of encoded-word is always 75, as defined in RFC 2047.)

=cut

sub encode ($;%) {
  my $string = shift;
  my %option = @_;
  $option{-preserve_wsp} = 1 unless defined $option{-preserve_wsp};
  $option{-source_charset} ||= '*internal';
  my $re_encode = join ('|', grep {$_}
     (($option{-charset} eq 'utf-8' ? '' :
       $option{-charset} eq 'iso-8859-1' ? '[^\x00-\xFF]' : '[^\x00-\x7F]'),
      (defined $option{-encode_char} ? qq([$option{-encode_char}]) : ''),
      (!defined $option{-encode_encoded_word_like}||$option{-encode_encoded_word_like} ? '^=\?' :'')
     )) || '(?!)';
  if ($option{-quoted_pair} && !ref $option{-quoted_pair}) {
    $option{-quoted_pair} = quotemeta $option{-quoted_pair};
    $option{-quoted_pair} = qr/([$option{-quoted_pair}])/;
  }
  my @string = split /(?<=[^\x09\x20])(?=[\x09\x20])/, $string;
  my @encoded;
  for my $i (0..$#string) {
    my $string_nows = $string[$i];
    my $ws = ''; $ws = $1 if $string_nows =~ s/^([\x09\x20]+)//;
    $encoded[$i] = -1;
    if ($i == 0) {	## First component of string
      if ($string_nows =~ /$re_encode/ || ($option{-preserve_wsp} && length ($ws) > 1)
      || ($option{-token_maxlength} && length ($string_nows) > $option{-token_maxlength})) {
        my $estring = _encode ($string[$i], \%option);
        if ($estring) {
          $string[$i] = $estring;
          $encoded[$i] = 1;
        }
      }
    } elsif ($i == $#string && length ($string_nows) == 0) {	## Last component of string is 1*WSP
      my $estring = _encode ($ws, \%option);
      if ($estring) {
        $string[$i] = ' ' . $estring;
        $encoded[$i] = 1;
      }
    } elsif ($i == 0 || !$encoded[$i-1]) {	## Previous token is not encoded
      if ($string_nows =~ /$re_encode/
      || ($option{-token_maxlength} && length ($string_nows) > $option{-token_maxlength})) {
        if ($option{-preserve_wsp} && length ($ws) > 1 && $i) {
          $string_nows = substr ($ws, 1) . $string_nows;
          $ws = substr ($ws, 0, 1);
        } elsif (!$ws) {
          $ws = ' ';
        }
        my $estring = _encode ($string_nows, \%option);
        if ($estring) {
          $string[$i] = $ws . $estring;
          $encoded[$i] = 1;
        }
      } elsif ($option{-preserve_wsp} && length ($ws) == 2) {
        my $estring = _encode (substr ($ws, 1) . $string_nows, \%option);
        if ($estring) {
          $string[$i] = substr ($ws, 0, 1) . $estring;
          $encoded[$i] = 1;
        }
      } elsif ($option{-preserve_wsp} && length ($ws) > 2) {
        my $estring = _encode (substr ($ws, 1, length ($ws) - 2), \%option);
        if ($estring) {
          $string_nows =~ s/$option{-quoted_pair}/\\$1/g if $option{-quoted_pair};
          $string[$i] = substr ($ws, 0, 1) . $estring . substr ($ws, -1) . $string_nows;
          $encoded[$i] = 0;
        }
      }
    } else {	## Previous token is encoded
      if ($string_nows =~ /$re_encode/
      || ($option{-token_maxlength} && length ($string_nows) > $option{-token_maxlength})) {
        my $estring = _encode ($string[$i], \%option);
        if ($estring) {
          $string[$i] = ($i!=0?' ':'') . $estring;
          $encoded[$i] = 1;
        }
      } elsif ($option{-preserve_wsp} && length ($ws) > 1) {
        my $estring = _encode (substr ($ws, 0, length ($ws) - 1), \%option);
        if ($estring) {
          $string_nows =~ s/$option{-quoted_pair}/\\$1/g if $option{-quoted_pair};
          $string[$i] = ($i!=0?' ':'') . $estring . substr ($ws, -1) . $string_nows;
          $encoded[$i] = 0;
        }
      }
    }
    if ($encoded[$i] == -1) {
      $string[$i] =~ s/$option{-quoted_pair}/\\$1/g if $option{-quoted_pair};
      $encoded[$i] = 0;
    }
  }
  join '', @string;
}

## $encoded_text must be octet string (not utf8 string).
sub _encode_q_encoding ($$;\%) {
    my ($encoding, $encoded_text, $option) = @_;
    ## -- What characters are encoded?
    my $achar = {
      default	=> q(!"#$%&'()*+,./0123456789:;<>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^`abcdefghijklmnopqrstuvwxyz{|}~\\[]-),
      comment	=> q(!"#$%&'*+,./0123456789:;<>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^`abcdefghijklmnopqrstuvwxyz{|}~[]-),
      phrase	=> q(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!*+/-),
      quoted_string	=> q(!#$%&'()*+,./0123456789:;<>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^`abcdefghijklmnopqrstuvwxyz{|}~[]-),
    }->{$option->{-context} || 'default'};
    my $echar = $option->{-q_encode_char}; $echar =~ s/([\/\\])/\\$1/g;
    eval qq{\$achar =~ tr/$echar//d};
    $achar =~ tr/!"#$@[\\]^`{|}~//d unless defined $option->{-ebcdic_safe} && $option->{-ebcdic_safe} == 0;
    $achar = quotemeta $achar;
    ## -- Encode
    $encoded_text =~ s/([^$achar])/sprintf '=%02X', ord $1/ge;
    $encoded_text =~ s/=20/_/g;
    ($encoded_text, {-encoded => 1});
}
sub _encode ($$) {
  my $option = $_[1];
  my $charset = $option->{-source_charset};
  my $encoding = Message::MIME::Charset::get_property ('cte_header_preferred', $charset);
  my @estr;
  for my $str (@{Message::MIME::Charset::divide_string ($charset, $_[0], -max => int ((75 - length ($charset.$encoding) - 6) * ({b=>3/4,q=>1/3}->{$encoding}||1)))}) {
    my $echarset = Message::MIME::Charset::get_interchange_charset ($charset, $str, $option)->{charset} || $charset;
    my ($estr, %r) = Message::MIME::Charset::encode ($echarset, $str);
    do {$echarset = $charset; $estr = $str; Message::MIME::Charset::_utf8_off ($estr)} unless $r{success};
    $encoding = Message::MIME::Charset::get_property ('cte_header_preferred', $echarset);
    if ($encoding eq '*auto') {
      $encoding = (($estr =~ tr/\x20-\x7E/\x20-\x7E/) < (length ($estr) * 0.55)) ? 'b' : 'q';
    }
    my ($s, $r) = &{$ENCODER{$encoding}} ($encoding, $estr, $option);
    if ($r->{-encoded}) {	## Success
      my $echarset = {Message::MIME::Charset::name_minimumize ($echarset, $estr, {-name_only=>1})}->{charset};
      push @estr, sprintf ('=?%s?%s?%s?=', $echarset, $encoding, $s);
    } else {
      return undef;
    }
  }
  join ' ', @estr;
}


=head1 LICENSE

Copyright 2002 Wakaba <w@suika.fam.cx>.

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

=cut

1; # $Date: 2002/12/28 09:07:05 $
