#!/usr/bin/perl
package test::Message::DOM::Element;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;

sub _test1 : Test(7) {
  my $doc = $dom->create_document;
  my $el = $doc->create_element ('et1');

  is 0+@{$el->attributes}, 0, 'create_element->attributes @{} 0+ [0]';

  my $dt = $doc->create_document_type_definition ('dt');
  my $et = $doc->create_element_type_definition ('et1');
  my $at = $doc->create_attribute_definition ('dattr1');
  $at->default_type ($at->EXPLICIT_DEFAULT);
  $at->text_content ('dattr1 default ');
  $et->set_attribute_definition_node ($at);
  $dt->set_element_type_definition_node ($et);
  $doc->append_child ($dt);
  my $el2 = $doc->create_element ('et1');

  is 0+@{$el2->attributes}, 1, 'create_element->attributes @{} 0+ [1]';

  is $el2->has_attribute ('dattr1') ? 1 : 0, 1, 'create_element->has_attr [1]';

  my $an = $el2->get_attribute_node ('dattr1');
  is UNIVERSAL::isa ($an, 'Message::IF::Attr') ? 1 : 0, 1, 'ce->def if [1]';
  is $an->text_content, 'dattr1 default ', 'ce->def tx [1]';
  is $an->specified ? 1 : 0, 0, 'ce->def specified [1]';

  $doc->dom_config->set_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 0);
  
  my $el3 = $doc->create_element ('et1');
  is 0+@{$el3->attributes}, 0, 'create_element->attributes @{} 0+ [2]';
} # _test1

sub _test2 : Test(7) {
  my $doc = $dom->create_document;
  my $el = $doc->create_element_ns (undef, 'et1');
  
  is 0+@{$el->attributes}, 0, 'create_element->attributes @{} 0+ [0]';
  
  my $dt = $doc->create_document_type_definition ('dt');
  my $et = $doc->create_element_type_definition ('et1');
  my $at = $doc->create_attribute_definition ('dattr1');
  $at->default_type ($at->EXPLICIT_DEFAULT);
  $at->text_content ('dattr1 default ');
  $et->set_attribute_definition_node ($at);
  $dt->set_element_type_definition_node ($et);
  $doc->append_child ($dt);
  my $el2 = $doc->create_element ('et1');

  is 0+@{$el2->attributes}, 1, 'create_element->attributes @{} 0+ [1]';

  is $el2->has_attribute ('dattr1') ? 1 : 0, 1, 'create_element->has_attr [1]';

  my $an = $el2->get_attribute_node ('dattr1');
  is UNIVERSAL::isa ($an, 'Message::IF::Attr') ? 1 : 0, 1, 'ce->def if [1]';
  is $an->text_content, 'dattr1 default ', 'ce->def tx [1]';
  is $an->specified ? 1 : 0, 0, 'ce->def specified [1]';

  $doc->dom_config->set_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 0);
  
  my $el3 = $doc->create_element ('et1');
  is 0+@{$el3->attributes}, 0, 'create_element->attributes @{} 0+ [2]';
} # _test2

sub _manakai_base_uri : Test(6) {
  my $doc = $dom->create_document;
  my $el = $doc->create_element ('element');
  
  for my $prop (qw/manakai_base_uri/) {
    is $el->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
    
    for ('http://absuri.test/', 'reluri', 0, '') {
      $el->$prop ($_);
      is $el->$prop, $_, $prop . $_;
    }
    
    $el->$prop (undef);
    is $el->$prop, undef, $prop . ' undef';
  }
} # _manakai_base_uri

sub _set_attr_node : Test(32) {
  for my $method (qw/set_attribute_node set_attribute_node_ns/) {
    my $doc = $dom->create_document;

    my $el = $doc->create_element ('element');
    is $el->can ($method) ? 1 : 0, 1, "can $method";
    
    my $a1 = $doc->create_attribute ('attr1');
    $a1->value ('value1');
    $a1->specified (0);
    
    my $r1 = $el->$method ($a1);
    is $r1, undef, "$method return [1]";
    is $el->get_attribute ('attr1'), 'value1', "$method get_attribute [1]";
    is $el->get_attribute_ns (undef, 'attr1'), 'value1',
        "$method get_attribute_ns [1]";
    is $el->get_attribute_node ('attr1'), $a1,
        "$method get_attribute_node [1]";
    is $el->get_attribute_node_ns (undef, 'attr1'), $a1,
        "$method get_attribute_node_ns [1]";
    is $a1->owner_element, $el, "$method owner_element [1]";
    is $a1->specified ? 1 : 0, 1, "$method specified [1]";
    $a1->specified (0);
    
    my $a2 = $doc->create_attribute ('attr1');
    my $r3 = $el->$method ($a2);
    is $r3, $a1, "$method return [2]";
    is $a1->owner_element, undef, "$method owner_element [2]";
    is $a1->specified ? 1 : 0, 1, "$method specified [2]";
    
    $el->set_attribute_ns (undef, attr => 'value');
    my $attr = $el->get_attribute_node_ns (undef, 'attr');
    $attr->specified (0);
    my $r4 = $el->$method ($attr);
    is $r4, undef, "$method return [3]";
    is $attr->owner_element, $el, "$method owner_element [3]";
    is $attr->specified ? 1 : 0, 0, "$method specified [3]";
    is $el->get_attribute_node_ns (undef, 'attr'), $attr,
        "$method get_attribute_node_ns [3]";
    is $el->get_attribute_ns (undef, 'attr'), 'value',
        "$method get_attribute_ns [3]";
  }
} # _set_attr_node

sub _attributes : Test(3) {
  my $doc = $dom->create_document;
  my $el = $doc->create_element ('e');
  is $el->can ('attributes') ? 1 : 0, 1, 'Element->attributes can';

  my $as = $el->attributes;
  is UNIVERSAL::isa ($as, 'Message::IF::NamedNodeMap') ? 1 : 0, 1, 'E->as if';
  
  $el->set_attribute (at1 => 'value');
  is $as->get_named_item ('at1'), $el->get_attribute_node ('at1'),
      'Element->attributes get_named_item get_attr_node';
} # _attributes

sub _schema_type_info_1 : Test(3) {
  my $doc = $dom->create_document;
  my $el = $doc->create_element ('el');
  $el->owner_document->dom_config->set_parameter ('schema-type' => undef);
  my $sti = $el->schema_type_info;
  is UNIVERSAL::isa ($sti, 'Message::IF::TypeInfo') ? 1 : 0, 1, 'sti if [1]';
  is $sti->type_name, undef, 'sti type_name [1]';
  is $sti->type_namespace, undef, 'sti type_namespace [1]';
} # _schema_type_info_1

sub _schema_type_info_2 : Test(3) {
  my $doc = $dom->create_document;
  my $el = $doc->create_element ('el');
  $el->owner_document->dom_config->set_parameter
      ('schema-type' => q<http://www.w3.org/TR/REC-xml>);
  my $sti = $el->schema_type_info;
  is UNIVERSAL::isa ($sti, 'Message::IF::TypeInfo') ? 1 : 0, 1, 'sti if [2]';
  is $sti->type_name, undef, 'sti type_name [2]';
  is $sti->type_namespace, undef, 'sti type_namespace [2]';
} # _schema_type_info_2

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
