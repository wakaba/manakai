#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 43 } 

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
      my $dt = $doc->create_notation ($v->[0]);
      ok $dt->node_name, $v->[0], 'create_notation '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, undef, 'create_notation '.$v->[0];
    };
  } else {
    try {
      $doc->create_notation ($v->[0]);
      ok 0, 1, 'create_notation '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, $v->[1], 'create_notation '.$v->[0];
    };
  }
  $doc->strict_error_checking (0);
  my $dt = $doc->create_notation ($v->[0]);
  ok $dt->node_name, $v->[0], 'create_notation s '.$v->[0];
}
$doc->strict_error_checking (1);

my $ent = $doc->create_notation ('entity');

for my $prop (qw/public_id system_id/) {
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('-//...//EN', 'http://absuri.test/', 'reluri',
       qq('illegal"), qq'\x{4E00}', 0, '') {
    $ent->$prop ($_);
    ok $ent->$prop, $_, $prop . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop, undef, $prop . ' undef';
}

## |manakaiDeclarationBaseURI|
{
  my $doc2 = $doc->implementation->create_document;
  my $ent = $doc2->create_notation ('notation');

  ok $ent->can ('manakai_declaration_base_uri') ? 1 : 0, 1,
      'can manakai_declaration_base_uri';

  $doc2->document_uri (q<http://www.example/>);
  ok $ent->manakai_declaration_base_uri, q<http://www.example/>,
      'manakai_declaration_base_uri document_uri';

  $ent->manakai_declaration_base_uri (q<ftp://www.example/>);
  ok $ent->manakai_declaration_base_uri, q<ftp://www.example/>,
      'manakai_declaration_base_uri explicit';
  ok $ent->base_uri, q<http://www.example/>,
      'manakai_declaration_base_uri (base_uri)';

  $ent->manakai_declaration_base_uri (undef);
  ok $ent->manakai_declaration_base_uri, q<http://www.example/>,
      'manakai_declaration_base_uri reset';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/08/22 10:59:43 $
