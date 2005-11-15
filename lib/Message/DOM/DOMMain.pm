#!/usr/bin/perl 
## This file is automatically generated
## 	at 2005-11-15T04:23:36+00:00,
## 	from file "lib/Message/DOM/DOMMain.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMMain>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::DOM::DOMCore;
require Message::DOM::DOMFeature;
require Message::Util::Error;
require Message::Util::Error::DOMException;
package Message::DOM::DOMMain;
our $VERSION = 20051115.0423;
sub ATTR_SET_NO_EFFECT ();
sub BAD_BASE_URI ();
sub MDOMX_EMPTY_NS_PREFIX ();
sub MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR ();
sub MDOM_NEWCHILD_IS_REFCHILD ();
sub MDOM_NS_EMPTY_URI ();
sub MDOM_REPLACE_BY_ITSELF_NO_EFFECT ();
sub RELATIVE_URI ();
sub AUTOLOAD {


        my $al = our $AUTOLOAD;
        $al =~ s/.+:://;
        if ({'ATTR_SET_NO_EFFECT', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::ATTR_SET_NO_EFFECT', 'BAD_BASE_URI', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::BAD_BASE_URI', 'MDOMX_EMPTY_NS_PREFIX', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOMX_EMPTY_NS_PREFIX', 'MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', 'Message::DOM::DOMMain::ManakaiDOMImplementationException::MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', 'MDOM_NEWCHILD_IS_REFCHILD', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOM_NEWCHILD_IS_REFCHILD', 'MDOM_NS_EMPTY_URI', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOM_NS_EMPTY_URI', 'MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'RELATIVE_URI', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::RELATIVE_URI'}->{$al}) {
          no strict 'refs';
          *{$AUTOLOAD} = \&{{'ATTR_SET_NO_EFFECT', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::ATTR_SET_NO_EFFECT', 'BAD_BASE_URI', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::BAD_BASE_URI', 'MDOMX_EMPTY_NS_PREFIX', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOMX_EMPTY_NS_PREFIX', 'MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', 'Message::DOM::DOMMain::ManakaiDOMImplementationException::MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', 'MDOM_NEWCHILD_IS_REFCHILD', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOM_NEWCHILD_IS_REFCHILD', 'MDOM_NS_EMPTY_URI', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOM_NS_EMPTY_URI', 'MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'RELATIVE_URI', 'Message::DOM::DOMMain::ManakaiDOMImplementationWarning::RELATIVE_URI'}->{$al}};
          goto &{$AUTOLOAD};
        } else {
          require Carp;
          Carp::croak (qq<Can't locate method "$AUTOLOAD">);
        }
      
}
sub import {


        my $self = shift;
        if (@_) {
          local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
          $self->SUPER::import (@_);
          for (grep {not /\W/} @_) {
            eval qq{$_};
          }
        }
      
}
our %EXPORT_TAG = ('ManakaiDOMImplementationExceptionCode', ['MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR'], 'ManakaiDOMImplementationWarningCode', ['ATTR_SET_NO_EFFECT', 'BAD_BASE_URI', 'MDOMX_EMPTY_NS_PREFIX', 'MDOM_NEWCHILD_IS_REFCHILD', 'MDOM_NS_EMPTY_URI', 'MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'RELATIVE_URI']);
our @EXPORT_OK = ('MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', 'ATTR_SET_NO_EFFECT', 'BAD_BASE_URI', 'MDOMX_EMPTY_NS_PREFIX', 'MDOM_NEWCHILD_IS_REFCHILD', 'MDOM_NS_EMPTY_URI', 'MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'RELATIVE_URI');
use Exporter; push our @ISA, 'Exporter';
package Message::DOM::DOMMain::ManakaiDOMObject;
our $VERSION = 20051115.0423;
push our @ISA, 'Message::Util::Error::MUErrorTarget';
sub ___report_error ($$) {
my ($self, $err) = @_;

{

if 
($err->isa (
'Message::Util::Error::DOMException::Exception'
)) {
  $err->throw;
} else {
## TODO: Implement warning reporting
  warn $err->stringify;
}


;}
}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMObject>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMObject>} = 0;
package Message::DOM::IFLatest::StringExtend;
our $VERSION = 20051115.0423;
package Message::DOM::DOMMain::ManakaiDOMStringExtend;
our $VERSION = 20051115.0423;
push our @ISA, 'Message::DOM::IF::StringExtend', 'Message::DOM::IFLatest::StringExtend', 'Message::DOM::IFLevel2::StringExtend', 'Message::DOM::IFLevel3::StringExtend';
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
  if ($$s =~ /[^\x{10000}-\x{10FFFF}]{1,$offset16}/gc) {
    $offset16 -= $+[0] - $-[0];
  } elsif ($$s =~ m{[\x{10000}-\x{10FFFF}]{1,$offset16/2}}gc) {
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
our $VERSION = 20051115.0423;
package Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException;
our $VERSION = 20051115.0423;
push our @ISA, 'Message::DOM::DOMMain::ManakaiDOMObject', 'Message::Util::Error', 'Message::DOM::IF::StringIndexOutOfBoundsException', 'Message::DOM::IFLatest::StringIndexOutOfBoundsException', 'Message::DOM::IFLevel2::StringIndexOutOfBoundsException', 'Message::DOM::IFLevel3::StringIndexOutOfBoundsException';
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException>} = 0;
package Message::DOM::DOMMain::ManakaiDOMImplementationException;
our $VERSION = 20051115.0423;
push our @ISA, 'Message::Util::Error::DOMException::Exception', 'Message::DOM::DOMMain::ManakaiDOMObject';
sub MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR {
2}
sub ___error_def {

{'MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', {'description', 'An attempt to break surrogate pair, i.e. the first character of the range is the low-surrogate (the second 16-bit unit of the surrogate pair) or the last character of the range is the high-surrogate (the first 16-bit unit of the surrogate pair).', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code', '2', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype', {}}}
}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMImplementationException>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMImplementationException>} = 0;
package Message::DOM::DOMMain::ManakaiDOMImplementationWarning;
our $VERSION = 20051115.0423;
push our @ISA, 'Message::Util::Error::DOMException::ManakaiDOMWarning', 'Message::DOM::DOMMain::ManakaiDOMObject';
sub ATTR_SET_NO_EFFECT {
0}
sub MDOM_NEWCHILD_IS_REFCHILD {
1}
sub MDOM_REPLACE_BY_ITSELF_NO_EFFECT {
2}
sub MDOMX_EMPTY_NS_PREFIX {
3}
sub MDOM_NS_EMPTY_URI {
4}
sub BAD_BASE_URI {
5}
sub RELATIVE_URI {
6}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMImplementationWarning>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMImplementationWarning>} = 0;
$Message::DOM::DOMImplementationRegistry = 'Message::DOM::DOMMain::DOMImplementationRegistry';
package Message::DOM::DOMMain::DOMImplementationRegistry;
our $VERSION = 20051115.0423;
push our @ISA, 'Message::DOM::DOMFeature::ImplementationRegistry', 'Message::DOM::IFLatest::DOMImplementationSource', 'Message::DOM::IFLevel3::DOMImplementationSource';
sub get_dom_implementation ($$) {
my ($self, $features) = @_;

{

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}


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

if 
(CORE::defined $features) {
  if (CORE::ref ($features) eq 'HASH') {
    my $new = {};
    for my $fname (keys %{$features}) {
      if (CORE::ref ($features->{$fname}) eq 'HASH') {
        my $lfname = lc $fname;
        for my $fver (keys %{$features->{$fname}}) {
          $new->{$lfname}->{$fver} = $features->{$fname}->{$fver};
        }
      } else {
        $new->{lc $fname} = {(CORE::defined $features->{$fname}
                                ? $features->{$fname} : '') => 1};
      }
    }
    $features = $new;
  } else {
    my @f = split /\s+/, $features;
    $features = {};
    while (@f) {
      my $name = lc shift @f;
      if (@f and $f[0] =~ /^[\d\.]+$/) {
        $features->{$name}->{shift @f} = 1;
      } else {
        $features->{$name}->{''} = 1;
      }
    }
  }
} else {
  $features = {};
}


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
