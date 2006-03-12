#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-03-12T12:07:02+00:00,
## 	from file "../DOM/DOMMain.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMMain>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::DOM::DOMCore;
require Message::DOM::DOMFeature;
require Message::Util::Error;
require Message::Util::Error::DOMException;
package Message::DOM::DOMMain;
our $VERSION = 20060312.1207;
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/main#empty-namespace-uri'} = {'description',
'An empty string is used as a namespace URI.',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::Util::Error::formatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/main#empty-namespace-uri'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/main#empty-namespace-prefix'} = {'description',
'An empty string is used as a namespace prefix.',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::Util::Error::formatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/main#empty-namespace-prefix'};
$Message::DOM::DOMImplementationRegistry = 'Message::DOM::DOMMain::DOMImplementationRegistry';
package Message::DOM::DOMMain::ManakaiDOMObject;
our $VERSION = 20060312.1207;
push our @ISA, 'Message::Util::Error::MUErrorTarget';
sub ___report_error ($$) {
my ($self, $err) = @_;

{

if 
($err->isa (
'Message::DOM::IF::DOMError'
)) {
  CORE::warn $err;
} else {
  $err->
throw
;
}


;}
}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMObject>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMObject>} = 0;
package Message::DOM::IFLatest::StringExtend;
our $VERSION = 20060312.1207;
package Message::DOM::DOMMain::ManakaiDOMStringExtend;
our $VERSION = 20060312.1207;
push our @ISA, 'Message::DOM::IF::StringExtend',
'Message::DOM::IFLatest::StringExtend',
'Message::DOM::IFLevel2::StringExtend',
'Message::DOM::IFLevel3::StringExtend';
sub find_offset_16 ($$) {
my ($self, $offset32) = @_;
my $r = 0;

{

my 
$s = ref $self eq 'SCALAR' ? $self : \$self;
if (not defined $offset32 or $offset32 < 0 or
    CORE::length ($$s) < $offset32) {
}
my $ss = substr $$s, 0, $offset32;
if ($ss =~ /[\x{10000}-\x{10FFFF}]/) {
  while ($ss =~ /[\x{10000}-\x{10FFFF}]+/g) {
    $r += $+[0] - $-[0];
  }
}


;}
$r}
sub find_offset_32 ($$) {
my ($self, $offset16) = @_;
my $r = 0;

{

my 
$s = ref $self eq 'SCALAR' ? $self : \$self;
if (not defined $offset16 or $offset16 < 0 or
    CORE::length ($$s) * 2 < $offset16) {
}
pos ($$s) = 0;
use integer;
while ($offset16 and pos $$s <= CORE::length $$s) {
  if ($$s =~ /\G[^\x{10000}-\x{10FFFF}]{1,$offset16}/gc) {
    $offset16 -= $+[0] - $-[0];
  } elsif ($$s =~ m{\G[\x{10000}-\x{10FFFF}]{1,$offset16/2}}gc) {
    $offset16 -= 2 * ($+[0] - $-[0]);
    last if $offset16 < 0;
  } else {
    
report Message::Util::Error::DOMException::CoreException -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#values' => {
        count => $offset16,
        position => 1,
      }, '-type' => 'MDOM_DEBUG_BUG', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'find_offset_32', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMMain::ManakaiDOMStringExtend';

;
  }
}
if ($offset16 > 0) {
}
$r = pos ($$s);


;}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMStringExtend>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMStringExtend>} = 0;
package Message::DOM::IFLatest::StringIndexOutOfBoundsException;
our $VERSION = 20060312.1207;
package Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException;
our $VERSION = 20060312.1207;
push our @ISA, 'Message::DOM::DOMMain::ManakaiDOMObject',
'Message::Util::Error',
'Message::DOM::IF::StringIndexOutOfBoundsException',
'Message::DOM::IFLatest::StringIndexOutOfBoundsException',
'Message::DOM::IFLevel2::StringIndexOutOfBoundsException',
'Message::DOM::IFLevel3::StringIndexOutOfBoundsException';
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException>} = 0;
package Message::DOM::DOMMain::DOMImplementationRegistry;
our $VERSION = 20060312.1207;
push our @ISA, 'Message::DOM::DOMFeature::ImplementationRegistry',
'Message::DOM::IFLatest::DOMImplementationSource',
'Message::DOM::IFLevel3::DOMImplementationSource';
sub get_dom_implementation ($$) {
my ($self, $features) = @_;

{


{

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $__new = {};
    for my $__fname (keys %{$features}) {
      if (CORE::ref ($features->{$__fname}) eq 'HASH') {
        my $__lfname = lc $__fname;
        for my $__fver (keys %{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = $features->{$__fname}->{$__fver};
        }
      } elsif (CORE::ref ($features->{$__fname}) eq 'ARRAY') {
        my $__lfname = lc $__fname;
        for my $__fver (@{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = 
1
;
        }
      } else {
        $__new->{lc $__fname} = {(CORE::defined $features->{$__fname}
                                ? $features->{$__fname} : '') => 
1
};
      }
    }
    $features = $__new;
  } else {
    my @__f = split /\s+/, $features;
    my $__new = {};
    while (@__f) {
      my $__name = lc shift @__f;
      if (@__f and $__f[0] =~ /^[\d\.]+$/) {
        $__new->{$__name}->{shift @__f} = 1;
      } else {
        $__new->{$__name}->{''} = 1;
      }
    }
    $features = $__new;
  }
} else {
  $features = {};
}


;}

;


;}
my $r;

{


$features->{core}->{'3.0'} = 
1
;


{

my 
@out;
for my $fname (sort {$a cmp $b} keys %{$features}) {
  for my $fver (sort {$a cmp $b} keys %{$features->{$fname}}) {
    push @out, $fname;
    push @out, $fver if length $fver;
  }
}
$features = join ' ', @out;


;}

;


{

local $Error::Depth = $Error::Depth + 1;

{


  C: 
for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    $r = $class->
get_dom_implementation
 ($features);
    last C if defined $r;
  }



;}


;}

;


;}
$r}
sub get_dom_implementation_list ($$) {
my ($self, $features) = @_;

{


{

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $__new = {};
    for my $__fname (keys %{$features}) {
      if (CORE::ref ($features->{$__fname}) eq 'HASH') {
        my $__lfname = lc $__fname;
        for my $__fver (keys %{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = $features->{$__fname}->{$__fver};
        }
      } elsif (CORE::ref ($features->{$__fname}) eq 'ARRAY') {
        my $__lfname = lc $__fname;
        for my $__fver (@{$features->{$__fname}}) {
          $__new->{$__lfname}->{$__fver} = 
1
;
        }
      } else {
        $__new->{lc $__fname} = {(CORE::defined $features->{$__fname}
                                ? $features->{$__fname} : '') => 
1
};
      }
    }
    $features = $__new;
  } else {
    my @__f = split /\s+/, $features;
    my $__new = {};
    while (@__f) {
      my $__name = lc shift @__f;
      if (@__f and $__f[0] =~ /^[\d\.]+$/) {
        $__new->{$__name}->{shift @__f} = 1;
      } else {
        $__new->{$__name}->{''} = 1;
      }
    }
    $features = $__new;
  }
} else {
  $features = {};
}


;}

;


;}
my $r;

