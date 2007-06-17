#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 23 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

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

## $Date: 2007/06/17 13:37:42 $
