
=head1 NAME

Message::Field::Token --- Message-pm: Lexical tokens used in Internet message formats

=head1 DESCRIPTION

This module provides functions for handling lexical tokens of Internet message formats,
such as quoted-string, comment, etc.

This module is part of Message::* Perl Modules.

=cut

package Message::Field::Token;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 $phrase = Message::Field::Token::en_phrase ($string, %option)

Return given string (in internal code) as a phrase (= atom / quoted-string / encoded-word).

Options:

=over 4

=item -charset => charset (default: 'us-ascii')

Charset name (in lower cases) to be used to encode the output string.

=item -ebcdic_safe

=item -encode_encoded_word_like

=item -quoted_pair

=item -token_maxlength

=item -unsafe_char => 1*CHAR / '' (default)

See options of C<en_quoted_string>.

=item -source_charset => charset (default = *internal)

Charset name (in lower case) of given string.

=back

=cut

sub en_phrase ($;%) {
  my $string = shift;
  my %option = @_;
  my @string = split /(?<=[^\x09\x20])(?=[\x09\x20])/, $string;
  my @str = ([0, '']);
  for my $i (0..$#string) {
    if (Message::MIME::Charset::is_representable_in ($option{-charset}, $string[$i], \%option) && $string[$i] !~ /[\x00\x0A\x0D]/) {
      if ($str[$#str]->[0]) {	## Preceding token should be encoded
        push @str, [0, $string[$i]];
      } else {	## Preceding token need not be encoded
        $str[$#str]->[1] .= $string[$i];
      }
    } else {	## Should be encoded
      if ($str[$#str]->[0]) {	## Preceding token should be encoded
        $str[$#str]->[1] .= $string[$i];
      } else {	## Preceding token need not be encoded
        push @str, [1, $string[$i]];
      }
    }
  }
  my $phrase = '';
  for my $i (0..$#str) {
    my $ws = ''; $ws = $1 if $i != 0 && $str[$i]->[1] =~ s/^([\x09\x20])//;
    if ($str[$i]->[0]) {
      $str[$i]->[1] = Message::MIME::EncodedWord::encode ($str[$i]->[1], %option, -context => 'phrase', -encode_char => '\x00-\x7F');
    } else {
      $str[$i]->[1] = _to_quoted_string ($str[$i]->[1], \%option);
    }
    $phrase .= $ws . $str[$i]->[1];
  }
  $phrase;
}

=head1 $quoted_string = Message::Field::Token::en_quoted_string ($string, %option)

Quote string as a quoted-string if necessary.

Options:

=over 4

=item -charset => charset (default: 'us-ascii')

Charset name (in lower cases) to be used to encode the output string.

=item -context => 'quoted_string' (default) / 'atom' / 'token' / 'http_token' / 'attr_char' / 'http_attr_char'

Context in which given string is embeded.  This value is used to check if
string should be quoted as a quoted-string.  'quoted_string', the default value,
makes string ALWAYS quoted.  'atom' makes it quoted when string contains
one or more characters not included in the atext (see RFC 2822).
Likewise, 'token' is for token of MIME, 'http_token' is for token of HTTP,
'attr_char' is attribute-char of MIME (RFC 2231) and 'http_attr_char'
is 'http_token' AND 'attr_char' (ie. safe for both HTTP and RFC 2231).

=item -ebcdic_safe

This option is only meaningful when C<-use_quoted_string> is true.
See L<Message::MIME::EncodedWord>::decode.

=item -encode_encoded_word_like

This option is only meaningful when C<-use_quoted_string> is true.
See L<Message::MIME::EncodedWord>::decode.

=item -quoted_pair => 1*CHAR / qr|(:: pattern ::)| (default: qr/([\x0D\\"]|(?<==)\?)/)

A character list or a Regexp pattern for characters to be quoted as
the quoted-pairs.  When '', no character is quoted.
Quoting is performed to characters NOT encoded as encoded-words.

=item -source_charset => charset (default = *internal)

Charset name (in lower case) of given string.

=item -token_maxlength

This option is only meaningful when C<-use_quoted_string> is true.
See L<Message::MIME::EncodedWord>::decode.

=item -unsafe_char => 1*CHAR / '' (default)

The list of characters that when one of them is included in the string
it should be quoted, in addition to special characters determined by C<-context> option.

=item -use_encoded_word => 0 (default)/1

If true, characters in qcontent which unable to be represented in C<-charset> charset
are encoded in encoded-words.

=back

=cut

sub en_quoted_string ($;%) {
  my ($string, %option) = @_;
  if ($option{-use_encoded_word}) {
    require Message::MIME::EncodedWord;
    $option{-quoted_pair} ||= qr/([\x0D\\"]|(?<==)\?)/;
    $string = Message::MIME::EncodedWord::encode ($string, %option, -context => 'quoted_string', -preserve_wsp => 0);
    $option{-quoted_pair} = qr/(?!)/;
  }
  $string = _to_quoted_string ($string, \%option);
  my ($s, %r) = Message::MIME::Charset::encode ($option{-charset}, $string);
  $r{success} ? $s : $string;
}

sub _to_quoted_string ($$) {
  my ($string, $option) = @_;
  ## -- What characters should be quoted?
    my $achar = {
      atom	=> qq(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#\$%&'*+/=?^_`{|}~-),
      token	=> qq(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#\$%&'*+^_`{|}~.-),
      http_token	=> qq(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#\$%&'*+^_`|~.-),
      attr_char	=> qq(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#\$&+^_`{|}~.-),
      http_attr_char	=> qq(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#\$&+^_`|~.-),
      quoted_string	=> '',
    }->{$option->{-context} || 'quoted_string'};
    my $echar = $option->{-unsafe_char}; $echar =~ s/([\/\\])/\\$1/g;
    eval qq{\$achar =~ tr/$echar//d};
    $achar =~ s/([\\\[\]])/\\$1/g;
    $option->{-quoted_pair} ||= qr/([\x0D"\\]|(?<==)\?)/;
    if (!ref $option->{-quoted_pair}) {
      $option->{-quoted_pair} = quotemeta $option->{-quoted_pair};
      $option->{-quoted_pair} = qr/([$option->{-quoted_pair}])/;
    }
  ## -- Quote
    if (length ($achar) == 0 || $string =~ /[^$achar]/) {
      $string =~ s/$option->{-quoted_pair}/\\$1/g if $option->{-quoted_pair};
      $string = '"' . $string . '"';
    }
  $string;
}

=head1 $string = Message::Field::Token::de_phrase ($phrase, %option)

Parses given phrase or a quoted-string and return it as a string (in internal code).

Options:

=over 4

=item -charset => charset (default: 'us-ascii')

Charset name of input.  The charset MUST be a superset of ASCII.

=item -use_encoded_word => 0/1 (default)

Decodes encoded-words (out of quoted-strings).

=item -use_quoted_encoded_word => 0 (default)/1

Decodes encoded-words in quoted-strings.

=back

=cut

sub de_phrase ($;%) {
  my ($string, %option) = @_;
  $option{-use_encoded_word} = 1 unless defined $option{-use_encoded_word};
  require Message::MIME::EncodedWord if $option{-use_encoded_word};
  require Message::MIME::Charset;
  $string =~ s("((?:\\.|[^"])*)"|([^"]+)){	## Note: broken <"> does not match with this.
    my ($qcontent, $atom) = ($1, $2);
    if (defined $qcontent) {
      if ($option{-use_quoted_encoded_word}) {
        $qcontent = Message::MIME::EncodedWord::decode($qcontent, -process_non_encoded_word => sub {
          $_[0] =~ s/\\(.)/$1/g;
          my ($s, %s) = Message::MIME::Charset::decode ($option{-charset} || 'us-ascii', $_[0]);
          $s{success} ? ($s, 0) : ($_[0], 0);
        });
      } else {
        $qcontent =~ s/\\(.)/$1/g;
        my ($s, %s) = Message::MIME::Charset::decode ($option{-charset} || 'us-ascii', $qcontent);
        $qcontent = $s if $s{success};
      }
      $qcontent;
    } else {	## 1*(atom / encoded-word / FWS)
      if ($option{-use_encoded_word}) {
        $atom = Message::MIME::EncodedWord::decode ($atom, -process_non_encoded_word => sub {
          my ($s, %s) = Message::MIME::Charset::decode ($option{-charset} || 'us-ascii', $_[0]);
          $s{success} ? ($s, 0) : ($_[0], 0);
        });
      }
      $atom;
    }
  }ges;
  $string;
}

=head1 $string = Message::Field::Token::de_quoted_string ($quoted_string, %option)

An alias to C<de_phrase>.

=cut

*de_quoted_string = \&de_phrase;

=head1 LICENSE

Copyright 2002 Wakaba <w@suika.fam.cx>

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

1; # $Date: 2002/12/29 03:04:53 $
