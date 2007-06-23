#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 55 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

## TODO: |create_document| tests

my $dom = Message::DOM::DOMImplementation->____new;
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

for my $prop (qw/document_uri input_encoding/) {
  ok $doc->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('http://absuri.test/', 'reluri', 0, '') {
    $doc->$prop ($_);
    ok $doc->$prop, $_, $prop . $_;
  }

  $doc->$prop (undef);
  ok $doc->$prop, undef, $prop . ' undef';
}

for my $prop (qw/all_declarations_processed/) {
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

## TODO: manakai_entity_base_uri

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/23 12:47:13 $
