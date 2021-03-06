package Whatpm::HTML::InputStream;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '1.0';
use Whatpm::HTML::Defs;

## ------ Constructor ------

sub new ($) {
  my $class = shift;
  my $self = bless {
    level => {
      must => 'm',
      should => 's',
      obsconforming => 's',
      warn => 'w',
      info => 'i',
      uncertain => 'u',
    },
  }, $class;
  $self->{application_cache_selection} = sub {
    #
  };
  
  return $self;
} # new

## ------ Parser common operations ------

sub _clear_refs ($) {
  my $self = $_[0];
  ## Remove self references.
  delete $self->{set_nc};
  delete $self->{read_until};
  delete $self->{parse_error};
  delete $self->{document};
  delete $self->{chars};
  delete $self->{chars_pull_next};
  delete $self->{restart_parser};
  delete $self->{t};
  delete $self->{embedded_encoding_name};
  delete $self->{byte_buffer};
} # _clear_refs

## ------ Error handling ------

our $DefaultErrorHandler = sub {
  my (%opt) = @_;
  my $line = $opt{token} ? $opt{token}->{line} : $opt{line};
  my $column = $opt{token} ? $opt{token}->{column} : $opt{column};
  warn "Parse error ($opt{type}) at line $line column $column\n";
}; # $DefaultErrorHandler

sub onerror ($;$) {
  if (@_ > 1) {
    $_[0]->{onerror} = $_[1];
  }
  return $_[0]->{onerror} || $DefaultErrorHandler;
} # onerror

## ------ Character encoding processing ------

## XXX Encoding Standard support

## <http://dvcs.w3.org/hg/encoding/raw-file/tip/Overview.html#encodings>

