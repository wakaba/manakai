#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 101 } 

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
      my $dt = $doc->create_general_entity ($v->[0]);
      ok $dt->node_name, $v->[0], 'create_general_entity '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, undef, 'create_general_entity '.$v->[0];
    };
  } else {
    try {
      $doc->create_general_entity ($v->[0]);
      ok 0, 1, 'create_general_entity '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, $v->[1], 'create_general_entity '.$v->[0];
    };
  }
  $doc->strict_error_checking (0);
  my $dt = $doc->create_general_entity ($v->[0]);
  ok $dt->node_name, $v->[0], 'create_general_entity s '.$v->[0];
}
$doc->strict_error_checking (1);

my $ent = $doc->create_general_entity ('entity');

for my $prop (qw/has_replacement_tree is_externally_declared/) {
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for (1, 0, '') {
    $ent->$prop ($_);
    ok $ent->$prop ? 1 : 0, $_ ? 1 : 0, $prop . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop ? 1 : 0, 0, $prop . ' undef';
}

for my $prop (qw/input_encoding notation_name public_id system_id/) {
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('-//...//EN', 'http://absuri.test/', 'reluri',
       'utf-8', 'x-sjis',
       qq('illegal"), qq'\x{4E00}', ' ', 0, '') {
    $ent->$prop ($_);
    ok $ent->$prop, $_, $prop . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop, undef, $prop . ' undef';
}

## |manakaiDeclarationBaseURI|
{
  my $doc2 = $doc->implementation->create_document;
  my $ent = $doc2->create_general_entity ('entity');

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

## |manakaiEntityBaseURI|
{
  my $doc2 = $doc->implementation->create_document;
  my $ent = $doc2->create_general_entity ('entity');
  ok $ent->manakai_entity_base_uri, undef, "Entity->manakai_entity_base_uri [0]";

  $doc2->document_uri (q<http://www.example/>);
  ok $ent->manakai_entity_base_uri, q<http://www.example/>,
      "Entity->manakai_entity_base_uri [1]";
  
  $ent->manakai_entity_base_uri (q<ftp://www.example/>);
  ok $ent->manakai_entity_base_uri, q<ftp://www.example/>,
      "Entity->manakai_entity_base_uri [2]";
  ok $ent->base_uri, q<http://www.example/>,
      "Entity->manakai_entity_base_uri base_uri [2]";
        
  $ent->manakai_entity_base_uri (undef);
  ok $ent->manakai_entity_base_uri, q<http://www.example/>,
      "Entity->manakai_entity_base_uri [3]";

  $ent->manakai_entity_uri (q<https://www.example/>);
  ok $ent->manakai_entity_base_uri, q<https://www.example/>,
      "Entity->manakai_entity_base_uri [4]";
  ok $ent->base_uri, q<http://www.example/>,
      "Entity->manakai_entity_base_uri base_uri [4]";

  $ent->manakai_entity_uri (undef);
  ok $ent->manakai_entity_base_uri, q<http://www.example/>,
      "Entity->manakai_entity_base_uri [5]";
}

## |manakaiEntityURI|
{
  my $doc2 = $doc->implementation->create_document;
  my $ent = $doc2->create_general_entity ('entity');
  ok $ent->manakai_entity_uri, undef, "Entity->manakai_entity_uri [0]";

  $doc2->document_uri (q<http://www.document.example/>);
  ok $ent->manakai_entity_uri, undef, "Entity->manakai_entity_uri [1]";

  $ent->manakai_declaration_base_uri (q<http://decl.example/>);
  ok $ent->manakai_entity_uri, undef, "Entity->manakai_entity_uri [2]";

  $ent->system_id (q<sysid>);
  ok $ent->manakai_entity_uri, q<http://decl.example/sysid>,
      "Entity->manakai_entity_uri [3]";

  $ent->manakai_entity_uri (q<http://enturi.example/>);
  ok $ent->manakai_entity_uri, q<http://enturi.example/>,
      "Entity->manakai_entity_uri [4]";

  $ent->manakai_entity_uri (undef);
  ok $ent->manakai_entity_uri, q<http://decl.example/sysid>,
      "Entity->manakai_entity_uri [5]";
}

## |xmlVersion|
{
   my $node = $doc->create_general_entity ('ent');
   ok $node->xml_version, undef, 'xml_version [1]';
   $node->xml_version ('1.0');
   ok $node->xml_version, '1.0', 'xml_version [2]';
   $node->xml_version ('1.1');
   ok $node->xml_version, '1.1', 'xml_version [3]';
   $node->xml_version (undef);
   ok $node->xml_version, undef, 'xml_version [4]';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/08/22 10:59:43 $
