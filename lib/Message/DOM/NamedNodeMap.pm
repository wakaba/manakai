package Message::DOM::NamedNodeMap;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::NamedNodeMap';
require Message::DOM::DOMException;
require Tie::Array;

use overload
    '@{}' => sub {
      tie my @list, (ref $_[0]) . '::Array', $_[0];
      return \@list;
    },
    '%{}' => sub {
      tie my %list, ref $_[0], $_[0];
      return \%list;
    },
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::NamedNodeMap');
      return 0 if $_[1]->isa ('Message::DOM::NamedNodeMap::ArrayMap');
      return (${$_[0]}->[0] eq ${$_[1]}->[0] and ${$_[0]}->[1] eq ${$_[1]}->[1]);
    },
    ne => sub {
      return not ($_[0] eq $_[1]);
    },
    '==' => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::IF::NamedNodeMap');
      
      local $Error::Depth = $Error::Depth + 1;
      my $length1 = @{$_[0]};
      my $length2 = @{$_[1]};
      return 0 if $length1 != $length2;

      for my $i (0..($length1 - 1)) {
        my $node1 = $_[0]->[$i];
        my $node2 = $_[1]->[$i];
        return 0 if $node1 != $node2;
      }
      ## TODO: This ordering is only assumed in manakai...

      return 1;
    },
    '!=' => sub {
      return not ($_[0] == $_[1]);
    },
    fallback => 1;

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |NamedNodeMap| attributes

sub length ($) {
  return scalar @{[map {$_} values %{${${$_[0]}->[0]}->{${$_[0]}->[1]}}]};
} # length

sub manakai_read_only ($) {
  return ${${$_[0]}->[0]}->{manakai_read_only};
} # manakai_read_only

## |NamedNodeMap| methods

sub get_named_item ($$) {
  return ${${$_[0]}->[0]}->{${$_[0]}->[1]}->{$_[1]};
} # get_named_item
*FETCH = \&get_named_item;

sub get_named_item_ns ($$$) { }

sub item ($$) {
  my $index = 0+$_[1];
  my $list = ${${$_[0]}->[0]}->{${$_[0]}->[1]};

  my $key = $index >= 0 ? [sort {$a cmp $b} keys %$list]->[$index] : undef;
  if (defined $key and defined $list->{$key}) {
    return $list->{$key};
  } else {
    return undef;
  }
} # item

