package test::Whatpm::HTML::Parser;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Whatpm::HTML::Parser;
use Message::DOM::DOMImplementation;
use Message::DOM::Document;

sub _html_parser_gc : Test(2) {
  my $parser_destroy_called = 0;
  my $doc_destroy_called = 0;

  no warnings 'redefine';
  local *Whatpm::HTML::Parser::DESTROY = sub { $parser_destroy_called++ };
  local *Message::DOM::Document::DESTROY = sub { $doc_destroy_called++ };

  my $doc = Message::DOM::DOMImplementation->new->create_document;
  Whatpm::HTML::Parser->parse_char_string (q<<p>abc</p>> => $doc);

  is $parser_destroy_called, 1;

  undef $doc;
  is $doc_destroy_called, 1;
} # _html_parser_gc

sub _html_fragment_parser_gc : Test(6) {
  my $parser_destroy_called = 0;
  my $doc_destroy_called = 0;
  my $el_destroy_called = 0;

  no warnings 'redefine';
  no warnings 'once';
  local *Whatpm::HTML::DESTROY = sub { $parser_destroy_called++ };
  local *Message::DOM::Document::DESTROY = sub { $doc_destroy_called++ };
  local *Message::DOM::Element::DESTROY = sub { $el_destroy_called++ };

  my $doc = Message::DOM::DOMImplementation->new->create_document;
  my $el = $doc->create_element ('p');

  $el->inner_html (q[]);
  is $el_destroy_called, 1; # fragment parser's |Element|
  is $doc_destroy_called, 1; # fragment parser's |Document|

  is $parser_destroy_called, 1; # parser itself

  undef $el;
  is $el_destroy_called, 2; # $el
  undef $doc;
  is $doc_destroy_called, 2; # $doc
  is $el_destroy_called, 2;
} # _html_fragment_parser_gc

sub _html_parser_srcdoc : Test(3) {
  my $doc = Message::DOM::DOMImplementation->new->create_document;
  $doc->manakai_is_srcdoc (1);

  Whatpm::HTML::Parser->parse_char_string (q<<p>abc</p>> => $doc);

  ok $doc->manakai_is_html;
  is $doc->compat_mode, 'CSS1Compat';
  is $doc->manakai_compat_mode, 'no quirks';
} # _html_parser_srcdoc

sub _html_parser_change_the_encoding_char_string : Test(4) {
  my $parser = Whatpm::HTML::Parser->new;
  my $called = 0;
  my $onerror = sub {
    my %args = @_;
    $called = 1 if $args{type} eq 'charset label detected';
  };
  
  my $doc = Message::DOM::DOMImplementation->new->create_document;
  $parser->parse_char_string ('<meta charset=shift_jis>' => $doc, sub { });
  ok !$called;
  is $doc->input_encoding, undef;
  
  my $doc2 = Message::DOM::DOMImplementation->new->create_document;
  $parser->parse_char_string ('<meta http-equiv=Content-Type content="text/html; charset=shift_jis">' => $doc2, sub { });
  ok !$called;
  is $doc2->input_encoding, undef;
} # _html_parser_change_the_encoding_char_string

sub _html_parser_change_the_encoding_fragment : Test(2) {
  my $parser = Whatpm::HTML::Parser->new;
  my $called = 0;
  my $onerror = sub {
    my %args = @_;
    $called = 1 if $args{type} eq 'charset label detected';
  };
  
  my $doc = Message::DOM::DOMImplementation->new->create_document;
  my $el = $doc->create_element ('div');

  $parser->set_inner_html ($el, '<meta charset=shift_jis>', sub { });
  ok !$called;

  $parser->set_inner_html ($el, '<meta http-equiv=content-type content="text/html; charset=shift_jis">', sub { });
  ok !$called;
} # _html_parser_change_the_encoding_fragment

sub _html_parser_change_the_encoding_byte_string : Test(32) {
  my $parser = Whatpm::HTML::Parser->new;
  my $called = 0;
  my $onerror = sub {
    my %args = @_;
    $called = 1 if $args{type} eq 'charset label detected';
  };
  my $dom = Message::DOM::DOMImplementation->new;

  for my $input (
    '<meta charset=shift_jis>',
    '<meta http-equiv=Content-Type content="text/html; charset=shift_jis">',
    '<meta http-equiv=Content-Type content="text/html; charsetcharset=shift_jis">',
    '<meta http-equiv=Content-Type content="text/html; charset.charset=shift_jis">',
    '<meta http-equiv=Content-Type content="text/html; charset-edition=1997;charset=shift_jis">',
    '<meta http-equiv=Content-Type content="text/html; charset=shift_jis;charset=euc-jp">',
    '<meta http-equiv=Content-Type content="text/html; charset  charset=shift_jis">',
    '<meta http-equiv=Content-Type content="text/html; charset = shift_jis">',
    '<meta http-equiv="Content-Type" content="text/html; charset=shift_jis">',
    '<meta http-equiv=Content-Type content="text/html;charset=shift_jis">',
    '<meta http-equiv=Content-Type content=text/html; charset=shift_jis>',
    '<meta http-equiv=CONTENT-TYPE content="TEXT/HTML; CHARSET=shift_jis">',
    '<meta content="text/html; charset=shift_jis" http-equiv="content-type">',
    '<body><meta http-equiv="Content-Type" content="text/html; charset=shift_jis">',
    '<meta http-equiv=content-type content="application/xhtml+xml; charset=shift_jis">',
    '<meta http-equiv=content-type content="charset=shift_jis">',
  ) {
    my $doc = $dom->create_document;
    $parser->parse_byte_string (undef, (' ' x 1024) . $input => $doc, $onerror);
    ok $called;
    is $doc->input_encoding, 'shift_jis';
  }
} # _html_parser_change_the_encoding_byte_string

