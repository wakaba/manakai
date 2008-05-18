package Message::Charset::Info;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub UNREGISTERED_CHARSET_NAME () { 0b1 }
    ## Names for non-standard encodings/implementations for Perl encodings
sub REGISTERED_CHARSET_NAME () { 0b10 }
    ## Names for standard encodings for Perl encodings
sub PRIMARY_CHARSET_NAME () { 0b100 }
    ## "Name:" field for IANA names
    ## Canonical name for Perl encodings
sub PREFERRED_CHARSET_NAME () { 0b1000 }
    ## "preferred MIME name" for IANA names

sub FALLBACK_ENCODING_IMPL () { 0b10000 }
    ## For Perl encodings: Not a name of the encoding, the encoding
    ## for the name might be useful as a fallback when the correct
    ## encoding is not supported.
sub NONCONFORMING_ENCODING_IMPL () { FALLBACK_ENCODING_IMPL }
    ## For Perl encodings: Not a conforming implementation of the encoding,
    ## though it seems that the intention was to implement that encoding.
sub SEMICONFORMING_ENCODING_IMPL () { 0b1000000 }
    ## For Perl encodings: The implementation itself (returned by
    ## |get_perl_encoding|) is non-conforming.  The decode handle
    ## implementation (returned by |get_decode_handle|) is conforming.
sub ERROR_REPORTING_ENCODING_IMPL () { 0b100000 }
    ## For Perl encodings: Support error reporting via |manakai_onerror|
    ## handler when the encoding is handled with decode handle.

## iana_status
sub STATUS_COMMON () { 0b1 }
sub STATUS_LIMITED_USE () { 0b10 }
sub STATUS_OBSOLETE () { 0b100 }

## category
sub CHARSET_CATEGORY_BLOCK_SAFE () { 0b1 }
    ## NOTE: Stateless
sub CHARSET_CATEGORY_EUCJP () { 0b10 }
sub CHARSET_CATEGORY_SJIS () { 0b100 }

## iana_names

