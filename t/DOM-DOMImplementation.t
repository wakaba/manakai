#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 10 } 

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->____new;

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
  my $doc = $dom->create_document_type;
  ok UNIVERSAL::isa ($doc, 'Message::IF::DocumentType');
}

ok $dom->can ('no_such_method') ? 1 : 0, 0;
my $something_called = 0;
eval {
  $dom->no_such_method;
  $something_called = 1;
};
ok $something_called, 0;

## License: Public Domain.
## $Date: 2007/06/17 13:37:42 $
