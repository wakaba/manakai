
=head1 NAME

Message::MIME::Charset::Jcode --- Japanese Coding Systems Support
with jcode.pl and/or Jcode.pm for Message::* Perl Modules

=head1 DESCRIPTION

Message::* therselves don't convert coding systems of parts of
messages, but have mechanism to define to call external functions.
This module provides such macros for Japanese coding systems,
supported by jcode.pl, Jcode.pm and/or other modules.

=head1 USAGE

  use Message::MIME::Charset::Jcode $module_name;

where $module_name is name of module.  List of it is shown below:

=over 4

=item 'jcode.pl'

jcode.pl L<lt>http://srekcah.org/jcode/>

=item 'Jcode' or 'Jcode.pm'

Jcode.pm L<lt>http://openlab.ring.gr.jp/Jcode/>

=item 'Kconv' or 'Kconv.pm'

Kconv.pm L<lt>ftp://ftp.intec.co.jp/pub/utils/>

=item 'NKF' or 'NKF.pm'

Network Kanji Filter (Perl module version)
L<lt>http://bw-www.ie.u-ryukyu.ac.jp/~kono/software.html>

=item 'Unicode::Japanese' or 'Unicode::Japanese.pm'

Unicode::Japanese L<lt>http://tech.ymirlink.co.jp/>

=back

When this module is C<use>d multiple times with different
conversion module name, latest one is used.  For example,

  use Message::MIME::Charset::Jcode 'jcode.pl';
  use Message::MIME::Charset::Jcode 'Jcode';

results to instruct to use Jcode.pm.

  use Message::MIME::Charset::Jcode 'Jcode';
  use Message::MIME::Charset::Jcode 'jcode.pl';

This example code leads a bit different result.  Jcode.pm can 
treat UTF-8, but jcode.pl cann't.  So convertion from/to UTF-8
is done by Jcode.pm.  But between other coding systems such as EUC-JP
E<lt>-E<gt> Shift JIS, jcode.pl is used.

Note that this module does not support Encode modules available
with Perl 5.7 or later.  It will be supported by
Message::MIME::Charset::Encode.

=cut

