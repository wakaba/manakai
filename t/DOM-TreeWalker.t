#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 423 }

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

## |create_tree_walker| and attributes
{
  ok $doc->can ('create_tree_walker') ? 1 : 0, 1, 'Document->create_tw can';

  my $el = $doc->create_element ('e');
  my $tw = $doc->create_tree_walker ($el);

  ok $tw->isa ('Message::IF::TreeWalker') ? 1 : 0, 1, 'create_tw [1] if';
  ok $tw->what_to_show, 0, 'create_tw [1] what_to_show';
  ok $tw->filter, undef, 'create_tw [1] filter';
  ok $tw->expand_entity_references ? 1 : 0, 0, 'create_tw [1] xent';
  ok $tw->current_node, $el, 'create_tw [1] current_node';
  ok $tw->root, $el, 'create_tw [1] root';
}
{
  my $el = $doc->create_element ('e');
  my $filter = sub { };
  my $tw = $doc->create_tree_walker ($el, 0xFFFFFFFF, $filter, 1);

  ok $tw->isa ('Message::IF::TreeWalker') ? 1 : 0, 1, 'create_tw [2] if';
  ok $tw->what_to_show, 0xFFFFFFFF, 'create_tw [2] what_to_show';
  ok $tw->filter, $filter, 'create_tw [2] filter';
  ok $tw->expand_entity_references ? 1 : 0, 1, 'create_tw [2] xent';
  ok $tw->current_node, $el, 'create_tw [2] current_node';
  ok $tw->root, $el, 'create_tw [2] root';
}
{
  my $el = $doc->create_element ('e');
  my $filter = sub { };
  my $tw = $doc->create_tree_walker ($el, 0xFFFFFFFF, $filter, 0);

  ok $tw->isa ('Message::IF::TreeWalker') ? 1 : 0, 1, 'create_tw [3] if';
  ok $tw->what_to_show, 0xFFFFFFFF, 'create_tw [3] what_to_show';
  ok $tw->filter, $filter, 'create_tw [3] filter';
  ok $tw->expand_entity_references ? 1 : 0, 0, 'create_tw [3] xent';
  ok $tw->current_node, $el, 'create_tw [3] current_node';
  ok $tw->root, $el, 'create_tw [3] root';
}
try {
  $doc->create_tree_walker;
  ok 1, 0, 'create_tw [4]';
} catch Message::IF::DOMException with {
  ok $_[0]->type, 'NOT_SUPPORTED_ERR', 'create_tw [4]';
};

my $tw = $doc->create_tree_walker ($doc);

my %tree1;
$tree1{el1} = $doc->create_element ('el1');
$tree1{el2} = $doc->create_element ('el2');
$tree1{el3} = $doc->create_element ('el3');
$tree1{el4} = $doc->create_element ('el4');
$tree1{el1}->append_child ($tree1{el2});
$tree1{el1}->append_child ($tree1{el3});
$tree1{el3}->append_child ($tree1{el4});

my %tree2;
$tree2{el1} = $doc->create_element ('el1');
$tree2{el2} = $doc->create_element ('el2');
$tree2{el3} = $doc->create_element ('el3');
$tree2{el4} = $doc->create_element ('el4');
$tree2{el5} = $doc->create_element ('el5');
$tree2{el1}->append_child ($tree2{el2});
$tree2{el1}->append_child ($tree2{el3});
$tree2{el3}->append_child ($tree2{el4});
$tree2{el3}->append_child ($tree2{el5});

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

my %tree4;
$tree4{el1} = $doc->create_element ('el1');
$tree4{er1} = $doc->create_entity_reference ('er1');
$tree4{er1}->manakai_set_read_only (0, 1);
$tree4{el3} = $doc->create_element ('el3');
$tree4{el4} = $doc->create_element ('el4');
$tree4{el5} = $doc->create_element ('el5');
$tree4{el6} = $doc->create_element ('el6');
$tree4{el1}->append_child ($tree4{er1});
$tree4{er1}->append_child ($tree4{el3});
$tree4{el3}->append_child ($tree4{el4});
$tree4{er1}->append_child ($tree4{el5});
$tree4{el1}->append_child ($tree4{el6});

