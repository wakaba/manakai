package test::Message::DOM::Document;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::More;

require Message::DOM::DOMImplementation;
use Message::Util::Error;

## TODO: |create_document| tests

sub _autoload : Test(4) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  ## AUTOLOAD test
  is $doc->can ('create_element_ns') ? 1 : 0, 1, "can create_element_ns";
  my $el = $doc->create_element_ns (undef, 'test');
  isa_ok $el, 'Message::IF::Element';
  
  is $doc->can ('no_such_method') ? 1 : 0, 0;
  my $something_called = 0;
  eval {
    $doc->no_such_method;
    $something_called = 1;
  };
  is $something_called, 0;
} # _autoload

## NOTE: Tests for |create_*| methods found in |DOM-Node.t|.

sub _implementation : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  my $impl = $doc->implementation;
  is UNIVERSAL::isa ($impl, 'Message::IF::DOMImplementation') ? 1 : 0, 1;
} # _implementation

sub _xml_version : Test(6) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  is $doc->can ('xml_version') ? 1 : 0, 1, 'can xml_version';
  
  is $doc->xml_version, '1.0', 'xml_version initial';
  
  $doc->xml_version ('1.1');
  is $doc->xml_version, '1.1', 'xml_version 1.1';
  
  $doc->xml_version ('1.0');
  is $doc->xml_version, '1.0', 'xml_version 1.0';
  
  try {
    $doc->xml_version ('1.2');
    is undef, 'NOT_SUPPORTED_ERR', 'xml_version 1.2 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    is $err->type, 'NOT_SUPPORTED_ERR', 'xml_version 1.2 exception';
  };
  is $doc->xml_version, '1.0', 'xml_version 1.2';
} # _xml_version

sub _html_xml_version : Test(6) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $html_doc = $doc->implementation->create_document;
  $html_doc->manakai_is_html (1);

  is $html_doc->manakai_is_html ? 1 : 0, 1, 'HTMLDocument->manakai_is_html 1';
  is $html_doc->xml_version, undef, 'HTMLDocument->xml_version';
  
  try {
    $html_doc->xml_version ('1.0');
    is undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_version 1.0 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    is $err->type, 'NOT_SUPPORTED_ERR',
        'HTMLDocument->xml_version 1.0 exception';
  };
  is $html_doc->xml_version, undef, 'HTMLDocument->xml_version 1.0';

  $html_doc->manakai_is_html (0);
  is $html_doc->manakai_is_html ? 1 : 0, 0, 'HTMLDocument->manakai_is_html 0';
  is $html_doc->xml_version, '1.0', '(was HTML) Document->xml_version 1.0';

  $html_doc->manakai_is_html (1);
} # _html_xml_version

sub _xml_encoding : Test(9) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  is $doc->can ('xml_encoding') ? 1 : 0, 1, 'can xml_encoding';

  $doc->xml_encoding ('utf-8');
  is $doc->xml_encoding, 'utf-8', 'xml_encoding legal';

  $doc->xml_encoding ('\abcd');
  is $doc->xml_encoding, '\abcd', 'xml_encoding illegal';

  $doc->xml_encoding (undef);
  is $doc->xml_encoding, undef, 'xml_encoding null';

  my $html_doc = $dom->create_document;
  $html_doc->manakai_is_html (1);
  is $html_doc->xml_encoding, undef, 'HTMLDocument->xml_encoding';
  
  try {
    $html_doc->xml_encoding ('utf-8');
    is undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    is $err->type, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception';
  };
  is $html_doc->xml_encoding, undef, 'HTMLDocument->xml_encoding';
  
  try {
    $html_doc->xml_encoding (undef);
    is undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception 2';
  } catch Message::IF::DOMException with {
    my $err = shift;
    is $err->type, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception 2';
  };
  is $html_doc->xml_encoding, undef, 'HTMLDocument->xml_encoding 2';
} # _xml_encoding

sub _xml_standalone : Test(8) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  is $doc->can ('xml_standalone') ? 1 : 0, 1, 'can xml_standalone';

  $doc->xml_standalone (1);
  is $doc->xml_standalone ? 1 : 0, 1, 'xml_standalone 1';

  $doc->xml_standalone (0);
  is $doc->xml_standalone ? 1 : 0, 0, 'xml_standalone 0';

  my $html_doc = $dom->create_document;
  $html_doc->manakai_is_html (1);
  is $html_doc->xml_standalone ? 1 : 0, 0, 'HTMLDocument->xml_standalone';
  
  try {
    $html_doc->xml_standalone (1);
    is undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_standalone 1 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    is $err->type, 'NOT_SUPPORTED_ERR',
        'HTMLDocument->xml_standalone 1 exception';
  };
  is $html_doc->xml_standalone ? 1 : 0, 0, 'HTMLDocument->xml_standalone 1';
  
  try {
    $html_doc->xml_standalone (0);
    is undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_standalone 0 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    is $err->type, 'NOT_SUPPORTED_ERR',
        'HTMLDocument->xml_standalone 0 exception';
  };
  is $html_doc->xml_standalone ? 1 : 0, 0, 'HTMLDocument->xml_standalone 0';
} # _xml_standalone