sub _html_parser_change_the_encoding_byte_string_changed : Test(48) {
  my $parser = Whatpm::HTML::Parser->new;
  my $called = 0;
  my $onerror = sub {
    my %args = @_;
    $called = 1 if $args{type} eq 'charset label detected';
  };
  my $dom = Message::DOM::DOMImplementation->new;

  for (
    ['<meta charset=shift_jis>' => 'shift_jis'],
    ['<meta charset=euc-jp>' => 'euc-jp'],
    ['<meta charset=iso-2022-jp>' => 'iso-2022-jp'],
    ['<meta charset=utf-8>' => 'utf-8'],
    ['<meta charset=utf-16>' => 'utf-8'],
    ['<meta charset=utf-16be>' => 'utf-8'],
    ['<meta charset=utf-16le>' => 'utf-8'],

    ['<meta http-equiv=content-type content="text/html; charset=euc-jp">' => 'euc-jp'],
    ['<meta http-equiv=content-type content="text/html; charset=utf-8">' => 'utf-8'],
    ['<meta http-equiv=content-type content="text/html; charset=utf-16">' => 'utf-8'],
    ['<meta http-equiv=content-type content="text/html; charset=utf-16be">' => 'utf-8'],
    ['<meta http-equiv=content-type content="text/html; charset=utf-16le">' => 'utf-8'],

    ['<p><meta charset=shift_jis>' => 'shift_jis'],
    ['<p><meta charset=euc-jp>' => 'euc-jp'],
    ['<p><meta charset=iso-2022-jp>' => 'iso-2022-jp'],
    ['<p><meta charset=utf-8>' => 'utf-8'],
    ['<p><meta charset=utf-16>' => 'utf-8'],
    ['<p><meta charset=utf-16be>' => 'utf-8'],
    ['<p><meta charset=utf-16le>' => 'utf-8'],

    ['<p><meta http-equiv=content-type content="text/html; charset=euc-jp">' => 'euc-jp'],
    ['<p><meta http-equiv=content-type content="text/html; charset=utf-8">' => 'utf-8'],
    ['<p><meta http-equiv=content-type content="text/html; charset=utf-16">' => 'utf-8'],
    ['<p><meta http-equiv=content-type content="text/html; charset=utf-16be">' => 'utf-8'],
    ['<p><meta http-equiv=content-type content="text/html; charset=utf-16le">' => 'utf-8'],
  ) {
    my $doc = $dom->create_document;
    $parser->parse_byte_string (undef, (' ' x 1024) . $_->[0] => $doc, $onerror);
    ok $called;
    is $doc->input_encoding, $_->[1];
  }
} # _html_parser_change_the_encoding_byte_string_changed

sub _html_parser_change_the_encoding_byte_string_not_called : Test(28) {
  my $parser = Whatpm::HTML::Parser->new;
  my $called = 0;
  my $onerror = sub {
    my %args = @_;
    $called = 1 if $args{type} eq 'charset label detected';
  };
  my $dom = Message::DOM::DOMImplementation->new;

  for my $input (
    '',
    '<meta content=shift_jis>',
    '<meta content="text/html; charset=shift_jis">',
    '<meta name=content-type content="text/html; charset=shift_jis">',
    '<meta http-equiv=content-style-type content="text/html; charset=shift_jis">',
    '<meta http-equiv=content_type content="text/html; charset=shift_jis">',

    '<meta charset=ebcdic>',
    '<meta http-equiv=content-type content="text/html; charset=ebcdic">',
    '<meta charset=utf-7>',
    '<meta http-equiv=content-type content="text/html; charset=utf-7">',
    '<meta charset=utf-1>',
    '<meta http-equiv=content-type content="text/html; charset=utf-1">',
    '<meta charset=unicode>',
    '<meta http-equiv=content-type content="text/html; charset=unicode">',
  ) {
    my $doc = $dom->create_document;
    $parser->parse_byte_string (undef, (' ' x 1024) . $input => $doc, $onerror);
    ok !$called;
    like $doc->input_encoding, qr[windows-1252|us-ascii];
  }
} # _html_parser_change_the_encoding_byte_string_not_called

