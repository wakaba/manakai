
=head1 NAME

Message::MIME::Charset::Encode --- Encode module plug-in for Message::* Perl Modules

=head1 DESCRIPTION

Message::* therselves don't convert coding systems of parts of
messages, but have mechanism to define to call external functions.
This module provides such macros for Encode modules.

=head1 USAGE

  use Message::MIME::Charset::Encode;

=cut

package Message::MIME::Charset::Encode;
use strict;
use vars qw(%CODE $VERSION);
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::MIME::Charset;
require Encode;

$CODE{internal} = 'utf-8';

=head1 $Message::MIME::Charset::Encode::CODE{input} = $perl_charset_name
=head1 $Message::MIME::Charset::Encode::CODE{output} = $perl_charset_name

Perl Encode module's name of '*default' charset.
You should change these value if necessary.

=cut

$CODE{input} = '7bit-jis';
$CODE{output} = '7bit-jis';

require Encode::Alias;
Encode::Alias::define_alias( qr/^(?:x-)?mac[-_]?(\w+)$/i => '"mac$1"' );
Encode::Alias::define_alias( qr/^macintosh$/i => '"macroman"' );
Encode::Alias::define_alias( qr/^windows[-_]?31j$/i => '"cp932"' );
unless ($Encode::EUCFixed::VERSION) {
  Encode::Alias::define_alias( qr/^cseucfixwidjapanese$/i => '"extended_unix_code_fixed_width_for_japanese"' );
}
unless ($Encode::HZ::VERSION) {
  Encode::Alias::define_alias( qr/^hz-gb-2312$/i => '"hz"' );
}
unless ($Encode::UTF1::VERSION) {
  Encode::Alias::define_alias( qr/^csiso10646utf1$/i => '"iso-10646-utf-1"' );
  Encode::Alias::define_alias( qr/^utf-?1$/i => '"iso-10646-utf-1"' );
}
unless ($Encode::UTF7::VERSION) {
  Encode::Alias::define_alias( qr/^(?:x-)?unicode-.-.-utf-?7$/i => '"utf-7"' );
  Encode::Alias::define_alias( qr/^csunicode11utf7$/i => '"utf-7"' );
  Encode::Alias::define_alias( qr/^cp65000$/i => '"utf-7"' );
}

my %_PerlName2IanaName = qw(
	7bit-jis	iso-2022-jp-1
	adobestandardencoding	adobe-standard-encoding
	adobesymbol	adobe-symbol-encoding
	ascii-ctrl	us-ascii
	cp37	ibm037
	cp932	windows-31j	cp936	gbk	cp949	windows-949
	cp1250	windows-1250	cp1251	windows-1251
	cp1252	windows-1252	cp1253	windows-1253
	cp1254	windows-1254	cp1255	windows-1255
	cp1256	windows-1256	cp1257	windows-1257
	cp1258	windows-1258
	euc-cn	gb2312
	gsm0338	gsm-default-alphabet
	hz	hz-gb-2312
	iso-8859-11	tis-620
	macarabic	x-mac-arabic	maccentraleurroman	x-mac-centralroman
	maccyrillic	x-mac-cyrillic	macgreek	x-mac-greek
	machebrew	x-mac-hebrew	macicelandic	x-mac-icelandic
	macroman	macintosh	macturkish	x-mac-turkish
	macukrainian	x-mac-ukrainian	macchinesesimp	x-mac-chinesesimp
	macjapanese	x-mac-japanese	mackorean	x-mac-korean
	shiftjis	shift_jis	shiftjisx0213	shift_jisx0213
	ucs-2be	iso-10646-ucs-2	ucs-4be	iso-10646-ucs-4
	ucs-2le	utf-16le	ucs-2	utf-16
);
#	MacCroatian	
#	MacFarsi	
#	MacRomanian	
#	MacRumanian	
#	MacSami	
#	MacThai	

