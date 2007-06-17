#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 22 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

my $ent = $doc->create_document_type_definition ('entity');

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

{
  my $doc2 = $doc->implementation->create_document;
  my $dt = $doc2->create_document_type_definition ('dt2');
  ok $dt->declaration_base_uri, undef, "DT->declaration_base_uri [0]";
  ok $dt->manakai_declaration_base_uri, undef,
      "DT->manakai_declaration_base_uri [0]";

  $doc2->document_uri (q<http://doc.test/>);
  ok $dt->declaration_base_uri, q<http://doc.test/>,
      "DT->declaration_base_uri [1]";
  ok $dt->manakai_declaration_base_uri, q<http://doc.test/>,
      "DT->manakai_declaration_base_uri [1]";
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/17 13:37:42 $
