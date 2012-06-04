package test::Message::DOM::TextTrackCue;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::DOMImplementation;
use Message::DOM::Node;

sub _constants : Test(4) {
  ok ELEMENT_NODE;
  ok ATTRIBUTE_NODE;
  ok DOCUMENT_TYPE_NODE;
  ok ATTRIBUTE_DEFINITION_NODE;
} # _constants

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;
my $SVG_NS = q<http://www.w3.org/2000/svg>;
my $MML_NS = q<http://www.w3.org/1998/Math/MathML>;

sub _manakai_get_child_namespace_uri_non_element_html : Test(36) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  
  for my $node (
    $doc,
    $doc->create_attribute ('hoge'),
    $doc->create_comment,
    $doc->create_document_fragment,
  ) {
    is $node->manakai_get_child_namespace_uri, $HTML_NS;
    is $node->manakai_get_child_namespace_uri (undef), $HTML_NS;
    is $node->manakai_get_child_namespace_uri ('a'), $HTML_NS;
    is $node->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $node->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $node->manakai_get_child_namespace_uri ('math'), $MML_NS;
    is $node->manakai_get_child_namespace_uri ('xml:base'), $HTML_NS;
    is $node->manakai_get_child_namespace_uri ('foreignObject'), $HTML_NS;
    is $node->manakai_get_child_namespace_uri ('malignmark'), $HTML_NS;
  }
} # _manakai_get_child_namespace_uri_non_element_html

sub _manakai_get_child_namespace_uri_non_element_xml_empty : Test(36) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  for my $node (
    $doc,
    $doc->create_attribute ('hoge'),
    $doc->create_comment,
    $doc->create_document_fragment,
  ) {
    is $node->manakai_get_child_namespace_uri, undef;
    is $node->manakai_get_child_namespace_uri (undef), undef;
    is $node->manakai_get_child_namespace_uri ('a'), undef;
    is $node->manakai_get_child_namespace_uri ('svg'), undef;
    is $node->manakai_get_child_namespace_uri ('SVG'), undef;
    is $node->manakai_get_child_namespace_uri ('math'), undef;
    is $node->manakai_get_child_namespace_uri ('xml:base'), undef;
    is $node->manakai_get_child_namespace_uri ('foreignObject'), undef;
    is $node->manakai_get_child_namespace_uri ('malignmark'), undef;
  }
} # _manakai_get_child_namespace_uri_non_element_xml_empty