my %tree5;
$tree5{el1} = $doc->create_element ('el1');
$tree5{el2} = $doc->create_element ('el2');
$tree5{er1} = $doc->create_entity_reference ('er1');
$tree5{er1}->manakai_set_read_only (0, 1);
$tree5{el3} = $doc->create_element ('el3');
$tree5{el4} = $doc->create_element ('el4');
$tree5{el5} = $doc->create_element ('el5');
$tree5{el1}->append_child ($tree5{el2});
$tree5{el1}->append_child ($tree5{er1});
$tree5{er1}->append_child ($tree5{el3});
$tree5{er1}->append_child ($tree5{el5});
$tree5{el3}->append_child ($tree5{el4});

## |currentNode|
{
  my $el = $doc->create_element ('e');
  $tw->current_node ($el);
  ok $tw->current_node, $el, 'current_node set [1]';
}
try {
  $tw->current_node (undef);
  ok 1, 0, 'current_node set null';
} catch Message::IF::DOMException with {
  ok shift->type, 'NOT_SUPPORTED_ERR', 'current_node set null';
};

## |firstChild|
{
  my $tw = $doc->create_tree_walker ($tree2{el1}, 0xFFFFFFFF);
  ok $tw->can ('first_child') ? 1 : 0, 1, 'can first_child';

  ok $tw->first_child, $tree2{el2}, 'fc fc [1]';
  ok $tw->current_node, $tree2{el2}, 'fc cn [1]';

  ok $tw->first_child, undef, 'fc fc [2]';
  ok $tw->current_node, $tree2{el2}, 'fc cn [2]';

  $tw->current_node ($tree2{el3});
  ok $tw->first_child, $tree2{el4}, 'fc fc [3]';
  ok $tw->current_node, $tree2{el4}, 'fc cn [3]';

  ok $tw->first_child, undef, 'fc fc [4]';
  ok $tw->current_node, $tree2{el4}, 'fc cn [4]';
}
{
  my $tw = $doc->create_tree_walker ($tree1{el1}, 0x00000002); # SHOW_ATTRIBUTE

  ok $tw->first_child, undef, 'fc fc [5]';
  ok $tw->current_node, $tree1{el1}, 'fc cn [5]';

  $tw->current_node ($tree1{el2});
  ok $tw->first_child, undef, 'fc fc [6]';
  ok $tw->current_node, $tree1{el2}, 'fc cn [6]';

  $tw->current_node ($tree1{el3});
  ok $tw->first_child, undef, 'fc fc [7]';
  ok $tw->current_node, $tree1{el3}, 'fc cn [7]';

  $tw->current_node ($tree1{el4});
  ok $tw->first_child, undef, 'fc fc [8]';
  ok $tw->current_node, $tree1{el4}, 'fc cn [8]';
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, undef, 0);

  ok $tw->first_child, $tree4{er1}, 'fc fc [9]';
  ok $tw->current_node, $tree4{er1}, 'fc cn [9]';

  $tw->current_node ($tree4{er1});
  ok $tw->first_child, undef, 'fc fc [10]';
  ok $tw->current_node, $tree4{er1}, 'fc cn [10]';

  $tw->current_node ($tree4{el3});
  ok $tw->first_child, $tree4{el4}, 'fc fc [11]';
  ok $tw->current_node, $tree4{el4}, 'fc cn [11]';

  ok $tw->first_child, undef, 'fc fc [12]';
  ok $tw->current_node, $tree4{el4}, 'fc cn [12]';

  $tw->current_node ($tree4{el5});
  ok $tw->first_child, undef, 'fc fc [13]';
  ok $tw->current_node, $tree4{el5}, 'fc cn [13]';

  $tw->current_node ($tree4{el6});
  ok $tw->first_child, undef, 'fc fc [14]';
  ok $tw->current_node, $tree4{el6}, 'fc cn [14]';
}
{
  ## expandEntityReferences emulated by MANAKAI_FILTER_OPAQUE

  my $tw = $doc->create_tree_walker
      ($tree4{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE
      ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, 'er1', 'er1'],
       ['er1', 'er1', undef, 'er1'],
       ['el3', 'el3', 'el4', 'el4'],
       ['el4', undef, undef, 'el4'],
       ['el5', 'el5', undef, 'el5'],
       ['el6', 'el6', undef, 'el6'],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->first_child, $_->[2] ? $tree4{$_->[2]} : undef,
        'first_child [4] ' . $_->[0] . ' first_child';
    ok $tw->current_node, $tree4{$_->[3]},
        'first_child [4] ' . $_->[0] . ' current_node';
  }
}

