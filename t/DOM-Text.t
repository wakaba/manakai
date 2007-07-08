#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 121 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

## |isElementContentWhitespace|
{
  my $node = $doc->create_text_node ('');

  ok $node->is_element_content_whitespace ? 1 : 0, 0, 'ecw [0]';

  $node->is_element_content_whitespace (1);
  ok $node->is_element_content_whitespace ? 1 : 0, 1, 'rcw [1]';

  $node->is_element_content_whitespace (0);
  ok $node->is_element_content_whitespace ? 1 : 0, 0, 'ecw [2]';
}

## |wholeText|
{
  my $text1 = $doc->create_text_node ('text1');
  my $el = $doc->create_element ('el');
  $el->append_child ($text1);

  ok $text1->whole_text, 'text1', 'whole_text [1]';

  my $text2 = $doc->create_text_node ('text2');
  $el->append_child ($text2);

  ok $text1->whole_text, 'text1text2', 'whole_text [2]';
  ok $text2->whole_text, 'text1text2', 'whole_text [3]';

  my $text3 = $doc->create_cdata_section ('text3');
  $el->append_child ($text3);

  ok $text1->whole_text, 'text1text2text3', 'whole_text [4]';
  ok $text2->whole_text, 'text1text2text3', 'whole_text [5]';
  ok $text3->whole_text, 'text1text2text3', 'whole_text [6]';

  my $el1 = $doc->create_element ('el1');
  $el->append_child ($el1);
  $el->append_child ($text2);

  ok $text1->whole_text, 'text1text3', 'whole_text [7]';
  ok $text2->whole_text, 'text2', 'whole_text [8]';
  ok $text3->whole_text, 'text1text3', 'whole_text [9]';
}
{
  my $el = $doc->create_element ('e');
  my $text1 = $doc->create_text_node ('text1');
  $el->append_child ($text1);
  my $text3 = $doc->create_cdata_section ('text3');
  $el->append_child ($text3);
  my $er1 = $doc->create_entity_reference ('er1');
  $er1->manakai_set_read_only (0, 1);
  $el->append_child ($er1);
  my $text4 = $doc->create_text_node ('text4');
  $er1->append_child ($text4);
  my $text2 = $doc->create_cdata_section ('text2');
  $el->append_child ($text2);

  ok $text1->whole_text, 'text1text3text4text2', 'whole_text [10]';
  ok $text2->whole_text, 'text1text3text4text2', 'whole_text [11]';
  ok $text3->whole_text, 'text1text3text4text2', 'whole_text [12]';
  ok $text4->whole_text, 'text1text3text4text2', 'whole_text [13]';
}
{
  my $el = $doc->create_element ('e');
  my $text1 = $doc->create_text_node ('text1');
  $el->append_child ($text1);
  my $text3 = $doc->create_cdata_section ('text3');
  $el->append_child ($text3);
  my $er1 = $doc->create_entity_reference ('er1');
  $er1->manakai_set_read_only (0, 1);
  $el->append_child ($er1);
  my $text4 = $doc->create_text_node ('text4');
  $er1->append_child ($text4);
  my $com1 = $doc->create_comment ('');
  $er1->append_child ($com1);
  my $text2 = $doc->create_text_node ('text2');
  $el->append_child ($text2);

  ok $text1->whole_text, 'text1text3text4', 'whole_text [14]';
  ok $text2->whole_text, 'text2', 'whole_text [15]';
  ok $text3->whole_text, 'text1text3text4', 'whole_text [16]';
  ok $text4->whole_text, 'text1text3text4', 'whole_text [17]';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/08 11:28:45 $
