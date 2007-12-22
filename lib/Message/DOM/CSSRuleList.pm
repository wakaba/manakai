package Message::DOM::CSSRuleList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Tie::Array', 'Message::IF::CSSRuleList';
require Tie::Array;

## ISSUE: The CSSOM ED does not mention to the possible read-only flag
## of |CSSRuleList| objects.  The current implementation does not support
## the flag.  The flag might be necessary to support CSS style sheet
## as presented as <style> element in an XML parsed entity.

## |CSSRuleList| attributes

use overload
    '@{}' => sub {
      tie my @list, ref $_[0], $_[0];
      return \@list;
    },
    fallback => 1;

sub TIEARRAY ($$) { $_[1] }

## NOTE: |Message::DOM::NodeList::ChildNodeList| has similar codes
## to this package.

## TODO: Perl binding documentation.

sub EXISTS ($$) {
  return exists ${$${$_[0]}}->{css_rules}->[$_[1]];
} # EXISTS

sub length ($) {
  return scalar @{${$${$_[0]}}->{css_rules}};
} # length

*FETCHSIZE = \&length;

sub STORESIZE ($$) {
  my $node = $${$_[0]};
  my $list = $$node->{css_rules};
  my $current_length = @{$list};
  my $count = $_[1];

  local $Error::Depth = $Error::Depth + 1;
  if ($current_length > $count) {
    for (my $i = $current_length - 1; $i >= $count; $i--) {
      $node->delete_rule ($i);
    }
  }
} # STORESIZE

## |CSSRuleList| methods

sub item ($$) {
  my $index = 0+$_[1];
  return undef if $index < 0;
  return ${$${$_[0]}}->{css_rules}->[$index];
} # item

sub FETCH ($$) {
  return ${$${$_[0]}}->{css_rules}->[$_[1]];
} # FETCH

sub STORE ($$$) {
  ## TODO: More Perl'ish message should be raised
  die "Can't modify the array";
} # STORE

sub DELETE ($$) {
  my $self = $_[0];
  my $list = ${$$$self}->{child_nodes};
  my $index = $_[1];

  if (exists $list->[$index]) {
    local $Error::Depth = $Error::Depth + 1;
    return $$$self->delete_rule ($index);
  } else {
    return undef;
  }
} # DELETE

package Message::IF::CSSRuleList;

1;
## $Date: 2007/12/22 06:29:32 $
