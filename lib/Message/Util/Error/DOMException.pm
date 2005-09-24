#!/usr/bin/perl 
## This file is automatically generated
## 	at 2005-09-24T13:41:27+00:00,
## 	from file "lib/Message/Util/Error/DOMException.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#Perl>.
## Don't edit by hand!
use strict;
require Message::Util::Error;
package Message::Util::Error::DOMException;
our $VERSION = 20050924.1341;
sub NO_MODIFICATION_ALLOWED_ERR ();
sub MDOM_DEBUG_BUG ();
sub NOT_SUPPORTED_ERR ();
sub AUTOLOAD {

#line 1 "lib/Message/Util/Error/DOMException.dis [u] (Chunk #1)"

        my $al = our $AUTOLOAD;
        $al =~ s/.+:://;
        if ({'NO_MODIFICATION_ALLOWED_ERR', 'Message::Util::Error::DOMException::NO_MODIFICATION_ALLOWED_ERR', 'MDOM_DEBUG_BUG', 'Message::Util::Error::DOMException::MDOM_DEBUG_BUG', 'NOT_SUPPORTED_ERR', 'Message::Util::Error::DOMException::NOT_SUPPORTED_ERR'}->{$al}) {
          no strict 'refs';
          *{$AUTOLOAD} = \&{{'NO_MODIFICATION_ALLOWED_ERR', 'Message::Util::Error::DOMException::NO_MODIFICATION_ALLOWED_ERR', 'MDOM_DEBUG_BUG', 'Message::Util::Error::DOMException::MDOM_DEBUG_BUG', 'NOT_SUPPORTED_ERR', 'Message::Util::Error::DOMException::NOT_SUPPORTED_ERR'}->{$al}};
          goto &{$AUTOLOAD};
        } else {
          require Carp;
          Carp::croak (qq<Can't locate method "$AUTOLOAD">);
        }
      
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #2)"
}
sub import {

#line 1 "lib/Message/Util/Error/DOMException.dis [u] (Chunk #3)"

        my $self = shift;
        if (@_) {
          local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
          $self->SUPER::import (@_);
          for (grep {not /\W/} @_) {
            eval qq{$_};
          }
        }
      
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #4)"
}
our %EXPORT_TAG = ('CoreExceptionCode', ['NO_MODIFICATION_ALLOWED_ERR', 'MDOM_DEBUG_BUG', 'NOT_SUPPORTED_ERR']);
our @EXPORT_OK = ('NO_MODIFICATION_ALLOWED_ERR', 'MDOM_DEBUG_BUG', 'NOT_SUPPORTED_ERR');
use Exporter; push our @ISA, 'Exporter';
package Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning;
our $VERSION = 20050924.1341;
push our @ISA, 'Message::Util::Error', 'Error', 'Message::Util::Error';
sub subtype ($;$) {
if (@_ == 1) {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #13)"
my ($self) = @_;
my $r = '';

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=subtype][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [b] (Chunk #11)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=subtype][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [bc] (Chunk #9)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=subtype][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #5)"
$r = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #6)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype'
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=subtype][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #7)"
};
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #8)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #10)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #12)"
}
$r;

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #14)"
} else {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #15)"
my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'subtype';

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #16)"
}}
sub stringify ($) {
my ($self) = @_;
my $r = '';

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [b] (Chunk #43)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [bc] (Chunk #41)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #17)"
$r = $self->SUPER::stringify;
if (defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #18)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class'
#line 2 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #19)"
}) {
  if (defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #20)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method'
#line 3 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #21)"
}) {
    $r = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #22)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class'
#line 4 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #23)"
} . '->' .
         $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #24)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method'
#line 5 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #25)"
} . ': ' . $r;
  } elsif (defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #26)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr'
#line 6 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #27)"
}) {
    $r = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #28)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class'
#line 7 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #29)"
} . '->' .
         $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #30)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr'
#line 8 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #31)"
} . ' (' .
         $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #32)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on'
