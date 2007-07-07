#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 68 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

{
  my $at = $doc->create_attribute_definition ('ad');
  my $list = $at->allowed_tokens;

  ## length (0)
  ok 0+@$list, 0, 'DOMStringList @{} 0+ [0]';
  ok $list->length, 0, 'DOMStringList->length [0]';

  ## PUSH
  push @$list, 'String1';

  ## length (1)
  ok 0+@$list, 1, 'DOMStringList @{} 0+ [1]';
  ok $list->length, 1, 'DOMStringList->length [1]';

  ## FETCH
  ok $list->[0], 'String1', 'DOMStringList->[0] [1]';
  ok $list->item (0), 'String1', 'DOMStringList->item (0) [1]';

  ## PUSH
  push @$list, 'String2';

  ## length (2)
  ok 0+@$list, 2, 'DOMStringList @{} 0+ [2]';
  ok $list->length, 2, 'DOMStringList->length [2]';

  ## FETCH
  ok $list->[1], 'String2', 'DOMStringList->[1] [2]';
  ok $list->item (1), 'String2', 'DOMStringList->item (1) [2]';
  
  ## EXISTS
  ok exists $list->[0] ? 1 : 0, 1, 'DOMStringList exists 0 [2]';
  ok exists $list->[1] ? 1 : 0, 1, 'DOMStringList exists 1 [2]';
  ok exists $list->[2] ? 1 : 0, 0, 'DOMStringList exists 2 [2]';
  ok exists $list->[3] ? 1 : 0, 0, 'DOMStringList exists 3 [2]';

  ## DELETE
  delete $list->[0];
    
  ## FETCHSIZE
  ok 0+@$list, 1, 'DOMStringList @{} 0+ [3]';

  ## EXISTS
  ok exists $list->[0] ? 1 : 0, 1, 'DOMStringList exists 0 [3]';
  ok exists $list->[1] ? 1 : 0, 0, 'DOMStringList exists 1 [3]';
  ok exists $list->[2] ? 1 : 0, 0, 'DOMStringList exists 2 [3]';
  ok exists $list->[3] ? 1 : 0, 0, 'DOMStringList exists 3 [3]';

  ## FETCH
  ok $list->[0], 'String2', 'DOMStringList->[0] [3]';
  ok $list->[1], undef, 'DOMStringList->[1] [3]';
  
  ## STORE
  $list->[0] = 'String3';

  ## FETCH
  ok $list->[0], 'String3', 'DOMStringList->[0] [4]';
  ok $list->[1], undef, 'DOMStringList->[1] [4]';
 
  ## STORE
  $list->[1] = 'String4';
  ok $list->[0], 'String3', 'DOMStringList->[0] [5]';
  ok $list->[1], 'String4', 'DOMStringList->[1] [5]';

  $list->[2] = 'String5';
  ok $list->[0], 'String3', 'DOMStringList->[0] [6]';
  ok $list->[1], 'String4', 'DOMStringList->[1] [6]';
  ok $list->[2], 'String5', 'DOMStringList->[2] [6]';
  ok 0+@$list, 3, 'DOMStringList @{} 0+ [6]';

  ## contains
  ok $list->contains ('String1') ? 1 : 0, 0, 'DOMStringList contains 1 [6]';
  ok $list->contains ('String2') ? 1 : 0, 0, 'DOMStringList contains 2 [6]';
  ok $list->contains ('String3') ? 1 : 0, 1, 'DOMStringList contains 3 [6]';
  ok $list->contains ('String4') ? 1 : 0, 1, 'DOMStringList contains 4 [6]';
  ok $list->contains ('String5') ? 1 : 0, 1, 'DOMStringList contains 5 [6]';

  ## DELETE
  delete $list->[2];
  ok exists $list->[0] ? 1 : 0, 1, 'DOMStringList exists 0 [7]';
  ok exists $list->[1] ? 1 : 0, 1, 'DOMStringList exists 1 [7]';
  ok exists $list->[2] ? 1 : 0, 0, 'DOMStringList exists 2 [7]';
  ok exists $list->[3] ? 1 : 0, 0, 'DOMStringList exists 3 [7]';
  ok exists $list->[4] ? 1 : 0, 0, 'DOMStringList exists 4 [7]';
  ok 0+@$list, 2, 'DOMStringList @{} 0+ [7]';
}

{
  my $at1 = $doc->create_attribute_definition ('ad');
  my $list1 = $at1->allowed_tokens;
  my $at2 = $doc->create_attribute_definition ('ad');
  my $list2 = $at2->allowed_tokens;

  ok $list1 == $list1 ? 1 : 0, 1, 'a == a [0]';
  ok $list1 != $list1 ? 1 : 0, 0, 'a != a [0]';
  ok $list1 eq $list1 ? 1 : 0, 1, 'a eq a [0]';
  ok $list1 ne $list1 ? 1 : 0, 0, 'a ne a [0]';
  ok $list1 == $list2 ? 1 : 0, 1, 'a == b [0]';
  ok $list1 != $list2 ? 1 : 0, 0, 'a != b [0]';
  ok $list1 eq $list2 ? 1 : 0, 0, 'a eq b [0]';
  ok $list1 ne $list2 ? 1 : 0, 1, 'a ne b [0]';

  push @$list1, '';
  push @$list2, '';
  ok $list1 == $list2 ? 1 : 0, 1, 'a == b [1]';
  ok $list1 != $list2 ? 1 : 0, 0, 'a != b [1]';
  ok $list1 eq $list2 ? 1 : 0, 0, 'a eq b [1]';
  ok $list1 ne $list2 ? 1 : 0, 1, 'a ne b [1]';

  push @$list1, 'str';
  push @$list2, 'str';
  ok $list1 == $list2 ? 1 : 0, 1, 'a == b [2]';
  ok $list1 != $list2 ? 1 : 0, 0, 'a != b [2]';
  ok $list1 eq $list2 ? 1 : 0, 0, 'a eq b [2]';
  ok $list1 ne $list2 ? 1 : 0, 1, 'a ne b [2]';

  push @$list1, 'a';
  ok $list1 == $list2 ? 1 : 0, 0, 'a == b [2]';
  ok $list1 != $list2 ? 1 : 0, 1, 'a != b [2]';
  ok $list1 eq $list2 ? 1 : 0, 0, 'a eq b [2]';
  ok $list1 ne $list2 ? 1 : 0, 1, 'a ne b [2]';

  push @$list2, 'b';
  ok $list1 == $list2 ? 1 : 0, 0, 'a == b [3]';
  ok $list1 != $list2 ? 1 : 0, 1, 'a != b [3]';
  ok $list1 eq $list2 ? 1 : 0, 0, 'a eq b [3]';
  ok $list1 ne $list2 ? 1 : 0, 1, 'a ne b [3]';

  push @$list1, 'b';
  push @$list2, 'a';
  ok $list1 == $list2 ? 1 : 0, 1, 'a == b [4]';
  ok $list1 != $list2 ? 1 : 0, 0, 'a != b [4]';
  ok $list1 eq $list2 ? 1 : 0, 0, 'a eq b [4]';
  ok $list1 ne $list2 ? 1 : 0, 1, 'a ne b [4]';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/07 04:47:30 $
