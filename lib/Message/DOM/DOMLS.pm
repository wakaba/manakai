#!/usr/bin/perl 
## This file is automatically generated
## 	at 2006-01-29T09:00:00+00:00,
## 	from file "lib/Message/DOM/DOMLS.dis",
## 	module <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOM.DOMLS>,
## 	for <http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#ManakaiDOMLatest>.
## Don't edit by hand!
use strict;
require Message::DOM::DOMCore;
require Message::DOM::DOMMain;
require Message::Util::Error;
require Message::Util::Error::DOMException;
package Message::DOM::DOMLS;
our $VERSION = 20060129.0900;
sub ACTION_APPEND_AS_CHILDREN ();
sub ACTION_INSERT_AFTER ();
sub ACTION_INSERT_BEFORE ();
sub ACTION_REPLACE ();
sub ACTION_REPLACE_CHILDREN ();
sub FILTER_ACCEPT ();
sub FILTER_INTERRUPT ();
sub FILTER_REJECT ();
sub FILTER_SKIP ();
sub MODE_ASYNCHRONOUS ();
sub MODE_SYNCHRONOUS ();
sub PARSE_ERR ();
sub SERIALIZE_ERR ();
sub AUTOLOAD {


        my $al = our $AUTOLOAD;
        $al =~ s/.+:://;
        if ({'ACTION_APPEND_AS_CHILDREN', 'Message::DOM::IFLatest::LSParser::ACTION_APPEND_AS_CHILDREN', 'ACTION_INSERT_AFTER', 'Message::DOM::IFLatest::LSParser::ACTION_INSERT_AFTER', 'ACTION_INSERT_BEFORE', 'Message::DOM::IFLatest::LSParser::ACTION_INSERT_BEFORE', 'ACTION_REPLACE', 'Message::DOM::IFLatest::LSParser::ACTION_REPLACE', 'ACTION_REPLACE_CHILDREN', 'Message::DOM::IFLatest::LSParser::ACTION_REPLACE_CHILDREN', 'FILTER_ACCEPT', 'Message::DOM::IFLatest::LSParserFilter::FILTER_ACCEPT', 'FILTER_INTERRUPT', 'Message::DOM::IFLatest::LSParserFilter::FILTER_INTERRUPT', 'FILTER_REJECT', 'Message::DOM::IFLatest::LSParserFilter::FILTER_REJECT', 'FILTER_SKIP', 'Message::DOM::IFLatest::LSParserFilter::FILTER_SKIP', 'MODE_ASYNCHRONOUS', 'Message::DOM::IFLatest::DOMImplementationLS::MODE_ASYNCHRONOUS', 'MODE_SYNCHRONOUS', 'Message::DOM::IFLatest::DOMImplementationLS::MODE_SYNCHRONOUS', 'PARSE_ERR', 'Message::DOM::IFLatest::LSException::PARSE_ERR', 'SERIALIZE_ERR', 'Message::DOM::IFLatest::LSException::SERIALIZE_ERR'}->{$al}) {
          no strict 'refs';
          *{$AUTOLOAD} = \&{{'ACTION_APPEND_AS_CHILDREN', 'Message::DOM::IFLatest::LSParser::ACTION_APPEND_AS_CHILDREN', 'ACTION_INSERT_AFTER', 'Message::DOM::IFLatest::LSParser::ACTION_INSERT_AFTER', 'ACTION_INSERT_BEFORE', 'Message::DOM::IFLatest::LSParser::ACTION_INSERT_BEFORE', 'ACTION_REPLACE', 'Message::DOM::IFLatest::LSParser::ACTION_REPLACE', 'ACTION_REPLACE_CHILDREN', 'Message::DOM::IFLatest::LSParser::ACTION_REPLACE_CHILDREN', 'FILTER_ACCEPT', 'Message::DOM::IFLatest::LSParserFilter::FILTER_ACCEPT', 'FILTER_INTERRUPT', 'Message::DOM::IFLatest::LSParserFilter::FILTER_INTERRUPT', 'FILTER_REJECT', 'Message::DOM::IFLatest::LSParserFilter::FILTER_REJECT', 'FILTER_SKIP', 'Message::DOM::IFLatest::LSParserFilter::FILTER_SKIP', 'MODE_ASYNCHRONOUS', 'Message::DOM::IFLatest::DOMImplementationLS::MODE_ASYNCHRONOUS', 'MODE_SYNCHRONOUS', 'Message::DOM::IFLatest::DOMImplementationLS::MODE_SYNCHRONOUS', 'PARSE_ERR', 'Message::DOM::IFLatest::LSException::PARSE_ERR', 'SERIALIZE_ERR', 'Message::DOM::IFLatest::LSException::SERIALIZE_ERR'}->{$al}};
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
our %EXPORT_TAG = ('ACTION_TYPES', ['ACTION_APPEND_AS_CHILDREN', 'ACTION_INSERT_AFTER', 'ACTION_INSERT_BEFORE', 'ACTION_REPLACE', 'ACTION_REPLACE_CHILDREN'], 'DOMImplementationLSMode', ['MODE_ASYNCHRONOUS', 'MODE_SYNCHRONOUS'], 'FilterReturnValue', ['FILTER_ACCEPT', 'FILTER_INTERRUPT', 'FILTER_REJECT', 'FILTER_SKIP'], 'LSExceptionCode', ['PARSE_ERR', 'SERIALIZE_ERR']);
our @EXPORT_OK = ('ACTION_APPEND_AS_CHILDREN', 'ACTION_INSERT_AFTER', 'ACTION_INSERT_BEFORE', 'ACTION_REPLACE', 'ACTION_REPLACE_CHILDREN', 'MODE_ASYNCHRONOUS', 'MODE_SYNCHRONOUS', 'FILTER_ACCEPT', 'FILTER_INTERRUPT', 'FILTER_REJECT', 'FILTER_SKIP', 'PARSE_ERR', 'SERIALIZE_ERR');
use Exporter; push our @ISA, 'Exporter';
package Message::DOM::IFLatest::LSException;
our $VERSION = 20060129.0900;
push our @ISA, 'Message::Util::Error';
sub PARSE_ERR () {
81}
sub SERIALIZE_ERR () {
82}
sub ___error_def () {

{'PARSE_ERR', {'description', 'An attempt was made to load a document or an XML fragment using <IF::LSParser> and the processing has been stopped.', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code', '81', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype', {}}, 'SERIALIZE_ERR', {'description', 'An attempt was made to serialize a <IF::DOMCore:Node> using <IF::LSSerializer> and the processing has been stop.', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#code', '82', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype', {}}}
}
package Message::DOM::DOMLS::ManakaiDOMLSException;
our $VERSION = 20060129.0900;
push our @ISA, 'Message::Util::Error::DOMException::Exception', 'Message::DOM::DOMMain::ManakaiDOMObject', 'Message::DOM::IF::LSException', 'Message::DOM::IFLatest::LSException', 'Message::DOM::IFLevel3::LSException';
$Message::DOM::ClassFeature{q<Message::DOM::DOMLS::ManakaiDOMLSException>} = {'ls', {'', '1', '3.0', '1'}, 'ls-async', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMLS::ManakaiDOMLSException>} = 6;
package Message::DOM::IFLatest::DOMImplementationLS;
our $VERSION = 20060129.0900;
sub MODE_SYNCHRONOUS () {
1}
sub MODE_ASYNCHRONOUS () {
2}
package Message::DOM::DOMLS::ManakaiDOMImplementationLS;
our $VERSION = 20060129.0900;
push our @ISA, 'Message::DOM::DOMCore::ManakaiDOMImplementation', 'Message::DOM::IF::DOMImplementationLS', 'Message::DOM::IFLatest::DOMImplementationLS', 'Message::DOM::IFLevel3::DOMImplementationLS';
sub create_ls_parser ($$;$) {
my ($self, $mode, $schemaType) = @_;
my $r;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NOT_SUPPORTED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'create_ls_parser', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#MDOM_IMPL_METHOD_NOT_IMPLEMENTED', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMLS::ManakaiDOMImplementationLS';
$r}
sub create_ls_serializer ($) {
my ($self) = @_;
my $r;
report Message::Util::Error::DOMException::CoreException -object => $self, '-type' => 'NOT_SUPPORTED_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => 'create_ls_serializer', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#subtype' => 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#MDOM_IMPL_METHOD_NOT_IMPLEMENTED', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMLS::ManakaiDOMImplementationLS';
$r}
sub create_ls_input ($) {
my ($self) = @_;
my $r;

{


$r = 
Message::DOM::DOMLS::ManakaiDOMLSInput->_new
;


;}

{

if 
(ref $r eq 'HASH') {
  $r = bless $r, 
'Message::DOM::DOMLS::ManakaiDOMLSInput'
;
}


;}
$r}
sub create_ls_output ($) {
my ($self) = @_;
my $r;

{


$r = 
Message::DOM::DOMLS::ManakaiDOMLSOutput->_new
;


;}
$r}
$Message::DOM::ImplFeature{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>}->{q<ls>}->{q<3.0>} ||= 1;
$Message::DOM::ImplFeature{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>}->{q<ls>}->{q<>} = 1;
$Message::DOM::ClassFeature{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = {'', {'', '1'}, 'http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#minimum', {'', '1', '3.0', '1'}, 'ls', {'', '1', '3.0', '1'}, 'ls-async', {'', '1', '3.0', '1'}, 'xml', {'', '1', '1.0', '1', '2.0', '1', '3.0', '1'}, 'xmlversion', {'', '1', '1.0', '1', '1.1', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = 17.1;
$Message::DOM::ManakaiDOMImplementationSource::SourceClass{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = 1;
$Message::DOM::ManakaiDOMImplementation::CompatClass{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = 1;
$Message::DOM::ManakaiDOMImplementationSource::SourceClass{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = 1;
$Message::DOM::ManakaiDOMImplementation::CompatClass{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = 1;
$Message::Util::ManakaiNode::ManakaiNodeRef::Prop{q<Message::DOM::DOMLS::ManakaiDOMImplementationLS>} = {};
package Message::DOM::IFLatest::LSParser;
our $VERSION = 20060129.0900;
sub ACTION_APPEND_AS_CHILDREN () {
1}
sub ACTION_REPLACE_CHILDREN () {
2}
sub ACTION_INSERT_BEFORE () {
3}
sub ACTION_INSERT_AFTER () {
4}
sub ACTION_REPLACE () {
5}
package Message::DOM::IFLatest::LSInput;
our $VERSION = 20060129.0900;
package Message::DOM::DOMLS::ManakaiDOMLSInput;
our $VERSION = 20060129.0900;
push our @ISA, 'Message::DOM::DOMMain::ManakaiDOMObject', 'Message::DOM::IF::LSInput', 'Message::DOM::IFLatest::LSInput', 'Message::DOM::IFLevel3::LSInput';
sub character_stream ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{character_stream};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{character_stream} = $given;


;}
}
}
sub byte_stream ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{byte_stream};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{byte_stream} = $given;


;}
}
}
sub string_data ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


$r = ref $self->{string_data} eq 'SCALAR'
       ? ${$self->{string_data}} : $self->{string_data};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{string_data} = ref $given eq 'SCALAR' ? $given : \$given;


;}
}
}
sub system_id ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{system_id};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{system_id} = $given;


;}
}
}
sub public_id ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{public_id};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{public_id} = $self;


