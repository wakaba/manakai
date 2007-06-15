#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 4 } 

require Message::DOM::DOMImplementation;

## TODO: |create_document| tests

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

## AUTOLOAD test
ok $doc->can ('create_element_ns');
my $el = $doc->create_element_ns (undef, 'test');
ok UNIVERSAL::isa ($el, 'Message::IF::Element');

ok $doc->can ('no_such_method') ? 1 : 0, 0;
my $something_called = 0;
eval {
  $doc->no_such_method;
  $something_called = 1;
};
ok $something_called, 0;

## NOTE: Tests for |create_*| methods found in each module's test file.

my $impl = $doc->implementation;
ok UNIVERSAL::isa ($impl, 'Message::IF::DOMImplementation') ? 1 : 0, 1;

## License: Public Domain.
## $Date: 2007/06/15 14:32:50 $
