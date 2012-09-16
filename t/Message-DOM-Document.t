package test::Message::DOM::Document;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::DOMImplementation;

sub ATOM_NS () { q<http://www.w3.org/2005/Atom> }

sub _atom_feed_element_no_document_element : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  
  is $doc->atom_feed_element, undef;
} # _atom_feed_element_no_document_element

sub _atom_feed_element_non_atom_document_element : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $el = $doc->create_element_ns (undef, 'feed');
  $doc->append_child ($el);
  
  is $doc->atom_feed_element, undef;
} # _atom_feed_element_non_atom_document_element

sub _atom_feed_element_atom_entry_document_element : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $el = $doc->create_element_ns (ATOM_NS, 'entry');
  $doc->append_child ($el);
  
  is $doc->atom_feed_element, undef;
} # _atom_feed_element_atom_entry_document_element

sub _atom_feed_element_atom_feed_document_element : Test(2) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  my $el = $doc->create_element_ns (ATOM_NS, 'feed');
  $doc->append_child ($el);
  
  isa_ok $doc->atom_feed_element, 'Message::DOM::Element';
  is $doc->atom_feed_element, $el;
} # _atom_feed_element_atom_feed_document_element

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
