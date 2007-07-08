package Message::DOM::Text;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::CharacterData', 'Message::IF::Text';
require Message::DOM::DOMCharacterData; ## TODO: Change to new module name

## |Node| attributes

sub node_name () { '#text' }

sub node_type () { 3 } # TEXT_NODE

## |Text| attributes

sub is_element_content_whitespace ($;$) {
  if (@_ > 1) {
    ## TODO: Document how setter work
    if (${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if ($_[1]) {
      ${$_[0]}->{is_element_content_whitespace} = 1;
    } else {
      delete ${$_[0]}->{is_element_content_whitespace};
    }
  }
  return ${$_[0]}->{is_element_content_whitespace};
} # is_element_content_whitespace

sub whole_text ($) {
  require Message::DOM::Traversal;
  local $Error::Depth = $Error::Depth + 1;
  my $doc = $_[0]->owner_document;
  my $tw1 = $doc->create_tree_walker
      ($doc, 0xFFFFFFFF, sub { # SHOW_ALL ENTITY_REFERENCE_NODE
        ($_[1]->node_type == 5) ? 3 : 1; # FILTER_SKIP FILTER_ACCEPT
      }, 1);
  $tw1->current_node ($_[0]);
  
  my $tw2 = $tw1->clone;
  my $r = $_[0]->node_value;

  S: while (defined (my $node = $tw1->previous_sibling)) {
    my $nt = $node->node_type;
    if ($nt == 3 or $nt == 4) { # TEXT_NODE CDATA_SECTION_NODE
      $r = $node->node_value . $r;
    } else {
      last S;
    }
  } # S

  S: while (defined (my $node = $tw2->next_sibling)) {
    my $nt = $node->node_type;
    if ($nt == 3 or $nt == 4) { # TEXT_NODE CDATA_SECTION_NODE
      $r .= $node->node_value;
    } else {
      last S;
    }
  } # S

  return $r;

  ## TODO: Skipping |DocumentType| is manakai-extension.  Document it!
} # whole_text

## |Text| methods

sub split_text ($;$) {
  my $parent = $_[0]->parent_node;
  if (${${$_[0]}->{owner_document}}->{strict_error_checking}) {
    if (${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if (defined $parent and $$parent->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
  }

  require Message::DOM::StringExtended;
  local $Error::Depth = $Error::Depth + 1;
  my $offset32 = Message::DOM::StringExtended::find_offset32
      (${$_[0]}->{data}, $_[1]);
  my $data2 = substr ${$_[0]}->{data}, $offset32;

  my $r = $_[0]->node_type == 3 # TEXT_NODE
      ? ${$_[0]}->{owner_document}->create_text_node ($data2)
      : ${$_[0]}->{owner_document}->create_cdata_section ($data2);
  $r->is_element_content_whitespace ($_[0]->is_element_content_whitespace);
  substr (${$_[0]}->{data}, $offset32) = '';

  if (defined $parent) {
    $parent->insert_before ($r, $_[0]->next_sibling);
  }

  return $r;
} # split_text

package Message::IF::Text;

package Message::DOM::Document;

sub create_text_node ($$) {
  return Message::DOM::Text->____new ($_[0], $_[1]);
} # create_text_node

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 13:04:37 $
