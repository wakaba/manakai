#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 16 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
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

## $Date: 2007/06/17 13:37:42 $