#line 9 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #33)"
} . '): ' . $r;
  } else {
    $r = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #34)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class'
#line 11 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #35)"
} . ': ' . $r;
  }
}
if (defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #36)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name'
#line 14 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #37)"
}) {
  $r = 'Parameter "' . $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #38)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#param-name'
#line 15 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Method[@type=DISLang:Method]/Return[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #39)"
} . '": ' . $r;
}
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #40)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #42)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #44)"
}
$r}
sub ___error_def () {

#line 1 "lib/Message/Util/Error/DOMException.dis [u] (Chunk #45)"
{}
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #46)"
}
sub value ($;$) {
if (@_ == 1) {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #57)"
my ($self) = @_;
my $r = 0;

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=value][@Type=DOMMain|unsigned-short||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [b] (Chunk #55)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=value][@Type=DOMMain|unsigned-short||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [bc] (Chunk #53)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=value][@Type=DOMMain|unsigned-short||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #47)"
$r = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #48)"
'-def'
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=value][@Type=DOMMain|unsigned-short||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #49)"
}->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #50)"
'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code'
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=value][@Type=DOMMain|unsigned-short||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #51)"
};
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #52)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #54)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #56)"
}
$r;

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #58)"
} else {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #59)"
my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'value';

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #60)"
}}
sub text ($;$) {
if (@_ == 1) {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #95)"
my ($self) = @_;
my $r = '';

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [b] (Chunk #93)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [bc] (Chunk #91)"
my 
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #61)"
$template;
if (defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #62)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype'
#line 2 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #63)"
} and
    defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #64)"
'-def'
#line 3 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #65)"
}->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #66)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype'
#line 3 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #67)"
}
         ->{$self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #68)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype'
#line 4 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #69)"
}}
         ->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #70)"
'description'
#line 5 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #71)"
}) {
  $template = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #72)"
'-def'
#line 6 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #73)"
}
         ->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #74)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype'
#line 7 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #75)"
}
         ->{$self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #76)"
'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype'
#line 8 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #77)"
}}
         ->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #78)"
'description'
#line 9 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #79)"
};
} elsif (defined $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #80)"
'-def'
#line 10 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #81)"
}
         ->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #82)"
'description'
#line 11 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #83)"
}) {
  $template = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #84)"
'-def'
#line 12 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #85)"
}
         ->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #86)"
