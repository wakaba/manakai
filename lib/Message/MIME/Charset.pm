
=head1 NAME

Message::MIME::Charset Perl module

=head1 DESCRIPTION

Perl module for MIME charset.

=cut

package Message::MIME::Charset;
use strict;
use vars qw(%ENCODER %DECODER %N11NTABLE %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

%ENCODER = (
  '*DEFAULT'	=> sub {$_[1]},
  'us-ascii'	=> sub {$_[1]},
);

%DECODER = (
  '*DEFAULT'	=> sub {$_[1]},
  'us-ascii'	=> sub {$_[1]},
);

## Charset name normalization
%N11NTABLE = (
  'euc'	=> 'euc-jp',	## ...
  'jis'	=> 'iso-2022-jp',	## Really?
  'shift-jis'	=> 'shift_jis',
  'shift-jisx0213'	=> 'shift_jisx0213',
  'x-big5'	=> 'big5',
  'x-x-big5'	=> 'big5',
  'x-euc'	=> 'euc-jp',	## ...
  'x-euc-jp'	=> 'euc-jp',
  'x-gbk'	=> 'gbk',
  'x-gbk2k'	=> 'gb18030',
  'x-x-gbk'	=> 'gbk',
  'x-sjis'	=> 'shift_jis',
);

sub encode ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $ENCODER{$charset}) {
    return (&{$ENCODER{$charset}} ($charset, $s), 1);
  }
  ($s, 0);
}

sub decode ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $DECODER{$charset}) {
    return (&{$DECODER{$charset}} ($charset, $s), 1);
  }
  ($s, 0);
}

sub name_normalize ($) {
  my $name = lc shift;
  $N11NTABLE{$name} || $name;
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
$Date: 2002/04/19 12:00:36 $

=cut

1;
