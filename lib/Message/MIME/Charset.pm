
=head1 NAME

Message::MIME::Charset Perl module

=head1 DESCRIPTION

Perl module for MIME charset.

=cut

## NOTE: You should not require/use other module (even it
##       is part of Message::* Perl Modules) as far as possible,
##       to be able to use this module (M::M::Charset) from
##       other (non-Message::*) modules.

package Message::MIME::Charset;
use strict;
use vars qw(%CHARSET %MSNAME2IANANAME %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.17 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

&_builtin_charset;
sub _builtin_charset () {

$CHARSET{'*DEFAULT'} = {
	preferred_name	=> '',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 1,	## Suitability in use as MIME text/* charset
	#accept_cte	=> [qw/7bit .../],
	cte_7bit_preferred	=> 'quoted-printable',
};
$CHARSET{'*default'} = $CHARSET{'*DEFAULT'};

$CHARSET{'us-ascii'} = {
	preferred_name	=> 'us-ascii',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
};

$CHARSET{'iso-2022-int-1'} = {
	preferred_name	=> 'iso-2022-int-1',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 1,
};

$CHARSET{'unknown-8bit'} = {
	preferred_name	=> 'unknown-8bit',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 1,
	cte_7bit_preferred	=> 'base64',
};

$CHARSET{'x-unknown'} = {
	preferred_name	=> 'x-unknown',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 0,
	cte_7bit_preferred	=> 'base64',
};

$CHARSET{'*undef'} = {
	preferred_name	=> '',
	
	#encoder	=> sub { $_[1] },
	#decoder	=> sub { $_[1] },
	
	mime_text	=> 0,
	cte_7bit_preferred	=> 'base64',
};

}	# /builtin_charset

my %_MINIMUMIZER = (
	'euc-jp'	=> \&_name_euc_japan,
	'euc-jisx0213'	=> \&_name_euc_japan,
	'euc-jisx0213-plane1'	=> \&_name_euc_japan,
	'x-euc-jisx0213-packed'	=> \&_name_euc_japan,
	'x-iso-2022'	=> \&_name_8bit_iso2022,
	'iso-2022-cn'	=> \&_name_8bit_iso2022,
	'iso-2022-cn-ext'	=> \&_name_8bit_iso2022,
	'iso-2022-int-1'	=> \&_name_net_ascii_8bit,
	'iso-2022-jp'	=> \&_name_8bit_iso2022,
	'iso-2022-jp-1'	=> \&_name_8bit_iso2022,
	'iso-2022-jp-2'	=> \&_name_8bit_iso2022,
	'iso-2022-jp-3'	=> \&_name_8bit_iso2022,
	'iso-2022-jp-3-plane1'	=> \&_name_8bit_iso2022,
	'iso-2022-kr'	=> \&_name_8bit_iso2022,
	'iso-8859-1'	=> \&_name_8bit_iso2022,
	jis_x0201	=> \&_name_shift_jis,
	junet	=> \&_name_8bit_iso2022,
	'x-junet8'	=> \&_name_net_ascii_8bit,
	shift_jis	=> \&_name_shift_jis,
	shift_jisx0213	=> \&_name_shift_jis,
	'shift_jisx0213-plane1'	=> \&_name_shift_jis,
	'x-sjis'	=> \&_name_shift_jis,
	'us-ascii'	=> \&_name_net_ascii_8bit,
	'utf-8'	=> \&_name_net_ascii_8bit,
);

my %_IsMimeText;
for (qw(
	adobe-standard-encoding	adobe-symbol-encoding
	big5	big5-eten	big5-hkscs
	cp950
	gbk	gb18030
	euc-jp	euc-jisx0213	euc-kr	euc-tw
	hp-roman8
	hz-gb-2312
	ibm437
	junet	x-junet8	x-iso-2022
	iso-2022-cn	iso-2022-cn-ext
	iso-2022-int-1
	iso-2022-jp	iso-2022-jp-1	iso-2022-jp-2	iso-2022-jp-3
	x-iso2022jp-cp932
	iso-2022-kr
	iso-8859-1	iso-8859-2	iso-8859-3
	iso-8859-4	iso-8859-5	iso-8859-6
	iso-8859-7	iso-8859-8	iso-8859-9
	iso-8859-10	iso-8859-12	iso-8859-13
	iso-8859-14	iso-8859-15	iso-8859-16
	jis_encoding
	koi8-r	koi8-u
	x-mac-arabic	x-mac-centralroman	x-mac-cyrillic	x-mac-greek
	x-mac-hebrew	x-mac-icelandic	macintosh	x-mac-turkish
	x-mac-ukrainian	x-mac-chinesesimp	x-mac-japanese	x-mac-korean
	shift_jis	shift_jisx0213	x-sjis
	tis-620
	unicode-1-1-utf-7	unicode-1-1-utf-8
	unicode-2-0-utf-7	unicode-2-0-utf-8
	utf-7	utf-8	utf-9
	viscii
	windows-1250	windows-1251	windows-1252	windows-1253
	windows-1254	windows-1255	windows-1256	windows-1257
	windows-1258	windows-31j	windows-949
)) { $_IsMimeText{$_} = 1 }

%MSNAME2IANANAME = (
	'iso-2022-jp'	=> 'x-iso2022jp-cp932',
	'ks_c_5601-1987'	=> 'windows-949',
);

sub make_charset ($%) {
  my $name = shift;
  return unless $name;	## Note: charset "0" is not supported.
  my %definition = @_;
  
  $definition{preferred_name} ||= $name;
  if ($definition{preferred_name} ne $name
      && ref $CHARSET{$definition{preferred_name}}) {
  ## New charset is an alias of defined charset,
    $CHARSET{$name} = $CHARSET{$definition{preferred_name}};
    return;
  } elsif ($definition{alias_of} && ref $CHARSET{$definition{alias_of}}) {
  ## New charset is an alias of defined charset,
    $CHARSET{$name} = $CHARSET{$definition{alias_of}};
    return;
  }
  $CHARSET{$name} = \%definition;
  
  ## Set default values
  #$definition{encoder} ||= sub { $_[1] };
  #$definition{decoder} ||= sub { $_[1] };

  $definition{mime_text} = 0 unless defined $definition{mime_text};
  $definition{cte_7bit_preferred} = 'base64'
    unless defined $definition{cte_7bit_preferred};
}

sub encode ($$) {
  my ($charset, $s) = (lc shift, shift);
  my $c = ref $CHARSET{$charset}->{encoder}? $charset: '*undef';
  if (ref $CHARSET{$c}->{encoder}) {
    my ($t, %r) = &{$CHARSET{$c}->{encoder}} ($charset, $s);
    unless (defined $r{success}) {
      $r{success} = 1;
    }
    return ($t, %r);
  }
  ($s, success => 0);
}

sub decode ($$) {
  my ($charset, $s) = (lc shift, shift);
  my $c = ref $CHARSET{$charset}->{decoder}? $charset: '*undef';
  if (ref $CHARSET{$c}->{decoder}) {
    my ($t, %r) = &{$CHARSET{$c}->{decoder}} ($charset, $s);
    unless (defined $r{success}) {
      $r{success} = 1;
    }
    return ($t, %r);
  }
  ($s, success => 0);
}

sub name_normalize ($) {
  my $name = lc shift;
  if (ref $CHARSET{$name}->{preferred_name} eq 'CODE') {
    return &{ $CHARSET{$name}->{preferred_name} } ($name);
  } elsif ($CHARSET{$name}->{preferred_name}) {
    return $CHARSET{$name}->{preferred_name};
  } elsif (ref $CHARSET{'*undef'}->{preferred_name} eq 'CODE') {
    return &{ $CHARSET{'*undef'}->{preferred_name} } ($name);
  }
  $name;
}

sub name_minimumize ($$) {
  require Message::MIME::Charset::MinName;
  my ($charset, $s) = (lc shift, shift);
  if (ref $CHARSET{$charset}->{name_minimumizer} eq 'CODE') {
    return &{$CHARSET{$charset}->{name_minimumizer}} ($charset, $s);
  } elsif (ref $Message::MIME::Charset::MinName::MIN{$charset}) {
    return &{$Message::MIME::Charset::MinName::MIN{$charset}} ($charset, $s);
  } elsif (ref $_MINIMUMIZER{$charset}) {
    return &{$_MINIMUMIZER{$charset}} ($charset, $s);
  } elsif (ref $CHARSET{'*undef'}->{name_minimumizer} eq 'CODE') {
    return &{$CHARSET{'*undef'}->{name_minimumizer}} ($charset, $s);
  }
  (charset => $charset);
}

sub msname2iananame ($) {
  my $mscharset = shift;
  $MSNAME2IANANAME{$mscharset} || $mscharset;
}

sub _name_7bit_iso2022 ($$) {shift;
  my $s = shift;
  if ($s =~ /[\x0E\x0F\x1B]/) {
    return (charset => 'iso-2022-jp')
      unless $s =~ /\x1B[^\x24\x28]
                   |\x1B\x24[^\x40B]
                   |\x1B\x28[^BJ]
                   |\x0E|\x0F/x;
    return (charset => 'iso-2022-jp-1')
      unless $s =~ /\x1B[^\x24\x28]
                   |\x1B\x24[^\x40B\x28]
                   |\x1B\x24\x28[^D]
                   |\x1B\x28[^BJ]
                   |\x0E|\x0F/x;
    return (charset => 'iso-2022-jp-3-plane1')
      unless $s =~ /\x1B[^\x24\x28]
                   |\x1B\x24[^\x28]	#[^B\x28]
                   |\x1B\x24\x28[^O]
                   |\x1B\x28[^B]
                   |\x0E|\x0F/x;
    return (charset => 'iso-2022-jp-3')
      unless $s =~ /\x1B[^\x24\x28]
                   |\x1B\x24[^\x28]	#[^B\x28]
                   |\x1B\x24\x28[^OP]
                   |\x1B\x28[^B]
                   |\x0E|\x0F/x;
    return (charset => 'iso-2022-kr')
      unless $s =~ /\x1B[^\x24]
                   |\x1B\x24[^\x29]
                   |\x1B\x24\x29[^C]/x;
    return (charset => 'iso-2022-jp-2')
      unless $s =~ /\x1B[^\x24\x28\x2E\x4E]
                   |\x1B\x24[^\x40AB\x28]
                   |\x1B\x24\x28[^CD]
                   |\x1B\x28[^BJ]
                   |\x1B\x2E[^AF]
                   |\x0E|\x0F/x;
    return (charset => 'iso-2022-cn')
      unless $s =~ /\x1B[^\x4E\x24]
                   |\x1B\x24[^\x29\x2A]
                   |\x1B\x24\x29[^AG]
                   |\x1B\x24\x2A[^H]/x;
    return (charset => 'iso-2022-cn-ext')
      unless $s =~ /\x1B[^\x4E\x4F\x24]
                   |\x1B\x24[^\x29\x2A]
                   |\x1B\x24\x29[^AEG]
                   |\x1B\x24\x2A[^HIJKLM]/x;
    return (charset => 'iso-2022-int-1')
      unless $s =~ /\x1B[^\x24\x28\x2D]
                   |\x1B\x24[^\x40AB\x28\x29]
                   |\x1B\x24\x28[^DGH]
                   |\x1B\x24\x29[^C]
                   |\x1B\x28[^BJ]
                   |\x1B\x2D[^AF]/x;
    return (charset => 'junet')
      unless $s =~ /\x1B[^\x24\x28\x2C]
                   |\x1B\x24[^\x28\x2C\x40-\x42]
                   |\x1B\x24[\x28\x2C][^\x20-\x7E]
                   |\x1B\x24[\x28\x2C][\x20-\x2F]+[^\x30-\x7E]
                   |\x1B[\x28\x2C][^\x20-\x7E]
                   |\x1B[\x28\x2C][\x20-\x2F]+[^\x30-\x7E]
                   |\x0E|\x0F/x;
    return (charset => 'x-iso-2022');
  } else {
    return (charset => 'us-ascii');
  }
}

sub _name_net_ascii_8bit ($) {
  my $name = shift; my $s = shift;
  return (charset => 'us-ascii') unless $s =~ /[\x1B\x0E\x0F\x80-\xFF]/;
  if ($s =~ /[\x80-\xFF]/) {
    if ($s =~ /[\xC0-\xFD][\x80-\xBF]*[\x80-\x8F]/) {
      if ($s =~ /\x1B/) {
        return (charset => 'x-junet8');	## junet + UTF-8
      } else {
        return (charset => 'utf-8');
      }
    } elsif ($s =~ /\x1B/) {
      return (charset => 'x-iso-2022');	## 8bit ISO 2022
    } else {
      return (charset => 'iso-8859-1');
    }
  } else {	## 7bit ISO 2022
    return _name_7bit_iso2022 ($name, $s);
  }
}

sub _name_8bit_iso2022 ($$) {
  my $name = shift; my $s = shift;
  return (charset => 'us-ascii') unless $s =~ /[\x1B\x0E\x0F\x80-\xFF]/;
  if ($s =~ /[\x80-\xFF]/) {
    if ($s =~ /\x1B/) {
      return (charset => 'x-iso-2022');	## 8bit ISO 2022
    } else {
      return (charset => 'iso-8859-1');
    }
  } else {	## 7bit ISO 2022
    return _name_7bit_iso2022 ($name, $s);
  }
}

## Not completed.
## TODO: gb18030, cn-gb-12345
## TODO: _name_euc_gbf (cn-gb-12345, gb2312)
sub _name_euc_gb ($$) {
  my $name = shift; my $s = shift;
  if ($s =~ /[\x80-\xFF]/) {
    if ($s =~ /
                  (?:\G|[\x00-\x3F\x7F\x80\xFF])
                  (?:[\xA1-\xA9\xB0-\xFE][\xA1-\xFE]
                    |[\x40-\x7E])*
        (?:
          [\x81-\xA0\xAA-\xAF][\x40-\xFE]
         |[\xA1-\xFE][\x40-\xA0]
        )
      /x) {
      (charset => 'gbk');
    } elsif ($s =~ /
        (?:\xA2[\xA1-\xAA]
          |\xA6[\xE0-\xF5]
          |\xA8[\xBB-\xC0]
        )
          (?=(?:[\xA1-\xFE][\xA1-\xFE])*(?:[\x00-\xA0\xFF]|\z))
      /x) {
      (charset => 'gbk');
    } elsif ($s =~ /
        (?:\xA3\xE7|\xA7[\xDD-\xF2]
          |\xA8[\xBB-\xC0]
          |[\xAA-\xAF\xF8-\xFE][\xA1-\xFE]
        )
          (?=(?:[\xA1-\xFE][\xA1-\xFE])*(?:[\x00-\xA0\xFF]|\z))
      /x) {
      (charset => 'cn-gb-isoir165', 'charset-edition' => 1992);
    } elsif ($s =~ /\xEF\xF1	## Typo bug of GB 2312
          (?=(?:[\xA1-\xFE][\xA1-\xFE])*(?:[\x00-\xA0\xFF]|\z))
      /x) {
      (charset => 'gb2312');
    } else {
      (charset => 'gb2312', 'charset-edition' => 1980);
    }
  } elsif ($s =~ /[\x0E\x0F]/) {
    (charset => 'gb2312');	## Actually, this is not "gb2312"
  } else {
    _name_7bit_iso2022 ($name, $s);
  }
}

sub _name_euc_japan ($$) {
  my $name = shift; my $s = shift;
  if ($s =~ /[\x80-\xFF]/) {
    if ($s =~ /\x8F[\xA1\xA3-\xA5\xA8\xAC-\xAF\xEE-\xFE][\xA1-\xFE]/) {
      if ($s =~ /\x8F[\xA2\xA6\xA7\xA9-\xAB\xB0-\xED][\xA1-\xFE]/) {
      ## JIS X 0213 plane 2 + JIS X 0212
        (charset => 'x-euc-jisx0213-packed');
      } else {
        (charset => 'euc-jisx0213');
      }
    } elsif ($s =~ m{(?<![\x8E\x8F])	## Not G2/G3 character
                    (?:	## JIS X 0213:2000
                       [\xA9-\xAF\xF5-\xFE][\xA1-\xFE]
                      |\xA2[\xAF-\xB9\xC2-\xC9\xD1-\xDB\xE9-\xF1\xFA-\xFD]
                      |\xA3[\xA1-\xAF\xBA-\xC0\xDB-\xE0\xFB-\xFE]
                      |\xA4[\xF4-\xFE]|\xA5[\xF7-\xFE]
                      |\xA6[\xB9-\xC0\xD9-\xFE]|\xA7[\xC2-\xD0\xF2-\xFE]
                      |\xA8[\xC1-\xFE]|\xCF[\xD4-\xFE]|\xF4[\xA7-\xFE]
                    )
                    (?=(?:[\xA1-\xFE][\xA1-\xFE])*(?:[\x00-\xA0\xFF]|\z))}x) {
      if ($s =~ /\x8F/) {	## JIS X 0213 plane 1 + JIS X 0212
        (charset => 'x-euc-jisx0213-packed');
      } else {
        (charset => 'euc-jisx0213-plane1');
      }
    } else {
      (charset => 'euc-jp');
    }
  } elsif ($s =~ /\x0E|\x0F|\x1B[\x4E\x4F]/) {
    (charset => 'euc-jisx0213');	## Actually, this is not euc-japan
  } else {
    _name_7bit_iso2022 ($name, $s);
  }
}

sub _name_shift_jis ($$) {
  my $name = shift; my $s = shift;
  if ($s =~ /[\x80-\xFF]/) {
    if ($s =~ /[\x0E\x0F\x1B]/) {
      (charset => 'x-sjis');
    } elsif ($s =~ /
                  (?:\G|[\x00-\x3F\x7F])
                  (?:[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]
                    |[\x40-\x7E\xA1-\xDF])*
               [\xF0-\xFC][\x40-\x7E\x80-\xFC]
      /x) {
      (charset => 'shift_jisx0213');
    } elsif ($s =~ /
                  (?:\G|[\x00-\x3F\x7F])
                  (?:[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]
                    |[\x40-\x7E\xA1-\xDF])*
              (?:
               [\x85-\x87\xEB-\xEF][\x40-\x7E\x80-\xFC]
              |\x81[\xAD-\xB7\xC0-\xC7\xCF-\xD9\xE9-\xEF\xF8-\xFB]
              |\x82[\x40-\x4E\x59-\x5F\x7A-\x80\x9B-\x9E\xF2-\xFC]
              |\x83[\x97-\x9E\xB7-\xBE\xD7-\xFC]
              |\x84[\x61-\x6F\x72-\x9E\xBF-\xFC]
              |\x88[\x40-\x9E]|\x98[\x73-\x9E]|\xEA[\xA5-\xFC]
              )
    /x) {
      (charset => 'shift_jisx0213-plane1');
    } else {
      (charset => 'shift_jis');
    }
  } elsif ($s =~ /[\x5C\x7E]/) {
    if ($s =~ /\x1B\x0E\x0F/) {
      (charset => 'x-sjis');	## ISO 2022 with implied "ESC ( J"
      	## BUG: "ESC ( B foobar\aaa ESC ( J aiueo" also matchs this
    } else {
      (charset => 'jis_x0201');
    }
  } else {
    _name_7bit_iso2022 ($name, $s);
  }
}

sub _utf8_on ($) {
  Encode::_utf8_on ($_[0]) if $Encode::VERSION;
}
sub _utf8_off ($) {
  Encode::_utf8_off ($_[0]) if $Encode::VERSION;
}

sub is_mime_text ($) {
  my $name = lc shift;
  if (ref $CHARSET{$name}->{mime_text} eq 'CODE') {
    return &{ $CHARSET{$name}->{mime_text} } ($name);
  } elsif (defined $CHARSET{$name}->{mime_text}) {
    return $CHARSET{$name}->{mime_text};
  } elsif (defined $_IsMimeText{$name}) {
    return $_IsMimeText{$name};
  } elsif (ref $CHARSET{'*undef'}->{mime_text} eq 'CODE') {
    return &{ $CHARSET{'*undef'}->{mime_text} } ($name);
  }
  0;
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
$Date: 2002/08/18 06:22:36 $

=cut

1;