sub _strict_error_checking : Test(4) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  is $doc->can ('strict_error_checking') ? 1 : 0, 1, 'can strict_error_checking';

  $doc->strict_error_checking (0);
  is $doc->strict_error_checking ? 1 : 0, 0, 'strict_error_checking 0';

  $doc->strict_error_checking (1);
  is $doc->strict_error_checking ? 1 : 0, 1, 'strict_error_checking 1';

  $doc->strict_error_checking (undef);
  is $doc->strict_error_checking ? 1 : 0, 0, 'strict_error_checking undef';

  $doc->strict_error_checking (1);
} # _strict_error_checking

sub _string_props : Test(18) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  for my $prop (qw/document_uri input_encoding manakai_charset/) {
    is $doc->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
    
    for ('http://absuri.test/', 'reluri', 0, '') {
      $doc->$prop ($_);
      is $doc->$prop, $_, $prop . $_;
    }
    
    $doc->$prop (undef);
    is $doc->$prop, undef, $prop . ' undef';
  }
} # _string_props

sub _bool_props : Test(15) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  for my $prop (qw/
      all_declarations_processed manakai_has_bom manakai_is_srcdoc
  /) {
    is $doc->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
    
    for (1, 0, '') {
      $doc->$prop ($_);
      is $doc->$prop ? 1 : 0, $_ ? 1 : 0, $prop . $_;
    }
    
    $doc->$prop (undef);
    is $doc->$prop ? 1 : 0, 0, $prop . ' undef';
  }
} # _bool_props

sub _html_version : Test(39) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  my $doc2 = $doc->implementation->create_document;
  is $doc2->can ('manakai_is_html') ? 1 : 0, 1, "can manakai_is_html";
  is $doc2->can ('compat_mode') ? 1 : 0, 1, "can compat_mode";
  is $doc2->can ('manakai_compat_mode') ? 1 : 0, 1, "can manakai_compat_mode";
  is $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [0]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [0]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [0]';

  $doc2->manakai_compat_mode ('quirks');
  is $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [1]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [1]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [1]';

  $doc2->manakai_compat_mode ('limited quirks');
  is $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [2]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [2]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [2]';

  $doc2->manakai_compat_mode ('no quirks');
  is $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [3]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [3]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [3]';

  $doc2->manakai_compat_mode ('bogus');
  is $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [4]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [4]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [4]';

  $doc2->manakai_is_html (1);
  is $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [5]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [5]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [5]';

  $doc2->manakai_compat_mode ('quirks');
  is $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [6]";
  is $doc2->compat_mode, 'BackCompat', 'compat_mode [6]';
  is $doc2->manakai_compat_mode, 'quirks', 'manakai_compat_mode [6]';

  $doc2->manakai_compat_mode ('limited quirks');
  is $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [7]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [7]';
  is $doc2->manakai_compat_mode, 'limited quirks', 'manakai_compat_mode [7]';

  $doc2->manakai_compat_mode ('no quirks');
  is $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [8]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [8]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [8]';

  $doc2->manakai_compat_mode ('bogus');
  is $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [9]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [9]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [9]';

  $doc2->manakai_compat_mode ('quirks');
  $doc2->manakai_is_html (0);
  is $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [10]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [10]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [10]';

  $doc2->manakai_is_html (1);
  is $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [11]";
  is $doc2->compat_mode, 'CSS1Compat', 'compat_mode [11]';
  is $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [11]';
} # _html_version

sub _impl : Test(6) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  is $doc->can ('implementation') ? 1 : 0, 1, 'Document->implementation can';
  my $impl = $doc->implementation;
  is UNIVERSAL::isa ($impl, 'Message::DOM::DOMImplementation') ? 1 : 0,
      1, 'Document->implementation class';
  my $impl2 = $doc->implementation;
  is $impl eq $impl2 ? 1 : 0, 1, 'Document->implementation eq D->i';
  is $impl ne $impl2 ? 1 : 0, 0, 'Document->implementation ne D->i';
  is $impl == $impl2 ? 1 : 0, 1, 'Document->implementation == D->i';
  is $impl != $impl2 ? 1 : 0, 0, 'Document->implementation != D->i';
} # _impl

sub _doctype : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  my $doc2 = $doc->implementation->create_document;
  is $doc2->doctype, undef, 'Document->implementation [0]';

  my $doctype = $doc2->implementation->create_document_type ('dt');
  my $el = $doc2->create_element_ns (undef, 'e');
  $doc2->append_child ($doctype);
  $doc2->append_child ($el);

  is $doc2->doctype, $doctype, 'Document->implementation [1]';
} # _doctype

