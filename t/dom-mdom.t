use Test;
use Message::DOM::ManakaiDOM;
use Data::Dumper;
use Message::Util::QName::General [qw/ExpandedURI/], {

};

plan tests => 1;

my $node = Message::DOM::ManakaiDOMNodeObject->_new;

ok $node->{rc}, 0;

my $ref = $node->_newReference;

ok $node->{rc}, 1;

my $ref2 = $node->_newReference;

ok $node->{rc}, 2;

undef $ref;

ok $node->{rc}, 1;

my $nid = $node->{nodeID};
my $tid = $node->{treeID};

ok $node->_isSameNode ($node), 1, "Same node is same node";
ok $node eq $node, 1, "Same node is same node";
ok $node eq ''.$node, 0, "Stringified value is not same node";

my $node2 = $node->_new ();
ok $nid ne $node2->{nodeID}, 1, "Node ID is unique";
ok $tid ne $node2->{treeID}, 1, "Tree ID is unique";

ok $node eq $node2, 0, "Different nodes are different nodes";

ok $node->_getRootNodes->[0] eq $node, 1, "Root node is myself";

$node->_importTree ($node2);
ok $tid, $node2->{treeID}, "Tree imported";

push @{$node->{subnode}}, 'child';
$node->{child} = [$node2];
push @{$node2->{origin}}, 'parent';
$node2->{parent} = $node;

ok $node2->_getRootNodes->[0] eq $node, 1, 'Root node is $node';

push @{$node->{subnode}}, 'child2';
$node->{child2} = [$node2];
push @{$node2->{origin}}, 'parent2';
$node2->{parent2} = $node;

ok @{$node2->_getRootNodes}, 1, "There is ONE root node";

my $node3 = $node2->_new;
$node->_importTree ($node2);
push @{$node3->{subnode}}, 'child2';
$node->{child2} = [];
$node3->{child2} = [$node2];
$node2->{parent2} = $node3;
ok @{$node2->_getRootNodes}, 2, "There are TWO root nodes";

push @{$node3->{origin}||=[]}, 'parent';
$node3->{parent} = $node;
push @{$node->{child2}}, $node3;
ok @{$node2->_getRootNodes}, 1, "There is ONE root node";

ok $node3->_isExternallyReferred, 1, "Tree is externally referred";
{
local $node->{rc} = 0;
ok $node3->_isExternallyReferred, 0, "Tree is not externally referred";
}

undef $ref2;

ok exists $node->{child} ?0:1, 1, '$node->{child} deleted';
ok exists $node->{child2} ?0:1, 1, '$node->{child2} deleted';
ok exists $node3->{child2} ?0:1, 1, '$node3->{child2} deleted';
ok exists $node2->{parent} ?0:1, 1, '$node2->{parent} deleted';
ok exists $node2->{parent2} ?0:1, 1, '$node2->{parent2} deleted';
ok exists $node3->{parent2} ?0:1, 1, '$node3->{parent2} deleted';

#print Dumper $node3;
#print Dumper $node2;
#print Dumper $node;



