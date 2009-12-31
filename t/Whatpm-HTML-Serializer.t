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

__PACKAGE__->runtests;

1;
