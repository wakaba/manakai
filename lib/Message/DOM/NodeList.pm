package Message::DOM::NodeList;
use strict;
use warnings;
our $VERSION = '2.0';
push our @ISA, 'Tie::Array', 'Message::IF::NodeList';
require Message::DOM::DOMException;
require Tie::Array;
use Carp;

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
    fallback => 1;

sub TIEARRAY ($$) { $_[1] }

sub STORE {
  croak "Modification of a read-only value attempted";
} # STORE

sub STORESIZE {
  croak "Modification of a read-only value attempted";
} # STORESIZE

sub to_list ($) {
  return (@{$_[0]});
} # to_list

sub to_a ($) {
  return [@{$_[0]}];
} # to_a

## For compatibility with Template::Iterator in Template Toolkit.
## Don't use for any ohter purpose.
sub as_list ($) {
  return $_[0]->to_a;
} # as_list

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

sub to_list ($) {
  return @{${$${$_[0]}}->{child_nodes}};
} # to_list

sub to_a ($) {
  return [@{${$${$_[0]}}->{child_nodes}}];
} # to_a

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

sub manakai_read_only ($) { 1 }

## |NodeList| methods

sub item ($$) { undef }

*FETCH = \&item;

sub to_list ($) {
  return ();
} # to_list

sub to_a ($) {
  return [];
} # to_a

package Message::DOM::NodeList::GetElementsList;
push our @ISA, 'Message::DOM::NodeList::EmptyNodeList';

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

sub length ($) {
  my $self = $_[0];
  my $r = 0;

  ## TODO: Improve!
  local $Error::Depth = $Error::Depth + 1;
  my @target = $$self->[0]->child_nodes->to_list;
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

sub to_list ($) {
  return (@{$_[0]});
} # to_list

sub to_a ($) {
  return [@{$_[0]}];
} # to_a

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

sub ____new_from_arrayref {
  my $list = bless $_[1], $_[0];
  Internals::SvREADONLY (@$list, 1);
  Internals::SvREADONLY ($_, 1) for @$list;
  return $list;
} # ____new_from_arrayref

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

sub to_a ($) {
  return [@{$_[0]}];
} # to_a

sub to_list ($) {
  return @{$_[0]};
} # to_list

sub as_list ($) {
  return [@{$_[0]}];
} # as_list

package Message::IF::NodeList;

package Message::IF::StaticNodeList;
push our @ISA, 'Message::IF::NodeList';

1;

=head1 LICENSE

Copyright 2007-2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
