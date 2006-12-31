#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-12-31T09:34:35+00:00,
## 	from file "../DOM/TreeStore.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.TreeStore>.
## Don't edit by hand!
use strict;
require Message::DOM::DOMCore;
package Message::DOM::TreeStore;
our $VERSION = 20061231.0934;
package Message::DOM::IF::DOMImplementationTreeStore;
our $VERSION = 20061231.0934;
package Message::DOM::TreeStore::ManakaiDOMImplementationTreeStore;
our $VERSION = 20061231.0934;
push our @ISA, 'Message::DOM::IF::DOMImplementation',
'Message::DOM::IF::DOMImplementation',
'Message::DOM::IF::DOMImplementationTreeStore';
push @Message::DOM::DOMCore::ManakaiDOMImplementation::ISA, q<Message::DOM::TreeStore::ManakaiDOMImplementationTreeStore> unless Message::DOM::DOMCore::ManakaiDOMImplementation->isa (q<Message::DOM::TreeStore::ManakaiDOMImplementationTreeStore>);
sub create_storable_object_from_node ($$) {
my ($self, $in) = @_;
my $r;

{

if 
({
  
9
 => 
1
,
  
11
 => 
1
,
  
1
 => 
1
,
  
2
 => 
1
,
  
3
 => 
1
,
  
4
 => 
1
,
}->{$in->
node_type
}) {
  my @target = ([$in,   # node
                 
undef
]); # origin
  
  while (@target) {
    my $target = shift @target;
    my $tnt = $target->[0]->
node_type
;
    if ($tnt == 
1
) {
      my $v = {};
      
      my $pv = ${$target->[0]}->{
'ns'
};
      $v->{namespace_uri} = $pv if defined $pv;

      $pv = ${$target->[0]}->{
'ln'
};
      $v->{local_name} = $pv;

      $pv = ${$target->[0]}->{
'pfx'
};
      $v->{prefix} = $pv if defined $pv;

      for (@{$target->[0]->
child_nodes
}) {
        push @target, [$_, $v];
      }
      for (@{$target->[0]->
attributes
}) {
        push @target, [$_, $v];
      }
      if (defined $target->[1]) {
        push @{$target->[1]->{child_nodes} ||= []}, $v;
      } else {
        $r = $v unless defined $r;
      }
    } elsif ($tnt == 
2
) {
      my $v = {
        value => \ $target->[0]->
value
,
      };
      
      my $pv = ${$target->[0]}->{
'ns'
};
      $v->{namespace_uri} = $pv if defined $pv;

      $pv = ${$target->[0]}->{
'ln'
};
      $v->{local_name} = $pv;

      $pv = ${$target->[0]}->{
'pfx'
};
      $v->{prefix} = $pv if defined $pv;

      if (defined $target->[1]) {
        push @{$target->[1]->{attributes} ||= []}, $v;
      } else {
        $r = $v unless defined $r;
      }
    } elsif ($tnt == 
3 or
             
$tnt == 
4
) {
      my $v = {};
      $v->{data} = ${$target->[0]}->{
'con'
};

      if (defined $target->[1]) {
        push @{$target->[1]->{child_nodes} ||= []}, $v;
      } else {
        $r = $v unless defined $r;
      }
    } elsif ($tnt == 
9
) {
      my $v = {
        xml_version => $target->[0]->
xml_version
,
      };
      
      for (@{$target->[0]->
child_nodes
}) {
        push @target, [$_, $v];
      }
      $r = $v unless defined $r;
    } elsif ($tnt == 
11
) {
      my $v = {};
      
      for (@{$target->[0]->
child_nodes
}) {
        push @target, [$_, $v];
      }
      $r = $v unless defined $r;
    } elsif ($tnt == 
5
) {
      for (@{$target->[0]->
child_nodes
}) {
        push @target, [$_, $target->[1]];
      }
    }
  }
} else {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NOT_SUPPORTED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'create_storable_object_from_node', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#CLONE_NODE_TYPE_NOT_SUPPORTED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::TreeStore::ManakaiDOMImplementationTreeStore', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'in', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#node' => $in;

;
}


}
$r}
sub create_node_from_storable_object ($$;$) {
my ($self, $in, $od) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $od = $self->
create_document
;
  my $orig_strict = $od->
strict_error_checking
;
  $od->
strict_error_checking
 (
0
);

  my @target = ([$in,
                 
undef
,   # parent node
                 
undef
]); # owner element
  while (@target) {
    my $target = shift @target;
    if (defined $target->[0]->{local_name}) {
      if (defined $target->[0]->{value}) {
      # Attribute
        my $node = $od->
create_attribute_ns

                          ($target->[0]->{namespace_uri},
                           [$target->[0]->{prefix},
                            $target->[0]->{local_name}]);
        $node->
manakai_append_text
 ($target->[0]->{value});
        if (defined $target->[2]) {
          $target->[2]->
set_attribute_node_ns
 ($node);
        } else {
          $r = $node unless defined $r;
        }
      } else {
      # Element
        my $node = $od->
create_element_ns

                          ($target->[0]->{namespace_uri},
                           [$target->[0]->{prefix},
                            $target->[0]->{local_name}]);
        for (@{ref $target->[0]->{child_nodes} eq 'ARRAY'
                 ? $target->[0]->{child_nodes} : []}) {
          push @target, [$_, $node];
        }
        for (@{ref $target->[0]->{attributes} eq 'ARRAY'
                 ? $target->[0]->{attributes} : []}) {
          push @target, [$_, 
undef
, $node];
        }
        if (defined $target->[1]) {
          $target->[1]->
append_child
 ($node);
        } else {
          $r = $node unless defined $r;
        }
      }
    } elsif (defined $target->[0]->{data}) {
    # Text
      if (defined $target->[1]) {
        $target->[1]->
manakai_append_text

                        ($target->[0]->{data});
      } elsif (not defined $r) {
        $r = $od->
create_text_node
 ('');
        $r->
manakai_append_text
 ($target->[0]->{data});
      }
    } elsif (defined $target->[0]->{xml_version}) {
    # Document
      my $node = $self->
create_document
;
      $node->
strict_error_checking
 (
0
);
      $node->
dom_config

           ->
set_parameter

               (
'http://suika.fam.cx/www/2006/dom-config/strict-document-children'
 => 
0
);
      $node->
xml_version
 ($target->[0]->{xml_version});
      for (@{ref $target->[0]->{child_nodes} eq 'ARRAY'
               ? $target->[0]->{child_nodes} : []}) {
        push @target, [$_, $node];
      }
      unless (defined $r) {
        $r = $node;
        $od = $node;
        $orig_strict = 
1
;
      }
    } else {
    # Document fragment
      unless (defined $r) {
        $r = $od->
create_document_fragment
;
        for (@{ref $target->[0]->{child_nodes} eq 'ARRAY'
                 ? $target->[0]->{child_nodes} : []}) {
          push @target, [$_, $r];
        }
      }
    }
  }
  $od->
strict_error_checking
 ($orig_strict);
  if ($r->
node_type
 == 
9
) {
    $r->
dom_config

      ->
set_parameter

          (
'http://suika.fam.cx/www/2006/dom-config/strict-document-children'
 => 
undef
);
  }



}


;}

;


}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::TreeStore::ManakaiDOMImplementationTreeStore>}->{has_feature} = {'',
{'',
'1'},
'http://suika.fam.cx/www/2006/feature/min',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/www/2006/feature/treestore',
{'',
'1',
'3.0',
'1'},
'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum',
{'',
'1',
'3.0',
'1'},
'xml',
{'',
'1',
'1.0',
'1',
'2.0',
'1',
'3.0',
'1'},
'xmlversion',
{'',
'1',
'1.0',
'1',
'1.1',
'1'}};
$Message::DOM::ClassPoint{q<Message::DOM::TreeStore::ManakaiDOMImplementationTreeStore>} = 14.1;
for ($Message::DOM::IF::DOMImplementation::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