# $ curl http://dvcs.w3.org/hg/encoding/raw-file/tip/encodings.json | perl -MJSON::XS -MData::Dumper -e 'local $/ = undef; $json = JSON::XS->new->decode(<>); $Data::Dumper::Sortkeys = 1; print Dumper {map { my $name = $_->{name}; map { $_ => $name } @{$_->{labels}} } map { @{$_->{encodings}} } @$json}'
my $CharsetMap = {
          '866' => 'ibm866',
          'ansi_x3.4-1968' => 'windows-1252',
          'arabic' => 'iso-8859-6',
          'ascii' => 'windows-1252',
          'asmo-708' => 'iso-8859-6',
          'big5' => 'big5',
          'big5-hkscs' => 'big5',
          'chinese' => 'gbk',
          'cn-big5' => 'big5',
          'cp1250' => 'windows-1250',
          'cp1251' => 'windows-1251',
          'cp1252' => 'windows-1252',
          'cp1253' => 'windows-1253',
          'cp1254' => 'windows-1254',
          'cp1255' => 'windows-1255',
          'cp1256' => 'windows-1256',
          'cp1257' => 'windows-1257',
          'cp1258' => 'windows-1258',
          'cp819' => 'windows-1252',
          'cp864' => 'ibm864',
          'cp866' => 'ibm866',
          'csbig5' => 'big5',
          'cseuckr' => 'euc-kr',
          'cseucpkdfmtjapanese' => 'euc-jp',
          'csgb2312' => 'gbk',
          'csibm864' => 'ibm864',
          'csibm866' => 'ibm866',
          'csiso2022jp' => 'iso-2022-jp',
          'csiso2022kr' => 'iso-2022-kr',
          'csiso58gb231280' => 'gbk',
          'csiso88596e' => 'iso-8859-6',
          'csiso88596i' => 'iso-8859-6',
          'csiso88598e' => 'iso-8859-8',
          'csiso88598i' => 'iso-8859-8',
          'csisolatin1' => 'windows-1252',
          'csisolatin2' => 'iso-8859-2',
          'csisolatin3' => 'iso-8859-3',
          'csisolatin4' => 'iso-8859-4',
          'csisolatin5' => 'windows-1254',
          'csisolatin6' => 'iso-8859-10',
          'csisolatin9' => 'iso-8859-15',
          'csisolatinarabic' => 'iso-8859-6',
          'csisolatincyrillic' => 'iso-8859-5',
          'csisolatingreek' => 'iso-8859-7',
          'csisolatinhebrew' => 'iso-8859-8',
          'cskoi8r' => 'koi8-r',
          'csksc56011987' => 'euc-kr',
          'csmacintosh' => 'macintosh',
          'csshiftjis' => 'shift_jis',
          'cyrillic' => 'iso-8859-5',
          'dos-874' => 'windows-874',
          'ecma-114' => 'iso-8859-6',
          'ecma-118' => 'iso-8859-7',
          'elot_928' => 'iso-8859-7',
          'euc-jp' => 'euc-jp',
          'euc-kr' => 'euc-kr',
          'gb18030' => 'gb18030',
          'gb2312' => 'gbk',
          'gb_2312' => 'gbk',
          'gb_2312-80' => 'gbk',
          'gbk' => 'gbk',
          'greek' => 'iso-8859-7',
          'greek8' => 'iso-8859-7',
          'hebrew' => 'iso-8859-8',
          'hz-gb-2312' => 'hz-gb-2312',
          'ibm-864' => 'ibm864',
          'ibm819' => 'windows-1252',
          'ibm864' => 'ibm864',
          'ibm866' => 'ibm866',
          'iso-2022-jp' => 'iso-2022-jp',
          'iso-2022-kr' => 'iso-2022-kr',
          'iso-8859-1' => 'windows-1252',
          'iso-8859-10' => 'iso-8859-10',
          'iso-8859-11' => 'windows-874',
          'iso-8859-13' => 'iso-8859-13',
          'iso-8859-14' => 'iso-8859-14',
          'iso-8859-15' => 'iso-8859-15',
          'iso-8859-16' => 'iso-8859-16',
          'iso-8859-2' => 'iso-8859-2',
          'iso-8859-3' => 'iso-8859-3',
          'iso-8859-4' => 'iso-8859-4',
          'iso-8859-5' => 'iso-8859-5',
          'iso-8859-6' => 'iso-8859-6',
          'iso-8859-6-e' => 'iso-8859-6',
          'iso-8859-6-i' => 'iso-8859-6',
          'iso-8859-7' => 'iso-8859-7',
          'iso-8859-8' => 'iso-8859-8',
          'iso-8859-8-e' => 'iso-8859-8',
          'iso-8859-8-i' => 'iso-8859-8',
          'iso-8859-9' => 'windows-1254',
          'iso-ir-100' => 'windows-1252',
          'iso-ir-101' => 'iso-8859-2',
          'iso-ir-109' => 'iso-8859-3',
          'iso-ir-110' => 'iso-8859-4',
          'iso-ir-126' => 'iso-8859-7',
          'iso-ir-127' => 'iso-8859-6',
          'iso-ir-138' => 'iso-8859-8',
          'iso-ir-144' => 'iso-8859-5',
          'iso-ir-148' => 'windows-1254',
          'iso-ir-149' => 'euc-kr',
          'iso-ir-157' => 'iso-8859-10',
          'iso-ir-58' => 'gbk',
          'iso8859-1' => 'windows-1252',
          'iso8859-10' => 'iso-8859-10',
          'iso8859-11' => 'windows-874',
          'iso8859-13' => 'iso-8859-13',
          'iso8859-14' => 'iso-8859-14',
          'iso8859-15' => 'iso-8859-15',
          'iso8859-2' => 'iso-8859-2',
          'iso8859-3' => 'iso-8859-3',
          'iso8859-4' => 'iso-8859-4',
          'iso8859-5' => 'iso-8859-5',
          'iso8859-6' => 'iso-8859-6',
          'iso8859-7' => 'iso-8859-7',
          'iso8859-8' => 'iso-8859-8',
          'iso8859-9' => 'windows-1254',
          'iso88591' => 'windows-1252',
          'iso885910' => 'iso-8859-10',
          'iso885911' => 'windows-874',
          'iso885913' => 'iso-8859-13',
          'iso885914' => 'iso-8859-14',
          'iso885915' => 'iso-8859-15',
          'iso88592' => 'iso-8859-2',
          'iso88593' => 'iso-8859-3',
          'iso88594' => 'iso-8859-4',
          'iso88595' => 'iso-8859-5',
          'iso88596' => 'iso-8859-6',
          'iso88597' => 'iso-8859-7',
          'iso88598' => 'iso-8859-8',
          'iso88599' => 'windows-1254',
          'iso_8859-1' => 'windows-1252',
          'iso_8859-15' => 'iso-8859-15',
          'iso_8859-1:1987' => 'windows-1252',
          'iso_8859-2' => 'iso-8859-2',
          'iso_8859-2:1987' => 'iso-8859-2',
          'iso_8859-3' => 'iso-8859-3',
          'iso_8859-3:1988' => 'iso-8859-3',
          'iso_8859-4' => 'iso-8859-4',
          'iso_8859-4:1988' => 'iso-8859-4',
          'iso_8859-5' => 'iso-8859-5',
          'iso_8859-5:1988' => 'iso-8859-5',
          'iso_8859-6' => 'iso-8859-6',
          'iso_8859-6:1987' => 'iso-8859-6',
          'iso_8859-7' => 'iso-8859-7',
          'iso_8859-7:1987' => 'iso-8859-7',
          'iso_8859-8' => 'iso-8859-8',
          'iso_8859-8:1988' => 'iso-8859-8',
          'iso_8859-9' => 'windows-1254',
          'iso_8859-9:1989' => 'windows-1254',
          'koi' => 'koi8-r',
          'koi8' => 'koi8-r',
          'koi8-r' => 'koi8-r',
          'koi8-u' => 'koi8-u',
          'koi8_r' => 'koi8-r',
          'korean' => 'euc-kr',
          'ks_c_5601-1987' => 'euc-kr',
          'ks_c_5601-1989' => 'euc-kr',
          'ksc5601' => 'euc-kr',
          'ksc_5601' => 'euc-kr',
          'l1' => 'windows-1252',
          'l2' => 'iso-8859-2',
          'l3' => 'iso-8859-3',
          'l4' => 'iso-8859-4',
          'l5' => 'windows-1254',
          'l6' => 'iso-8859-10',
          'l9' => 'iso-8859-15',
          'latin1' => 'windows-1252',
          'latin2' => 'iso-8859-2',
          'latin3' => 'iso-8859-3',
          'latin4' => 'iso-8859-4',
          'latin5' => 'windows-1254',
          'latin6' => 'iso-8859-10',
          'logical' => 'iso-8859-8',
          'mac' => 'macintosh',
          'macintosh' => 'macintosh',
          'ms_kanji' => 'shift_jis',
          'shift-jis' => 'shift_jis',
          'shift_jis' => 'shift_jis',
          'sjis' => 'shift_jis',
          'sun_eu_greek' => 'iso-8859-7',
          'tis-620' => 'windows-874',
          'unicode-1-1-utf-8' => 'utf-8',
          'us-ascii' => 'windows-1252',
          'utf-16' => 'utf-16',
          'utf-16be' => 'utf-16be',
          'utf-16le' => 'utf-16',
          'utf-8' => 'utf-8',
          'utf8' => 'utf-8',
          'visual' => 'iso-8859-8',
          'windows-1250' => 'windows-1250',
          'windows-1251' => 'windows-1251',
          'windows-1252' => 'windows-1252',
          'windows-1253' => 'windows-1253',
          'windows-1254' => 'windows-1254',
          'windows-1255' => 'windows-1255',
          'windows-1256' => 'windows-1256',
          'windows-1257' => 'windows-1257',
          'windows-1258' => 'windows-1258',
          'windows-31j' => 'shift_jis',
          'windows-874' => 'windows-874',
          'windows-949' => 'euc-kr',
          'x-cp1250' => 'windows-1250',
          'x-cp1251' => 'windows-1251',
          'x-cp1252' => 'windows-1252',
          'x-cp1253' => 'windows-1253',
          'x-cp1254' => 'windows-1254',
          'x-cp1255' => 'windows-1255',
          'x-cp1256' => 'windows-1256',
          'x-cp1257' => 'windows-1257',
          'x-cp1258' => 'windows-1258',
          'x-euc-jp' => 'euc-jp',
          'x-gbk' => 'gbk',
          'x-mac-cyrillic' => 'x-mac-cyrillic',
          'x-mac-roman' => 'macintosh',
          'x-mac-ukrainian' => 'x-mac-cyrillic',
          'x-sjis' => 'shift_jis',
          'x-x-big5' => 'big5'
}; # $CharsetMap

