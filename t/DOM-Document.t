#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 139 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

## TODO: |create_document| tests

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

## AUTOLOAD test
ok $doc->can ('create_element_ns') ? 1 : 0, 1, "can create_element_ns";
my $el = $doc->create_element_ns (undef, 'test');
ok UNIVERSAL::isa ($el, 'Message::IF::Element');

ok $doc->can ('no_such_method') ? 1 : 0, 0;
my $something_called = 0;
eval {
  $doc->no_such_method;
  $something_called = 1;
};
ok $something_called, 0;

## NOTE: Tests for |create_*| methods found in |DOM-Node.t|.

my $impl = $doc->implementation;
ok UNIVERSAL::isa ($impl, 'Message::IF::DOMImplementation') ? 1 : 0, 1;

## |xmlVersion|
ok $doc->can ('xml_version') ? 1 : 0, 1, 'can xml_version';

ok $doc->xml_version, '1.0', 'xml_version initial';

$doc->xml_version ('1.1');
ok $doc->xml_version, '1.1', 'xml_version 1.1';

$doc->xml_version ('1.0');
ok $doc->xml_version, '1.0', 'xml_version 1.0';

try {
  $doc->xml_version ('1.2');
  ok undef, 'NOT_SUPPORTED_ERR', 'xml_version 1.2 exception';
} catch Message::IF::DOMException with {
  my $err = shift;
  ok $err->type, 'NOT_SUPPORTED_ERR', 'xml_version 1.2 exception';
};
ok $doc->xml_version, '1.0', 'xml_version 1.2';

## |xmlVersion| and |manakaiIsHTML|
my $html_doc = $doc->implementation->create_document;
{
  $html_doc->manakai_is_html (1);
  ok $html_doc->manakai_is_html ? 1 : 0, 1, 'HTMLDocument->manakai_is_html 1';
  ok $html_doc->xml_version, undef, 'HTMLDocument->xml_version';
  
  try {
    $html_doc->xml_version ('1.0');
    ok undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_version 1.0 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NOT_SUPPORTED_ERR',
        'HTMLDocument->xml_version 1.0 exception';
  };
  ok $html_doc->xml_version, undef, 'HTMLDocument->xml_version 1.0';

  $html_doc->manakai_is_html (0);
  ok $html_doc->manakai_is_html ? 1 : 0, 0, 'HTMLDocument->manakai_is_html 0';
  ok $html_doc->xml_version, '1.0', '(was HTML) Document->xml_version 1.0';

  $html_doc->manakai_is_html (1);
}

## |xmlEncoding|
{
  ok $doc->can ('xml_encoding') ? 1 : 0, 1, 'can xml_encoding';

  $doc->xml_encoding ('utf-8');
  ok $doc->xml_encoding, 'utf-8', 'xml_encoding legal';

  $doc->xml_encoding ('\abcd');
  ok $doc->xml_encoding, '\abcd', 'xml_encoding illegal';

  $doc->xml_encoding (undef);
  ok $doc->xml_encoding, undef, 'xml_encoding null';

  ok $html_doc->xml_encoding, undef, 'HTMLDocument->xml_encoding';
  
  try {
    $html_doc->xml_encoding ('utf-8');
    ok undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception';
  };
  ok $html_doc->xml_encoding, undef, 'HTMLDocument->xml_encoding';
  
  try {
    $html_doc->xml_encoding (undef);
    ok undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception 2';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_encoding exception 2';
  };
  ok $html_doc->xml_encoding, undef, 'HTMLDocument->xml_encoding 2';
}

## |xmlStandalone|
{
  ok $doc->can ('xml_standalone') ? 1 : 0, 1, 'can xml_standalone';

  $doc->xml_standalone (1);
  ok $doc->xml_standalone ? 1 : 0, 1, 'xml_standalone 1';

  $doc->xml_standalone (0);
  ok $doc->xml_standalone ? 1 : 0, 0, 'xml_standalone 0';

  ok $html_doc->xml_standalone ? 1 : 0, 0, 'HTMLDocument->xml_standalone';
  
  try {
    $html_doc->xml_standalone (1);
    ok undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_standalone 1 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NOT_SUPPORTED_ERR',
        'HTMLDocument->xml_standalone 1 exception';
  };
  ok $html_doc->xml_standalone ? 1 : 0, 0, 'HTMLDocument->xml_standalone 1';
  
  try {
    $html_doc->xml_standalone (0);
    ok undef, 'NOT_SUPPORTED_ERR', 'HTMLDocument->xml_standalone 0 exception';
  } catch Message::IF::DOMException with {
    my $err = shift;
    ok $err->type, 'NOT_SUPPORTED_ERR',
        'HTMLDocument->xml_standalone 0 exception';
  };
  ok $html_doc->xml_standalone ? 1 : 0, 0, 'HTMLDocument->xml_standalone 0';
}

