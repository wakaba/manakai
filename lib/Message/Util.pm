
=head1 NAME

Message::Util Perl module

=head1 DESCRIPTION

Utilities for Message::* Perl modules.

=cut

package Message::Util;
use strict;
use vars qw(%REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

$REG{WSP} = qr/[\x09\x20]/;
$REG{FWS} = qr/[\x09\x20]*/;

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
$Date: 2002/04/03 13:31:36 $

=cut

1;
