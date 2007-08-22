#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 99 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

for my $v (
  [a => undef],
  [abc => undef],
  ['a:b' => undef],
  [1 => 'INVALID_CHARACTER_ERR'],
  [1234 => 'INVALID_CHARACTER_ERR'],
  ["\x{3001}\x{3002}" => 'INVALID_CHARACTER_ERR'], ## XML 1.1 Name
  [':aa' => undef],
  [':1' => undef],
  ['a:' => undef],
  ["a:\x{3005}b" => undef], ## XML 1.0 Name, XML 1.1 QName
) {
  $doc->strict_error_checking (1);
  if (not defined $v->[1]) {
    try {
      my $dt = $doc->create_attribute_definition ($v->[0]);
      ok $dt->node_name, $v->[0], 'create_attribute_definition '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, undef, 'create_attribute_definition '.$v->[0];
    };
  } else {
    try {
      $doc->create_attribute_definition ($v->[0]);
      ok 0, 1, 'create_attribute_definition '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, $v->[1], 'create_attribute_definition '.$v->[0];
    };
  }
  $doc->strict_error_checking (0);
  my $dt = $doc->create_attribute_definition ($v->[0]);
  ok $dt->node_name, $v->[0], 'create_attribute_definition s '.$v->[0];
}
$doc->strict_error_checking (1);

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

## allowedToken
{
  my $at = $doc->create_attribute_definition ('ay');

  ok $at->can ('allowed_tokens') ? 1 : 0, 1, 'can allowedTokens';

  my $list = $at->allowed_tokens;
  ok UNIVERSAL::isa ($list, 'Message::IF::DOMStringList') ? 1 : 0, 1,
      'allowedTokens interface';
  ok 0+@$list, 0, 'allowedTokens @{} 0+';

  push @$list, 'NMTOKEN';
  ok $list->[0], 'NMTOKEN', 'allowedTokens->[0]';
  undef $list;

  my $list2 = $at->allowed_tokens;
  ok $list2->[0], 'NMTOKEN', 'allowedTokens->[0] 2';

  my $list3 = $at->allowed_tokens;
  my $at2 = $doc->create_attribute_definition ('at2');
  my $list4 = $at2->allowed_tokens;

  ok $list2 eq $list3 ? 1 : 0, 1, 'allowedTokens eq allowedTokens';
  ok $list2 ne $list3 ? 1 : 0, 0, 'allowedTokens ne allowedTokens';
  ok $list2 eq $list4 ? 1 : 0, 0, 'allowedTokens eq allowedTokens2';
  ok $list2 ne $list4 ? 1 : 0, 1, 'allowedTokens ne allowedTokens2';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/08/22 10:59:43 $
