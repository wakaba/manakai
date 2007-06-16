#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 10 }

require Message::DOM::DOMImplementation;
use Message::Util::Error;

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
  ok 0+@$cn, 0, '@{child_nodes} [0]';

  ok $cn->can ('item') ? 1 : 0, 1, 'can childNodes.item';
  ok $cn->item (0), undef, 'childNodes.item (0) [0]';
  ok $cn->item (1), undef, 'childNodes.item (1) [0]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [0]';
  ok $cn->item (undef), undef, 'childNodes.item (undef) [0]';
  ok $cn->[0], undef, 'child_nodes->[0] [0]';
  ok $cn->[1], undef, 'child_nodes->[1] [0]';

  $parent->append_child ($node1);
  
  ok $cn->length, 1, 'childNodes.length [1]';

  ok $cn->item (0), $node1, 'childNodes.item (0) [1]';
  ok $cn->item (1), undef, 'childNodes.item (1) [1]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [1]';
  ok $cn->item (undef), $node1, 'childNodes.item (undef) [1]';
  ok $cn->[0], $node1, 'child_nodes->[0] [1]';
  ok $cn->[1], undef, 'child_nodes->[1] [1]';
  ok exists $cn->[0] ? 1 : 0, 1, 'exists child_nodes->[0] [1]';
  ok exists $cn->[1] ? 1 : 0, 0, 'exists child_nodes->[1] [1]';

  $parent->append_child ($node2);
  
  ok $cn->length, 2, 'childNodes.length [2]';

  ok $cn->item (0), $node1, 'childNodes.item (0) [2]';
  ok $cn->item (1), $node2, 'childNodes.item (1) [2]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [2]';
  ok $cn->item (undef), $node1, 'childNodes.item (undef) [2]';
  ok $cn->[0], $node1, 'child_nodes->[0] [2]';
  ok $cn->[1], $node2, 'child_nodes->[1] [2]';

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

  $cn->[2] = $node1a;
  ok $cn->[2], $node1a, 'child_nodes->[2] setter (item)';
  ok 0+@$cn, 3, 'child_nodes->[2] setter (length)';

  $cn->[4] = $node2a;
  ok $cn->[3], $node2a, 'child_nodes->[3] setter (item)';
  ok $cn->[4], undef, 'child_nodes->[4] setter (item)';
  ok 0+@$cn, 4, 'child_nodes->[4] setter (length)';
  ## TODO: Add replaceChild test

  my $deleted = delete $cn->[4];
  ok $deleted, undef, 'delete child_nodes->[4]';
  ok $cn->[3], $node2a, 'delete child_nodes->[4] item(3)';
  ok $cn->[4], undef, 'delete child_nodes->[4] item(4)';

  $deleted = delete $cn->[0];
  ok $deleted, $node1, 'delete child_nodes->[0]';
  ok $cn->[0], $node2, 'delete child_nodes->[0] item(0)';
  ok $cn->[1], $node1a, 'delete child_nodes->[0] item(1)';
  ok $cn->[2], $node2a, 'delete child_nodes->[0] item(2)';
  ok $cn->[3], undef, 'delete child_nodes->[0] item(3)';
  ok $cn->[4], undef, 'delete child_nodes->[0] item(4)';

  my @a = @$cn;
  ok 0+@a, 3;
  ok $a[0], $node2, '@ = @{child_nodes} item(0)';
  ok $a[1], $node1a, '@ = @{child_nodes} item(1)';
  ok $a[2], $node2a, '@ = @{child_nodes} item(2)';
  ok $a[3], undef, '@ = @{child_nodes} item(3)';

  @$cn = ();
  ok 0+@$cn, 0, 'child_nodes->clear';
}

for my $parent (create_leaf_nodes ()) {
  my $node1;
  my $node2;
  my $node1a;
  my $node2a;
    $node1 = $doc->create_text_node ('text1');
    $node2 = $doc->create_text_node ('text2');
    $node1a = $doc->create_text_node ('text1');
    $node2a = $doc->create_text_node ('text2');

  my $cn = $parent->child_nodes;
  ok UNIVERSAL::isa ($cn, 'Message::IF::NodeList') ? 1 : 0, 1,
      'childNodes.interface';
  ok $cn ? 1 : 0, 1, 'bool';

  ok $cn->can ('manakai_read_only') ? 1 : 0, 1, 'can childNodes.manakaiReadOnly';
  $parent->manakai_set_read_only (1);
  ok $cn->manakai_read_only ? 1 : 0, 1, 'childNodes.manakaiReadOnly (1)';
  $parent->manakai_set_read_only (0);
  ok $cn->manakai_read_only ? 1 : 0, 1, 'childNodes.manakaiReadOnly (0)';

  ok $cn->can ('length') ? 1 : 0, 1, 'can childNodes.length [0]';
  ok $cn->length, 0, 'childNodes.length [0]';
  ok 0+@$cn, 0, '@{child_nodes} [0]';

  ok $cn->can ('item') ? 1 : 0, 1, 'can childNodes.item';
  ok $cn->item (0), undef, 'childNodes.item (0) [0]';
  ok $cn->item (1), undef, 'childNodes.item (1) [0]';
  ok $cn->item (-1), undef, 'childNodes.item (-1) [0]';
  ok $cn->item (undef), undef, 'childNodes.item (undef) [0]';
  ok $cn->[0], undef, 'child_nodes->[0] [0]';
  ok $cn->[1], undef, 'child_nodes->[1] [0]';
  ok exists $cn->[0] ? 1 : 0, 0, 'exists child_nodes->[0] [1]';
  ok exists $cn->[1] ? 1 : 0, 0, 'exists child_nodes->[1] [1]';

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
  ok $cn == $cn3 ? 1 : 0, 1, 'A == B (A != B)';
  ok $cn != $cn3 ? 1 : 0, 0, 'A != B (A != B)';

  try {
    $cn->[2] = $node1a;
    ok 0, 1, $parent->node_name . '->child_nodes->[2] = $node';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NO_MODIFICATION_ALLOWED_ERR',
        $parent->node_name . '->child_nodes->[2] = $node';
  };
  ok 0+@$cn, 0, $parent->node_name . '->child_nodes->[2] (length)';

  try {
    delete $cn->[4];
    ok 0, 1, $parent->node_name . '->child_nodes->[2] delete';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NO_MODIFICATION_ALLOWED_ERR',
        $parent->node_name . '->child_nodes->[2] delete';
  };

  my @a = @$cn;
  ok 0+@a, 0, $parent->node_type . '->child_nodes @{} = 0+';

  try {
    @$cn = ();
    ok 0, 1, $parent->node_name . '->child_nodes->[2] delete';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NO_MODIFICATION_ALLOWED_ERR',
        $parent->node_name . '->child_nodes @{} CLEAR';
  };
}

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

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/16 08:49:00 $
