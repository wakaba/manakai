#!/usr/bin/perl
package test::Message::URI::URIReference;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;
use Test::Differences;

sub _00_interface : Test(1) {
  require Message::DOM::DOMImplementation;
  my $dom = Message::DOM::DOMImplementation->new;
  isa_ok $dom, 'Message::IF::URIImplementation';
} # _interface

__PACKAGE__->runtests;

1;

## License: Public Domain.
