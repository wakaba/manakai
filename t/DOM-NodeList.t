#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 10 }

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

for my $parent (create_parent_nodes ()) {
  my $node1;
  my $node2;
  my $node1a;
  my $node2a;
  if ($parent->node_type == $parent->DOCUMENT_TYPE_NODE) {
    $node1 = $doc->create_processing_instruction ('pi1', 'data1');
    $node2 = $doc->create_processing_instruction ('pi2', 'data2');
    $node1a = $doc->create_processing_instruction ('pi1', 'data1');
    $node2a = $doc->create_processing_instruction ('pi2', 'data2');
  } elsif ($parent->node_type == $parent->DOCUMENT_NODE) {
    $node1 = $doc->create_comment ('comment1');
    $node2 = $doc->create_comment ('comment2');
    $node1a = $doc->create_comment ('comment1');
    $node2a = $doc->create_comment ('comment2');
  } else {
    $node1 = $doc->create_text_node ('text1');
    $node2 = $doc->create_text_node ('text2');
    $node1a = $doc->create_text_node ('text1');
    $node2a = $doc->create_text_node ('text2');
  }

  my $cn = $parent->child_nodes;
  ok UNIVERSAL::isa ($cn, 'Message::IF::NodeList') ? 1 : 0, 1,
      'childNodes.interface';
  ok $cn ? 1 : 0, 1, 'bool';

  ok $cn->can ('manakai_read_only') ? 1 : 0, 1, 'can childNodes.manakaiReadOnly';
  $parent->manakai_set_read_only (1);
  ok $cn->manakai_read_only ? 1 : 0, 1, 'childNodes.manakaiReadOnly (1)';
  $parent->manakai_set_read_only (0);
  ok $cn->manakai_read_only ? 1 : 0, 0, 'childNodes.manakaiReadOnly (0)';

  ok $cn->can ('length') ? 1 : 0, 1, 'can childNodes.length [0]';
  ok $cn->length, 0, 'childNodes.length [0]';

  ok $cn->can ('item') ? 1 : 0, 1, 'can childNodes.item';
  ok $cn->item (0), undef, 'childNodes.item (0) [0]';
  ok $cn->item (1), undef, 'childNodes.item (1) [0]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [0]';
  ok $cn->item (undef), undef, 'childNodes.item (undef) [0]';

  $parent->append_child ($node1);
  
  ok $cn->length, 1, 'childNodes.length [1]';

  ok $cn->item (0), $node1, 'childNodes.item (0) [1]';
  ok $cn->item (1), undef, 'childNodes.item (1) [1]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [1]';
  ok $cn->item (undef), $node1, 'childNodes.item (undef) [1]';

  $parent->append_child ($node2);
  
  ok $cn->length, 2, 'childNodes.length [2]';

  ok $cn->item (0), $node1, 'childNodes.item (0) [2]';
  ok $cn->item (1), $node2, 'childNodes.item (1) [2]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [2]';
  ok $cn->item (undef), $node1, 'childNodes.item (undef) [2]';

  ok $cn eq $cn ? 1 : 0, 1, 'A eq A';
  ok $cn ne $cn ? 1 : 0, 0, 'A ne A';
  ok $cn == $cn ? 1 : 0, 1, 'A == A';
  ok $cn != $cn ? 1 : 0, 0, 'A != A';
  
  my $cn2 = $parent->child_nodes;
  ok $cn eq $cn2 ? 1 : 0, 1, "A eq A'";
  ok $cn ne $cn2 ? 1 : 0, 0, "A ne A'";
  ok $cn == $cn2 ? 1 : 0, 1, "A == A'";
  ok $cn != $cn2 ? 1 : 0, 0, "A != A'";

  my $parenta = $doc->create_element ('element');
  my $cn3 = $parenta->child_nodes;
  ok $cn eq $cn3 ? 1 : 0, 0, 'A eq B (A != B)';
  ok $cn ne $cn3 ? 1 : 0, 1, 'A ne B (A != B)';
  ok $cn == $cn3 ? 1 : 0, 0, 'A == B (A != B)';
  ok $cn != $cn3 ? 1 : 0, 1, 'A != B (A != B)';

  $parenta->append_child ($node1a);
  $parenta->append_child ($node2a);
  ok $cn eq $cn3 ? 1 : 0, 0, 'A eq B (A == B)';
  ok $cn ne $cn3 ? 1 : 0, 1, 'A ne B (A == B)';
  ok $cn == $cn3 ? 1 : 0, 1, 'A == B (A == B)';
  ok $cn != $cn3 ? 1 : 0, 0, 'A != B (A == B)';
}

## TODO: tests for @{$node_list} and @{$empty_node_list}

sub create_leaf_nodes () {
  (
   $doc->create_cdata_section ('cdata1'),
   $doc->create_comment ('comment1'),
   $doc->create_notation ('notation1'),
   $doc->create_processing_instruction ('pi1', 'pi1data'),
   $doc->create_text_node ('text1'),
  );
} # create_leaf_nodes

sub create_parent_nodes () {
  (
   $doc->create_attribute ('attr1'),
   $doc->create_attribute_definition ('at1'),
   $doc->create_element ('element1'),
   $doc->create_general_entity ('entity1'),
   $doc->create_entity_reference ('entity-reference1'),
   $doc->implementation->create_document,
   $doc->create_document_fragment,
   $doc->create_document_type_definition ('dt1'),
  );
} # create_parent_nodes
