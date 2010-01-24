#!/usr/bin/perl
package test::Message::DOM::DOMStringList;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;

require Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;

sub _test1 : Test(41) {
  my $doc = $dom->create_document;

  my $at = $doc->create_attribute_definition ('ad');
  my $list = $at->allowed_tokens;

  isa_ok $list, 'Message::IF::DOMStringList';

  ## length (0)
  is 0+@$list, 0, 'DOMStringList @{} 0+ [0]';
  is $list->length, 0, 'DOMStringList->length [0]';

  ## PUSH
  push @$list, 'String1';

  ## length (1)
  is 0+@$list, 1, 'DOMStringList @{} 0+ [1]';
  is $list->length, 1, 'DOMStringList->length [1]';

  ## FETCH
  is $list->[0], 'String1', 'DOMStringList->[0] [1]';
  is $list->item (0), 'String1', 'DOMStringList->item (0) [1]';

  ## PUSH
  push @$list, 'String2';

  ## length (2)
  is 0+@$list, 2, 'DOMStringList @{} 0+ [2]';
  is $list->length, 2, 'DOMStringList->length [2]';

  ## FETCH
  is $list->[1], 'String2', 'DOMStringList->[1] [2]';
  is $list->item (1), 'String2', 'DOMStringList->item (1) [2]';
  
  ## EXISTS
  is exists $list->[0] ? 1 : 0, 1, 'DOMStringList exists 0 [2]';
  is exists $list->[1] ? 1 : 0, 1, 'DOMStringList exists 1 [2]';
  is exists $list->[2] ? 1 : 0, 0, 'DOMStringList exists 2 [2]';
  is exists $list->[3] ? 1 : 0, 0, 'DOMStringList exists 3 [2]';

  ## DELETE
  delete $list->[0];
    
  ## FETCHSIZE
  is 0+@$list, 1, 'DOMStringList @{} 0+ [3]';

  ## EXISTS
  is exists $list->[0] ? 1 : 0, 1, 'DOMStringList exists 0 [3]';
  is exists $list->[1] ? 1 : 0, 0, 'DOMStringList exists 1 [3]';
  is exists $list->[2] ? 1 : 0, 0, 'DOMStringList exists 2 [3]';
  is exists $list->[3] ? 1 : 0, 0, 'DOMStringList exists 3 [3]';

  ## FETCH
  is $list->[0], 'String2', 'DOMStringList->[0] [3]';
  is $list->[1], undef, 'DOMStringList->[1] [3]';
  
  ## STORE
  $list->[0] = 'String3';

  ## FETCH
  is $list->[0], 'String3', 'DOMStringList->[0] [4]';
  is $list->[1], undef, 'DOMStringList->[1] [4]';
 
  ## STORE
  $list->[1] = 'String4';
  is $list->[0], 'String3', 'DOMStringList->[0] [5]';
  is $list->[1], 'String4', 'DOMStringList->[1] [5]';

  $list->[2] = 'String5';
  is $list->[0], 'String3', 'DOMStringList->[0] [6]';
  is $list->[1], 'String4', 'DOMStringList->[1] [6]';
  is $list->[2], 'String5', 'DOMStringList->[2] [6]';
  is 0+@$list, 3, 'DOMStringList @{} 0+ [6]';

  ## contains
  is $list->contains ('String1') ? 1 : 0, 0, 'DOMStringList contains 1 [6]';
  is $list->contains ('String2') ? 1 : 0, 0, 'DOMStringList contains 2 [6]';
  is $list->contains ('String3') ? 1 : 0, 1, 'DOMStringList contains 3 [6]';
  is $list->contains ('String4') ? 1 : 0, 1, 'DOMStringList contains 4 [6]';
  is $list->contains ('String5') ? 1 : 0, 1, 'DOMStringList contains 5 [6]';

  ## DELETE
  delete $list->[2];
  is exists $list->[0] ? 1 : 0, 1, 'DOMStringList exists 0 [7]';
  is exists $list->[1] ? 1 : 0, 1, 'DOMStringList exists 1 [7]';
  is exists $list->[2] ? 1 : 0, 0, 'DOMStringList exists 2 [7]';
  is exists $list->[3] ? 1 : 0, 0, 'DOMStringList exists 3 [7]';
  is exists $list->[4] ? 1 : 0, 0, 'DOMStringList exists 4 [7]';
  is 0+@$list, 2, 'DOMStringList @{} 0+ [7]';
} # _test1

