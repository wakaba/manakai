#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 20 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->new;
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
      my $dt = $doc->create_element_type_definition ($v->[0]);
      ok $dt->node_name, $v->[0], 'create_element_type_definition '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, undef, 'create_element_type_definition '.$v->[0];
    };
  } else {
    try {
      $doc->create_element_type_definition ($v->[0]);
      ok 0, 1, 'create_element_type_definition '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, $v->[1], 'create_element_type_definition '.$v->[0];
    };
  }
  $doc->strict_error_checking (0);
  my $dt = $doc->create_element_type_definition ($v->[0]);
  ok $dt->node_name, $v->[0], 'create_element_type_definition s '.$v->[0];
}
$doc->strict_error_checking (1);

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/08/22 10:59:43 $