sub _html_parser_change_the_encoding_byte_string_with_charset : Test(2) {
  my $parser = Whatpm::HTML::Parser->new;
  my $called = 0;
  my $onerror = sub {
    my %args = @_;
    $called = 1 if $args{type} eq 'charset label detected';
  };
  my $dom = Message::DOM::DOMImplementation->new;

  for my $input (
    '<meta http-equiv=content-type content="text/html; charset=shift_jis">',
  ) {
    my $doc = $dom->create_document;
    $parser->parse_byte_string ('euc-jp', (' ' x 1024) . $input => $doc, $onerror);
    ok !$called;
    is $doc->input_encoding, 'euc-jp';
  }
} # _html_parser_change_the_encoding_byte_string_with_charset

sub _parse_char_string : Test(4) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<!DOCTYPE html><html lang=en><title>\x{0500}\x{200}</title>\x{500}};
  my $parser = Whatpm::HTML::Parser->new;
  $parser->parse_char_string ($input => $doc);
  is $doc->child_nodes->length, 2;
  eq_or_diff $doc->inner_html, qq{<!DOCTYPE html><html lang="en"><head><title>\x{0500}\x{0200}</title></head><body>\x{0500}</body></html>};
  is $doc->input_encoding, undef; # XXX Should be UTF-8 for consistency with DOM4?
  is $doc->manakai_is_html, 1;
} # _parse_char_string

sub _parse_char_string_onerror_old : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<html lang=en>};
  my $parser = Whatpm::HTML::Parser->new;
  my @error;
  $parser->parse_char_string ($input => $doc, sub {
    push @error, {@_};
  });
  ok $error[0]->{token};
  delete $error[0]->{token};
  eq_or_diff \@error, [{
    type => 'no DOCTYPE',
    level => 'm',
    line => 1,
    column => 14,
  }];
} # _parse_char_string_onerror_old

sub _parse_char_string_onerror_new : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<html lang=en>};
  my $parser = Whatpm::HTML::Parser->new;
  my @error;
  $parser->onerror (sub {
    push @error, {@_};
  });
  $parser->parse_char_string ($input => $doc);
  ok $error[0]->{token};
  delete $error[0]->{token};
  eq_or_diff \@error, [{
    type => 'no DOCTYPE',
    level => 'm',
    line => 1,
    column => 14,
  }];
} # _parse_char_string_onerror_new

sub _parse_char_string_old_children : Test(3) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->inner_html (q{<foo><bar/></foo><!---->});
  is $doc->child_nodes->length, 2;

  my $input = qq{<html lang=en>};
  my $parser = Whatpm::HTML::Parser->new;
  $parser->parse_char_string ($input => $doc);

  is $doc->child_nodes->length, 1;
  eq_or_diff $doc->inner_html, q{<html lang="en"><head></head><body></body></html>};
} # _parse_char_string_old_children

sub _parse_char_string_encoding_decl : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<html lang=en><meta charset=euc-jp>};
  my $parser = Whatpm::HTML::Parser->new;
  $parser->parse_char_string ($input => $doc);
  eq_or_diff $doc->inner_html, q{<html lang="en"><head><meta charset="euc-jp"></head><body></body></html>};
  is $doc->input_encoding, undef;
} # _parse_char_string_encoding_decl

sub _parse_byte_string_latin1 : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<html lang=en>\xCF\xEF\xEE\x21\x21};
  my $parser = Whatpm::HTML::Parser->new;
  $parser->parse_byte_string ('iso-8859-1', $input => $doc);

  eq_or_diff $doc->inner_html, qq{<html lang="en"><head></head><body>\xCF\xEF\xEE\x21\x21</body></html>};
  is $doc->input_encoding, 'windows-1252';
} # _parse_byte_string_latin1

sub _parse_byte_string_utf8 : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<html lang=en>\xCF\xAF\xEE\x21\x21};
  my $parser = Whatpm::HTML::Parser->new;
  $parser->parse_byte_string ('utf-8', $input => $doc);

  eq_or_diff $doc->inner_html, qq{<html lang="en"><head></head><body>\x{03ef}\x{fffd}\x21\x21</body></html>};
  is $doc->input_encoding, 'utf-8';
} # _parse_byte_string_utf8

sub _parse_byte_string_onerror_new : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<html lang=en>\xC3\xAC};
  my $parser = Whatpm::HTML::Parser->new;
  my @error;
  $parser->onerror (sub {
    push @error, {@_};
  });
  $parser->parse_byte_string ('utf-8', $input => $doc);
  ok $error[0]->{token};
  delete $error[0]->{token};
  eq_or_diff \@error, [{
    type => 'no DOCTYPE',
    level => 'm',
    line => 1,
    column => 15,
  }];
} # _parse_byte_string_onerror_new

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2009-2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
