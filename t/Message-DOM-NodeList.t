package test::Message::DOM::NodeList;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::DOMImplementation;

my $DOM = Message::DOM::DOMImplementation->new;
my $Doc = $DOM->create_document;
$Doc->manakai_is_html (1);
$Doc->inner_html (q{<!DOCTYPE html><p>foo<p>bar});

sub nodelists () {
  my @nodelist;

  ## ChildeNodeList
  push @nodelist, $Doc->last_child->last_child->child_nodes;
  
  ## EmptyNodeList
  push @nodelist, $Doc->last_child->last_child->last_child->last_child->child_nodes;

  ## GetElementsList
  push @nodelist, $Doc->get_elements_by_tag_name ('p');
  
  ## StaticNodeList
  push @nodelist, $Doc->query_selector_all ('p');

  return @nodelist;
} # nodelists

sub _length : Test(8) {
  for my $nl (nodelists) {
    lives_ok { $nl->length };
    is scalar @$nl, $nl->length;
  }
} # _length

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
