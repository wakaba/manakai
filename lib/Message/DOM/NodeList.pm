package Message::DOM::NodeList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Tie::Array', 'Message::IF::NodeList';
require Message::DOM::DOMException;
require Tie::Array;

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
      ## NOTE: Same as |StaticNodeList|'s.
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

## NOTE: |Message::DOM::CSSRuleList| has similar codes to this package.

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
    ## ISSUE: This might not work if new_child is a sibling of ref_child
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
  for (my @a = @$list) {
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

package Message::DOM::NodeList::GetElementsList;
push our @ISA, 'Message::DOM::NodeList::EmptyNodeList';

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |NodeList| attributes

sub length ($) {
  my $self = $_[0];
  my $r = 0;

  ## TODO: Improve!
  local $Error::Depth = $Error::Depth + 1;
  my @target = @{$$self->[0]->child_nodes};
  while (@target) {
    my $target = shift @target;
    if ($target->node_type == 1) { # ELEMENT_NODE
      if ($$self->[1]->($target)) {
        $r++;
      }
    }
    unshift @target, @{$target->child_nodes};
  }

  return $r;
} # length
*FETCHSIZE = \&length;

## |NodeList| methods

sub item ($;$) {
  my $self = $_[0];
  my $index = 0+($_[1] or 0);

  ## TODO: Improve!
  local $Error::Depth = $Error::Depth + 1;
  my @target = @{$$self->[0]->child_nodes};
  my $i = -1;
  while (@target) {
    my $target = shift @target;
    if ($target->node_type == 1) { # ELEMENT_NODE
      if ($$self->[1]->($target)) {
        if (++$i == $index) {
          return $target;
        }
      }
    }
    unshift @target, @{$target->child_nodes};
  }

  return undef;
} # item
*FETCH = \&item;

sub EXISTS ($$) {
  return defined $_[0]->item ($_[1]);
} # EXISTS

package Message::DOM::NodeList::StaticNodeList;
push our @ISA, 'Message::IF::StaticNodeList';

use overload
    '==' => sub {
      ## NOTE: Same as |NodeList|'s.
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

## |NodeList| attributes

sub length ($) {
  return scalar @{$_[0]};
} # length

sub manakai_read_only () { 0 }

## |NodeList| methods

sub item ($;$) {
  my $index = int ($_[1] or 0);
  return $_[0]->[$index] if $index >= 0;
} # item

package Message::IF::NodeList;

package Message::IF::StaticNodeList;
push our @ISA, 'Message::IF::NodeList';

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/12/22 06:29:32 $
