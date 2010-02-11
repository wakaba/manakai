#!/usr/bin/perl
package test::Message::MIME::Type;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;
use Test::Differences;

use Message::MIME::Type;

# ------ Instantiation ------

sub _new_from_type_and_subtype : Test(5) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'plain');
  isa_ok $mt, 'Message::MIME::Type';

  is $mt->type, 'text';
  is $mt->subtype, 'plain';
  is $mt->as_valid_mime_type_with_no_params, 'text/plain';
  is $mt->as_valid_mime_type, 'text/plain';
} # _new_from_type_and_subtype

sub _new_from_type_and_subtype_2 : Test(5) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('tEXt', 'pLAin');
  isa_ok $mt, 'Message::MIME::Type';

  is $mt->type, 'text';
  is $mt->subtype, 'plain';
  is $mt->as_valid_mime_type_with_no_params, 'text/plain';
  is $mt->as_valid_mime_type, 'text/plain';
} # _new_from_type_and_subtype_2

sub _parser : Test(63) {
  require (file (__FILE__)->dir->file ('testfiles.pl')->stringify);
  
  execute_test (file (__FILE__)->dir->subdir ('mime')->file ('types.dat'), {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    result => {is_prefixed => 1},
  }, sub {
    my $test = shift;
    
    my @errors;
    my $onerror = sub {
      my %opt = @_;
      push @errors, join ';',
          $opt{index},
          $opt{type},
          defined $opt{value} ? $opt{value} : '',
          $opt{level};
    }; # $onerror
    
    my $parsed = Message::MIME::Type->parse_web_mime_type
        ($test->{data}->[0], $onerror);
    
    if ($test->{errors}) {
      is join ("\n", sort {$a cmp $b} @errors),
          join ("\n", sort {$a cmp $b} @{$test->{errors}->[0]}),
          $test->{data}->[0];
    } else {
      warn qq[No #errors section: "$test->{data}->[0]];
    }

    my $expected_result = $test->{result}->[0] // '';
    my $actual_result = '';
    if ($parsed) {
      $actual_result .= $parsed->type . "\n";
      $actual_result .= $parsed->subtype . "\n";
      for my $attr (@{$parsed->attrs}) {
        $actual_result .= $attr . "\n";
        $actual_result .= $parsed->param ($attr) . "\n";
      }
      $expected_result .= "\n" if length $actual_result;
    }
    is $actual_result, $expected_result, '#result of ' . $test->{data}->[0];
  });
} # _parser

# ------ Accessors ------

sub _type : Test(3) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('image', 'png');
  is $mt->type, 'image';
  $mt->type('Audio');
  is $mt->type, 'audio';
  is $mt->as_valid_mime_type, 'audio/png';
} # _type

sub _subtype : Test(3) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('modeL', 'vrmL');
  is $mt->subtype, 'vrml';
  $mt->subtype ('BMP');
  is $mt->subtype, 'bmp';
  is $mt->as_valid_mime_type, 'model/bmp';
} # _subtype

sub _param : Test(6) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('message', 'rfc822');
  is $mt->param ('charset'), undef;
  $mt->param (charset => '');
  is $mt->param ('charset'), '';
  $mt->param (charset => 0);
  is $mt->param ('charset'), 0;
  $mt->param (charset => 'us-ASCII');
  is $mt->param ('charset'), 'us-ASCII';
  is $mt->param ('CHArset'), 'us-ASCII';
  $mt->param (chARSet => 'iso-2022-JP');
  is $mt->param ('CHARSET'), 'iso-2022-JP';
} # _param

## ------ Properties ------

sub _is_styling_lang : Test(7) {
  for (
      ['text', 'plain', 0],
      ['text', 'html', 0],
      ['text', 'css', 1],
      ['text', 'xsl', 1],
      ['text', 'xslt', 0],
      ['application', 'xslt+xml', 1],
      ['x-unknown', 'x-unknown', 0],
  ) {
    my $mt = Message::MIME::Type->new_from_type_and_subtype ($_->[0], $_->[1]);
    is !!$mt->is_styling_lang, !!$_->[2];
  }
} # _is_styling_lang

sub _is_text_based : Test(18) {
  for (
      ['text', 'plain', 1],
      ['text', 'html', 1],
      ['text', 'css', 1],
      ['text', 'xsl', 1],
      ['text', 'xslt', 1],
      ['application', 'xslt+xml', 1],
      ['image', 'bmp', 0],
      ['message', 'rfc822', 1],
      ['message', 'x-unknown', 1],
      ['x-unknown', 'x-unknown', 0],
      ['application', 'xhtml+xml', 1],
      ['model', 'x-unknown', 0],
      ['image', 'svg+xml', 1],
      ['application', 'octet-stream', 0],
      ['text', 'x-unknown', 1],
      ['video', 'x-unknown+xml', 1],
      ['text', 'xml', 1],
      ['application', 'xml', 1],
  ) {
    my $mt = Message::MIME::Type->new_from_type_and_subtype ($_->[0], $_->[1]);
    is !!$mt->is_text_based, !!$_->[2];
  }
} # _is_text_based

sub _is_composite : Test(21) {
  for (
      ['text', 'plain', 0],
      ['text', 'html', 0],
      ['text', 'css', 0],
      ['text', 'xsl', 0],
      ['text', 'xslt', 0],
      ['application', 'xslt+xml', 0],
      ['image', 'bmp', 0],
      ['message', 'rfc822', 1],
      ['message', 'x-unknown', 1],
      ['x-unknown', 'x-unknown', 0],
      ['application', 'xhtml+xml', 0],
      ['model', 'x-unknown', 0],
      ['image', 'svg+xml', 0],
      ['application', 'octet-stream', 0],
      ['text', 'x-unknown', 0],
      ['video', 'x-unknown+xml', 0],
      ['text', 'xml', 0],
      ['application', 'xml', 0],
      ['multipart', 'mixed', 1],
      ['multipart', 'example', 1],
      ['multipart', 'rfc822+xml', 1],
  ) {
    my $mt = Message::MIME::Type->new_from_type_and_subtype ($_->[0], $_->[1]);
    is !!$mt->is_composite_type, !!$_->[2];
  }
} # _is_composite