## is_html_ascii_superset: "superset of US-ASCII (specifically, ANSI_X3.4-1968)
##     for bytes in the range 0x09 - 0x0D, 0x20, 0x21, 0x22, 0x26, 0x27,
##     0x2C - 0x3F, 0x41 - 0x5A, and 0x61 - 0x7A" [HTML5]
## is_ebcdic_based
  ## TODO: These flags are obsolete - should be replaced by category

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
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'ansi_x3.4-1968' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-6' => REGISTERED_CHARSET_NAME,
    'ansi_x3.4-1986' => REGISTERED_CHARSET_NAME,
    'iso_646.irv:1991' => REGISTERED_CHARSET_NAME,
    'ascii' => REGISTERED_CHARSET_NAME,
    'iso646-us' => REGISTERED_CHARSET_NAME,
    'us-ascii' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'us' => REGISTERED_CHARSET_NAME,
    'ibm367' => REGISTERED_CHARSET_NAME,
    'cp367' => REGISTERED_CHARSET_NAME,
    'csascii' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

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
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-1:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-100' => REGISTERED_CHARSET_NAME,
    'iso_8859-1' => REGISTERED_CHARSET_NAME,
    'iso-8859-1' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin1' => REGISTERED_CHARSET_NAME,
    'l1' => REGISTERED_CHARSET_NAME,
    'ibm819' => REGISTERED_CHARSET_NAME,
    'cp819' => REGISTERED_CHARSET_NAME,
    'csisolatin1' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'web-latin1' => UNREGISTERED_CHARSET_NAME | SEMICONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
    'iso-8859-1' => FALLBACK_ENCODING_IMPL,
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x82" => "\x{201A}",
    "\x83" => "\x{0192}",
    "\x84" => "\x{201E}",
    "\x85" => "\x{2026}",
    "\x86" => "\x{2020}",
    "\x87" => "\x{2021}",
    "\x88" => "\x{02C6}",
    "\x89" => "\x{2030}",
    "\x8A" => "\x{0160}",
    "\x8B" => "\x{2039}",
    "\x8C" => "\x{0152}",
    "\x8E" => "\x{017D}",
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
    "\x98" => "\x{02DC}",
    "\x99" => "\x{2122}",
    "\x9A" => "\x{0161}",
    "\x9B" => "\x{203A}",
    "\x9C" => "\x{0153}",
    "\x9E" => "\x{017E}",
    "\x9F" => "\x{0178}",
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-2'}
= $IANACharset->{'iso_8859-2:1987'}
= $IANACharset->{'iso-ir-101'}
= $IANACharset->{'iso_8859-2'}
= $IANACharset->{'iso-8859-2'}
= $IANACharset->{'latin2'}
= $IANACharset->{'l2'}
= $IANACharset->{'csisolatin2'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-2:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-101' => REGISTERED_CHARSET_NAME,
    'iso_8859-2' => REGISTERED_CHARSET_NAME,
    'iso-8859-2' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin2' => REGISTERED_CHARSET_NAME,
    'l2' => REGISTERED_CHARSET_NAME,
    'csisolatin2' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-3'}
= $IANACharset->{'iso_8859-3:1988'}
= $IANACharset->{'iso-ir-109'}
= $IANACharset->{'iso_8859-3'}
= $IANACharset->{'iso-8859-3'}
= $IANACharset->{'latin3'}
= $IANACharset->{'l3'}
= $IANACharset->{'csisolatin3'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-3:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-109' => REGISTERED_CHARSET_NAME,
    'iso_8859-3' => REGISTERED_CHARSET_NAME,
    'iso-8859-3' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin3' => REGISTERED_CHARSET_NAME,
    'l3' => REGISTERED_CHARSET_NAME,
    'csisolatin3' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-4'}
= $IANACharset->{'iso_8859-4:1988'}
= $IANACharset->{'iso-ir-110'}
= $IANACharset->{'iso_8859-4'}
= $IANACharset->{'iso-8859-4'}
= $IANACharset->{'latin4'}
= $IANACharset->{'l4'}
= $IANACharset->{'csisolatin4'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-4:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-110' => REGISTERED_CHARSET_NAME,
    'iso_8859-4' => REGISTERED_CHARSET_NAME,
    'iso-8859-4' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin4' => REGISTERED_CHARSET_NAME,
    'l4' => REGISTERED_CHARSET_NAME,
    'csisolatin4' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-5'}
= $IANACharset->{'iso_8859-5:1988'}
= $IANACharset->{'iso-ir-144'}
= $IANACharset->{'iso_8859-5'}
= $IANACharset->{'iso-8859-5'}
= $IANACharset->{'cyrillic'}
= $IANACharset->{'csisolatincyrillic'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-5:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-144' => REGISTERED_CHARSET_NAME,
    'iso_8859-5' => REGISTERED_CHARSET_NAME,
    'iso-8859-5' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cyrillic' => REGISTERED_CHARSET_NAME,
    'csisolatincyrillic' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-6'}
= $IANACharset->{'iso_8859-6:1987'}
= $IANACharset->{'iso-ir-127'}
= $IANACharset->{'iso_8859-6'}
= $IANACharset->{'iso-8859-6'}
= $IANACharset->{'ecma-114'}
= $IANACharset->{'asmo-708'}
= $IANACharset->{'arabic'}
= $IANACharset->{'csisolatinarabic'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-6:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-127' => REGISTERED_CHARSET_NAME,
    'iso_8859-6' => REGISTERED_CHARSET_NAME,
    'iso-8859-6' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'ecma-114' => REGISTERED_CHARSET_NAME,
    'asmo-708' => REGISTERED_CHARSET_NAME,
    'arabic' => REGISTERED_CHARSET_NAME,
    'csisolatinarabic' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
      ## NOTE: 3/0..3/9 have different semantics from U+0030..0039,
      ## but have same character names (maybe).
      ## NOTE: According to RFC 2046, charset left-hand half of "iso-8859-6"
      ## is same as "us-ascii".
});

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
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-7:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-126' => REGISTERED_CHARSET_NAME,
    'iso_8859-7' => REGISTERED_CHARSET_NAME,
    'iso-8859-7' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'elot_928' => REGISTERED_CHARSET_NAME,
    'ecma-118' => REGISTERED_CHARSET_NAME,
    'greek' => REGISTERED_CHARSET_NAME,
    'greek8' => REGISTERED_CHARSET_NAME,
    'csisolatingreek' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-8'}
= $IANACharset->{'iso_8859-8:1988'}
= $IANACharset->{'iso-ir-138'}
= $IANACharset->{'iso_8859-8'}
= $IANACharset->{'iso-8859-8'}
= $IANACharset->{'hebrew'}
= $IANACharset->{'csisolatinhebrew'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-8:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-138' => REGISTERED_CHARSET_NAME,
    'iso_8859-8' => REGISTERED_CHARSET_NAME,
    'iso-8859-8' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'hebrew' => REGISTERED_CHARSET_NAME,
    'csisolatinhebrew' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-9'}
= $IANACharset->{'iso_8859-9:1989'}
= $IANACharset->{'iso-ir-148'}
= $IANACharset->{'iso_8859-9'}
= $IANACharset->{'iso-8859-9'}
= $IANACharset->{'latin5'}
= $IANACharset->{'l5'}
= $IANACharset->{'csisolatin5'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_8859-9:1989' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-148' => REGISTERED_CHARSET_NAME,
    'iso_8859-9' => REGISTERED_CHARSET_NAME,
    'iso-8859-9' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin5' => REGISTERED_CHARSET_NAME,
    'l5' => REGISTERED_CHARSET_NAME,
    'csisolatin5' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-10'}
= $IANACharset->{'iso-8859-10'}
= $IANACharset->{'iso-ir-157'}
= $IANACharset->{'l6'}
= $IANACharset->{'iso_8859-10:1992'}
= $IANACharset->{'csisolatin6'}
= $IANACharset->{'latin6'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso-8859-10' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-157' => REGISTERED_CHARSET_NAME,
    'l6' => REGISTERED_CHARSET_NAME,
    'iso_8859-10:1992' => REGISTERED_CHARSET_NAME,
    'csisolatin6' => REGISTERED_CHARSET_NAME,
    'latin6' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso_6937-2-add'}
= $IANACharset->{'iso_6937-2-add'}
= $IANACharset->{'iso-ir-142'}
= $IANACharset->{'csisotextcomm'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso_6937-2-add' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-142' => REGISTERED_CHARSET_NAME,
    'csisotextcomm' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'jis_x0201'}
= $IANACharset->{'jis_x0201'}
= $IANACharset->{'x0201'}
= $IANACharset->{'cshalfwidthkatakana'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'jis_x0201' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'x0201' => REGISTERED_CHARSET_NAME,
    'cshalfwidthkatakana' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'jis_encoding'}
= $IANACharset->{'jis_encoding'}
= $IANACharset->{'csjisencoding'}
= __PACKAGE__->new ({
  category => 0,
  iana_names => {
    'jis_encoding' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csjisencoding' => REGISTERED_CHARSET_NAME,
  },
  ## NOTE: What is this?
});

$Charset->{'shift_jis'}
= $IANACharset->{'shift_jis'}
= $IANACharset->{'ms_kanji'}
= $IANACharset->{'csshiftjis'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'shift_jis' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'ms_kanji' => REGISTERED_CHARSET_NAME,
    'csshiftjis' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'shift-jis-1997' => UNREGISTERED_CHARSET_NAME |
        SEMICONFORMING_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    shiftjis => PRIMARY_CHARSET_NAME | NONCONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: Unicode mapping is wrong.
  },
  mime_text_suitable => 1,
});

$Charset->{'x-sjis'}
= $IANACharset->{'x-sjis'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'x-sjis' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'shift-jis-1997' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  mime_text_suitable => 1,
});

$Charset->{shift_jisx0213}
= $IANACharset->{shift_jisx0213}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    shift_jisx0213 => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    #shift_jisx0213 (non-standard - i don't know its conformance)
    'shift-jis-1997' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    'shiftjis' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  mime_text_suitable => 1,
});

$Charset->{'euc-jp'}
= $IANACharset->{'extended_unix_code_packed_format_for_japanese'}
= $IANACharset->{'cseucpkdfmtjapanese'}
= $IANACharset->{'euc-jp'}
= $IANACharset->{'x-euc-jp'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_EUCJP | CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'extended_unix_code_packed_format_for_japanese' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cseucpkdfmtjapanese' => REGISTERED_CHARSET_NAME,
    'euc-jp' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'euc-jp-1997' => UNREGISTERED_CHARSET_NAME |
        SEMICONFORMING_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: Though the IANA definition references the 1990 version
        ## of EUC-JP, the 1997 version of JIS standard claims that the version
        ## is same coded character set as the 1990 version, such that we
        ## consider the EUC-JP 1990 version is same as the 1997 version.
    'euc-jp' => PREFERRED_CHARSET_NAME | NONCONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: Unicode mapping is wrong.
  },
  is_html_ascii_superset => 1,
  mime_text_suitable => 1,
});

