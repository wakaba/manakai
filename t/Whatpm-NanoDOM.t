#!/usr/bin/perl
package test::Whatpm::NanoDOM;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::NanoDOM;

sub _element_tag_name_xml_lowercase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el1 = $doc->create_element_ns (undef, [undef, 'element']);
  is $el1->tag_name, 'element';
  is $el1->manakai_tag_name, 'element';

  $doc->manakai_is_html (1);
  is $el1->tag_name, 'element';
  is $el1->manakai_tag_name, 'element';
}

sub _element_tag_name_xml_mixcase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el1 = $doc->create_element_ns (undef, [undef, 'eleMent']);
  is $el1->tag_name, 'eleMent';
  is $el1->manakai_tag_name, 'eleMent';

  $doc->manakai_is_html (1);
  is $el1->tag_name, 'eleMent';
  is $el1->manakai_tag_name, 'eleMent';
}

sub _element_tag_name_html_lowercase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el1 = $doc->create_element_ns (q<http://www.w3.org/1999/xhtml>, [undef, 'element']);
  {
    local $TODO = 'Not implemented yet';
    is $el1->tag_name, 'ELEMENT';
  }
  is $el1->manakai_tag_name, 'element';

  $doc->manakai_is_html (1);
  {
    local $TODO = 'Not implemented yet';
    is $el1->tag_name, 'ELEMENT';
  }
  is $el1->manakai_tag_name, 'element';
}

sub _element_tag_name_html_mixcase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el1 = $doc->create_element_ns (q<http://www.w3.org/1999/xhtml>, [undef, 'eleMent']);
  {
    local $TODO = 'Not implemented yet';
    is $el1->tag_name, 'ELEMENT';
  }
  is $el1->manakai_tag_name, 'eleMent';

  $doc->manakai_is_html (1);
  {
    local $TODO = 'Not implemented yet';
    is $el1->tag_name, 'ELEMENT';
  }
  is $el1->manakai_tag_name, 'eleMent';
}

sub _attr_name_xml_lowercase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el = $doc->create_element_ns (undef, [undef, 'div']);
  $el->set_attribute_ns (undef, [undef, 'attribute']);
  is $el->get_attribute_node_ns (undef, 'attribute')->name, 'attribute';
  is $el->get_attribute_node_ns (undef, 'attribute')->manakai_name, 'attribute';

  $doc->manakai_is_html (1);
  is $el->get_attribute_node_ns (undef, 'attribute')->name, 'attribute';
  is $el->get_attribute_node_ns (undef, 'attribute')->manakai_name, 'attribute';
}

sub _attr_name_xml_mixcase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el = $doc->create_element_ns (undef, [undef, 'div']);
  $el->set_attribute_ns (undef, [undef, 'attriBute']);
  is $el->get_attribute_node_ns (undef, 'attriBute')->name, 'attriBute';
  is $el->get_attribute_node_ns (undef, 'attriBute')->manakai_name, 'attriBute';

  $doc->manakai_is_html (1);
  is $el->get_attribute_node_ns (undef, 'attriBute')->name, 'attriBute';
  is $el->get_attribute_node_ns (undef, 'attriBute')->manakai_name, 'attriBute';
}

sub _attr_name_html_lowercase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el = $doc->create_element_ns (q<http://www.w3.org/1999/xhtml>, [undef, 'div']);
  $el->set_attribute_ns (undef, [undef, 'attribute']);
  is $el->get_attribute_node_ns (undef, 'attribute')->name, 'attribute';
  is $el->get_attribute_node_ns (undef, 'attribute')->manakai_name, 'attribute';

  $doc->manakai_is_html (1);
  is $el->get_attribute_node_ns (undef, 'attribute')->name, 'attribute';
  is $el->get_attribute_node_ns (undef, 'attribute')->manakai_name, 'attribute';
}

sub _attr_name_html_mixcase : Test(4) {
  my $doc = Whatpm::NanoDOM::Document->new;
  my $el = $doc->create_element_ns (q<http://www.w3.org/1999/xhtml>, [undef, 'div']);
  $el->set_attribute_ns (undef, [undef, 'attriBute']);
  is $el->get_attribute_node_ns (undef, 'attriBute')->name, 'attriBute';
  is $el->get_attribute_node_ns (undef, 'attriBute')->manakai_name, 'attriBute';

  $doc->manakai_is_html (1);
  is $el->get_attribute_node_ns (undef, 'attriBute')->name, 'attriBute';
  is $el->get_attribute_node_ns (undef, 'attriBute')->manakai_name, 'attriBute';
}

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2009-2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