my $LocaleDefaultCharset = {
  ar => 'utf-8',
  be => 'iso-8859-5',
  bg => 'windows-1251',
  cs => 'iso-8859-2',
  cy => 'utf-8',
  fa => 'utf-8',
  he => 'windows-1255',
  hr => 'utf-8',
  hu => 'iso-8859-2',
  ja => 'shift_jis',
  kk => 'utf-8',
  ko => 'euc-kr',
  ku => 'windows-1254',
  lt => 'windows-1257',
  lv => 'iso-8859-13',
  mk => 'utf-8',
  or => 'utf-8',
  pl => 'iso-8859-2',
  ro => 'utf-8',
  ru => 'windows-1251',
  sk => 'windows-1250',
  sl => 'iso-8859-2',
  sr => 'utf-8',
  th => 'windows-874',
  tr => 'windows-1254',
  uk => 'windows-1251',
  vi => 'utf-8',
  'zh-cn' => 'gb18030',
  'zh-tw' => 'big5',
};

# XXX
sub _get_encoding_name ($) {
  my $input = shift || '';
  $input =~ s/\A[\x09\x0A\x0C\x0D\x20]+//;
  $input =~ s/[\x09\x0A\x0C\x0D\x20]+\z//;
  $input =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
  return $CharsetMap->{$input}; # or undef
} # _get_encoding_name

