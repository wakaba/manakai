package Message::Charset::Info;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub UNREGISTERED_CHARSET_NAME () { 0b1 }
sub REGISTERED_CHARSET_NAME () { 0b10 }
sub PRIMARY_CHARSET_NAME () { 0b100 | REGISTERED_CHARSET_NAME }
    ## "Name:" field for IANA names
sub PREFERRED_CHARSET_NAME () { 0b1000 | REGISTERED_CHARSET_NAME }
    ## "preferred MIME name" for IANA names

## iana_names
## is_html_ascii_superset: "superset of US-ASCII (specifically, ANSI_X3.4-1968)
##     for bytes in the range 0x09 - 0x0D, 0x20, 0x21, 0x22, 0x26, 0x27,
##     0x2C - 0x3F, 0x41 - 0x5A, and 0x61 - 0x7A" [HTML5]
## is_ebcdic_based

## ISSUE: Shift_JIS is a superset of US-ASCII?  ISO-2022-JP is?
## ISSUE: 0x5F (_) should be added to the range?

my $Charset;

our $IANACharset;

$Charset->{'us-ascii'}
= $IANACharset->{'ansi_x3.4-1968'}
= $IANACharset->{'iso-ir-6'}
= $IANACharset->{'ansi_x3.4-1986'}
= $IANACharset->{'iso_646.irv:1991'}
= $IANACharset->{'ascii'}
= $IANACharset->{'iso646-us'}
= $IANACharset->{'us-ascii'}
= $IANACharset->{'us'}
= $IANACharset->{'ibm367'}
= $IANACharset->{'cp367'}
= $IANACharset->{'csascii'}
= {
  iana_names => {
    'ansi_x3.4-1968' => PRIMARY_CHARSET_NAME,
    'iso-ir-6' => REGISTERED_CHARSET_NAME,
    'ansi_x3.4-1986' => REGISTERED_CHARSET_NAME,
    'iso_646.irv:1991' => REGISTERED_CHARSET_NAME,
    'ascii' => REGISTERED_CHARSET_NAME,
    'iso646-us' => REGISTERED_CHARSET_NAME,
    'us-ascii' => PREFERRED_CHARSET_NAME,
    'us' => REGISTERED_CHARSET_NAME,
    'ibm367' => REGISTERED_CHARSET_NAME,
    'cp367' => REGISTERED_CHARSET_NAME,
    'csascii' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-1'}
= $IANACharset->{'iso_8859-1:1987'}
= $IANACharset->{'iso-ir-100'}
= $IANACharset->{'iso_8859-1'}
= $IANACharset->{'iso-8859-1'}
= $IANACharset->{'latin1'}
= $IANACharset->{'l1'}
= $IANACharset->{'ibm819'}
= $IANACharset->{'cp819'}
= $IANACharset->{'csisolatin1'}
= {
  iana_names => {
    'iso_8859-1:1987' => PRIMARY_CHARSET_NAME,
    'iso-ir-100' => REGISTERED_CHARSET_NAME,
    'iso_8859-1' => REGISTERED_CHARSET_NAME,
    'iso-8859-1' => PREFERRED_CHARSET_NAME,
    'latin1' => REGISTERED_CHARSET_NAME,
    'l1' => REGISTERED_CHARSET_NAME,
    'ibm819' => REGISTERED_CHARSET_NAME,
    'cp819' => REGISTERED_CHARSET_NAME,
    'csisolatin1' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

## TODO: other names..

$Charset->{'shift_jis'}
= $IANACharset->{'shift_jis'}
= $IANACharset->{'ms_kanji'}
= $IANACharset->{'csshiftjis'}
= {
  iana_names => {
    'shift_jis' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME,
    'ms_kanji' => REGISTERED_CHARSET_NAME,
    'csshiftjis' => REGISTERED_CHARSET_NAME,
  },
};

$Charset->{'euc-jp'}
= $IANACharset->{'extended_unix_code_packed_format_for_japanese'}
= $IANACharset->{'cseucpkdfmtjapanese'}
= $IANACharset->{'euc-jp'}
= {
  iana_names => {
    'extended_unix_code_packed_format_for_japanese' => PRIMARY_CHARSET_NAME,
    'cseucpkdfmtjapanese' => REGISTERED_CHARSET_NAME,
    'euc-jp' => PREFERRED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

## TODO: ...

$Charset->{'iso-2022-jp'}
= $IANACharset->{'iso-2022-jp'}
= $IANACharset->{'csiso2022jp'}
= {
  iana_names => {
    'iso-2022-jp' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME,
    'csiso2022jp' => REGISTERED_CHARSET_NAME,
  },
};

## TODO: ...

$Charset->{'utf-8'}
= $IANACharset->{'utf-8'}
= {
  iana_names => {
    'utf-8' => PRIMARY_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

## TODO: ...

$Charset->{'utf-16be'}
= $IANACharset->{'utf-16be'}
= {
  iana_names => {
    'utf-16be' => PRIMARY_CHARSET_NAME,
  },
};

$Charset->{'utf-16le'}
= $IANACharset->{'utf-16le'}
= {
  iana_names => {
    'utf-16le' => PRIMARY_CHARSET_NAME,
  },
};

$Charset->{'utf-16'}
= $IANACharset->{'utf-16'}
= {
  iana_names => {
    'utf-16' => PRIMARY_CHARSET_NAME,
  },
};

## TODO: ...

$Charset->{'windows-1252'}
= $IANACharset->{'windows-1252'}
= {
  iana_names => {
    'windows-1252' => PRIMARY_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

## TODO: ...

sub is_syntactically_iana_charset_name ($) {
  my $name = shift;
  return $name =~ /\A[\x20-\x7E]{1,40}\z/;
} # is_suntactically_valid_iana_charset_name

1;
## $Date: 2007/11/18 11:08:40 $

