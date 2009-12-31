#!/usr/bin/perl
package test::Whatpm::XML::Parser;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::XML::Parser;
use Message::DOM::DOMImplementation;
use Message::DOM::Document;

sub _xml_parser_gc : Test(2) {
  my $parser_destroy_called = 0;
  my $doc_destroy_called = 0;

  no warnings 'redefine';
  local *Whatpm::XML::Parser::DESTROY = sub { $parser_destroy_called++ };
  local *Message::DOM::Document::DESTROY = sub { $doc_destroy_called++ };

  my $doc = Message::DOM::DOMImplementation->new->create_document;
  Whatpm::XML::Parser->parse_char_string (q<<p>abc</p>> => $doc);

  is $parser_destroy_called, 1;

  undef $doc;
  is $doc_destroy_called, 1;
}

__PACKAGE__->runtests;

1;
