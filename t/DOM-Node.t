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
      node_name => 'a',
      name => 'a',
      node_value => 'b',
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
      node_name => 'a',
      name => 'a',
      node_value => 'b',
      value => 'b',
      attributes => undef,
    },
  },
  attr_ns_prefixed => {
    node => sub {
      my $attr = $doc->create_attribute_ns ('http://test/', 'a:b');
      $attr->value ('c');
      return $attr;
    },
    attr_get => {
      node_name => 'a:b',
      name => 'a:b',
      node_value => 'c',
      value => 'c',
      attributes => undef,
    },
  },
  cdatasection => {
    node => sub { return $doc->create_cdata_section ('cdatadata') },
    attr_get => {
      node_name => '#cdata-section',
      node_value => 'cdatadata',
      data => 'cdatadata',
      attributes => undef,
    },
  },
  cdatasectionmde => {
    node => sub { return $doc->create_cdata_section ('cdata]]>data') },
    attr_get => {
      node_name => '#cdata-section',
      node_value => 'cdata]]>data',
      data => 'cdata]]>data',
      attributes => undef,
    },
  },
  comment => {
    node => sub { return $doc->create_comment ('commentdata') },
    attr_get => {
      node_name => '#comment',
      node_value => 'commentdata',
      data => 'commentdata',
      attributes => undef,
    },
  },
  commentcom1 => {
    node => sub { return $doc->create_comment ('comment--data') },
    attr_get => {
      node_name => '#comment',
      node_value => 'comment--data',
      data => 'comment--data',
      attributes => undef,
    },
  },
  commentcom2 => {
    node => sub { return $doc->create_comment ('commentdata-') },
    attr_get => {
      node_name => '#comment',
      node_value => 'commentdata-',
      data => 'commentdata-',
      attributes => undef,
    },
  },
  document => {
    node => sub { return $doc },
    attr_get => {
      attributes => undef,
      local_name => undef,
      namespace_uri => undef,
      node_name => '#document',
      node_value => undef,
      parent_node => undef,
      prefix => undef,
    },
  },
  document_fragment => {
    node => sub { return $doc->create_document_fragment },
    attr_get => {
      attributes => undef,
      node_name => '#document-fragment',
      node_value => undef,
    },
  },
  document_type => {
    node => sub { return $doc->implementation->create_document_type ('n') },
    attr_get => {
      attributes => undef,
      node_name => 'n',
      node_value => undef,
    },
  },
  document_type_definition => {
    node => sub { return $doc->create_document_type_definition ('n') },
    attr_get => {
      attributes => undef,
      node_name => 'n',
      node_value => undef,
    },
  },
  element => {
    node => sub { return $doc->create_element ('e') },
    attr_get => {
      ## TODO: attributes => 
      node_name => 'e',
      node_value => undef,
    },
  },
  element_ns_default => {
    node => sub { return $doc->create_element_ns ('http://test/', 'f') },
    attr_get => {
      ## TODO: attributes => 
      node_name => 'f',
      node_value => undef,
    },
  },
  element_ns_prefiexed => {
    node => sub { return $doc->create_element_ns ('http://test/', 'e:f') },
    attr_get => {
      ## TODO: attributes => 
      node_name => 'e:f',
      node_value => undef,
    },
  },
  entity => {
    node => sub { return $doc->create_general_entity ('e') },
    attr_get => {
      attributes => undef,
      node_name => 'e',
      node_value => undef,
    },
  },
  entity_reference => {
    node => sub { return $doc->create_entity_reference ('e') },
    attr_get => {
      attributes => undef,
      node_name => 'e',
      node_value => undef,
    },
  },
  notation => {
    node => sub { return $doc->create_notation ('e') },
    attr_get => {
      attributes => undef,
      node_name => 'e',
      node_value => undef,
    },
  },
  processing_instruction => {
    node => sub { return $doc->create_processing_instruction ('t', 'd') },
    attr_get => {
      attributes => undef,
      node_name => 't',
      node_value => 'd',
    },
  },
  text => {
    node => sub { return $doc->create_text_node ('textdata') },
    attr_get => {
      attributes => undef,
      node_name => '#text',
      node_value => 'textdata',
    },
  },
  element_type_definition => {
    node => sub { return $doc->create_element_type_definition ('e') },
    attr_get => {
      attributes => undef,
      node_name => 'e',
      node_value => undef,
    },
  },
  attribute_definition => {
    node => sub { return $doc->create_attribute_definition ('e') },
    attr_get => {
      attributes => undef,
      node_name => 'e',
      node_value => undef,
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

## License: Public Domain.
## $Date: 2007/06/15 14:32:50 $