{


{

local $Error::Depth = $Error::Depth + 1;

{


       ## NOTE: Method name directly written
  $r = bless $self->SUPER::get_dom_implementation_list ($features),
             
'Message::DOM::DOMCore::ManakaiDOMImplementationList'
;



;}


;}

;


;}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::DOMImplementationRegistry>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::DOMImplementationRegistry>} = 0;
push @Message::DOM::IF::StringIndexOutOfBoundsException::ISA, 'Message::Util::Error' unless @Message::DOM::IF::StringIndexOutOfBoundsException::ISA;
push @Message::DOM::IFLevel2::StringIndexOutOfBoundsException::ISA, 'Message::Util::Error' unless @Message::DOM::IFLevel2::StringIndexOutOfBoundsException::ISA;
push @Message::DOM::IFLevel3::StringIndexOutOfBoundsException::ISA, 'Message::Util::Error' unless @Message::DOM::IFLevel3::StringIndexOutOfBoundsException::ISA;
for ($Message::DOM::IF::StringExtend::, $Message::DOM::IFLatest::DOMImplementationSource::, $Message::DOM::IFLevel2::StringExtend::, $Message::DOM::IFLevel3::DOMImplementationSource::, $Message::DOM::IFLevel3::StringExtend::, $Message::Util::Error::MUErrorTarget::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
