#!/usr/bin/perl
package test::Message::IMT::InternetMediaType;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;
use Test::Differences;

sub _00_from_dom : Test(4) {
  require Message::DOM::DOMImplementation;
  my $dom = Message::DOM::DOMImplementation->new;
  ok $dom->can ('create_internet_media_type');
  isa_ok $dom, 'Message::IF::IMTImplementation';

  my $imt = $dom->create_internet_media_type ('text', 'plain');
  isa_ok $imt, 'Message::IMT::InternetMediaType';
  isa_ok $imt, 'Message::IF::InternetMediaType';
}

sub _tests : Test(27) {
  my $dom = Message::DOM::DOMImplementation->new;
  
  my $imt = $dom->create_internet_media_type ('text', 'plain');
  my $imt2 = $dom->create_internet_media_type ('Text', 'PLAIN');
  
  is $imt->top_level_type, 'text';
  is $imt->subtype, 'plain';
  is $imt->type, 'text/plain';
  is $imt->imt_text, 'text/plain';
  is $imt.'', 'text/plain';
  
  is $imt2->top_level_type, 'text';
  is $imt2->subtype, 'plain';
  is $imt2->type, 'text/plain';
  is $imt2->imt_text, 'text/plain';
  is $imt2.'', 'text/plain';
  
  is (($imt) ? 1 : 0, 1);
  is (($imt eq undef) ? 1 : 0, 0);
  is (($imt eq 'text/plain') ? 1 : 0, 1);
  is (($imt eq 'TEXT/PLAIN') ? 1 : 0, 0);
  is (($imt eq $imt) ? 1 : 0, 1);
  is (($imt eq $imt2) ? 1 : 0, 1);
  
  is $imt->parameter_length, 0;
  $imt->set_parameter (charseT => 'US-ascii');
  is $imt->parameter_length, 1;
  is $imt->get_attribute (0), 'charset';
  is $imt->get_value (0), 'US-ascii';
  is $imt->get_parameter ('charSet'), 'US-ascii';
  is $imt.'', 'text/plain; charset=US-ascii';
  $imt->remove_parameter ('Charset');
  is $imt->parameter_length, 0;
  $imt->set_parameter (format => 'flowed');
  $imt->set_parameter (delsp => 1);
  $imt->set_attribute (1 => 'format');
  $imt->set_value (1 => 'fixed');
  is $imt.'', 'text/plain; format=flowed; format=fixed';
  $imt->set_parameter (format => 'in\valid');
  is $imt.'', 'text/plain; format="in\\\\valid"';
  $imt->remove_parameter ('format');
  is $imt.'', 'text/plain';
  
  $imt->add_parameter (charset => 'utf-8');
  $imt->add_parameter (charset => 'utf-8');
  $imt->add_parameter (format => 'fixed');
  $imt->add_parameter (charset => 'us-ascii');
  is $imt.'', 'text/plain; charset=utf-8; charset=utf-8; format=fixed; charset=us-ascii';
}

__PACKAGE__->runtests;

1;

## License: Public Domain.
