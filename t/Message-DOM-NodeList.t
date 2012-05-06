package test::Message::DOM::NodeList;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::DOMImplementation;
use Message::DOM::NodeList;

my $DOM = Message::DOM::DOMImplementation->new;
my $Doc = $DOM->create_document;
$Doc->manakai_is_html (1);
$Doc->inner_html (q{<!DOCTYPE html><p>foo<p>bar});

sub nodelists (;%) {
  my %args = @_;
  my @nodelist;

  ## ChildeNodeList
  push @nodelist, $Doc->last_child->last_child->child_nodes
      if not $args{non_clearable} and not $args{empty_only};
  
  ## EmptyNodeList
  push @nodelist, $Doc->last_child->last_child->last_child->last_child->child_nodes
      unless $args{p2_only};

  ## GetElementsList
  push @nodelist, $Doc->get_elements_by_tag_name ('p')
      if not $args{empty_only};
  
  ## StaticNodeList
  push @nodelist, $Doc->query_selector_all ('p')
      if not $args{empty_only};

  return @nodelist;
} # nodelists

sub _new_static_list : Test(6) {
  my $node1 = $Doc->create_element ('abc1');
  my $node2 = $Doc->create_element ('abc2');
  my $node3 = $Doc->create_element ('abc3');
  my $nl = Message::DOM::NodeList::StaticNodeList->____new_from_arrayref
      ([$node1, $node2]);
  
  dies_here_ok {
    $nl->[0] = $node3;
  };
  dies_here_ok {
    push @$nl, $node3;
  };
  dies_here_ok {
    delete $nl->[1];
  };
  is $nl->length, 2;

  is $node1->append_child ($node3), $node3;
  $$node1->{test} = 1;
  is $$node1->{test}, 1;
} # _new_static_list

sub _length : Test(8) {
  for my $nl (nodelists) {
    lives_ok { $nl->length };
    is scalar @$nl, $nl->length;
  }
} # _length

sub _store : Test(8) {
  my $node = $Doc->create_text_node;
  for my $nl (nodelists) {
    my $length = $nl->length;
    dies_here_ok {
      $nl->[1] = $node;
    };
    is $nl->length, $length;
  }
} # _store

sub _delete : Test(8) {
  my $node = $Doc->create_text_node;
  for my $nl (nodelists) {
    my $length = $nl->length;
    dies_here_ok {
      delete $nl->[0];
    };
    is $nl->length, $length;
  }
} # _delete

sub _clear_not_clearable : Test(6) {
  my $node = $Doc->create_text_node;
  for my $nl (nodelists non_clearable => 1) {
    my $length = $nl->length;
    dies_here_ok {
      @$nl = ();
    };
    is $nl->length, $length;
  }
} # _clear_clearable

sub _clear_child_nodes : Test(2) {
  my $node = $Doc->create_element ('div');
  $node->inner_html ('<p>fff<p>babee<b>wagfa</b><i>fe</i>');
  my $nl = $node->child_nodes;
  is $nl->length, 2;
  @$nl = ();
  is $nl->length, 0;
} # _clear_child_nodes

sub _list : Test(66) {
  for my $nl (nodelists p2_only => 1) {
    my $arrayref = $nl->to_a;
    is ref $arrayref, 'ARRAY';
    is scalar @$arrayref, 2;
    is $arrayref->[0], $nl->item (0);
    is $arrayref->[1], $nl->item (1);
    isnt $nl->to_a, $arrayref;
    
    my $arrayref2 = $nl->as_list;
    is ref $arrayref2, 'ARRAY';
    is scalar @$arrayref2, 2;
    is $arrayref->[0], $nl->item (0);
    is $arrayref->[1], $nl->item (1);
    isnt $nl->as_list, $arrayref2;
    isnt $arrayref2, $arrayref;

    my @list = $nl->to_list;
    is scalar @list, 2;
    is $list[0], $nl->item (0);
    is $list[1], $nl->item (1);

    my @list2 = @$nl;
    is scalar @list2, 2;
    is $list2[0], $nl->item (0);
    is $list2[1], $nl->item (1);

    is $nl->[0], $nl->item (0);
    is $nl->[1], $nl->item (1);
    is $nl->[2], undef;
    is $nl->[-1], $nl->[1];
    dies_here_ok { ng $nl->[-3] };
  }
} # _list

sub _list_empty : Test(8) {
  for my $nl (nodelists empty_only => 1) {
    my $arrayref = $nl->to_a;
    is ref $arrayref, 'ARRAY';
    is scalar @$arrayref, 0;

    my $arrayref2 = $nl->as_list;
    is ref $arrayref2, 'ARRAY';
    is scalar @$arrayref2, 0;

    my @list = @$nl;
    is scalar @list, 0;

    my @list2 = $nl->to_list;
    is scalar @list2, 0;

    is $nl->[0], undef;
    dies_here_ok { ng $nl->[-1] };
  }
} # _list_empty

## XXXtest need more tests!

__PACKAGE__->runtests;

our $DetectLeak = 1;

sub Message::DOM::NodeList::DESTROY
    { die ref ($_[0]) . ": Leak detected" if $DetectLeak }

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
