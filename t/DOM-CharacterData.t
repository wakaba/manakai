#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 121 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;
    
for my $node (
              $doc->create_text_node ('initial value'),
              $doc->create_comment ('initial value'),
              $doc->create_cdata_section ('initial value'),
             ) {
  ok $node->node_value, 'initial value', $node->node_name . '->node_value get';
  ok $node->text_content, 'initial value', $node->node_name . '->tc get';
  ok $node->data, 'initial value', $node->node_name . '->data get';
  
  $node->manakai_set_read_only (0);

  $node->node_value ('value1');
  
  ok $node->node_value, 'value1', $node->node_name . '->node_value nv.set';
  ok $node->text_content, 'value1', $node->node_name . '->text_content nv.set';
  ok $node->data, 'value1', $node->node_name . '->data nv.set';

  $node->node_value ('');
  
  ok $node->node_value, '', $node->node_name . '->node_value nv.empty';
  ok $node->text_content, '', $node->node_name . '->text_content nv.empty';
  ok $node->data, '', $node->node_name . '->data nv.empty';

  $node->text_content ('value3');

  ok $node->node_value, 'value3', $node->node_name . '->node_value tc.set';
  ok $node->text_content, 'value3', $node->node_name . '->text_content tc.set';
  ok $node->data, 'value3', $node->node_name . '->data tc.set';

  $node->text_content ('');

  ok $node->node_value, '', $node->node_name . '->node_value tc.empty';
  ok $node->text_content, '', $node->node_name . '->text_content tc.empty';
  ok $node->data, '', $node->node_name . '->data tc.empty';

  $node->text_content ('value4');
  $node->text_content (undef);

  ok $node->node_value, '', $node->node_name . '->node_value tc.undef';
  ok $node->text_content, '', $node->node_name . '->text_content tc.undef';
  ok $node->data, '', $node->node_name . '->data tc.undef';

  $node->data ('value2');

  ok $node->node_value, 'value2', $node->node_name . '->node_value d.set';
  ok $node->text_content, 'value2', $node->node_name . '->text_content d.set';
  ok $node->data, 'value2', $node->node_name . '->data d.set';

  $node->data ('');

  ok $node->node_value, '', $node->node_name . '->node_value d.empty';
  ok $node->text_content, '', $node->node_name . '->text_content d.empty';
  ok $node->data, '', $node->node_name . '->data d.empty';

  $node->manakai_set_read_only (1);

  try {
    $node->node_value ('value1');
  } catch Message::DOM::DOMException with {
    ok shift->type, 'NO_MODIFICATION_ALLOWED_ERR', $node->node_name . '->nv.ro';
  };

  try {
    $node->text_content ('value1');
  } catch Message::DOM::DOMException with {
    ok shift->type, 'NO_MODIFICATION_ALLOWED_ERR', $node->node_name . '->tc.ro';
  };

  try {
    $node->data ('value1');
  } catch Message::DOM::DOMException with {
    ok shift->type, 'NO_MODIFICATION_ALLOWED_ERR', $node->node_name . '->d.ro';
  };
}

## |length|
{
  my $text = $doc->create_text_node ('');
  for my $testdata (
                    # id, data, length
                    ['empty', '', 0],
                    ['small.a', 'a', 1],
                    ['han.4e00', "\x{4E00}", 1],
                    ['a-z', 'abcdefghijklmnopqrstuvwxyz', 26],
                    ['U+10000', "\x{10000}", 2],
                    ['aU+10000', "a\x{10000}", 3],
                    ['U+10000U+11111', "\x{10000}\x{11111}", 4],
                   ) {
    $text->data ($testdata->[1]);
    ok $text->length, $testdata->[2], $testdata->[0] . '->length';
  }

  $text->data ('');
  ok $text->substring_data (0, 0), '', "substring_data [1]";
  ok $text->substring_data (0, 1), '', "substring_data [2]";

  $text->data ('abcdefg');
  ok $text->substring_data (0, 0), '', "substring_data [1]";
  ok $text->substring_data (0, 1), 'a', "substring_data [2]";
  ok $text->substring_data (5, 1), 'f', "substring_data [3]";
  ok $text->substring_data (5, 2), 'fg', "substring_data [4]";
  
  $text->data ('');
  $text->append_data ('');
  ok $text->data, '', "append_data [1]";

  $text->append_data ('a');
  ok $text->data, 'a', "append_data [2]";

  $text->append_data ('abc');
  ok $text->data, 'aabc', "append_data [3]";

  $text->data ('');

  try {
    $text->insert_data (1, 'abc');
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'insert_data [1]';
  };

  try {
    $text->insert_data (-1, 'abc');
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'insert_data [2]';
  };

  $text->insert_data (0, 'abc');
  ok $text->data, 'abc', 'insert_data [3]';

  $text->insert_data (3, 'abc');
  ok $text->data, 'abcabc', 'insert_data [4]';

  $text->insert_data (1, 'abc');
  ok $text->data, 'aabcbcabc', 'insert_data [5]';
 
  $text->data ('');
 
  $text->insert_data (0, "\x{10000}");
  ok $text->data, "\x{10000}", "insert_data [6]";

  $text->insert_data (2, "\x{10001}");
  ok $text->data, "\x{10000}\x{10001}", "insert_data [7]";

  $text->insert_data (2, 'a');
  ok $text->data, "\x{10000}a\x{10001}", "insert_data [8]";

  $text->data ('');

  $text->delete_data (0, 0);
  ok $text->data, '', 'delete_data [1]';

  $text->delete_data (0, 10);
  ok $text->data, '', 'delete_data [2]';

  try {
    $text->delete_data (-1, 0);
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'delete_data [3]';
  };

  try {
    $text->delete_data (1, 0);
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'delete_data [4]';
  };

  try {
    $text->delete_data (0, -10);
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'delete_data [5]';
  };

  $text->append_data ('abcdefg');

  $text->delete_data (0, 0);
  ok $text->data, 'abcdefg', 'delete_data [6]';

  $text->delete_data (0, 2);
  ok $text->data, 'cdefg', 'delete_data [7]';

  try {
    $text->delete_data (-1, 0);
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'delete_data [8]';
  };

  try {
    $text->delete_data (20, 0);
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'delete_data [9]';
  };

  try {
    $text->delete_data (0, -10);
  } catch Message::DOM::DOMException with {
    ok shift->type, 'INDEX_SIZE_ERR', 'delete_data [10]';
  };

  $text->delete_data (2, 12);
  ok $text->data, 'cd', 'delete_data [11]';

  $text->delete_data (0, 2);
  ok $text->data, '', 'delete_data [12]';

  $text->data ("ab\x{10000}cdefg");

  $text->delete_data (0, 4);
  ok $text->data, 'cdefg', 'delete_data [13]';

  $text->data ("ab\x{10000}cdefg");

  $text->delete_data (4, 2);
  ok $text->data, "ab\x{10000}efg", 'delete_data [14]';

  $text->data ('abcdefg');
  $text->replace_data (0, 2, 'ABCD');
  ok $text->data, 'ABCDcdefg', 'replace_data [1]';

  $text->replace_data (3, 32, "\x{3000}\x{4E00}");
  ok $text->data, "ABC\x{3000}\x{4E00}", 'replace_data [2]';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/08 11:28:45 $
