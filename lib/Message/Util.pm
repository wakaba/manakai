
=head1 NAME

Message::Util -- Utilities for Message::* Perl modules.

=head1 DESCRIPTION

Useful functions for Message::* Perl modules.
This module is only intended for internal use.
But some can be useful for general use.

=cut

package Message::Util;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

$REG{WSP} = qr/[\x09\x20]/;
$REG{FWS} = qr/[\x09\x20]*/;

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*)\x29/;

$REG{NON_atom} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;

=head1 STRUCTURED FIELD FUNCTIONS

=over 4

=item Message::Util::delete_comment ($string)

Gets rid of all C<comment>s.  Inserts a SP instead.

=cut

sub delete_comment ($) {
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

=item Message::Util::unquote_ccontent ($string)

Unquotes C<quoted-pair> in C<comment>s.

=cut

sub unquote_ccontent ($) {
  my $comment = shift;
  $comment =~ s{$REG{M_comment}}{
    my $ctext = $1;
    $ctext =~ s/\x5C([\x00-\xFF])/$1/g;
    '('.$ctext.')';
  }goex;
  $comment;
}

=item Message::Util::unquote_quoted_string ($string)

Unquotes C<quoted-pair> in C<quoted-string>s and
unquotes C<quoted-string> (or gets rid of C<DQUOTE>s).

=cut

sub unquote_quoted_string ($) {
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

=item Message::Util::quote_unsafe_string ($string)

Quotes string itself by C<DQUOTES> if it contains of
I<unsafe> character.

Default I<unsafe> is defined as E<lt>not ( atom / "." / %x09 / %x20 ) E<gt>.

=cut

sub quote_unsafe_string ($) {
  my $string = shift;
  if ($string =~ /$REG{NON_atom}/ || $string =~ /$REG{WSP}$REG{WSP}+/) {
    $string =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
    $string = '"'.$string.'"';
  }
  $string;
}

=head1 ENCODER and DECODER

=over 4

=item Message::Util::encode_header_string ($yourself, $string, [%options])

=cut

sub encode_header_string ($$;%) {
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_after_encode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  $o{current_charset} = Message::MIME::Charset::name_normalize ($o{current_charset});
  my ($t,$r) = Message::MIME::Charset::encode ($o{charset}, $s);
  my @o = (language => $o{language});
  if ($r>0) {	## Convertion successed
    (value => $t, @o, charset => ($o{charset}=~/\*/?'':$o{charset}));
  } else {	## Fault
    (value => $s, @o, charset => ($o{current_charset}=~/\*/?'':$o{current_charset}));
  }
}

sub decode_header_string ($$;%) {
  require Message::MIME::EncodedWord;
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_before_decode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  $s = Message::MIME::EncodedWord::decode ($s)
    if $o{type} !~ /quoted/ && $o{type} !~ /encoded/;
  my ($t,$r) = Message::MIME::Charset::decode ($o{charset}, $s);
  $r>0 ? (value => $t, language => $o{language}):	## suceess
  (value => $s, language => $o{language},
   charset => ($o{charset}=~/\*/?'':$o{charset}));	## fault
}

sub encode_body_string {
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_after_encode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  $o{current_charset} = Message::MIME::Charset::name_normalize ($o{current_charset});
  my ($t,$r) = Message::MIME::Charset::encode ($o{charset}, $s);
  my @o = ();
  if ($r>0) {	## Convertion successed
    (value => $t, @o, charset => ($o{charset}=~/\*/?'':$o{charset}));
  } else {	## Fault
    (value => $s, @o, charset => ($o{current_charset}=~/\*/?'':$o{current_charset}));
  }
}

sub decode_body_string {
  require Message::MIME::EncodedWord;
  require Message::MIME::Charset;
  my $yourself = shift; my $s = shift; my %o = @_;
  $o{charset} ||= $yourself->{option}->{encoding_before_decode};
  $o{charset} = Message::MIME::Charset::name_normalize ($o{charset});
  my ($t,$r) = Message::MIME::Charset::decode ($o{charset}, $s);
  $r>0 ? (value => $t):	## suceess
  (value => $s,
   charset => ($o{charset}=~/\*/?'':$o{charset}));	## fault
}

=item Message::Util::encode_qcontent ($yourself, $string)

Encodes (by C<hook_encode_string> of C<$yourself-E<gt>{option}>)
C<qcontent> (content of C<quoted-string>) within C<$string>.

=cut

sub encode_qcontent ($$) {
  my $yourself = shift;
  my $quoted_strings = shift;
  $quoted_strings =~ s{$REG{M_quoted_string}}{
    my ($qtext) = ($1);
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$yourself->{option}->{hook_encode_string}} ($yourself, $qtext,
                type => 'phrase/quoted');
      $s{value} =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
      '"'.$s{value}.'"';
  }goex;
  $quoted_strings;
}

=item Message::Util::decode_qcontent ($yourself, $string)

Decodes (by C<hook_decode_string> of C<$yourself-E<gt>{option}>)
C<qcontent> (content of C<quoted-string>) within C<$string>.

=cut

sub decode_qcontent ($$) {
  my $yourself = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my ($qtext) = ($1);
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$yourself->{option}->{hook_decode_string}} ($yourself, $qtext,
                type => 'phrase/quoted');
      $s{value} =~ s/([\x22\x5C])([\x20-\xFF])?/"\x5C$1".($2?"\x5C$2":'')/ge;
      '"'.$s{value}.'"';
  }goex;
  $quoted_string;
}

=item @comments = Message::Util::comment_to_array ($youtself, $comments)

Replaces C<comment>s to C< > (a SP), decodes C<ccontent>s,
and returns them as array.

=cut

sub comment_to_array ($$) {
  my $yourself = shift;
  my $body = shift;
  my @r = ();
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{M_comment}}{
    my ($o, $c) = ($1, $2);
    if ($o) {$o}
    else {
      push @r, decode_ccontent ($yourself, $c);
      ' ';
    }
  }gex;
  @r;
}

=item Message::Util::encode_ccontent ($yourself, $ccontent)

Encodes C<ccontent> (content of C<comment>).

=cut

sub encode_ccontent ($$) {
  my $yourself = shift;
  my $ccontent = shift;
  my %f = &{$yourself->{option}->{hook_encode_string}} ($yourself, 
            $ccontent, type => 'ccontent');
  $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
  $f{value};
}

=item Message::Util::decode_ccontent ($yourself, $ccontent)

Decodes C<ccontent> (content of C<comment>).

=cut

sub decode_ccontent ($$) {
  require Message::MIME::EncodedWord;
  &Message::MIME::EncodedWord::decode_ccontent (@_[1,0]);
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
$Date: 2002/04/05 14:56:26 $

=cut

1;
