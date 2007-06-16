package Message::DOM::NodeList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::NodeList';
require Message::DOM::DOMException;

use overload
    '@{}' => sub {
      tie my @list, ref $_[0], $_[0];
      return \@list;
    },
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::NodeList');
      return $${$_[0]} eq $${$_[1]};
    },
    ne => sub {
      return not ($_[0] eq $_[1]);
    },
    '==' => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::IF::NodeList');
      
      local $Error::Depth = $Error::Depth + 1;
      my $l1 = $_[0]->length;
      my $l2 = $_[1]->length;
      return 0 unless $l1 == $l2;
      
      for my $i (0 .. ($l1-1)) {
        return 0 unless $_[0]->item ($i) == $_[1]->item ($i);
      }
      
      return 1;
    },
    '!=' => sub {
      return not ($_[0] == $_[1]);
    },
    fallback => 1;

sub TIEARRAY ($$) { $_[1] }

package Message::DOM::NodeList::ChildNodeList;
push our @ISA, 'Message::DOM::NodeList';

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |NodeList| attributes

sub EXISTS ($$) {
  return exists ${$${$_[0]}}->{child_nodes}->[$_[1]];
} # EXISTS

sub length ($) {
  return scalar @{${$${$_[0]}}->{child_nodes}};
} # length

*FETCHSIZE = \&length;

sub STORESIZE ($$) {
  my $node = $${$_[0]};
  my $list = $$node->{child_nodes};
  my $current_length = @{$list};
  my $count = $_[1];

  local $Error::Depth = $Error::Depth + 1;
  if ($current_length > $count) {
    for (my $i = $current_length - 1; $i >= $count; $i--) {
      $node->remove_child ($list->[$i]);
    }
  }
} # STORESIZE

sub manakai_read_only ($) {
  local $Error::Depth = $Error::Depth + 1;
  return $${$_[0]}->manakai_read_only;
} # manakai_read_only

## |NodeList| methods

sub item ($$) {
  my $index = 0+$_[1];
  return undef if $index < 0;
  return ${$${$_[0]}}->{child_nodes}->[$index];
} # item

sub FETCH ($$) {
  return ${$${$_[0]}}->{child_nodes}->[$_[1]];
} # FETCH

sub STORE ($$$) {
  my $self = $_[0];
  my $list = ${$$$self}->{child_nodes};
  my $index = $_[1];
           
  local $Error::Depth = $Error::Depth + 1;
  if (exists $list->[$index]) {
    $$$self->replace_child ($_[2], $list->[$index]);
  } else {
    $$$self->append_child ($_[2]);
  }
} # STORE

sub DELETE ($$) {
  my $self = $_[0];
  my $list = ${$$$self}->{child_nodes};
  my $index = $_[1];

  if (exists $list->[$index]) {
    local $Error::Depth = $Error::Depth + 1;
    return $$$self->remove_child ($list->[$index]);
  } else {
    return undef;
  }
} # DELETE

sub CLEAR ($) {
  my $self = $_[0];
  my $list = ${$$$self}->{child_nodes};

  local $Error::Depth = $Error::Depth + 1;
  for (@$list) {
    $$$self->remove_child ($_);
  }
} # CLEAR

package Message::DOM::NodeList::EmptyNodeList;
push our @ISA, 'Message::DOM::NodeList';

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |NodeList| attributes

sub EXISTS ($$) { 0 }

sub length ($) { 0 }

*FETCHSIZE = \&length;

sub STORESIZE ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'NO_MODIFICATION_ALLOWED_ERR',
      -subtype => 'READ_ONLY_NODE_LIST_ERR'
      unless $_[1] == 0;
} # STORESIZE

sub manakai_read_only ($) { 1 }

## |NodeList| methods

sub item ($$) { undef }

*FETCH = \&item;

sub STORE ($$$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'NO_MODIFICATION_ALLOWED_ERR',
      -subtype => 'READ_ONLY_NODE_LIST_ERR';
} # STORE

*DELETE = \&STORE;

*CLEAR = \&STORE;

package Message::IF::NodeList;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/16 08:05:48 $
