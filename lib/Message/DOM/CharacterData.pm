#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-04-16T12:54:40+00:00,
## 	from file "CharacterData.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.CharacterData>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::DOM::DOMCore;
require Message::DOM::TreeCore;
require Message::Util::Error::DOMException;
package Message::DOM::CharacterData;
our $VERSION = 20060416.1254;
package Message::DOM::IFLatest::CharacterData;
our $VERSION = 20060416.1254;
package Message::DOM::CharacterData::ManakaiDOMCharacterData;
our $VERSION = 20060416.1254;
push our @ISA, 'Message::DOM::TreeCore::ManakaiDOMNode',
'Message::DOM::IF::CharacterData',
'Message::DOM::IF::Node',
'Message::DOM::IFLatest::CharacterData',
'Message::DOM::IFLatest::Node',
'Message::DOM::IFLatest::StringExtended',
'Message::DOM::IFLevel1::CharacterData',
'Message::DOM::IFLevel1::Node',
'Message::DOM::IFLevel2::CharacterData',
'Message::DOM::IFLevel2::Node',
'Message::DOM::IFLevel3::CharacterData',
'Message::DOM::IFLevel3::Node';
use Message::Util::Error;
sub ___create_node_stem ($$$$) {
my ($self, $bag, $obj, $opt) = @_;
my $r = {};

{


$obj->{
'con'
} = $opt->{
'con'
};


{


$obj->{'od'} = $opt->{'od'}->{
'id'
};
$bag->{${$opt->{'od'}->{
'id'
}}}
    ->{'do'}->{${$obj->{
'id'
}}}
  = $obj->{
'id'
};


}

;
$r = $obj;


}
$r}
sub child_nodes ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


{


$r = bless [], 
'Message::DOM::TreeCore::ManakaiDOMEmptyNodeList'
;


}

;


}
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'child_nodes';
}
}
sub append_child ($$) {
my ($self, $newChild) = @_;
my $r;

{

report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'HIERARCHY_REQUEST_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'append_child', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#HIERARCHY_BAD_TYPE', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'newChild', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#node' => $newChild;

;


}
$r}
sub insert_before ($$;$) {
my ($self, $newChild, $refChild) = @_;
my $r;

{

report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'HIERARCHY_REQUEST_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'insert_before', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#HIERARCHY_BAD_TYPE', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'newChild', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#node' => $newChild;

;


}
$r}
sub replace_child ($$$) {
my ($self, $newChild, $oldChild) = @_;
my $r;

{

report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'HIERARCHY_REQUEST_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'replace_child', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#HIERARCHY_BAD_TYPE', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'newChild', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#node' => $newChild;

;


}
$r}
sub manakai_append_text ($$) {
my ($self, $string) = @_;
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{


  if 
($self->
owner_document

           ->
strict_error_checking and
      
$self->
manakai_read_only
) {
    

{

local $Error::Depth = $Error::Depth - 1;

{

report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'manakai_append_text', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData';


}


;}

;
  }
  my $v;
  

{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
  $$v .= ref $string eq 'SCALAR' ? $$string : $string;
  $r = $self;



}


;}

;


}
$r}
sub node_value ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

my 
$v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$r = $$v;


}
$r;
} else {my ($self, $given) = @_;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;
my $v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$$v = defined $given ? $given : '';
        ## NOTE: Setting NULL is supported for
        ##       compatibility with |textContent|.


}
}
}
sub text_content ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

my 
$v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$r = $$v;


}
$r;
} else {my ($self, $given) = @_;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;
my $v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$$v = defined $given ? $given : '';
        ## NOTE: Setting NULL is supported for
        ##       compatibility with |textContent|.


}
}
}
sub base_uri ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$pe = $self->
parent_node
;
  W: {
    while (defined $pe) {
      my $nt = $pe->
node_type
;
      if ($nt == 
'1' or
          
$nt == 
'2' or
          
$nt == 
'9' or
          
$nt == 
'11' or
          
$nt == 
'6'
) {
        $r = $pe->
base_uri
;
        last W;
      } elsif ($nt == 
'5'
) {
        if ($pe->
manakai_external
) {
          $r = $pe->
manakai_entity_base_uri
;
          last W;
        }
      }
      $pe = $pe->
parent_node
;
    }
    if ($pe) {
      $r = $pe->
base_uri
;
    } else {
      $r = $self->
owner_document
->
base_uri
;
    }
  } # W



}


;}