## |lastChild|
{
  my $tw = $doc->create_tree_walker ($tree2{el1}, 0xFFFFFFFF);
  ok $tw->can ('last_child') ? 1 : 0, 1, 'can last_child';

  for (
       ['el1', undef, 'el3', 'el3'],
       ['el3', undef, 'el5', 'el5'],
       ['el5', undef, undef, 'el5'],
       ['el2', 'el2', undef, 'el2'],
       ['el4', 'el4', undef, 'el4'],
  ) {
    $tw->current_node ($tree2{$_->[1]}) if $_->[1];
    ok $tw->last_child, $_->[2] ? $tree2{$_->[2]} : undef,
        'last_child [1] ' . $_->[0] . ' last_child';
    ok $tw->current_node, $tree2{$_->[3]},
        'last_child [1] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree1{el1}, 0x00000002); # SHOW_ATTRIBUTE

  for (
       ['el1', undef, undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', undef],
       ['el4', 'el4', undef],
  ) {
    $tw->current_node ($tree1{$_->[1]}) if $_->[1];
    ok $tw->last_child, $_->[2] ? $tree1{$_->[2]} : undef,
        'last_child [2] ' . $_->[0] . ' last_child';
    ok $tw->current_node, $tree1{$_->[2] || $_->[1] || $_->[0]},
        'last_child [2] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree5{el1}, 0xFFFFFFFF, undef, 0);

  for (
       ['el1', undef, 'er1'],
       ['er1', undef, undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', 'el4'],
       ['el4', undef, undef],
       ['el5', 'el5', undef],
  ) {
    $tw->current_node ($tree5{$_->[1]}) if $_->[1];
    ok $tw->last_child, $_->[2] ? $tree5{$_->[2]} : undef,
        'last_child [3] ' . $_->[0] . ' last_child';
    ok $tw->current_node, $tree5{$_->[2] || $_->[1] || $_->[0]},
        'last_child [3] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree5{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE
      ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, 'er1'],
       ['er1', undef, undef],
       ['el3', 'el3', 'el4'],
       ['el4', undef, undef],
       ['el5', 'el5', undef],
       ['el2', 'el2', undef],
  ) {
    $tw->current_node ($tree5{$_->[1]}) if $_->[1];
    ok $tw->last_child, $_->[2] ? $tree5{$_->[2]} : undef,
        'last_child [4] ' . $_->[0] . ' last_child';
    ok $tw->current_node, $tree5{$_->[2] || $_->[1] || $_->[0]},
        'last_child [4] ' . $_->[0] . ' current_node';
  }
}

## |parentNode|
{
  my $tw = $doc->create_tree_walker ($tree1{el1}, 0xFFFFFFFF);
  ok $tw->can ('parent_node') ? 1 : 0, 1, 'can parent_node';

  for (
       ['el1', undef, undef],
       ['el4', 'el4', 'el3'],
       ['el3', undef, 'el1'],
       ['el2', 'el2', 'el1'],
  ) {
    $tw->current_node ($tree1{$_->[1]}) if $_->[1];
    ok $tw->parent_node, $_->[2] ? $tree1{$_->[2]} : undef,
        'parent_node [1] ' . $_->[0] . ' parent_node';
    ok $tw->current_node, $tree1{$_->[2] || $_->[1] || $_->[0]},
        'parent_node [1] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree1{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 1 : 2 # ACCEPT : REJECT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', undef],
       ['el4', 'el4', 'el3'],
  ) {
    $tw->current_node ($tree1{$_->[1]}) if $_->[1];
    ok $tw->parent_node, $_->[2] ? $tree1{$_->[2]} : undef,
        'parent_node [2] ' . $_->[0] . ' parent_node';
    ok $tw->current_node, $tree1{$_->[2] || $_->[1] || $_->[0]},
        'parent_node [2] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree1{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 3 : 1 # SKIP : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el1'],
       ['el3', 'el3', 'el1'],
       ['el4', 'el4', 'el1'],
  ) {
    $tw->current_node ($tree1{$_->[1]}) if $_->[1];
    ok $tw->parent_node, $_->[2] ? $tree1{$_->[2]} : undef,
        'parent_node [3] ' . $_->[0] . ' parent_node';
    ok $tw->current_node, $tree1{$_->[2] || $_->[1] || $_->[0]},
        'parent_node [3] ' . $_->[0] . ' current_node';
  }
}
{
  ## NOTE: FILTER_REJECT works as if FILTER_SKIP if the currentNode
  ## is in the rejected subtree.

  my $tw = $doc->create_tree_walker ($tree1{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 2 : 1 # REJECT : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el1'],
       ['el3', 'el3', 'el1'],
       ['el4', 'el4', 'el1'],
  ) {
    $tw->current_node ($tree1{$_->[1]}) if $_->[1];
    ok $tw->parent_node, $_->[2] ? $tree1{$_->[2]} : undef,
        'parent_node [4] ' . $_->[0] . ' parent_node';
    ok $tw->current_node, $tree1{$_->[2] || $_->[1] || $_->[0]},
        'parent_node [4] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, undef, 0);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', 'el1'],
       ['el3', 'el3', 'er1'],
       ['el4', 'el4', 'er1'],
       ['el5', 'el5', 'er1'],
       ['el6', 'el6', 'el1'],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->parent_node, $_->[2] ? $tree4{$_->[2]} : undef,
        'parent_node [5] ' . $_->[0] . ' parent_node';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'parent_node [5] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker
      ($tree5{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE
      ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', 'el1'],
       ['el3', 'el3', 'er1'],
       ['el4', 'el4', 'el3'],
       ['el5', 'el5', 'er1'],
       ['el2', 'el2', 'el1'],
  ) {
    $tw->current_node ($tree5{$_->[1]}) if $_->[1];
    ok $tw->parent_node, $_->[2] ? $tree5{$_->[2]} : undef,
        'parent_node [6] ' . $_->[0] . ' parent_node';
    ok $tw->current_node, $tree5{$_->[2] || $_->[1] || $_->[0]},
        'parent_node [6] ' . $_->[0] . ' current_node';
  }
}

## |nextNode|
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF);
  ok $tw->can ('next_node') ? 1 : 0, 1, 'can next_node';

  for (
       ['el1', undef, 'el2'],
       ['el2', undef, 'el3'],
       ['el3', undef, 'el4'],
       ['el4', undef, 'el5'],
       ['el5', undef, undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_node [1] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_node [1] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el3}, 0xFFFFFFFF);

  for (
       ['el1', 'el1', 'el2'],
       ['el2', undef, 'el3'],
       ['el3', undef, 'el4'],
       ['el4', undef, undef],
       ['el5', 'el5', undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_node [2] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_node [2] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 3 : 1 # SKIP : ACCEPT
  });

  for (
       ['el1', undef, 'el2'],
       ['el2', undef, 'el4'],
       ['el3', 'el3', 'el4'],
       ['el4', undef, 'el5'],
       ['el5', undef, undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_node [3] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_node [3] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 2 : 1 # REJECT : ACCEPT
  });

  for (
       ['el1', undef, 'el2'],
       ['el2', undef, 'el5'],
       ['el3', 'el3', 'el4'],
       ['el4', undef, 'el5'],
       ['el5', undef, undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_node [4] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_node [4] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF);

  for (
       ['el1', undef, 'er1'],
       ['er1', undef, 'el6'],
       ['el3', 'el3', 'el4'],
       ['el4', undef, 'el6'],
       ['el5', 'el5', 'el6'],
       ['el6', undef, undef],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->next_node, $_->[2] ? $tree4{$_->[2]} : undef,
        'next_node [5] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'next_node [5] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, 'er1'],
       ['er1', undef, 'el6'],
       ['el3', 'el3', 'el4'],
       ['el4', undef, 'el5'],
       ['el5', undef, 'el6'],
       ['el6', undef, undef],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->next_node, $_->[2] ? $tree4{$_->[2]} : undef,
        'next_node [6] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'next_node [6] ' . $_->[0] . ' current_node';
  }
}

## |nextSibling|
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF);
  ok $tw->can ('next_sibling') ? 1 : 0, 1, 'can next_sibling';

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el3'],
       ['el3', undef, 'el5'],
       ['el4', 'el4', undef],
       ['el5', 'el5', undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_sibling [1] ' . $_->[0] . ' next_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_sibling [1] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el3}, 0xFFFFFFFF);

  for (
       ['el1', 'el1', undef],
       ['el2', 'el2', 'el3'],
       ['el3', 'el3', undef],
       ['el4', 'el4', undef],
       ['el5', 'el5', undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_sibling [2] ' . $_->[0] . ' next_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_sibling [2] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 3 : 1 # SKIP : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el4'],
       ['el3', 'el3', 'el5'],
       ['el4', 'el4', 'el5'],
       ['el5', 'el5', undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_sibling [3] ' . $_->[0] . ' next_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_sibling [3] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 2 : 1 # REJECT : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el5'],
       ['el3', 'el3', 'el5'],
       ['el4', 'el4', undef],
       ['el5', 'el5', undef],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->next_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'next_sibling [4] ' . $_->[0] . ' next_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'next_sibling [4] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, undef, 0);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', 'el6'],
       ['el3', 'el3', undef],
       ['el4', 'el4', undef],
       ['el5', 'el5', undef],
       ['el6', 'el6', undef],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->next_sibling, $_->[2] ? $tree4{$_->[2]} : undef,
        'next_sibling [5] ' . $_->[0] . ' next_sibling';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'next_sibling [5] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', 'el6'],
       ['el3', 'el3', 'el5'],
       ['el4', 'el4', undef],
       ['el5', 'el5', undef],
       ['el6', 'el6', undef],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->next_sibling, $_->[2] ? $tree4{$_->[2]} : undef,
        'next_sibling [6] ' . $_->[0] . ' next_sibling';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'next_sibling [6] ' . $_->[0] . ' current_node';
  }
}