$Charset->{'x-euc-jp'}
= $IANACharset->{'x-euc-jp'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_EUCJP | CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'x-euc-jp' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'euc-jp-1997' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    'euc-jp' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  is_html_ascii_superset => 1,  is_html_ascii_superset => 1,
  mime_text_suitable => 1,
});

$Charset->{'extended_unix_code_fixed_width_for_japanese'}
= $IANACharset->{'extended_unix_code_fixed_width_for_japanese'}
= $IANACharset->{'cseucfixwidjapanese'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'extended_unix_code_fixed_width_for_japanese' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cseucfixwidjapanese' => REGISTERED_CHARSET_NAME,
  },
});

## TODO: ...

$Charset->{'euc-kr'}
= $IANACharset->{'euc-kr'}
= $IANACharset->{'cseuckr'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'euc-kr' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cseuckr' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-2022-jp'}
= $IANACharset->{'iso-2022-jp'}
= $IANACharset->{'csiso2022jp'}
= $IANACharset->{'iso2022jp'}
= $IANACharset->{'junet-code'}
= __PACKAGE__->new ({
  category => 0,
  iana_names => {
    'iso-2022-jp' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csiso2022jp' => REGISTERED_CHARSET_NAME,
    'iso2022jp' => UNREGISTERED_CHARSET_NAME,
    'junet-code' => UNREGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
});

$Charset->{'iso-2022-jp-2'}
= $IANACharset->{'iso-2022-jp-2'}
= $IANACharset->{'csiso2022jp2'}
= __PACKAGE__->new ({
  category => 0,
  iana_names => {
    'iso-2022-jp-2' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csiso2022jp2' => REGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
});

## TODO: ...

$Charset->{'utf-8'}
= $IANACharset->{'utf-8'}
= $IANACharset->{'x-utf-8'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'utf-8' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
        ## NOTE: IANA name "utf-8" references RFC 3629.  According to the RFC,
        ## the definitive definition is one specified in the Unicode Standard.
    'x-utf-8' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'utf-8-strict' => PRIMARY_CHARSET_NAME | SEMICONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: It does not support non-Unicode UCS characters (conforming).
        ## It does detect illegal sequences (conforming).
        ## It does not support surrpgate pairs (conforming).
        ## It does not support BOMs (non-conforming).
  },
  bom_pattern => qr/\xEF\xBB\xBF/,
  is_html_ascii_superset => 1,
  mime_text_suitable => 1,
});