## |strictErrorChecking|
{
  ok $doc->can ('strict_error_checking') ? 1 : 0, 1, 'can strict_error_checking';

  $doc->strict_error_checking (0);
  ok $doc->strict_error_checking ? 1 : 0, 0, 'strict_error_checking 0';

  $doc->strict_error_checking (1);
  ok $doc->strict_error_checking ? 1 : 0, 1, 'strict_error_checking 1';

  $doc->strict_error_checking (undef);
  ok $doc->strict_error_checking ? 1 : 0, 0, 'strict_error_checking undef';

  $doc->strict_error_checking (1);
}

for my $prop (qw/document_uri input_encoding manakai_charset/) {
  ok $doc->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('http://absuri.test/', 'reluri', 0, '') {
    $doc->$prop ($_);
    ok $doc->$prop, $_, $prop . $_;
  }

  $doc->$prop (undef);
  ok $doc->$prop, undef, $prop . ' undef';
}

for my $prop (qw/all_declarations_processed manakai_has_bom/) {
  ok $doc->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for (1, 0, '') {
    $doc->$prop ($_);
    ok $doc->$prop ? 1 : 0, $_ ? 1 : 0, $prop . $_;
  }

  $doc->$prop (undef);
  ok $doc->$prop ? 1 : 0, 0, $prop . ' undef';
}

## |manakaiIsHTML|, |compatMode|, and |manakaiCompatMode|
{
  my $doc2 = $doc->implementation->create_document;
  ok $doc2->can ('manakai_is_html') ? 1 : 0, 1, "can manakai_is_html";
  ok $doc2->can ('compat_mode') ? 1 : 0, 1, "can compat_mode";
  ok $doc2->can ('manakai_compat_mode') ? 1 : 0, 1, "can manakai_compat_mode";
  ok $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [0]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [0]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [0]';

  $doc2->manakai_compat_mode ('quirks');
  ok $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [1]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [1]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [1]';

  $doc2->manakai_compat_mode ('limited quirks');
  ok $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [2]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [2]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [2]';

  $doc2->manakai_compat_mode ('no quirks');
  ok $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [3]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [3]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [3]';

  $doc2->manakai_compat_mode ('bogus');
  ok $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [4]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [4]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [4]';

  $doc2->manakai_is_html (1);
  ok $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [5]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [5]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [5]';

  $doc2->manakai_compat_mode ('quirks');
  ok $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [6]";
  ok $doc2->compat_mode, 'BackCompat', 'compat_mode [6]';
  ok $doc2->manakai_compat_mode, 'quirks', 'manakai_compat_mode [6]';

  $doc2->manakai_compat_mode ('limited quirks');
  ok $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [7]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [7]';
  ok $doc2->manakai_compat_mode, 'limited quirks', 'manakai_compat_mode [7]';

  $doc2->manakai_compat_mode ('no quirks');
  ok $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [8]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [8]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [8]';

  $doc2->manakai_compat_mode ('bogus');
  ok $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [9]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [9]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [9]';

  $doc2->manakai_compat_mode ('quirks');
  $doc2->manakai_is_html (0);
  ok $doc2->manakai_is_html ? 1 : 0, 0, "manakai_is_html [10]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [10]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [10]';

  $doc2->manakai_is_html (1);
  ok $doc2->manakai_is_html ? 1 : 0, 1, "manakai_is_html [11]";
  ok $doc2->compat_mode, 'CSS1Compat', 'compat_mode [11]';
  ok $doc2->manakai_compat_mode, 'no quirks', 'manakai_compat_mode [11]';
}

{
  ok $doc->can ('implementation') ? 1 : 0, 1, 'Document->implementation can';
  my $impl = $doc->implementation;
  ok UNIVERSAL::isa ($impl, 'Message::DOM::DOMImplementation') ? 1 : 0,
      1, 'Document->implementation class';
  my $impl2 = $doc->implementation;
  ok $impl eq $impl2 ? 1 : 0, 1, 'Document->implementation eq D->i';
  ok $impl ne $impl2 ? 1 : 0, 0, 'Document->implementation ne D->i';
  ok $impl == $impl2 ? 1 : 0, 1, 'Document->implementation == D->i';
  ok $impl != $impl2 ? 1 : 0, 0, 'Document->implementation != D->i';
}