## Encoding sniffing algorithm
## <http://www.whatwg.org/specs/web-apps/current-work/#determining-the-character-encoding>.
sub _encoding_sniffing ($;%) {
  my ($self, %args) = @_;

  ## Change the encoding
  ## <http://www.whatwg.org/specs/web-apps/current-work/#change-the-encoding>
  ## Step 5. Encoding from <meta charset>
  if ($args{embedded_encoding_name}) {
    my $name = _get_encoding_name $args{embedded_encoding_name};
    if ($name) {
      $self->{input_encoding} = $name;
      $self->{confident} = 1; # certain
      return;
    }
  }

  ## Step 1. User-specified encoding
  if ($args{user_encoding_name}) {
    my $name = _get_encoding_name $args{user_encoding_name};
    if ($name) {
      $self->{input_encoding} = $name;
      $self->{confident} = 1; # certain
      return;
    }
  }

  ## Step 2. Transport-layer encoding
  if ($args{transport_encoding_name}) {
    my $name = _get_encoding_name $args{transport_encoding_name};
    if ($name) {
      $self->{input_encoding} = $name;
      $self->{confident} = 1; # certain
      return;
    }
  }

  return if $args{no_body_data_yet};

  ## Step 3. Sniffing
  if ($args{read_head}) {
    my $head = $args{read_head}->();
    if (defined $head) {
      ## Step 4. BOM
      if ($$head =~ /^\xFE\xFF/) {
        $self->{input_encoding} = 'utf-16be';
        $self->{confident} = 1; # certain
        return;
      } elsif ($$head =~ /^\xFF\xFE/) {
        $self->{input_encoding} = 'utf-16le';
        $self->{confident} = 1; # certain
        return;
      } elsif ($$head =~ /^\xEF\xBB\xBF/) {
        $self->{input_encoding} = 'utf-8';
        $self->{confident} = 1; # certain
        return;
      }

      ## Step 5. <meta charset>
      # XXX

      ## Step 6. History
      if ($args{get_history_encoding_name}) {
        my $name = _get_encoding_name $args{get_history_encoding_name}->();
        if ($name) {
          $self->{input_encoding} = $name;
          $self->{confident} = 0; # tentative
          return;
        }
      }

      ## Step 7. UniversalCharDet
      require Whatpm::Charset::UniversalCharDet;
      my $name = _get_encoding_name
          +Whatpm::Charset::UniversalCharDet->detect_byte_string ($$head);
      if ($name) {
        $self->{input_encoding} = $name;
        $self->{confident} = 0; # tentative
        return;
      }
    } # $head
  }

  ## Step 8. Locale-dependent default
  if ($args{locale}) {
    my $name = _get_encoding_name $LocaleDefaultCharset->{$args{locale}};
    if ($name) {
      $self->{input_encoding} = $name;
      $self->{confident} = 0; # tentative
      return;
    }
  }

  ## Step 8. Default of default
  $self->{input_encoding} = 'windows-1252';
  $self->{confident} = 0; # tentative
  return;

  # XXX expose sniffing info for validator
} # _encoding_sniffing