sub _is_xmt : Test(26) {
  for (
      ['text', 'plain', 0],
      ['text', 'html', 0],
      ['text', 'css', 0],
      ['text', 'xsl', 0],
      ['text', 'xslt', 0],
      ['application', 'xslt+xml', 1],
      ['image', 'bmp', 0],
      ['message', 'rfc822', 0],
      ['message', 'x-unknown', 0],
      ['x-unknown', 'x-unknown', 0],
      ['application', 'xhtml+xml', 1],
      ['model', 'x-unknown', 0],
      ['image', 'svg+xml', 1],
      ['application', 'octet-stream', 0],
      ['text', 'x-unknown', 0],
      ['video', 'x-unknown+xml', 1],
      ['text', 'xml', 1],
      ['application', 'xml', 1],
      ['multipart', 'mixed', 0],
      ['multipart', 'example', 0],
      ['unknown', 'unknown+XML', 1],
      ['TEXT', 'XML', 1],
      ['audio', 'xml', 0],
      ['message', 'mime+xml', 1],
      ['text', 'csv+xml+html', 0],
      ['text+xml', 'plain', 0],
  ) {
    my $mt = Message::MIME::Type->new_from_type_and_subtype ($_->[0], $_->[1]);
    is !!$mt->is_xml_mime_type, !!$_->[2], join ' ', 'xmt', @$_;
  }
} # _is_xmt

## ------ Serialization ------

sub _as_valid_1 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css';
} # _as_valid_1

sub _as_valid_invalid_type_1 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->type ('NOT@TEXT');
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_invalid_type_2 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->type ("\x{4e00}");
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_invalid_type_3 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->type ("a/b");
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_invalid_type_4 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->type ('');
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_invalid_subtype_1 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->subtype ('<NOCSS>');
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_invalid_subtype_2 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->subtype ('');
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_invalid_subtype_3 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->subtype ("\x{FE00}");
  is $mt->as_valid_mime_type_with_no_params, undef;
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_param_1 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css; abc=def';
} # _as_valid

sub _as_valid_param_2 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def<xxyz>');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css; abc="def<xxyz>"';
} # _as_valid

sub _as_valid_param_3 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def');
  $mt->param (xyz => 1);
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css; abc=def; xyz=1';
} # _as_valid

sub _as_valid_param_4 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def');
  $mt->param (xyz => "\x{4e00}");
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_param_5 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def');
  $mt->param (xyz => "");
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css; abc=def; xyz=""';
} # _as_valid

sub _as_valid_param_6 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def');
  $mt->param (abc => 'xyz');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css; abc=xyz';
} # _as_valid

sub _as_valid_param_7 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'def');
  $mt->param (xyz => "<M");
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, 'text/css; abc=def; xyz="<M"';
} # _as_valid

sub _as_valid_param_8 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param ("<abc>" => 'def');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_param_9 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param ("" => 'def');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_param_10 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param ("\x{5000}" => 'def');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, undef;
} # _as_valid

sub _as_valid_param_11 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => "ab\x0Acd");
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, qq[text/css; abc="ab\x0D\x0A cd"];
} # _as_valid

sub _as_valid_param_12 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => "\x0D\x0D\x0A");
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, qq[text/css; abc="\x0D\x0A \x0D\x0A "];
} # _as_valid

sub _as_valid_param_13 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => 'de\"f');
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, qq[text/css; abc="de\x5C\x5C\x5C"f"];
} # _as_valid

sub _as_valid_param_14 : Test(2) {
  my $mt = Message::MIME::Type->new_from_type_and_subtype ('text', 'css');
  $mt->param (abc => qq[de\x00f]);
  is $mt->as_valid_mime_type_with_no_params, 'text/css';
  is $mt->as_valid_mime_type, qq[text/css; abc="de\x5C\x00f"];
} # _as_valid

## ------ Conformance ------

sub _validate : Test(17) {
  require (file (__FILE__)->dir->file ('testfiles.pl')->stringify);
  
  execute_test (file (__FILE__)->dir->subdir ('mime')->file ('type-conformance.dat'), {
    data => {is_prefixed => 1, is_list => 1},
    errors => {is_list => 1},
  }, sub {
    my $test = shift;
    
    my @errors;
    my $onerror = sub {
      my %opt = @_;
      push @errors, join ';',
          $opt{type},
          defined $opt{value} ? $opt{value} : '',
          $opt{level};
    }; # $onerror

    my $data = [@{$test->{data}->[0]}];
    
    my $type = Message::MIME::Type->new_from_type_and_subtype
        (shift @$data, shift @$data);
    while (@$data) {
        $type->param (shift @$data => shift @$data);
    }

    $type->validate ($onerror);
    
    if ($test->{errors}) {
      is join ("\n", sort {$a cmp $b} @errors),
          join ("\n", sort {$a cmp $b} @{$test->{errors}->[0]}),
          join (' ', @{$test->{data}->[0]});
    } else {
      warn qq[No #errors section: ] . join ' ', @{$test->{data}->[0]};
    }
  });
} # _validate

__PACKAGE__->runtests;

1;

## License: Public Domain.
