#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 38 } 

require Message::DOM::DOMImplementation;

my $impl = Message::DOM::DOMImplementation->new;

## |AtomDOMImplementation|
ok $impl->isa ('Message::IF::AtomDOMImplementation') ? 1 : 0, 1,
    'AtomDOMImplementation interface';
ok $impl->can ('create_atom_entry_document') ? 1 : 0, 1, 'ADI->create_aed';
ok $impl->can ('create_atom_feed_document') ? 1 : 0, 1, 'ADI->create_afd';

my $ATOM_NS = q<http://www.w3.org/2005/Atom>;
my $CCE = q<http://suika.fam.cx/www/2006/dom-config/create-child-element>;

## |createAtomFeedDocument|, |createAtomEntryDocument|
for my $m (
  [feed => 'create_atom_feed_document'],
  [entry => 'create_atom_entry_document'],
) {
  my $mn = $m->[1];
  my $doc = $impl->$mn ('about:id', 'feed title', 'en');
  for (
       'Message::IF::Node',
       'Message::IF::Document',
      ) {
    ok $doc->isa ($_) ? 1 : 0, 1, $mn.' [1] interface '.$_;
  }

  ok $doc->xml_version, '1.0', $mn.' [1] xml_version';

  my $feed = $doc->document_element;
  ok $feed->namespace_uri, $ATOM_NS, $mn.' [1] namespace_uri';
  ok $feed->manakai_local_name, $m->[0], $mn.' [1] local_name';
  ok $feed->get_attribute_ns (q<http://www.w3.org/XML/1998/namespace>, 'lang'),
      'en', $mn.' [1] lang';

  my $id;
  my $title;
  my $updated;
  for my $cn (@{$feed->child_nodes}) {
    if ($cn->node_type == 1 and # ELEMENT_NODE
        $cn->namespace_uri eq $ATOM_NS) {
      if ($cn->manakai_local_name eq 'id') {
        $id = $cn;
      } elsif ($cn->manakai_local_name eq 'title') {
        $title = $cn;
      } elsif ($cn->manakai_local_name eq 'updated') {
        $updated = $cn;
      }
    }
  }

  ok defined $id ? 1 : 0, 1, $mn.' [1] id';
  ok $id->text_content, 'about:id', $mn.' [1] id.text_content';
  ok defined $title ? 1 : 0, 1, $mn.' [1] title';
  ok $title->text_content, 'feed title', $mn.' [1] title.text_content';
  ok $title->get_attribute_ns (undef, 'type'), undef, $mn.' [1] title@type';
  ok defined $updated ? 1 : 0, 1, $mn.' [1] updated';
  ok $updated->value > 0 ? 1 : 0, 1, $mn.' [1] updated.value';
}

## |AtomTextConstructor| |container|
{
  my $doc = $impl->create_document;
  my $el = $doc->create_element_ns ($ATOM_NS, 'title');

  ok $el->container, $el, 'AtomTextConstructor->container #IMPLIED';

  $el->type ('text');
  ok $el->container, $el, 'AtomTextConstructor->container text';

  $el->type ('html');
  ok $el->container, $el, 'AtomTextConstructor->container html';

  $el->type ('xhtml');
  ok $el->container, undef, 'AtomTextConstructor->container xhtml';

  $doc->dom_config->set_parameter ($CCE => 1);
  my $con = $el->container;
  ok $el ne $con ? 1 : 0, 1, 'AtomTextConstructor->container xhtml container';
  ok $con->parent_node, $el, 'ATC->container xhtml container parentNode';
  ok $con->namespace_uri, q<http://www.w3.org/1999/xhtml>,
      'ATC->container xhtml container namespaceURI';
  ok $con->manakai_local_name, 'div', 'ATC->container xhtml container ln';

  ok $el->container, $con, 'ATC->container xhtml container [2]';
}

## TODO: 

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/29 07:46:50 $