sub _change_encoding {
  my ($self, $name, $token) = @_;

  ## "meta" start tag
  ## <http://www.whatwg.org/specs/web-apps/current-work/#parsing-main-inhead>.

  ## "meta". Confidence is /tentative/
  return 0 if $self->{confident}; # tentative

  $name = _get_encoding_name $name;
  unless ($name) {
    ## "meta". Supported encoding
    return 0;
  }

  ## "meta". ASCII-compatible or UTF-16
  ## All encodings in Encoding Standard are ASCII-compatible or UTF-16.

  ## Change the encoding
  ## <http://www.whatwg.org/specs/web-apps/current-work/#change-the-encoding>.

  ## Step 1. UTF-16
  if ($self->{input_encoding} eq 'utf-16' or
      $self->{input_encoding} eq 'utf-16be') {
    $self->{confident} = 1; # certain
    return 0;
  }

  ## Step 2. UTF-16
  $name = 'utf-8' if $name eq 'utf-16' or $name eq 'utf-16be';
  
  ## Step 3. Same
  if ($name eq $self->{input_encoding}) {
    $self->{confident} = 1; # certain
    return 0;
  }

  $self->{parse_error}->(type => 'charset label detected',
                         text => $self->{input_encoding},
                         value => $name,
                         level => $self->{level}->{warn},
                         token => $token);

  ## Step 4. Change the encoding on the fly
  ## Not implemented.

  ## Step 5. Navigate with replace.
  if ($self->{restart_parser}) {
    return $self->{restart_parser}->($name);
  }

  ## Step 5. Can't restart
  $self->{confident} = 1; # certain
  return 0;

  # XXX expose info for validator
} # _change_encoding

## ------ Feed characters from input stream to tokenizer ------

my $CommonStoppers = {
  ## Newlines
  "\x{000D}" => 1, "\x{000A}" => 1,
  "\x{0085}" => 1, "\x{2028}" => 1,

  ## Parse errors
  "\x{000B}" => 1, "\x{FFFE}" => 1, "\x{FFFF}" => 1,
  "\x{1FFFE}" => 1, "\x{1FFFF}" => 1, "\x{2FFFE}" => 1, "\x{2FFFF}" => 1,
  "\x{3FFFE}" => 1, "\x{3FFFF}" => 1, "\x{4FFFE}" => 1, "\x{4FFFF}" => 1,
  "\x{5FFFE}" => 1, "\x{5FFFF}" => 1, "\x{6FFFE}" => 1, "\x{6FFFF}" => 1,
  "\x{7FFFE}" => 1, "\x{7FFFF}" => 1, "\x{8FFFE}" => 1, "\x{8FFFF}" => 1,
  "\x{9FFFE}" => 1, "\x{9FFFF}" => 1, "\x{AFFFE}" => 1, "\x{AFFFF}" => 1,
  "\x{BFFFE}" => 1, "\x{BFFFF}" => 1, "\x{CFFFE}" => 1, "\x{CFFFF}" => 1,
  "\x{DFFFE}" => 1, "\x{DFFFF}" => 1, "\x{EFFFE}" => 1, "\x{EFFFF}" => 1,
  "\x{FFFFE}" => 1, "\x{FFFFF}" => 1,
  "\x{10FFFE}" => 1, "\x{10FFFF}" => 1,
  "\x{000C}" => 1,
};
$CommonStoppers->{chr $_} = 1
    for 0x0001..0x0008, 0x000E..0x001F, 0x007F..0x009F, 0xFDD0..0xFDEF,
        0xD800..0xDFFF;

## U+0000 error will be detected by tokenizer or tree constructor.
my $ParseErrorControlCodePosition = {
  html => {0x000B => 'must', 0x0085 => 'must'},
  1 => {0x000B => 'must', 0x000C => 'must', 0x0085 => 'warn'},
  1.1 => {0x000B => 'must', 0x000C => 'must'},
};
$ParseErrorControlCodePosition->{html}->{$_} = 'must',
$ParseErrorControlCodePosition->{1}->{$_} = 'must',
$ParseErrorControlCodePosition->{1.1}->{$_} = 'must'
    for 0x0001..0x0008, 0x000E..0x001F;
$ParseErrorControlCodePosition->{html}->{$_} = 'must',
$ParseErrorControlCodePosition->{1}->{$_} = 'warn',
$ParseErrorControlCodePosition->{1.1}->{$_} = 'must'
    for 0x007F..0x0084, 0x0086..0x009F;