;


}
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'base_uri';
}
}
sub find_offset16 ($$) {
my ($self, $offset32) = @_;
my $r = 0;

{

my 
$v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;

if (not defined $offset32 or $offset32 < 0 or
    CORE::length ($$v) < $offset32) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#index' => $offset32, '-type' => 'INDEX_SIZE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'find_offset16', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#StringIndexOutOfBoundsException', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'offset32';

;
}

my $ss = substr $$v, 0, $offset32;
$r = $offset32;
if ($ss =~ /[\x{10000}-\x{10FFFF}]/) {
  while ($ss =~ /[\x{10000}-\x{10FFFF}]+/g) {
    $r += $+[0] - $-[0];
  }
}


}
$r}
sub find_offset32 ($$) {
my ($self, $offset16) = @_;
my $r = 0;

{

my 
$v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;

if (not defined $offset16 or $offset16 < 0) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#index' => $offset16, '-type' => 'INDEX_SIZE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'find_offset32', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#StringIndexOutOfBoundsException', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'offset16';

;
}

my $o = $offset16;
while ($o > 0) {
  my $c = substr ($$v, $r, 1);
  if (length $c) {
    if ($c =~ /[\x{10000}-\x{10FFFF}]/) {
      $o -= 2;
    } else {
      $o--;
    }
    $r++;
  } else {
    
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#index' => $offset16, '-type' => 'INDEX_SIZE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'find_offset32', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#StringIndexOutOfBoundsException', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'offset16';

;
  }
}


}
$r}
sub data ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{

my 
$v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$r = $$v;


}
$r;
} else {my ($self, $given) = @_;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;
my $v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$$v = defined $given ? $given : '';
        ## NOTE: Setting NULL is supported for
        ##       compatibility with |textContent|.


}
}
}
sub length ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = 0;

{

my 
$v;


{


$v = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'con'};


}

;
$r = CORE::length $$v;
$r++ while $$v =~ /[\x{10000}-\x{10FFFF}]/g;


}
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'length';
}
}
sub substring_data ($$$) {
my ($self, $offset, $count) = @_;
my $r = '';

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;
if ($count < 0) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'INDEX_SIZE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'substring_data', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#length' => $count, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#NEGATIVE_LENGTH_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'count';

;
}
my $eoffset32;


try {local $Error::Depth = $Error::Depth + 3;


  $eoffset32 = $self->
find_offset32

                        ($offset + $count);
} catch 
Message::DOM::IFLatest::DOMException with 
{
  my $err = shift;
  if ($err->subtype eq 
'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#StringIndexOutOfBoundsException'
) {
    $eoffset32 = ($offset + $count) * 2;
  } else {
    $err->throw;
  }
};


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$offset32 = $self->
find_offset32
 ($offset);
  my $data = $self->
data
;
  $r = substr ($data, $offset32, $eoffset32 - $offset32);



}


;}

;


}
$r}
sub append_data ($$) {
my ($self, $arg) = @_;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $self->
manakai_append_text
 (\$arg);



}


;}

;


}
}
sub insert_data ($$$) {
my ($self, $offset, $arg) = @_;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$offset32 = $self->
find_offset32
 ($offset);
  my $data = $self->
data
;
  substr ($data, $offset32, 0) = $arg;
  $self->
data
 ($data);



}


;}

;


}
}
sub delete_data ($$$) {
my ($self, $offset, $count) = @_;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;
if ($count < 0) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'INDEX_SIZE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'delete_data', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#length' => $count, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#NEGATIVE_LENGTH_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMCharacterData', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name' => 'count';

;
}
my $eoffset32;


try {local $Error::Depth = $Error::Depth + 3;


  $eoffset32 = $self->
find_offset32

                        ($offset + $count);
} catch 
Message::DOM::IFLatest::DOMException with 
{
  my $err = shift;
  if ($err->subtype eq 
'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#StringIndexOutOfBoundsException'
) {
    $eoffset32 = ($offset + $count) * 2;
  } else {
    $err->throw;
  }
};


{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$offset32 = $self->
find_offset32
 ($offset);
  my $data = $self->
data
;
  substr ($data, $offset32, $eoffset32 - $offset32) = '';
  $self->
data
 ($data);



}


;}

;


}
}
sub replace_data ($$$$) {
my ($self, $offset, $count, $arg) = @_;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $self->
delete_data
 ($offset, $count);
  $self->
insert_data
 ($offset, $arg);



}


;}