;}
}
}
sub base_uri ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


$r = $self->{base_uri};


;}
$r;
} else {my ($self, $given) = @_;

{

if 
(not defined $given) {
  
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#null-base-uri', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'set', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMLS::ManakaiDOMLSInput', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'base_uri';

;
} elsif (
($given !~ /\A[0-9A-Za-z+_.%-]+:/)
) {
  
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#relative-base-uri', 'rdata' => $given, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'set', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMLS::ManakaiDOMLSInput', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'base_uri';

;
}
$self->{base_uri} = $given;


;}
}
}
sub encoding ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


$r = $self->{encoding};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{encoding} = $given;


;}
}
}
sub certified_text ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = 0;

{


$r = $self->{certified_text};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{certified_text} = $given;


;}
}
}
sub _new ($) {
my ($self) = @_;
my $r;

{


$r = bless {}, $self;


;}

{

if 
(ref $r eq 'HASH') {
  $r = bless $r, 
'Message::DOM::DOMLS::ManakaiDOMLSInput'
;
}


;}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMLS::ManakaiDOMLSInput>} = {'ls', {'', '1', '3.0', '1'}, 'ls-async', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMLS::ManakaiDOMLSInput>} = 6;
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#relative-uri'} = {'description', 'A relative reference is specified where its interpretation is implementation dependent.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#relative-uri'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#relative-base-uri'} = {'description', 'A relative reference is specified as the base URI where its interpretation is implementation dependent.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#relative-base-uri'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#null-base-uri'} = {'description', '<DOM::null> is specified as the base URI.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#null-base-uri'};
package Message::DOM::IFLatest::LSResourceResolver;
our $VERSION = 20060129.0900;
package Message::DOM::DOMLS::ManakaiDOMLSResourceResolver;
our $VERSION = 20060129.0900;
push our @ISA, 'Message::DOM::IF::LSResourceResolver', 'Message::DOM::IFLatest::LSResourceResolver', 'Message::DOM::IFLevel3::LSResourceResolver';
sub resolve_resource ($$$;$$$) {
my ($self, $type, $namespaceURI, $publicId, $systemId, $baseURI) = @_;
my $r;

{

goto 
&$self;


;}

{

if 
(ref $r eq 'HASH') {
  $r = bless $r, 
'Message::DOM::DOMLS::ManakaiDOMLSInput'
;
}


;}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMLS::ManakaiDOMLSResourceResolver>} = {'ls', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMLS::ManakaiDOMLSResourceResolver>} = 3;
package Message::DOM::IFLatest::LSParserFilter;
our $VERSION = 20060129.0900;
sub FILTER_ACCEPT () {
1}
sub FILTER_REJECT () {
2}
sub FILTER_SKIP () {
3}
sub FILTER_INTERRUPT () {
4}
package Message::DOM::IFLatest::LSSerializer;
our $VERSION = 20060129.0900;
package Message::DOM::IFLatest::LSOutput;
our $VERSION = 20060129.0900;
package Message::DOM::DOMLS::ManakaiDOMLSOutput;
our $VERSION = 20060129.0900;
push our @ISA, 'Message::DOM::DOMMain::ManakaiDOMObject', 'Message::DOM::IF::LSOutput', 'Message::DOM::IFLatest::LSOutput', 'Message::DOM::IFLevel3::LSOutput';
sub character_stream ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{characterStream};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{characterStream} = $given;