$Charset->{'utf-8n'}
= $IANACharset->{'utf-8n'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'utf-8n' => UNREGISTERED_CHARSET_NAME,
        ## NOTE: Is there any normative definition for the charset?
        ## What variant of UTF-8 should we use for the charset?
  },
  perl_names => {
    'utf-8-strict' => PRIMARY_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
  },
  is_html_ascii_superset => 1,
  mime_text_suitable => 1,
});

## TODO: ...

$Charset->{'gbk'}
= $IANACharset->{'gbk'}
= $IANACharset->{'cp936'}
= $IANACharset->{'ms936'}
= $IANACharset->{'windows-936'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'gbk' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cp936' => REGISTERED_CHARSET_NAME,
    'ms936' => REGISTERED_CHARSET_NAME,
    'windows-936' => REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_COMMON | STATUS_OBSOLETE,
  mime_text_suitable => 1,
});

$Charset->{'gb18030'}
= $IANACharset->{'gb18030'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'gb18030' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_COMMON,
  mime_text_suitable => 1,
});

## TODO: ...

$Charset->{'utf-16be'}
= $IANACharset->{'utf-16be'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'utf-16be' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
});

$Charset->{'utf-16le'}
= $IANACharset->{'utf-16le'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'utf-16le' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
});

$Charset->{'utf-16'}
= $IANACharset->{'utf-16'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'utf-16' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
});

## TODO: ...

$Charset->{'windows-31j'}
= $IANACharset->{'windows-31j'}
= $IANACharset->{'cswindows31j'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'windows-31j' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cswindows31j' => REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_LIMITED_USE, # maybe
  mime_text_suitable => 1,
});

$Charset->{'gb2312'}
= $IANACharset->{'gb2312'}
= $IANACharset->{'csgb2312'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'gb2312' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csgb2312' => REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
  mime_text_suitable => 1,
});

