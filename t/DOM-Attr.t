#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 142 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

my $ent = $doc->create_attribute ('attr');

## Constants
my $constants = [
                 [NO_TYPE_ATTR => 0],
                 [CDATA_ATTR => 1],
                 [ID_ATTR => 2],
                 [IDREF_ATTR => 3],
                 [IDREFS_ATTR => 4],
                 [ENTITY_ATTR => 5],
                 [ENTITIES_ATTR => 6],
                 [NMTOKEN_ATTR => 7],
                 [NMTOKENS_ATTR => 8],
                 [NOTATION_ATTR => 9],
                 [ENUMERATION_ATTR => 10],
                 [UNKNOWN_ATTR => 11],
];
for (@$constants) {
  my $const_name = $_->[0];
  ok $ent->can ($const_name) ? 1 : 0, 1, "can ($const_name)";
  ok $ent->$const_name, $_->[1], $const_name;
}

## |specified|
{
  my $prop = 'specified';
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  ok $ent->$prop ? 1 : 0, 1, $prop . ' test is valid?';
  
  for (0, 1, '') {
    $ent->$prop ($_);
    ok $ent->$prop ? 1 : 0, 1, $prop . ' ' . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop ? 1 : 0, 1, $prop . ' undef';

  my $el = $doc->create_element ('element');
  $el->set_attribute_node ($ent); # set owner_element
  ok $ent->$prop ? 1 : 0, 1, $prop . ' test is valid? (has owner_element)';

  for (0, 1, '') {
    $ent->$prop ($_);
    ok $ent->$prop ? 1 : 0, $_ ? 1 : 0, $prop . ' (has owner_element) ' . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop ? 1 : 0, 0, $prop . ' (has owner_element) undef';
}

{
  my $attr = $doc->create_attribute_ns (undef, 'at1');
  my $el = $doc->create_element_ns (undef, 'el');
  $el->set_attribute_node_ns ($attr);
  ok $attr->specified ? 1 : 0, 1, 'specified [1]';
  $attr->specified (0);
  ok $attr->specified ? 1 : 0, 0, 'specified [2]';
  $attr->specified (1);
  ok $attr->specified ? 1 : 0, 1, 'specified [3]';
  $attr->specified (0);
  $el->remove_attribute_node ($attr);
  ok $attr->specified ? 1 : 0, 1, 'specified [4]';
}

{
  my $attr = $doc->create_attribute_ns (undef, 'at1');
  my $el = $doc->create_element_ns (undef, 'el');
  $el->set_attribute_node_ns ($attr);
  $attr->specified (0);
  my $attr2 = $doc->create_attribute_ns (undef, 'at1');
  $el->set_attribute_node_ns ($attr2);
  ok $attr->specified ? 1 : 0, 1, 'specified [5]';
}

for my $prop (qw/manakai_attribute_type/) {
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  local $^W = 0;
  
  for (-3..10, 'abc', '') {
    $ent->$prop ($_);
    ok $ent->$prop, 0+$_, $prop . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop, 0, $prop . ' undef';
}

## |schemaTypeInfo|
{
  my $el = $doc->create_element ('el');
  $el->owner_document->dom_config->set_parameter
      ('schema-type' => undef);
  $el->set_attribute_ns (undef, 'a', 'b');
  my $attr = $el->get_attribute_node_ns (undef, 'a');
  my $sti = $attr->schema_type_info;
  ok UNIVERSAL::isa ($sti, 'Message::IF::TypeInfo') ? 1 : 0, 1, 'sti if [1]';
  ok $sti->type_name, undef, 'sti type_name [1]';
  ok $sti->type_namespace, undef, 'sti type_namespace [1]';
}

{
  my $el = $doc->create_element ('el');
  $el->owner_document->dom_config->set_parameter
      ('schema-type' => q<http://www.w3.org/TR/REC-xml>);
  $el->set_attribute_ns (undef, 'a', 'b');
  my $attr = $el->get_attribute_node_ns (undef, 'a');
  my $sti = $attr->schema_type_info;
  ok UNIVERSAL::isa ($sti, 'Message::IF::TypeInfo') ? 1 : 0, 1, 'sti if [2]';
  ok $sti->type_name, undef, 'sti type_name [2]';
  ok $sti->type_namespace, undef, 'sti type_namespace [2]';
}

{
  my $el = $doc->create_element ('el');
  $el->owner_document->dom_config->set_parameter
      ('schema-type' => q<http://www.w3.org/TR/REC-xml>);
  $el->set_attribute_ns (undef, 'a', 'b');
  my $attr = $el->get_attribute_node_ns (undef, 'a');
  for (
       [$attr->CDATA_ATTR, 'CDATA'],
       [$attr->ID_ATTR, 'ID'],
       [$attr->IDREF_ATTR, 'IDREF'],
       [$attr->IDREFS_ATTR, 'IDREFS'],
       [$attr->ENTITY_ATTR, 'ENTITY'],
       [$attr->ENTITIES_ATTR, 'ENTITIES'],
       [$attr->NOTATION_ATTR, 'NOTATION'],
       [$attr->ENUMERATION_ATTR, 'ENUMERATION'],
       [$attr->NMTOKEN_ATTR, 'NMTOKEN'],
       [$attr->NMTOKENS_ATTR, 'NMTOKENS'],
      ) {
    $attr->manakai_attribute_type ($_->[0]);
    my $sti = $attr->schema_type_info;
    ok UNIVERSAL::isa ($sti, 'Message::IF::TypeInfo') ? 1 : 0, 1,
        'sti if '.$_->[1].' [3]';
    ok $sti->type_name, $_->[1], 'sti type_name '.$_->[1].' [3]';
    ok $sti->type_namespace, q<http://www.w3.org/TR/REC-xml>,
        'sti type_namespace '.$_->[1].' [3]';
  }

  for (
       [$attr->NO_TYPE_ATTR, 'NO_VALUE'],
       [$attr->UNKNOWN_ATTR, 'UNKNOWN'],
      ) {
    $attr->manakai_attribute_type ($_->[0]);
    my $sti = $attr->schema_type_info;
    ok UNIVERSAL::isa ($sti, 'Message::IF::TypeInfo') ? 1 : 0, 1,
        'sti if '.$_->[1].' [3]';
    ok $sti->type_name, undef, 'sti type_name '.$_->[1].' [3]';
    ok $sti->type_namespace, undef, 'sti type_namespace '.$_->[1].' [3]';
  }
}

## |isId|
{
  my $attr = $doc->create_attribute ('a');
  $attr->manakai_attribute_type ($attr->ID_ATTR);
  ok $attr->is_id ? 1 : 0, 1, 'is_id [1]';
  $attr->is_id (1);
  ok $attr->is_id ? 1 : 0, 1, 'is_id [2]';
  $attr->is_id (0);
  ok $attr->is_id ? 1 : 0, 1, 'is_id [3]';
}

{
  my $attr = $doc->create_attribute ('a');
  for (
       $attr->CDATA_ATTR,
       $attr->IDREF_ATTR,
       $attr->IDREFS_ATTR,
       $attr->ENTITY_ATTR,
       $attr->ENTITIES_ATTR,
       $attr->NOTATION_ATTR,
       $attr->ENUMERATION_ATTR,
       $attr->NMTOKEN_ATTR,
       $attr->NMTOKENS_ATTR,
       $attr->NO_TYPE_ATTR,
       $attr->UNKNOWN_ATTR,
    ) {
    $attr->manakai_attribute_type ($_);
    ok $attr->is_id ? 1 : 0, 0, 'is_id '.$_.' [1]';
    $attr->is_id (1);
    ok $attr->is_id ? 1 : 0, 1, 'is_id '.$_.' [2]';
    $attr->is_id (0);
    ok $attr->is_id ? 1 : 0, 0, 'is_id '.$_.' [3]';
  }
}

{
  my $attr = $doc->create_attribute ('xml:id');
  ok $attr->is_id ? 1 : 0, 1, 'is_id xml:id [1]';
  $attr->is_id (0);
  ok $attr->is_id ? 1 : 0, 1, 'is_id xml:id [2]';
  $attr->is_id (1);
  ok $attr->is_id ? 1 : 0, 1, 'is_id xml:id [3]';
}

{
  my $attr = $doc->create_attribute_ns
      (q<http://www.w3.org/XML/1998/namespace>, 'xml:id');
  ok $attr->is_id ? 1 : 0, 1, 'is_id xml:id [4]';
  $attr->is_id (0);
  ok $attr->is_id ? 1 : 0, 1, 'is_id xml:id [5]';
  $attr->is_id (1);
  ok $attr->is_id ? 1 : 0, 1, 'is_id xml:id [6]';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/29 03:49:00 $
