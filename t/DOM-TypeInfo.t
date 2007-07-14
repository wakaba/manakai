#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 50 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

## "eq" and "ne"
{
  my $el1 = $doc->create_element ('e1');
  ok $el1->can ('schema_type_info') ? 1 : 0, 1, 'Element->schema_type_info can';
  my $ti1 = $el1->schema_type_info;
  my $el2 = $doc->create_element ('e2');
  my $ti2 = $el1->schema_type_info;

  ok $ti1 eq $ti1 ? 1 : 0, 1, "<A> eq <A>";
  ok $ti1 ne $ti1 ? 1 : 0, 0, "<A> ne <A>";
  ok $ti1 eq $ti2 ? 1 : 0, 1, "<A> eq <B>";
  ok $ti1 ne $ti2 ? 1 : 0, 0, "<A> ne <B>";

  my $at1 = $doc->create_attribute ('a1');
  ok $at1->can ('schema_type_info') ? 1 : 0, 1, 'Attr->schema_type_info can';
  $ti2 = $at1->schema_type_info;
  ok $ti1 eq $ti2 ? 1 : 0, 1, q[<A> eq B=""];
  ok $ti1 ne $ti2 ? 1 : 0, 0, q[<A> ne B=""];

  for (1..10) {
    $at1->manakai_attribute_type ($_);
    $ti2 = $at1->schema_type_info;
    ok $ti2 eq $ti2 ? 1 : 0, 1, qq[B="$_" eq B="$_"];
    ok $ti2 ne $ti2 ? 1 : 0, 0, qq[B="$_" ne B="$_"];
    ok $ti1 eq $ti2 ? 1 : 0, 0, qq[<A> eq B="$_"];
    ok $ti1 ne $ti2 ? 1 : 0, 1, qq[<A> ne B="$_"];
  }

  $at1->manakai_attribute_type (11);
  $ti2 = $at1->schema_type_info;
  ok $ti1 eq $ti2 ? 1 : 0, 1, q[<A> eq B=""];
  ok $ti1 ne $ti2 ? 1 : 0, 0, q[<A> ne B=""];
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/14 06:12:56 $
