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
      unless $args{non_clearable};
  
  ## EmptyNodeList
  push @nodelist, $Doc->last_child->last_child->last_child->last_child->child_nodes;

  ## GetElementsList
  push @nodelist, $Doc->get_elements_by_tag_name ('p');
  
  ## StaticNodeList
  push @nodelist, $Doc->query_selector_all ('p');

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
