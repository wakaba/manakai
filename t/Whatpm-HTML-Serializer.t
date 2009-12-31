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
  return $el;
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
    my $el = create_el_from_html $_->[0];
    is $el->inner_html, $_->[1] // $_->[0];
  }
} # _element_inner_html

__PACKAGE__->runtests;

1;
