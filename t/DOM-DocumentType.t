#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 56 } 

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
  [':aa' => 'NAMESPACE_ERR'],
  [':1' => 'NAMESPACE_ERR'],
  ['a:' => 'NAMESPACE_ERR'],
  ["a:\x{3005}b" => 'NAMESPACE_ERR'], ## XML 1.0 Name, XML 1.1 QName
) {
  $doc->strict_error_checking (1);
  unless (defined $v->[1]) {
    try {
      my $dt = $dom->create_document_type ($v->[0]);
      ok $dt->node_name, $v->[0], 'create_document_type '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, undef, 'create_document_type '.$v->[0];
    };
  } else {
    try {
      $dom->create_document_type ($v->[0]);
      ok 0, 1, 'create_document_type '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, $v->[1], 'create_document_type '.$v->[0];
    };
  }
  if (not defined $v->[1] or $v->[1] eq 'NAMESPACE_ERR') {
    try {
      my $dt = $doc->create_document_type_definition ($v->[0]);
      ok $dt->node_name, $v->[0], 'create_document_type_definition '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, undef, 'create_document_type_definition '.$v->[0];
    };
  } else {
    try {
      $doc->create_document_type_definition ($v->[0]);
      ok 0, 1, 'create_document_type_definition '.$v->[0];
    } catch Message::IF::DOMException with {
      my $e = shift;
      ok $e->type, $v->[1], 'create_document_type_definition '.$v->[0];
    };
  }
  $doc->strict_error_checking (0);
  my $dt = $doc->create_document_type_definition ($v->[0]);
  ok $dt->node_name, $v->[0], 'create_document_type_definition s '.$v->[0];
}

$doc->strict_error_checking (1);

## |createDocumentType|
{
  my $dt = $dom->create_document_type ('qname', 'pubid', 'sysid');
  ok $dt->isa ('Message::IF::DocumentType') ? 1 : 0, 1, 'cdt interface';
  ok $dt->node_name, 'qname', 'cdt node_name';
  ok $dt->public_id, 'pubid', 'cdt public_id';
  ok $dt->system_id, 'sysid', 'cdt system_id';
}

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

## $Date: 2007/08/22 10:59:43 $