$Charset->{'big5'}
= $IANACharset->{'big5'}
= $IANACharset->{'csbig5'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'big5' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csbig5' => REGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
});

## TODO: ...

$Charset->{'big5-hkscs'}
= $IANACharset->{'big5-hkscs'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'big5-hkscs' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  mime_text_suitable => 1,
});

## TODO: ...

$Charset->{'windows-1252'}
= $IANACharset->{'windows-1252'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'windows-1252' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  is_html_ascii_superset => 1,
});

## TODO: ...

$Charset->{'tis-620'}
= $IANACharset->{'tis-620'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'tis-620' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'tis-620' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: An alias of |iso-8859-11|.
  },
  is_html_ascii_superset => 1,
});

$Charset->{'iso-8859-11'}
= $IANACharset->{'iso-8859-11'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'iso-8859-11' => UNREGISTERED_CHARSET_NAME,
        ## NOTE: The Web Thai encoding, i.e. windows-874.
  },
  perl_names => {
    'windows-874' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    'web-thai' => UNREGISTERED_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x85" => "\x{2026}",
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
  },
  is_html_ascii_superset => 1,
});

$Charset->{'windows-874'}
= $IANACharset->{'windows-874'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'windows-874' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'windows-874' => REGISTERED_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
  },
  is_html_ascii_superset => 1,
});

sub new ($$) {
  return bless $_[1], $_[0];
} # new

## NOTE: A class method
sub get_by_iana_name ($$) {
  my $name = $_[1];
  $name =~ tr/A-Z/a-z/; ## ASCII case-insensitive
  unless ($IANACharset->{$name}) {
    $IANACharset->{$name} = __PACKAGE__->new ({
      iana_names => {
        $name => UNREGISTERED_CHARSET_NAME,
      },
    });
  }
  return $IANACharset->{$name};
} # get_by_iana_name

sub get_decode_handle ($$;%) {
  my $self = shift;
  my $byte_stream = shift;
  my %opt = @_;

  my $obj = {
    character_queue => [],
    filehandle => $byte_stream,
    charset => '', ## TODO: We set a charset name for input_encoding (when we get identify-by-URI nonsense away)
    byte_buffer => $opt{byte_buffer} ? ${$opt{byte_buffer}} : '', ## TODO: ref, instead of value, should be used
    onerror => $opt{onerror} || sub {},
    must_level => 'm',
    fact_level => 'm',
  };

  require Whatpm::Charset::DecodeHandle;
  if ($self->{iana_names}->{'iso-2022-jp'}) {
    $obj->{state_2440} = 'gl-jis-1978';
    $obj->{state_2442} = 'gl-jis-1983';
    $obj->{state} = 'state_2842';
    eval {
      require Encode::GLJIS1978;
      require Encode::GLJIS1983;
    };
    if (Encode::find_encoding ($obj->{state_2440}) and
        Encode::find_encoding ($obj->{state_2442})) {
      return ((bless $obj, 'Whatpm::Charset::DecodeHandle::ISO2022JP'),
              PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME);
    }
  } elsif ($self->{xml_names}->{'iso-2022-jp'}) {
    $obj->{state_2440} = 'gl-jis-1997-swapped';
    $obj->{state_2442} = 'gl-jis-1997';
    $obj->{state} = 'state_2842';
    eval {
      require Encode::GLJIS1997Swapped;
      require Encode::GLJIS1997;
    };
    if (Encode::find_encoding ($obj->{state_2440}) and
        Encode::find_encoding ($obj->{state_2442})) {
      return ((bless $obj, 'Whatpm::Charset::DecodeHandle::ISO2022JP'),
              PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME);
    }
  }

  my ($e, $e_status) = $self->get_perl_encoding
      (%opt, allow_semiconforming => 1);
  if ($e) {
    $obj->{perl_encoding_name} = $e->name;
    if ($self->{category} & CHARSET_CATEGORY_EUCJP) {
      return ((bless $obj, 'Whatpm::Charset::DecodeHandle::EUCJP'),
              $e_status);
    } elsif ($self->{category} & CHARSET_CATEGORY_SJIS) {
      return ((bless $obj, 'Whatpm::Charset::DecodeHandle::ShiftJIS'),
              $e_status);
    #} elsif ($self->{category} & CHARSET_CATEGORY_BLOCK_SAFE) {
    } else {
      $e_status |= FALLBACK_ENCODING_IMPL
          unless $self->{category} & CHARSET_CATEGORY_BLOCK_SAFE;
      $obj->{bom_pattern} = $self->{bom_pattern};
      $obj->{fallback} = $self->{fallback};
      return ((bless $obj, 'Whatpm::Charset::DecodeHandle::Encode'),
              $e_status);
    #} else {
    #  ## TODO: no encoding error (?)
    #  return (undef, 0);
    }
  } else {
    ## TODO: no encoding error(?)
    return (undef, 0);
  }
} # get_decode_handle

