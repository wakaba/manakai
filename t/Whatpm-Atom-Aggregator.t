package test::Whatpm::Atom::Aggregator;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::More;
use Whatpm::Atom::Aggregator;
use Message::DOM::DOMImplementation;

sub ATOM_NS () { q<http://www.w3.org/2005/Atom> }

sub _create_feed_from_feeds_empty : Test(3) {
  my $doc = Whatpm::Atom::Aggregator->create_feed_from_feeds;
  isa_ok $doc, 'Message::DOM::Document';
  
  my $de = $doc->document_element;
  isa_ok $de, 'Message::DOM::Element';
  
  is $de->local_name, 'feed';
} # _create_feed_from_feeds_empty

sub _create_feed_from_feeds_one : Test(4) {
  my $input1 = Message::DOM::DOMImplementation->new->create_atom_feed_document
      (q<about:test:input1>, 'Feed 1');
  my $feed_el_1 = $input1->document_element;
  $feed_el_1->updated_element->value (1040000123);
  $feed_el_1->append_child ($input1->create_element_ns (ATOM_NS, 'author'))
      ->name ('Feed Author Name');
  $feed_el_1->add_new_entry
      (q<about:test:input1:entry1>, 'ENTRY 1')
          ->updated_element->value (1040800123);
  for my $entry_el ($feed_el_1->add_new_entry
                        (q<about:test:input1:entry2>, 'ENTRY 2', 'en')) {
    $entry_el->updated_element->value (1040600123);
    $_->name ('Entry2 Author'), $_->uri (q<http://entry2.test/>) for
    $entry_el->append_child ($input1->create_element_ns (ATOM_NS, 'author'));
  }

  my $doc = Whatpm::Atom::Aggregator->create_feed_from_feeds
      ({}, $input1);
  isa_ok $doc, 'Message::DOM::Document';
  
  my $de = $doc->document_element;
  isa_ok $de, 'Message::DOM::Element';
  
  is $de->local_name, 'feed';

  $doc->document_element->updated_element->value (3233233333);
  is $doc->inner_html, q[<feed xml:lang="" xmlns="http://www.w3.org/2005/Atom" xmlns:h="http://www.w3.org/1999/xhtml"><id></id><title></title><updated>2072-06-15T16:22:13Z</updated><entry><id>about:test:input1:entry1</id><title>ENTRY 1</title><updated>2002-12-25T07:08:43Z</updated><source><id>about:test:input1</id><title>Feed 1</title><updated>2002-12-16T00:55:23Z</updated><author><name>Feed Author Name</name></author></source></entry><entry xml:lang="en"><id>about:test:input1:entry2</id><title>ENTRY 2</title><updated>2002-12-22T23:35:23Z</updated><author><name>Entry2 Author</name><uri>http://entry2.test/</uri></author><source><id>about:test:input1</id><title>Feed 1</title><updated>2002-12-16T00:55:23Z</updated><author><name>Feed Author Name</name></author></source></entry></feed>];
} # _create_feed_from_feeds_one

sub _create_feed_from_feeds_two : Test(4) {
  my $input1 = Message::DOM::DOMImplementation->new->create_atom_feed_document
      (q<about:test:input1>, 'Feed 1');
  my $feed_el_1 = $input1->document_element;
  $feed_el_1->updated_element->value (1040000123);
  $feed_el_1->append_child ($input1->create_element_ns (ATOM_NS, 'author'))
      ->name ('Feed Author Name');
  $feed_el_1->add_new_entry
      (q<about:test:input1:entry1>, 'ENTRY 1')
          ->updated_element->value (1040800123);
  for my $entry_el ($feed_el_1->add_new_entry
                        (q<about:test:input1:entry2>, 'ENTRY 2', 'en')) {
    $entry_el->updated_element->value (1040600123);
    $_->name ('Entry2 Author'), $_->uri (q<http://entry2.test/>) for
    $entry_el->append_child ($input1->create_element_ns (ATOM_NS, 'author'));
  }

  my $input2 = Message::DOM::DOMImplementation->new->create_atom_feed_document
      (q<about:test:input2>, 'Feed 2');
  my $feed_el_2 = $input2->document_element;
  $feed_el_2->updated_element->value (1040000456);
  $feed_el_2->append_child ($input2->create_element_ns (ATOM_NS, 'author'))
      ->name ('Feed2 Author Name');
  $feed_el_2->add_new_entry
      (q<about:test:input2:entry2>, 'ENTRY 2-2')
          ->updated_element->value (1040800456);
  for my $entry_el ($feed_el_2->add_new_entry
                        (q<about:test:input1:entry2>, 'ENTRY 2', 'en')) {
    $entry_el->updated_element->value (1040600456);
    $_->name ('Entry2 Author'), $_->uri (q<http://entry2.test/>) for
    $entry_el->append_child ($input2->create_element_ns (ATOM_NS, 'author'));
  }

  my $doc = Whatpm::Atom::Aggregator->create_feed_from_feeds
      ({}, $input1, $input2);
  isa_ok $doc, 'Message::DOM::Document';
  
  my $de = $doc->document_element;
  isa_ok $de, 'Message::DOM::Element';
  
  is $de->local_name, 'feed';

  $doc->document_element->updated_element->value (3233233333);
  is $doc->inner_html, q[<feed xml:lang="" xmlns="http://www.w3.org/2005/Atom" xmlns:h="http://www.w3.org/1999/xhtml"><id></id><title></title><updated>2072-06-15T16:22:13Z</updated><entry><id>about:test:input2:entry2</id><title>ENTRY 2-2</title><updated>2002-12-25T07:14:16Z</updated><source><id>about:test:input2</id><title>Feed 2</title><updated>2002-12-16T01:00:56Z</updated><author><name>Feed2 Author Name</name></author></source></entry><entry><id>about:test:input1:entry1</id><title>ENTRY 1</title><updated>2002-12-25T07:08:43Z</updated><source><id>about:test:input1</id><title>Feed 1</title><updated>2002-12-16T00:55:23Z</updated><author><name>Feed Author Name</name></author></source></entry><entry xml:lang="en"><id>about:test:input1:entry2</id><title>ENTRY 2</title><updated>2002-12-22T23:40:56Z</updated><author><name>Entry2 Author</name><uri>http://entry2.test/</uri></author><source><id>about:test:input2</id><title>Feed 2</title><updated>2002-12-16T01:00:56Z</updated><author><name>Feed2 Author Name</name></author></source></entry></feed>];
} # _create_feed_from_feeds_two

sub _create_feed_from_feeds_title : Test(3) {
  my $doc = Whatpm::Atom::Aggregator->create_feed_from_feeds
      ({feed_id => q<URL>, feed_title => 'abc', feed_lang => 'ja'});
  isa_ok $doc, 'Message::DOM::Document';
  
  my $de = $doc->document_element;
  isa_ok $de, 'Message::DOM::Element';
  
  $doc->document_element->updated_element->value (3233233333);
  is $doc->inner_html, q[<feed xml:lang="ja" xmlns="http://www.w3.org/2005/Atom" xmlns:h="http://www.w3.org/1999/xhtml"><id>URL</id><title>abc</title><updated>2072-06-15T16:22:13Z</updated></feed>];
} # _create_feed_from_feeds_empty

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
