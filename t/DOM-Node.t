#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 4 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

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

## TODO: parent_node tests, as with append_child tests

## TODO: text_content tests for CharacterData and PI

## TODO: manakai_read_only tests

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
## $Date: 2007/06/16 15:27:45 $
