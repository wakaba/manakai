#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-12-29T06:31:45+00:00,
## 	from file "DOMString.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMString>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::Util::Error::DOMException;
require Tie::Array;
package Message::DOM::DOMString;
our $VERSION = 20061229.0631;
package Message::DOM::IFLatest::DOMString;
our $VERSION = 20061229.0631;
package Message::DOM::IFLatest::DOMStringList;
our $VERSION = 20061229.0631;
package Message::DOM::DOMString::ManakaiDOMStringList;
our $VERSION = 20061229.0631;
push our @ISA, 'Tie::Array',
'Message::DOM::IF::DOMStringList',
'Message::DOM::IFLatest::DOMStringList';
sub FETCH ($$) {
my ($self, $index) = @_;
my $r = '';

{

my 
$v = ${$$self->[0]}->{$$self->[1]};
if (not defined $index or
    $index < 0 or
    $index > $#$v) {
  $r = 
undef
;
} else {
  $r = $v->[$index];
}


}
$r}
*item = \&FETCH;
sub STORE ($$$) {
my ($self, $index, $value) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{


  ## NOTE: Bare method name
  $$self->[0]->_check_read_only;



}


;}

;
my $v = ${$$self->[0]}->{$$self->[1]};
$r = $v->[$index] if defined wantarray;
$v->[$index] = $value;


}
$r}
sub DELETE ($$) {
my ($self, $index) = @_;
my $r = '';

{


{

local $Error::Depth = $Error::Depth + 1;

{


  ## NOTE: Bare method name
  $$self->[0]->_check_read_only;



}


;}

;
my $v = ${$$self->[0]}->{$$self->[1]};
$r = $v->[$index] if defined wantarray;
CORE::delete $v->[$index];


}
$r}
sub EXISTS ($$) {
my ($self, $index) = @_;
my $r = 0;

{

my 
$v = ${$$self->[0]}->{$$self->[1]};
$r = CORE::exists $v->[$index];


}
$r}
sub FETCHSIZE ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = 0;

{

my 
$v = ${$$self->[0]}->{$$self->[1]};
$r = @$v;


}
$r;
} else {my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMString::ManakaiDOMStringList', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'length';
}
}
*length = \&FETCHSIZE;
sub contains ($$) {
my ($self, $str) = @_;
my $r = 0;

{

my 
$v = ${$$self->[0]}->{$$self->[1]};
CHK: {
  

{

local $Error::Depth = $Error::Depth + 1;

{


    for 
(@$v) {
      if ($str eq $_) {
        $r = 
1
;
        last CHK;
      }
    }
  


}


;}

;
} # CHK


}
$r}
sub TIEARRAY ($$) {
my ($self, $list) = @_;
my $r;

{


$r = $list


}
$r}
use overload 
bool => sub () {1}, 
'@{}' => sub ($) {
my ($self) = @_;
my $r = [];

{

tie 
my @list, ref $self, $self;
$r = \@list;


}
$r}
, 
'==' => sub ($$) {
my ($self, $arg) = @_;
my $r = 0;

{

EQ: 
{
  last EQ
      unless UNIVERSAL::isa
                 ($arg, 
'Message::DOM::IF::DOMStringList'
);
  my @v1 = @$self;
  my @v2 = @$arg;
  last EQ unless @v1 == @v2;
  no warnings 'uninitialized';
  (@v1) = sort {$a cmp $b} @v1;
  (@v2) = sort {$a cmp $b} @v2;
  for my $i (0..$#v1) {
    if (defined $v1[$i] and defined $v2[$i]) {
      last EQ unless $v1[$i] eq $v2[$i];
    } elsif (defined $v1[$i] or defined $v2[$i]) {
      last EQ;
    }
  }
  $r = 
1
;
} # EQ


}
$r}
, 
fallback => 1;
$Message::DOM::DOMFeature::ClassInfo->{q<Message::DOM::DOMString::ManakaiDOMStringList>}->{has_feature} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMString::ManakaiDOMStringList>} = 0;
for ($Message::DOM::IF::DOMStringList::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
