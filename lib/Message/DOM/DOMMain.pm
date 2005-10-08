#!/usr/bin/perl 
## This file is automatically generated
## 	at 2005-10-08T14:13:32+00:00,
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
our $VERSION = 20051008.1413;
sub ATTR_SET_NO_EFFECT ();
sub BAD_BASE_URI ();
sub MDOMX_EMPTY_NS_PREFIX ();
sub MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR ();
sub MDOM_NEWCHILD_IS_REFCHILD ();
sub MDOM_NS_EMPTY_URI ();
sub MDOM_REPLACE_BY_ITSELF_NO_EFFECT ();
sub RELATIVE_URI ();
sub AUTOLOAD {

#line 1 "lib/Message/DOM/DOMMain.dis [u] (Chunk #1)"

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
      
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #2)"
}
sub import {

#line 1 "lib/Message/DOM/DOMMain.dis [u] (Chunk #3)"

        my $self = shift;
        if (@_) {
          local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
          $self->SUPER::import (@_);
          for (grep {not /\W/} @_) {
            eval qq{$_};
          }
        }
      
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #4)"
}
our %EXPORT_TAG = ('ManakaiDOMImplementationExceptionCode', ['MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR'], 'ManakaiDOMImplementationWarningCode', ['ATTR_SET_NO_EFFECT', 'BAD_BASE_URI', 'MDOMX_EMPTY_NS_PREFIX', 'MDOM_NEWCHILD_IS_REFCHILD', 'MDOM_NS_EMPTY_URI', 'MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'RELATIVE_URI']);
our @EXPORT_OK = ('MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR', 'ATTR_SET_NO_EFFECT', 'BAD_BASE_URI', 'MDOMX_EMPTY_NS_PREFIX', 'MDOM_NEWCHILD_IS_REFCHILD', 'MDOM_NS_EMPTY_URI', 'MDOM_REPLACE_BY_ITSELF_NO_EFFECT', 'RELATIVE_URI');
use Exporter; push our @ISA, 'Exporter';
package Message::DOM::DOMMain::ManakaiDOMObject;
our $VERSION = 20051008.1413;
push our @ISA, 'Message::Util::Error::MUErrorTarget';
sub ___report_error ($$) {
my ($self, $err) = @_;

{
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMObject][@type=ManakaiDOM:Class]/ResourceDef[@type=DISLang|Method]/Return[@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #11)"

#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMObject][@type=ManakaiDOM:Class]/ResourceDef[@type=DISLang|Method]/Return[@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #9)"
if 
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMObject][@type=ManakaiDOM:Class]/ResourceDef[@type=DISLang|Method]/Return[@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #5)"
($err->isa (
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #6)"
'Message::Util::Error::DOMException::Exception'
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMObject][@type=ManakaiDOM:Class]/ResourceDef[@type=DISLang|Method]/Return[@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #7)"
)) {
  $err->throw;
} else {
## TODO: Implement warning reporting
  warn $err->stringify;
}
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #8)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #10)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #12)"
}
}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMObject>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMObject>} = 0;
package Message::DOM::IFLatest::StringExtend;
our $VERSION = 20051008.1413;
package Message::DOM::DOMMain::ManakaiDOMStringExtend;
our $VERSION = 20051008.1413;
push our @ISA, 'Message::DOM::IF::StringExtend', 'Message::DOM::IFLatest::StringExtend', 'Message::DOM::IFLevel2::StringExtend', 'Message::DOM::IFLevel3::StringExtend';
sub find_offset_16 ($$) {
my ($self, $offset32) = @_;
my $r = 0;

{
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset16][@type=DISLang|Method]/Return[@Type=DOMMain|unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #17)"

#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset16][@type=DISLang|Method]/Return[@Type=DOMMain|unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #15)"
my 
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset16][@type=DISLang|Method]/Return[@Type=DOMMain|unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #13)"
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
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #14)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #16)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #18)"
}
$r}
sub find_offset_32 ($$) {
my ($self, $offset16) = @_;
my $r = 0;

{
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset32][@type=DISLang|Method]/Return[@Type=unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #27)"

#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset32][@type=DISLang|Method]/Return[@Type=unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #21)"
my 
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset32][@type=DISLang|Method]/Return[@Type=unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #19)"
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
    
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #20)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #22)"
report Message::Util::Error::DOMException::CoreException -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#values' => {
        count => $offset16,
        position => 1,
      }, '-type' => 'MDOM_DEBUG_BUG', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'find_offset_32', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMMain::ManakaiDOMStringExtend';

#line 20 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset32][@type=DISLang|Method]/Return[@Type=unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #25)"

#line 20 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@type=dis:MultipleResource][@Name=StringExtend][@Name=ManakaiDOMStringExtend][@type=ManakaiDOM:IF][@type=ManakaiDOM:PrimitiveTypeClass]/Method[@Name=findOffset32][@type=DISLang|Method]/Return[@Type=unsigned-long||ManakaiDOM|all][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #23)"
;
  }
}
if ($offset16 > 0) {
}
$r = pos ($$s);
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #24)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #26)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #28)"
}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMStringExtend>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMStringExtend>} = 0;
package Message::DOM::IFLatest::StringIndexOutOfBoundsException;
our $VERSION = 20051008.1413;
package Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException;
our $VERSION = 20051008.1413;
push our @ISA, 'Message::DOM::DOMMain::ManakaiDOMObject', 'Message::Util::Error', 'Message::DOM::IF::StringIndexOutOfBoundsException', 'Message::DOM::IFLatest::StringIndexOutOfBoundsException', 'Message::DOM::IFLevel2::StringIndexOutOfBoundsException', 'Message::DOM::IFLevel3::StringIndexOutOfBoundsException';
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMStringIndexOutOfBoundsException>} = 0;
package Message::DOM::DOMMain::ManakaiDOMImplementationException;
our $VERSION = 20051008.1413;
push our @ISA, 'Message::DOM::DOMMain::ManakaiDOMObject';
sub MDOM_DOMSTRING_INDEX_IN_SURROGATE_PAIR () {
2}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMImplementationException>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMImplementationException>} = 0;
package Message::DOM::DOMMain::ManakaiDOMImplementationWarning;
our $VERSION = 20051008.1413;
push our @ISA, 'Message::Util::Error::DOMException::ManakaiDOMWarning', 'Message::DOM::DOMMain::ManakaiDOMObject';
sub ATTR_SET_NO_EFFECT () {
0}
sub BAD_BASE_URI () {
5}
sub MDOMX_EMPTY_NS_PREFIX () {
3}
sub MDOM_NEWCHILD_IS_REFCHILD () {
1}
sub MDOM_NS_EMPTY_URI () {
4}
sub MDOM_REPLACE_BY_ITSELF_NO_EFFECT () {
2}
sub RELATIVE_URI () {
6}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::ManakaiDOMImplementationWarning>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::ManakaiDOMImplementationWarning>} = 0;
$Message::DOM::DOMImplementationRegistry = 'Message::DOM::DOMMain::DOMImplementationRegistry';
package Message::DOM::DOMMain::DOMImplementationRegistry;
our $VERSION = 20051008.1413;
push our @ISA, 'Message::DOM::DOMFeature::ImplementationRegistry', 'Message::DOM::IFLatest::DOMImplementationSource', 'Message::DOM::IFLevel3::DOMImplementationSource';
sub get_dom_implementation ($$) {
my ($self, $features) = @_;

{
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/InputProcessor[@type=DISLang:InputProcessor]/PerlDef [b] (Chunk #33)"

#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/InputProcessor[@type=DISLang:InputProcessor]/PerlDef [bc] (Chunk #31)"
if 
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/InputProcessor[@type=DISLang:InputProcessor]/PerlDef [u] (Chunk #29)"
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
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #30)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #32)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #34)"
}
my $r;

{
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #65)"

#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #39)"

#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #35)"
$features->{core}->{'3.0'} = 
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #36)"
1
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #37)"
;

#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #38)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #40)"

{
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/ResourceDef[@QName=DOMMain:stringifyFeatures][@type=dis2pm:BlockCode]/PerlDef [b] (Chunk #45)"

#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/ResourceDef[@QName=DOMMain:stringifyFeatures][@type=dis2pm:BlockCode]/PerlDef [bc] (Chunk #43)"
my 
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/ResourceDef[@QName=DOMMain:stringifyFeatures][@type=dis2pm:BlockCode]/PerlDef [u] (Chunk #41)"
@out;
for my $fname (keys %{$features}) {
  for my $fver (keys %{$features->{$fname}}) {
    push @out, $fname . ' ' . $fver . ' ' if $features->{$fname}->{$fver};
  }
}
$features = join ' ', @out;
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #42)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #44)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #46)"
}

#line 3 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #49)"

#line 3 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #47)"
;

#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #48)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #50)"

{
#line 1 "lib/Message/DOM/DOMMain.dis [b] (Chunk #59)"
local $Error::Depth = $Error::Depth + 1;

{
#line 4 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #57)"

#line 4 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #55)"

  C: 
#line 4 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #51)"
for my $class (
    keys %Message::DOM::ManakaiDOMImplementationRegistry::SourceClass
  ) {
    $r = $class->
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #52)"
get_dom_implementation
#line 7 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #53)"
 ($features);
    last C if defined $r;
  }

#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #54)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #56)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #58)"
}

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #60)"
}

#line 12 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #63)"

#line 12 "/document (lib/Message/DOM/DOMFeature.dis)/ResourceDef[@QName=ImplementationRegistry][@QName=def|ImplRegDescription][@QName=def|ImplRegJava][@QName=def|ImplRegECMAScript][@QName=def|ImplRegPerl][@type=DISLang|Class][@type=dis|MultipleResource][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation][@type=doc|Documentation]/Method[@Name=getDOMImplementation][@type=DISLang|Method]/Return[@Type=MinimumImplementation][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #61)"
;
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #62)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #64)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #66)"
}
$r}
sub get_dom_implementation_list ($$) {
my ($self, $features) = @_;

{
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/InputProcessor[@type=DISLang:InputProcessor]/PerlDef [b] (Chunk #71)"

#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/InputProcessor[@type=DISLang:InputProcessor]/PerlDef [bc] (Chunk #69)"
if 
#line 1 "/document (lib/Message/DOM/DOMFeature.dis)/StringDataTypeDef[@QName=FeaturesString][@type=DISLang|DataType]/InputProcessor[@type=DISLang:InputProcessor]/PerlDef [u] (Chunk #67)"
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
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #68)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #70)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #72)"
}
my $r;

{
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #89)"

#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #73)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #74)"

{
#line 1 "lib/Message/DOM/DOMMain.dis [b] (Chunk #83)"
local $Error::Depth = $Error::Depth + 1;

{
#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [b] (Chunk #81)"

#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #79)"

#line 1 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #75)"
       ## NOTE: Method name directly written
  $r = bless $self->SUPER::get_dom_implementation_list ($features),
             
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #76)"
'Message::DOM::DOMCore::ManakaiDOMImplementationList'
#line 3 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #77)"
;

#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #78)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #80)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #82)"
}

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #84)"
}

#line 4 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [bc] (Chunk #87)"

#line 4 "/document (lib/Message/DOM/DOMMain.dis)/ResourceDef[@QName=DOMImplementationRegistry][@type=ManakaiDOM|Class]/Method[@Name=getDOMImplementationList][@type=DISLang|Method]/Return[@Type=DOMCore|DOMImplementationList][@type=DISLang|MethodReturn]/PerlDef [u] (Chunk #85)"
;
#line 1 "lib/Message/DOM/DOMMain.dis [/u] (Chunk #86)"

#line 1 "lib/Message/DOM/DOMMain.dis [/bc] (Chunk #88)"

#line 1 "lib/Message/DOM/DOMMain.dis [/b] (Chunk #90)"
}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMMain::DOMImplementationRegistry>} = {};
$Message::DOM::ClassPoint{q<Message::DOM::DOMMain::DOMImplementationRegistry>} = 0;
push @Message::DOM::IF::StringIndexOutOfBoundsException::ISA, 'Message::Util::Error' unless @Message::DOM::IF::StringIndexOutOfBoundsException::ISA;
push @Message::DOM::IFLevel2::StringIndexOutOfBoundsException::ISA, 'Message::Util::Error' unless @Message::DOM::IFLevel2::StringIndexOutOfBoundsException::ISA;
push @Message::DOM::IFLevel3::StringIndexOutOfBoundsException::ISA, 'Message::Util::Error' unless @Message::DOM::IFLevel3::StringIndexOutOfBoundsException::ISA;
for ($Message::DOM::IF::StringExtend::, $Message::DOM::IFLatest::DOMImplementationSource::, $Message::DOM::IFLevel2::StringExtend::, $Message::DOM::IFLevel3::DOMImplementationSource::, $Message::DOM::IFLevel3::StringExtend::, $Message::Util::Error::MUErrorTarget::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
