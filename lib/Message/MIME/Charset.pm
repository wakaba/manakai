
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
use vars qw(%CHARSET %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

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
	
	mime_text	=> 0,
	cte_7bit_preferred	=> 'base64',
};
$CHARSET{'x-unknown'} = $CHARSET{'unknown-8bit'};

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
	'iso-10646-j-1'	=> \&_name_utf16be,
	'iso-10646-ucs-2'	=> \&_name_utf16be,
	'iso-10646-ucs-4'	=> \&_name_utf32be,
	'iso-10646-ucs-basic'	=> \&_name_utf16be,
	'iso-10646-unicode-latin1'	=> \&_name_utf16be,
	jis_x0201	=> \&_name_shift_jis,
	junet	=> \&_name_8bit_iso2022,
	'x-junet8'	=> \&_name_net_ascii_8bit,
	shift_jis	=> \&_name_shift_jis,
	shift_jisx0213	=> \&_name_shift_jis,
	'shift_jisx0213-plane1'	=> \&_name_shift_jis,
	'x-sjis'	=> \&_name_shift_jis,
	'us-ascii'	=> \&_name_net_ascii_8bit,
	'utf-8'	=> \&_name_net_ascii_8bit,
	'utf-16be'	=> \&_name_utf16be,
	'utf-32be'	=> \&_name_utf32be,
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
  if (ref $CHARSET{$charset}->{encoder}) {
    return (&{$CHARSET{$charset}->{encoder}} ($charset, $s), success => 1);
  }
  ($s, success => 0);
}

sub decode ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $CHARSET{$charset}->{decoder}) {
    return (&{$CHARSET{$charset}->{decoder}} ($charset, $s), 1);
  }
  ($s, 0);
}

sub name_normalize ($) {
  my $name = lc shift;
  $CHARSET{$name}->{preferred_name} || $name;
}

sub name_minimumize ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $CHARSET{$charset}->{name_minimumizer} eq 'CODE') {
    return &{$CHARSET{$charset}->{name_minimumizer}} ($charset, $s);
  } elsif (ref $_MINIMUMIZER{$charset}) {
    return &{$_MINIMUMIZER{$charset}} ($charset, $s);
  }
  (charset => $charset);
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

sub _name_utf16be ($$) {
  shift; my $s = shift;
  if ($s =~ /[\xD8-\xDB][\x00-\xFF][\xDC-\xDF][\x00-\xFF]
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
    (charset => 'utf-16be');
  } elsif ($s =~ /[\x01-\xFF][\x00-\xFF]
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
    if ($s =~ /([^\x00\x03\x04\x23\x25\x30\xFE\xFF]
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
  } elsif ($s =~ /\x00[\x80-\xFF]
             (?=(?:[\x00-\xFF][\x00-\xFF])*\z)/sx) {
    (charset => 'iso-10646-unicode-latin1');
  } else {
    (charset => 'iso-10646-ucs-basic');
  }
}

sub _name_utf32be ($$) {
  shift; my $s = shift;
  if ($s =~ /
    ([\x01-\x7F][\x00-\xFF]{3}
    |\x00[\x11-\xFF][\x00-\xFF][\x00-\xFF])
             (?=(?:[\x00-\xFF]{4})*\z)/sx) {
    (charset => 'iso-10646-ucs-4');
  } else {
    (charset => 'utf-32be');
  }
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
$Date: 2002/07/19 11:49:46 $

=cut

1;