'description'
#line 13 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #87)"
};
} else {
  $template = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #88)"
'-type'
#line 15 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=text][@type=DISLang:Attribute]/Get[@Type=DISLang:String::ManakaiDOM:all][@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #89)"
};
}
$r = $self->_FORMATTER_PACKAGE_->new
          ->replace ($template, param => $self);
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #90)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #92)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #94)"
}
$r;

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #96)"
} else {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #97)"
my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'text';

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #98)"
}}
sub type ($;$) {
if (@_ == 1) {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #105)"
my ($self) = @_;
my $r = '';

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=type][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [b] (Chunk #103)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=type][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [bc] (Chunk #101)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=type][@Type=DISLang|String||ManakaiDOM|all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #99)"
$r = $self->{-type};
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #100)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #102)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #104)"
}
$r;

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #106)"
} else {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #107)"
my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'type';

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #108)"
}}
sub code ($;$) {
if (@_ == 1) {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #119)"
my ($self) = @_;
my $r = 0;

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=code][@Type=DOMMain:unsigned-short::ManakaiDOM:all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [b] (Chunk #117)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=code][@Type=DOMMain:unsigned-short::ManakaiDOM:all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [bc] (Chunk #115)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=code][@Type=DOMMain:unsigned-short::ManakaiDOM:all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #109)"
$r = $self->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #110)"
'-def'
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=code][@Type=DOMMain:unsigned-short::ManakaiDOM:all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #111)"
}->{
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #112)"
'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code'
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDOM:ManakaiDOMExceptionOrWarning][@type=AnyExceptionClass]/Attr[@Name=code][@Type=DOMMain:unsigned-short::ManakaiDOM:all][@type=DISLang:Attribute]/Get[@type=DISLang:AttributeGet]/PerlDef [u] (Chunk #113)"
};
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #114)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #116)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #118)"
}
$r;

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #120)"
} else {
#line 1 "lib/Message/Util/Error/DOMException.dis [bc] (Chunk #121)"
my ($self) = @_;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NO_MODIFICATION_ALLOWED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'get', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'code';

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #122)"
}}
use overload bool => sub () {1}, '0+', 'value', fallback => 1;
$Message::DOM::ClassFeature{q<Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning>} = {};
$Message::DOM::ClassPoint{q<Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning>} = 0;
package Message::Util::IF::ManakaiDOMExceptionIF;
our $VERSION = 20050924.1341;
push our @ISA, 'Message::Util::Error';
package Message::Util::Error::DOMException::ManakaiDOMException;
our $VERSION = 20050924.1341;
push our @ISA, 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning';
sub ___error_def () {

#line 1 "lib/Message/Util/Error/DOMException.dis [u] (Chunk #123)"
{}
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #124)"
}
$Message::DOM::ClassFeature{q<Message::Util::Error::DOMException::ManakaiDOMException>} = {};
$Message::DOM::ClassPoint{q<Message::Util::Error::DOMException::ManakaiDOMException>} = 0;
package Message::Util::Error::DOMException::ManakaiDOMWarning;
our $VERSION = 20050924.1341;
push our @ISA, 'Message::Util::Error::DOMException::ManakaiDOMExceptionOrWarning';
sub ___error_def () {

#line 1 "lib/Message/Util/Error/DOMException.dis [u] (Chunk #125)"
{}
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #126)"
}
$Message::DOM::ClassFeature{q<Message::Util::Error::DOMException::ManakaiDOMWarning>} = {};
$Message::DOM::ClassPoint{q<Message::Util::Error::DOMException::ManakaiDOMWarning>} = 0;
package Message::Util::Error::DOMException::CoreException;
our $VERSION = 20050924.1341;
push our @ISA, 'Message::Util::Error::DOMException::ManakaiDOMException';
sub NO_MODIFICATION_ALLOWED_ERR () {
7}
sub MDOM_DEBUG_BUG () {
3}
sub ___error_def () {

#line 1 "lib/Message/Util/Error/DOMException.dis [u] (Chunk #127)"
{'NO_MODIFICATION_ALLOWED_ERR', {'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code', '7', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype', {'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#READ_ONLY_ATTRIBUTE_ERR', {'description', 'Attribute "%p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class}, suffix => {.} );%p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr});" is read-only'}}, 'description', 'An attempt is made to modify read-only object.'}, 'MDOM_DEBUG_BUG', {'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code', '3', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype', {'http://suika.fam.cx/~wakaba/archive/2004/dom/main#ASSERTION_ERR', {'description', 'ASSERTION ERROR: got "%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/main#actualValue});" while %p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/main#expectedValue}, prefix => {"}, suffix => {"});%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/main#expectedLabel}, prefix => { (}, suffix => {)}); is expected %p ( name => {http://suika.fam.cx/~wakaba/archive/2004/dom/main#traceText});'}}, 'description', 'Unexpected case occurs. In general, this exception is not reported. If the implementation has a bug and something unexpected is occur, this exception is raised. Applications <kwd:MUST-NOT> try to catch this exception. If this exception is raised, please report to the author of that module. {NOTE:: New assertion mechanism and subtype <X::DOMMain|ASSERTION_ERR> has been introduced; it should be used instead of throwing <X::MDOMX:MDOM_DEBUG_BUG> directly. }'}, 'NOT_SUPPORTED_ERR', {'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code', '9', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype', {'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#MDOM_IMPL_METHOD_NOT_IMPLEMENTED', {'description', 'The method "%p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class}, suffix => {.} );%p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method});" has not been implemented yet'}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#MDOM_IMPL_ATTR_NOT_IMPLEMENTED', {'description', 'The attribute "%p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class}, suffix => {.} );%p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr});" %p (name => {http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on}, prefix => {(}, suffix => {)}); has not been implemented yet'}}, 'description', 'The implementation does not support the action.'}}
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #128)"
}
sub NOT_SUPPORTED_ERR () {
9}
$Message::DOM::ClassFeature{q<Message::Util::Error::DOMException::CoreException>} = {};
$Message::DOM::ClassPoint{q<Message::Util::Error::DOMException::CoreException>} = 0;
package Message::Util::Error::DOMException::ManakaiDefaultExceptionHandler;
our $VERSION = 20050924.1341;
push our @ISA, 'Message::Util::IF::MUErrorTarget';
sub ___report_error ($$) {
my ($self, $err) = @_;

{
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDefaultExceptionHandler][@type=DISLang|Class]/ResourceDef[@type=DISLang:Method]/Return[@type=DISLang:MethodReturn]/PerlDef [b] (Chunk #135)"

#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDefaultExceptionHandler][@type=DISLang|Class]/ResourceDef[@type=DISLang:Method]/Return[@type=DISLang:MethodReturn]/PerlDef [bc] (Chunk #133)"
if 
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDefaultExceptionHandler][@type=DISLang|Class]/ResourceDef[@type=DISLang:Method]/Return[@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #129)"
($err->isa (
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #130)"
'Message::Util::Error::DOMException::ManakaiDOMException'
#line 1 "/document (lib/Message/Util/Error/DOMException.dis)/ResourceDef[@QName=ManakaiDefaultExceptionHandler][@type=DISLang|Class]/ResourceDef[@type=DISLang:Method]/Return[@type=DISLang:MethodReturn]/PerlDef [u] (Chunk #131)"
)) {
  $err->throw;
} else {
## TODO: Implement warning reporting
  warn $err->stringify;
}
#line 1 "lib/Message/Util/Error/DOMException.dis [/u] (Chunk #132)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/bc] (Chunk #134)"

#line 1 "lib/Message/Util/Error/DOMException.dis [/b] (Chunk #136)"
}
}
$Message::DOM::ClassFeature{q<Message::Util::Error::DOMException::ManakaiDefaultExceptionHandler>} = {};
$Message::DOM::ClassPoint{q<Message::Util::Error::DOMException::ManakaiDefaultExceptionHandler>} = 0;
for ($Error::, $Message::Util::IF::MUErrorTarget::, $Message::Util::Error::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
