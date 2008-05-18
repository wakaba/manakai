#!/usr/bin/perl
package Whatpm::Charset::WebLatin1;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

## NOTE: This module does not expect that its standalone uses.
## See Message::Charset::Info for how it is used.

require Encode::Encoding;
push our @ISA, 'Encode::Encoding';
__PACKAGE__->Define (qw/web-thai/);

sub encode ($$;$) {
  # $self, $str, $chk
  if ($_[2]) {
    if ($_[1] =~ s/^([\x00-\x7F\xA0\x{0E01}-\x{0E3A}\x{0E3F}-\x{0E5B}]+)//) {
      return Encode::encode ('iso-8859-11', $1);
    } else {
      return '';
    }
  } else {
    my $r = $_[1];
    $r =~ s/[^\x00-\x7F\xA0\x{0E01}-\x{0E3A}\x{0E3F}-\x{0E5B}]/?/g;
    return Encode::encode ('iso-8859-11', $r);
  }
} # encode

sub decode ($$;$) {
  # $self, $s, $chk
  if ($_[2]) {
    my $r = '';
    while (1) {
      if ($_[1] =~ s/^([\x00-\x7F\xA0-\xDA\xDF-\xFB]+)//) {
        $r .= Encode::decode ('iso-8859-11', $1);
      } else {
        return $r;
      }
    }
  } else {
    return Encode::decode ('windows-874', $_[1]);
  }
} # decode

1;
## $Date: 2008/05/18 06:07:22 $
