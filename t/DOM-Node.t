#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 4 } 

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

## Constants
my $constants = [
  [ELEMENT_NODE => 1],
  [ATTRIBUTE_NODE => 2],
  [TEXT_NODE => 3],
  [CDATA_SECTION_NODE => 4],
  [ENTITY_REFERENCE_NODE => 5],
  [ENTITY_NODE => 6],
  [PROCESSING_INSTRUCTION_NODE => 7],
  [COMMENT_NODE => 8],
  [DOCUMENT_NODE => 9],
  [DOCUMENT_TYPE_NODE => 10],
  [DOCUMENT_FRAGMENT_NODE => 11],
  [NOTATION_NODE => 12],
  [ELEMENT_TYPE_DEFINITION_NODE => 81001],
  [ATTRIBUTE_DEFINITION_NODE => 81002],
];

my $tests = {
  attr => {
    node => sub {
      my $attr = $doc->create_attribute ('a');
      $attr->value ('b');
      return $attr;
    },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
      name => 'a',
      node_value => 'b',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      value => 'b',
      attributes => undef,
    },
  },
  attr_ns_default => {
    node => sub {
      my $attr = $doc->create_attribute_ns (undef, 'a');
      $attr->value ('b');
      return $attr;
    },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
      name => 'a',
      node_value => 'b',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      value => 'b',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  attr_ns_prefixed => {
    node => sub {
      my $attr = $doc->create_attribute_ns ('http://test/', 'a:b');
      $attr->value ('c');
      return $attr;
    },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => 'b',
      manakai_local_name => 'b',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'a:b',
      name => 'a:b',
      node_value => 'c',
      owner_document => $doc,
      parent_node => undef,
      prefix => 'a',
      value => 'c',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  cdatasection => {
    node => sub { return $doc->create_cdata_section ('cdatadata') },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#cdata-section',
      node_value => 'cdatadata',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'cdatadata',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  cdatasectionmde => {
    node => sub { return $doc->create_cdata_section ('cdata]]>data') },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#cdata-section',
      node_value => 'cdata]]>data',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'cdata]]>data',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  comment => {
    node => sub { return $doc->create_comment ('commentdata') },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#comment',
      node_value => 'commentdata',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'commentdata',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  commentcom1 => {
    node => sub { return $doc->create_comment ('comment--data') },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#comment',
      node_value => 'comment--data',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'comment--data',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  commentcom2 => {
    node => sub { return $doc->create_comment ('commentdata-') },
    attr_get => {
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#comment',
      node_value => 'commentdata-',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'commentdata-',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  document => {
    node => sub { return $doc },
    attr_get => {
      attributes => undef,
      first_child => undef,
      implementation => $dom,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#document',
      node_value => undef,
      owner_document => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  document_fragment => {
    node => sub { return $doc->create_document_fragment },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#document-fragment',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  document_type => {
    node => sub { return $doc->implementation->create_document_type ('n') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      implementation => $dom,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'n',
      node_value => undef,
      owner_document => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  document_type_definition => {
    node => sub { return $doc->create_document_type_definition ('n') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      implementation => $dom,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'n',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  element => {
    node => sub { return $doc->create_element ('e') },
    attr_get => {
      ## TODO: attributes => 
      first_child => undef,
      last_child => undef,
      local_name => 'e',
      manakai_local_name => 'e',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  element_ns_default => {
    node => sub { return $doc->create_element_ns ('http://test/', 'f') },
    attr_get => {
      ## TODO: attributes => 
      first_child => undef,
      last_child => undef,
      local_name => 'f',
      manakai_local_name => 'f',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'f',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  element_ns_prefiexed => {
    node => sub { return $doc->create_element_ns ('http://test/', 'e:f') },
    attr_get => {
      ## TODO: attributes => 
      first_child => undef,
      last_child => undef,
      local_name => 'f',
      manakai_local_name => 'f',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'e:f',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => 'e',
      previous_sibling => undef,
    },
  },
  entity => {
    node => sub { return $doc->create_general_entity ('e') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      previous_sibling => undef,
    },
  },
  entity_reference => {
    node => sub { return $doc->create_entity_reference ('e') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  notation => {
    node => sub { return $doc->create_notation ('e') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  processing_instruction => {
    node => sub { return $doc->create_processing_instruction ('t', 'd') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 't',
      node_value => 'd',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  text => {
    node => sub { return $doc->create_text_node ('textdata') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#text',
      node_value => 'textdata',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  element_type_definition => {
    node => sub { return $doc->create_element_type_definition ('e') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
  attribute_definition => {
    node => sub { return $doc->create_attribute_definition ('e') },
    attr_get => {
      attributes => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
  },
};

for my $test_id (sort {$a cmp $b} keys %$tests) {
  my $test_def = $tests->{$test_id};
  my $node = $test_def->{node}->();

  for (@$constants) {
    my $const_name = $_->[0];
    ok $node->can ($const_name) ? 1 : 0, 1, "$test_id->can ($const_name)";
    ok $node->$const_name, $_->[1], "$test_id.$const_name";
  }

  for my $attr_name (sort {$a cmp $b} keys %{$test_def->{attr_get}}) {
    my $expected = $test_def->{attr_get}->{$attr_name};
    ok $node->can ($attr_name) ? 1 : 0, 1, "$test_id->can ($attr_name)";
    my $actual = $node->$attr_name;
    ok $actual, $expected, "$test_id.$attr_name.get";
  }
}

## Child node accessors' tests
for my $parent (create_parent_nodes ()) {
  my $node1;
  my $node2;
  my $node3;
  if ($parent->node_type == $parent->DOCUMENT_TYPE_NODE) {
    $node1 = $doc->create_processing_instruction ('pi1', 'data1');
    $node2 = $doc->create_processing_instruction ('pi2', 'data2');
    $node3 = $doc->create_processing_instruction ('pi3', 'data3');
  } elsif ($parent->node_type == $parent->DOCUMENT_NODE) {
    $node1 = $doc->create_comment ('comment1');
    $node2 = $doc->create_comment ('comment2');
    $node3 = $doc->create_comment ('comment3');
  } else {
    $node1 = $doc->create_text_node ('text1');
    $node2 = $doc->create_text_node ('text2');
    $node3 = $doc->create_text_node ('text3');
  }

  $parent->append_child ($node1);
  ok $parent->first_child, $node1, $parent->node_name."->first_child [1]";
  ok $parent->last_child, $node1, $parent->node_name."->last_child [1]";
  ok $node1->next_sibling, undef, $parent->node_name."->next_sibling [1]";
  ok $node1->previous_sibling, undef, $parent->node_name."->previous_sibling [1]";

  $parent->append_child ($node2);
  ok $parent->first_child, $node1, $parent->node_name."->first_child [2]";
  ok $parent->last_child, $node2, $parent->node_name."->last_child [2]";
  ok $node1->next_sibling, $node2, $parent->node_name."1->next_sibling [2]";
  ok $node1->previous_sibling, undef, $parent->node_name."1->previous_sibling [2]";
  ok $node2->next_sibling, undef, $parent->node_name."2->next_sibling [2]";
  ok $node2->previous_sibling, $node1, $parent->node_name."2->previous_sibling [2]";

  $parent->append_child ($node3);
  ok $parent->first_child, $node1, $parent->node_name."->first_child [3]";
  ok $parent->last_child, $node3, $parent->node_name."->last_child [3]";
  ok $node1->next_sibling, $node2, $parent->node_name."1->next_sibling [3]";
  ok $node1->previous_sibling, undef, $parent->node_name."1->previous_sibling [3]";
  ok $node2->next_sibling, $node3, $parent->node_name."2->next_sibling [3]";
  ok $node2->previous_sibling, $node1, $parent->node_name."2->previous_sibling [3]";
  ok $node3->next_sibling, undef, $parent->node_name."3->next_sibling [3]";
  ok $node3->previous_sibling, $node2, $parent->node_name."3->previous_sibling [3]";
}

## TODO: parent_node tests, as with append_child tests

sub create_nodes () {
  (
   $doc->create_attribute ('attr1'),
   $doc->create_attribute_definition ('at1'),
   $doc->create_cdata_section ('cdata1'),
   $doc->create_comment ('comment1'),
   $doc->create_element ('element1'),
   $doc->create_element_type_definition ('et1'),
   $doc->create_general_entity ('entity1'),
   $doc->create_entity_reference ('entity-reference1'),
   $doc->implementation->create_document,
   $doc->create_document_fragment,
   $doc->create_document_type_definition ('dt1'),
   $doc->create_notation ('notation1'),
   $doc->create_processing_instruction ('pi1', 'pi1data'),
   $doc->create_text_node ('text1'),
  );
} # create_nodes

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

## License: Public Domain.
## $Date: 2007/06/15 16:12:28 $
