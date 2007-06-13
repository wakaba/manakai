#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 10 } 

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->____new;

ok $dom->isa ('Message::DOM::DOMImplementation');
ok $dom->isa ('Message::IF::DOMImplementation');

## AUTOLOAD test
ok $dom->can ('create_uri_reference');
my $uri = $dom->create_uri_reference ('http://www.uri.test/');
ok UNIVERSAL::isa ($uri, 'Message::IF::URIReference');

ok $dom->can ('no_such_method') ? 1 : 0, 0;
my $something_called = 0;
eval {
  $dom->no_such_method;
  $something_called = 1;
};
ok $something_called, 0;

## License: Public Domain.
## $Date: 2007/06/13 12:04:51 $