## |previousNode|
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF);
  ok $tw->can ('previous_node') ? 1 : 0, 1, 'can previous_node';

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el1'],
       ['el3', 'el3', 'el2'],
       ['el4', 'el4', 'el3'],
       ['el5', 'el5', 'el4'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_node [1] ' . $_->[0] . ' previous_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_node [1] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el3}, 0xFFFFFFFF);

  for (
       ['el1', 'el1', undef],
       ['el2', 'el2', 'el1'],
       ['el3', 'el3', undef],
       ['el4', 'el4', 'el3'],
       ['el5', 'el5', 'el4'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_node [2] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_node [2] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 3 : 1 # SKIP : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el1'],
       ['el3', 'el3', 'el2'],
       ['el4', 'el4', 'el2'],
       ['el5', 'el5', 'el4'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_node [3] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_node [3] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 2 : 1 # REJECT : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', 'el1'],
       ['el3', 'el3', 'el2'],
       ['el4', 'el4', 'el2'],
       ['el5', 'el5', 'el2'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_node, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_node [4] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_node [4] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, undef, 0);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', 'el1'],
       ['el3', 'el3', 'er1'],
       ['el4', 'el4', 'er1'],
       ['el5', 'el5', 'er1'],
       ['el6', 'el6', 'er1'],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->previous_node, $_->[2] ? $tree4{$_->[2]} : undef,
        'previous_node [5] ' . $_->[0] . ' next_node';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'previous_node [5] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', 'el1'],
       ['el3', 'el3', 'er1'],
       ['el4', 'el4', 'el3'],
       ['el5', 'el5', 'el4'],
       ['el6', 'el6', 'er1'],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->previous_node, $_->[2] ? $tree4{$_->[2]} : undef,
        'previous_node [6] ' . $_->[0] . ' previous_node';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'previous_node [6] ' . $_->[0] . ' current_node';
  }
}