sub _manakai_get_child_namespace_uri_non_element_xml_has_root_element : Test(56) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $el = $doc->create_element_ns (q<http://hoge/>, q<fuga>);
  $el->set_attribute_ns
      (q<http://www.w3.org/2000/xmlns/>,
       [q<xmlns>, q<AbC>] => q<http://foo/bar>);
  $doc->append_child ($el);
  
  for my $node (
    $doc,
  ) {
    is $node->manakai_get_child_namespace_uri, q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri (undef), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('a'), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('svg'), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('SVG'), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('math'), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('xml:base'), undef;
    is $node->manakai_get_child_namespace_uri ('foreignObject'), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('malignmark'), q<http://hoge/>;
    is $node->manakai_get_child_namespace_uri ('abc:mark'), undef;
    is $node->manakai_get_child_namespace_uri ('AbC:mark'), q<http://foo/bar>;
    is $node->manakai_get_child_namespace_uri ('AbC:'), q<http://foo/bar>;
    is $node->manakai_get_child_namespace_uri ('-:'), undef;
    is $node->manakai_get_child_namespace_uri (':abc'), undef;
  }

  for my $node (
    $doc->create_attribute ('hoge'),
    $doc->create_comment,
    $doc->create_document_fragment,
  ) {
    is $node->manakai_get_child_namespace_uri, undef;
    is $node->manakai_get_child_namespace_uri (undef), undef;
    is $node->manakai_get_child_namespace_uri ('a'), undef;
    is $node->manakai_get_child_namespace_uri ('svg'), undef;
    is $node->manakai_get_child_namespace_uri ('SVG'), undef;
    is $node->manakai_get_child_namespace_uri ('math'), undef;
    is $node->manakai_get_child_namespace_uri ('xml:base'), undef;
    is $node->manakai_get_child_namespace_uri ('foreignObject'), undef;
    is $node->manakai_get_child_namespace_uri ('malignmark'), undef;
    is $node->manakai_get_child_namespace_uri ('abc:mark'), undef;
    is $node->manakai_get_child_namespace_uri ('AbC:mark'), undef;
    is $node->manakai_get_child_namespace_uri ('AbC:'), undef;
    is $node->manakai_get_child_namespace_uri ('-:'), undef;
    is $node->manakai_get_child_namespace_uri (':abc'), undef;
  }
} # _manakai_get_child_namespace_uri_non_element_xml_has_root_element

sub _manakai_get_child_namespace_uri_element_xml_null_ns : Test(9) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  my $el = $doc->create_element ('hoge');
  is $el->manakai_get_child_namespace_uri, undef;
  is $el->manakai_get_child_namespace_uri (''), undef;
  is $el->manakai_get_child_namespace_uri (':'), undef;
  is $el->manakai_get_child_namespace_uri ('xml:lang'), undef;
  is $el->manakai_get_child_namespace_uri ('hoge:foo'), undef;
  is $el->manakai_get_child_namespace_uri ('svg'), undef;
  is $el->manakai_get_child_namespace_uri ('math'), undef;
  is $el->manakai_get_child_namespace_uri ('svg:math'), undef;

  $el->set_attribute_ns
      (q<http://www.w3.org/2000/xmlns/>, q<xmlns:hoge> => q<http://foo/>);
  is $el->manakai_get_child_namespace_uri ('hoge:foo'), q<http://foo/>;
} # _manakai_get_child_namespace_uri_element_xml_null_ns

sub _manakai_get_child_namespace_uri_element_xml_non_null_ns : Test(9) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  my $el = $doc->create_element_ns ('http://abc/', 'hoge');
  is $el->manakai_get_child_namespace_uri, 'http://abc/';
  is $el->manakai_get_child_namespace_uri (''), 'http://abc/';
  is $el->manakai_get_child_namespace_uri (':'), undef;
  is $el->manakai_get_child_namespace_uri ('xml:lang'), undef;
  is $el->manakai_get_child_namespace_uri ('hoge:foo'), undef;
  is $el->manakai_get_child_namespace_uri ('svg'), 'http://abc/';
  is $el->manakai_get_child_namespace_uri ('math'), 'http://abc/';
  is $el->manakai_get_child_namespace_uri ('svg:math'), undef;

  $el->set_attribute_ns
      (q<http://www.w3.org/2000/xmlns/>, q<xmlns:hoge> => q<http://foo/>);
  is $el->manakai_get_child_namespace_uri ('hoge:foo'), q<http://foo/>;
} # _manakai_get_child_namespace_uri_element_xml_non_null_ns

sub _manakai_get_child_namespace_uri_element_xml_html_ns : Test(9) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  my $el = $doc->create_element_ns ($HTML_NS, 'hoge');
  is $el->manakai_get_child_namespace_uri, $HTML_NS;
  is $el->manakai_get_child_namespace_uri (''), $HTML_NS;
  is $el->manakai_get_child_namespace_uri (':'), undef;
  is $el->manakai_get_child_namespace_uri ('xml:lang'), undef;
  is $el->manakai_get_child_namespace_uri ('hoge:foo'), undef;
  is $el->manakai_get_child_namespace_uri ('svg'), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('math'), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('svg:math'), undef;

  $el->set_attribute_ns
      (q<http://www.w3.org/2000/xmlns/>, q<xmlns:hoge> => q<http://foo/>);
  is $el->manakai_get_child_namespace_uri ('hoge:foo'), q<http://foo/>;
} # _manakai_get_child_namespace_uri_element_xml_html_ns

sub _manakai_get_child_namespace_uri_element_html : Test(10) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  my $el = $doc->create_element_ns ($HTML_NS, 'foo');
  is $el->manakai_get_child_namespace_uri, $HTML_NS;
  is $el->manakai_get_child_namespace_uri (''), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('hoge'), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('div'), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
  is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
  is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
  is $el->manakai_get_child_namespace_uri ('svg:foo'), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('xml:lang'), $HTML_NS;
  is $el->manakai_get_child_namespace_uri ('annotation-xml'), $HTML_NS;
} # _manakai_get_child_namespace_uri_element_html