package Message::MIME::Charset::Jcode;
use strict;
use vars qw(%CODE $VERSION);
$VERSION=do{my @r=(q$Revision: 1.14 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::MIME::Charset;

=head1 CODING SYSTEMS NAMES

These names can be used as the value of L</VARIABLES>.
(These name are NOT same as MIME charset name, which is acutually
written down in message header fields.)

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

UTF-8.  (MIME: UTF-8)  This coding system is not supported by jcode.pl
and NKF.pm.

=item C<ucs2>

UCS-2 (or Unicode without surrogate pairs) big endian (network
byte order).  This coding system is not supported by jcode.pl
and NKF.pm.

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

$CODE{internal} = 'euc';	## default: 'euc' / 'utf8' (Unicode::Japanese)
$CODE{input} = '';	## default: auto-detect
$CODE{output} = 'jis';	## default: 'jis'

sub import ($;%) {
  shift;
  for (@_) {
    if ($_ eq 'jcode.pl') {
      require 'jcode.pl';
      Message::MIME::Charset::make_charset ('*default' =>
        encoder	=> sub { jcode::to ($CODE{output}, __jcode_pl_fw_to_hw ($_[1]), $CODE{internal}) },
        decoder	=> sub { jcode::to ($CODE{internal}, $_[1], $CODE{input}) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub {
          my $s = jcode::jis (__jcode_pl_fw_to_hw ($_[1]), $CODE{internal});
          ($s, Message::MIME::Charset::_name_8bit_iso2022 ('iso-2022-jp', $s));
        },
        decoder	=> sub {
          $CODE{internal} eq 'euc' ?
            __jcode_pl_fw_to_hw (jcode::to ('euc', $_[1], 'jis'))
          :
            jcode::to ($CODE{internal}, $_[1], 'jis')
        },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub {
          my $s = jcode::euc ($_[1], $CODE{internal});
          (__jcode_pl_fw_to_hw ($s),
           Message::MIME::Charset::_name_euc_japan ('euc-jp' => $s));
        },
        decoder	=> sub {
          $CODE{internal} eq 'euc' ?
            __jcode_pl_fw_to_hw (jcode::to ('euc', $_[1], 'euc'))
          :
            jcode::to ($CODE{internal}, $_[1], 'euc')
        },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub {
          my $s = jcode::sjis (__jcode_pl_fw_to_hw ($_[1]), $CODE{internal});
          ($s, Message::MIME::Charset::_name_shift_jis (shift_jis => $s));
        },
        decoder	=> sub {
          $CODE{internal} eq 'euc' ?
            __jcode_pl_fw_to_hw (jcode::to ('euc', $_[1], 'sjis'))
          :
            jcode::to ($CODE{internal}, $_[1], 'sjis')
        },
        mime_text	=> 1,
      );
    } elsif ($_ eq 'Jcode' || $_ eq 'Jcode.pm') {
      require Jcode;
      Message::MIME::Charset::make_charset ('*default' =>
        encoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{output}, $CODE{internal}); $s },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, $CODE{input}); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub {
          my $s = Jcode->new ($_[1], $CODE{internal})->jis; ## ->iso_2022_jp;
          ($s, Message::MIME::Charset::_name_8bit_iso2022 ('iso-2022-jp' => $s));
        },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'jis'); $s },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub {
          my $s = Jcode->new ($_[1], $CODE{internal})->euc;
          ($s, Message::MIME::Charset::_name_euc_japan ('euc-jp' => $s));
        },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'euc'); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub {
          my $s = Jcode->new ($_[1], $CODE{internal})->sjis;
          ($s, Message::MIME::Charset::_name_shift_jis (shift_jis => $s));
        },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'sjis'); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('utf-8' =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->utf8 },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'utf8'); $s },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-10646-ucs-2' =>
        encoder	=> sub { Jcode->new ($_[1], $CODE{internal})->ucs2 },
        decoder	=> sub { my $s = $_[1]; Jcode::convert (\$s, $CODE{internal}, 'ucs2'); $s },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('ucs-2be' => alias_of => 'iso-10646-ucs-2');
      Message::MIME::Charset::make_charset ('ucs-2' => alias_of => 'ucs-2be');
      Message::MIME::Charset::make_charset ('utf-16' => alias_of => 'ucs-2');
      Message::MIME::Charset::make_charset ('utf-16be' => alias_of => 'ucs-2be');
    } elsif ($_ eq 'NKF' || $_ eq 'NKF.pm') {
      unless ($NKF::VERSION) {
        eval q{ use NKF } or Carp::croak ("Message::MIME::Charset::Jcode: NKF: $@");
      }
      Message::MIME::Charset::make_charset ('*default' =>
        encoder	=> sub { nkf ( "-".    substr ($CODE{output},   0, 1)
                            . " -".uc (substr ($CODE{internal}, 0, 1)), $_[1] ) },
        decoder	=> sub { nkf ( "-".    substr ($CODE{internal}, 0, 1)
                            . " -".uc (substr ($CODE{input},    0, 1)), $_[1] ) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub {
          my $s = nkf ( "-j -".uc (substr ($CODE{internal}, 0, 1)), $_[1] );
          ($s, Message::MIME::Charset::_name_8bit_iso2022 ('iso-2022-jp' => $s));
        },
        decoder	=> sub { nkf ( "-". substr ($CODE{internal}, 0, 1) . " -J", $_[1] ) },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub {
          my $s = nkf ( "-e -".uc (substr ($CODE{internal}, 0, 1)), $_[1] );
          ($s, Message::MIME::Charset::_name_euc_japan ('euc-jp' => $s));
        },
        decoder	=> sub { nkf ( "-". substr ($CODE{internal}, 0, 1) . " -E", $_[1] ) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub {
          my $s = nkf ( "-s -".uc (substr ($CODE{internal}, 0, 1)), $_[1] );
          ($s, Message::MIME::Charset::_name_shift_jis (shift_jis => $s));
        },
        decoder	=> sub { nkf ( "-". substr ($CODE{internal}, 0, 1) . " -S", $_[1] ) },
        mime_text	=> 1,
      );
    } elsif ($_ eq 'Unicode::Japanese' || $_ eq 'Unicode::Japanese.pm') {
      require Unicode::Japanese;
      $CODE{internal} = 'utf8';
      Message::MIME::Charset::make_charset ('*default' =>
        ## Very tricky:-)
        encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->conv ($CODE{output}) },
        decoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{input} || 'auto')->conv ($CODE{internal}) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub {
          my $s = Unicode::Japanese->new ($_[1], $CODE{internal})->jis;
          ($s, Message::MIME::Charset::_name_8bit_iso2022 ('iso-2022-jp' => $s));
        },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'jis')->conv ($CODE{internal}) },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub {
          my $s = Unicode::Japanese->new ($_[1], $CODE{internal})->euc;
          ($s, Message::MIME::Charset::_name_euc_japan ('euc-jp' => $s));
        },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'euc')->conv ($CODE{internal}) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub {
          my $s = Unicode::Japanese->new ($_[1], $CODE{internal})->sjis;
          ($s, Message::MIME::Charset::_name_shift_jis (shift_jis => $s));
        },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'sjis')->conv ($CODE{internal}) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('utf-8' =>
        encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->utf8 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf8')->conv ($CODE{internal}) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('ucs-2' =>
        encoder	=> sub { "\xFF\xFE".Unicode::Japanese->new ($_[1], $CODE{internal})->ucs2 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'ucs2')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('iso-10646-ucs-2' =>
        encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->ucs2 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'ucs2')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('ucs-2be' => alias_of => 'iso-10646-ucs-2');
      Message::MIME::Charset::make_charset ('utf-16' =>
        encoder	=> sub { "\xFF\xFE".Unicode::Japanese->new ($_[1], $CODE{internal})->utf16 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf16')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('utf-16be' =>
        encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->utf16 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf16-ge')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('utf-16le' =>
        #encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->utf16 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf16-le')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('ucs-2le' => alias_of => 'utf-16le');
      Message::MIME::Charset::make_charset ('utf-32' =>
        encoder	=> sub { "\x00\x00\xFF\xFE".Unicode::Japanese->new ($_[1], $CODE{internal})->ucs4 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf32')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('iso-10646-ucs-4' =>
        encoder	=> sub { "\x00\x00\xFF\xFE".Unicode::Japanese->new ($_[1], $CODE{internal})->ucs4 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'ucs4')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('ucs-4' => alias_of => 'iso-10646-ucs-4');
      Message::MIME::Charset::make_charset ('utf-32be' =>
        encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->ucs4 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf32-ge')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('ucs-4be' =>
        encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->ucs4 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'ucs4')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('utf-32le' =>
        #encoder	=> sub { Unicode::Japanese->new ($_[1], $CODE{internal})->utf32 },
        decoder	=> sub { Unicode::Japanese->new ($_[1], 'utf32-le')->conv ($CODE{internal}) },
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('ucs-4le' => alias_of => 'utf-32le');
    } elsif ($_ eq 'Kconv' || $_ eq 'Kconv.pm') {
      unless ($Kconv::VERSION) {
        eval q{ require Kconv } or Carp::croak ("Message::MIME::Charset::Jcode: Kconv: $@");
      }
      Message::MIME::Charset::make_charset ('*default' =>
        encoder	=> sub { kconv ($_[1], __kconv_code_name ($CODE{output}), 
                                       __kconv_code_name ($CODE{internal})) },
        decoder	=> sub { kconv ($_[1], __kconv_code_name ($CODE{internal}), 
                                       __kconv_code_name ($CODE{input})) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset ('iso-2022-jp' =>
        encoder	=> sub {
          my $s = kconv ($_[1], &_JIS, __kconv_code_name ($CODE{internal}));
          ($s, Message::MIME::Charset::_name_8bit_iso2022 ('iso-2022-jp' => $s));
        },
        decoder	=> sub { kconv ($_[1], __kconv_code_name ($CODE{internal}), &_JIS) },
        mime_text	=> 1,
        cte_7bit_preferred	=> 'base64',
      );
      Message::MIME::Charset::make_charset ('euc-jp' =>
        encoder	=> sub {
          my $s = kconv ($_[1], &_EUC, __kconv_code_name ($CODE{internal}));
          ($s, Message::MIME::Charset::_name_euc_japan ('euc-jp' => $s));
        },
        decoder	=> sub { kconv ($_[1], __kconv_code_name ($CODE{internal}), &_EUC) },
        mime_text	=> 1,
      );
      Message::MIME::Charset::make_charset (shift_jis =>
        encoder	=> sub {
          my $s = kconv ($_[1], &_SJIS, __kconv_code_name ($CODE{internal}));
          ($s, Message::MIME::Charset::_name_shift_jis (shift_jis => $s));
        },
        decoder	=> sub { kconv ($_[1], __kconv_code_name ($CODE{internal}), &_SJIS) },
        mime_text	=> 1,
      );
    } else {
      Carp::croak "Jcode: $_: Module not supported";
    }
    ## Defines common alias names
    Message::MIME::Charset::make_charset (jis => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset (junet => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset ('x-iso-2022-7bit' => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset ('junet-code' => alias_of => 'iso-2022-jp');
    Message::MIME::Charset::make_charset ('x-iso2022jp-cp932' => alias_of => 'iso-2022-jp');	## pseudo ISO-2022-JP of Microsoft CP932
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
    Message::MIME::Charset::make_charset ('x-euc-jisx0213-packed' => alias_of => 'euc-jisx0213');
    Message::MIME::Charset::make_charset (sjis => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset ('shift-jis' => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset ('x-sjis' => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset (shift_jisx0213 => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset ('shift-jisx0213' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset ('x-shift_jisx0213' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset ('x-shift-jisx0213' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset ('shift_jisx0213-plane1' => alias_of => 'shift_jisx0213');
    Message::MIME::Charset::make_charset (jis_x0201 => alias_of => 'shift_jis');
    Message::MIME::Charset::make_charset (x0201 => alias_of => 'jis_x0201');
  }
}

sub unimport ($) {
  for (qw/euc euc-jisx0213 euc-jisx0213-plane1 euc-jp euc_jp iso-2022-jp iso-2022-jp-1 iso-2022-jp-3 iso-2022-jp-3-plane1 iso-10646-ucs-2 iso-10646-ucs-4 jis jis_x0201 junet junet-code shift-jis shift_jis shift-jisx0213 shift_jisx0213 shift_jisx0213-plane1 sjis ucs-2 ucs-2be ucs-2le ucs-4 ucs-4be ucs-4le utf-8 utf-16 utf-16be utf-16le utf-32 utf-32be utf-32le x0201 x-euc x-euc-jisx0213 x-euc-jisx0213-packed x-euc-jisx0213-plane1 x-euc-jp x-iso-2022-7bit x-iso-2022-jp-3 x-shift-jisx0213 x-shift_jisx0213 x-sjis/) {
    delete $Message::MIME::Charset::CHARSET{$_};
  }
  Message::MIME::Charset::make_charset ('*default' =>
    encoder	=> sub { $_[1] },
    decoder	=> sub { $_[1] },
    mime_text	=> 1,
  );
}

sub __jcode_pl_fw_to_hw ($) {
  my $s = shift;
  return $s unless $CODE{internal} eq 'euc';
  jcode::tr(\$s, "\xa3\xb0-\xa3\xb9\xa3\xc1-\xa3\xda\xa3\xe1-\xa3\xfa\xa1\xf5".
                 "\xa1\xa4\xa1\xa5\xa1\xa7\xa1\xa8\xa1\xa9\xa1\xaa\xa1\xae".
                 "\xa1\xb0\xa1\xb2\xa1\xbf\xa1\xc3\xa1\xca\xa1\xcb\xa1\xce".
                 "\xa1\xcf\xa1\xd0\xa1\xd1\xa1\xdc\xa1\xf0\xa1\xf3\xa1\xf4".
                 "\xa1\xf6\xa1\xf7\xa1\xe1\xa2\xaf\xa2\xb0\xa2\xb2\xa2\xb1".
                 "\xa1\xe4\xa1\xe3\xA1\xC0\xA1\xA1" =>
            '0-9A-Za-z&,.:;?!`^_/|()[]{}+$%#*@=\'"~-><\\ ');
  $s;
}

sub __kconv_code_name ($) {
  my $c = shift;
  $c eq 'sjis'? &_SJIS:
  $c eq 'euc' ? &_EUC:
  $c eq 'jis' ? &_JIS:
  &_AUTO;
}

## TODO: UCS support is very confusual, especially its charset name

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
$Date: 2002/12/28 09:07:05 $

=cut

1;