## |previousSibling|
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF);
  ok $tw->can ('previous_sibling') ? 1 : 0, 1, 'can previous_sibling';

  for (
       ['el1', undef, undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', 'el2'],
       ['el4', 'el4', undef],
       ['el5', 'el5', 'el3'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_sibling [1] ' . $_->[0] . ' previous_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_sibling [1] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el3}, 0xFFFFFFFF);

  for (
       ['el1', 'el1', undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', undef],
       ['el4', 'el4', undef],
       ['el5', 'el5', 'el3'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_sibling [2] ' . $_->[0] . ' previous_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_sibling [2] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 3 : 1 # SKIP : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', 'el2'],
       ['el4', 'el4', 'el2'],
       ['el5', 'el5', 'el4'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_sibling [3] ' . $_->[0] . ' previous_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_sibling [3] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree3{el1}, 0xFFFFFFFF, sub {
    $_[0]->local_name eq 'el3' ? 2 : 1 # REJECT : ACCEPT
  });

  for (
       ['el1', undef, undef],
       ['el2', 'el2', undef],
       ['el3', 'el3', 'el2'],
       ['el4', 'el4', 'el2'],
       ['el5', 'el5', 'el2'],
  ) {
    $tw->current_node ($tree3{$_->[1]}) if $_->[1];
    ok $tw->previous_sibling, $_->[2] ? $tree3{$_->[2]} : undef,
        'previous_sibling [4] ' . $_->[0] . ' previous_sibling';
    ok $tw->current_node, $tree3{$_->[2] || $_->[1] || $_->[0]},
        'previous_sibling [4] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, undef, 0);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', undef],
       ['el3', 'el3', undef],
       ['el4', 'el4', undef],
       ['el5', 'el5', undef],
       ['el6', 'el6', 'er1'],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->previous_sibling, $_->[2] ? $tree4{$_->[2]} : undef,
        'previous_sibling [5] ' . $_->[0] . ' previous_sibling';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'previous_sibling [5] ' . $_->[0] . ' current_node';
  }
}
{
  my $tw = $doc->create_tree_walker ($tree4{el1}, 0xFFFFFFFF, sub {
    $_[0]->node_type == $_[0]->ENTITY_REFERENCE_NODE ? 12101 : 1;
  }, 1);

  for (
       ['el1', undef, undef],
       ['er1', 'er1', undef],
       ['el3', 'el3', undef],
       ['el4', 'el4', undef],
       ['el5', 'el5', 'el3'],
       ['el6', 'el6', 'er1'],
  ) {
    $tw->current_node ($tree4{$_->[1]}) if $_->[1];
    ok $tw->previous_sibling, $_->[2] ? $tree4{$_->[2]} : undef,
        'previous_sibling [6] ' . $_->[0] . ' previous_sibling';
    ok $tw->current_node, $tree4{$_->[2] || $_->[1] || $_->[0]},
        'previous_sibling [6] ' . $_->[0] . ' current_node';
  }
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/14 16:32:28 $
