#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 6185 }

require Whatpm::Charset::DecodeHandle;

my $XML_AUTO_CHARSET = q<http://suika.fam.cx/www/2006/03/xml-entity/>;
my $IANA_CHARSET = q<urn:x-suika-fam-cx:charset:>;
my $PERL_CHARSET = q<http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.>;
my $XML_CHARSET = q<http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.>;

## |create_decode_handle|
for my $test (
  ['perl.utf8', $PERL_CHARSET.'utf8', 1],
  ['xml', $XML_AUTO_CHARSET, 1],
  ['unknown', q<http://www.unknown.test/>, 0],
  ['iana.euc-jp', $IANA_CHARSET.'euc-jp', 1],
  ['xml.euc-jp', $XML_CHARSET.'euc-jp', 1],
  ['iana.shift_jis', $IANA_CHARSET.'shift_jis', 1],
  ['xml.shift_jis', $XML_CHARSET.'shift_jis', 1],
  ['iana.iso-2022-jp', $IANA_CHARSET.'iso-2022-jp', 1],
  ['xml.iso-2022-jp', $XML_CHARSET.'iso-2022-jp', 1],
) {
  open my $fh, '<', \'';
  my $dh = Whatpm::Charset::DecodeHandle->create_decode_handle ($test->[1], $fh);

  if ($test->[2]) {
    ok UNIVERSAL::isa ($dh, 'Whatpm::Charset::DecodeHandle::Encode') ? 1 : 0, 1,
        'create_decode_handle ' . $test->[0] . ' object';
    ok ref $dh->onerror eq 'CODE' ? 1 : 0, 1,
        'create_decode_handle ' . $test->[0] . ' onerror';
  } else {
    ok UNIVERSAL::isa ($dh, 'Whatpm::Charset::DecodeHandle::Encode') ? 1 : 0, 0,
        'create_decode_handle ' . $test->[0] . ' object';

    Whatpm::Charset::DecodeHandle->create_decode_handle ($test->[1], $fh, sub {
      ok $_[1], 'charset-not-supported-error',
          'create_decode_handle ' . $test->[0] . ' error';
    });
  }
}

## |name_to_uri|
for (
          [$IANA_CHARSET.'utf-8', 'utf-8'],
          [$IANA_CHARSET.'x-no-such-charset', 'x-no-such-charset'],
          [$IANA_CHARSET.'utf-8', 'UTF-8'],
          [$IANA_CHARSET.'utf-8', 'uTf-8'],
          [$IANA_CHARSET.'utf-16be', 'utf-16be'],
) {
  my $iname = Whatpm::Charset::DecodeHandle->name_to_uri (ietf => $_->[1]);
  ok $iname, $_->[0], 'ietf charset URI ' . $_->[1];
}

for (
          [$XML_CHARSET.'utf-8', 'utf-8'],
          [$XML_CHARSET.'x-no-such-charset', 'x-no-such-charset'],
          [$XML_CHARSET.'utf-8', 'UTF-8'],
          [$XML_CHARSET.'utf-8', 'uTf-8'],
          [$IANA_CHARSET.'utf-16be', 'utf-16be'],
) {
  my $iname = Whatpm::Charset::DecodeHandle->name_to_uri (xml => $_->[1]);
  ok $iname, $_->[0], 'XML encoding URI ' . $_->[1];
}

## |uri_to_name|
for (
          [$IANA_CHARSET.'utf-8', 'utf-8'],
          [$IANA_CHARSET.'x-no-such-charset', 'x-no-such-charset'],
          [q<http://charset.example/>, undef],
) {
  my $uri = Whatpm::Charset::DecodeHandle->uri_to_name (ietf => $_->[0]);
  ok $uri, $_->[1], 'URI -> IETF charset ' . $_->[0];
}

for (
          [$XML_CHARSET.'utf-8', 'utf-8'],
          [$XML_CHARSET.'x-no-such-charset', 'x-no-such-charset'],
          [q<http://charset.example/>, undef],
) {
  my $uri = Whatpm::Charset::DecodeHandle->uri_to_name (xml => $_->[0]);
  ok $uri, $_->[1], 'URI -> XML encoding ' . $_->[0];
}

## |getc|
{
  my $byte = "a\xE3\x81\x82\x81a";
  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($PERL_CHARSET.'utf8', $fh);
  
  my $error;
  $efh->onerror (sub {
    my ($efh, $type, %opt) = @_;
    $error = ${$opt{octets}};
  });

  ok $efh->getc, "a", "getc 1 [1]";
  ok $error, undef, "getc 1 [1] error";
  ok $efh->getc, "\x{3042}", "getc 1 [2]";
  ok $error, undef, "getc 1 [2] error";
  ok $efh->getc, "\x81", "getc 1 [3]";
  ok $error, "\x81", "getc 1 [3] error";
  undef $error;
  ok $efh->getc, "a", "getc 1 [4]";
  ok $error, undef, "getc 1 [4] error";
  ok $efh->getc, undef, "getc 1 [5]";
  ok $error, undef, "getc 1 [5] error";
}

{
  my $byte = "a" x 256;
  $byte .= "b" x 256;
  
  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($PERL_CHARSET.'utf8', $fh);

  my $error;
  $efh->onerror (sub {
    my ($efh, $type, %opt) = @_;
    $error = ${$opt{octets}};
  });

  for my $i (0..255) {
    ok $efh->getc, "a", "getc 2 [$i]";
    ok $error, undef, "getc 2 [$i] error";
  }

  for my $i (0..255) {
    ok $efh->getc, "b", "getc 2 [255+$i]";
    ok $error, undef, "getc 2 [255+$i] error";
  }

  ok $efh->getc, undef, "getc 2 [-1]";
  ok $error, undef, "getc 2 [-1] error";
}

{
  my $byte = "a" x 255;
  $byte .= "\xE3\x81\x82";
  $byte .= "b" x 256;

  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($PERL_CHARSET.'utf8', $fh);

  my $error;
  $efh->onerror (sub {
    my ($efh, $type, %opt) = @_;
    $error = ${$opt{octets}};
  });

  for my $i (0..254) {
    ok $efh->getc, "a", "getc 3 [$i]";
    ok $error, undef, "getc 3 [$i] error";
  }

  ok $efh->getc, "\x{3042}", "getc 3 [255]";
  ok $error, undef, "getc 3 [255] error";

  for my $i (0..255) {
    ok $efh->getc, "b", "getc 3 [255+$i]";
    ok $error, undef, "getc 3 [255+$i] error";
  }

  ok $efh->getc, undef, "getc 3 [-1]";
  ok $error, undef, "getc 3 [-1] error";
}

{
  my $byte = "a" x 255;
  $byte .= "\xE3";

  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($PERL_CHARSET.'utf8', $fh);

  my $error;
  $efh->onerror (sub {
    my ($efh, $type, %opt) = @_;
    $error = ${$opt{octets}};
  });

  for my $i (0..254) {
    ok $efh->getc, "a", "getc 4 [$i]";
    ok $error, undef, "getc 4 [$i] error";
  }

  ok $efh->getc, "\xE3", "getc 4 [255]";
  ok $error, "\xE3", "getc 4 [255] error";
  undef $error;

  ok $efh->getc, undef, "getc 4 [-1]";
  ok $error, undef, "getc 4 [-1] error";
}

## |ungetc|
{
  my $byte = "a\x{4E00}b\x{4E11}";

  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($PERL_CHARSET.'utf8', $fh);

  ok $efh->getc, "a", "ungetc [1]";

  $efh->ungetc (ord "a");
  ok $efh->getc, "a", "ungetc [2]";

  ok $efh->getc, "\x{4E00}", "ungetc [3]";

  $efh->ungetc (ord "\x{4E00}");
  ok $efh->getc, "\x{4E00}", "ungetc [4]";

  ok $efh->getc, "b", "ungetc [5]";

  ok $efh->getc, "\x{4E11}", "ungetc [6]";

  $efh->ungetc (ord "\x{4E11}");
  ok $efh->getc, "\x{4E11}", "ungetc [7]";
}

## UTF-8, UTF-16 and BOM
for my $test (
  ["UTF-8 BOM 1", qq<\xEF\xBB\xBFabc>, $XML_CHARSET.'utf-8',
   ["a", "b", "c", undef], 1],
  ["UTF-8 no BOM 1", qq<abc>, $XML_CHARSET.'utf-8',
   ["a", "b", "c", undef], 0],
  ["UTF-8 BOM 2", qq<\xEF\xBB\xBF\xEF\xBB\xBFabc>, $XML_CHARSET.'utf-8',
   ["\x{FEFF}", "a", "b", "c", undef], 1],
  ["UTF-8 BOM 3", qq<\xEF\xBB\xBF>, $XML_CHARSET.'utf-8',
   [undef], 1],
  ["UTF-8 no BOM 2", qq<>, $XML_CHARSET.'utf-8',
   [undef], 0],
  ["UTF-8 no BOM 3", qq<ab>, $XML_CHARSET.'utf-8',
   [qw/a b/, undef], 0],
  ["UTF-8 no BOM 4", qq<a>, $XML_CHARSET.'utf-8',
   [qw/a/, undef], 0],
  ["UTF-16BE BOM 1", qq<\xFE\xFF\x4E\x00\x00a>, $XML_CHARSET.'utf-16',
   ["\x{4E00}", "a", undef], 1],
  ["UTF-16LE BOM 1", qq<\xFF\xFE\x00\x4Ea\x00>, $XML_CHARSET.'utf-16',
   ["\x{4E00}", "a", undef], 1],
  ["UTF-16BE BOM 2", qq<\xFE\xFF\x00a>, $XML_CHARSET.'utf-16',
   ["a", undef], 1],
  ["UTF-16LE BOM 2", qq<\xFF\xFEa\x00>, $XML_CHARSET.'utf-16',
   ["a", undef], 1],
  ["UTF-16BE BOM 3", qq<\xFE\xFF>, $XML_CHARSET.'utf-16',
   [undef], 1],
  ["UTF-16LE BOM 3", qq<\xFF\xFE>, $XML_CHARSET.'utf-16',
   [undef], 1],
) {
  my $error;
  
  open my $fh, '<', \($test->[1]);
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($test->[2], $fh, sub { $error = 1 });

  for my $i (0..$#{$test->[3]}) {
    ok $efh->getc, $test->[3]->[$i], $test->[0] . " $i";
  }
  ok $error, undef, $test->[0] . " error";
  ok $efh->has_bom ? 1 : 0, $test->[4], $test->[0] . " has_bom";
}

{
  my $byte = qq<\xFE\xFFa>;

  my $error;

  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($XML_CHARSET.'utf-16', $fh, sub { $error = $_[1] });

  ok $error, undef, "UTF-16 [1]";
  ok $efh->getc, "a", "UTF-16 [2]";
  ok $error, 'illegal-octets-error', "UTF-16 [3]";
  undef $error;
  ok $efh->getc, undef, "UTF-16 [4]";
  ok $error, undef, "UTF-16 [5]";
  ok $efh->has_bom ? 1 : 0, 1, "UTF-16 [6]";
}
{
  my $byte = qq<\xFF\xFEa>;

  my $error;

  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($XML_CHARSET.'utf-16', $fh, sub { $error = $_[1] });

  ok $error, undef, "UTF-16 [7]";
  ok $efh->getc, "a", "UTF-16 [8]";
  ok $error, 'illegal-octets-error', "UTF-16 [9]";
  undef $error;
  ok $efh->getc, undef, "UTF-16 [10]";
  ok $error, undef, "UTF-16 [11]";
  ok $efh->has_bom ? 1 : 0, 1, "UTF-16 [12]";
}

{
  my $byte = qq<\xFD\xFF>;
  
  my $error;
  
  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($XML_CHARSET.'utf-16', $fh, sub { $error = $_[1] });

  ok $error, 'no-bom-error', "UTF-16 [13]";
  undef $error;

  ok $efh->getc, "\x{FDFF}", "UTF-16 [14]";
  ok $error, undef, "UTF-16 [15]";
  ok $efh->getc, undef, "UTF-16 [16]";
  ok $error, undef, "UTF-16 [17]";
  ok $efh->has_bom ? 1 : 0, 0, "UTF-16 [18]";
}

{
  my $byte = qq<\xFD>;
  
  my $error;
  
  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($XML_CHARSET.'utf-16', $fh, sub { $error = $_[1] });

  ok $error, 'no-bom-error', "UTF-16 [19]";
  undef $error;

  ok $efh->getc, "\xFD", "UTF-16 [20]";
  ok $error, 'illegal-octets-error', "UTF-16 [21]";
  undef $error;

  ok $efh->getc, undef, "UTF-16 [22]";
  ok $error, undef, "UTF-16 [23]";
  ok $efh->has_bom ? 1 : 0, 0, "UTF-16 [24]";
}

{
  my $byte = qq<>;
  
  my $error;
  
  open my $fh, '<', \$byte;
  my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($XML_CHARSET.'utf-16', $fh, sub { $error = $_[1] });

  ok $error, 'no-bom-error', "UTF-16 [25]";
  undef $error;

  ok $efh->getc, undef, "UTF-16 [26]";
  ok $error, undef, "UTF-16 [27]";
  ok $efh->has_bom ? 1 : 0, 0, "UTF-16 [28]";
}

sub check_charset ($$$) {
  my $test_name = $_[0];
  my $charset_uri = $_[1];
  for my $testdata (@{$_[2]}) {
    my $byte = $testdata->{in};
    my $error;
    my $i = 0;

    open my $fh, '<', \$byte;
    my $efh = Whatpm::Charset::DecodeHandle->create_decode_handle
        ($charset_uri, $fh, sub {
           my (undef, $etype, %opt) = @_;
           $error = [$etype, \%opt];
         });

    ok defined $efh ? 1 : 0, 1, "$test_name $testdata->{id} return";
    next unless defined $efh;
    ok $efh->has_bom ? 1 : 0, $testdata->{bom} || 0,
        "$test_name $testdata->{id} BOM";
    ok $efh->input_encoding, $testdata->{name}, "$test_name $testdata->{id} ie";

    while (@{$testdata->{out}}) {
      if ($i != 0) {
        my $c = shift @{$testdata->{out}};
        ok $efh->getc, $c, "$test_name $testdata->{id} $i";
      }

      my $v = shift @{$testdata->{out}};
      if (defined $v) {
        ok defined $error ? 1 : 0, 1, "$test_name $testdata->{id} $i error";
        ok $error->[0], $v->[0], "$test_name $testdata->{id} $i error 0";
      } else {
        ok defined $error ? 1 : 0, 0, "$test_name $testdata->{id} $i error";
      }
      undef $error;
      $i++;
    }

    ok $efh->getc, undef, "$test_name $testdata->{id} EOF";
    if ($testdata->{eof_error}) {
      ok defined $error ? 1 : 0, 1, "$test_name $testdata->{id} EOF error";
      ok $error->[0], $testdata->{eof_error}->[0],
          "$test_name $testdata->{id} EOF error 0";
    } else {
      ok $error, undef, "$test_name $testdata->{id} EOF error";
    }
  } # testdata
} # check_charset

## XML Character Encoding Autodetection
{
  my @testdata = (
        {
          id => q<l=0>,
          in => q<>,
          out => [undef],
          name => 'utf-8', bom => 0,
        },
        {
          id => q<l=1>,
          in => "a",
          out => [undef, "a", undef],
          name => 'utf-8', bom => 0,
        },
        {
          id => q<bom8.l=0>,
          in => "\xEF\xBB\xBF",
          out => [undef],
          name => 'utf-8', bom => 1,
        },
        {
          id => q<bom8.l=1>,
          in => "\xEF\xBB\xBFa",
          out => [undef, "a", undef],
          name => 'utf-8', bom => 1,
        },
        {
          id => q<bom8.zwnbsp>,
          in => "\xEF\xBB\xBF\xEF\xBB\xBF",
          out => [undef, "\x{FEFF}", undef],
          name => 'utf-8', bom => 1,
        },
        {
          id => q<bom16be.l=0>,
          in => "\xFE\xFF",
          out => [undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.l=0>,
          in => "\xFF\xFE",
          out => [undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16be.l=1>,
          in => "\xFE\xFFa",
          out => [undef, "a", [q<illegal-octets-error>]],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.l=1>,
          in => "\xFF\xFEa",
          out => [undef, "a", [q<illegal-octets-error>]],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16be.l=2>,
          in => "\xFE\xFF\x4E\x00",
          out => [undef, "\x{4E00}", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.l=2>,
          in => "\xFF\xFE\x00\x4E",
          out => [undef, "\x{4E00}", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16be.l=2lt>,
          in => "\xFE\xFF\x00<",
          out => [undef, "<", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.l=2lt>,
          in => "\xFF\xFE<\x00",
          out => [undef, "<", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16be.zwnbsp>,
          in => "\xFE\xFF\xFE\xFF",
          out => [undef, "\x{FEFF}", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.zwnbsp>,
          in => "\xFF\xFE\xFF\xFE",
          out => [undef, "\x{FEFF}", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom32e3412.l=0>,
          in => "\xFE\xFF\x00\x00",
          out => [undef, "\x00", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom32e4321.l=0>,
          in => "\xFF\xFE\x00\x00",
          out => [undef, "\x00", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16be.l=4ltq>,
          in => "\xFE\xFF\x00<\x00?",
          out => [undef, "<", undef, "?", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.l=4ltq>,
          in => "\xFF\xFE<\x00?\x00",
          out => [undef, "<", undef, "?", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16be.decl.1>,
          in => qq[\xFE\xFF\x00<\x00?\x00x\x00m\x00l\x00 \x00v\x00e\x00r].
                qq[\x00s\x00i\x00o\x00n\x00=\x00"\x001\x00.\x000\x00"].
                qq[\x00 \x00e\x00n\x00c\x00o\x00d\x00i\x00n\x00g\x00=].
                qq[\x00"\x00u\x00t\x00f\x00-\x001\x006\x00"\x00?\x00>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "1", undef,
                  "6", undef, '"', undef, "?", undef, ">", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<bom16le.decl.1>,
          in => qq[\xFF\xFE<\x00?\x00x\x00m\x00l\x00 \x00v\x00e\x00r].
                qq[\x00s\x00i\x00o\x00n\x00=\x00"\x001\x00.\x000\x00"].
                qq[\x00 \x00e\x00n\x00c\x00o\x00d\x00i\x00n\x00g\x00=].
                qq[\x00"\x00u\x00t\x00f\x00-\x001\x006\x00"\x00?\x00>\x00],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "1", undef,
                  "6", undef, '"', undef, "?", undef, ">", undef],
          name => 'utf-16', bom => 1,
        },
        {
          id => q<utf16be.decl.1>,
          in => qq[\x00<\x00?\x00x\x00m\x00l\x00 \x00v\x00e\x00r].
                qq[\x00s\x00i\x00o\x00n\x00=\x00"\x001\x00.\x000\x00"].
                qq[\x00 \x00e\x00n\x00c\x00o\x00d\x00i\x00n\x00g\x00=].
                qq[\x00"\x00u\x00t\x00f\x00-\x001\x006\x00b\x00e\x00"\x00?\x00>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "1", undef,
                  "6", undef, "b", undef, "e", undef, '"', undef,
                  "?", undef, ">", undef],
          name => 'utf-16be', bom => 0,
        },
        {
          id => q<utf16le.decl.1>,
          in => qq[<\x00?\x00x\x00m\x00l\x00 \x00v\x00e\x00r].
                qq[\x00s\x00i\x00o\x00n\x00=\x00"\x001\x00.\x000\x00"].
                qq[\x00 \x00e\x00n\x00c\x00o\x00d\x00i\x00n\x00g\x00=].
                qq[\x00"\x00u\x00t\x00f\x00-\x001\x006\x00l\x00e\x00"].
                qq[\x00?\x00>\x00],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "1", undef,
                  "6", undef, "l", undef, "e", undef, '"', undef, "?", undef,
                  ">", undef],
          name => 'utf-16le', bom => 0,
        },
        {
          id => q<16be.decl.1>,
          in => qq[\x00<\x00?\x00x\x00m\x00l\x00 \x00v\x00e\x00r].
                qq[\x00s\x00i\x00o\x00n\x00=\x00"\x001\x00.\x000\x00"].
                qq[\x00 \x00e\x00n\x00c\x00o\x00d\x00i\x00n\x00g\x00=].
                qq[\x00"\x00u\x00t\x00f\x00-\x001\x006\x00"\x00?\x00>],
          out => [[q<charset-name-mismatch-error>],
                  "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "1", undef,
                  "6", undef, '"', undef, "?", undef, ">", undef],
          name => 'utf-16', bom => 0,
        },
        {
          id => q<16le.decl.1>,
          in => qq[<\x00?\x00x\x00m\x00l\x00 \x00v\x00e\x00r].
                qq[\x00s\x00i\x00o\x00n\x00=\x00"\x001\x00.\x000\x00"].
                qq[\x00 \x00e\x00n\x00c\x00o\x00d\x00i\x00n\x00g\x00=].
                qq[\x00"\x00u\x00t\x00f\x00-\x001\x006\x00"\x00?\x00>\x00],
          out => [[q<charset-name-mismatch-error>],
                  "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "1", undef,
                  "6", undef, '"', undef, "?", undef, ">", undef],
          name => 'utf-16', bom => 0,
        },
        {
          id => q<8.decl.1>,
          in => qq[<?xml version="1.0" encoding="utf-8"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "8", undef,
                  '"', undef, "?", undef, ">", undef],
          name => 'utf-8', bom => 0,
        },
        {
          id => q<8.decl.2>,
          in => qq[<?xml encoding="utf-8"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "8", undef,
                  '"', undef, "?", undef, ">", undef],
          name => 'utf-8', bom => 0,
        },
        {
          id => q<8.decl.3>,
          in => qq[<?xml version="1.1" encoding="utf-8"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "1", undef, '"', undef, " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "8", undef,
                  '"', undef, "?", undef, ">", undef],
          name => 'utf-8', bom => 0,
        },
        {
          id => q<8.decl.4>,
          in => qq[<?xml version="1.0"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef, "v", undef, "e", undef, "r", undef, "s", undef,
                  "i", undef, "o", undef, "n", undef, "=", undef, '"', undef,
                  "1", undef, ".", undef, "0", undef, '"', undef, 
                  "?", undef, ">", undef],
          name => 'utf-8', bom => 0,
        },
        {
          id => q<bom8.decl.1>,
          in => qq[\xEF\xBB\xBF<?xml encoding="utf-8"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "t", undef, "f", undef, "-", undef, "8", undef,
                  '"', undef, "?", undef, ">", undef],
          name => 'utf-8', bom => 1,
        },
        {
          id => q<us-ascii.decl.1>,
          in => qq[<?xml encoding="us-ascii"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "u", undef, "s", undef, "-", undef, "a", undef, "s", undef,
                  "c", undef, "i", undef, "i", undef,
                  '"', undef, "?", undef, ">", undef],
          name => 'us-ascii', bom => 0,
        },
        {
          id => q<us-ascii.decl.2>,
          in => qq[<?xml encoding="US-ascii"?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, '"', undef,
                  "U", undef, "S", undef, "-", undef, "a", undef, "s", undef,
                  "c", undef, "i", undef, "i", undef,
                  '"', undef, "?", undef, ">", undef],
          name => 'us-ascii', bom => 0,
        },
        {
          id => q<us-ascii.decl.3>,
          in => qq[<?xml encoding='us-ascii'?>],
          out => [undef, "<", undef, "?", undef, "x", undef, "m", undef, "l", undef,
                  " ", undef,
                  "e", undef, "n", undef, "c", undef, "o", undef, "d", undef,
                  "i", undef, "n", undef, "g", undef, "=", undef, "'", undef,
                  "u", undef, "s", undef, "-", undef, "a", undef, "s", undef,
                  "c", undef, "i", undef, "i", undef,
                  "'", undef, "?", undef, ">", undef],
          name => 'us-ascii', bom => 0,
        },
  );
  check_charset ('XML', $XML_AUTO_CHARSET, \@testdata);
}

## EUC-JP
{
      my @testdata = (
        {
          id => q<l=0>,
          in => q<>,
          out => [undef],
        },
        {
          id => q<l=1.00>,
          in => qq<\x00>,
          out => [undef, "\x00", undef],
        },
        {
          id => q<l=1.0d>,
          in => qq<\x0D>,
          out => [undef, "\x0D", undef],
        },
        {
          id => q<l=1.0e>,
          in => qq<\x0E>,
          out => [undef, "\x0E", undef],
        }, # Error??
        {
          id => q<l=1.0f>,
          in => qq<\x0F>,
          out => [undef, "\x0F", undef],
        }, # Error??
        {
          id => q<l=1.1b>,
          in => qq<\x1B>,
          out => [undef, "\x1B", undef],
        }, # Error??
        {
          id => q<l=1.a>,
          in => q<a>,
          out => [undef, "a", undef],
        },
        {
          id => q<l=1.20>,
          in => qq<\x20>,
          out => [undef, "\x20", undef],
        },
        {
          id => q<5C>,
          in => qq<\x5C>,
          out => [undef, "\x5C", undef],
        },
        {
          id => q<l=1.7E>,
          in => qq<\x7E>,
          out => [undef, "\x7E", undef],
        },
        {
          id => q<l=1.7F>,
          in => qq<\x7F>,
          out => [undef, "\x7F", undef],
        },
        {
          id => q<l=1.80>,
          in => qq<\x80>,
          out => [undef, "\x80", undef],
        },
        {
          id => q<l=1.8c>,
          in => qq<\x8C>,
          out => [undef, "\x8C", undef],
        },
        {
          id => q<l=1.8e>,
          in => qq<\x8E>,
          out => [undef, "\x8E", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.8f>,
          in => qq<\x8F>,
          out => [undef, "\x8F", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a0>,
          in => qq<\xA0>,
          out => [undef, "\xA0", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.a1>,
          in => qq<\xA1>,
          out => [undef, "\xA1", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a2>,
          in => qq<\xA2>,
          out => [undef, "\xA2", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.fd>,
          in => qq<\xFD>,
          out => [undef, "\xFD", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.fe>,
          in => qq<\xFE>,
          out => [undef, "\xFE", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.ff>,
          in => qq<\xFF>,
          out => [undef, "\xFF", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=2.0000>,
          in => qq<\x00\x00>,
          out => [undef, "\x00", undef, "\x00", undef],
        },
        {
          id => q<l=2.0D0A>,
          in => qq<\x0D\x0A>,
          out => [undef, "\x0D", undef, "\x0A", undef],
        },
        {
          id => q<l=2.1B28>,
          in => qq<\x1B\x28>,
          out => [undef, "\x1B", undef, "\x28", undef],
        },# Error??
        {
          id => q<l=2.2020>,
          in => qq<\x20\x20>,
          out => [undef, "\x20", undef, "\x20", undef],
        },
        {
          id => q<l=2.ab>,
          in => qq<ab>,
          out => [undef, "a", undef, "b", undef],
        },
        {
          id => q<l=2.a0a1>,
          in => qq<\xA0\xA1>,
          out => [undef, "\xA0", [q<unassigned-code-point-error>],
                        "\xA1", [q<illegal-octets-error>]],
        },
        {
          id => q<l=2.a1a1>,
          in => qq<\xA1\xA1>,
          out => [undef, "\x{3000}", undef],
        },
        {
          id => q<l=2.a1a2>,
          in => qq<\xA1\xA2>,
          out => [undef, "\x{3001}", undef],
        },
        {
          id => q<l=2.a1a4>,
          in => qq<\xA1\xA4>,
          out => [undef, "\x{FF0C}", undef], # FULLWIDTH COMMA
        },
        {
          id => q<a1a6>,
          in => qq<\xA1\xA6>,
          out => [undef, "\x{30FB}", undef], # KATAKABA MIDDLE DOT
        },
        {
          id => q<a1a7>,
          in => qq<\xA1\xA7>,
          out => [undef, "\x{FF1A}", undef], # FULLWIDTH COLON
        },
        {
          id => q<a1b1>,
          in => qq<\xA1\xB1>,
          out => [undef, "\x{203E}", undef], # OVERLINE
        },
        {
          id => q<a1bd>,
          in => qq<\xA1\xBD>,
          out => [undef, "\x{2014}", undef], # EM DASH
        },
        {
          id => q<a1c0>,
          in => qq<\xA1\xC0>,
          out => [undef, "\x{FF3C}", undef], # FULLWIDTH REVERSE SOLIDUS
        },
        {
          id => q<a1c1>,
          in => qq<\xA1\xC1>,
          out => [undef, "\x{301C}", undef], # WAVE DASH
        },
        {
          id => q<a1c2>,
          in => qq<\xA1\xC2>,
          out => [undef, "\x{2016}", undef], # DOUBLE VERTICAL LINE
        },
        {
          id => q<a1c4>,
          in => qq<\xA1\xC4>,
          out => [undef, "\x{2026}", undef], # HORIZONTAL ELLIPSIS
        },
        {
          id => q<a1dd>,
          in => qq<\xA1\xDD>,
          out => [undef, "\x{2212}", undef], # MINUS SIGN
        },
        {
          id => q<a1ef>,
          in => qq<\xA1\xEF>,
          out => [undef, "\x{00A5}", undef], # YEN SIGN
        },
        {
          id => q<a1f1>,
          in => qq<\xA1\xF1>,
          out => [undef, "\x{00A2}", undef], # CENT SIGN
        },
        {
          id => q<a1f2>,
          in => qq<\xA1\xF2>,
          out => [undef, "\x{00A3}", undef], # POUND SIGN
        },
        {
          id => q<a1f2>,
          in => qq<\xA1\xFF>,
          out => [undef, "\xA1", [q<illegal-octets-error>],
                        "\xFF", [q<unassigned-code-point-error>]],
        },
        {
          id => q<a2ae>,
          in => qq<\xA2\xAE>,
          out => [undef, "\x{3013}", undef], # GETA MARK
        },
        {
          id => q<a2af>,
          in => qq<\xA2\xAF>,
          out => [undef, "\xA2\xAF", [q<unassigned-code-point-error>]],
        },
        {
          id => q<a2ba>,
          in => qq<\xA2\xBA>,
          out => [undef, "\x{2208}", undef], # ELEMENT OF
        },
        {
          id => q<a2fe>,
          in => qq<\xA2\xFE>,
          out => [undef, "\x{25EF}", undef], # LARGE CIRCLE
        },
        {
          id => q<adce>,
          in => qq<\xAD\xCE>,
          out => [undef, "\xAD\xCE", [q<unassigned-code-point-error>]],
        },
        {
          id => q<b0a6>,
          in => qq<\xB0\xA6>,
          out => [undef, "\x{611B}", undef], # han
        },
        {
          id => q<f4a6>,
          in => qq<\xF4\xA6>,
          out => [undef, "\x{7199}", undef], # han
        },
        {
          id => q<8ea1>,
          in => qq<\x8E\xA1>,
          out => [undef, "\x{FF61}", undef],
        },
        {
          id => q<8efe>,
          in => qq<\x8E\xFE>,
          out => [undef, "\x8E\xFE", [q<unassigned-code-point-error>]],
        },
        {
          id => q<8ffe>,
          in => qq<\x8F\xFE>,
          out => [undef, "\x8F\xFE", [q<illegal-octets-error>]],
        },
        {
          id => q<l=2.a1a2a3>,
          in => qq<\xA1\xA2\xA3>,
          out => [undef, "\x{3001}", undef,
                        "\xA3", [q<illegal-octets-error>]],
        },
        {
          id => q<8ea1a1>,
          in => qq<\x8E\xA1\xA1>,
          out => [undef, "\x{FF61}", undef,
                        "\xA1", [q<illegal-octets-error>]],
        },
        {
          id => q<8fa1a1>,
          in => qq<\x8F\xA1\xA1>,
          out => [undef, "\x8F\xA1\xA1", [q<unassigned-code-point-error>]],
        },
        {
          id => q<8fa2af>,
          in => qq<\x8F\xA2\xAF>,
          out => [undef, "\x{02D8}", undef],
        },
        {
          id => q<8fa2b7>,
          in => qq<\x8F\xA2\xB7>,
          out => [undef, "\x{FF5E}", undef], # FULLWIDTH TILDE
        },
        {
          id => q<a1a2a1a3>,
          in => qq<\xA1\xA2\xA1\xA3>,
          out => [undef, "\x{3001}", undef, "\x{3002}", undef],
        },
        {
          id => q<8fa2af>,
          in => qq<\x8F\xA2\xAF\xAF>,
          out => [undef, "\x{02D8}", undef,
                        "\xAF", [q<illegal-octets-error>]],
        },
        {
          id => q<8fa2afafa1>,
          in => qq<\x8F\xA2\xAF\xAF\xA1>,
          out => [undef, "\x{02D8}", undef,
                        "\xAF\xA1", [q<unassigned-code-point-error>]],
        },
      );
  check_charset ('XML-EUC-JP', $XML_CHARSET.'euc-jp', \@testdata);
}

## Shift_JIS
{
      my @testdata = (
        {
          id => q<l=0>,
          in => q<>,
          out => [undef],
        },
        {
          id => q<l=1.00>,
          in => qq<\x00>,
          out => [undef, "\x00", undef],
        },
        {
          id => q<l=1.0d>,
          in => qq<\x0D>,
          out => [undef, "\x0D", undef],
        },
        {
          id => q<l=1.0e>,
          in => qq<\x0E>,
          out => [undef, "\x0E", undef],
        }, # Error??
        {
          id => q<l=1.0f>,
          in => qq<\x0F>,
          out => [undef, "\x0F", undef],
        }, # Error??
        {
          id => q<l=1.1b>,
          in => qq<\x1B>,
          out => [undef, "\x1B", undef],
        }, # Error??
        {
          id => q<l=1.a>,
          in => q<a>,
          out => [undef, "a", undef],
        },
        {
          id => q<l=1.20>,
          in => qq<\x20>,
          out => [undef, "\x20", undef],
        },
        {
          id => q<l=1.5C>,
          in => qq<\x5C>,
          out => [undef, "\xA5", undef], # YEN SIGN
        },
        {
          id => q<l=1.7E>,
          in => qq<\x7E>,
          out => [undef, "\x{203E}", undef], # OVERLINE
        },
        {
          id => q<l=1.7F>,
          in => qq<\x7F>,
          out => [undef, "\x7F", undef],
        },
        {
          id => q<l=1.80>,
          in => qq<\x80>,
          out => [undef, "\x80", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.8c>,
          in => qq<\x8C>,
          out => [undef, "\x8C", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.8e>,
          in => qq<\x8E>,
          out => [undef, "\x8E", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.8f>,
          in => qq<\x8F>,
          out => [undef, "\x8F", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a0>,
          in => qq<\xA0>,
          out => [undef, "\xA0", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.a1>,
          in => qq<\xA1>,
          out => [undef, "\x{FF61}", undef],
        },
        {
          id => q<l=1.a2>,
          in => qq<\xA2>,
          out => [undef, "\x{FF62}", undef],
        },
        {
          id => q<l=1.df>,
          in => qq<\xdf>,
          out => [undef, "\x{FF9F}", undef],
        },
        {
          id => q<l=1.e0>,
          in => qq<\xe0>,
          out => [undef, "\xE0", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.ef>,
          in => qq<\xEF>,
          out => [undef, "\xEF", [q<illegal-octets-error>]],
        },
        {
          id => q<F0>,
          in => qq<\xF0>,
          out => [undef, "\xF0", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.fc>,
          in => qq<\xFC>,
          out => [undef, "\xFC", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.fd>,
          in => qq<\xFD>,
          out => [undef, "\xFD", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.fe>,
          in => qq<\xFE>,
          out => [undef, "\xFE", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=1.ff>,
          in => qq<\xFF>,
          out => [undef, "\xFF", [q<unassigned-code-point-error>]],
        },
        {
          id => q<l=2.0000>,
          in => qq<\x00\x00>,
          out => [undef, "\x00", undef, "\x00", undef],
        },
        {
          id => q<l=2.0D0A>,
          in => qq<\x0D\x0A>,
          out => [undef, "\x0D", undef, "\x0A", undef],
        },
        {
          id => q<l=2.1B28>,
          in => qq<\x1B\x28>,
          out => [undef, "\x1B", undef, "\x28", undef],
        },# Error??
        {
          id => q<l=2.2020>,
          in => qq<\x20\x20>,
          out => [undef, "\x20", undef, "\x20", undef],
        },
        {
          id => q<l=2.ab>,
          in => qq<ab>,
          out => [undef, "a", undef, "b", undef],
        },
        {
          id => q<8040>,
          in => qq<\x80\x40>,
          out => [undef, "\x80", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<8100>,
          in => qq<\x81\x00>,
          out => [undef, "\x81\x00", [q<unassigned-code-point-error>]],
        },
        {
          id => q<8101>,
          in => qq<\x81\x01>,
          out => [undef, "\x81\x01", [q<unassigned-code-point-error>]],
        },
        {
          id => q<813F>,
          in => qq<\x81\x3F>,
          out => [undef, "\x81\x3F", [q<unassigned-code-point-error>]],
        },
        {
          id => q<8140>,
          in => qq<\x81\x40>,
          out => [undef, "\x{3000}", undef],
        },
        {
          id => q<8141>,
          in => qq<\x81\x41>,
          out => [undef, "\x{3001}", undef],
        },
        {
          id => q<8143>,
          in => qq<\x81\x43>,
          out => [undef, "\x{FF0C}", undef], # FULLWIDTH COMMA
        },
        {
          id => q<8150>,
          in => qq<\x81\x50>,
          out => [undef, "\x{FFE3}", undef], # FULLWIDTH MACRON
        },
        {
          id => q<815C>,
          in => qq<\x81\x5C>,
          out => [undef, "\x{2014}", undef], # EM DASH
        },
        {
          id => q<815F>,
          in => qq<\x81\x5F>,
          out => [undef, "\x{005C}", undef], # REVERSE SOLIDUS
        },
        {
          id => q<8160>,
          in => qq<\x81\x60>,
          out => [undef, "\x{301C}", undef], # WAVE DASH
        },
        {
          id => q<8161>,
          in => qq<\x81\x61>,
          out => [undef, "\x{2016}", undef], # DOUBLE VERTICAL LINE
        },
        {
          id => q<8163>,
          in => qq<\x81\x63>,
          out => [undef, "\x{2026}", undef], # HORIZONTAL ELLIPSIS
        },
        {
          id => q<817C>,
          in => qq<\x81\x7C>,
          out => [undef, "\x{2212}", undef], # MINUS SIGN
        },
        {
          id => q<817F>,
          in => qq<\x81\x7F>,
          out => [undef, "\x81\x7F", [q<unassigned-code-point-error>]],
        },
        {
          id => q<818F>,
          in => qq<\x81\x8F>,
          out => [undef, "\x{FFE5}", undef], # FULLWIDTH YEN SIGN
        },
        {
          id => q<8191>,
          in => qq<\x81\x91>,
          out => [undef, "\x{00A2}", undef], # CENT SIGN
        },
        {
          id => q<8192>,
          in => qq<\x81\x92>,
          out => [undef, "\x{00A3}", undef], # POUND SIGN
        },
        {
          id => q<81AC>,
          in => qq<\x81\xAC>,
          out => [undef, "\x{3013}", undef], # GETA MARK
        },
        {
          id => q<81AD>,
          in => qq<\x81\xAD>,
          out => [undef, "\x81\xAD", [q<unassigned-code-point-error>]],
        },
        {
          id => q<81B8>,
          in => qq<\x81\xB8>,
          out => [undef, "\x{2208}", undef], # ELEMENT OF
        },
        {
          id => q<81CA>,
          in => qq<\x81\xCA>,
          out => [undef, "\x{00AC}", undef], # NOT SIGN
        },
        {
          id => q<81FC>,
          in => qq<\x81\xFC>,
          out => [undef, "\x{25EF}", undef], # LARGE CIRCLE
        },
        {
          id => q<81FD>,
          in => qq<\x81\xFD>,
          out => [undef, "\x81\xFD", [q<unassigned-code-point-error>]],
        },
        {
          id => q<81FE>,
          in => qq<\x81\xFE>,
          out => [undef, "\x81\xFE", [q<unassigned-code-point-error>]],
        },
        {
          id => q<81FF>,
          in => qq<\x81\xFF>,
          out => [undef, "\x81\xFF", [q<unassigned-code-point-error>]],
        },
        {
          id => q<DDDE>,
          in => qq<\xDD\xDE>,
          out => [undef, "\x{FF9D}", undef, "\x{FF9E}", undef],
        },
        {
          id => q<e040>,
          in => qq<\xE0\x40>,
          out => [undef, "\x{6F3E}", undef],
        },
        {
          id => q<eaa4>,
          in => qq<\xEA\xA4>,
          out => [undef, "\x{7199}", undef],
        },
        {
          id => q<eaa5>,
          in => qq<\xEA\xA5>,
          out => [undef, "\xEA\xA5", [q<unassigned-code-point-error>]],
        },
        {
          id => q<eb40>,
          in => qq<\xEB\x40>,
          out => [undef, "\xEB\x40", [q<unassigned-code-point-error>]],
        },
        {
          id => q<ed40>,
          in => qq<\xED\x40>,
          out => [undef, "\xED\x40", [q<unassigned-code-point-error>]],
        },
        {
          id => q<effc>,
          in => qq<\xEF\xFC>,
          out => [undef, "\xEF\xFC", [q<unassigned-code-point-error>]],
        },
        {
          id => q<f040>,
          in => qq<\xF0\x40>,
          out => [undef, "\xF0", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<f140>,
          in => qq<\xF1\x40>,
          out => [undef, "\xF1", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<fb40>,
          in => qq<\xFB\x40>,
          out => [undef, "\xFB", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<fc40>,
          in => qq<\xFc\x40>,
          out => [undef, "\xFC", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<fd40>,
          in => qq<\xFD\x40>,
          out => [undef, "\xFD", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<fE40>,
          in => qq<\xFE\x40>,
          out => [undef, "\xFE", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<ff40>,
          in => qq<\xFF\x40>,
          out => [undef, "\xFF", [q<unassigned-code-point-error>],
                        "\x40", undef],
        },
        {
          id => q<81408142>,
          in => qq<\x81\x40\x81\x42>,
          out => [undef, "\x{3000}", undef, "\x{3002}", undef],
        },
      );

  check_charset ('XML-Shift_JIS', $XML_CHARSET.'shift_jis', \@testdata);
}

## ISO-2022-JP
{

      my @testdata = (
        {
          id => q<l=0>,
          in => q<>,
          out1 => [undef],
          out2 => [undef],
        },
        {
          id => q<l=1.00>,
          in => qq<\x00>,
          out1 => [undef, "\x00", undef],
          out2 => [undef, "\x00", undef],
        },
        {
          id => q<l=1.0d>,
          in => qq<\x0D>,
          out1 => [undef, "\x0D", undef],
          out2 => [undef, "\x0D", undef],
        }, # Error?
        {
          id => q<0A>,
          in => qq<\x0A>,
          out1 => [undef, "\x0A", undef],
          out2 => [undef, "\x0A", undef],
        }, # Error?
        {
          id => q<l=1.0e>,
          in => qq<\x0E>,
          out1 => [undef, "\x0E", [q<illegal-octets-error>]],
          out2 => [undef, "\x0E", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.0f>,
          in => qq<\x0F>,
          out1 => [undef, "\x0F", [q<illegal-octets-error>]],
          out2 => [undef, "\x0F", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.1b>,
          in => qq<\x1B>,
          out1 => [undef, "\x1B", [q<illegal-octets-error>]],
          out2 => [undef, "\x1B", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a>,
          in => q<a>,
          out1 => [undef, "a", undef],
          out2 => [undef, "a", undef],
        },
        {
          id => q<l=1.20>,
          in => qq<\x20>,
          out1 => [undef, "\x20", undef],
          out2 => [undef, "\x20", undef],
        },
        {
          id => q<l=1.5C>,
          in => qq<\x5C>,
          out1 => [undef, "\x5C", undef],
          out2 => [undef, "\x5C", undef],
        },
        {
          id => q<l=1.7E>,
          in => qq<\x7E>,
          out1 => [undef, "\x7E", undef],
          out2 => [undef, "\x7E", undef],
        },
        {
          id => q<l=1.7F>,
          in => qq<\x7F>,
          out1 => [undef, "\x7F", undef],
          out2 => [undef, "\x7F", undef],
        },
        {
          id => q<l=1.80>,
          in => qq<\x80>,
          out1 => [undef, "\x80", [q<illegal-octets-error>]],
          out2 => [undef, "\x80", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.8c>,
          in => qq<\x8C>,
          out1 => [undef, "\x8C", [q<illegal-octets-error>]],
          out2 => [undef, "\x8C", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.8e>,
          in => qq<\x8E>,
          out1 => [undef, "\x8E", [q<illegal-octets-error>]],
          out2 => [undef, "\x8E", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.8f>,
          in => qq<\x8F>,
          out1 => [undef, "\x8F", [q<illegal-octets-error>]],
          out2 => [undef, "\x8F", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a0>,
          in => qq<\xA0>,
          out1 => [undef, "\xA0", [q<illegal-octets-error>]],
          out2 => [undef, "\xA0", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a1>,
          in => qq<\xA1>,
          out1 => [undef, "\xA1", [q<illegal-octets-error>]],
          out2 => [undef, "\xA1", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.a2>,
          in => qq<\xA2>,
          out1 => [undef, "\xA2", [q<illegal-octets-error>]],
          out2 => [undef, "\xA2", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.df>,
          in => qq<\xdf>,
          out1 => [undef, "\xDF", [q<illegal-octets-error>]],
          out2 => [undef, "\xDF", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.e0>,
          in => qq<\xe0>,
          out1 => [undef, "\xE0", [q<illegal-octets-error>]],
          out2 => [undef, "\xE0", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.ef>,
          in => qq<\xEF>,
          out1 => [undef, "\xEF", [q<illegal-octets-error>]],
          out2 => [undef, "\xEF", [q<illegal-octets-error>]],
        },
        {
          id => q<F0>,
          in => qq<\xF0>,
          out1 => [undef, "\xF0", [q<illegal-octets-error>]],
          out2 => [undef, "\xF0", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.fc>,
          in => qq<\xFC>,
          out1 => [undef, "\xFC", [q<illegal-octets-error>]],
          out2 => [undef, "\xFC", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.fd>,
          in => qq<\xFD>,
          out1 => [undef, "\xFD", [q<illegal-octets-error>]],
          out2 => [undef, "\xFD", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.fe>,
          in => qq<\xFE>,
          out1 => [undef, "\xFE", [q<illegal-octets-error>]],
          out2 => [undef, "\xFE", [q<illegal-octets-error>]],
        },
        {
          id => q<l=1.ff>,
          in => qq<\xFF>,
          out1 => [undef, "\xFF", [q<illegal-octets-error>]],
          out2 => [undef, "\xFF", [q<illegal-octets-error>]],
        },
        {
          id => q<l=2.0000>,
          in => qq<\x00\x00>,
          out1 => [undef, "\x00", undef, "\x00", undef],
          out2 => [undef, "\x00", undef, "\x00", undef],
        },
        {
          id => q<l=2.0D0A>,
          in => qq<\x0D\x0A>,
          out1 => [undef, "\x0D", undef, "\x0A", undef],
          out2 => [undef, "\x0D", undef, "\x0A", undef],
        },
        {
          id => q<l=2.1B1B>,
          in => qq<\x1B\x1B>,
          out1 => [undef, "\x1B", [q<illegal-octets-error>],
                         "\x1B", [q<illegal-octets-error>]],
          out2 => [undef, "\x1B", [q<illegal-octets-error>],
                         "\x1B", [q<illegal-octets-error>]],
        },
        {
          id => q<l=2.1B20>,
          in => qq<\x1B\x20>,
          out1 => [undef, "\x1B", [q<illegal-octets-error>], "\x20", undef],
          out2 => [undef, "\x1B", [q<illegal-octets-error>], "\x20", undef],
        },
        {
          id => q<l=2.1B24>,
          in => qq<\x1B\x24>,
          out1 => [undef, "\x1B", [q<illegal-octets-error>], "\x24", undef],
          out2 => [undef, "\x1B", [q<illegal-octets-error>], "\x24", undef],
        },
        {
          id => q<l=2.1B28>,
          in => qq<\x1B\x28>,
          out1 => [undef, "\x1B", [q<illegal-octets-error>], "\x28", undef],
          out2 => [undef, "\x1B", [q<illegal-octets-error>], "\x28", undef],
        },
        {
          id => q<l=2.2020>,
          in => qq<\x20\x20>,
          out1 => [undef, "\x20", undef, "\x20", undef],
          out2 => [undef, "\x20", undef, "\x20", undef],
        },
        {
          id => q<l=2.ab>,
          in => qq<ab>,
          out1 => [undef, "a", undef, "b", undef],
          out2 => [undef, "a", undef, "b", undef],
        },
        {
          id => q<8040>,
          in => qq<\x80\x40>,
          out1 => [undef, "\x80", [q<illegal-octets-error>],
                         "\x40", undef],
          out2 => [undef, "\x80", [q<illegal-octets-error>],
                         "\x40", undef],
        },
        {
          id => q<1B2440>,
          in => qq<\x1B\x24\x40>,
          out1 => [undef],
          out2 => [undef],
          eof_error => [q<invalid-state-error>],
        },
        {
          id => q<1B2442>,
          in => qq<\x1B\x24\x42>,
          out1 => [undef],
          out2 => [undef],
          eof_error => [q<invalid-state-error>],
        },
        {
          id => q<1B2840>,
          in => qq<\x1B\x28\x40>,
          out1 => [undef, "\x1B", [q<illegal-octets-error>], "(", undef,
                         "\x40", undef],
          out2 => [undef, "\x1B", [q<illegal-octets-error>], "(", undef,
                         "\x40", undef],
        },
        {
          id => q<1B2842>,
          in => qq<\x1B\x28\x42>,
          out1 => [undef],
          out2 => [undef],
        },
        {
          id => q<1B284A>,
          in => qq<\x1B\x28\x4A>,
          out1 => [undef],
          out2 => [undef],
          eof_error => [q<invalid-state-error>],
        },
        {
          id => q<1B$B1B(B>,
          in => qq<\x1B\x24\x42\x1B\x28\x42>,
          out1 => [undef],
          out2 => [undef],
        },
        {
          id => q<1B(B1B(B>,
          in => qq<\x1B\x28\x42\x1B\x28\x42>,
          out1 => [undef],
          out2 => [undef],
        },
        {
          id => q<1B(Ba1B(B>,
          in => qq<\x1B\x28\x42a\x1B\x28\x42>,
          out1 => [undef, "a", undef],
          out2 => [undef, "a", undef],
        },
        {
          id => q<1B(Ba1B(B1B(B>,
          in => qq<\x1B\x28\x42a\x1B\x28\x42\x1B\x28\x42>,
          out1 => [undef, "a", undef],
          out2 => [undef, "a", undef],
        },
        {
          id => q<1B$42!!1B2842>,
          in => qq<\x1B\x24\x42!!\x1B\x28\x42>,
          out1 => [undef, "\x{3000}", undef],
          out2 => [undef, "\x{3000}", undef],
        },
        {
          id => q<1B$4221211B284A>,
          in => qq<\x1B\x24\x42!!\x1B\x28\x4A>,
          out1 => [undef, "\x{3000}", undef],
          out2 => [undef, "\x{3000}", undef],
          eof_error => [q<invalid-state-error>],
        },
        {
          id => q<1B$4021211B2842>,
          in => qq<\x1B\x24\x40!!\x1B\x28\x42>,
          out1 => [undef, "\x{3000}", undef],
          out2 => [undef, "\x{3000}", undef],
        },
        {
          id => q<1B$402121211B2842>,
          in => qq<\x1B\x24\x40!!!\x1B\x28\x42>,
          out1 => [undef, "\x{3000}", undef, "!", [q<illegal-octets-error>]],
          out2 => [undef, "\x{3000}", undef, "!", [q<illegal-octets-error>]],
        },
        {
          id => q<1B$4021211B2442!!1B2842>,
          in => qq<\x1B\x24\x40!!\x1B\x24\x42!!\x1B\x28\x42>,
          out1 => [undef, "\x{3000}", undef, "\x{3000}", undef],
          out2 => [undef, "\x{3000}", undef, "\x{3000}", undef],
        },
        {
          id => q<1B$4021211B2440!!1B2842>,
          in => qq<\x1B\x24\x40!!\x1B\x24\x40!!\x1B\x28\x42>,
          out1 => [undef, "\x{3000}", undef, "\x{3000}", undef],
          out2 => [undef, "\x{3000}", undef, "\x{3000}", undef],
        },
        {
          id => q<1B$@!"1B(B\~|>,
          in => qq<\x1B\x24\x40!"\x1B(B\\~|>,
          out1 => [undef, "\x{3001}", undef, "\x5C", undef,
                         "\x7E", undef, "|", undef],
          out2 => [undef, "\x{3001}", undef, "\x5C", undef,
                         "\x7E", undef, "|", undef],
        },
        {
          id => q<1B$B!"1B(J\~|1B(B>,
          in => qq<\x1B\x24\x42!"\x1B(J\\~|\x1B(B>,
          out1 => [undef, "\x{3001}", undef, "\xA5", undef,
                         "\x{203E}", undef, "|", undef],
          out2 => [undef, "\x{3001}", undef, "\xA5", undef,
                         "\x{203E}", undef, "|", undef],
        },
        {
          id => q<78compat.3022(16-02)>,
          in => qq<\x1B\$\@\x30\x22\x1B\$B\x30\x22\x1B(B>,
          out1 => [undef, "\x{555E}", undef, "\x{5516}", undef],
          out2 => [undef, "\x{5516}", undef, "\x{5516}", undef],
        },
        {
          id => q<unassigned.2239>,
          in => qq<\x1B\$\@\x22\x39\x1B\$B\x22\x39\x1B(B>,
          out1 => [undef, "\x22\x39", [q<unassigned-code-point-error>],
                         "\x22\x39", [q<unassigned-code-point-error>]],
          out2 => [undef, "\x22\x39", [q<unassigned-code-point-error>],
                         "\x22\x39", [q<unassigned-code-point-error>]],
        },
        {
          id => q<83add.223A>,
          in => qq<\x1B\$\@\x22\x3A\x1B\$B\x22\x3A\x1B(B>,
          out1 => [undef, "\x22\x3A", [q<unassigned-code-point-error>],
                         "\x{2208}", undef],
          out2 => [undef, "\x{2208}", undef, "\x{2208}", undef],
        },
        {
          id => q<83add.2840>,
          in => qq<\x1B\$\@\x28\x40\x1B\$B\x28\x40\x1B(B>,
          out1 => [undef, "\x28\x40", [q<unassigned-code-point-error>],
                         "\x{2542}", undef],
          out2 => [undef, "\x{2542}", undef, "\x{2542}", undef],
        },
        {
          id => q<83add.7421>,
          in => qq<\x1B\$\@\x74\x21\x1B\$B\x74\x21\x1B(B>,
          out1 => [undef, "\x74\x21", [q<unassigned-code-point-error>],
                         "\x{582F}", undef],
          out2 => [undef, "\x{5C2D}", undef, "\x{582F}", undef],
        },
        {
          id => q<83swap.3033>,
          in => qq<\x1B\$\@\x30\x33\x1B\$B\x30\x33\x1B(B>,
          out1 => [undef, "\x{9C3A}", undef, "\x{9BF5}", undef],
          out2 => [undef, "\x{9C3A}", undef, "\x{9BF5}", undef],
        },
        {
          id => q<83swap.724D>,
          in => qq<\x1B\$\@\x72\x4D\x1B\$B\x72\x4D\x1B(B>,
          out1 => [undef, "\x{9BF5}", undef, "\x{9C3A}", undef],
          out2 => [undef, "\x{9BF5}", undef, "\x{9C3A}", undef],
        },
        {
          id => q<90add.7425>,
          in => qq<\x1B\$\@\x74\x25\x1B\$B\x74\x25\x1B(B>,
          out1 => [undef, "\x74\x25", [q<unassigned-code-point-error>],
                         "\x74\x25", [q<unassigned-code-point-error>]],
          out2 => [undef, "\x{51DC}", undef, "\x{51DC}", undef],
        },
        {
          id => q<90add.7426>,
          in => qq<\x1B\$\@\x74\x26\x1B\$B\x74\x26\x1B(B>,
          out1 => [undef, "\x74\x26", [q<unassigned-code-point-error>],
                         "\x74\x26", [q<unassigned-code-point-error>]],
          out2 => [undef, "\x{7199}", undef, "\x{7199}", undef],
        },
      );

  check_charset ('IETF-ISO-2022-JP', $IANA_CHARSET.'iso-2022-jp',
                 [map {$_->{out} = $_->{out1}; $_} @testdata]);
  check_charset ('XML-ISO-2022-JP', $XML_CHARSET.'iso-2022-jp',
                 [map {$_->{out} = $_->{out2}; $_} @testdata]);
}
