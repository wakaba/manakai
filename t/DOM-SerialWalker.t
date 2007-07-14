#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 258 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

## |manakai_create_serial_walker| and attributes
{
  ok $doc->can ('manakai_create_serial_walker') ? 1 : 0, 1, 'create_sw can';

  my $el = $doc->create_element ('e');
  my $tw = $doc->manakai_create_serial_walker ($el);

  ok $tw->isa ('Message::IF::SerialWalker') ? 1 : 0, 1, 'create_sw [1] if';
  ok $tw->what_to_show, 0, 'create_sw [1] what_to_show';
  ok $tw->filter, undef, 'create_sw [1] filter';
  ok $tw->expand_entity_references ? 1 : 0, 0, 'create_sw [1] xent';
  ok $tw->current_node, $el, 'create_sw [1] current_node';
  ok $tw->root, $el, 'create_sw [1] root';
}
{
  my $el = $doc->create_element ('e');
  my $filter = sub { };
  my $tw = $doc->manakai_create_serial_walker ($el, 0xFFFFFFFF, $filter, 1);

  ok $tw->isa ('Message::IF::SerialWalker') ? 1 : 0, 1, 'create_sw [2] if';
  ok $tw->what_to_show, 0xFFFFFFFF, 'create_sw [2] what_to_show';
  ok $tw->filter, $filter, 'create_sw [2] filter';
  ok $tw->expand_entity_references ? 1 : 0, 1, 'create_sw [2] xent';
  ok $tw->current_node, $el, 'create_sw [2] current_node';
  ok $tw->root, $el, 'create_sw [2] root';
}
{
  my $el = $doc->create_element ('e');
  my $filter = sub { };
  my $tw = $doc->manakai_create_serial_walker ($el, 0xFFFFFFFF, $filter, 0);

  ok $tw->isa ('Message::IF::SerialWalker') ? 1 : 0, 1, 'create_sw [3] if';
  ok $tw->what_to_show, 0xFFFFFFFF, 'create_sw [3] what_to_show';
  ok $tw->filter, $filter, 'create_sw [3] filter';
  ok $tw->expand_entity_references ? 1 : 0, 0, 'create_sw [3] xent';
  ok $tw->current_node, $el, 'create_sw [3] current_node';
  ok $tw->root, $el, 'create_sw [3] root';
}
try {
  $doc->manakai_create_serial_walker;
  ok 1, 0, 'create_sw [4]';
} catch Message::IF::DOMException with {
  ok $_[0]->type, 'NOT_SUPPORTED_ERR', 'create_sw [4]';
};

my %tree3;
$tree3{el1} = $doc->create_element ('el1');
$tree3{el2} = $doc->create_element ('el2');
$tree3{el3} = $doc->create_element ('el3');
$tree3{el4} = $doc->create_element ('el4');
$tree3{el5} = $doc->create_element ('el5');
$tree3{el1}->append_child ($tree3{el2});
$tree3{el1}->append_child ($tree3{el3});
$tree3{el3}->append_child ($tree3{el4});
$tree3{el1}->append_child ($tree3{el5});

ok $doc->can ('manakai_create_serial_walker') ? 1 : 0, 1, 'can create_sw';

