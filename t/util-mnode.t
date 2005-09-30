use Test;
use Message::Util::ManakaiNode;
plan tests => 28;

my $node = Message::Util::ManakaiNode::ManakaiNodeStem->_new ('Test1');

ok $node->{rc}, 0;

my $ref = bless {
  node => $node,
  t => 'Test1',
}, 'Message::Util::ManakaiNode::ManakaiNodeRef';
$node->{rc}++;
${$node->{grc}}++;

ok $node->{rc}, 1;

my $ref2 = bless {
  node => $node,
  t => 'Test1',
}, 'Message::Util::ManakaiNode::ManakaiNodeRef';
$node->{rc}++;
${$node->{grc}}++;

ok $node->{rc}, 2;

undef $ref;

ok $node->{rc}, 1;

my $nid = $node->{nid};
my $tid = $node->{tid};

ok $node->_is_same_node ($node), 1, "Same node is same node";
ok $node eq $node, 1, "Same node is same node";
ok !!($node eq ''.$node), !!0, "Stringified value is not same node";

my $node2 = $node->_new ('Test1');
ok $nid ne $node2->{nid}, 1, "Node ID is unique";
ok $$tid ne ${$node2->{tid}}, 1, "Tree ID is unique";

ok !!($node eq $node2), !!0, "Different nodes are different nodes";

$node->_import_tree ($node2);
ok $$tid, ${$node2->{tid}}, "Tree imported";

push @{$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{Test1}->{s}||=[]}, 'child';
$node->{child} = [$node2];

push @{$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{Test1}->{o}||=[]}, 'parent';
$node2->{parent} = $node;

push @{$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{Test1}->{s}||=[]}, 'child2';
$node->{child2} = [$node2];
push @{$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{Test1}->{o}||=[]}, 'parent2';
$node2->{parent2} = $node;

my $node3 = $node2->_new ('Test1');
$node->_import_tree ($node3);
push @{$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{Test1}->{s}||=[]}, 'child2';
$node->{child2} = [];
$node3->{child2} = [$node2];
$node2->{parent2} = $node3;

push @{$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{Test1}->{o}||=[]}, 'parent';
$node3->{parent} = $node;
push @{$node->{child2}}, $node3;

ok $node->_is_externally_referred, 1, "Tree is externally referred";
ok $node2->_is_externally_referred, 1, "Tree is externally referred";
ok $node3->_is_externally_referred, 1, "Tree is externally referred";

undef $ref2;

ok exists $node->{child} ?0:1, 1, '$node->{child} deleted';
ok exists $node->{child2} ?0:1, 1, '$node->{child2} deleted';
ok exists $node3->{child2} ?0:1, 1, '$node3->{child2} deleted';
ok exists $node2->{parent} ?0:1, 1, '$node2->{parent} deleted';
ok exists $node2->{parent2} ?0:1, 1, '$node2->{parent2} deleted';
ok exists $node3->{parent2} ?0:1, 1, '$node3->{parent2} deleted';
