
=head1 NAME

Message::MIME::Charset::MinName --- IANA charset name minumumizers

=cut

package Message::MIME::Charset::MinName;
use strict;
use vars qw(%MIN $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::MIME::Charset;

## $MIN{ $charset } = sub ($charset, $string) { (charset => $charset) };

$MIN{hz} = sub {
  if ($_[1] =~ /[\x80-\xFF]/) {
    (charset => 'x-hz8');
  } elsif ($_[1] =~ /\x7E/) {
    (charset => 'hz-gb-2312');
  } else {
    (charset => 'us-ascii');
  }
};

$MIN{'iso-10646-utf-1'} = sub {
  if ($_[1] =~ /[\x80-\xFF]/) {
    (charset => 'iso-10646-utf-1');
  } else {
    (charset => 'us-ascii');
  }
};

$MIN{'utf-16be'} = sub {
  if ($_[1] =~ /[\xD8-\xDB][\x00-\xFF][\xDC-\xDF][\x00-\xFF]
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
    (charset => 'utf-16be');
  } elsif ($_[1] =~ /[\x01-\xFF][\x00-\xFF]
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
    if ($_[1] =~ /([^\x00\x03\x04\x23\x25\x30\xFE\xFF]
                     [\x00-\xFF]	# ^\x20\x22\x4E-\x9F\xF9\xFA
                  |\x03[^\x00-\x6F\xD0-\xFF]
                  #|\x20[^\x00-\x6F]
                  |\x25[^\x00-\x7F]
                  |\xFE[^\x30-\x4F]
                  |\xFF[^\x00-\xEF]
                  ## note 1 of RFC 1816 is ambitious, so block entire
                  ## is excepted
                    |\x30[\x00-\x3F]
                  )
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
      (charset => 'iso-10646-ucs-2');
    } else {
      (charset => 'iso-10646-j-1');
    }
  } elsif ($_[1] =~ /\x00[\x80-\xFF]
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
    (charset => 'iso-10646-unicode-latin1');
  } else {
    (charset => 'iso-10646-ucs-basic');
  }
};
$MIN{'iso-10646-j-1'} = $MIN{'utf-16be'};
$MIN{'iso-10646-ucs-2'} = $MIN{'utf-16be'};
$MIN{'iso-10646-ucs-basic'} = $MIN{'utf-16be'};
$MIN{'iso-10646-unicode-latin'} = $MIN{'utf-16be'};

$MIN{'utf-32be'} = sub {
  if ($_[1] =~ /
    ([\x01-\x7F][\x00-\xFF]{3}
    |\x00[\x11-\xFF][\x00-\xFF][\x00-\xFF])
             (?=(?:[\x00-\xFF]{4})*\z)/sx) {
    (charset => 'iso-10646-ucs-4');
  } else {
    (charset => 'utf-32be');
  }
};
$MIN{'iso-10646-ucs-4'} = $MIN{'utf-32be'};

=head1 SEE ALSO

Message::MIME::Charset

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

=cut

1; ## $Date: 2002/08/18 06:21:24 $
### MinName.pm ends here
