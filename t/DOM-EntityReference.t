#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 30 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;

{
  my $doc = $dom->create_document;
  my $dt = $doc->create_document_type_definition ('dt');
  my $ent = $doc->create_general_entity ('ent1');
  $ent->text_content ('replacement text content');
  $ent->has_replacement_tree (1);
  $dt->set_general_entity_node ($ent);
  $doc->append_child ($dt);

  my $entref = $doc->create_entity_reference ('ent1');
  ok UNIVERSAL::isa ($entref, 'Message::IF::EntityReference') ? 1 : 0, 1,
      'create_er interface [0]';
  ok $entref->manakai_expanded ? 1 : 0, 1, 'create_er->m_expanded [0]';
  ok $entref->has_child_nodes ? 1 : 0, 1, 'create_er->has_cn [0]';
  ok $entref->text_content, 'replacement text content', 'create_er->tx [0]';
  ok $entref->manakai_read_only ? 1 : 0, 1, 'create_er->mro [0]';
}

{
  my $doc = $dom->create_document;
  my $dt = $doc->create_document_type_definition ('dt');
  my $ent0 = $doc->create_entity_reference ('ent1');
  my $et = $doc->create_general_entity ('ent1');
  $et->append_child ($ent0);
  $et->has_replacement_tree (1);
  $dt->set_general_entity_node ($et);
  $doc->append_child ($dt);

  my $entref = $doc->create_entity_reference ('ent1');
  ok UNIVERSAL::isa ($entref, 'Message::IF::EntityReference') ? 1 : 0, 1,
      'create_er interface [1]';
  ok $entref->manakai_expanded ? 1 : 0, 1, 'create_er->m_expanded [1]';
  ok $entref->has_child_nodes ? 1 : 0, 1, 'create_er->has_cn [1]';
  ok $entref->manakai_read_only ? 1 : 0, 1, 'create_er->mro [1]';
  ok defined $entref->first_child ? 1 : 0, 1, 'create_er->fc [1]';
  ok $entref->first_child->manakai_expanded ? 1 : 0, 0, 'create_er->rec x [1]';
}

{
  my $doc = $dom->create_document;
  my $dt = $doc->create_document_type_definition ('dt');
  my $ent0 = $doc->create_entity_reference ('ent2');
  my $et = $doc->create_general_entity ('ent1');
  $et->append_child ($ent0);
  $et->has_replacement_tree (1);
  my $ent0_2 = $doc->create_entity_reference ('ent1');
  my $et_2 = $doc->create_general_entity ('ent2');
  $et_2->append_child ($ent0_2);
  $et_2->has_replacement_tree (1);
  $dt->set_general_entity_node ($et);
  $dt->set_general_entity_node ($et_2);
  $doc->append_child ($dt);

  my $entref = $doc->create_entity_reference ('ent1');
  ok $entref->manakai_expanded ? 1 : 0, 1, 'create_er->me [2]';
  ok defined $entref->first_child ? 1 : 0, 1, 'create_er->fc [2]';
  ok $entref->first_child->manakai_expanded ? 1 : 0, 0, 'create_er->fc->me [2]';
}

my $doc = $dom->create_document;
my $ent = $doc->create_entity_reference ('entity');

for my $prop (qw/manakai_expanded manakai_external/) {
  ok $ent->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for (1, 0, '') {
    $ent->$prop ($_);
    ok $ent->$prop ? 1 : 0, $_ ? 1 : 0, $prop . $_;
  }

  $ent->$prop (undef);
  ok $ent->$prop ? 1 : 0, 0, $prop . ' undef';
}

## |manakaiEntityBaseURI|.
{
  my $doc2 = $doc->implementation->create_document;
  my $ent = $doc2->create_entity_reference ('ent1');
  $ent->manakai_set_read_only (0, 1);
  ok $ent->manakai_entity_base_uri, undef, "ER->manakai_entity_base_uri [0]";

  $doc2->document_uri (q<http://www.example/>);
  ok $ent->manakai_entity_base_uri, q<http://www.example/>, 
      "ER->manakai_entity_base_uri [1]";

  $ent->manakai_entity_base_uri (q<ftp://www.example/>);
  ok $ent->manakai_entity_base_uri, q<ftp://www.example/>,
      "ER->manakai_entity_base_uri [2]";
  ok $ent->base_uri, q<http://www.example/>,
      "ER->manakai_entity_base_uri base_uri [2]";
  
  $ent->manakai_entity_base_uri (undef);
  ok $ent->manakai_entity_base_uri, q<http://www.example/>,
      "ER->manakai_entity_base_uri [3]";
  ok $ent->base_uri, q<http://www.example/>,
      "ER->manakai_entity_base_uri base_uri [3]";
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/07 11:11:34 $
