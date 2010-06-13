package Whatpm::Atom::Aggregator;
use strict;
use warnings;
our $VERSION = '1.0';

sub ATOM_NS () { q<http://www.w3.org/2005/Atom> }
sub XMLNS_NS () { q<http://www.w3.org/2000/xmlns/> }
sub HTML_NS () { q<http://www.w3.org/1999/xhtml> }

## Spec: <http://tools.ietf.org/html/rfc4287#section-4.2.11>.

my $CopiedElements = {
  author => 1,
  category => 1,
  contributor => 1,
  id => 1,
  rights => 1,
  title => 1,
  updated => 1,
};

sub create_feed_from_feeds ($$@) {
  my ($class, $args, @feed) = @_;
  
  require Message::DOM::DOMImplementation;
  my $dom = Message::DOM::DOMImplementation->new;

  my $new_doc = $dom->create_atom_feed_document
      ($args->{feed_id},
       $args->{feed_title},
       $args->{feed_lang});
  my $new_feed_el = $new_doc->document_element;
  $new_feed_el->set_attribute_ns (XMLNS_NS, q<xmlns>, ATOM_NS);
  $new_feed_el->set_attribute_ns (XMLNS_NS, q<xmlns:h>, HTML_NS);

  for my $old_doc (@feed) {
    my $old_feed_el = $old_doc->document_element;
    next unless $old_feed_el->can ('entry_elements');

    my @source_meta_el;
    for my $old_feed_meta_el (@{$old_feed_el->child_nodes}) {
      next unless $old_feed_meta_el->node_type == 1;
      next unless ($old_feed_meta_el->namespace_uri // '') eq ATOM_NS;
      if ($CopiedElements->{$old_feed_meta_el->manakai_local_name}) {
        push @source_meta_el, $old_feed_meta_el;
      }
    }

    @source_meta_el
        = map { $new_doc->adopt_node ($_->clone_node (1)) }
            @source_meta_el;

    no warnings; ## I don't understand why this is necessary.
    for my $old_entry_el (@{$old_feed_el->entry_elements}) {
      my $new_entry_el = $old_entry_el->clone_node (1);
      $new_doc->adopt_node ($new_entry_el);
      $new_feed_el->append_child ($new_entry_el);

      if (@source_meta_el) {
        my $source_el = $new_doc->create_element_ns (ATOM_NS, 'source');
        $source_el->append_child ($_->clone_node (1)) for @source_meta_el;
        $new_entry_el->append_child ($source_el);
      }
    }
  }

  my $added_id = {};
  for my $entry_el (map { $_->[0] }
                    sort { $b->[1] <=> $a->[1] }
                    map { $_->[1] = $_->[1] ? $_->[1]->value : 0; $_ }
                    map { [$_, $_->updated_element] }
                    @{$new_feed_el->entry_elements}) {
    my $id = $entry_el->id;
    if (defined $id and length $id and $added_id->{$id}) {
      $new_feed_el->remove_child ($entry_el);
    } else {
      $new_feed_el->append_child ($entry_el);
      $added_id->{$id} = 1;
    }
  }

  return $new_doc;
} # create_feed_from_feeds

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