{
  my $doc2 = $doc->implementation->create_document;
  ok $doc2->doctype, undef, 'Document->implementation [0]';

  my $doctype = $doc2->implementation->create_document_type ('dt');
  my $el = $doc2->create_element_ns (undef, 'e');
  $doc2->append_child ($doctype);
  $doc2->append_child ($el);

  ok $doc2->doctype, $doctype, 'Document->implementation [1]';
}

{
  my $doc2 = $doc->implementation->create_document;
  my $doctype = $doc2->implementation->create_document_type ('dt');
  my $el = $doc2->create_element_ns (undef, 'e');
  my $comment = $doc2->create_comment ('');
  $doc2->append_child ($comment);
  $doc2->append_child ($doctype);
  $doc2->append_child ($el);

  ok $doc2->doctype, $doctype, 'Document->implementation [2]';
}

{
  my $doc2 = $doc->implementation->create_document;
  ok $doc2->can ('document_element') ? 1 : 0, 1, 'Document->document_el can';
  ok $doc2->document_element, undef, 'Document->document_element [0]';

  my $el = $doc2->create_element_ns (undef, 'e');
  $doc2->append_child ($el);

  ok $doc2->document_element, $el, 'Document->document_element [1]';
}

{
  my $doc2 = $doc->implementation->create_document;
  my $doctype = $doc2->implementation->create_document_type ('dt');
  $doc2->append_child ($doctype);
  my $el = $doc2->create_element_ns (undef, 'e');
  $doc2->append_child ($el);

  ok $doc2->document_element, $el, 'Document->document_element [1]';
}

{
  ok $doc->can ('dom_config') ? 1 : 0, 1, 'Document->dom_config can';
  my $cfg = $doc->dom_config;
  ok UNIVERSAL::isa ($cfg, 'Message::IF::DOMConfiguration') ? 1 : 0,
      1, 'Document->dom_config interface';
}

{
  my $impl = $doc->implementation;
  my $doc1 = $impl->create_document;
  my $doc2 = $impl->create_document;

  ok $doc2->can ('adopt_node') ? 1 : 0, 1, 'Document->adopt_node can';

  my $el1 = $doc1->create_element_ns (undef, 'e');
  my $el2 = $doc2->adopt_node ($el1);

  ok $el1 eq $el2 ? 1 : 0, 1, 'Document->adopt_node return == source';
  ok $el2->owner_document, $doc2, 'Document->adopt_node owner_document';
  
  my $node = $doc1->create_element ('e');
  my $udh_called = 0;
  $node->set_user_data (key => {}, sub {
    my ($op, $key, $data, $src, $dest) = @_;
    $udh_called = 1;
    
    ok $op, 5, 'adopt_node user data handler operation';
    ok $key, 'key', 'adopt_node user data handler key';
    ok ref $data, 'HASH', 'adopt_node user data handler data';
    ok $src, $node, 'adopt_node user data handler src';
    ok $dest, undef, 'adopt_node user data handler dest';
  });

  $doc2->adopt_node ($node);

  ok $udh_called, 1, 'Document->adopt_node udh called';

  $node->set_user_data (key => undef, undef);

  my $el3 = $doc1->create_element_ns (undef, 'e');
  my $el4 = $doc1->adopt_node ($el3);
  
  ok $el4, $el3, 'Document->adopt_node samedoc return';
  ok $el4->owner_document, $doc1, 'Document->adopt_node samedoc od';

  my $parent = $doc1->create_element ('pa');
  my $child = $doc1->create_element ('ch');
  $parent->append_child ($child);

  my $child2 = $doc2->adopt_node ($child);
  
  ok $child2, $child, 'Document->adopt_node return [2]';
  ok $child2->owner_document, $doc2, 'Document->adopt_node->od [2]';
  ok $child2->parent_node, undef, 'Document->adopt_node->parent_node [2]';
  ok 0+@{$parent->child_nodes}, 0, 'Document->adopt_node parent->cn @{} 0+ [2]';

  my $attr = $doc1->create_attribute ('e');
  $parent->set_attribute_node ($attr);

  my $attr2 = $doc2->adopt_node ($attr);
  ok $attr2, $attr, 'Document->adopt_node return [3]';
  ok $attr2->owner_document, $doc2, 'Document->adopt_node->od [3]';
  ok $attr2->owner_element, undef, 'Document->adopt_node->oe [3]';
  ok 0+@{$parent->attributes}, 0, 'Document->adopt_node parent->a @{} 0+ [3]';
}

## TODO: manakai_entity_base_uri

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/11/18 11:08:43 $
