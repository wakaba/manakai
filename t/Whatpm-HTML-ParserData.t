package test::Whatpm::HTML::ParserData;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::HTML::ParserData;

sub _nsurls : Test(6) {
  ok Whatpm::HTML::ParserData::HTML_NS;
  ok Whatpm::HTML::ParserData::SVG_NS;
  ok Whatpm::HTML::ParserData::MML_NS;
  ok Whatpm::HTML::ParserData::XML_NS;
  ok Whatpm::HTML::ParserData::XMLNS_NS;
  ok Whatpm::HTML::ParserData::XLINK_NS;
} # _nsurls

sub _mathml_attr : Test(1) {
  is $Whatpm::HTML::ParserData::MathMLAttrNameFixup->{definitionurl},
      'definitionURL';
} # _mathml_attr

sub _svg_attr : Test(1) {
  is $Whatpm::HTML::ParserData::SVGAttrNameFixup->{glyphref},
      'glyphRef';
} # _svg_attr

sub _foreign_attr : Test(1) {
  is_deeply $Whatpm::HTML::ParserData::ForeignAttrNamespaceFixup->{'xml:lang'},
      ['http://www.w3.org/XML/1998/namespace', ['xml', 'lang']];
} # _foreign_attr

sub _svg_el : Test(1) {
  is $Whatpm::HTML::ParserData::SVGElementNameFixup->{foreignobject},
      'foreignObject';
} # _svg_el

sub _charrefes : Test(3) {
  is $Whatpm::HTML::ParserData::NamedCharRefs->{'amp;'}, '&';
  is $Whatpm::HTML::ParserData::NamedCharRefs->{'AMP'}, '&';
  is $Whatpm::HTML::ParserData::NamedCharRefs->{'acE;'}, "\x{223E}\x{333}";
} # _charrefs

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
