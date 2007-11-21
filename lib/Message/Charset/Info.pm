package Message::Charset::Info;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub UNREGISTERED_CHARSET_NAME () { 0b1 }
sub REGISTERED_CHARSET_NAME () { 0b10 }
sub PRIMARY_CHARSET_NAME () { 0b100 | REGISTERED_CHARSET_NAME }
    ## "Name:" field for IANA names
sub PREFERRED_CHARSET_NAME () { 0b1000 | REGISTERED_CHARSET_NAME }
    ## "preferred MIME name" for IANA names

## iana_status
sub STATUS_COMMON () { 0b1 }
sub STATUS_LIMITED_USE () { 0b10 }
sub STATUS_OBSOLETE () { 0b100 }

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

$Charset->{'iso-8859-2'}
= $IANACharset->{'iso_8859-2:1987'}
= $IANACharset->{'iso-ir-101'}
= $IANACharset->{'iso_8859-2'}
= $IANACharset->{'iso-8859-2'}
= $IANACharset->{'latin2'}
= $IANACharset->{'l2'}
= $IANACharset->{'csisolatin2'}
= {
  iana_names => {
    'iso_8859-2:1987' => PRIMARY_CHARSET_NAME,
    'iso-ir-101' => REGISTERED_CHARSET_NAME,
    'iso_8859-2' => REGISTERED_CHARSET_NAME,
    'iso-8859-2' => PREFERRED_CHARSET_NAME,
    'latin2' => REGISTERED_CHARSET_NAME,
    'l2' => REGISTERED_CHARSET_NAME,
    'csisolatin2' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-3'}
= $IANACharset->{'iso_8859-3:1988'}
= $IANACharset->{'iso-ir-109'}
= $IANACharset->{'iso_8859-3'}
= $IANACharset->{'iso-8859-3'}
= $IANACharset->{'latin3'}
= $IANACharset->{'l3'}
= $IANACharset->{'csisolatin3'}
= {
  iana_names => {
    'iso_8859-3:1988' => PRIMARY_CHARSET_NAME,
    'iso-ir-109' => REGISTERED_CHARSET_NAME,
    'iso_8859-3' => REGISTERED_CHARSET_NAME,
    'iso-8859-3' => PREFERRED_CHARSET_NAME,
    'latin3' => REGISTERED_CHARSET_NAME,
    'l3' => REGISTERED_CHARSET_NAME,
    'csisolatin3' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-4'}
= $IANACharset->{'iso_8859-4:1988'}
= $IANACharset->{'iso-ir-110'}
= $IANACharset->{'iso_8859-4'}
= $IANACharset->{'iso-8859-4'}
= $IANACharset->{'latin4'}
= $IANACharset->{'l4'}
= $IANACharset->{'csisolatin4'}
= {
  iana_names => {
    'iso_8859-4:1988' => PRIMARY_CHARSET_NAME,
    'iso-ir-110' => REGISTERED_CHARSET_NAME,
    'iso_8859-4' => REGISTERED_CHARSET_NAME,
    'iso-8859-4' => PREFERRED_CHARSET_NAME,
    'latin4' => REGISTERED_CHARSET_NAME,
    'l4' => REGISTERED_CHARSET_NAME,
    'csisolatin4' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-5'}
= $IANACharset->{'iso_8859-5:1988'}
= $IANACharset->{'iso-ir-144'}
= $IANACharset->{'iso_8859-5'}
= $IANACharset->{'iso-8859-5'}
= $IANACharset->{'cyrillic'}
= $IANACharset->{'csisolatincyrillic'}
= {
  iana_names => {
    'iso_8859-5:1988' => PRIMARY_CHARSET_NAME,
    'iso-ir-144' => REGISTERED_CHARSET_NAME,
    'iso_8859-5' => REGISTERED_CHARSET_NAME,
    'iso-8859-5' => PREFERRED_CHARSET_NAME,
    'cyrillic' => REGISTERED_CHARSET_NAME,
    'csisolatincyrillic' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-6'}
= $IANACharset->{'iso_8859-6:1987'}
= $IANACharset->{'iso-ir-127'}
= $IANACharset->{'iso_8859-6'}
= $IANACharset->{'iso-8859-6'}
= $IANACharset->{'ecma-114'}
= $IANACharset->{'asmo-708'}
= $IANACharset->{'arabic'}
= $IANACharset->{'csisolatinarabic'}
= {
  iana_names => {
    'iso_8859-6:1987' => PRIMARY_CHARSET_NAME,
    'iso-ir-127' => REGISTERED_CHARSET_NAME,
    'iso_8859-6' => REGISTERED_CHARSET_NAME,
    'iso-8859-6' => PREFERRED_CHARSET_NAME,
    'ecma-114' => REGISTERED_CHARSET_NAME,
    'asmo-708' => REGISTERED_CHARSET_NAME,
    'arabic' => REGISTERED_CHARSET_NAME,
    'csisolatinarabic' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
      ## NOTE: 3/0..3/9 have different semantics from U+0030..0039,
      ## but have same character names (maybe).
};

$Charset->{'iso-8859-7'}
= $IANACharset->{'iso_8859-7:1987'}
= $IANACharset->{'iso-ir-126'}
= $IANACharset->{'iso_8859-7'}
= $IANACharset->{'iso-8859-7'}
= $IANACharset->{'elot_928'}
= $IANACharset->{'ecma-118'}
= $IANACharset->{'greek'}
= $IANACharset->{'greek8'}
= $IANACharset->{'csisolatingreek'}
= {
  iana_names => {
    'iso_8859-7:1987' => PRIMARY_CHARSET_NAME,
    'iso-ir-126' => REGISTERED_CHARSET_NAME,
    'iso_8859-7' => REGISTERED_CHARSET_NAME,
    'iso-8859-7' => PREFERRED_CHARSET_NAME,
    'elot_928' => REGISTERED_CHARSET_NAME,
    'ecma-118' => REGISTERED_CHARSET_NAME,
    'greek' => REGISTERED_CHARSET_NAME,
    'greek8' => REGISTERED_CHARSET_NAME,
    'csisolatingreek' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-8'}
= $IANACharset->{'iso_8859-8:1988'}
= $IANACharset->{'iso-ir-138'}
= $IANACharset->{'iso_8859-8'}
= $IANACharset->{'iso-8859-8'}
= $IANACharset->{'hebrew'}
= $IANACharset->{'csisolatinhebrew'}
= {
  iana_names => {
    'iso_8859-8:1988' => PRIMARY_CHARSET_NAME,
    'iso-ir-138' => REGISTERED_CHARSET_NAME,
    'iso_8859-8' => REGISTERED_CHARSET_NAME,
    'iso-8859-8' => PREFERRED_CHARSET_NAME,
    'hebrew' => REGISTERED_CHARSET_NAME,
    'csisolatinhebrew' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-9'}
= $IANACharset->{'iso_8859-9:1989'}
= $IANACharset->{'iso-ir-148'}
= $IANACharset->{'iso_8859-9'}
= $IANACharset->{'iso-8859-9'}
= $IANACharset->{'latin5'}
= $IANACharset->{'l5'}
= $IANACharset->{'csisolatin5'}
= {
  iana_names => {
    'iso_8859-9:1989' => PRIMARY_CHARSET_NAME,
    'iso-ir-148' => REGISTERED_CHARSET_NAME,
    'iso_8859-9' => REGISTERED_CHARSET_NAME,
    'iso-8859-9' => PREFERRED_CHARSET_NAME,
    'latin5' => REGISTERED_CHARSET_NAME,
    'l5' => REGISTERED_CHARSET_NAME,
    'csisolatin5' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-8859-10'}
= $IANACharset->{'iso-8859-10'}
= $IANACharset->{'iso-ir-157'}
= $IANACharset->{'l6'}
= $IANACharset->{'iso_8859-10:1992'}
= $IANACharset->{'csisolatin6'}
= $IANACharset->{'latin6'}
= {
  iana_names => {
    'iso-8859-10' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME,
    'iso-ir-157' => REGISTERED_CHARSET_NAME,
    'l6' => REGISTERED_CHARSET_NAME,
    'iso_8859-10:1992' => REGISTERED_CHARSET_NAME,
    'csisolatin6' => REGISTERED_CHARSET_NAME,
    'latin6' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso_6937-2-add'}
= $IANACharset->{'iso_6937-2-add'}
= $IANACharset->{'iso-ir-142'}
= $IANACharset->{'csisotextcomm'}
= {
  iana_names => {
    'iso_6937-2-add' => PRIMARY_CHARSET_NAME,
    'iso-ir-142' => REGISTERED_CHARSET_NAME,
    'csisotextcomm' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'jis_x0201'}
= $IANACharset->{'jis_x0201'}
= $IANACharset->{'x0201'}
= $IANACharset->{'cshalfwidthkatakana'}
= {
  iana_names => {
    'jis_x0201' => PRIMARY_CHARSET_NAME,
    'x0201' => REGISTERED_CHARSET_NAME,
    'cshalfwidthkatakana' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'jis_encoding'}
= $IANACharset->{'jis_encoding'}
= $IANACharset->{'csjisencoding'}
= {
  iana_names => {
    'jis_encoding' => PRIMARY_CHARSET_NAME,
    'csjisencoding' => REGISTERED_CHARSET_NAME,
  },
  ## NOTE: What is this?
};

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
  mime_text_suitable => 1,
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

$Charset->{'extended_unix_code_fixed_width_for_japanese'}
= $IANACharset->{'extended_unix_code_fixed_width_for_japanese'}
= $IANACharset->{'cseucfixwidjapanese'}
= {
  iana_names => {
    'extended_unix_code_fixed_width_for_japanese' => PRIMARY_CHARSET_NAME,
    'cseucfixwidjapanese' => REGISTERED_CHARSET_NAME,
  },
};

## TODO: ...

$Charset->{'euc-kr'}
= $IANACharset->{'euc-kr'}
= $IANACharset->{'cseuckr'}
= {
  iana_names => {
    'euc-kr' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME,
    'cseuckr' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
};

$Charset->{'iso-2022-jp'}
= $IANACharset->{'iso-2022-jp'}
= $IANACharset->{'csiso2022jp'}
= {
  iana_names => {
    'iso-2022-jp' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME,
    'csiso2022jp' => REGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
};

$Charset->{'iso-2022-jp-2'}
= $IANACharset->{'iso-2022-jp-2'}
= $IANACharset->{'csiso2022jp2'}
= {
  iana_names => {
    'iso-2022-jp-2' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME,
    'csiso2022jp2' => REGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
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

$Charset->{'gbk'}
= $IANACharset->{'gbk'}
= $IANACharset->{'cp936'}
= $IANACharset->{'ms936'}
= $IANACharset->{'windows-936'}
= {
  iana_names => {
    'gbk' => PRIMARY_CHARSET_NAME,
    'cp936' => REGISTERED_CHARSET_NAME,
    'ms936' => REGISTERED_CHARSET_NAME,
    'windows-936' => REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_COMMON | STATUS_OBSOLETE,
  mime_text_suitable => 1,
};

$Charset->{'gb18030'}
= $IANACharset->{'gb18030'}
= {
  iana_names => {
    'gb18030' => PRIMARY_CHARSET_NAME,
  },
  iana_status => STATUS_COMMON,
  mime_text_suitable => 1,
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

$Charset->{'windows-31j'}
= $IANACharset->{'windows-31j'}
= $IANACharset->{'cswindows31j'}
= {
  iana_names => {
    'windows-31j' => PRIMARY_CHARSET_NAME,
    'cswindows31j' => REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_LIMITED_USE, # maybe
  mime_text_suitable => 1,
};

$Charset->{'gb2312'}
= $IANACharset->{'gb2312'}
= $IANACharset->{'csgb2312'}
= {
  iana_names => {
    'gb2312' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME,
    'csgb2312' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
  mime_text_suitable => 1,
};

$Charset->{'big5'}
= $IANACharset->{'big5'}
= $IANACharset->{'csbig5'}
= {
  iana_names => {
    'big5' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME,
    'csbig5' => REGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
};

## TODO: ...

$Charset->{'big5-hkscs'}
= $IANACharset->{'big5-hkscs'}
= {
  iana_names => {
    'big5-hkscs' => PRIMARY_CHARSET_NAME,
  },
  mime_text_suitable => 1,
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
## $Date: 2007/11/21 12:47:22 $

