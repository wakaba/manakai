#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 23 } 

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;

ok $dom->isa ('Message::DOM::DOMImplementation');
ok $dom->isa ('Message::IF::DOMImplementation');

## AUTOLOAD test
{
  ok $dom->can ('create_uri_reference') ? 1 : 0, 1, "can create_uri_reference";
  my $uri = $dom->create_uri_reference ('http://www.uri.test/');
  ok UNIVERSAL::isa ($uri, 'Message::IF::URIReference');
}

{
  ok $dom->can ('create_document') ? 1 : 0, 1, "can create_document";
  my $doc = $dom->create_document;
  ok UNIVERSAL::isa ($doc, 'Message::IF::Document');
}

{
  ok $dom->can ('create_document_type') ? 1 : 0, 1, "can create_document_type";
  my $doc = $dom->create_document_type ('dt');
  ok UNIVERSAL::isa ($doc, 'Message::IF::DocumentType');
}

ok $dom->can ('no_such_method') ? 1 : 0, 0;
my $something_called = 0;
eval {
  $dom->no_such_method;
  $something_called = 1;
};
ok $something_called, 0;

require Message::DOM::DOMImplementationRegistry;
F: for my $features (
  {Core => '1.0'}, {XML => '1.0'}, {Core => '1.0', XML => '1.0'},
  {Core => '2.0'}, {XML => '2.0'}, {Core => '2.0', XML => '2.0'},
  {Core => '3.0'}, {XML => '3.0'}, {Core => '3.0', XML => '3.0'},
  {XMLVersion => '1.0'}, {XMLVersion => '1.1'},
  {Traversal => '2.0'}, {Traversal => ''},
) {
  my $list = $Message::DOM::DOMImplementationRegistry
      ->get_dom_implementation_list ($features);
  for my $impl (@$list) {
    if ($impl->isa ('Message::DOM::DOMImplementation')) {
      ok 1, 1, 'features: '. join ',', %$features;
      next F;
    }
  }
} # F

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/14 16:32:28 $
