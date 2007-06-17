#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 29 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

my $ent = $doc->create_attribute ('attr');

{
  my $prop = 'specified';
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  ok $ent->$prop ? 1 : 0, 1, $prop . ' test is valid?';
  
  for (0, 1, '') {
    $ent->$prop ($_);
    ok $ent->$prop ? 1 : 0, 1, $prop . ' ' . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop ? 1 : 0, 1, $prop . ' undef';

  my $el = $doc->create_element ('element');
  $el->set_attribute_node ($ent); # set owner_element
  ok $ent->$prop ? 1 : 0, 1, $prop . ' test is valid? (has owner_element)';

  for (0, 1, '') {
    $ent->$prop ($_);
    ok $ent->$prop ? 1 : 0, $_ ? 1 : 0, $prop . ' (has owner_element) ' . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop ? 1 : 0, 0, $prop . ' (has owner_element) undef';
}

for my $prop (qw/manakai_attribute_type/) {
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  local $^W = 0;
  
  for (-3..10, 'abc', '') {
    $ent->$prop ($_);
    ok $ent->$prop, 0+$_, $prop . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop, 0, $prop . ' undef';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/17 13:37:42 $
