package test::Whatpm::HTML::Parser;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::HTML;
use Message::DOM::DOMImplementation;
use Message::DOM::Document;

sub _html_parser_gc : Test(2) {
  my $parser_destroy_called = 0;
  my $doc_destroy_called = 0;

  no warnings 'redefine';
  local *Whatpm::HTML::DESTROY = sub { $parser_destroy_called++ };
  local *Message::DOM::Document::DESTROY = sub { $doc_destroy_called++ };

  my $doc = Message::DOM::DOMImplementation->new->create_document;
  Whatpm::HTML->parse_char_string (q<<p>abc</p>> => $doc);

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

  Whatpm::HTML->parse_char_string (q<<p>abc</p>> => $doc);

  ok $doc->manakai_is_html;
  is $doc->compat_mode, 'CSS1Compat';
  is $doc->manakai_compat_mode, 'no quirks';
} # _html_parser_srcdoc

sub _html_parser_change_the_encoding_char_string : Test(4) {
  my $parser = Whatpm::HTML->new;
  my $called = 0;
  $parser->{change_encoding} = sub {
    $called = 1;
  }; # change_encoding
  
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
  my $parser = Whatpm::HTML->new;
  my $called = 0;
  $parser->{change_encoding} = sub {
    $called = 1;
  }; # change_encoding
  
  my $doc = Message::DOM::DOMImplementation->new->create_document;
  my $el = $doc->create_element ('div');

  $parser->set_inner_html ($el, '<meta charset=shift_jis>', sub { });
  ok !$called;

  $parser->set_inner_html ($el, '<meta http-equiv=content-type content="text/html; charset=shift_jis">', sub { });
  ok !$called;
} # _html_parser_change_the_encoding

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2009-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