;


}
}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::CharacterData::ManakaiDOMCharacterData>}->{has_feature} = {'core',
{'',
'1',
'1.0',
'1',
'2.0',
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
$Message::DOM::ClassPoint{q<Message::DOM::CharacterData::ManakaiDOMCharacterData>} = 14.1;
$Message::Util::Grove::ClassProp{q<Message::DOM::CharacterData::ManakaiDOMCharacterData>} = {'o0',
['parent'],
'w0',
['od']};
package Message::DOM::IFLatest::Text;
our $VERSION = 20060416.1254;
package Message::DOM::CharacterData::ManakaiDOMText;
our $VERSION = 20060416.1254;
push our @ISA, 'Message::DOM::CharacterData::ManakaiDOMCharacterData',
'Message::DOM::IF::CharacterData',
'Message::DOM::IF::Node',
'Message::DOM::IF::Text',
'Message::DOM::IFLatest::CharacterData',
'Message::DOM::IFLatest::Node',
'Message::DOM::IFLatest::Text',
'Message::DOM::IFLevel1::CharacterData',
'Message::DOM::IFLevel1::Node',
'Message::DOM::IFLevel1::Text',
'Message::DOM::IFLevel2::CharacterData',
'Message::DOM::IFLevel2::Node',
'Message::DOM::IFLevel2::Text',
'Message::DOM::IFLevel3::CharacterData',
'Message::DOM::IFLevel3::Node',
'Message::DOM::IFLevel3::Text';
sub node_type ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;
$r = '3';
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMText', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'node_type';
}
}
sub node_name ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '#text';
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMText', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'node_name';
}
}
sub get_feature ($$$) {
my ($self, $feature, $version) = @_;

{


$feature = lc $feature;


}

{


$version = '' unless defined $version;


}
my $r;

{


$feature =~ s/^\+//;


{

if 
($Message::DOM::DOMFeature::ClassInfo->{ref $self}
      ->{has_feature}->{$feature}->{$version}) {
  $r = $self;
} else {
  CLASS: for my $__class (sort {
    $Message::DOM::ClassPoint{$b} <=> $Message::DOM::ClassPoint{$a}
  } grep {
    $Message::DOM::DOMFeature::ClassInfo->{'Message::DOM::CharacterData::ManakaiDOMText'}
        ->{compat_class}->{$_}
  } keys %{$Message::DOM::DOMFeature::ClassInfo->{'Message::DOM::CharacterData::ManakaiDOMText'}
               ->{compat_class} or {}}) {
    if ($Message::DOM::DOMFeature::ClassInfo->{$__class}
            ->{has_feature}->{$feature}->{$version}) {
      

{


$r = ${($self->{'b'})->{${($self->{'id'})}}->{
'cls'
}}->___create_node_ref ({
  
'id'
 => ($self->{'id'}),
  
'b'
 => ($self->{'b'}),
}, {
          'nrcls' => \$__class,
        });
($self->{'b'})->{${($self->{'id'})}}->{
'rc'
}++;


}

;
      last CLASS;
    }
  } # CLASS
}


}

;
unless (defined $r) {
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $r = $self->SUPER::get_feature ($feature, $version);
  


}


;}

;
}


}
$r}
sub is_element_content_whitespace ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = 0;

