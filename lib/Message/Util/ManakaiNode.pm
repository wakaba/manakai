#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-12-31T09:20:46+00:00,
## 	from file "ManakaiNode.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/ManakaiNode>.
## Don't edit by hand!
use strict;
package Message::Util::ManakaiNode;
our $VERSION = 20061231.0920;
package Message::Util::IF::NodeStem;
our $VERSION = 20061231.0920;
package Message::Util::ManakaiNode::ManakaiNodeStem;
our $VERSION = 20061231.0920;
push our @ISA, 'Message::Util::IF::NodeStem';
sub _new ($$) {
my ($self, $className) = @_;
my $r;

{

my 
$grc = 0;
$r = bless {
  
't'
   => $className,
  
'grc'
 => \$grc,
  
'rc'
     => 0,
  
'tid'
 => \ (
(
  'tag:suika.fam.cx,2005-09:' . time . ':' . $$ . ':' .
  ($Message::Util::ManakaiNode::UniqueIDR ||=
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62]) .
  (++$Message::Util::ManakaiNode::UniqueIDN)
)
),
  
'nid'
 => 
(
  'tag:suika.fam.cx,2005-09:' . time . ':' . $$ . ':' .
  ($Message::Util::ManakaiNode::UniqueIDR ||=
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62]) .
  (++$Message::Util::ManakaiNode::UniqueIDN)
)
,
}, ref $self || $self;


}
$r}
sub _new_node ($$) {
my ($self, $className) = @_;
my $r;

{


$r = bless {
  
't'
   => $className,
  
'grc'

                 => $self->{
'grc'
},
  
'rc'
     => 0,
  
'tid'
 => $self->{
'tid'
},
  
'nid'
 => 
(
  'tag:suika.fam.cx,2005-09:' . time . ':' . $$ . ':' .
  ($Message::Util::ManakaiNode::UniqueIDR ||=
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62]) .
  (++$Message::Util::ManakaiNode::UniqueIDN)
)
,
}, ref $self;


}
$r}
sub _is_externally_referred ($) {
my ($self) = @_;
my $r;

{

if 
($self->{
'rc'
}) {
  $r = 
1
;
} else {
  my @node = ($self);
  my %checked;
  NODES: while (@node) {
    my $node = shift @node;
    next NODES unless ref $node;
    if ($node->{
'rc'
}) {
      $r = 
1
;
      last NODES;
    } elsif ($checked{$node->{
'nid'
}}) {
      next NODES;
    }
    my @n;
    my $nt = $Message::Util::ManakaiNode::ManakaiNodeRef::Prop{
      $node->{
't'
}
    }; 
    for my $p (@{$nt->{
's2'
}}) {
      if (ref $node->{$p} eq 'ARRAY') {
        push @n, @{$node->{$p}};
      } elsif (ref $node->{$p} eq 'HASH') {
        push @n, values %{$node->{$p}};
      }
    }
    for my $p (@n,
               map {$node->{$_}} @{$nt->{
's'
}}) {
      if (ref $p eq 'ARRAY') {
        push @node, @$p;
      } elsif (ref $p eq 'HASH') {
        push @node, values %$p;
      }
    }
    for my $p (@{$nt->{
'o'
}}) {
      unshift @node, $node->{$p} if $node->{$p};
      ## NOTE: Puts the top of the list,
      ##       since upper-level nodes are expected to be referred
      ##       more than lower-levels.
    }
    for my $p (@{$nt->{
's0'
}}) {
      push @node, $node->{$p} if $node->{$p};
    }
    $checked{$node->{
'nid'
}} = 
1
;
  }
}


}
$r}
sub _destroy ($) {
my ($self) = @_;

{

my 
@node = ($self);
my $tid = $self->{
'tid'
} || \'';
my %xrnode;
NODES: while (@node) {
  my $node = shift @node;
  next NODES unless ref $node and defined $node->{
'nid'
};
  my @n;
      my $nt = $Message::Util::ManakaiNode::ManakaiNodeRef::Prop{
        $node->{
't'
}
      }; 
      for my $p (@{$nt->{
's2'
}||[]}) {
        my $ref = ref $node->{$p};
        if ($ref eq 'HASH') {
          push @n, values %{$node->{$p}};
        } elsif ($ref eq 'ARRAY') {
          push @n, @{$node->{$p}};
        }
      }
      for my $p (@n, map {$node->{$_}} @{$nt->{
's'
}||[]}) {
        my $ref = ref $p;
        if ($ref eq 'ARRAY') {
          push @node, @$p;
        } elsif ($ref eq 'HASH') {
          push @node, values %$p;
        }
      }
      for my $p (@{$nt->{
'o'
}||[]},
             @{$nt->{
's0'
}||[]}) {
        push @node, $node->{$p};
      }

  $node->
_destroy_node_stem
;

  for my $p (@{$nt->{
'x'
}||[]}) {
    if (defined $node->{$p} and 
        ${$node->{$p}->{
'tid'
}||$tid} ne $$tid) {
      $node->{$p}->{
'rc'
}--;
      ${$node->{$p}->{
'grc'
}}--;
      $xrnode{${$node->{$p}->{
'tid'
}}} = $node->{$p};
    }
  }

  %$node = ();
} # @node

CORE::delete $xrnode{$$tid};
for my $node (values %xrnode) {
  unless (
(${$node->{'grc'}} > 0)
) {
    $node->
_destroy
;
  }
}


}
}
sub _destroy_node_stem ($) {
my ($self) = @_;

{


## No action by default


}
}
sub _import_tree ($$) {
my ($self, $node) = @_;

{

my 
@node = ($node);
my $newgrc = $self->{
'grc'
};
my $newtid = $self->{
'tid'
};
my $oldtid = $node->{
'tid'
};
my @xrnode;
NODES: while (@node) {
  my $node = shift @node;
  next NODES unless ref $node;
  next NODES if ${$node->{
'tid'
}} eq $$newtid;
  my @n;
    my $nt = $Message::Util::ManakaiNode::ManakaiNodeRef::Prop{
      $node->{
't'
}
    }; 
    for my $p (@{$nt->{
's2'
}||[]}) {
      my $ref = ref $node->{$p};
      if ($ref eq 'HASH') {
        push @n, values %{$node->{$p}};
      } elsif ($ref eq 'ARRAY') {
        push @n, @{$node->{$p}};
      }
    }
    for my $p (@n, map {$node->{$_}} @{$nt->{
's'
}||[]}) {
      my $ref = ref $p;
      if ($ref eq 'ARRAY') {
        push @node, @$p;
      } elsif ($ref eq 'HASH') {
        push @node, values %$p;
      }
    }
  for my $p (@{$nt->{
'o'
}||[]},
           @{$nt->{
's0'
}||[]}) {
    push @node, $node->{$p} if defined $node->{$p};
  }

  for (@{$nt->{
'x'
}||[]}) {
    push @xrnode, $node->{$_} if defined $node->{$_};
  }

  ${$node->{
'grc'
}} -= $node->{
'rc'
};
  $node->{
'tid'
} = $newtid;
  $node->{
'grc'
} = $newgrc;
  $$newgrc += $node->{
'rc'
};
}

for my $n (@xrnode) {
  if (${$n->{
'tid'
}} eq $$oldtid) {
    $n->{
'rc'
}++;
    ${$n->{
'grc'
}}++;
  } elsif (${$n->{
'tid'
}} eq $$newtid) {
    $n->{
'rc'
}--;
    ${$n->{
'grc'
}}--;
    ## Is it necessary to test whether rc is 0 or not
    ## and if so call "destroy" method?  Maybe it need not
    ## (or should not, rather).
  }
}


}
}
sub _change_tree_id ($$$) {
my ($self, $treeID, $groveRC) = @_;

{

my 
$tid = ref $treeID ? $treeID : \$treeID;
my $oldtid = $self->{
'tid'
};
my @xrnode;
my @node = ($self);
NODES: while (@node) {
  my $node = shift @node;
  next NODES unless ref $node;
  next NODES if ${$node->{
'tid'
}} eq $$tid;
    my @n;
    my $nt = $Message::Util::ManakaiNode::ManakaiNodeRef::Prop{
      $node->{
't'
}
    }; 
    for my $p (@{$nt->{
's2'
}||[]}) {
      if (ref $node->{$p} eq 'ARRAY') {
        push @n, @{$node->{$p}};
      } elsif (ref $node->{$p} eq 'HASH') {
        push @n, values %{$node->{$p}};
      }
    }
    for my $p (@n,
               map {$node->{$_}} @{$nt->{
's'
}||[]}) {
      if (ref $p eq 'ARRAY') {
        push @node, @$p;
      } elsif (ref $p eq 'HASH') {
        push @node, values %$p;
      }
    }
  for my $p (@{$nt->{
'o'
}||[]},
               @{$nt->{
's0'
}||[]}) {
    push @node, $node->{$p};
  }

  for (@{$nt->{
'x'
}||[]}) {
    push @xrnode, $node->{$_} if defined $node->{$_};
  }

  ${$node->{
'grc'
}} -= $node->{
'rc'
};
  $node->{
'tid'
} = $tid;
  $node->{
'grc'
} = $groveRC;
  ${$node->{
'grc'
}} += $node->{
'rc'
};
}

for my $n (@xrnode) {
  if (${$n->{
'tid'
}} eq $$oldtid) {
    $n->{
'rc'
}++;
    ${$n->{
'grc'
}}++;
  } elsif (${$n->{
'tid'
}} eq $$tid) {
    $n->{
'rc'
}--;
    ${$n->{
'grc'
}}--;
    ## Is it necessary to test whether rc is 0 or not
    ## and if so call "destroy" method?  Maybe it need not
    ## (or should not, rather).
  }
}


}
}
sub _is_same_node ($$) {
my ($self, $node) = @_;
my $r;

{

if 
(ref $node and
    UNIVERSAL::isa ($node, 
'Message::Util::ManakaiNode::ManakaiNodeStem'
) and
    $node->{
'nid'
} eq $self->{
'nid'
}) {
  $r = 
1
;
}


}
$r}
sub _orphanate ($) {
my ($self) = @_;

{

if 
($self->
_is_externally_referred
) {
  my $grc = 0;
  $self->
_change_tree_id

               (\(
(
  'tag:suika.fam.cx,2005-09:' . time . ':' . $$ . ':' .
  ($Message::Util::ManakaiNode::UniqueIDR ||=
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62] .
    [qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        0 1 2 3 4 5 6 7 8 9/]->[rand 62]) .
  (++$Message::Util::ManakaiNode::UniqueIDN)
)
), \$grc);
} else {
  $self->
_destroy
;
}


}
}
use overload 
bool => sub () {1}, 
'eq' => '_is_same_node', 
fallback => 1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::Util::ManakaiNode::ManakaiNodeStem>}->{has_feature} = {};
$Message::DOM::ClassPoint{q<Message::Util::ManakaiNode::ManakaiNodeStem>} = 0;
package Message::Util::ManakaiNode::ManakaiNodeRef;
our $VERSION = 20061231.0920;
push our @ISA, 'Message::Util::IF::NodeRef';
sub free ($) {
my ($self) = @_;

{


$self->{
'node'
}->
_destroy
;


}
}
sub DESTROY ($) {
my ($self) = @_;

{

if 
(my $node = $self->{
'node'
}) {
  CORE::delete $self->{
'node'
};
  unless ($self->{
'w'
}) {
    $node->{
'rc'
}--;
    ${$node->{
'grc'
}}--;
    unless (
(${$node->{'grc'}} > 0)
) {
      $node->
_destroy
;
    }
  }
} else {
  warn ref ($self) . q{->DESTROY: there is no associated }.
       q{node object - you have a global variable or }.
       qq{potential memory-leak detected\n};
}


}
}
*_destroy = \&DESTROY;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::Util::ManakaiNode::ManakaiNodeRef>}->{has_feature} = {};
$Message::DOM::ClassPoint{q<Message::Util::ManakaiNode::ManakaiNodeRef>} = 0;
$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{q<Message::Util::ManakaiNode::ManakaiNodeRef>} = {};
package Message::Util::IF::NodeRef;
our $VERSION = 20061231.0920;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
