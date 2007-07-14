#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 5086 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;


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

sub create_leaf_nodes () {
  (
   $doc->create_cdata_section ('cdata1'),
   $doc->create_comment ('comment1'),
   $doc->create_notation ('notation1'),
   $doc->create_processing_instruction ('pi1', 'pi1data'),
   $doc->create_text_node ('text1'),
  );
} # create_leaf_nodes

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

  [DOCUMENT_POSITION_DISCONNECTED => 0x01],
  [DOCUMENT_POSITION_PRECEDING => 0x02],
  [DOCUMENT_POSITION_FOLLOWING => 0x04],
  [DOCUMENT_POSITION_CONTAINS => 0x08],
  [DOCUMENT_POSITION_CONTAINED_BY => 0x10],
  [DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC => 0x20],

  [NODE_CLONED => 1],
  [NODE_IMPORTED => 2],
  [NODE_DELETED => 3],
  [NODE_RENAMED => 4],
  [NODE_ADOPTED => 5],
];

my $tests = {
  attr1 => {
    node => sub { return $doc->create_attribute ('a') },
    attr_get => {
      manakai_attribute_type => 0,
      base_uri => undef,
      manakai_expanded_uri => 'a',
      first_child => undef,
      last_child => undef,
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
      node_type => 2,
      name => 'a',
      node_value => '',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      value => '',
      attributes => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_id => 0,
      manakai_read_only => 0,
      specified => 1,
    },
  },
  attr2 => {
    node => sub {
      my $attr = $doc->create_attribute ('a');
      $attr->value ('b');
      return $attr;
    },
    attr_get => {
      manakai_attribute_type => 0,
      base_uri => undef,
      manakai_expanded_uri => 'a',
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
      node_type => 2,
      name => 'a',
      node_value => 'b',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      value => 'b',
      attributes => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 1,
      is_id => 0,
      manakai_read_only => 0,
      specified => 1,
    },
  },
  attr_ns_default => {
    node => sub { return $doc->create_attribute_ns (undef, 'a') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => 'a',
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
      node_type => 2,
      name => 'a',
      node_value => '',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      value => '',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_id => 0,
      manakai_read_only => 0,
      specified => 1,
    },
  },
  attr_ns_prefixed => {
    node => sub { return $doc->create_attribute_ns ('http://test/', 'a:b') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => 'http://test/b',
      local_name => 'b',
      manakai_local_name => 'b',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'a:b',
      node_type => 2,
      name => 'a:b',
      node_value => '',
      owner_document => $doc,
      parent_node => undef,
      prefix => 'a',
      value => '',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_id => 0,
      manakai_read_only => 0,
      specified => 1,
    },
  },
  attr_ns_prefixed_array => {
    node => sub { $doc->create_attribute_ns ('http://test/', ['a', 'b']) },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => 'http://test/b',
      local_name => 'b',
      manakai_local_name => 'b',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'a:b',
      node_type => 2,
      name => 'a:b',
      node_value => '',
      owner_document => $doc,
      parent_node => undef,
      prefix => 'a',
      value => '',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_id => 0,
      manakai_read_only => 0,
      specified => 1,
    },
  },
  cdatasection => {
    node => sub { return $doc->create_cdata_section ('cdatadata') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#cdata-section',
      node_type => 4,
      node_value => 'cdatadata',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'cdatadata',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_element_content_whitespace => 0,
      manakai_read_only => 0,
    },
  },
  cdatasectionmde => {
    node => sub { return $doc->create_cdata_section ('cdata]]>data') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#cdata-section',
      node_type => 4,
      node_value => 'cdata]]>data',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'cdata]]>data',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_element_content_whitespace => 0,
      manakai_read_only => 0,
    },
  },
  comment => {
    node => sub { return $doc->create_comment ('commentdata') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#comment',
      node_type => 8,
      node_value => 'commentdata',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'commentdata',
      attributes => undef,
      previous_sibling => undef,
    }, 
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  commentcom1 => {
    node => sub { return $doc->create_comment ('comment--data') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#comment',
      node_type => 8,
      node_value => 'comment--data',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'comment--data',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  commentcom2 => {
    node => sub { return $doc->create_comment ('commentdata-') },
    attr_get => {
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#comment',
      node_type => 8,
      node_value => 'commentdata-',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      data => 'commentdata-',
      attributes => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  document => {
    node => sub { return $doc },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      document_uri => undef,
      manakai_entity_base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      implementation => $dom,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#document',
      node_type => 9,
      node_value => undef,
      owner_document => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      xml_encoding => undef,
      xml_version => '1.0',
    },
    attr_get_bool => {
      all_declarations_processed => 0,
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_is_html => 0,
      manakai_read_only => 0,
      strict_error_checking => 1,
      xml_standalone => 0,
    },
  },
  document_fragment => {
    node => sub { return $doc->create_document_fragment },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#document-fragment',
      node_type => 11,
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  document_type => {
    node => sub {
      return $doc->implementation->create_document_type ('n', '', '');
    },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      declaration_base_uri => undef,
      manakai_declaration_base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      implementation => $dom,
      internal_subset => '',
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'n',
      node_type => 10,
      node_value => undef,
      owner_document => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      public_id => '',
      system_id => '',
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 1,
    },
  },
  document_type_definition => {
    node => sub { return $doc->create_document_type_definition ('n') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      declaration_base_uri => undef,
      manakai_declaration_base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      implementation => $dom,
      internal_subset => '',
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'n',
      node_type => 10,
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      public_id => '',
      system_id => '',
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  element => {
    node => sub { return $doc->create_element ('e') },
    attr_get => {
      base_uri => undef,
      manakai_base_uri => undef,
      manakai_expanded_uri => 'e',
      first_child => undef,
      last_child => undef,
      local_name => 'e',
      manakai_local_name => 'e',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_type => 1,
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      tag_name => 'e',
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  element_ns_default => {
    node => sub { return $doc->create_element_ns ('http://test/', 'f') },
    attr_get => {
      base_uri => undef,
      manakai_base_uri => undef,
      manakai_expanded_uri => 'http://test/f',
      first_child => undef,
      last_child => undef,
      local_name => 'f',
      manakai_local_name => 'f',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'f',
      node_type => 1,
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      tag_name => 'f',
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  element_ns_prefiexed => {
    node => sub { return $doc->create_element_ns ('http://test/', 'e:f') },
    attr_get => {
      base_uri => undef,
      manakai_base_uri => undef,
      manakai_expanded_uri => 'http://test/f',
      first_child => undef,
      last_child => undef,
      local_name => 'f',
      manakai_local_name => 'f',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'e:f',
      node_type => 1,
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => 'e',
      previous_sibling => undef,
      tag_name => 'e:f',
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  entity => {
    node => sub { return $doc->create_general_entity ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_declaration_base_uri => undef,
      manakai_entity_base_uri => undef,
      manakai_entity_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      next_sibling => undef,
      node_name => 'e',
      node_type => 6,
      node_value => undef,
      notation_name => undef,
      owner_document => $doc,
      owner_document_type_definition => undef,
      parent_node => undef,
      previous_sibling => undef,
      public_id => undef,
      system_id => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  entity_reference => {
    node => sub { return $doc->create_entity_reference ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_entity_base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_type => 5,
      node_value => undef,
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      manakai_expanded => 0,
      manakai_external => 0,
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 1,
    },
  },
  notation => {
    node => sub { return $doc->create_notation ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_declaration_base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_type => 12,
      node_value => undef,
      owner_document => $doc,
      owner_document_type_definition => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      public_id => undef,
      system_id => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  processing_instruction => {
    node => sub { return $doc->create_processing_instruction ('t', 'd') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 't',
      node_type => 7,
      node_value => 'd',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  text => {
    node => sub { return $doc->create_text_node ('textdata') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => '#text',
      node_type => 3,
      node_value => 'textdata',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      is_element_content_whitespace => 0,
      manakai_read_only => 0,
    },
  },
  element_type_definition => {
    node => sub { return $doc->create_element_type_definition ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_type => 81001,
      node_value => undef,
      owner_document => $doc,
      owner_document_type_definition => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
    },
  },
  attribute_definition => {
    node => sub { return $doc->create_attribute_definition ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      declared_type => 0,
      default_type => 0,
      manakai_expanded_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => undef,
      manakai_local_name => undef,
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'e',
      node_type => 81002,
      node_value => '',
      owner_document => $doc,
      owner_element_type_definition => undef,
      parent_node => undef,
      prefix => undef,
      previous_sibling => undef,
      text_content => '',
    },
    attr_get_bool => {
      has_attributes => 0,
      has_child_nodes => 0,
      manakai_read_only => 0,
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

  for my $attr_name (sort {$a cmp $b} keys %{$test_def->{attr_get_bool} or {}}) {
    my $expected = $test_def->{attr_get_bool}->{$attr_name} ? 1 : 0;
    ok $node->can ($attr_name) ? 1 : 0, 1, "$test_id->can ($attr_name)";
    my $actual = $node->$attr_name ? 1 : 0;
    ok $actual, $expected, "$test_id.$attr_name.get";
  }
}

## Child node accessors' tests
for my $parent (create_parent_nodes ()) {
  my $doc = $parent->owner_document || $parent;
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

  $parent->manakai_set_read_only (0, 1);
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

## |prefix| setter
for my $node (create_nodes ()) {
  $node->manakai_set_read_only (0);

  $node->prefix ('non-null');
  if ($node->node_type == $node->ELEMENT_NODE or
      $node->node_type == $node->ATTRIBUTE_NODE) {
    ok $node->prefix, 'non-null', $node->node_name . '->prefix (non-null)';
  } else {
    ok $node->prefix, undef, $node->node_name . '->prefix (non-null)';
  }

  $node->prefix (undef);
  if ($node->node_type == $node->ELEMENT_NODE or
      $node->node_type == $node->ATTRIBUTE_NODE) {
    ok $node->prefix, undef, $node->node_name . '->prefix (null)';
  } else {
    ok $node->prefix, undef, $node->node_name . '->prefix (null)';
  }

  $node->manakai_set_read_only (1);
  my $err_type;
  try {
    $node->prefix ('non-null');
  } catch Message::IF::DOMException with {
    my $err = shift;
    $err_type = $err->type;
  };
  if ($node->node_type == $node->ELEMENT_NODE or
      $node->node_type == $node->ATTRIBUTE_NODE) {
    ok $err_type, 'NO_MODIFICATION_ALLOWED_ERR',
        $node->node_name . '->prefix exception (read-only)';
    ok $node->prefix, undef, $node->node_name . '->prefix (read-only)';
  } else {
    ok $err_type, undef, $node->node_name . '->prefix exception (read-only)';
    ok $node->prefix, undef, $node->node_name . '->prefix (read-only)';
  }
}

## |text_content|
{
  my $doc2 = $doc->implementation->create_document;
  $doc2->dom_config->set_parameter
      ('http://suika.fam.cx/www/2006/dom-config/strict-document-children' => 1);
  for my $node (
                $doc2,
                $doc->create_document_type_definition ('dt1'),
                $doc->implementation->create_document_type ('doctype1'),
                $doc->create_notation ('notation1'),
                $doc->create_element_type_definition ('et1'),
               ) {
    ok $node->can ('text_content') ? 1 : 0, 1,
        $node->node_name . '->can text_content';

    ok $node->text_content, undef, $node->node_name . '->text_content';

    $node->manakai_set_read_only (0);
    $node->text_content ('new-text-content');
    ok $node->text_content, undef, $node->node_name . '->text_content set';

    $node->manakai_set_read_only (1);
    $node->text_content ('new-text-content');
    ok $node->text_content, undef,
        $node->node_name . '->text_content set (read-only)';
  }

  $doc2->dom_config->set_parameter
      ('http://suika.fam.cx/www/2006/dom-config/strict-document-children' => 0);
  for my $node (
                $doc2,
                $doc->create_attribute ('attr1'),
                $doc->create_attribute_definition ('at1'),
                $doc->create_element ('element1'),
                $doc->create_general_entity ('entity1'),
                $doc->create_entity_reference ('entity-reference1'),
                $doc->create_document_fragment,
               ) {
    ok $node->can ('text_content') ? 1 : 0, 1,
        $node->node_name . '->can text_content';

    ok $node->text_content, '', $node->node_name . '->text_content';

    $node->manakai_set_read_only (0);
    $node->text_content ('text1');
    ok $node->text_content, 'text1', $node->node_name . '->text_content set';
    ok 0+@{$node->child_nodes}, 1,
        $node->node_name . '->text_content set child_nodes length';

    $node->text_content ('');
    ok $node->text_content, '', $node->node_name . '->text_content set empty';
    ok 0+@{$node->child_nodes}, 0,
        $node->node_name . '->text_content set empty child_nodes length';

    $node->text_content ('text2');
    $node->text_content ('');
    ok $node->text_content, '', $node->node_name . '->text_content set empty';
    ok 0+@{$node->child_nodes}, 0,
        $node->node_name . '->text_content set empty child_nodes length';

    $node->text_content ('text3');
    $node->manakai_set_read_only (1);
    try {
      $node->text_content ('new-text-content');
      ok undef, 'NO_MODIFICATION_ALLOWED_ERR', 
          $node->node_name . '->text_content set (read-only)';
    } catch Message::IF::DOMException with {
      my $err = shift;
      ok $err->type, 'NO_MODIFICATION_ALLOWED_ERR', 
          $node->node_name . '->text_content set (read-only)';
    };
    ok $node->text_content, 'text3',
        $node->node_name . '->text_content set (read-only) text_content';
  }


  for (0..2) {
    my $el;
    my $ce;

    [
     sub {
       $el = $doc->create_element ('nestingElement');
       $ce = $doc->create_element ('el2');
     },
     sub {
       $el = $doc->create_element ('elementWithEntityReference');
       $ce = $doc->create_entity_reference ('ent');
       $ce->manakai_set_read_only (0, 1);
     },
     sub {
       $el = $doc->create_general_entity ('generalEntityWithChild');
       $ce = $doc->create_element ('el');
       $el->manakai_set_read_only (0, 1);
     },
    ]->[$_]->();
    $el->append_child ($ce);

    ok $el->text_content, '', $el->node_name . '->text_content [1]';

    $ce->text_content ('gc');
    ok $el->text_content, 'gc', $el->node_name . '->text_content [2]';

    $el->manakai_append_text ('cc');
    ok $el->text_content, 'gccc', $el->node_name . '->text_content [3]';

    $el->text_content ('nc');
    ok $el->text_content, 'nc', $el->node_name . '->text_content [4]';
    ok 0+@{$el->child_nodes}, 1,
        $el->node_name . '->text_content child_nodes length [4]';
    ok $ce->parent_node, undef,
        $el->node_name . '->text_content old_child parent_node [4]';
  }
}

## |manakaiReadOnly| and |manakaiSetReadOnly|
{
  for my $node (create_nodes ()) {
    $node->manakai_set_read_only (1, 0);
    ok $node->manakai_read_only ? 1 : 0, 1, 
        $node->node_name . '->manakai_set_read_only (1, 0) [1]';

    $node->manakai_set_read_only (0, 0);
    ok $node->manakai_read_only ? 1 : 0, 0, 
        $node->node_name . '->manakai_set_read_only (0, 0)';

    $node->manakai_set_read_only (1, 0);
    ok $node->manakai_read_only ? 1 : 0, 1,
        $node->node_name . '->manakai_set_read_only (1, 0) [2]';
  }

  {
    my $el = $doc->create_element ('readOnlyElement1');
    my $c1 = $doc->create_element ('c1');
    $el->append_child ($c1);
    my $c2 = $doc->create_text_node ('c2');
    $el->append_child ($c2);
    my $c3 = $doc->create_element ('c3');
    $el->append_child ($c3);
    my $c4 = $doc->create_attribute ('c4');
    $el->set_attribute_node ($c4);
    my $c5 = $doc->create_entity_reference ('c5');
    $el->append_child ($c5);
    
    $el->manakai_set_read_only (1, 1);
    for ($c1, $c2, $c3, $c4, $c5) {
      ok $_->manakai_read_only ? 1 : 0, 1,
          $el->node_name . '->read_only (1, 1) ' . $_->node_name . ' [1]';
    }
    
    $el->manakai_set_read_only (0, 1);
    for ($c1, $c2, $c3, $c4, $c5) {
      ok $_->manakai_read_only ? 1 : 0, 0,
          $el->node_name . '->read_only (1, 0) ' . $_->node_name;
    }
    
    $el->manakai_set_read_only (1, 1);
    for ($c1, $c2, $c3, $c4, $c5) {
      ok $_->manakai_read_only ? 1 : 0, 1,
          $el->node_name . '->read_only (1, 1) ' . $_->node_name . ' [2]';
    }
  }

  {
    my $dtd = $doc->create_document_type_definition ('readOnlyDTDef1');
    my $c1 = $doc->create_processing_instruction ('c1', '');
    $dtd->append_child ($c1);
    my $c2 = $doc->create_element_type_definition ('c2');
    $dtd->set_element_type_definition_node ($c2);
    my $c3 = $doc->create_general_entity ('c3');
    $dtd->set_general_entity_node ($c3);
    my $c4 = $doc->create_notation ('c4');
    $dtd->set_notation_node ($c4);
    my $c5 = $doc->create_text_node ('c5');
    $c3->append_child ($c5);

    $dtd->manakai_set_read_only (1, 1);
    for ($c1, $c2, $c3, $c4, $c5) {
      ok $_->manakai_read_only ? 1 : 0, 1,
          $dtd->node_name . '->read_only (1, 1) ' . $_->node_name . ' [1]';
    }
    
    $dtd->manakai_set_read_only (0, 1);
    for ($c1, $c2, $c3, $c4, $c5) {
      ok $_->manakai_read_only ? 1 : 0, 0,
          $dtd->node_name . '->read_only (1, 0) ' . $_->node_name;
    }
    
    $dtd->manakai_set_read_only (1, 1);
    for ($c1, $c2, $c3, $c4, $c5) {
      ok $_->manakai_read_only ? 1 : 0, 1,
          $dtd->node_name . '->read_only (1, 1) ' . $_->node_name . ' [2]';
    }
  }

  {
    my $et = $doc->create_element_type_definition ('readOnlyETDef1');
    my $c1 = $doc->create_element ('c1');
    $et->set_attribute_definition_node ($c1);
    my $c2 = $doc->create_text_node ('c2');
    $c1->append_child ($c2);

    $et->manakai_set_read_only (1, 1);
    for ($c1, $c2) {
      ok $_->manakai_read_only ? 1 : 0, 1,
          $et->node_name . '->read_only (1, 1) ' . $_->node_name . ' [1]';
    }
    
    $et->manakai_set_read_only (0, 1);
    for ($c1, $c2) {
      ok $_->manakai_read_only ? 1 : 0, 0,
          $et->node_name . '->read_only (1, 0) ' . $_->node_name;
    }
    
    $et->manakai_set_read_only (1, 1);
    for ($c1, $c2) {
      ok $_->manakai_read_only ? 1 : 0, 1,
          $et->node_name . '->read_only (1, 1) ' . $_->node_name . ' [2]';
    }
  }
}

## |manakaiAppendText|
{
  my $doc2 = $doc->implementation->create_document;

  $doc2->dom_config->set_parameter
      ('http://suika.fam.cx/www/2006/dom-config/strict-document-children' => 1);
  for my $node (
                $doc2,
                $doc->create_notation ('Notation_manakaiAppendText'),
                $doc->create_document_type_definition ('DT_manakaiAppendText'),
                $doc->create_element_type_definition ('ET_manakaiAppendText'),
               ) {
    ok $node->can ('manakai_append_text') ? 1 : 0, 1, $node->node_name . 'can';

    $node->manakai_append_text ('aaaa');
    ok $node->text_content, undef, $node->node_name . ' [1]';
    ok 0+@{$node->child_nodes}, 0, $node->node_name . ' childNodes @{} 0+ [1]';
  }

  $doc2->dom_config->set_parameter
      ('http://suika.fam.cx/www/2006/dom-config/strict-document-children' => 0);
  for my $node (
                $doc->create_attribute ('Attr_manakaiAppendText'),
                $doc->create_element ('Element_manakaiAppendText'),
                $doc2,
                $doc->create_document_fragment,
                $doc->create_general_entity ('Entity_manakaiAppendText'),
                $doc->create_entity_reference ('ER_manakaiAppendText'),
                $doc->create_attribute_definition ('AT_manakaiAppendText'),
               ) {
    $node->manakai_set_read_only (0, 1);
    ok $node->can ('manakai_append_text') ? 1 : 0, 1, $node->node_name . 'can';

    $node->manakai_append_text ('string');
    ok $node->text_content, 'string', $node->node_name . ' [1]';
    ok 0+@{$node->child_nodes}, 1, $node->node_name . ' childNodes @{} 0+ [1]';

    $node->manakai_append_text ('STRING');
    ok $node->text_content, 'stringSTRING', $node->node_name . ' [2]';
    ok 0+@{$node->child_nodes}, 1, $node->node_name . ' childNodes @{} 0+ [2]';

    my $er = ($node->owner_document || $node)->create_entity_reference ('er');
    $node->append_child ($er);

    $node->manakai_append_text ('text');
    ok $node->text_content, 'stringSTRINGtext', $node->node_name . ' [3]';
    ok 0+@{$node->child_nodes}, 3, $node->node_name . ' childNodes @{} 0+ [3]';
  }

  for my $node (
                $doc->create_text_node (''),
                $doc->create_cdata_section (''),
                $doc->create_comment (''),
                $doc->create_processing_instruction ('PI_manakaiAppendText'),
               ) {
    ok $node->can ('manakai_append_text') ? 1 : 0, 1, $node->node_name . 'can';

    $node->manakai_append_text ('aaaa');
    ok $node->text_content, 'aaaa', $node->node_name . ' [1]';
    ok 0+@{$node->child_nodes}, 0, $node->node_name . ' childNodes @{} 0+ [1]';

    $node->manakai_append_text ('bbbb');
    ok $node->text_content, 'aaaabbbb', $node->node_name . ' [1]';
    ok 0+@{$node->child_nodes}, 0, $node->node_name . ' childNodes @{} 0+ [1]';
  }
}

## |baseURI|
{
  my $doc2 = $doc->implementation->create_document;

  $doc2->document_uri (q<ftp://suika.fam.cx/>);
  ok $doc2->base_uri, q<ftp://suika.fam.cx/>, 'Document->base_uri [1]';

  $doc2->document_uri (undef);
  ok $doc2->base_uri, undef, 'Document->base_uri [2]';
  ok $doc2->manakai_entity_base_uri, undef, 'Document->base_uri ebu [2]';

  $doc2->manakai_entity_base_uri (q<https://suika.fam.cx/>);
  ok $doc2->base_uri, q<https://suika.fam.cx/>, 'Document->base_uri [3]';
  ok $doc2->manakai_entity_base_uri, q<https://suika.fam.cx/>,
      'Document->base_uri ebu [3]';

  $doc2->manakai_entity_base_uri (undef);
  ok $doc2->base_uri, undef, 'Document->base_uri [4]';
  ok $doc2->manakai_entity_base_uri, undef, 'Document->base_uri ebu [4]';

  $doc2->document_uri (q<ftp://suika.fam.cx/>);
  $doc2->manakai_entity_base_uri (q<https://suika.fam.cx/>);
  ok $doc2->base_uri, q<https://suika.fam.cx/>, 'Document->base_uri [5]';
  ok $doc2->manakai_entity_base_uri, q<https://suika.fam.cx/>,
      'Document->base_uri ebu [5]';
}

for my $method (qw/
                create_document_fragment
                create_element_type_definition
                create_attribute_definition
                /) {
  my $doc2 = $doc->implementation->create_document;  

  my $node = $doc2->$method ('a');

  $doc2->document_uri (q<ftp://doc.test/>);
  ok $node->base_uri, q<ftp://doc.test/>, $node->node_name . '->base_uri [1]';

  $doc2->manakai_entity_base_uri (q<ftp://suika.fam.cx/>);
  ok $node->base_uri, q<ftp://suika.fam.cx/>,
      $node->node_name . '->base_uri [2]';
}

{
  my $doc2 = $doc->implementation->create_document;

  my $attr = $doc2->create_attribute_ns (undef, 'attr');
  
  $doc2->document_uri (q<http://www.example.com/>);
  ok $attr->base_uri, q<http://www.example.com/>, 'Attr->base_uri [1]';

  my $el = $doc2->create_element_ns (undef, 'element');
  $el->set_attribute_ns ('http://www.w3.org/XML/1998/namespace',
                         'xml:base' => q<http://www.example.org/>);
  $el->set_attribute_node_ns ($attr);
  ok $attr->base_uri, q<http://www.example.org/>, 'Attr->base_uri [2]';
}

for my $i (0..1) {
  my $xb = [
            ['http://www.w3.org/XML/1998/namespace', 'xml:base'],
            [undef, [undef, 'xml:base']],
           ]->[$i];

  my $doc2 = $doc->implementation->create_document;
  $doc2->strict_error_checking (0);

  my $attr = $doc2->create_attribute_ns (@$xb);
  $attr->value (q<http://attr.test/>);

  ok $attr->base_uri, undef, 'xml:base->base_uri [0]' . $i;

  $doc2->document_uri (q<http://doc.test/>);
  ok $attr->base_uri, q<http://doc.test/>, 'xml:base->base_uri [1]' . $i;

  my $el = $doc2->create_element_ns (undef, 'e');
  $el->set_attribute_node_ns ($attr);
  ok $attr->base_uri, q<http://doc.test/>, 'xml:base->base_uri [2]' . $i;

  my $pel = $doc2->create_element_ns (undef, 'e');
  $pel->set_attribute_ns (@$xb, q<http://pel.test/>);
  $pel->append_child ($el);
  ok $attr->base_uri, q<http://pel.test/>, 'xml:base->base_uri [3]' . $i;
}

for my $i (0..1) {
  my $xb = [
            ['http://www.w3.org/XML/1998/namespace', 'xml:base'],
            [undef, [undef, 'xml:base']],
           ]->[$i];

  my $doc2 = $doc->implementation->create_document;
  $doc2->strict_error_checking (0);
  
  my $el = $doc2->create_element_ns (undef, 'el');

  ok $el->base_uri, undef, "Element->base_uri [0]";
  ok $el->manakai_base_uri, undef, "Element->manakai_base_uri [0]";

  $doc2->document_uri (q<http://foo.example/>);
  ok $el->base_uri, q<http://foo.example/>, "Element->base_uri [1]";
  ok $el->manakai_base_uri, undef, "Element->manakai_base_uri [1]";

  $el->set_attribute_ns (@$xb => q<http://www.example.com/>);
  ok $el->base_uri, q<http://www.example.com/>, "Element->base_uri [2]";
  ok $el->manakai_base_uri, undef, "Element->manakai_base_uri [2]";

  $el->set_attribute_ns (@$xb => q<bar>);
  ok $el->base_uri, q<http://foo.example/bar>, "Element->base_uri [3]";
  ok $el->manakai_base_uri, undef, "Element->manakai_base_uri [3]";

  $el->manakai_base_uri (q<http://baz.example/>);
  ok $el->base_uri, q<http://baz.example/>, "Element->base_uri [4]";
  ok $el->manakai_base_uri, q<http://baz.example/>,
      "Element->manakai_base_uri [4]";

  $el->manakai_base_uri (undef);
  ok $el->base_uri, q<http://foo.example/bar>, "Element->base_uri [5]";
  ok $el->manakai_base_uri, undef, "Element->manakai_base_uri [5]";
}

{
  my $doc2 = $doc->implementation->create_document;
  
  my $el = $doc2->create_element_ns (undef, 'el');

  ok $el->base_uri, undef, "Element->base_uri [6]";

  $doc2->document_uri (q<http://doc.test/>);
  ok $el->base_uri, q<http://doc.test/>, "Element->base_uri [7]";

  my $el0 = $doc2->create_element_ns (undef, 'e');
  $el0->set_attribute_ns ('http://www.w3.org/XML/1998/namespace', 'xml:base',
                          q<http://el.test/>);
  $el0->append_child ($el);
  ok $el->base_uri, q<http://el.test/>, "Element->base_uri [8]";

  my $ent = $doc2->create_entity_reference ('ent');
  $ent->manakai_set_read_only (0, 1);
  $ent->manakai_external (1);
  $ent->manakai_entity_base_uri (q<http://ent.test/>);
  $el0->append_child ($ent);
  $ent->append_child ($el);
  ok $el->base_uri, q<http://ent.test/>, "Element->base_uri [9]";
}

for (qw/create_text_node create_cdata_section create_comment/) {
  my $doc2 = $doc->implementation->create_document;
  my $node = $doc2->$_ ('');

  $doc2->document_uri (q<http://doc.test/>);
  ok $node->base_uri, q<http://doc.test/>, $node->node_name . "->base_uri [0]";

  my $el = $doc2->create_element_ns (undef, 'e');
  $el->set_attribute_ns ('http://www.w3.org/XML/1998/namespace', 'xml:base',
                         q<http://el.test/>);
  $el->append_child ($node);
  ok $node->base_uri, q<http://el.test/>, $node->node_name . "->base_uri [1]";

  my $ent = $doc2->create_entity_reference ('ent');
  $ent->manakai_set_read_only (0, 1);
  $ent->manakai_external (1);
  $ent->manakai_entity_base_uri (q<http://ent.test/>);
  $el->append_child ($ent);
  $ent->append_child ($node);
  ok $node->base_uri, q<http://ent.test/>, $node->node_name . "->base_uri [2]";
}

{
  my $doc2 = $doc->implementation->create_document;
  my $ent = $doc2->create_general_entity ('ent');

  $doc2->document_uri (q<http://base.example/>);
  ok $ent->base_uri, q<http://base.example/>, "Entity->base_uri [1]";
  
  $ent->manakai_entity_base_uri (q<http://www.example.com/>);
  ok $ent->base_uri, q<http://base.example/>, "Entity->base_uri [2]";

  $ent->manakai_declaration_base_uri (q<http://www.example/>);
  ok $ent->base_uri, q<http://base.example/>, "Entity->base_uri [3]";
}

{
  my $doc2 = $doc->implementation->create_document;

  my $ent = $doc2->create_entity_reference ('ent');
  $ent->manakai_set_read_only (0, 1);

  $doc2->document_uri (q<http://base.example/>);
  ok $ent->base_uri, q<http://base.example/>, "ER->base_uri [1]";

  $ent->manakai_entity_base_uri (q<http://www.example.com/>);
  ok $ent->base_uri, q<http://base.example/>;

  my $el = $doc2->create_element_ns (undef, 'el');
  $el->set_attribute_ns ('http://www.w3.org/XML/1998/namespace', 'xml:base',
                         q<http://el.test/>);
  $el->append_child ($ent);
  ok $ent->base_uri, q<http://el.test/>, "ER->base_uri [2]";

  my $xent = $doc2->create_entity_reference ('ext');
  $xent->manakai_set_read_only (0, 1);
  $xent->manakai_entity_base_uri (q<http://ent.test/>);
  $xent->manakai_external (1);
  $el->append_child ($xent);
  $xent->append_child ($ent);
  ok $ent->base_uri, q<http://ent.test/>, "ER->base_uri [3]";
}

{
  my $doc2 = $doc->implementation->create_document;

  my $pi = $doc2->create_processing_instruction ('i');

  ok $pi->base_uri, undef, "PI->base_uri [0]";
  ok $pi->manakai_base_uri, undef, "PI->manakai_base_uri [0]";

  $doc2->document_uri (q<http://doc.test/>);
  ok $pi->base_uri, q<http://doc.test/>, "PI->base_uri [1]";
  ok $pi->manakai_base_uri, undef, "PI->manakai_base_uri [1]";

  my $el = $doc2->create_element_ns (undef, 'e');
  $el->set_attribute_ns ('http://www.w3.org/XML/1998/namespace', 'xml:base',
                         q<http://el.test/>);
  $el->append_child ($pi);
  ok $pi->base_uri, q<http://el.test/>, "PI->base_uri [2]";
  ok $pi->manakai_base_uri, undef, "PI->manakai_base_uri [2]";

  my $ent = $doc2->create_entity_reference ('ent');
  $ent->manakai_set_read_only (0, 1);
  $ent->manakai_external (1);
  $ent->manakai_entity_base_uri (q<http://ent.test/>);
  $el->append_child ($ent);
  $ent->append_child ($pi);
  ok $pi->base_uri, q<http://ent.test/>, "PI->base_uri [3]";
  ok $pi->manakai_base_uri, undef, "PI->manakai_base_uri [3]";
  
  $pi->manakai_base_uri (q<http://pi.ent/>);
  ok $pi->base_uri, q<http://pi.ent/>, "PI->base_uri [4]";
  ok $pi->manakai_base_uri, q<http://pi.ent/>, "PI->manakai_base_uri [4]";

  $pi->manakai_base_uri (undef);
  ok $pi->base_uri, q<http://ent.test/>, "PI->base_uri [5]";
  ok $pi->manakai_base_uri, undef, "PI->manakai_base_uri [5]";
}

{
  my $doc2 = $doc->implementation->create_document;

  my $pi = $doc2->create_notation ('i');

  $doc2->document_uri (q<http://doc.test/>);
  ok $pi->base_uri, q<http://doc.test/>, "Notation->base_uri [1]";
  
  $pi->manakai_declaration_base_uri (q<http://www.example/>);
  ok $pi->base_uri, q<http://doc.test/>, "Notation->base_uri [2]";
}

{
  my $dt = $doc->implementation->create_document_type ('name');
  ok $dt->base_uri, undef, "DT->base_uri [0]";

  my $doc2 = $doc->implementation->create_document;
  $doc2->append_child ($dt);
  $doc2->document_uri (q<http://doc.test/>);
  ok $dt->owner_document, $doc2;
  ok $dt->base_uri, q<http://doc.test/>, "DT->base_uri [1]";
}

## |hasAttribute|
{
  my $el = $doc->create_element ('e');
  ok $el->has_attributes ? 1 : 0, 0, "Element->has_attributes [0]";

  $el->set_attribute (a => 'b');
  ok $el->has_attributes ? 1 : 0, 1, "Element->has_attributes [1]";

  $el->set_attribute (c => 'd');
  ok $el->has_attributes ? 1 : 0, 1, "Element->has_attributes [2]";

  $el->remove_attribute ('c');
  ok $el->has_attributes ? 1 : 0, 1, "Element->has_attributes [3]";

  $el->get_attribute_node ('a')->specified (0);
  ok $el->has_attributes ? 1 : 0, 1, "Element->has_attributes [4]";

  $el->remove_attribute ('a');
  ok $el->has_attributes ? 1 : 0, 0, "Element->has_attributes [5]";
}

## |hasChildNodes|
{
  my $doc2 = $doc->implementation->create_document;
  
  ok $doc2->has_child_nodes ? 1 : 0, 0, "Document->has_child_nodes [0]";

  $doc2->append_child ($doc2->create_comment (''));
  ok $doc2->has_child_nodes ? 1 : 0, 1, "Document->has_child_nodes [1]";

  $doc2->append_child ($doc2->create_comment (''));
  ok $doc2->has_child_nodes ? 1 : 0, 1, "Document->has_child_nodes [2]";

  $doc2->remove_child ($doc2->first_child);
  ok $doc2->has_child_nodes ? 1 : 0, 1, "Document->has_child_nodes [3]";

  $doc2->remove_child ($doc2->first_child);
  ok $doc2->has_child_nodes ? 1 : 0, 0, "Document->has_child_nodes [4]";
}

## |compareDocumentPosition|
{
  my $e1 = $doc->create_element ('e1');
  my $e2 = $doc->create_element ('e2');
  
  my $dp2 = $e1->compare_document_position ($e2);
  
  ok $dp2 & $e1->DOCUMENT_POSITION_DISCONNECTED ? 1 : 0, 1, "cdp [1]";
  ok $dp2 & $e1->DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC ? 1 : 0, 1, "edp [2]";
  ok (($dp2 & $e1->DOCUMENT_POSITION_PRECEDING ||
       $dp2 & $e1->DOCUMENT_POSITION_FOLLOWING) ? 1 : 0, 1, "cdp [3]");

  my $dp1 = $e2->compare_document_position ($e1);
  
  ok $dp1 & $e1->DOCUMENT_POSITION_DISCONNECTED ? 1 : 0, 1, "cdp [4]";
  ok $dp1 & $e1->DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC ? 1 : 0, 1, "cdp [5]";
  ok (($dp1 & $e1->DOCUMENT_POSITION_PRECEDING ||
       $dp1 & $e1->DOCUMENT_POSITION_FOLLOWING) ? 1 : 0, 1, "cdp [6]");
}

{
  my $e1 = $doc->create_element ('e1');
  my $e2 = $doc->create_element ('e2');

  my $pe = $doc->create_element ('pe');
  $pe->append_child ($e1);
  $pe->append_child ($e2);

  my $dp2 = $e1->compare_document_position ($e2);

  ok $dp2 & $e1->DOCUMENT_POSITION_FOLLOWING ? 1 : 0, 1, "cde [7]";

  my $dp1 = $e2->compare_document_position ($e1);

  ok $dp1 & $e1->DOCUMENT_POSITION_PRECEDING ? 1 : 0, 1, "cde [8]";
}
## TODO: Apparently compare_document_position requires more tests.

## |lookupNamespaceURI|
{
  for my $node (create_nodes ()) {
    ok $node->lookup_namespace_uri ('ns1'), undef, $node->node_name . " lnu [0]";
    ok $node->lookup_namespace_uri ('xml'), undef, $node->node_name . " lnu [1]";
    ok $node->lookup_namespace_uri ('xmlns'), undef, $node->node_name . " lnu [2]";
    ok $node->lookup_namespace_uri (''), undef, $node->node_name . " lnu [3]";
    ok $node->lookup_namespace_uri (undef), undef, $node->node_name . " lnu [4]";
  }

  my $el = $doc->create_element_ns ('about:', 'el');
  ok $el->lookup_namespace_uri ('ns1'), undef, 'Element->lnu [0]';

  $el->prefix ('ns1');
  ok $el->lookup_namespace_uri ('ns1'), 'about:', 'Element->lnu [1]';

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns:ns1', 'DAV:');
  ok $el->lookup_namespace_uri ('ns1'), 'about:', 'Element->lnu [2]';

  $el->prefix (undef);
  ok $el->lookup_namespace_uri ('ns1'), 'DAV:', 'Element->lnu [3]';
}

## |lookupPrefix|
{
  for my $node (create_nodes ()) {
    ok $node->lookup_prefix ('http://test/'), undef, $node->node_name . "lp [0]";
    ok $node->lookup_prefix ('http://www.w3.org/XML/1998/namespace'), undef, $node->node_name . "lp [1]";
    ok $node->lookup_prefix ('http://www.w3.org/2000/xmlns/'), undef, $node->node_name . "lp [2]";
    ok $node->lookup_prefix ('http://www.w3.org/1999/xhtml'), undef, $node->node_name . "lp [3]";
    ok $node->lookup_prefix (''), undef, $node->node_name . "lp [4]";
    ok $node->lookup_prefix (undef), undef, $node->node_name . "lp [5]";
  }

  my $el = $doc->create_element_ns ('http://test/', 'e');
  ok $el->lookup_prefix ('ns'), undef, "Element->lp [0]";;

  my $el2 = $doc->create_element_ns ('http://test/', 'f');
  $el2->append_child ($el);
  $el2->prefix ('ns');
  ok $el->lookup_prefix ('http://test/'), 'ns', "Element->lp [1]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns:a',
                         'http://test/');
  ok $el->lookup_prefix ('http://test/'), 'a', "Element->lp [2]";

  $el->prefix ('b');
  ok $el->lookup_prefix ('http://test/'), 'b', "Element->lp [3]";
}

## |isDefaultNamespace|
{
  for my $node (create_nodes ()) {
    next if $node->node_type == 1;
    ok $node->is_default_namespace ('about:') ? 1 : 0, 0, $node->node_name."idn[0]";
    ok $node->is_default_namespace ('http://www.w3.org/XML/1998/namespace') ? 1 : 0, 0, $node->node_name."idn[2]";
    ok $node->is_default_namespace ('http://www.w3.org/2000/xmlns/') ? 1 : 0, 0, $node->node_name."idn[3]";
    ok $node->is_default_namespace ('') ? 1 : 0, 0, $node->node_name."idn[4]";
    ok $node->is_default_namespace (undef) ? 1 : 0, 0, $node->node_name."idn[5]";
  }
  
  my $el = $doc->create_element_ns ('about:', 'el');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 1, "Element->idn [0]";
  
  $el->prefix ('ns1');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [1]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', 'DAV:');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [2]";
  
  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', 'about:');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 1, "Element->idn [3]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', '');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [4]";
}

{
  my $el = $doc->create_element_ns ('about:', 'p:el');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [5]";
  
  $el->prefix ('ns1');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [6]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', 'DAV:');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [7]";
  
  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', 'about:');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 1, "Element->idn [8]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', '');
  ok $el->is_default_namespace ('about:') ? 1 : 0, 0, "Element->idn [9]";
}

{
  my $el = $doc->create_element ('e');

  ## NOTE: This might look like strange, but it is how it is defined!
  ok $el->is_default_namespace (undef) ? 1 : 0, 0, "Element->idn [10]";
  ok $el->is_default_namespace ('') ? 1 : 0, 0, "Element->idn [11]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', 'DAV:');
  ok $el->is_default_namespace (undef) ? 1 : 0, 0, "Element->idn [12]";
  ok $el->is_default_namespace ('') ? 1 : 0, 0, "Element->idn [13]";

  $el->set_attribute_ns ('http://www.w3.org/2000/xmlns/', 'xmlns', '');
  ok $el->is_default_namespace (undef) ? 1 : 0, 0, "Element->idn [14]";
  ok $el->is_default_namespace ('') ? 1 : 0, 0, "Element->idn [15]";
}

## |manakaiParentElement|
{
  my $el = $doc->create_element ('el');
  ok $el->manakai_parent_element, undef, "mpe [0]";

  my $el2 = $doc->create_element ('el2');
  $el->append_child ($el2);
  ok $el2->manakai_parent_element, $el, "mpe [1]";
  
  my $er1 = $doc->create_entity_reference ('er1');
  $er1->manakai_set_read_only (0, 1);
  $el->append_child ($er1);
  $er1->append_child ($el2);
  ok $el2->manakai_parent_element, $el, "mpe [1]";
}

{
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $el->normalize;
  
  ok $el->text_content, 't1t2', 'normalize [0]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [1]';
}

{
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  my $t3 = $doc->create_text_node ('t3');
  my $t4 = $doc->create_text_node ('t4');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $el->append_child ($t3);
  $el->append_child ($t4);
  $el->normalize;
  
  ok $el->text_content, 't1t2t3t4', 'normalize [2]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [3]';
}

{
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  my $c1 = $doc->create_cdata_section ('c1');
  my $t3 = $doc->create_text_node ('t3');
  my $t4 = $doc->create_text_node ('t4');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $el->append_child ($c1);
  $el->append_child ($t3);
  $el->append_child ($t4);
  $el->normalize;
  
  ok $el->text_content, 't1t2c1t3t4', 'normalize [4]';
  ok 0+@{$el->child_nodes}, 3, 'normalize [5]';
  ok $el->first_child->text_content, 't1t2', 'normalize [6]';
  ok $el->last_child->text_content, 't3t4', 'normalize [7]';
}

{
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $el->normalize;
  
  ok $el->text_content, 't1', 'normalize [8]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [9]';
}

{
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $el->normalize;
  
  ok $el->text_content, 't2', 'normalize [10]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [11]';
}

{
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('');
  $el->append_child ($t1);
  $el->normalize;
  
  ok $el->text_content, '', 'normalize [12]';
  ok 0+@{$el->child_nodes}, 0, 'normalize [13]';
}

{
  my $pe = $doc->create_element ('pe');
  my $el = $doc->create_element ('el');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $pe->append_child ($el);
  $pe->normalize;
  
  ok $el->text_content, 't1t2', 'normalize [14]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [15]';
}

{
  my $pe = $doc->create_element ('pe');
  my $el = $doc->create_attribute ('a');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $pe->set_attribute_node ($el);
  $pe->normalize;
  
  ok $el->text_content, 't1t2', 'normalize [16]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [17]';
}

{
  my $pe = $doc->create_element_type_definition ('pe');
  my $el = $doc->create_attribute_definition ('a');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $pe->set_attribute_definition_node ($el);
  $pe->normalize;
  
  ok $el->text_content, 't1t2', 'normalize [16]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [17]';
}

{
  my $dt = $doc->create_document_type_definition ('dt');
  my $pe = $doc->create_element_type_definition ('pe');
  my $el = $doc->create_attribute_definition ('a');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $pe->set_attribute_definition_node ($el);
  $dt->set_element_type_definition_node ($pe);
  $dt->normalize;
  
  ok $el->text_content, 't1t2', 'normalize [18]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [19]';
}

{
  my $pe = $doc->create_document_type_definition ('pe');
  my $el = $doc->create_general_entity ('a');
  my $t1 = $doc->create_text_node ('t1');
  my $t2 = $doc->create_text_node ('t2');
  $el->append_child ($t1);
  $el->append_child ($t2);
  $pe->set_general_entity_node ($el);
  $pe->normalize;
  
  ok $el->text_content, 't1t2', 'normalize [20]';
  ok 0+@{$el->child_nodes}, 1, 'normalize [21]';
}

## |getFeature| and |isSupported|
for my $node (create_nodes ()) {
  for (
       [Core => '1.0', 1],
       [Core => '2.0', 1],
       [Core => '3.0', 1],
       ['+Core' => '3.0', 1],
       ['++Core' => '3.0', 0],
       [Core => '', 1],
       [Core => undef, 1],
       [Core => 3, 0],
       [Traversal => '2.0', 1], [Traversal => '', 1], [Traversal => '1.0', 0],
       [XML => '1.0', 1],
       [XML => '2.0', 1],
       [XML => '3.0', 1],
       [XML => '', 1],
       [XML => undef, 1],
       ['+XML' => undef, 1],
       [XMLVersion => '1.0', 1],
       [XMLVersion => '1.1', 1],
       [XMLVersion => '', 1],
       [XMLVersion => undef, 1],
       ['+XMLVersion' => undef, 1],
       [unknown => 3, 0],
       [unknown => '', 0],
       [unknown => undef, 0],
       ['+unknown' => undef, 0],
       [q<http://suika.fam.cx/www/2006/feature/xdoctype> => '', 1],
       [q<http://suika.fam.cx/www/2006/feature/xdoctype> => '3.0', 1],
      ) {
    my $label = $node->node_name . ' ' . $_->[0] . ', ' .
        (defined $_->[1] ? $_->[1] : 'undef');
    ok $node->can ('get_feature') ? 1 : 0, 1, 'can get_feature ' . $label;
    ok $node->get_feature ($_->[0], $_->[1]), $_->[2] ? $node : undef,
        'get_feature ' . $label;
    ok $node->can ('is_supported') ? 1 : 0, 1, 'can is_supported ' . $label;
    ok $node->is_supported ($_->[0], $_->[1]) ? 1 : 0, $_->[2],
        'is_supported ' . $label;
  }
}

## |isEqualNode|
for my $node (create_nodes ()) {
  ok $node->can ('is_equal_node') ? 1 : 0, 1, $node->node_name . '->is_eq_n can';

  ok $node->is_equal_node ($node) ? 1 : 0, 1, $node->node_name . '->iseq self';
  ok $node == $node ? 1 : 0, 1, $node->node_name . ' == self';
  ok $node != $node ? 1 : 0, 0, $node->node_name . ' != self';
  ok $node == 'node' ? 1 : 0, 0, $node->node_name . ' == string';
  ok $node != 'node' ? 1 : 0, 1, $node->node_name . ' != string';
  ok $node == 0 ? 1 : 0, 0, $node->node_name . ' == num';
  ok $node != 0 ? 1 : 0, 1, $node->node_name . ' != num';
  ok $node == '' ? 1 : 0, 0, $node->node_name . ' == empty';
  ok $node != '' ? 1 : 0, 1, $node->node_name . ' != empty';
  ok $node == undef () ? 1 : 0, 0, $node->node_name . ' == undef';
  ok $node != undef () ? 1 : 0, 1, $node->node_name . ' != undef';
}

{
  my $el1 = $doc->create_element_ns (undef, 'type');
  my $el2 = $doc->create_element_ns (undef, 'type');
  my $el3 = $doc->create_element_ns (undef, 'TYPE');

  ok $el1 == $el2 ? 1 : 0, 1, 'Element == [1]';
  ok $el1 != $el2 ? 1 : 0, 0, 'Element != [1]';
  ok $el1 == $el3 ? 1 : 0, 0, 'Element == [2]';
  ok $el1 != $el3 ? 1 : 0, 1, 'Element != [2]';

  my $el4 = $doc->create_element_ns ('about:', 'type');
  my $el5 = $doc->create_element_ns ('about:', 'type');
  my $el6 = $doc->create_element_ns ('about:', 'TYPE');
  my $el7 = $doc->create_element_ns ('DAV:', 'type');

  ok $el1 == $el4 ? 1 : 0, 0, 'Element == [3]';
  ok $el1 != $el4 ? 1 : 0, 1, 'Element != [3]';
  ok $el4 == $el5 ? 1 : 0, 1, 'Element == [4]';
  ok $el4 != $el5 ? 1 : 0, 0, 'Element != [4]';
  ok $el4 == $el6 ? 1 : 0, 0, 'Element == [5]';
  ok $el4 != $el6 ? 1 : 0, 1, 'Element != [5]';
  ok $el4 == $el7 ? 1 : 0, 0, 'Element == [6]';
  ok $el4 != $el7 ? 1 : 0, 1, 'Element != [6]';

  $el5->prefix ('prefix');
  ok $el4 == $el5 ? 1 : 0, 0, 'Element == [7]';
  ok $el4 != $el5 ? 1 : 0, 1, 'Element != [7]';
}

## |getUserData|, |setUserData|
{
  my $node = $dom->create_document;

  my $data = ['2'];
  my $handler = sub { 1 };

  ok $node->set_user_data ('key1', $data, $handler), undef,
      'set_user_data [1]';
  
  my $key1_data = $node->get_user_data ('key1');
  ok $key1_data, $data, 'set_user_data [2]';
  ok $key1_data->[0], $data->[0], 'set_user_data [3]';

  my $data2 = ['4'];
  ok $node->set_user_data ('key1', $data2, undef), $data, 'set_user_data [4]';
  ok $node->get_user_data ('key1'), $data2, 'set_user_data [5]';

  $node->set_user_data (key1 => undef, $handler);
  ok $node->get_user_data ('key1'), undef, 'set_user_data [6]';

  $node->set_user_data (key1 => undef, undef);
  ok $node->get_user_data ('key1'), undef, 'set_user_data [7]';
}

## |removeChild|
{
  my $el = $doc->create_element ('p');
  my $c1 = $doc->create_element ('e');
  $el->append_child ($c1);
  my $c2 = $doc->create_element ('f');
  $el->append_child ($c2);
  my $c3 = $doc->create_element ('g');
  $el->append_child ($c3);
  ok $el->can ('remove_child') ? 1 : 0, 1, 'Node->remove_child can [0]';

  my $return = $el->remove_child ($c1);
  ok $return, $c1, 'Node->remove_child return [1]';
  ok $c1->parent_node, undef, 'Node->remove_child parent_node [1]';
  ok $el->first_child, $c2, 'Node->remove_child first_child [1]';
  ok $el->last_child, $c3, 'Node->remove_child last_child [1]';
  ok 0+@{$el->child_nodes}, 2, 'Node->remove_child child_nodes [1]';
}
{
  my $el = $doc->create_element ('p');
  my $c1 = $doc->create_element ('e');
  $el->append_child ($c1);
  my $c2 = $doc->create_element ('f');
  $el->append_child ($c2);
  my $c3 = $doc->create_element ('g');
  $el->append_child ($c3);

  my $return = $el->remove_child ($c2);
  ok $return, $c2, 'Node->remove_child return [2]';
  ok $c2->parent_node, undef, 'Node->remove_child parent_node [2]';
  ok $el->first_child, $c1, 'Node->remove_child first_child [2]';
  ok $el->last_child, $c3, 'Node->remove_child last_child [2]';
  ok 0+@{$el->child_nodes}, 2, 'Node->remove_child child_nodes [2]';
}
{
  my $el = $doc->create_element ('p');
  my $c1 = $doc->create_element ('e');
  $el->append_child ($c1);
  my $c2 = $doc->create_element ('f');
  $el->append_child ($c2);
  my $c3 = $doc->create_element ('g');
  $el->append_child ($c3);

  my $return = $el->remove_child ($c3);
  ok $return, $c3, 'Node->remove_child return [3]';
  ok $c3->parent_node, undef, 'Node->remove_child parent_node [3]';
  ok $el->first_child, $c1, 'Node->remove_child first_child [3]';
  ok $el->last_child, $c2, 'Node->remove_child last_child [3]';
  ok 0+@{$el->child_nodes}, 2, 'Node->remove_child child_nodes [3]';
}
{
  my $el = $doc->create_element ('p');
  my $c1 = $doc->create_element ('e');
  $el->append_child ($c1);

  my $return = $el->remove_child ($c1);
  ok $return, $c1, 'Node->remove_child return [4]';
  ok $c1->parent_node, undef, 'Node->remove_child parent_node [4]';
  ok $el->first_child, undef, 'Node->remove_child first_child [4]';
  ok $el->last_child, undef, 'Node->remove_child last_child [4]';
  ok 0+@{$el->child_nodes}, 0, 'Node->remove_child child_nodes [4]';
}

## |appendChild|, |insertBefore|, |replaceChild|
for my $node (create_leaf_nodes) {
  for my $method_name (qw/append_child insert_before replace_child/) {
    ok $node->can ($method_name) ? 1 : 0, 1,
        $node->node_name . '->can ' . $method_name;

    for my $node2 (create_nodes) {
      try {
        if ($method_name eq 'replace_child') {
          $node->replace_child ($node2, $node2);
        } else {
          $node->$method_name ($node2);
        }
        ok 1, 0,
            $node->node_name . '->' . $method_name . ' ' . $node2->node_name;
      } catch Message::IF::DOMException with {
        if ($_[0]->type eq 'HIERARCHY_REQUEST_ERR' or
            ($_[0]->type eq 'WRONG_DOCUMENT_ERR' and
             ($node2->owner_document or $node2) ne $doc) or
            ($_[0]->type eq 'NOT_FOUND_ERR' and
             $method_name eq 'replace_child')) {
          ok 1, 1,
            $node->node_name . '->' . $method_name . ' ' . $node2->node_name;
        }
      };
    }
  }
}

## TODO: parent_node tests, as with append_child tests

## TODO: text_content tests for CharacterData and PI

## |UserDataHandler|, |setData|, and |NODE_DELETED|
## NOTE: This should be the last test, since it does define
## Node.DESTORY.
{
  my $doc = $dom->create_document ('http://test/', 'ex');
  my $node = $doc->document_element;
  
  $node->set_user_data (key => {}, sub {
    my ($op, $key, $data, $src, $dest) = @_;

    ok $op, 3, 'set_user_data operation [8]'; # NODE_DELETED
    ok $key, 'key', 'set_user_data key [8]';
    ok ref $data, 'HASH', 'set_user_data data [8]';
    ok $src, undef, 'set_user_data src [8]';
    ok $dest, undef, 'set_user_data dest [8]';
  });

  undef $node;
  undef $doc;

  ## NOTE: We cannot control exactly when it is called.
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/14 16:32:28 $
