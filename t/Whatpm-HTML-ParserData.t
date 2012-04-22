package test::Whatpm::HTML::ParserData;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::HTML::ParserData;

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

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