sub _manakai_get_child_namespace_uri_element_html_mml : Test(39) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $tn (qw(math mabc xyz)) {
    my $el = $doc->create_element_ns ($MML_NS, $tn);
    is $el->manakai_get_child_namespace_uri, $MML_NS;
    is $el->manakai_get_child_namespace_uri (''), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $MML_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_mml

sub _manakai_get_child_namespace_uri_element_html_mml_text : Test(70) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $tn (qw(mi ms mn mo mtext)) {
    my $el = $doc->create_element_ns ($MML_NS, $tn);
    is $el->manakai_get_child_namespace_uri, $HTML_NS;
    is $el->manakai_get_child_namespace_uri (''), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('mGLYPh'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $HTML_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_mml_text

sub _manakai_get_child_namespace_uri_element_html_mml_axml : Test(52) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $enc (undef, '', 'text/plain', 'text/html ') {
    my $el = $doc->create_element_ns ($MML_NS, 'annotation-xml');
    $el->set_attribute (encoding => $enc) if defined $enc;
    is $el->manakai_get_child_namespace_uri, $MML_NS;
    is $el->manakai_get_child_namespace_uri (''), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $MML_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_mml_axml

sub _manakai_get_child_namespace_uri_element_html_mml_axml_ip : Test(39) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $enc ('text/html', 'Text/HTML', 'application/xhtml+xml') {
    my $el = $doc->create_element_ns ($MML_NS, 'annotation-xml');
    $el->set_attribute (encoding => $enc) if defined $enc;
    is $el->manakai_get_child_namespace_uri, $HTML_NS;
    is $el->manakai_get_child_namespace_uri (''), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $HTML_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_mml_axml_ip

sub _manakai_get_child_namespace_uri_element_html_svg : Test(52) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $tn (qw(svg mabc xyz foreignobject)) {
    my $el = $doc->create_element_ns ($SVG_NS, $tn);
    is $el->manakai_get_child_namespace_uri, $SVG_NS;
    is $el->manakai_get_child_namespace_uri (''), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $SVG_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_svg

sub _manakai_get_child_namespace_uri_element_html_svg_ip : Test(39) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $tn (qw(title desc foreignObject)) {
    my $el = $doc->create_element_ns ($SVG_NS, $tn);
    is $el->manakai_get_child_namespace_uri, $HTML_NS;
    is $el->manakai_get_child_namespace_uri (''), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $HTML_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_svg_ip

sub _manakai_get_child_namespace_uri_element_html_unknown : Test(39) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);

  for my $ns (undef, q<http://hoge/>) {
    my $el = $doc->create_element_ns ($ns, 'svg');
    is $el->manakai_get_child_namespace_uri, $HTML_NS;
    is $el->manakai_get_child_namespace_uri (''), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('hoge'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('div'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('svg'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('SVG'), $SVG_NS;
    is $el->manakai_get_child_namespace_uri ('MatH'), $MML_NS;
    is $el->manakai_get_child_namespace_uri ('svg:foo'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('xml:lang'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('annotation-xml'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('mglyph'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('malignmark'), $HTML_NS;
    is $el->manakai_get_child_namespace_uri ('ms'), $HTML_NS;
  }
} # _manakai_get_child_namespace_uri_element_html_unknown

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