my $ParseErrorNoncharCodePosition = {};
$ParseErrorNoncharCodePosition->{html}->{$_} = 'must',
$ParseErrorNoncharCodePosition->{1}->{$_} = 'warn',
$ParseErrorNoncharCodePosition->{1.1}->{$_} = 'warn'
    for 0xFDD0..0xFDEF;
$ParseErrorNoncharCodePosition->{html}->{$_} = 'must',
$ParseErrorNoncharCodePosition->{1}->{$_} = 'must',
$ParseErrorNoncharCodePosition->{1.1}->{$_} = 'must'
    for 0xFFFE, 0xFFFF;
$ParseErrorNoncharCodePosition->{1}->{$_} = 'must',
$ParseErrorNoncharCodePosition->{1.1}->{$_} = 'must'
    for 0xD800..0xDFFF;
$ParseErrorNoncharCodePosition->{html}->{$_} = 'must',
$ParseErrorNoncharCodePosition->{1}->{$_} = 'warn',
$ParseErrorNoncharCodePosition->{1.1}->{$_} = 'warn'
    for 0x1FFFE, 0x1FFFF, 0x2FFFE, 0x2FFFF, 0x3FFFE, 0x3FFFF, 0x4FFFE,
        0x4FFFF, 0x5FFFE, 0x5FFFF, 0x6FFFE, 0x6FFFF, 0x7FFFE, 0x7FFFF,
        0x8FFFE, 0x8FFFF, 0x9FFFE, 0x9FFFF, 0xAFFFE, 0xAFFFF, 0xBFFFE,
        0xBFFFF, 0xCFFFE, 0xCFFFF, 0xDFFFE, 0xDFFFF, 0xEFFFE, 0xEFFFF,
        0xFFFFE, 0xFFFFF, 0x10FFFE, 0x10FFFF;

sub _set_nc ($) {
  my $self = $_[0];
  {
    if ($self->{chars_pos} < @{$self->{chars}}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      my $lang = $self->{is_xml} || 'html';
      my $c = ord $self->{chars}->[$self->{chars_pos}++];
      if ($c == 0x000A or
          ($c == 0x0085 and $lang eq 1.1)) {
        if ($self->{chars_was_cr}) {
          delete $self->{chars_was_cr};
          redo;
        } else {
          delete $self->{chars_was_cr};
          $self->{line}++;
          $self->{column} = 0;
          $c = 0x000A;
        }
      } elsif ($c == 0x000D) {
        $self->{chars_was_cr} = 1;
        $self->{line}++;
        $self->{column} = 0;
        $c = 0x000A;
      } elsif ($c == 0x2028 and $lang eq 1.1) {
        delete $self->{chars_was_cr};
        $self->{line}++;
        $self->{column} = 0;
        $c = 0x000A;
      } else {
        if (my $level = $ParseErrorControlCodePosition->{$lang}->{$c}) {
          $self->{parse_error}
              ->(type => 'control char', # XXXtype
                 value => (sprintf 'U+%04X', $c),
                 level => $self->{level}->{$level},
                 line => $self->{line},
                 column => $self->{column} + 1);
        } elsif ($level = $ParseErrorNoncharCodePosition->{$lang}->{$c}) {
          $self->{parse_error}
              ->(type => 'nonchar', # XXXtype
                 value => (sprintf 'U+%04X', $c),
                 level => $self->{level}->{$level},
                 line => $self->{line},
                 column => $self->{column} + 1);
        }
        
        delete $self->{chars_was_cr};
        $self->{column}++;
      }
      $self->{nc} = $c;
    } else {
      if ($self->{chars_pull_next}->()) {
        $self->{nc} = ABORT_CHAR;
      } else {
        delete $self->{chars_was_cr};
        $self->{nc} = EOF_CHAR;
      }
    }
  } # block
} # _set_nc

sub _read_chars ($$) {
  my ($self, $stoppers) = @_;
  
  my $start = $self->{chars_pos};
  {
    my $char = $self->{chars}->[$self->{chars_pos}];
    last if not defined $char;
    if ($stoppers->{$char} or $CommonStoppers->{$char}) {
      last;
    } else {
      $self->{chars_pos}++;
    }
    redo;
  }
  return '' if $start == $self->{chars_pos};

  $self->{column} += $self->{chars_pos} - $start;
  return join '', @{$self->{chars}}[$start..($self->{chars_pos}-1)];
} # _read_chars

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
