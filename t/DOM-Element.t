#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 38 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

my $el = $doc->create_element ('element');

for my $prop (qw/manakai_base_uri/) {
  ok $el->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('http://absuri.test/', 'reluri', 0, '') {
    $el->$prop ($_);
    ok $el->$prop, $_, $prop . $_;
  }

  $el->$prop (undef);
  ok $el->$prop, undef, $prop . ' undef';
}

for my $method (qw/set_attribute_node set_attribute_node_ns/) {
  my $el = $doc->create_element ('element');
  ok $el->can ($method) ? 1 : 0, 1, "can $method";

  my $a1 = $doc->create_attribute ('attr1');
  $a1->value ('value1');
  $a1->specified (0);

  my $r1 = $el->$method ($a1);
  ok $r1, undef, "$method return [1]";
  ok $el->get_attribute ('attr1'), 'value1', "$method get_attribute [1]";
  ok $el->get_attribute_ns (undef, 'attr1'), 'value1',
      "$method get_attribute_ns [1]";
  ok $el->get_attribute_node ('attr1'), $a1, "$method get_attribute_node [1]";
  ok $el->get_attribute_node_ns (undef, 'attr1'), $a1,
      "$method get_attribute_node_ns [1]";
  ok $a1->owner_element, $el, "$method owner_element [1]";
  ok $a1->specified ? 1 : 0, 1, "$method specified [1]";
  $a1->specified (0);

  my $a2 = $doc->create_attribute ('attr1');
  my $r3 = $el->$method ($a2);
  ok $r3, $a1, "$method return [2]";
  ok $a1->owner_element, undef, "$method owner_element [2]";
  ok $a1->specified ? 1 : 0, 1, "$method specified [2]";

  $el->set_attribute_ns (undef, attr => 'value');
  my $attr = $el->get_attribute_node_ns (undef, 'attr');
  $attr->specified (0);
  my $r4 = $el->$method ($attr);
  ok $r4, undef, "$method return [3]";
  ok $attr->owner_element, $el, "$method owner_element [3]";
  ok $attr->specified ? 1 : 0, 0, "$method specified [3]";
  ok $el->get_attribute_node_ns (undef, 'attr'), $attr,
      "$method get_attribute_node_ns [3]";
  ok $el->get_attribute_ns (undef, 'attr'), 'value',
      "$method get_attribute_ns [3]";
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/17 13:37:42 $
