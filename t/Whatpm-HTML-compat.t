package test::Whatpm::HTML::compat;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Whatpm::HTML;
use Message::DOM::DOMImplementation;
use Whatpm::Charset::DecodeHandle;

sub _parse_string : Test(4) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $input = qq{<!DOCTYPE html><html lang=en><title>\x{0500}\x{200}</title>\x{500}};
  my $parser = Whatpm::HTML->new;
  $parser->parse_string ($input => $doc);
  is $doc->child_nodes->length, 2;
  eq_or_diff $doc->inner_html, qq{<!DOCTYPE html><html lang="en"><head><title>\x{0500}\x{0200}</title></head><body>\x{0500}</body></html>};
  is $doc->input_encoding, undef; # XXX Should be UTF-8 for consistency with DOM4?
  is $doc->manakai_is_html, 1;
} # _parse_string

sub _parse_char_stream : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $s = qq{<html><p>\x{4000}\x{3000}a<p>bc};

  my $input = Whatpm::Charset::DecodeHandle::CharString->new (\$s);
  my $parser = Whatpm::HTML->new;
  $parser->parse_char_stream ($input => $doc);

  eq_or_diff $doc->inner_html, qq{<html><head></head><body><p>\x{4000}\x{3000}a</p><p>bc</p></body></html>};
  is $doc->input_encoding, undef;
} # _parse_char_stream

sub _parse_byte_stream_utf8 : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $s = qq{<html><p>\xE5\x9A\x81\xC2\xAFa<p>bc};

  my $input = Whatpm::Charset::DecodeHandle::ByteString->new (\$s);
  my $parser = Whatpm::HTML->new;
  $parser->parse_byte_stream ('utf-8', $input => $doc);

  eq_or_diff $doc->inner_html, qq{<html><head></head><body><p>\x{5681}\xafa</p><p>bc</p></body></html>};
  is $doc->input_encoding, 'utf-8';
} # _parse_byte_stream_utf8

sub _parse_byte_stream_latin1 : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $s = qq{<html><p>\xE5\x9A\x81\xC2\xAFa<p>bc};

  my $input = Whatpm::Charset::DecodeHandle::ByteString->new (\$s);
  my $parser = Whatpm::HTML->new;
  $parser->parse_byte_stream ('latin1', $input => $doc);

  eq_or_diff $doc->inner_html, qq{<html><head></head><body><p>\xe5\x{0161}\x{fffd}\xc2\xafa</p><p>bc</p></body></html>};
  is $doc->input_encoding, 'windows-1252';
} # _parse_byte_stream_latin1

sub _parse_byte_stream_change : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $s = qq{<html><p><foo><meta charset=shift_jis>\xE5\xA3\xC2};

  my $input = Whatpm::Charset::DecodeHandle::ByteString->new (\$s);
  my $parser = Whatpm::HTML->new;
  $parser->parse_byte_stream (undef, $input => $doc);

  eq_or_diff $doc->inner_html, qq{<html><head></head><body><p><foo><meta charset="shift_jis">\x{87a2}\x{ff82}</foo></p></body></html>};
  is $doc->input_encoding, 'shift_jis';
} # _parse_byte_stream_change

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2009-2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
