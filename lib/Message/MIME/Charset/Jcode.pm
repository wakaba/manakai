
=head1 NAME

Message::MIME::Charset::Jcode --- Japanese Coding Systems Support
with jcode.pl and/or Jcode.pm for Message::* Perl Modules

=head1 DESCRIPTION

Message::* therselves don't convert coding systems of parts of
messages, but have mechanism to define to call external functions.
This module provides such macros for Japanese coding systems,
supported by jcode.pl and/or Jcode.pm.

=cut

package Message::MIME::Charset::Jcode;
use strict;
use vars qw(%CODE $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Util;
require Message::MIME::Charset;

=head1 CODING SYSTEMS

=over 4

=item C<euc>

Japanese EUC.  (MIME: euc-jp)

=item C<jis>

7bit ISO/IEC 2022, so-called junet code.  ASCII, JIS X 0201 Roman,
JIS X 0201 Katakana, JIS X 0208, JIS X 0212 are supported by
jcode.pl and Jcode.pm.  ISO-2022-JP, ISO-2022-JP-1 are subsets of
junet code.

=item C<sjis>

Shift JIS.  (MIME: Shift_JIS)

=item C<utf8>

UTF-8.  (MIME: UTF-8)  This coding system is not supported by jcode.pl.

=item C<ucs2>

UCS-2 (or Unicode without surrogate pairs) big endian (network
byte order).  This coding system is not supported by jcode.pl.

=back

=head1 VARIABLES

=over 4

=item $Messag::MIME::Charset::Jcode::CODE{internal}

Internal coding system.  You can get strings written in this
coding system from Message::* Perl modules.  (Default: C<euc>)

=item $Messag::MIME::Charset::Jcode::CODE{input}

Coding system of input string.  (Default: auto-detect)

=item $Messag::MIME::Charset::Jcode::CODE{output}

Coding system of output string.  (Default: C<jis>)

=back

=cut

$CODE{internal} = 'euc';
$CODE{input} = '';
$CODE{output} = 'jis';

sub import ($;%) {
  shift;
  for (@_) {
    if ($_ eq 'jcode.pl') {
      require 'jcode.pl';
      Message::MIME::Charset::make_charset ('*default' =>
        encoder	=> sub { jcode::to ($CODE{output},   $_[1], $CODE{internal}) },
        decoder	=> sub { jcode::to ($CODE{internal}, $_[1], $CODE{input}) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub { jcode::jis ($_[1], $CODE{internal}) },
        decoder	=> sub { jcode::to ($CODE{internal}, $_[1], 'jis') },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub { jcode::euc ($_[1], $CODE{internal}) },
        decoder	=> sub { jcode::to ($CODE{internal}, $_[1], 'euc') },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub { jcode::sjis ($_[1], $CODE{internal}) },
        decoder	=> sub { jcode::to ($CODE{internal}, $_[1], 'sjis') },
        mime_text	=> 1,
      );
    } elsif ($_ eq 'Jcode' || $_ eq 'Jcode.pm') {
      require Jcode;
      Message::MIME::Charset::make_charset ('*default' =>
        ## Very tricky:-)
        encoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{output}, $CODE{internal}); $s },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, $CODE{input}); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->iso_2022_jp },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'jis'); $s },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->euc },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'euc'); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->sjis },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'sjis'); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('utf-8' =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->utf8 },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'utf8'); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('ucs-2be' =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->ucs2 },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'ucs2'); $s },
      );
      Message::MIME::Charset::make_charset ('ucs-2' => alias_of => 'ucs-2be');
      Message::MIME::Charset::make_charset ('utf-16' => alias_of => 'ucs-2');
      Message::MIME::Charset::make_charset ('utf-16be' => alias_of => 'ucs-2be');
    } else {
      Carp::croak "Jcode: $_: Module not supported";
    }
    Message::MIME::Charset::make_charset (jis => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset ('iso-2022-jp-1' => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset ('iso-2022-jp-3' => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset ('x-iso-2022-jp-3' => alias_of => 'iso-2022-jp-3');
    Message::MIME::Charset::make_charset ('iso-2022-jp-3-plane1' => alias_of => 'iso-2022-jp-3');
    Message::MIME::Charset::make_charset (euc => alias_of => 'euc-jp');
    Message::MIME::Charset::make_charset (euc_jp => alias_of => 'euc-jp');
    Message::MIME::Charset::make_charset ('x-euc' => alias_of => 'euc-jp');
    Message::MIME::Charset::make_charset ('x-euc-jp' => alias_of => 'euc-jp');
    Message::MIME::Charset::make_charset ('euc-jisx0213' => alias_of => 'euc-jp');
    Message::MIME::Charset::make_charset ('x-euc-jisx0213' => alias_of => 'euc-jisx0213');
    Message::MIME::Charset::make_charset ('euc-jisx0213-plane1' => alias_of => 'euc-jisx0213');
    Message::MIME::Charset::make_charset (sjis => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset ('shift-jis' => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset ('x-sjis' => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset (shift_jisx0213 => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset ('shift-jisx0213' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset ('x-shift_jisx0213' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset ('x-shift-jisx0213' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset ('shift_jisx0213-plane1' => alias_of => 'shift_jisx0213');
  }
}

=head1 EXAMPLE

  ## Uses jcode.pl.  Input is euc-japan, output is junet.
  use Message::MIME::Charset::Jcode 'jcode.pl';
  	## You don't have to do {require 'jcode.pl'}.
  $Message::MIME::Charset::Jcode::CODE{input} = 'euc';
  $Message::MIME::Charset::Jcode::CODE{output} = 'jis';
  require Message::Entity;
  #...

  ## Uses Jcode.pm.
  use Message::MIME::Charset::Jcode 'Jcode';
  require Message::Entity;
  #...

  ## Uses jcode.pl, but also Jcode.pm for Unicode encodings.
  ## Internal code is UTF-8.
  use Message::MIME::Charset::Jcode 'Jcode';
  use Message::MIME::Charset::Jcode 'jcode.pl';
  $Message::MIME::Charset::Jcode::CODE{internal} = 'utf-8';
  require Message::Entity;
  #...

=head1 SEE ALSO

Message::MIME::Charset

Message::Entity

jcode.pl

Jcode.pm

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
$Date: 2002/05/30 12:48:04 $

=cut

1;
