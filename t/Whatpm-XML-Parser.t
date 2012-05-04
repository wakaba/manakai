package test::Whatpm::XML::Parser;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Whatpm::XML::Parser;
use Message::DOM::DOMImplementation;
use Message::DOM::Document;

sub _xml_parser_gc : Test(2) {
  my $parser_destroy_called = 0;
  my $doc_destroy_called = 0;

  no warnings 'redefine';
  no warnings 'once';
  local *Whatpm::XML::Parser::DESTROY = sub { $parser_destroy_called++ };
  local *Message::DOM::Document::DESTROY = sub { $doc_destroy_called++ };

  my $doc = Message::DOM::DOMImplementation->new->create_document;
  Whatpm::XML::Parser->parse_char_string (q<<p>abc</p>> => $doc);

  is $parser_destroy_called, 1;

  undef $doc;
  is $doc_destroy_called, 1;
} # _xml_parser_gc

sub _parse_char_string : Test(7) { 
  my $s = qq{<foo>\x{4500}<bar xy="zb"/>\x{400}abc</foo><!---->};
  my $parser = Whatpm::XML::Parser->new;
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $parser->parse_char_string ($s => $doc);
  eq_or_diff $doc->inner_html, qq{<foo>\x{4500}<bar xy="zb"></bar>\x{0400}abc</foo><!---->};
  is $doc->input_encoding, undef;
  is $doc->xml_version, '1.0';
  is $doc->xml_encoding, undef;
  ng $doc->xml_standalone;
  ng $doc->manakai_is_html;
  is $doc->child_nodes->length, 2;
} # _parse_char_string

sub _parse_char_string_old_content : Test(3) { 
  my $s = qq{<foo>\x{4500}<bar xy="zb"/>\x{400}abc</foo><!---->};
  my $parser = Whatpm::XML::Parser->new;
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->inner_html (q{<foo>abc</foo>});
  is $doc->child_nodes->length, 1;
  
  $parser->parse_char_string ($s => $doc);
  eq_or_diff $doc->inner_html,
      qq{<foo>\x{4500}<bar xy="zb"></bar>\x{0400}abc</foo><!---->};
  is $doc->child_nodes->length, 2;
} # _parse_char_string_old_content

sub _parse_char_string_onerror : Test(3) { 
  my $s = qq{<foo>\x{4500}<bar xy=zb />\x{400}abc</foo><!---->};
  my $parser = Whatpm::XML::Parser->new;
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  my @error;
  $parser->parse_char_string ($s => $doc, sub {
    push @error, {@_};
  });
  eq_or_diff $doc->inner_html,
      qq{<foo>\x{4500}<bar xy="zb"></bar>\x{0400}abc</foo><!---->};
  is $doc->child_nodes->length, 2;
  delete $error[0]->{token};
  eq_or_diff \@error, [{type => 'unquoted attr value',
                        level => 'm',
                        line => 1, column => 15}];
} # _parse_char_string_old_content

sub _parse_char_stream : Test(3) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $s = qq{<html><p>\x{4000}\x{3000}a<p>bc};

  require Whatpm::Charset::DecodeHandle;
  my $input = Whatpm::Charset::DecodeHandle::CharString->new (\$s);
  my $parser = Whatpm::XML::Parser->new;
  $parser->parse_char_stream ($input => $doc);

  eq_or_diff $doc->inner_html, qq{<html><p>\x{4000}\x{3000}a<p>bc</p></p></html>};
  is $doc->input_encoding, undef;
  ng $doc->manakai_is_html;
} # _parse_char_stream

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2009-2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
