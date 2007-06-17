#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 70 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

my $ent = $doc->create_attribute_definition ('ad');

## Constants
my $constants = [
                 [NO_TYPE_ATTR => 0],
                 [CDATA_ATTR => 1],
                 [ID_ATTR => 2],
                 [IDREF_ATTR => 3],
                 [IDREFS_ATTR => 4],
                 [ENTITY_ATTR => 5],
                 [ENTITIES_ATTR => 6],
                 [NMTOKEN_ATTR => 7],
                 [NMTOKENS_ATTR => 8],
                 [NOTATION_ATTR => 9],
                 [ENUMERATION_ATTR => 10],
                 [UNKNOWN_ATTR => 11],
                 [UNKNOWN_DEFAULT => 0],
                 [FIXED_DEFAULT => 1],
                 [REQUIRED_DEFAULT => 2],
                 [IMPLIED_DEFAULT => 3],
                 [EXPLICIT_DEFAULT => 4],
];
for (@$constants) {
  my $const_name = $_->[0];
  ok $ent->can ($const_name) ? 1 : 0, 1, "can ($const_name)";
  ok $ent->$const_name, $_->[1], $const_name;
}

for my $prop (qw/declared_type default_type/) {
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