{


{


$r = $self->{
'b'
}->{${$self->{
'id'
}}}
         ->{'ecws'};


}

;


}
$r;
} else {my ($self, $given) = @_;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

;


{


$self->{
'b'
}->{${$self->{
'id'
}}}
    ->{'ecws'} = $given;


}

;


}
}
}
sub whole_text ($;$) {
if (@_ == 1) {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NOT_SUPPORTED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#MDOM_IMPL_ATTR_NOT_IMPLEMENTED', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMText', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'whole_text';
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMText', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'whole_text';
}
}
sub replace_whole_text ($$) {
my ($self, $content) = @_;
my $r;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NOT_SUPPORTED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'replace_whole_text', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#MDOM_IMPL_METHOD_NOT_IMPLEMENTED', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMText';
$r}
sub split_text ($$) {
my ($self, $offset) = @_;
my $r;

{


{

if 
($self->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_THIS', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2005/manakai/DOM/TreeCore/NodeReadOnlyError+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest';

;
}


}

; 
my $parent = $self->
parent_node
;
if (defined $parent and $parent->
manakai_read_only
) {
  
report Message::DOM::DOMCore::ManakaiDOMException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'split_text', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#NOMOD_PARENT', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMText';

;
}



{

local $Error::Depth = $Error::Depth + 1;

{


  my 
$offset32 = $self->
find_offset32
 ($offset);
  my $data1 = $self->
data
;
  my $data2 = substr ($data1, $offset32);
  substr ($data1, $offset32) = '';

  $r = $self->
node_type
 == 
'3'

         ? $self->
owner_document

                ->
create_text_node
 ($data2)
         : $self->
owner_document

                ->
create_cdata_section
 ($data2);
  $r->
is_element_content_whitespace

        ($self->
is_element_content_whitespace
);
  $self->
data
 ($data1);
  if (defined $parent) {
    $parent->
insert_before

               ($r, $self->
next_sibling
);
  }



}


;}

;


}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::CharacterData::ManakaiDOMText>}->{has_feature} = {'core',
{'',
'1',
'1.0',
'1',
'2.0',
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
$Message::DOM::ClassPoint{q<Message::DOM::CharacterData::ManakaiDOMText>} = 14.1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::TreeCore::ManakaiDOMText>}->{compat_class}->{q<Message::DOM::CharacterData::ManakaiDOMText>} = 1;
$Message::Util::Grove::ClassProp{q<Message::DOM::CharacterData::ManakaiDOMText>} = {'o0',
['parent'],
'w0',
['od']};
package Message::DOM::IFLatest::Comment;
our $VERSION = 20060416.1254;
package Message::DOM::CharacterData::ManakaiDOMComment;
our $VERSION = 20060416.1254;
push our @ISA, 'Message::DOM::CharacterData::ManakaiDOMCharacterData',
'Message::DOM::IF::CharacterData',
'Message::DOM::IF::Comment',
'Message::DOM::IF::Node',
'Message::DOM::IFLatest::CharacterData',
'Message::DOM::IFLatest::Comment',
'Message::DOM::IFLatest::Node',
'Message::DOM::IFLevel1::CharacterData',
'Message::DOM::IFLevel1::Comment',
'Message::DOM::IFLevel1::Node',
'Message::DOM::IFLevel2::CharacterData',
'Message::DOM::IFLevel2::Comment',
'Message::DOM::IFLevel2::Node',
'Message::DOM::IFLevel3::CharacterData',
'Message::DOM::IFLevel3::Comment',
'Message::DOM::IFLevel3::Node';
sub node_type ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;
$r = '8';
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMComment', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'node_type';
}
}
sub node_name ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';
$r = '#comment';
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::CharacterData::ManakaiDOMComment', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'node_name';
}
}
sub get_feature ($$$) {
my ($self, $feature, $version) = @_;

{


$feature = lc $feature;


}

{


$version = '' unless defined $version;


}
my $r;

{


$feature =~ s/^\+//;


{

if 
($Message::DOM::DOMFeature::ClassInfo->{ref $self}
      ->{has_feature}->{$feature}->{$version}) {
  $r = $self;
} else {
  CLASS: for my $__class (sort {
    $Message::DOM::ClassPoint{$b} <=> $Message::DOM::ClassPoint{$a}
  } grep {
    $Message::DOM::DOMFeature::ClassInfo->{'Message::DOM::CharacterData::ManakaiDOMComment'}
        ->{compat_class}->{$_}
  } keys %{$Message::DOM::DOMFeature::ClassInfo->{'Message::DOM::CharacterData::ManakaiDOMComment'}
               ->{compat_class} or {}}) {
    if ($Message::DOM::DOMFeature::ClassInfo->{$__class}
            ->{has_feature}->{$feature}->{$version}) {
      

{


$r = ${($self->{'b'})->{${($self->{'id'})}}->{
'cls'
}}->___create_node_ref ({
  
'id'
 => ($self->{'id'}),
  
'b'
 => ($self->{'b'}),
}, {
          'nrcls' => \$__class,
        });
($self->{'b'})->{${($self->{'id'})}}->{
'rc'
}++;


}

;
      last CLASS;
    }
  } # CLASS
}


}

;
unless (defined $r) {
  

{

local $Error::Depth = $Error::Depth + 1;

{



    $r = $self->SUPER::get_feature ($feature, $version);
  


}


;}

;
}


}
$r}
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::CharacterData::ManakaiDOMComment>}->{has_feature} = {'core',
{'',
'1',
'1.0',
'1',
'2.0',
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
$Message::DOM::ClassPoint{q<Message::DOM::CharacterData::ManakaiDOMComment>} = 14.1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::TreeCore::ManakaiDOMComment>}->{compat_class}->{q<Message::DOM::CharacterData::ManakaiDOMComment>} = 1;
$Message::Util::Grove::ClassProp{q<Message::DOM::CharacterData::ManakaiDOMComment>} = {'o0',
['parent'],
'w0',
['od']};
package Message::DOM::IFLatest::StringExtended;
our $VERSION = 20060416.1254;
for ($Message::DOM::IF::CharacterData::, $Message::DOM::IF::Comment::, $Message::DOM::IF::Node::, $Message::DOM::IF::Text::, $Message::DOM::IFLatest::Node::, $Message::DOM::IFLevel1::CharacterData::, $Message::DOM::IFLevel1::Comment::, $Message::DOM::IFLevel1::Node::, $Message::DOM::IFLevel1::Text::, $Message::DOM::IFLevel2::CharacterData::, $Message::DOM::IFLevel2::Comment::, $Message::DOM::IFLevel2::Node::, $Message::DOM::IFLevel2::Text::, $Message::DOM::IFLevel3::CharacterData::, $Message::DOM::IFLevel3::Comment::, $Message::DOM::IFLevel3::Node::, $Message::DOM::IFLevel3::Text::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
