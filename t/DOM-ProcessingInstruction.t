#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 33 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

my $el = $doc->create_processing_instruction ('pi');

for my $prop (qw/manakai_base_uri/) {
  ok $el->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('http://absuri.test/', 'reluri', 0, '') {
    $el->$prop ($_);
    ok $el->$prop, $_, $prop . $_;
  }

  $el->$prop (undef);
  ok $el->$prop, undef, $prop . ' undef';
}

## |nodeValue|, |textContent|, |data|
{
  my $node = $doc->create_processing_instruction ('pi', 'initial');
  ok $node->node_value, 'initial', 'node_value [1]';
  ok $node->text_content, 'initial', 'text_content [1]';
  ok $node->data, 'initial', 'data [1]';

  $node->node_value ('value1');
  ok $node->node_value, 'value1', 'node_value [2]';
  ok $node->text_content, 'value1', 'text_content [2]';
  ok $node->data, 'value1', 'data [2]';

  $node->node_value ('');
  ok $node->node_value, '', 'node_value [3]';
  ok $node->text_content, '', 'text_content [3]';
  ok $node->data, '', 'data [3]';

  $node->text_content ('value3');
  ok $node->node_value, 'value3', 'node_value [4]';
  ok $node->text_content, 'value3', 'text_content [4]';
  ok $node->data, 'value3', 'data [4]';

  $node->text_content ('');
  ok $node->node_value, '', 'node_value [5]';
  ok $node->text_content, '', 'text_content [5]';
  ok $node->data, '', 'data [5]';

  $node->text_content ('value4');
  $node->text_content (undef);
  ok $node->node_value, '', 'node_value [6]';
  ok $node->text_content, '', 'text_content [6]';
  ok $node->data, '', 'data [6]';

  $node->data ('value5');
  ok $node->node_value, 'value5', 'node_value [7]';
  ok $node->text_content, 'value5', 'text_content [7]';
  ok $node->data, 'value5', 'data [7]';

  $node->data ('');
  ok $node->node_value, '', 'node_value [8]';
  ok $node->text_content, '', 'text_content [8]';
  ok $node->data, '', 'data [8]';

  $node->manakai_set_read_only (1);
  try {
    $node->node_value ('value6');
    ok 0, 1, 'node_value [9]';
  } catch Message::IF::DOMException with {
    ok $_[0]->type, 'NO_MODIFICATION_ALLOWED_ERR', 'node_value [9]';
  };
  try {
    $node->text_content ('value7');
    ok 0, 1, 'text_content [9]';
  } catch Message::IF::DOMException with {
    ok $_[0]->type, 'NO_MODIFICATION_ALLOWED_ERR', 'text_content [9]';
  };
  try {
    $node->data ('value8');
    ok 0, 1, 'data [9]';
  } catch Message::IF::DOMException with {
    ok $_[0]->type, 'NO_MODIFICATION_ALLOWED_ERR', 'data [9]';
  };
}


=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/29 03:49:00 $