sub get_perl_encoding ($;%) {
  my ($self, %opt) = @_;
  
  require Encode;
  my $load_encode = sub {
    my $name = shift;
    if ($name eq 'euc-jp-1997') {
      require Encode::EUCJP1997;
    } elsif ($name eq 'shift-jis-1997') {
      require Encode::ShiftJIS1997;
    } elsif ($name eq 'web-latin1') {
      require Whatpm::Charset::WebLatin1;
    } elsif ($name eq 'web-thai') {
      require Whatpm::Charset::WebThai;
    }
  }; # $load_encode

  if ($opt{allow_error_reporting}) {
    for my $perl_name (keys %{$self->{perl_names} or {}}) {
      my $perl_status = $self->{perl_names}->{$perl_name};
      next unless $perl_status & ERROR_REPORTING_ENCODING_IMPL;
      next if $perl_status & FALLBACK_ENCODING_IMPL;
      next if $perl_status & SEMICONFORMING_ENCODING_IMPL and
          not $opt{allow_semiconforming};
      
      $load_encode->($perl_name);
      my $e = Encode::find_encoding ($perl_name);
      if ($e) {
        return ($e, $perl_status);
      }
    }
  }
  
  for my $perl_name (keys %{$self->{perl_names} or {}}) {
    my $perl_status = $self->{perl_names}->{$perl_name};
    next if $perl_status & ERROR_REPORTING_ENCODING_IMPL;
    next if $perl_status & FALLBACK_ENCODING_IMPL;
    next if $perl_status & SEMICONFORMING_ENCODING_IMPL and
        not $opt{allow_semiconforming};

    $load_encode->($perl_name);
    my $e = Encode::find_encoding ($perl_name);
    if ($e) {
      return ($e, $perl_status);
    }
  }
  
  if ($opt{allow_fallback}) {
    for my $perl_name (keys %{$self->{perl_names} or {}}) {
      my $perl_status = $self->{perl_names}->{$perl_name};
      next unless $perl_status & FALLBACK_ENCODING_IMPL or
          $perl_status & SEMICONFORMING_ENCODING_IMPL;
      ## NOTE: We don't prefer semi-conforming implementations to 
      ## non-conforming implementations, since semi-conforming implementations
      ## will never be conforming without assist of the callee, and in such
      ## cases the callee should set the |allow_semiconforming| option upon
      ## the invocation of the method anyway.
  
      $load_encode->($perl_name);
      my $e = Encode::find_encoding ($perl_name);
      if ($e) {
        return ($e, $perl_status);
      }
    }

    for my $iana_name (keys %{$self->{iana_names} or {}}) {
      $load_encode->($iana_name);
      my $e = Encode::find_encoding ($iana_name);
      if ($e) {
        return ($e, FALLBACK_ENCODING_IMPL);
      }
    }
  }
  
  return (undef, 0);
} # get_perl_encoding

sub get_iana_name ($) {
  my $self = shift;
  
  my $primary;
  my $other;
  for my $iana_name (keys %{$self->{iana_names} or {}}) {
    my $name_status = $self->{iana_names}->{$iana_name};
    if ($name_status & PREFERRED_CHARSET_NAME) {
      return $iana_name;
    } elsif ($name_status & PRIMARY_CHARSET_NAME) {
      $primary = $iana_name;
    } elsif ($name_status & REGISTERED_CHARSET_NAME) {
      $other = $iana_name;
    } else {
      $other ||= $iana_name;
    }
  }

  return $primary || $other;
} # get_iana_name

## NOTE: A non-method function
sub is_syntactically_valid_iana_charset_name ($) {
  my $name = shift;
  return $name =~ /\A[\x20-\x7E]{1,40}\z/;
} # is_suntactically_valid_iana_charset_name

1;
## $Date: 2008/05/18 06:09:50 $

