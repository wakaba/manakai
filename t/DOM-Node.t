#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 1921 } 

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
  attr1 => {
    node => sub { return $doc->create_attribute ('a') },
    attr_get => {
      manakai_attribute_type => 0,
      base_uri => undef,
      first_child => undef,
      last_child => undef,
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
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
    attr_get_bool => {
      specified => 1,
    },
  },
  attr_ns_default => {
    node => sub { return $doc->create_attribute_ns (undef, 'a') },
    attr_get => {
      base_uri => undef,
      local_name => 'a',
      manakai_local_name => 'a',
      namespace_uri => undef,
      next_sibling => undef,
      node_name => 'a',
      name => 'a',
      node_value => '',
      owner_document => $doc,
      parent_node => undef,
      prefix => undef,
      value => '',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  attr_ns_prefixed => {
    node => sub { return $doc->create_attribute_ns ('http://test/', 'a:b') },
    attr_get => {
      base_uri => undef,
      local_name => 'b',
      manakai_local_name => 'b',
      namespace_uri => 'http://test/',
      next_sibling => undef,
      node_name => 'a:b',
      name => 'a:b',
      node_value => '',
      owner_document => $doc,
      parent_node => undef,
      prefix => 'a',
      value => '',
      attributes => undef,
      previous_sibling => undef,
    },
  },
  cdatasection => {
    node => sub { return $doc->create_cdata_section ('cdatadata') },
    attr_get => {
      base_uri => undef,
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
      base_uri => undef,
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
      base_uri => undef,
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
      base_uri => undef,
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
      base_uri => undef,
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
      base_uri => undef,
      document_uri => undef,
      manakai_entity_base_uri => undef,
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
      xml_encoding => undef,
      xml_version => '1.0',
    },
    attr_get_bool => {
      all_declarations_processed => 0,
      manakai_is_html => 0,
      strict_error_checking => 1,
      xml_standalone => 0,
    },
  },
  document_fragment => {
    node => sub { return $doc->create_document_fragment },
    attr_get => {
      attributes => undef,
      base_uri => undef,
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
      base_uri => undef,
      declaration_base_uri => undef,
      manakai_declaration_base_uri => undef,
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
      public_id => undef,
      system_id => undef,
    },
  },
  document_type_definition => {
    node => sub { return $doc->create_document_type_definition ('n') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      declaration_base_uri => undef,
      manakai_declaration_base_uri => undef,
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
      public_id => undef,
      system_id => undef,
    },
  },
  element => {
    node => sub { return $doc->create_element ('e') },
    attr_get => {
      ## TODO: attributes => 
      base_uri => undef,
      manakai_base_uri => undef,
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
      base_uri => undef,
      manakai_base_uri => undef,
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
      base_uri => undef,
      manakai_base_uri => undef,
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
      base_uri => undef,
      manakai_declaration_base_uri => undef,
      manakai_entity_base_uri => undef,
      manakai_entity_uri => undef,
      first_child => undef,
      last_child => undef,
      next_sibling => undef,
      node_name => 'e',
      node_value => undef,
      notation_name => undef,
      owner_document => $doc,
      parent_node => undef,
      previous_sibling => undef,
      public_id => undef,
      system_id => undef,
    },
  },
  entity_reference => {
    node => sub { return $doc->create_entity_reference ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_entity_base_uri => undef,
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
    attr_get_bool => {
      manakai_expanded => 0,
      manakai_external => 0,
    },
  },
  notation => {
    node => sub { return $doc->create_notation ('e') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_declaration_base_uri => undef,
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
      public_id => undef,
      system_id => undef,
    },
  },
  processing_instruction => {
    node => sub { return $doc->create_processing_instruction ('t', 'd') },
    attr_get => {
      attributes => undef,
      base_uri => undef,
      manakai_base_uri => undef,
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
      base_uri => undef,
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
      base_uri => undef,
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
      base_uri => undef,
      declared_type => 0,
      default_type => 0,
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

  for my $attr_name (sort {$a cmp $b} keys %{$test_def->{attr_get_bool} or {}}) {
    my $expected = $test_def->{attr_get_bool}->{$attr_name} ? 1 : 0;
    ok $node->can ($attr_name) ? 1 : 0, 1, "$test_id->can ($attr_name)";
    my $actual = $node->$attr_name ? 1 : 0;
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

    my $er = $doc->create_entity_reference ('er');
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


## TODO: parent_node tests, as with append_child tests

## TODO: text_content tests for CharacterData and PI

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/17 14:15:39 $