;}
}
}
sub byte_stream ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{byteStream};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{byteStream} = $given;


;}
}
}
sub system_id ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r;

{


$r = $self->{systemId};


;}
$r;
} else {my ($self, $given) = @_;

{

if 
(
($given !~ /\A[0-9A-Za-z+_.%-]+:/)
) {
  
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#relative-uri', 'rdata' => $given, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#on' => 'set', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::DOMLS::ManakaiDOMLSOutput', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#attr' => 'system_id';

;
}
$self->{systemId} = $given;


;}
}
}
sub encoding ($;$) {
if (@_ == 1) {my ($self) = @_;
my $r = '';

{


$r = $self->{encoding};


;}
$r;
} else {my ($self, $given) = @_;

{


$self->{encoding} = $given;


;}
}
}
sub _new ($) {
my ($self) = @_;
my $r;

{


$r = bless {}, $self;


;}
$r}
$Message::DOM::ClassFeature{q<Message::DOM::DOMLS::ManakaiDOMLSOutput>} = {'ls', {'', '1', '3.0', '1'}};
$Message::DOM::ClassPoint{q<Message::DOM::DOMLS::ManakaiDOMLSOutput>} = 3;
package Message::DOM::IFLatest::LSProgressEvent;
our $VERSION = 20060129.0900;
package Message::DOM::IFLatest::LSLoadEvent;
our $VERSION = 20060129.0900;
package Message::DOM::IFLatest::LSSerializerFilter;
our $VERSION = 20060129.0900;
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#doctype-not-allowed'} = {'description', 'If the configuration parameter <err::disallow-doctype> is set to <DOM::true> and a document type declaration is encountered.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'doctype-not-allowed'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#no-input-specified'} = {'description', 'When loading a document, no input is specified in the <IF::LSInput> object.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'no-input-specified'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#pi-base-uri-not-preserved'} = {'description', 'If a processing instruction is encountered in context where the base URI of the processing instruction cannot be preserved.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'pi-base-uri-not-preserved'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#unbound-prefix-in-entity'} = {'description', 'The configuration parameter <cfg::DOMCore:namespaces> is set to <DOM::true> and an unbound namespace prefix is encountered in the replacement text of an entity. This warning is implementation dependent and not enforced since some existing parsers may not recognize unbound namespace prefixes in the replacement text of entities. <SRC::DOM Level 3 LS>', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'unbound-prefix-in-entity'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#unknown-character-denormalization'} = {'description', 'If the configuration parameter <cfg::ignore-unknown-character-denormalizations> is set to <DOM::false> and a character is encountered for which the processor cannot determine the normalization properties.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'unknown-character-denormalization'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#unknown-character-denormalization.warning'} = {'description', 'If the configuration parameter <cfg::ignore-unknown-character-denormalizations> is set to <DOM::true> and verifying full normalization of XML 1.1 is supported and a character is encountered for which the processor cannot determine the normalization properties.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'unknown-character-denormalization'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#unsupported-encoding'} = {'description', 'If an unsupported encoding is encountered.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'unsupported-encoding'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#unsupported-media-type'} = {'description', 'If the configuration parameter <cfg::supported-media-types-only> is set to <DOM::true> and an unsupported media type is encountered.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'unsupported-media-type'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#no-output-specified'} = {'description', 'If no output is specified in <IF::LSOutput> when writing to it.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'no-output-specified'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#unbound-prefix-in-entity-reference'} = {'description', 'If the configuration parameter <cfg::DOMCore:namespaces> is set to <DOM::true> and an entity whose replacement text contains unbound namespace prefixes is referenced in context where there are no bindings for the namespace prefixes.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'unbound-prefix-in-entity-reference'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#canonical-form-not-xml10'} = {'description', 'If the configuration parameter <cfg::canonical-form> is set to <DOM::true> and an attempt is made to serialize a non-XML 1.0 document.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '3', 't', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#canonical-form-not-xml10'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#byte-order-mark-needed'} = {'description', 'If the <CHAR::BYTE ORDER MARK> is not generated.', 'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter', 'Message::Util::Error::formatter', 'sev', '1', 't', 'byte-order-mark-needed'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'canonical-form'} = {'iname', 'canon', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'canonical-form'} = {'iname', 'canon', 'setparam', [undef, {'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2004/dom/ls%23discard-default-content+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest', '0', 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2004/dom/ls%23format-pretty-print+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest', '0', 'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2004/dom/ls%23xml-declaration+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest', '0'}], 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{undef}->{'cdata-sections'} = {'iname', 'pcdsect', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{undef}->{'cdata-sections'} = {'iname', 'pcdsect', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'charset-overrides-xml-encoding'} = {'default', '1', 'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#charset-overrides-xml-encoding', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'check-character-normalization'} = {'iname', 'charnormc', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'check-character-normalization'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'check-character-normalization'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'comments'} = {'iname', 'pcom', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'comments'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'comments'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'datatype-normalization'} = {'iname', 'tnorm', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'datatype-normalization'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'datatype-normalization'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'disallow-doctype'} = {'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#disallow-doctype', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'element-content-whitespace'} = {'iname', 'pecws', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'element-content-whitespace'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'element-content-whitespace'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'entities'} = {'iname', 'pent', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'entities'} = {'iname', 'pent', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'error-handler'} = {'checker', sub ($$$) {
my ($self, $name, $value) = @_;

