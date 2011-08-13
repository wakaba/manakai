#!/usr/bin/perl
package test::Whatpm::HTML::Serializer;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use base qw(Test::Class);
use Test::More;
use Test::Differences;
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

sub _element_inner_html : Test(6) {
  for (
    [q<>],
    [q<xy z>],
    [q<<p>abc</p>>],
    [q<<p>abc</p><!---->>],
    [q<<img alt="b" src="x">>],
    [q<<spacer>abc</spacer>>],
  ) {
    my ($doc, $el) = create_el_from_html $_->[0];
    is $el->inner_html, $_->[1] // $_->[0];
  }
} # _element_inner_html

sub _plaintext : Test(4) {
  my ($doc, $el) = create_el_from_html ('<plaintext>');
  my $pt = $el->first_child;
  is $pt->inner_html, q<>;

  $pt->inner_html (q<abc>);
  is $pt->inner_html, q<abc>;

  $pt->append_child ($doc->create_text_node ('<p>xyz'));
  is $pt->inner_html, q<abc<p>xyz>;

  $pt->append_child ($doc->create_element ('A'))->text_content ('bcd');
  is $pt->inner_html, q<abc<p>xyz<A>bcd</A>>;
} # _plaintext

sub _noscript : Test(4) {
  my ($doc, $el) = create_el_from_html ('<noscript></noscript>');
  my $noscript = $el->first_child;
  $noscript->append_child ($doc->create_text_node ('avc&<">\'' . "\xA0"));
  $noscript->append_child ($doc->create_element ('abC'))
      ->set_attribute (class => 'xYz');
  $noscript->append_child ($doc->create_text_node ('Q&A'));

  local $Whatpm::ScriptingEnabled = 0;
  is $noscript->inner_html, qq<avc&amp;&lt;"&gt;'&nbsp;<abC class="xYz"></abC>Q&amp;A>,
      'noscript_scripting_disabled noscript inner';
  is $el->inner_html, qq<<noscript>avc&amp;&lt;"&gt;'&nbsp;<abC class="xYz"></abC>Q&amp;A</noscript>>,
      'noscript_scripting_disabled';

  local $Whatpm::ScriptingEnabled = 1;
  is $noscript->inner_html, qq<avc&<">'\xA0<abC class="xYz"></abC>Q&A>,
      'noscript_scripting_enabled noscript inner';
  is $el->inner_html, qq<<noscript>avc&<">'\xA0<abC class="xYz"></abC>Q&A</noscript>>,
      'noscript_scripting_enabled';
} # _noscript

sub _xmp_descendant : Test(2) {
  my ($doc, $el) = create_el_from_html ('<xmp></xmp>');
  my $xmp = $el->first_child;
  $xmp->append_child ($doc->create_text_node ('abc<>&"' . "\xA0"));
  my $pre = $xmp->append_child ($doc->create_element ('pre'));
  $pre->append_child ($doc->create_text_node ('abc<>&"' . "\xA0"));

  is $xmp->inner_html, qq<abc<>&"\xA0<pre>\x0Aabc&lt;&gt;&amp;"&nbsp;</pre>>;
  is $el->inner_html, qq<<xmp>abc<>&"\xA0<pre>\x0Aabc&lt;&gt;&amp;"&nbsp;</pre></xmp>>;
} # _xmp_descendant

sub _attr_value : Test(1) {
  my ($doc, $el) = create_el_from_html ('<p>');
  my $p = $el->first_child;
  $p->set_attribute ('id' => '<>&"' . qq<"']]> . '>' . "\xA0");
  
  is $el->inner_html, qq{<p id="<>&amp;&quot;&quot;']]>&nbsp;"></p>};
} # _attr_value

sub _void_elements : Test(95) {
  for my $tag_name (qw(
    area base basefont bgsound br col command embed frame hr img input
    keygen link meta param source track wbr
  )) {
    my ($doc, $el) = create_el_from_html ('<p>');
    my $p = $el->first_child;
    my $el = $doc->create_element_ns ('http://www.w3.org/1999/xhtml', $tag_name);
    $p->append_child ($el);
    is $p->inner_html, qq{<$tag_name>};

    my $el2 = $doc->create_element ($tag_name);
    $p->replace_child ($el2, $el);
    is $p->inner_html, qq{<$tag_name></$tag_name>};

    my $el3 = $doc->create_element_ns ('http://test/', $tag_name);
    $p->replace_child ($el3, $el2);
    is $p->inner_html, qq{<$tag_name></$tag_name>};

    my $el4 = $doc->create_element_ns ('http://www.w3.org/2000/svg', $tag_name);
    $p->replace_child ($el4, $el3);
    is $p->inner_html, qq{<$tag_name></$tag_name>};

    my $el5 = $doc->create_element_ns ('http://www.w3.org/1998/Math/MathML', $tag_name);
    $p->replace_child ($el5, $el4);
    is $p->inner_html, qq{<$tag_name></$tag_name>};
  }
} # _void_elements

sub _doc : Test(1) {
  my $doc = create_doc_from_html ('<!DOCTYPE html><p>');
  is $doc->inner_html, q<<!DOCTYPE html><html><head></head><body><p></p></body></html>>;
} # _doc

sub _df : Test(1) {
  my $doc = create_doc_from_html ('<!DOCTYPE html>');
  my $df = $doc->create_document_fragment;
  $df->append_child ($doc->create_element ('p'))->text_content ('a&b');
  $df->manakai_append_text ('ab<>cd');
  is ${Whatpm::HTML::Serializer->get_inner_html ($df)},
    q<<p>a&amp;b</p>ab&lt;&gt;cd>;
} # _df

sub _svg : Test(1) {
  ## See
  ## <http://permalink.gmane.org/gmane.org.w3c.whatwg.discuss/11191>.

  my $doc = create_doc_from_html ('<!DOCTYPE HTML>');
  my $div = $doc->create_element ('div');
  my $svg = $doc->create_element_ns (q<http://www.w3.org/2000/svg>, 'svg:svg');
  $div->append_child ($svg);
  
  is $div->inner_html, q<<svg:svg></svg:svg>>;
} # _svg

sub _nanodom : Test(1) {
  require Whatpm::NanoDOM;
  my $doc = Whatpm::NanoDOM::Document->new;
  my $div = $doc->create_element_ns (q<http://www.w3.org/1999/xhtml>, [undef, 'div']);
  my $el = $doc->create_element_ns (q<http://www.w3.org/1999/xhtml>, [undef, 'p']);
  $div->append_child ($el);
  $el->text_content ("a b \x{1000}\x{2000}<!&\"'>\xA0");
  $el->set_attribute_ns (undef, [undef, 'title'], '<!&"\'>' . "\xA0");
  $el->append_child ($doc->create_comment ('A -- B'));
  $el->append_child ($doc->create_processing_instruction ('xml', 'version="1.0?>"'));
  $doc->append_child ($div);
  my $html = Whatpm::HTML::Serializer->get_inner_html ($doc);
  eq_or_diff $$html, qq{<div><p title="<!&amp;&quot;'>&nbsp;">a b \x{1000}\x{2000}&lt;!&amp;"'&gt;&nbsp;<!--A -- B--><?xml version="1.0?>"></p></div>};
}

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2009-2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