sub _test2 : Test(30) {
  my $doc = $dom->create_document;

  my $at1 = $doc->create_attribute_definition ('ad');
  my $list1 = $at1->allowed_tokens;
  my $at2 = $doc->create_attribute_definition ('ad');
  my $list2 = $at2->allowed_tokens;

  isa_ok $list1, 'Message::IF::DOMStringList';
  isa_ok $list2, 'Message::IF::DOMStringList';

  is $list1 == $list1 ? 1 : 0, 1, 'a == a [0]';
  is $list1 != $list1 ? 1 : 0, 0, 'a != a [0]';
  is $list1 eq $list1 ? 1 : 0, 1, 'a eq a [0]';
  is $list1 ne $list1 ? 1 : 0, 0, 'a ne a [0]';
  is $list1 == $list2 ? 1 : 0, 1, 'a == b [0]';
  is $list1 != $list2 ? 1 : 0, 0, 'a != b [0]';
  is $list1 eq $list2 ? 1 : 0, 0, 'a eq b [0]';
  is $list1 ne $list2 ? 1 : 0, 1, 'a ne b [0]';

  push @$list1, '';
  push @$list2, '';
  is $list1 == $list2 ? 1 : 0, 1, 'a == b [1]';
  is $list1 != $list2 ? 1 : 0, 0, 'a != b [1]';
  is $list1 eq $list2 ? 1 : 0, 0, 'a eq b [1]';
  is $list1 ne $list2 ? 1 : 0, 1, 'a ne b [1]';

  push @$list1, 'str';
  push @$list2, 'str';
  is $list1 == $list2 ? 1 : 0, 1, 'a == b [2]';
  is $list1 != $list2 ? 1 : 0, 0, 'a != b [2]';
  is $list1 eq $list2 ? 1 : 0, 0, 'a eq b [2]';
  is $list1 ne $list2 ? 1 : 0, 1, 'a ne b [2]';

  push @$list1, 'a';
  is $list1 == $list2 ? 1 : 0, 0, 'a == b [2]';
  is $list1 != $list2 ? 1 : 0, 1, 'a != b [2]';
  is $list1 eq $list2 ? 1 : 0, 0, 'a eq b [2]';
  is $list1 ne $list2 ? 1 : 0, 1, 'a ne b [2]';

  push @$list2, 'b';
  is $list1 == $list2 ? 1 : 0, 0, 'a == b [3]';
  is $list1 != $list2 ? 1 : 0, 1, 'a != b [3]';
  is $list1 eq $list2 ? 1 : 0, 0, 'a eq b [3]';
  is $list1 ne $list2 ? 1 : 0, 1, 'a ne b [3]';

  push @$list1, 'b';
  push @$list2, 'a';
  is $list1 == $list2 ? 1 : 0, 1, 'a == b [4]';
  is $list1 != $list2 ? 1 : 0, 0, 'a != b [4]';
  is $list1 eq $list2 ? 1 : 0, 0, 'a eq b [4]';
  is $list1 ne $list2 ? 1 : 0, 1, 'a ne b [4]';
} # _test2

sub _static_as_array : Test(1) {
  require Message::DOM::DOMStringList;
  my $l = bless [qw(a b c)], 'Message::DOM::DOMStringList::StaticList';
  is_deeply [@$l], [qw(a b c)];
} # _static_as_array

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