{


$name = lc $name;


;}

{


$value = bless $value, 
'Message::DOM::DOMCore::ManakaiDOMErrorHandler'
  if 
ref $value eq 'CODE';


;}
my $r = 0;

{


$r = UNIVERSAL::isa ($value, 
'Message::DOM::IFLatest::DOMErrorHandler'
);


;}
$r}
, 'get_default', sub ($$) {
my ($self, $name) = @_;

{


$name = lc $name;


;}
my $r;

{


$r = sub {
  my (undef, $err) = @_;
  CORE::warn $err;
  return ($err->
severity
 !=
          
3
);
};


;}

{


$r = bless $r, 
'Message::DOM::DOMCore::ManakaiDOMErrorHandler'
  if 
ref $r eq 'CODE';


;}
$r}
, 'iname', 'onerr', 'otype', 'Message::DOM::IFLatest::DOMErrorHandler', 'setter', sub ($$$) {
my ($self, $name, $value) = @_;

{


$name = lc $name;


;}

{


$value = bless $value, 
'Message::DOM::DOMCore::ManakaiDOMErrorHandler'
  if 
ref $value eq 'CODE';


;}

{


$self->[1]->{
'onerr'
} = $value;


;}
}
, 'type', 'object'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'error-handler'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'error-handler'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'ignore-unknown-character-denormalizations'} = {'default', '1', 'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#ignore-unknown-character-denormalizations', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'ignore-unknown-character-denormalizations'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'ignore-unknown-character-denormalizations'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'infoset'} = {'getter', sub ($$) {
my ($self, $name) = @_;

{


$name = lc $name;


;}
my $r = 0;

{


{

local $Error::Depth = $Error::Depth + 1;

{



  $r = !$self->
get_parameter

                                       ('validate-if-schema') &&
       !$self->
get_parameter

                                       ('entities') &&
       !$self->
get_parameter

                                       ('datatype-normalization') &&
       !$self->
get_parameter

                                       ('cdata-sections') && 
        $self->
get_parameter

                                       ('namespace-declarations') &&
        $self->
get_parameter

                                       ('well-formed') &&
        $self->
get_parameter

                                       ('element-content-whitespace') &&
        $self->
get_parameter

                                       ('comment') && 
        $self->
get_parameter

                                       ('namespaces');



;}


;}

;


;}
$r}
, 'iname', 'http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#infoset', 'setter', sub ($$$) {
my ($self, $name, $value) = @_;

{


$name = lc $name;


;}

{


## TODO: Warning


;}
}
, 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'infoset'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'infoset'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'namespaces'} = {'iname', 'nsaware', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'namespaces'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'namespaces'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'namespace-declarations'} = {'iname', 'pnsattr', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'namespace-declarations'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'namespace-declarations'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'normalize-characters'} = {'iname', 'charnorm', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'normalize-characters'} = {'default', '1', 'iname', 'charnorm', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::Document'}->{'resource-resolver'} = {'iname', 'rresolver', 'otype', 'Message::DOM::IFLatest::LSResourceResolver', 'setter', sub ($$$) {
my ($self, $name, $value) = @_;

{


$self->[1]->{
'rresolver'
} = $value;


;}
}
, 'type', 'object'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'resource-resolver'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::Document'}->{'resource-resolver'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'schema-location'} = {'getter', sub ($$) {
my ($self, $name) = @_;

