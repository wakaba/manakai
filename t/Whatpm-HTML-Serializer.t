#!/usr/bin/perl
package test::Whatpm::HTML::Serializer;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::HTML::Serializer;
use Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;

sub create_doc_from_html ($) {
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  $doc->inner_html ($_[0]);
  return $doc;
} # create_doc_from_html

sub create_el_from_html ($) {
  my $doc = create_doc_from_html q<<!DOCTYPE HTML><div></div>>;
  my $el = $doc->last_child->last_child->first_child;
  $el->inner_html ($_[0]);
  return ($doc, $el);
} # create_el_from_html

sub _document_inner_html : Test(4) {
  for (
    [q<<html><head></head><body><p>foo</p></body></html>>],
    [q<<!DOCTYPE html><html><head></head><body><p>foo</p></body></html>>],
    [q<<!DOCTYPE html><html><head></head><body></body></html>>],
    [q<<!DOCTYPE html><html><head></head><body x="y"></body></html>>],
  ) {
    my $doc = create_doc_from_html $_->[0];
    is $doc->inner_html, $_->[1] // $_->[0];
  }
} # _document_inner_html

sub _element_inner_html : Test(5) {
  for (
    [q<>],
    [q<xy z>],
    [q<<p>abc</p>>],
    [q<<p>abc</p><!---->>],
    [q<<img alt="b" src="x">>],
  ) {
    my ($doc, $el) = create_el_from_html $_->[0];
    is $el->inner_html, $_->[1] // $_->[0];
  }
} # _element_inner_html

sub _plaintext_1 : Test(1) {
  my ($doc, $el) = create_el_from_html ('<plaintext>');
  my $pt = $el->first_child;
  is $pt->inner_html, q<>;

  $pt->inner_html (q<abc>);
  is $pt->inner_html, q<abc>;

  $pt->append_child ($doc->create_text_node ('<p>xyz'));
  is $pt->inner_html, q<abc<p>xyz>;
}

__PACKAGE__->runtests;

1;