## |nextNode|
{
  my $sw = $doc->manakai_create_serial_walker
      ($tree3{el1}, 0xFFFFFFFF);

  ok $sw->can ('next_node') ? 1 : 0, 1, 'can next_node';

  for (
       [1, 'el1', 'el1', $sw->PRE_PHASE, 0],
       [2, 'el2', 'el2', $sw->PRE_PHASE, 0],
       [3, 'el2', 'el2', $sw->POST_PHASE, 1],
       [4, 'el1', 'el1', $sw->IN_PHASE, 1],
       [5, 'el3', 'el3', $sw->PRE_PHASE, 0],
       [6, 'el4', 'el4', $sw->PRE_PHASE, 0],
       [7, 'el4', 'el4', $sw->POST_PHASE, 1],
       [8, 'el3', 'el3', $sw->POST_PHASE, 1],
       [9, 'el1', 'el1', $sw->IN_PHASE, 2],
       [10, 'el5', 'el5', $sw->PRE_PHASE, 0],
       [11, 'el5', 'el5', $sw->POST_PHASE, 1],
       [12, 'el1', 'el1', $sw->POST_PHASE, 3],
       [13, undef, 'el1', $sw->POST_PHASE, 3],
       [14, undef, 'el1', $sw->POST_PHASE, 3],
      ) {
    ok $sw->next_node, $_->[1] ? $tree3{$_->[1]} : undef, 
        $_->[0] . ' next_node [0] next_node';
    ok $sw->current_node, $tree3{$_->[2]},
        $_->[0] . ' next_node [0] current_node';
    ok $sw->current_phase, $_->[3],
        $_->[0] . ' next_node [0] current_phase';
    ok $sw->current_index, $_->[4],
        $_->[0] . ' next_node [0] current_index';
  }
}
{
  my $sw = $doc->manakai_create_serial_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name ne 'el3' ? 1 : 3; # ACCEPT : SKIP
  });

  for (
       [1, 'el1', 'el1', $sw->PRE_PHASE, 0],
       [2, 'el2', 'el2', $sw->PRE_PHASE, 0],
       [3, 'el2', 'el2', $sw->POST_PHASE, 1],
       [4, 'el1', 'el1', $sw->IN_PHASE, 1],
       [6, 'el4', 'el4', $sw->PRE_PHASE, 0],
       [7, 'el4', 'el4', $sw->POST_PHASE, 1],
       [9, 'el1', 'el1', $sw->IN_PHASE, 2],
       [10, 'el5', 'el5', $sw->PRE_PHASE, 0],
       [11, 'el5', 'el5', $sw->POST_PHASE, 1],
       [12, 'el1', 'el1', $sw->POST_PHASE, 3],
       [13, undef, 'el1', $sw->POST_PHASE, 3],
       [14, undef, 'el1', $sw->POST_PHASE, 3],
      ) {
    ok $sw->next_node, $_->[1] ? $tree3{$_->[1]} : undef, 
        $_->[0] . ' next_node [1] next_node';
    ok $sw->current_node, $tree3{$_->[2]},
        $_->[0] . ' next_node [1] current_node';
    ok $sw->current_phase, $_->[3],
        $_->[0] . ' next_node [1] current_phase';
    ok $sw->current_index, $_->[4],
        $_->[0] . ' next_node [1] current_index';
  }
}
{
  my $sw = $doc->manakai_create_serial_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 12101 : 1;
  });

  for (
       [1, 'el1', 'el1', $sw->PRE_PHASE, 0],
       [2, 'el2', 'el2', $sw->PRE_PHASE, 0],
       [3, 'el2', 'el2', $sw->POST_PHASE, 1],
       [4, 'el1', 'el1', $sw->IN_PHASE, 1],
       [3, 'el3', 'el3', $sw->PRE_PHASE, 0],
       [8, 'el3', 'el3', $sw->POST_PHASE, 1],
       [9, 'el1', 'el1', $sw->IN_PHASE, 2],
       [10, 'el5', 'el5', $sw->PRE_PHASE, 0],
       [11, 'el5', 'el5', $sw->POST_PHASE, 1],
       [12, 'el1', 'el1', $sw->POST_PHASE, 3],
       [13, undef, 'el1', $sw->POST_PHASE, 3],
       [14, undef, 'el1', $sw->POST_PHASE, 3],
      ) {
    ok $sw->next_node, $_->[1] ? $tree3{$_->[1]} : undef, 
        $_->[0] . ' next_node [2] next_node';
    ok $sw->current_node, $tree3{$_->[2]},
        $_->[0] . ' next_node [2] current_node';
    ok $sw->current_phase, $_->[3],
        $_->[0] . ' next_node [2] current_phase';
    ok $sw->current_index, $_->[4],
        $_->[0] . ' next_node [2] current_index';
  }
}
{
  my $sw = $doc->manakai_create_serial_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 2 : 1; # REJECT : ACCEPT
  });

  for (
       [1, 'el1', 'el1', $sw->PRE_PHASE, 0],
       [2, 'el2', 'el2', $sw->PRE_PHASE, 0],
       [3, 'el2', 'el2', $sw->POST_PHASE, 1],
       [4, 'el1', 'el1', $sw->IN_PHASE, 1],
       [10, 'el5', 'el5', $sw->PRE_PHASE, 0],
       [11, 'el5', 'el5', $sw->POST_PHASE, 1],
       [12, 'el1', 'el1', $sw->POST_PHASE, 2],
       [13, undef, 'el1', $sw->POST_PHASE, 2],
       [14, undef, 'el1', $sw->POST_PHASE, 2],
      ) {
    ok $sw->next_node, $_->[1] ? $tree3{$_->[1]} : undef, 
        $_->[0] . ' next_node [3] next_node';
    ok $sw->current_node, $tree3{$_->[2]},
        $_->[0] . ' next_node [3] current_node';
    ok $sw->current_phase, $_->[3],
        $_->[0] . ' next_node [3] current_phase';
    ok $sw->current_index, $_->[4],
        $_->[0] . ' next_node [3] current_index';
  }
}
{
  my $sw = $doc->manakai_create_serial_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el4' ? 2 : 1; # REJECT : ACCEPT
  });

  for (
       [1, 'el1', 'el1', $sw->PRE_PHASE, 0],
       [2, 'el2', 'el2', $sw->PRE_PHASE, 0],
       [3, 'el2', 'el2', $sw->POST_PHASE, 1],
       [4, 'el1', 'el1', $sw->IN_PHASE, 1],
       [5, 'el3', 'el3', $sw->PRE_PHASE, 0],
       [8, 'el3', 'el3', $sw->POST_PHASE, 1],
       [9, 'el1', 'el1', $sw->IN_PHASE, 2],
       [10, 'el5', 'el5', $sw->PRE_PHASE, 0],
       [11, 'el5', 'el5', $sw->POST_PHASE, 1],
       [12, 'el1', 'el1', $sw->POST_PHASE, 3],
       [13, undef, 'el1', $sw->POST_PHASE, 3],
       [14, undef, 'el1', $sw->POST_PHASE, 3],
      ) {
    ok $sw->next_node, $_->[1] ? $tree3{$_->[1]} : undef, 
        $_->[0] . ' next_node [4] next_node';
    ok $sw->current_node, $tree3{$_->[2]},
        $_->[0] . ' next_node [4] current_node';
    ok $sw->current_phase, $_->[3],
        $_->[0] . ' next_node [4] current_phase';
    ok $sw->current_index, $_->[4],
        $_->[0] . ' next_node [4] current_index';
  }
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/14 16:32:28 $