sub remove_named_item ($$) {
  my $name = ''.$_[1];
  my $list = ${${$_[0]}->[0]}->{${$_[0]}->[1]};

  my $od = ${${$_[0]}->[0]}->{owner_document}; # might be undef, but no problem

  my $key = ${$_[0]}->[1] eq 'attribute_definitions'
      ? 'owner_element_type_definition' : 'owner_document_type_definition';

  if ($$od->{strict_error_checking}) {
    if (${${$_[0]}->[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
  }

  if (defined $list->{$name}) {
    my $r = $list->{$name};
    delete $$r->{$key};
    delete $list->{$name};
    return $r;
  } else {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  }
} # remove_named_item

sub remove_named_item_ns ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'NOT_FOUND_ERR',
      -subtype => 'NOT_CHILD_ERR';
} # remove_named_item_ns

sub DELETE ($$) {
  my $r;
  try {
    $r = $_[0]->remove_named_item ($_[1]);
  } catch Message::DOM::DOMException with {
    my $err = shift;
    unless ($err->subtype eq 'NOT_CHILD_ERR') {
      $err->throw;
    }
  };
  return $r; ## TODO: This return value is ok?
} # DELETE

sub set_named_item ($$) {
  my $od = ${${$_[0]}->[0]}->{owner_document};
  if (not defined $od or
      $od ne ($_[1]->owner_document || $_[1])) {
    ## TODO: $od not defined case is manakai extension.  Document it!
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'WRONG_DOCUMENT_ERR',
        -subtype => 'EXTERNAL_OBJECT_ERR';
  }

  my $key = ${$_[0]}->[1] eq 'attribute_definitions'
      ? 'owner_element_type_definition' : 'owner_document_type_definition';

  if ($$od->{strict_error_checking}) {
    if ($_[1]->node_type !=
        {
         element_types => 81001, # ELEMENT_TYPE_DEFINITION_NODE
         attribute_definitions => 81002, # ATTRIBUTE_DEFINITION_NODE
         entities => 6, # ENTITY_NODE
         notations => 12, # NOTATION_NODE
        }->{${$_[0]}->[1]}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'HIERARCHY_REQUEST_ERR',
          -subtype => 'CHILD_NODE_TYPE_ERR';
    }

    if (${${$_[0]}->[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if (${$_[1]}->{$key} and not ${$_[1]}->{$key} eq ${$_[0]}->[0]) {
      ## TODO: This is manakai extension.  Document it!
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'HIERARCHY_REQUEST_ERR',
          -subtype => 'INUSE_DEFINITION_ERR';
    }
  }

  my $name = $_[1]->node_name;
  my $list = ${${$_[0]}->[0]}->{${$_[0]}->[1]};
  if (defined $list->{$name}) {
    my $r = $list->{$name};
    if ($r eq $_[1]) {
      ## NOTE: Replace by itself (implementation dependent).
      return undef;
    } else {
      $list->{$name} = $_[1];
      ${$_[1]}->{$key} = ${$_[0]}->[0];
      Scalar::Util::weaken (${$_[1]}->{$key});
      delete $$r->{$key};
      return $r;
    }
  } else {
    $list->{$name} = $_[1];
    ${$_[1]}->{$key} = ${$_[0]}->[0];
    Scalar::Util::weaken (${$_[1]}->{$key});
    return undef;
  }
} # set_named_item

sub set_named_item_ns ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # set_named_item_ns

sub EXISTS ($$) {
  return exists ${${$_[0]}->[0]}->{${$_[0]}->[1]}->{$_[1]};
} # EXISTS

sub FIRSTKEY ($) {
  my $list = ${${$_[0]}->[0]}->{${$_[0]}->[1]};
  my $a = keys %$list; # reset
  return each %$list;
} # FIRSTKEY

sub NEXTKEY ($) {
  return each %{${${$_[0]}->[0]}->{${$_[0]}->[1]}};
} # NEXTKEY

sub SCALAR ($) {
  return scalar %{${${$_[0]}->[0]}->{${$_[0]}->[1]}};
} # SCALAR

package Message::DOM::NamedNodeMap::Array;
push our @ISA, 'Tie::Array';

sub DELETE ($$) {
  my $item = $_[0]->item ($_[1]);
  if ($item) {
    local $Error::Depth = $Error::Depth + 1;
    return $_[0]->remove_named_item ($item->node_name);
  } else {
    return undef;
  }
} # DELETE

sub EXISTS ($$) {
  return ($_[1] < $_[0]->length);
} # EXISTS

*FETCH = \&Message::DOM::NamedNodeMap::item;

*FETCHSIZE = \&Message::DOM::NamedNodeMap::length;

## TODO: |STORE|

sub STORESIZE ($) {
  local $Error::Depth = $Error::Depth + 1;
  my $length = $_[0]->length;
  if ($length > $_[1]) {
    for (my $i = $length - 1; $i >= $_[1]; $i--) {
      my $item = $_[0]->item ($i);
      $_[0]->remove_named_item ($item->node_name);
    }
  }
} # STORESIZE

sub TIEARRAY ($$) { bless \[${$_[1]}->[0], ${$_[1]}->[1]], __PACKAGE__ }

package Message::DOM::NamedNodeMap::AttrMap;
push our @ISA, 'Message::DOM::NamedNodeMap';

use overload
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::NamedNodeMap');
      return $${$_[0]} eq $${$_[1]};
    },
    fallback => 1;

## |NamedNodeMap| attributes

sub length ($) {
  my $list = ${$${$_[0]}}->{manakai_content_attribute_list};
  if (defined $list) {
    return scalar @$list;
  } else {
    $list = ${$${$_[0]}}->{attributes};
    my $r = 0;
    for my $l (values %$list) {
      $r += grep {$l->{$_}} keys %$l;
    }
    return $r;
  }
} # length

sub manakai_read_only ($) {
  return ${$${$_[0]}}->{manakai_read_only};
} # manakai_read_only

## |NamedNodeMap| methods

sub get_named_item ($$) {
  local $Error::Depth = $Error::Depth + 1;
  return $${$_[0]}->get_attribute_node ($_[1]);
} # get_named_item
*FETCH = \&get_named_item;

sub get_named_item_ns ($$$) {
  local $Error::Depth = $Error::Depth + 1;
  return $${$_[0]}->get_attribute_node_ns ($_[1], $_[2]);
} # get_named_item_ns

sub item ($$) {
  ## Update the sorted content attribute name list
  my $list = ${$${$_[0]}}->{manakai_content_attribute_list};
  my $attrs = ${$${$_[0]}}->{attributes};
  unless (defined $list) {
    $list = [];
    for my $ns (sort {$a cmp $b} keys %{$attrs}) {
      push @$list, map {[$ns => $_]} sort {$a cmp $b} keys %{$attrs->{$ns}};
    }
    ${$${$_[0]}}->{manakai_content_attribute_list} = $list;
  }

  my $index = 0+$_[1];
  return $attrs->{$list->[$index]->[0]}->{$list->[$index]->[1]};
} # item

sub remove_named_item ($$) {
  my $el = $${$_[0]};
  local $Error::Depth = $Error::Depth + 1;
  my $node = $el->get_attribute_node ($_[1]);
  unless ($node) {
    local $Error::Depth = $Error::Depth - 1;
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  }
  return $el->remove_attribute_node ($node);
} # remove_named_item

sub remove_named_item_ns ($$) {
  my $el = $${$_[0]};
  local $Error::Depth = $Error::Depth + 1;
  my $node = $el->get_attribute_node_ns ($_[1], $_[2]);
  unless ($node) {
    local $Error::Depth = $Error::Depth - 1;
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  }
  return $el->remove_attribute_node ($node);
} # remove_named_item_ns

sub set_named_item ($$) {
  if ($_[1]->node_type != 2) { # ATTRIBUTE_NODE
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'HIERARCHY_REQUEST_ERR',
        -subtype => 'CHILD_NODE_TYPE_ERR';
  }

  local $Error::Depth = $Error::Depth + 1;
  return $${$_[0]}->set_attribute_node ($_[1]);
} # set_named_item

sub set_named_item_ns ($$) {
  if ($_[1]->node_type != 2) { # ATTRIBUTE_NODE
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'HIERARCHY_REQUEST_ERR',
        -subtype => 'CHILD_NODE_TYPE_ERR';
  }

  local $Error::Depth = $Error::Depth + 1;
  return $${$_[0]}->set_attribute_node_ns ($_[1]);
} # set_named_item_ns

sub EXISTS ($$) {
  local $Error::Depth = $Error::Depth + 1;
  return defined ($_[0]->get_named_item ($_[1]));
} # EXISTS

sub FIRSTKEY ($) {
  local $Error::Depth = $Error::Depth + 1;
  my $node = $_[0]->item (0);
  ${$${$_[0]}}->{manakai_hash_position} = 1;
  return $node ? $node->node_name : undef;
} # FIRSTKEY

sub NEXTKEY ($) {
  my $i = ${$${$_[0]}}->{manakai_hash_position}++;
  my $node = $_[0]->item ($i);
  return $node ? $node->node_name : undef;
} # NEXTKEY

sub SCALAR ($) {
  local $Error::Depth = $Error::Depth + 1;
  return $${$_[0]}->has_attributes;
} # SCALAR

package Message::DOM::NamedNodeMap::AttrMap::Array;
push our @ISA, 'Tie::Array';

sub DELETE ($$) {
  my $item = $_[0]->item ($_[1]);
  if ($item) {
    local $Error::Depth = $Error::Depth + 1;
    return $_[0]->remove_named_item_ns
        ($item->namespace_uri, $item->manakai_local_name);
  } else {
    return undef;
  }
} # DELETE

sub EXISTS ($$) {
  return ($_[1] < $_[0]->length);
} # EXISTS

*FETCH = \&Message::DOM::NamedNodeMap::AttrMap::item;

*FETCHSIZE = \&Message::DOM::NamedNodeMap::AttrMap::length;

sub STORESIZE ($) {
  local $Error::Depth = $Error::Depth + 1;
  my $length = $_[0]->length;
  if ($length > $_[1]) {
    for (my $i = $length - 1; $i >= $_[1]; $i--) {
      my $item = $_[0]->item ($i);
      $_[0]->remove_named_item_ns
          ($item->namespace_uri, $item->manakai_local_name);
    }
  }
} # STORESIZE

sub TIEARRAY ($$) { bless \\$${$_[1]}, __PACKAGE__ }

package Message::IF::NamedNodeMap;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 07:59:02 $