sub import ($;%) {
  shift;
  Message::MIME::Charset::make_charset ('*undef' =>
    encoder	=> sub {
      my ($name, $s) = @_;
      $name = $CODE{output} if $name =~ /\*/;
      unless (Encode::find_encoding ($name)) {
        Message::MIME::Charset::_utf8_off ($s);
        return ($s, success => 0);
      }
      return (Encode::encode ($name, $s), success => 1);
    },
    decoder	=> sub {
      my ($name, $s) = @_;
      $name = $CODE{input} if $name =~ /\*/;
      #unless ($name) {
      #  use Encode::Guess qw/utf-8 iso-8859-1 iso-2022-jp/;
      #  $name = Encode::Guess->guess ($s);
      #  return ($name->decode ($s), success => 1) if ref $name;
      #}
      return ($s, success => 0) unless Encode::find_encoding ($name);
      return (Encode::decode ($name, $s), success => 1);
    },
    preferred_name	=> \&_preferred_name,
  );
  Message::MIME::Charset::make_charset ('*default' => alias_of => '*undef');
  Message::MIME::Charset::make_charset (extended_unix_code_fixed_width_for_japanese =>
    encoder	=> sub { &_encoder ('EUCFixed', 'EUCFixed', @_) },
    decoder	=> sub { &_decoder ('EUCFixed', 'EUCFixed', @_) },
  );
  Message::MIME::Charset::make_charset ('x-iso2022jp-cp932' =>
    encoder	=> sub { &_encoder ('ISO2022::CP932', 'ISO2022::CP932', @_) },
    decoder	=> sub { &_decoder ('ISO2022::CP932', 'ISO2022::CP932', @_) },
  );
  Message::MIME::Charset::make_charset ('iso-10646-utf-1' =>
    encoder	=> sub { &_encoder ('Unicode::UTF1', 'Unicode::UTF1', @_) },
    decoder	=> sub { &_decoder ('Unicode::UTF1', 'Unicode::UTF1', @_) },
  );
  Message::MIME::Charset::make_charset ('utf-7' =>
    encoder	=> sub { &_encoder ('Unicode::UTF7', 'Unicode::UTF7', @_) },
    decoder	=> sub { &_decoder ('Unicode::UTF7', 'Unicode::UTF7', @_) },
  );
  Message::MIME::Charset::make_charset ('x-imap4-modified-utf7' =>
    encoder	=> sub { &_encoder ('Unicode::UTF7', 'Unicode::UTF7::IMAP', @_) },
    decoder	=> sub { &_decoder ('Unicode::UTF7', 'Unicode::UTF7::IMAP', @_) },
  );
}

sub _encoder ($@) {
  no strict 'refs';
  my $p1 = shift;
  my $p2 = shift;
  if (!${'Encode::'.$p2.'::VERSION'} && !eval qq{use Encode::$p1}) {
    my $s = shift;
    Message::MIME::Charset::_utf8_off ($s);
    return ($s, success => 0);
  }
  return (Encode::encode (@_), success => 1);
}
sub _decoder ($@) {
  no strict 'refs';
  my $p = shift;
  return ($_[1], success => 0)
    if !${'Encode::'.$p.'::VERSION'} && !eval qq{use Encode::$p};
  return (Encode::decode (@_), success => 1);
}
sub _preferred_name ($) {
      my $name = shift;
      my $perlname = lc Encode::resolve_alias ($name);
      $_PerlName2IanaName{$perlname} || $perlname || $name;
}

=head1 EXAMPLE

  use Message::MIME::Charset::Encode;
  $Message::MIME::Charset::Encode::CODE{input} = 'euc-jp';
  $Message::MIME::Charset::Encode::CODE{output} = 'iso-2022-jp';
  require Message::Entity;
  #...

=head1 SEE ALSO

Message::MIME::Charset

Message::Entity

Encode

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
$Date: 2002/08/29 12:30:46 $

=cut

1;