sub _doctype2 : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  my $doc2 = $doc->implementation->create_document;
  my $doctype = $doc2->implementation->create_document_type ('dt');
  my $el = $doc2->create_element_ns (undef, 'e');
  my $comment = $doc2->create_comment ('');
  $doc2->append_child ($comment);
  $doc2->append_child ($doctype);
  $doc2->append_child ($el);

  is $doc2->doctype, $doctype, 'Document->implementation [2]';
} # _doctype2

sub _docel : Test(3) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;

  my $doc2 = $doc->implementation->create_document;
  is $doc2->can ('document_element') ? 1 : 0, 1, 'Document->document_el can';
  is $doc2->document_element, undef, 'Document->document_element [0]';

  my $el = $doc2->create_element_ns (undef, 'e');
  $doc2->append_child ($el);

  is $doc2->document_element, $el, 'Document->document_element [1]';
} # _docel

sub _docel2 : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc2 = $dom->create_document;
  my $doctype = $doc2->implementation->create_document_type ('dt');
  $doc2->append_child ($doctype);
  my $el = $doc2->create_element_ns (undef, 'e');
  $doc2->append_child ($el);

  is $doc2->document_element, $el, 'Document->document_element [1]';
} # _docel2

sub _config : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  is $doc->can ('dom_config') ? 1 : 0, 1, 'Document->dom_config can';
  my $cfg = $doc->dom_config;
  is UNIVERSAL::isa ($cfg, 'Message::IF::DOMConfiguration') ? 1 : 0,
      1, 'Document->dom_config interface';
} # _config

sub _adopt_note : Test(19) {
  my $impl = Message::DOM::DOMImplementation->new;
  my $doc1 = $impl->create_document;
  my $doc2 = $impl->create_document;

  is $doc2->can ('adopt_node') ? 1 : 0, 1, 'Document->adopt_node can';
  
  my $el1 = $doc1->create_element_ns (undef, 'e');
  my $el2 = $doc2->adopt_node ($el1);

  is $el1 eq $el2 ? 1 : 0, 1, 'Document->adopt_node return == source';
  is $el2->owner_document, $doc2, 'Document->adopt_node owner_document';
  
  my $node = $doc1->create_element ('e');
  my $udh_called = 0;
  $node->set_user_data (key => {}, sub {
    my ($op, $key, $data, $src, $dest) = @_;
    $udh_called = 1;
    
    is $op, 5, 'adopt_node user data handler operation';
    is $key, 'key', 'adopt_node user data handler key';
    is ref $data, 'HASH', 'adopt_node user data handler data';
    is $src, $node, 'adopt_node user data handler src';
    is $dest, undef, 'adopt_node user data handler dest';
  });

  $doc2->adopt_node ($node);

  is $udh_called, 1, 'Document->adopt_node udh called';

  $node->set_user_data (key => undef, undef);

  my $el3 = $doc1->create_element_ns (undef, 'e');
  my $el4 = $doc1->adopt_node ($el3);
  
  is $el4, $el3, 'Document->adopt_node samedoc return';
  is $el4->owner_document, $doc1, 'Document->adopt_node samedoc od';

  my $parent = $doc1->create_element ('pa');
  my $child = $doc1->create_element ('ch');
  $parent->append_child ($child);

  my $child2 = $doc2->adopt_node ($child);
  
  is $child2, $child, 'Document->adopt_node return [2]';
  is $child2->owner_document, $doc2, 'Document->adopt_node->od [2]';
  is $child2->parent_node, undef, 'Document->adopt_node->parent_node [2]';
  is 0+@{$parent->child_nodes}, 0, 'Document->adopt_node parent->cn @{} 0+ [2]';

  my $attr = $doc1->create_attribute ('e');
  $parent->set_attribute_node ($attr);

  my $attr2 = $doc2->adopt_node ($attr);
  is $attr2, $attr, 'Document->adopt_node return [3]';
  is $attr2->owner_document, $doc2, 'Document->adopt_node->od [3]';
  is $attr2->owner_element, undef, 'Document->adopt_node->oe [3]';
  is 0+@{$parent->attributes}, 0, 'Document->adopt_node parent->a @{} 0+ [3]';
} # _adopt_note

## TODO: manakai_entity_base_uri

sub _ready_state_initial : Test(1) {
  my $doc = Message::DOM::DOMImplementation->new->create_document;
  is $doc->ready_state, 'complete';
} # _ready_state_initial

sub _ready_state_initial_with_parser : Test(1) {
  local $TODO = 'creation of document with a parser is not supported yet';
  my $doc = Message::DOM::DOMImplementation->new->create_document;
  is $doc->ready_state, 'interactive';
} # _ready_state_initial

sub _ready_state_changed : Test(3) {
  my $doc = Message::DOM::DOMImplementation->new->create_document;

  $doc->_set_ready_state ('interactive');
  is $doc->ready_state, 'interactive';

  $doc->_set_ready_state ('loading');
  is $doc->ready_state, 'loading';

  $doc->_set_ready_state ('complete');
  is $doc->ready_state, 'complete';
} # _ready_state_changed

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