{


$name = lc $name;


;}
my $r = '';

{

my 
$v = $self->[1]->{
'scloc'
};
if (defined $v and @$v) {
  $r = join ' ', @$v;
} else {
  $r = 
undef
;
}


;}
$r}
, 'iname', 'scloc', 'setter', sub ($$$) {
my ($self, $name, $value) = @_;

{


$name = lc $name;


;}

{


$self->[1]->{
'scloc'
} = $value;


;}
}
, 'type', 'string'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'schema-location'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'schema-location'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'schema-type'} = {'iname', 'sctype', 'type', 'string'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'schema-type'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'schema-type'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'split-cdata-sections'} = {'iname', 'splitcdsect', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'split-cdata-sections'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'split-cdata-sections'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'validate'} = {'iname', 'val', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'validate'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'validate'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'validate-if-schema'} = {'iname', 'vals', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'validate-if-schema'} = $Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'validate-if-schema'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'well-formed'} = {'iname', 'wf', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'well-formed'} = {'iname', 'wf', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSParser'}->{'supported-media-types-only'} = {'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#supported-media-types-only', 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'discard-default-content'} = {'default', '1', 'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#discard-default-content', 'setparam', [undef, {'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2004/dom/ls%23canonical-form+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest', '0'}], 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'format-pretty-print'} = {'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#format-pretty-print', 'setparam', [undef, {'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2004/dom/ls%23canonical-form+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest', '0'}], 'type', 'boolean'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::IFLatest::LSSerializer'}->{'xml-declaration'} = {'default', '1', 'iname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/ls#xml-declaration', 'setparam', [undef, {'tag:suika.fam.cx,2005-09:http://suika.fam.cx/~wakaba/archive/2004/dom/ls%23canonical-form+http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom%23ManakaiDOMLatest', '0'}], 'type', 'boolean'};
push @Message::DOM::IF::LSException::ISA, 'Message::Util::Error' unless @Message::DOM::IF::LSException::ISA;
push @Message::DOM::IFLevel3::LSException::ISA, 'Message::Util::Error' unless @Message::DOM::IFLevel3::LSException::ISA;
for ($Message::DOM::IF::DOMImplementationLS::, $Message::DOM::IF::LSInput::, $Message::DOM::IF::LSOutput::, $Message::DOM::IF::LSResourceResolver::, $Message::DOM::IFLevel3::DOMImplementationLS::, $Message::DOM::IFLevel3::LSInput::, $Message::DOM::IFLevel3::LSOutput::, $Message::DOM::IFLevel3::LSResourceResolver::){}
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
1;
