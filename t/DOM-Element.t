#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 55 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;

{
  my $doc = $dom->create_document;
  my $el = $doc->create_element ('et1');

  ok 0+@{$el->attributes}, 0, 'create_element->attributes @{} 0+ [0]';

  my $dt = $doc->create_document_type_definition ('dt');
  my $et = $doc->create_element_type_definition ('et1');
  my $at = $doc->create_attribute_definition ('dattr1');
  $at->default_type ($at->EXPLICIT_DEFAULT);
  $at->text_content ('dattr1 default ');
  $et->set_attribute_definition_node ($at);
  $dt->set_element_type_definition_node ($et);
  $doc->append_child ($dt);
  my $el2 = $doc->create_element ('et1');

  ok 0+@{$el2->attributes}, 1, 'create_element->attributes @{} 0+ [1]';

  ok $el2->has_attribute ('dattr1') ? 1 : 0, 1, 'create_element->has_attr [1]';

  my $an = $el2->get_attribute_node ('dattr1');
  ok UNIVERSAL::isa ($an, 'Message::IF::Attr') ? 1 : 0, 1, 'ce->def if [1]';
  ok $an->text_content, 'dattr1 default ', 'ce->def tx [1]';
  ok $an->specified ? 1 : 0, 0, 'ce->def specified [1]';

  $doc->dom_config->set_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 0);
  
  my $el3 = $doc->create_element ('et1');
  ok 0+@{$el3->attributes}, 0, 'create_element->attributes @{} 0+ [2]';
}

{
  my $doc = $dom->create_document;
  my $el = $doc->create_element_ns (undef, 'et1');

  ok 0+@{$el->attributes}, 0, 'create_element->attributes @{} 0+ [0]';

  my $dt = $doc->create_document_type_definition ('dt');
  my $et = $doc->create_element_type_definition ('et1');
  my $at = $doc->create_attribute_definition ('dattr1');
  $at->default_type ($at->EXPLICIT_DEFAULT);
  $at->text_content ('dattr1 default ');
  $et->set_attribute_definition_node ($at);
  $dt->set_element_type_definition_node ($et);
  $doc->append_child ($dt);
  my $el2 = $doc->create_element ('et1');

  ok 0+@{$el2->attributes}, 1, 'create_element->attributes @{} 0+ [1]';

  ok $el2->has_attribute ('dattr1') ? 1 : 0, 1, 'create_element->has_attr [1]';

  my $an = $el2->get_attribute_node ('dattr1');
  ok UNIVERSAL::isa ($an, 'Message::IF::Attr') ? 1 : 0, 1, 'ce->def if [1]';
  ok $an->text_content, 'dattr1 default ', 'ce->def tx [1]';
  ok $an->specified ? 1 : 0, 0, 'ce->def specified [1]';

  $doc->dom_config->set_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute> => 0);
  
  my $el3 = $doc->create_element ('et1');
  ok 0+@{$el3->attributes}, 0, 'create_element->attributes @{} 0+ [2]';
}

my $doc = $dom->create_document;
my $el = $doc->create_element ('element');

for my $prop (qw/manakai_base_uri/) {
  ok $el->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('http://absuri.test/', 'reluri', 0, '') {
    $el->$prop ($_);
    ok $el->$prop, $_, $prop . $_;
  }

  $el->$prop (undef);
  ok $el->$prop, undef, $prop . ' undef';
}

for my $method (qw/set_attribute_node set_attribute_node_ns/) {
  my $el = $doc->create_element ('element');
  ok $el->can ($method) ? 1 : 0, 1, "can $method";

  my $a1 = $doc->create_attribute ('attr1');
  $a1->value ('value1');
  $a1->specified (0);

  my $r1 = $el->$method ($a1);
  ok $r1, undef, "$method return [1]";
  ok $el->get_attribute ('attr1'), 'value1', "$method get_attribute [1]";
  ok $el->get_attribute_ns (undef, 'attr1'), 'value1',
      "$method get_attribute_ns [1]";
  ok $el->get_attribute_node ('attr1'), $a1, "$method get_attribute_node [1]";
  ok $el->get_attribute_node_ns (undef, 'attr1'), $a1,
      "$method get_attribute_node_ns [1]";
  ok $a1->owner_element, $el, "$method owner_element [1]";
  ok $a1->specified ? 1 : 0, 1, "$method specified [1]";
  $a1->specified (0);

  my $a2 = $doc->create_attribute ('attr1');
  my $r3 = $el->$method ($a2);
  ok $r3, $a1, "$method return [2]";
  ok $a1->owner_element, undef, "$method owner_element [2]";
  ok $a1->specified ? 1 : 0, 1, "$method specified [2]";

  $el->set_attribute_ns (undef, attr => 'value');
  my $attr = $el->get_attribute_node_ns (undef, 'attr');
  $attr->specified (0);
  my $r4 = $el->$method ($attr);
  ok $r4, undef, "$method return [3]";
  ok $attr->owner_element, $el, "$method owner_element [3]";
  ok $attr->specified ? 1 : 0, 0, "$method specified [3]";
  ok $el->get_attribute_node_ns (undef, 'attr'), $attr,
      "$method get_attribute_node_ns [3]";
  ok $el->get_attribute_ns (undef, 'attr'), 'value',
      "$method get_attribute_ns [3]";
}

## |attributes|
{
  my $el = $doc->create_element ('e');
  ok $el->can ('attributes') ? 1 : 0, 1, 'Element->attributes can';

  my $as = $el->attributes;
  ok UNIVERSAL::isa ($as, 'Message::IF::NamedNodeMap') ? 1 : 0, 1, 'E->as if';
  
  $el->set_attribute (at1 => 'value');
  ok $as->get_named_item ('at1'), $el->get_attribute_node ('at1'),
      'Element->attributes get_named_item get_attr_node';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/08 13:04:39 $
