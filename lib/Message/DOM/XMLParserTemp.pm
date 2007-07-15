# -*- mode: fundamental -*- # cperl-mode takes very long time to parse
package Message::DOM::XMLParserTemp;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::DOM::DOMCore::ManakaiDOMError;
push our @ISA, 'Message::DOM::DOMError';
require Message::DOM::DOMError;

sub ___error_def {
  return \%Message::DOM::DOMCore::ManakaiDOMError::Def;
}

sub location {
  $_[0]->{location} ||= $_[0]->{loc};
  return $_[0]->SUPER::location;
}

sub _FORMATTER_PACKAGE_ {
  'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter'
}

$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error'} = {'-description',
'|%xp-error-token-type;|%xp-error-token-value (prefix => { (|}, suffix => {|)}); is not allowed%xp-error-lines (prefix => { (|}, suffix => {|)});',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml'} = {'-description',
'Processing instruction target name cannot be |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});|',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-end-tag'} = {'-description',
'End-tag |</%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#expected-element-type});>| is required',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-end-tag'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-unsupported-xml-version'} = {'-description',
'XML version |%p (name => {http://www.w3.org/2001/04/infoset#version});| is not supported',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-unsupported-xml-version'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-malformed-enc-name'} = {'-description',
'Encoding name |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not allowed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-malformed-enc-name'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-malformed-xml-standalone'} = {'-description',
'|standalone| pseudo-attribute value |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not allowed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-malformed-xml-standalone'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-literal-character'} = {'-description',
'Character %character-code-point (v => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number}); is not allowed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-literal-character'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name'} = {'-description',
'Character %character-code-point (v => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number}); is not allowed in name',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'wf-invalid-character-in-node-name'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pes-in-internal-subset'} = {'-description',
'Parameter entity reference |%percent;%param (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});;| cannot occur within a markup declaration',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pes-in-internal-subset'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-element-type-match'} = {'-description',
'End-tag |</%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#actual-element-type});>| does not match to start-tag |<%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#expected-element-type});>|',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-element-type-match'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-unique-att-spec'} = {'-description',
'Attribute |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is specified more than once in the same tag',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-unique-att-spec'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references'} = {'-description',
'External entity |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is referenced in an attribute value literal',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-lt-in-attribute-values'} = {'-description',
'Entity replacement text cannot contain a |LESS-THAN SIGN| since it is referenced from an attribute value literal',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-lt-in-attribute-values'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-attribute-definition-ignored'} = {'-description',
'Attribute definition for |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is ignored',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-attribute-definition-ignored'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character'} = {'-description',
'Reference to character %character-code-point (v => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number}); is not allowed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared'} = {'-description',
'Entity |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| must be declared in the internal subset',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-parsed-entity'} = {'-description',
'Entity |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is an unparsed entity',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-parsed-entity'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion'} = {'-description',
'Entity |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is recursively referenced',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-xml11-end-of-line-in-xml-declaration'} = {'-description',
'End-of-line character %character-code-point (v => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number}); cannot be used within the XML or text declaration',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-xml11-end-of-line-in-xml-declaration'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-internal-predefined-entity'} = {'-description',
'Entity |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| must be declared as an internal entity',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'2',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-internal-predefined-entity'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-malformed-predefined-entity'} = {'-description',
'Entity declaration for |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| (replacement text |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#replacement-text});|) is malformed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'2',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-malformed-predefined-entity'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-entity-declaration-ignored'} = {'-description',
'Entity declaration for |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is ignored',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-entity-declaration-ignored'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#vc-unique-notation-name'} = {'-description',
'Notation |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is already declared',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'2',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#vc-unique-notation-name'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-entity-declaration-not-processed'} = {'-description',
'Entity declaration for |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not processed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-entity-declaration-not-processed'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-attribute-definition-not-processed'} = {'-description',
'Attribute definition for |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not processed',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-attribute-definition-not-processed'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-illegal-byte-sequence'} = {'-description',
'Illegal byte sequence',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-illegal-byte-sequence'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-unassigned-code-point'} = {'-description',
'Unassigned code point found',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-unassigned-code-point'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-unprocessable-encoding'} = {'-description',
'Encoding <%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#charset-uri});> %p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#encoding}, prefix => {(}, suffix => {) });is not supported',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-unprocessable-encoding'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-utf-16-no-bom'} = {'-description',
'The entity contains no BOM',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-utf-16-no-bom'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-encoding-mismatch'} = {'-description',
'The entity is labeled as <%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#charset-uri});> %p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#encoding}, prefix => {(}, suffix => {) });but it is wrong',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-encoding-mismatch'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warn-unknown-decode-error'} = {'-description',
'Encoding decoder error: <%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-type});>',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'1',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warn-unknown-decode-error'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname'} = {'-description',
'<CODE::Name> |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not an <CODE::NCName>',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname'} = {'-description',
'<CODE::Name> |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not a <CODE::QName>',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-prefix-xml'} = {'-description',
'Namespace prefix |xml| cannot be bound to namespace name |%p (name => {http://www.w3.org/2001/04/infoset#namespaceName});|',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-prefix-xml'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xml'} = {'-description',
'Namespace prefix |%p (name => {http://www.w3.org/2001/04/infoset#prefix});| cannot be bound to namespace name |http://www.w3.org/XML/1998/namespace|',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xml'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-prefix-xmlns'} = {'-description',
'Namespace prefix |xmlns| cannot be declared or undeclared',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-prefix-xmlns'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xmlns'} = {'-description',
'Namespace prefix |%p (name => {http://www.w3.org/2001/04/infoset#prefix});| cannot be bound to namespace name |http://www.w3.org/2000/xmlns/|',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xmlns'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-prefix-declared'} = {'-description',
'Namespace prefix |%p (name => {http://www.w3.org/2001/04/infoset#prefix});| in qualified name |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| is not declared',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-prefix-declared'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-empty-namespace-name'} = {'-description',
'Namespace |%p (name => {http://www.w3.org/2001/04/infoset#prefix});| cannot be undeclared in XML 1.0',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-empty-namespace-name'};
$Message::DOM::DOMCore::ManakaiDOMError::Def{'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-unique-att-spec-expanded-name'} = {'-description',
'Attribute |%p (name => {http://www.w3.org/2001/04/infoset#localName});| in namespace |%p (name => {http://www.w3.org/2001/04/infoset#namespaceName});| is attached to the same element more than once (as |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name});| and |%p (name => {http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#another-attribute-name});|)',
'http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/Core/textFormatter',
'Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter',
'sev',
'3',
't',
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-unique-att-spec-expanded-name'};
$Message::DOM::DOMCore::ManakaiDOMConfiguration{'Message::DOM::XMLParser::ManakaiXMLParser'}->{'http://suika.fam.cx/www/2006/dom-config/xml-id'} = {'iname',
'xmlid',
'type',
'boolean',
'vsupport',
['1',
'1']};

package Message::DOM::DOMLS::ManakaiDOMLSException;
push our @ISA, 'Message::DOM::DOMException';

sub ___error_def {
+{
  PARSE_ERR => {
    -code => 80,
    -description => q(XML parse error),
  },
}
}

package Message::DOM::XMLParserTemp;

use Char::Class::XML 'InXMLNCNameChar10',
'InXMLNCNameChar11',
'InXMLNCNameStartChar11',
'InXMLNameChar10',
'InXMLNameChar11',
'InXMLNameStartChar11',
'InXML_NCNameStartChar10',
'InXML_NameStartChar10';

sub parse_byte_stream ($$$$%) {
  my ($class, $filehandle_byte, $impl, $onerror, %opt) = @_;
  my $self = bless {}, $class;
  
  $opt{document_uri} = q<thismessage:/> unless defined $opt{document_uri};
  $opt{base_uri} = $opt{document_uri} unless defined $opt{base_uri};
  # $opt{charset};

  $self->{onerror} = $onerror || sub { warn $_[0] };

  require Whatpm::Charset::DecodeHandle;
  my $encode_uri = defined $opt{charset}
      ? Whatpm::Charset::DecodeHandle->name_to_uri (xml => $opt{charset})
      : 'http://suika.fam.cx/www/2006/03/xml-entity/';
  my $filehandle_char = Whatpm::Charset::DecodeHandle->create_decode_handle
      ($encode_uri, $filehandle_byte, sub {
         my ($fh, $type, %opt) = @_;
         my $continue = 1;
         if ($type eq 'illegal-octets-error') {
           $continue = report Message::DOM::DOMCore::ManakaiDOMError
               -object => $self, ## ISSUE: Memory leak?
               -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-illegal-byte-sequence',
               'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#byte-sequence' => $opt{octets};
         } elsif ($type eq 'unassigned-code-point-error') {
           $continue = report Message::DOM::DOMCore::ManakaiDOMError
               -object => $self, ## ISSUE: Memory leak?
               -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-unassigned-code-point',
               byte_sequence => $opt{octets};
           $opt{octets} = \"\x{FFFD}";
         } elsif ($type eq 'invalid-state-error') {
           $continue = report Message::DOM::DOMCore::ManakaiDOMError
               -object => $self, ## ISSUE: Memory leak?
               -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-illegal-byte-sequence',
               code_state => $opt{state};
         } elsif ($type eq 'charset-not-supported-error') {
           $continue = report Message::DOM::DOMCore::ManakaiDOMError
               -object => $self, ## ISSUE: Memory leak?
               -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-unprocessable-encoding',
               charset_uri => $opt{charset_uri};
         } elsif ($type eq 'no-bom-error') {
           if ($opt{charset_uri} eq 'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.utf-16') {
             $continue = report Message::DOM::DOMCore::ManakaiDOMError
                 -object => $self, ## ISSUE: Memory leak?
                 -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-utf-16-no-bom';
           } else {
             $continue = report Message::DOM::DOMCore::ManakaiDOMError
                 -object => $self, ## ISSUE: Memory leak?
                 -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-illegal-byte-sequence',
                 code_state => 'bom';
           }
         } elsif ($type eq 'charset-name-mismatch-error') {
           $continue = report Message::DOM::DOMCore::ManakaiDOMError
               -object => $self, ## ISSUE: Memory leak?
               -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-encoding-mismatch',
               charset_uri => $opt{charset_uri};
         } else {
           $continue = report Message::DOM::DOMCore::ManakaiDOMError
               -object => $self, ## ISSUE: Memory leak?
               -type => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warn-unknown-decode-error',
               error_type => $type,
               error_param => \%opt;
         }
         unless ($continue) {
           die "LSException: PARSE_ERR"; # TODO: for now.
         }
      });
  unless (defined $filehandle_char) {
    die "LSException: PARSE_ERR: Encoding not supported"; ## TODO: for now.
  }

  require IO::Handle;
  
  $self->{char} = [];
  $self->{token} = [];
  $self->{entity} = [{
    fh => $filehandle_char,
    base_uri => $opt{base_uri},
    doc_uri => $opt{document_uri},
    in_enc => $filehandle_char->input_encoding,
    line => 1,
    column => 1,
    pos => 0,
    close_file => sub { $filehandle_char->close },
    reptxt => \'',
    is_external_entity => 1,
  }];

  ## Entity stack.
  $self->{location} = $self->{entity}->[-1];
  ## Parsing location object as required by DPG.
  ## It must always be equal to |{entity}->[-1]|.
  $self->{entity_char} = [];
  ## Stack for |{char}| stacks analog to |{entity}| stack.
  $self->{entity_token} = [];
  ## Stack for |{token}| stacks analog to |{entity}| stack.
  $self->{xml_version} = '1.0';
  ## Document XML version: either |1.0| or |1.1|.
  $self->{standalone} = 0;
  ## True iff |standalone=yes| is explicitly specified.
  $self->{has_xref} = 0;
  ## There is an unread external entity.
  $self->{dont_process} = 0;
  ## So, don't process |ENTITY| and |ATTLIST| declarations.
  $self->{general_entity} = {
    lt => {is_predefined => 1},
    gt => {is_predefined => 1},
    amp => {is_predefined => 1},
    quot => {is_predefined => 1},
    apos => {is_predefined => 1},
  };
  ## Declared general entities.
  $self->{param_entity} = {};
  ## Declared parameter entities.
  $self->{attr} = {};
  # $self->{attr}->{$element_type_name}->{$attr_name} = $attr_def
  ## Declared attributes.

  $self->{doc} = $impl->create_document;
    ## |Document| object.
  $self->{doc_cfg} = $self->{doc}->dom_config;
    ## |Document|'s configuration.
  CORE::delete $self->{dtdef};
    ## |DocumentTypeDefinition| object (if created).
  CORE::delete $self->{dtdecl};
    ## |DocumentTypeDeclaration| object (if created).
  $self->{doc}->strict_error_checking (0);
    ## NOTE: Any checks such as |Name| validity done by
    ##       methods on DOM nodes are disabled.  It might result
    ##       in creating an ill-formed DOM tree when parser
    ##       errors are traped by |error-handler|.
  $self->{doc_cfg}->
set_parameter

                      (
'http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree'
 => 
1
);
    ## NOTE: Turn this configuration parameter on makes 
    ##       entity reference subtrees in attribute default values
    ##       cloned as is into default attribute node subtrees.
  $self->{doc_cfg}->
set_parameter

                      (
'http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute'
 => 
0
);
    ## NOTE: Don't create DTD default attributes by
    ##       |createElementNS| method.
  $self->{doc_cfg}->
set_parameter

                      (
'http://suika.fam.cx/www/2006/dom-config/xml-id'
 => $self->{'http://suika.fam.cx/www/2006/dom-config/xml-id'});
  $self->{doc_cfg}->set_parameter ('error-handler' => sub {
    my $err = shift;
    return $err->severity != 3;
  }) unless $Message::DOM::XMLParser::DEBUG;
    ## NOTE: The default error handler in manakai |warn|s error
    ##       description.

  ## Document entity's URI and base URI
  $self->{doc}->
document_uri
 ($self->{entity}->[0]->{doc_uri});
  $self->{doc}->
manakai_entity_base_uri

        ($self->{entity}->[0]->{base_uri});

  ## Encoding name
  $self->{doc}->
input_encoding
 ($self->{entity}->[0]->{in_enc});

  ## Document entity -> |Document| node
  $self->_parse_DocumentEntity;

  for (@{$self->{entity}}) {
    $_->{close_file}->();
    ## NOTE: There should be only the document entity.
  }

  ## Replacement tree for general |Entity| nodes
  if ($self->{'http://suika.fam.cx/www/2006/dom-config/entity-replacement-tree'}) {
    my @ent = values %{$self->{general_entity}};
    for my $ent (@ent) {
      if (exists $ent->{has_replacement_text}) {
        my $ent_name = $ent->{name};
        $self->{entity} = [
{%{$self->{'general_entity'}->{$ent_name}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$ent_name}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
];
        $self->{location} = $self->{entity}->[-1];
        $self->{token} = [];
        $self->{char} = [];
        local $ent->{is_opened} = 
1
;
        ## TODO: External entity support
        $ent->{node}->
manakai_set_read_only
 (
0
, 
1
);
        $self->_parse_InternalGeneralParsedEntity ($ent->{node});
        $ent->{node}->
has_replacement_tree
 (
1
);
        $ent->{node}->
manakai_set_read_only
 (
1
, 
1
);
        $self->{entity}->[-1]->{close_file}->();
        ## ISSUE: Should errors detected by this phase result
        ##        in |DOMLS:PARSE_ERR| exception thrown?
      }
    }
  } # cfg|entity-replacement-tree

  ## Turns flags to their default value
  $self->{doc_cfg}->
set_parameter

                      (
'http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree'
 => 
undef
);
  $self->{doc_cfg}->
set_parameter

                      (
'http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute'
 => 
undef
);
  $self->{doc_cfg}->
set_parameter

                      (
'http://suika.fam.cx/www/2006/dom-config/xml-id'
 => 
undef
);
  $self->{doc_cfg}->
set_parameter

                      ('error-handler' => 
undef
);
  $self->{doc}->
strict_error_checking
 (
1
);


  return $self->{doc};
} # parse_byte_stream

sub _shift_char ($) {
my ($self) = @_;
my $r = 0;

{

if 
(@{$self->{char}}) {
  $r = shift @{$self->{char}};
} else {
  GETCHAR: {
    no warnings 'closed'; # getc() on closed filehandle warning
    my $ent = $self->{entity}->[-1];
    my $char = $ent->{fh}->getc;

    if (defined $char and length $char) {
      $ent->{pos}++;
      $r = ord $char;
      if ($r == 0x000A) {
        $ent->{line}++;
        $ent->{column} = 1;
      } elsif ($r == 0x000D) {
        my $next_char = $ent->{fh}->getc;
        if ($next_char eq "\x0A") {
          if ($ent->{is_external_entity}) {
            $ent->{pos}++;
            $ent->{line}++;
            $ent->{column} = 1;
            $r = 0x000A; # ^ U+000D U+000A -> U+000A ^
          } else { # Internal entity
            $ent->{column}++;
            ## Line number will be increased by next |shiftChar|.
            $ent->{fh}->ungetc (0x000A);
            #$r = 0x000D; # ^ U+000D U+000A -> U+000D ^ U+000A
            # no change
          }
        } elsif ($next_char eq "\x85") {
          if ($self->{xml_version} eq '1.1') {
            if ($ent->{is_external_entity}) {
              if ($ent->{no_xml11_eol}) {
                my $location = {
                  utf32_offset => $ent->{pos} - 1,
                  line_number => $ent->{line},
                  column_number => $ent->{column},
                };
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-xml11-end-of-line-in-xml-declaration', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => '_shift_char', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::XMLParser::ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $r;

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              } # no_xml11_eol
              $ent->{pos}++; 
              $ent->{line}++;
              $ent->{column} = 1;
              $r = 0x000A; # ^ U+000D U+0085 -> U+000A ^
            } else { # internal entity
              $ent->{column}++;
              ## Line number will be increased by next |shiftChar|.
              $ent->{fh}->ungetc (0x0085);
              #$r = 0x000D; # ^ U+000D U+0085 -> U+000D ^ U+0085
              # no change
            }
          } else { # XML 1.0
            ## |no_xml11_eol| will be tested later.
            $ent->{column}++;
            ## Line number will be increased by next |shiftChar|.
            $ent->{fh}->ungetc (0x0085);
            $r = 0x000A if $ent->{is_external_entity};
              # external: ^ U+000D U+0085 -> U+000A ^ U+0085
              # internal: ^ U+000D U+0085 -> U+000D ^ U+0085 (as is)
          }
        } else { # neither U+000A nor U+0085
          $ent->{line}++;
          $ent->{column} = 1;
          $ent->{fh}->ungetc (ord $next_char);
          $r = 0x000A if $ent->{is_external_entity};
            # external: ^ U+000D _ -> U+000A ^ _
            # internal: ^ U+000D _ -> U+000D ^ _ (as is)
        }
      } elsif ($r == 0x0085 or $r == 0x2028) {
        if ($ent->{no_xml11_eol}) {
          my $location = {
            utf32_offset => $ent->{pos} - 1,
            line_number => $ent->{line},
            column_number => $ent->{column},
          };
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#fatal-xml11-end-of-line-in-xml-declaration', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => '_shift_char', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::XMLParser::ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $r;

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        } # no_xml11_eol
        $r = 0x000A if $self->{xml_version} eq '1.1' and
                       $ent->{is_external_entity};
        ## Even in XML 1.0 it increases the line number.
        $ent->{line}++;
        $ent->{column} = 1;
      } elsif (
        not ((0x0020 <= $r and $r <= 0x007E) or
             (0x00A0 <= $r and $r <= 0xD7FF) or
             (0xE000 <= $r and $r <= 0xFFFD) or
             (0x10000 <= $r and $r <= 0x10FFFF)) and
        $r != 0x0009 and
        not (($self->{xml_version} eq '1.0' or
              not $ent->{is_external_entity}) and
             (0x007F <= $r and $r <= 0x009F)) and
        not ($self->{xml_version} eq '1.1' and
             not $ent->{is_external_entity} and
             0x0001 <= $r and $r <= 0x001F)
      ) {
        my $location = {
          utf32_offset => $ent->{pos} - 1,
          line_number => $ent->{line},
          column_number => $ent->{column},
        };
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-literal-character', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#method' => '_shift_char', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#class' => 'Message::DOM::XMLParser::ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $r;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
        $ent->{column}++;
      } else { # XML |Char|
        $ent->{column}++;
      }
    } else {
      $r = -1;
    }
  } # GETCHAR
}


}
$r}

sub ___report_error ($$) {
  my ($self, $err) = @_;
  if ($err->isa ('Message::IF::DOMError')) {
    local $Error::Depth = $Error::Depth + 1;
    return $self->{onerror}->($err);
  } else {
    $err->throw;
  }
}

sub _scan_DocumentEnd ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 60) 
{

push (@ch, $ch);

Sa1da4bc9c55a0fceab13363423b10eda:
{

my $ch = $self->_shift_char;
if ($ch == 63) 
{


S14958ebece080f97ea7332cf9e83907c:
{

return {'location',
$location,
'type',
'PIO'};


}
# S14958ebece080f97ea7332cf9e83907c


}
elsif ($ch == 33) 
{

push (@ch, $ch);

S797ce2cb00dd0bf121024b9327727179:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{

push (@ch, $ch);

S63f599bea4ea7ca8944683e740af956a:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S871e1185aa8ab8ce10a709a58cdd4d25:
{

return {'location',
$location,
'type',
'CDO'};


}
# S871e1185aa8ab8ce10a709a58cdd4d25


}
unshift (@{$self->{char}}, $ch);


}
# S63f599bea4ea7ca8944683e740af956a


}
unshift (@{$self->{char}}, $ch);


}
# S797ce2cb00dd0bf121024b9327727179


}
unshift (@{$self->{char}}, $ch);


}
# Sa1da4bc9c55a0fceab13363423b10eda


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_DocumentMisc ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 60) 
{

push (@ch, $ch);

Sa74534b3bb7273e8853604374372886f:
{

my $ch = $self->_shift_char;
if ($ch == 63) 
{


S14958ebece080f97ea7332cf9e83907c:
{

return {'location',
$location,
'type',
'PIO'};


}
# S14958ebece080f97ea7332cf9e83907c
unshift (@{$self->{char}}, $ch);


}
elsif ($ch == 33) 
{

push (@ch, $ch);

S797ce2cb00dd0bf121024b9327727179:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{

push (@ch, $ch);

S63f599bea4ea7ca8944683e740af956a:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S871e1185aa8ab8ce10a709a58cdd4d25:
{

return {'location',
$location,
'type',
'CDO'};


}
# S871e1185aa8ab8ce10a709a58cdd4d25


}
unshift (@{$self->{char}}, $ch);


}
# S63f599bea4ea7ca8944683e740af956a


}
unshift (@{$self->{char}}, $ch);


}
# S797ce2cb00dd0bf121024b9327727179
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'STAGO'};


}
# Sa74534b3bb7273e8853604374372886f


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_DocumentProlog ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 60) 
{

push (@ch, $ch);

S457909653166b3fdf8de026a018e3d23:
{

my $ch = $self->_shift_char;
if ($ch == 63) 
{


S14958ebece080f97ea7332cf9e83907c:
{

return {'location',
$location,
'type',
'PIO'};


}
# S14958ebece080f97ea7332cf9e83907c
unshift (@{$self->{char}}, $ch);


}
elsif ($ch == 33) 
{

push (@ch, $ch);

S053efb7c98fb0c0f8a7af7f2d8b5d7b5:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{

push (@ch, $ch);

S63f599bea4ea7ca8944683e740af956a:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S871e1185aa8ab8ce10a709a58cdd4d25:
{

return {'location',
$location,
'type',
'CDO'};


}
# S871e1185aa8ab8ce10a709a58cdd4d25


}
unshift (@{$self->{char}}, $ch);


}
# S63f599bea4ea7ca8944683e740af956a
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'MDO'};


}
# S053efb7c98fb0c0f8a7af7f2d8b5d7b5
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'STAGO'};


}
# S457909653166b3fdf8de026a018e3d23


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_DocumentStart ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 60) 
{

push (@ch, $ch);

S26446cc1a974639dacde1f3176499a42:
{

my $ch = $self->_shift_char;
if ($ch == 63) 
{

push (@ch, $ch);

Sd95027091cb2d533e375a5ef1b576306:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{

push (@ch, $ch);

S4878fb7bf6f42f86fa33996b5b91f37d:
{

my $ch = $self->_shift_char;
if ($ch == 109) 
{

push (@ch, $ch);

S4e73c07df53855f67c5bf738b183c86e:
{

my $ch = $self->_shift_char;
if ($ch == 108) 
{


S88bc15281d1a1d3f171d1537d5b586fa:
{

return {'location',
$location,
'type',
'XDO'};


}
# S88bc15281d1a1d3f171d1537d5b586fa


}
unshift (@{$self->{char}}, $ch);


}
# S4e73c07df53855f67c5bf738b183c86e


}
unshift (@{$self->{char}}, $ch);


}
# S4878fb7bf6f42f86fa33996b5b91f37d
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'PIO'};


}
# Sd95027091cb2d533e375a5ef1b576306
unshift (@{$self->{char}}, $ch);


}
elsif ($ch == 33) 
{

push (@ch, $ch);

S053efb7c98fb0c0f8a7af7f2d8b5d7b5:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{

push (@ch, $ch);

S63f599bea4ea7ca8944683e740af956a:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S871e1185aa8ab8ce10a709a58cdd4d25:
{

return {'location',
$location,
'type',
'CDO'};


}
# S871e1185aa8ab8ce10a709a58cdd4d25


}
unshift (@{$self->{char}}, $ch);


}
# S63f599bea4ea7ca8944683e740af956a
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'MDO'};


}
# S053efb7c98fb0c0f8a7af7f2d8b5d7b5
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'STAGO'};


}
# S26446cc1a974639dacde1f3176499a42


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_CommentDeclaration ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};
my @dch;

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 45) 
{

push (@ch, $ch);

S7cbbfe6822361aba376452051344e5b0:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S329bc175b2f886629e0de8924927c14e:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'COM'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'COM'};


}


}
# S329bc175b2f886629e0de8924927c14e


}
unshift (@{$self->{char}}, $ch);


}
# S7cbbfe6822361aba376452051344e5b0


}
elsif ($ch == -1) 
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'#EOF'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'#EOF'};


}


}
push (@dch, $ch);
redo Sb6eb11560b64af561256705703c93caf;


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_PIName ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 63) 
{

push (@ch, $ch);

S1ab95e885c202fc0810f4384f6b33aff:
{

my $ch = $self->_shift_char;
if ($ch == 62) 
{


S0da0e0b24dbb9376749d1ce7d4b35b63:
{

return {'location',
$location,
'type',
'PIC'};


}
# S0da0e0b24dbb9376749d1ce7d4b35b63


}
unshift (@{$self->{char}}, $ch);


}
# S1ab95e885c202fc0810f4384f6b33aff


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_PINmtoken ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S848f71a51122f9823d93f03a83b47d6f:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo S848f71a51122f9823d93f03a83b47d6f;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Nmtoken',
'value',
$token_val};


}
# S848f71a51122f9823d93f03a83b47d6f


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 63) 
{

push (@ch, $ch);

S1ab95e885c202fc0810f4384f6b33aff:
{

my $ch = $self->_shift_char;
if ($ch == 62) 
{


S0da0e0b24dbb9376749d1ce7d4b35b63:
{

return {'location',
$location,
'type',
'PIC'};


}
# S0da0e0b24dbb9376749d1ce7d4b35b63


}
unshift (@{$self->{char}}, $ch);


}
# S1ab95e885c202fc0810f4384f6b33aff


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_PIData ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};
my @dch;

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 63) 
{

push (@ch, $ch);

S1ab95e885c202fc0810f4384f6b33aff:
{

my $ch = $self->_shift_char;
if ($ch == 62) 
{


S0da0e0b24dbb9376749d1ce7d4b35b63:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'PIC'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'DATA',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'PIC'};


}


}
# S0da0e0b24dbb9376749d1ce7d4b35b63


}
unshift (@{$self->{char}}, $ch);


}
# S1ab95e885c202fc0810f4384f6b33aff


}
elsif ($ch == -1) 
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'#EOF'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'DATA',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'#EOF'};


}


}
push (@dch, $ch);
redo Sb6eb11560b64af561256705703c93caf;


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_ElementContent ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};
my @dch;

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 60) 
{

push (@ch, $ch);

S4ae8f48258713ea8f715924a72afc107:
{

my $ch = $self->_shift_char;
if ($ch == 33) 
{

push (@ch, $ch);

S7e551fab746c340198787d3a9ea116de:
{

my $ch = $self->_shift_char;
if ($ch == 91) 
{

push (@ch, $ch);

Sd09eb60899766ed7d7fefadddca7b1d9:
{

my $ch = $self->_shift_char;
if ($ch == 67) 
{

push (@ch, $ch);

Sb8b041e13b5053750231960dfdb1b827:
{

my $ch = $self->_shift_char;
if ($ch == 68) 
{

push (@ch, $ch);

Sc65eb0b0fdab9236792104e424253136:
{

my $ch = $self->_shift_char;
if ($ch == 65) 
{

push (@ch, $ch);

S6fb78181e28a4a3bdcaea1c3521d3c60:
{

my $ch = $self->_shift_char;
if ($ch == 84) 
{

push (@ch, $ch);

S6f8d9beabb8734e12126dcda9e478ca1:
{

my $ch = $self->_shift_char;
if ($ch == 65) 
{

push (@ch, $ch);

Sfa00d040b0ba9749d73ac5440ec003c4:
{

my $ch = $self->_shift_char;
if ($ch == 91) 
{


S145cd36a3abc6de613828690b95c2394:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'CDSO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'CDSO'};


}


}
# S145cd36a3abc6de613828690b95c2394


}
unshift (@{$self->{char}}, $ch);


}
# Sfa00d040b0ba9749d73ac5440ec003c4


}
unshift (@{$self->{char}}, $ch);


}
# S6f8d9beabb8734e12126dcda9e478ca1


}
unshift (@{$self->{char}}, $ch);


}
# S6fb78181e28a4a3bdcaea1c3521d3c60


}
unshift (@{$self->{char}}, $ch);


}
# Sc65eb0b0fdab9236792104e424253136


}
unshift (@{$self->{char}}, $ch);


}
# Sb8b041e13b5053750231960dfdb1b827


}
unshift (@{$self->{char}}, $ch);


}
# Sd09eb60899766ed7d7fefadddca7b1d9


}
elsif ($ch == 45) 
{

push (@ch, $ch);

S63f599bea4ea7ca8944683e740af956a:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S871e1185aa8ab8ce10a709a58cdd4d25:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'CDO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'CDO'};


}


}
# S871e1185aa8ab8ce10a709a58cdd4d25


}
unshift (@{$self->{char}}, $ch);


}
# S63f599bea4ea7ca8944683e740af956a


}
unshift (@{$self->{char}}, $ch);


}
# S7e551fab746c340198787d3a9ea116de
unshift (@{$self->{char}}, $ch);


}
elsif ($ch == 63) 
{


S14958ebece080f97ea7332cf9e83907c:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'PIO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'PIO'};


}


}
# S14958ebece080f97ea7332cf9e83907c
unshift (@{$self->{char}}, $ch);


}
elsif ($ch == 47) 
{


S7cf7222ce0d1641ea7bef5223814096d:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'ETAGO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'ETAGO'};


}


}
# S7cf7222ce0d1641ea7bef5223814096d
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'STAGO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'STAGO'};


}


}
# S4ae8f48258713ea8f715924a72afc107


}
elsif ($ch == 38) 
{

push (@ch, $ch);

Sb38bd1b50570b4f4ed86d6f1e11d017d:
{

my $ch = $self->_shift_char;
if ($ch == 35) 
{

push (@ch, $ch);

S1c2bac16e184ab0fa17b03ae05b56d1e:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{


S9d912bd81aee720926e2f5eeadae8441:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'HCRO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'HCRO'};


}


}
# S9d912bd81aee720926e2f5eeadae8441
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'CRO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'CRO'};


}


}
# S1c2bac16e184ab0fa17b03ae05b56d1e
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'ERO'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'ERO'};


}


}
# Sb38bd1b50570b4f4ed86d6f1e11d017d


}
elsif ($ch == 93) 
{

push (@ch, $ch);

Sdac3cc8cbc3f856c13aa9dedbf1660e0:
{

my $ch = $self->_shift_char;
if ($ch == 93) 
{

push (@ch, $ch);

Sa2e3d52421d38edc67f2c6dbcb466dfa:
{

my $ch = $self->_shift_char;
if ($ch == 62) 
{


S0b2cef6f5a1977fb12d395a3414cd165:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'MSE'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'MSE'};


}


}
# S0b2cef6f5a1977fb12d395a3414cd165


}
unshift (@{$self->{char}}, $ch);


}
# Sa2e3d52421d38edc67f2c6dbcb466dfa


}
unshift (@{$self->{char}}, $ch);


}
# Sdac3cc8cbc3f856c13aa9dedbf1660e0


}
elsif ($ch == -1) 
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'#EOF'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CharData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'#EOF'};


}


}
push (@dch, $ch);
redo Sb6eb11560b64af561256705703c93caf;


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_CDATASectionContent ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};
my @dch;

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 93) 
{

push (@ch, $ch);

Sdac3cc8cbc3f856c13aa9dedbf1660e0:
{

my $ch = $self->_shift_char;
if ($ch == 93) 
{

push (@ch, $ch);

Sa2e3d52421d38edc67f2c6dbcb466dfa:
{

my $ch = $self->_shift_char;
if ($ch == 62) 
{


S0b2cef6f5a1977fb12d395a3414cd165:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'MSE'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'MSE'};


}


}
# S0b2cef6f5a1977fb12d395a3414cd165


}
unshift (@{$self->{char}}, $ch);


}
# Sa2e3d52421d38edc67f2c6dbcb466dfa


}
unshift (@{$self->{char}}, $ch);


}
# Sdac3cc8cbc3f856c13aa9dedbf1660e0


}
elsif ($ch == -1) 
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'#EOF'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'CData',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'#EOF'};


}


}
push (@dch, $ch);
redo Sb6eb11560b64af561256705703c93caf;


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_EntityReference ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif ($ch == 59) 
{


Sfa66fb85d08952fdd55957fec2c35ec8:
{

return {'location',
$location,
'type',
'REFC'};


}
# Sfa66fb85d08952fdd55957fec2c35ec8


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_NumericCharacterReference ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ((48 <= $ch) and ($ch <= 57)) 
{

push (@ch, $ch);

S92f5fbf288880b6b74d5023c13167729:
{

my $ch = $self->_shift_char;
if ((48 <= $ch) and ($ch <= 57)) 
{

push (@ch, $ch);
redo S92f5fbf288880b6b74d5023c13167729;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'NUMBER',
'value',
$token_val};


}
# S92f5fbf288880b6b74d5023c13167729


}
elsif ($ch == 59) 
{


Sfa66fb85d08952fdd55957fec2c35ec8:
{

return {'location',
$location,
'type',
'REFC'};


}
# Sfa66fb85d08952fdd55957fec2c35ec8


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_HexadecimalCharacterReference ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((48 <= $ch) and ($ch <= 57)) or ((65 <= $ch) and ($ch <= 70)) or ((97 <= $ch) and ($ch <= 102))) 
{

push (@ch, $ch);

S650d2503a3ce9f7edd898e0cc5a89baf:
{

my $ch = $self->_shift_char;
if (((48 <= $ch) and ($ch <= 57)) or ((65 <= $ch) and ($ch <= 70)) or ((97 <= $ch) and ($ch <= 102))) 
{

push (@ch, $ch);
redo S650d2503a3ce9f7edd898e0cc5a89baf;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Hex',
'value',
$token_val};


}
# S650d2503a3ce9f7edd898e0cc5a89baf


}
elsif ($ch == 59) 
{


Sfa66fb85d08952fdd55957fec2c35ec8:
{

return {'location',
$location,
'type',
'REFC'};


}
# Sfa66fb85d08952fdd55957fec2c35ec8


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_XMLDeclaration ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 61) 
{


S70db9124e0bdfa0450c974d2118dd414:
{

return {'location',
$location,
'type',
'VI'};


}
# S70db9124e0bdfa0450c974d2118dd414


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif ($ch == 63) 
{


S3f2b37951fb42f92709cec7637cfa845:
{

return {'location',
$location,
'type',
'PIC1'};


}
# S3f2b37951fb42f92709cec7637cfa845


}
elsif ($ch == 62) 
{


Sb1795473a2cb921f302fe9c2dffedf12:
{

return {'location',
$location,
'type',
'PIC2'};


}
# Sb1795473a2cb921f302fe9c2dffedf12


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_XMLDeclarationOrPI ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{


S38e7440f50e38d634f3f3281fd8f8a34:
{

shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@ch, $ch);


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'NameChar',
'value',
$token_val};


}
# S38e7440f50e38d634f3f3281fd8f8a34


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_StartTag ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 61) 
{


S70db9124e0bdfa0450c974d2118dd414:
{

return {'location',
$location,
'type',
'VI'};


}
# S70db9124e0bdfa0450c974d2118dd414


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif ($ch == 62) 
{


S521868b7ae916fd1d42e2b9a383bf4a7:
{

return {'location',
$location,
'type',
'TAGC'};


}
# S521868b7ae916fd1d42e2b9a383bf4a7


}
elsif ($ch == 47) 
{


S010ab7faf7e86785b93954432e3b039a:
{

return {'location',
$location,
'type',
'NESTC'};


}
# S010ab7faf7e86785b93954432e3b039a


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_EndTag ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 62) 
{


S521868b7ae916fd1d42e2b9a383bf4a7:
{

return {'location',
$location,
'type',
'TAGC'};


}
# S521868b7ae916fd1d42e2b9a383bf4a7


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_AttributeValueLiteral ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 38) 
{

push (@ch, $ch);

Sb38bd1b50570b4f4ed86d6f1e11d017d:
{

my $ch = $self->_shift_char;
if ($ch == 35) 
{

push (@ch, $ch);

S1c2bac16e184ab0fa17b03ae05b56d1e:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{


S9d912bd81aee720926e2f5eeadae8441:
{

return {'location',
$location,
'type',
'HCRO'};


}
# S9d912bd81aee720926e2f5eeadae8441
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'CRO'};


}
# S1c2bac16e184ab0fa17b03ae05b56d1e
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'ERO'};


}
# Sb38bd1b50570b4f4ed86d6f1e11d017d


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif (((0 <= $ch) and ($ch <= 33)) or ((35 <= $ch) and ($ch <= 37)) or ((39 <= $ch) and ($ch <= 59)) or 61 <= $ch) 
{

push (@ch, $ch);

Sb22cc0b95384888814314289dbc0932c:
{

my $ch = $self->_shift_char;
if (((0 <= $ch) and ($ch <= 33)) or ((35 <= $ch) and ($ch <= 37)) or ((39 <= $ch) and ($ch <= 59)) or 61 <= $ch) 
{

push (@ch, $ch);
redo Sb22cc0b95384888814314289dbc0932c;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
# Sb22cc0b95384888814314289dbc0932c


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_AttributeValueLiteralA ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 38) 
{

push (@ch, $ch);

Sb38bd1b50570b4f4ed86d6f1e11d017d:
{

my $ch = $self->_shift_char;
if ($ch == 35) 
{

push (@ch, $ch);

S1c2bac16e184ab0fa17b03ae05b56d1e:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{


S9d912bd81aee720926e2f5eeadae8441:
{

return {'location',
$location,
'type',
'HCRO'};


}
# S9d912bd81aee720926e2f5eeadae8441
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'CRO'};


}
# S1c2bac16e184ab0fa17b03ae05b56d1e
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'ERO'};


}
# Sb38bd1b50570b4f4ed86d6f1e11d017d


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif (((0 <= $ch) and ($ch <= 37)) or ((40 <= $ch) and ($ch <= 59)) or 61 <= $ch) 
{

push (@ch, $ch);

Sb22cc0b95384888814314289dbc0932c:
{

my $ch = $self->_shift_char;
if (((0 <= $ch) and ($ch <= 37)) or ((40 <= $ch) and ($ch <= 59)) or 61 <= $ch) 
{

push (@ch, $ch);
redo Sb22cc0b95384888814314289dbc0932c;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
# Sb22cc0b95384888814314289dbc0932c


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_AttributeValueLiteralE ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 38) 
{

push (@ch, $ch);

Sb38bd1b50570b4f4ed86d6f1e11d017d:
{

my $ch = $self->_shift_char;
if ($ch == 35) 
{

push (@ch, $ch);

S1c2bac16e184ab0fa17b03ae05b56d1e:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{


S9d912bd81aee720926e2f5eeadae8441:
{

return {'location',
$location,
'type',
'HCRO'};


}
# S9d912bd81aee720926e2f5eeadae8441
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'CRO'};


}
# S1c2bac16e184ab0fa17b03ae05b56d1e
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'ERO'};


}
# Sb38bd1b50570b4f4ed86d6f1e11d017d


}
elsif (((0 <= $ch) and ($ch <= 37)) or ((39 <= $ch) and ($ch <= 59)) or 61 <= $ch) 
{

push (@ch, $ch);

Sb22cc0b95384888814314289dbc0932c:
{

my $ch = $self->_shift_char;
if (((0 <= $ch) and ($ch <= 37)) or ((39 <= $ch) and ($ch <= 59)) or 61 <= $ch) 
{

push (@ch, $ch);
redo Sb22cc0b95384888814314289dbc0932c;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
# Sb22cc0b95384888814314289dbc0932c


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_EntityValue ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 37) 
{


Sa6377e01c8d0b0672f95cfc349bab3d2:
{

return {'location',
$location,
'type',
'PERO'};


}
# Sa6377e01c8d0b0672f95cfc349bab3d2


}
elsif ($ch == 38) 
{

push (@ch, $ch);

Sb38bd1b50570b4f4ed86d6f1e11d017d:
{

my $ch = $self->_shift_char;
if ($ch == 35) 
{

push (@ch, $ch);

S1c2bac16e184ab0fa17b03ae05b56d1e:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{


S9d912bd81aee720926e2f5eeadae8441:
{

return {'location',
$location,
'type',
'HCRO'};


}
# S9d912bd81aee720926e2f5eeadae8441
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'CRO'};


}
# S1c2bac16e184ab0fa17b03ae05b56d1e
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'ERO'};


}
# Sb38bd1b50570b4f4ed86d6f1e11d017d


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif (((0 <= $ch) and ($ch <= 33)) or ((35 <= $ch) and ($ch <= 36)) or 39 <= $ch) 
{

push (@ch, $ch);

Sb22cc0b95384888814314289dbc0932c:
{

my $ch = $self->_shift_char;
if (((0 <= $ch) and ($ch <= 33)) or ((35 <= $ch) and ($ch <= 36)) or 39 <= $ch) 
{

push (@ch, $ch);
redo Sb22cc0b95384888814314289dbc0932c;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
# Sb22cc0b95384888814314289dbc0932c


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_EntityValueA ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 37) 
{


Sa6377e01c8d0b0672f95cfc349bab3d2:
{

return {'location',
$location,
'type',
'PERO'};


}
# Sa6377e01c8d0b0672f95cfc349bab3d2


}
elsif ($ch == 38) 
{

push (@ch, $ch);

Sb38bd1b50570b4f4ed86d6f1e11d017d:
{

my $ch = $self->_shift_char;
if ($ch == 35) 
{

push (@ch, $ch);

S1c2bac16e184ab0fa17b03ae05b56d1e:
{

my $ch = $self->_shift_char;
if ($ch == 120) 
{


S9d912bd81aee720926e2f5eeadae8441:
{

return {'location',
$location,
'type',
'HCRO'};


}
# S9d912bd81aee720926e2f5eeadae8441
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'CRO'};


}
# S1c2bac16e184ab0fa17b03ae05b56d1e
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'ERO'};


}
# Sb38bd1b50570b4f4ed86d6f1e11d017d


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif (((0 <= $ch) and ($ch <= 36)) or 40 <= $ch) 
{

push (@ch, $ch);

Sb22cc0b95384888814314289dbc0932c:
{

my $ch = $self->_shift_char;
if (((0 <= $ch) and ($ch <= 36)) or 40 <= $ch) 
{

push (@ch, $ch);
redo Sb22cc0b95384888814314289dbc0932c;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
# Sb22cc0b95384888814314289dbc0932c


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_SystemLiteral ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};
my @dch;

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'LIT'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'LIT'};


}


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif ($ch == -1) 
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'#EOF'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'#EOF'};


}


}
push (@dch, $ch);
redo Sb6eb11560b64af561256705703c93caf;


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_SystemLiteralA ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};
my @dch;

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'LITA'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'LITA'};


}


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif ($ch == -1) 
{

if (@dch) 
{

unshift (@{$self->{token}}, {'location',
$location,
'location_d',
0 + @dch,
'type',
'#EOF'});
my $token_val;
while (@dch) 
{

$token_val .= chr (shift (@dch));


}
return {'location',
$location,
'type',
'STRING',
'value',
$token_val};


}
else 
{

return {'location',
$location,
'type',
'#EOF'};


}


}
push (@dch, $ch);
redo Sb6eb11560b64af561256705703c93caf;


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_DTD ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 60) 
{

push (@ch, $ch);

S51e3803c388b7a5cfbe562892a33cbfe:
{

my $ch = $self->_shift_char;
if ($ch == 63) 
{


S14958ebece080f97ea7332cf9e83907c:
{

return {'location',
$location,
'type',
'PIO'};


}
# S14958ebece080f97ea7332cf9e83907c


}
elsif ($ch == 33) 
{

push (@ch, $ch);

S554a9d323fdecd91c1fbb865551b5fad:
{

my $ch = $self->_shift_char;
if ($ch == 91) 
{


S5f013d0d307ecd60ec6a7f00805cb6ba:
{

return {'location',
$location,
'type',
'CSO'};


}
# S5f013d0d307ecd60ec6a7f00805cb6ba
unshift (@{$self->{char}}, $ch);


}
elsif ($ch == 45) 
{

push (@ch, $ch);

S63f599bea4ea7ca8944683e740af956a:
{

my $ch = $self->_shift_char;
if ($ch == 45) 
{


S871e1185aa8ab8ce10a709a58cdd4d25:
{

return {'location',
$location,
'type',
'CDO'};


}
# S871e1185aa8ab8ce10a709a58cdd4d25


}
unshift (@{$self->{char}}, $ch);


}
# S63f599bea4ea7ca8944683e740af956a
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'MDO'};


}
# S554a9d323fdecd91c1fbb865551b5fad


}
unshift (@{$self->{char}}, $ch);


}
# S51e3803c388b7a5cfbe562892a33cbfe


}
elsif ($ch == 37) 
{


Sa6377e01c8d0b0672f95cfc349bab3d2:
{

return {'location',
$location,
'type',
'PERO'};


}
# Sa6377e01c8d0b0672f95cfc349bab3d2


}
elsif ($ch == 93) 
{


Sdb93dc4cb9d05824d8457d41edaaa7ae:
{

return {'location',
$location,
'type',
'DSC'};


}
# Sdb93dc4cb9d05824d8457d41edaaa7ae


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_MarkupDeclaration ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 62) 
{


Sa177a95ccc162790897bdad08100f50c:
{

return {'location',
$location,
'type',
'MDC'};


}
# Sa177a95ccc162790897bdad08100f50c


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif ($ch == 37) 
{


Sa6377e01c8d0b0672f95cfc349bab3d2:
{

return {'location',
$location,
'type',
'PERO'};


}
# Sa6377e01c8d0b0672f95cfc349bab3d2


}
elsif ($ch == 91) 
{


S9917001261a0d1f28d35a0b913d9e550:
{

return {'location',
$location,
'type',
'DSO'};


}
# S9917001261a0d1f28d35a0b913d9e550


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_ElementDeclaration ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 62) 
{


Sa177a95ccc162790897bdad08100f50c:
{

return {'location',
$location,
'type',
'MDC'};


}
# Sa177a95ccc162790897bdad08100f50c


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif ($ch == 37) 
{


Sa6377e01c8d0b0672f95cfc349bab3d2:
{

return {'location',
$location,
'type',
'PERO'};


}
# Sa6377e01c8d0b0672f95cfc349bab3d2


}
elsif ($ch == 91) 
{


S9917001261a0d1f28d35a0b913d9e550:
{

return {'location',
$location,
'type',
'DSO'};


}
# S9917001261a0d1f28d35a0b913d9e550


}
elsif ($ch == 40) 
{


S48c88a5fba8ec21c0a5828587ce0988a:
{

return {'location',
$location,
'type',
'MGO'};


}
# S48c88a5fba8ec21c0a5828587ce0988a


}
elsif ($ch == 41) 
{


Sf6b66847728bb2a4a72802800d128fe2:
{

return {'location',
$location,
'type',
'MGC'};


}
# Sf6b66847728bb2a4a72802800d128fe2


}
elsif ($ch == 35) 
{


S10a217c119dc72dd8374475e29d73cf9:
{

return {'location',
$location,
'type',
'RNI'};


}
# S10a217c119dc72dd8374475e29d73cf9


}
elsif ($ch == 63) 
{


Sc0998eb34d4f903d97ed554dfe36bc37:
{

return {'location',
$location,
'type',
'OPT'};


}
# Sc0998eb34d4f903d97ed554dfe36bc37


}
elsif ($ch == 42) 
{


S825d66f2fae7db0f1b66cf32b7fc192f:
{

return {'location',
$location,
'type',
'REP'};


}
# S825d66f2fae7db0f1b66cf32b7fc192f


}
elsif ($ch == 43) 
{


S0ef22a72225a71c6f71c7532a111e282:
{

return {'location',
$location,
'type',
'PLUS'};


}
# S0ef22a72225a71c6f71c7532a111e282


}
elsif ($ch == 124) 
{


S27f2d0624520fec4cefc22fb98ad995a:
{

return {'location',
$location,
'type',
'OR'};


}
# S27f2d0624520fec4cefc22fb98ad995a


}
elsif ($ch == 44) 
{


S0f0b745760d76725999bc7a02e1d2552:
{

return {'location',
$location,
'type',
'SEQ'};


}
# S0f0b745760d76725999bc7a02e1d2552


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_AttlistDeclaration ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (($ch == 58) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 767)) or ((880 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S5d9945385cfb98decadc1ff9f45fb53a:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

Sf8426584cb276d6b438fb92fa0c1ed24:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo Sf8426584cb276d6b438fb92fa0c1ed24;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# Sf8426584cb276d6b438fb92fa0c1ed24
unshift (@{$self->{char}}, $ch);


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Name',
'value',
$token_val};


}
# S5d9945385cfb98decadc1ff9f45fb53a


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 62) 
{


Sa177a95ccc162790897bdad08100f50c:
{

return {'location',
$location,
'type',
'MDC'};


}
# Sa177a95ccc162790897bdad08100f50c


}
elsif ($ch == 34) 
{


S597a4b3cb839e9d8afdcb7ce0a6112c3:
{

return {'location',
$location,
'type',
'LIT'};


}
# S597a4b3cb839e9d8afdcb7ce0a6112c3


}
elsif ($ch == 39) 
{


S411be239a732781cd6b18f690de0a2ab:
{

return {'location',
$location,
'type',
'LITA'};


}
# S411be239a732781cd6b18f690de0a2ab


}
elsif ($ch == 37) 
{


Sa6377e01c8d0b0672f95cfc349bab3d2:
{

return {'location',
$location,
'type',
'PERO'};


}
# Sa6377e01c8d0b0672f95cfc349bab3d2


}
elsif ($ch == 91) 
{


S9917001261a0d1f28d35a0b913d9e550:
{

return {'location',
$location,
'type',
'DSO'};


}
# S9917001261a0d1f28d35a0b913d9e550


}
elsif ($ch == 40) 
{


S6c9bf2ecd88c6b092018702e4ec46a52:
{

return {'location',
$location,
'type',
'EGO'};


}
# S6c9bf2ecd88c6b092018702e4ec46a52


}
elsif ($ch == 41) 
{


S22fc48c7c0ddea36f0f5feae9b02f512:
{

return {'location',
$location,
'type',
'EGC'};


}
# S22fc48c7c0ddea36f0f5feae9b02f512


}
elsif ($ch == 124) 
{


S27f2d0624520fec4cefc22fb98ad995a:
{

return {'location',
$location,
'type',
'OR'};


}
# S27f2d0624520fec4cefc22fb98ad995a


}
elsif ($ch == 35) 
{


S10a217c119dc72dd8374475e29d73cf9:
{

return {'location',
$location,
'type',
'RNI'};


}
# S10a217c119dc72dd8374475e29d73cf9


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _scan_Enumeration ($) {
my $self = shift ();
if (@{$self->{token}}) 
{

return shift (@{$self->{token}});


}
my $ch = -2;
my $location = {%{$self->{location}},
                 char_d => 0+@{$self->{char}}};

Sb6eb11560b64af561256705703c93caf:
{

my @ch;
push (@ch, $ch);
my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);

S848f71a51122f9823d93f03a83b47d6f:
{

my $ch = $self->_shift_char;
if (((45 <= $ch) and ($ch <= 46)) or ((48 <= $ch) and ($ch <= 58)) or ((65 <= $ch) and ($ch <= 90)) or ($ch == 95) or ((97 <= $ch) and ($ch <= 122)) or ($ch == 183) or ((192 <= $ch) and ($ch <= 214)) or ((216 <= $ch) and ($ch <= 246)) or ((248 <= $ch) and ($ch <= 893)) or ((895 <= $ch) and ($ch <= 8191)) or ((8204 <= $ch) and ($ch <= 8205)) or ((8255 <= $ch) and ($ch <= 8256)) or ((8304 <= $ch) and ($ch <= 8591)) or ((11264 <= $ch) and ($ch <= 12271)) or ((12289 <= $ch) and ($ch <= 55295)) or ((63744 <= $ch) and ($ch <= 64975)) or ((65008 <= $ch) and ($ch <= 65533)) or ((65536 <= $ch) and ($ch <= 983039))) 
{

push (@ch, $ch);
redo S848f71a51122f9823d93f03a83b47d6f;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
shift (@ch);
my $token_val = '';
if ($ch > -1) 
{

push (@{$self->{char}}, pop (@ch));


}
while (@ch) 
{

$token_val .= chr (shift (@ch));


}
return {'location',
$location,
'type',
'Nmtoken',
'value',
$token_val};


}
# S848f71a51122f9823d93f03a83b47d6f


}
elsif (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);

S13755a4dff473160e9488f0f50b1b638:
{

my $ch = $self->_shift_char;
if (((9 <= $ch) and ($ch <= 10)) or ($ch == 13) or ($ch == 32)) 
{

push (@ch, $ch);
redo S13755a4dff473160e9488f0f50b1b638;


}
else 
{

unshift (@{$self->{char}}, $ch);
$ch = -2;


}
return {'location',
$location,
'type',
'S'};


}
# S13755a4dff473160e9488f0f50b1b638


}
elsif ($ch == 41) 
{


S22fc48c7c0ddea36f0f5feae9b02f512:
{

return {'location',
$location,
'type',
'EGC'};


}
# S22fc48c7c0ddea36f0f5feae9b02f512


}
elsif ($ch == 124) 
{


S27f2d0624520fec4cefc22fb98ad995a:
{

return {'location',
$location,
'type',
'OR'};


}
# S27f2d0624520fec4cefc22fb98ad995a


}
elsif ($ch == -1) 
{

return {'location',
$location,
'type',
'#EOF'};


}
return {'location',
$location,
'type',
'#INVALID',
'value',
chr ($ch)};


}
# Sb6eb11560b64af561256705703c93caf
}
sub _parse_AttributeValueLiteralE_ ($$$) {
my ($self, $parent, $vals) = @_;
my $token;
$token = $self->{scanner}->($self);

MATCH_1:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      $parent->
manakai_append_text
 (\($token->{value}));
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $parent = $parent;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $char = chr $num;
      $parent->
manakai_append_text
 (\$char);
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $parent = $parent;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $char = chr $token->{value};
      $parent->
manakai_append_text
 (\$char);
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $parent = $parent;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{



      $parent->
manakai_append_text
 ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{



      $parent->
manakai_append_text
 ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{



      $parent->
manakai_append_text
 ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{



      $parent->
manakai_append_text
 ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{



      $parent->
manakai_append_text
 ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;

      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      $parent->
append_child
 ($er);
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif (($token->{type} eq '#INVALID') and ($token->{value} eq '<')) 
{


{


      my 
$location;
      

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
      my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-lt-in-attribute-values', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
      unless ($continue) {
        

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
      }

      $parent->
manakai_append_text
 ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
else 
{

last MATCH_1;


}
redo MATCH_1;


}
# MATCH_1
unshift (@{$self->{token}}, $token);
}
sub _parse_InternalGeneralParsedEntity ($$) {
my ($self, $ent) = @_;
my $token;
$self->{scanner} = $self->can ('_scan_ElementContent');
my $ns;

{



    $ns = {
      xml => 
'http://www.w3.org/XML/1998/namespace'
,
      xmlns => 
'http://www.w3.org/2000/xmlns/'
,
    };
  


}

{

my $parent = $ent;
my $ns = $ns;
my $doc;

{



    $doc = $self->{doc};
  


}
$token = $self->{scanner}->($self);

MATCH_2:
{

if ($token->{type} eq 'CharData') 
{


{



      $parent->
manakai_append_text
 (\($token->{value}));
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'STAGO') 
{

unshift (@{$self->{token}}, $token);
$self->_parse_Element_ ($doc, $parent, $ns);
$token = $self->{scanner}->($self);
if ($token->{type} eq 'TAGC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $parent = $parent;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $parent->
manakai_append_text
 (chr $num);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $parent = $parent;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $parent->
manakai_append_text
 (chr $token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{

$self->_parse__GeneralEntityReferenceEC ($doc, $parent, $ns);
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'CDO') 
{


{

my $doc = $doc;
my $parent = $parent;
$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{


      my 
$com = $doc->
create_comment
 ($token->{value});
      $parent->
append_child
 ($com);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


      my 
$com = $doc->
create_comment
 ('');
      $parent->
append_child
 ($com);
    


}


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CDSO') 
{


{

my $doc = $doc;
my $parent = $parent;
$self->{scanner} = $self->can ('_scan_CDATASectionContent');
my $cdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'CData') 
{


{



      $cdata = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $cdata = '';
    


}


}

{


    my 
$cdsect = $doc->
create_cdata_section

                         ($cdata);
    $parent->
append_child
 ($cdsect);
  


}


}
if ($token->{type} eq 'MSE') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $parent = $parent;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_2;


}
redo MATCH_2;


}
# MATCH_2


}
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
unshift (@{$self->{token}}, $token);
}
sub _parse_DocumentEntity ($) {
my ($self) = @_;
my $token;
$self->{scanner} = $self->can ('_scan_DocumentStart');
my $doc;

{



    $doc = $self->{doc};
  


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'XDO') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclarationOrPI');

{



      $self->{entity}->[-1]->{no_xml11_eol} = 
1
;
    


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{


{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'version')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'VI') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
my $ver;
my $bad_token;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



          $ver = $token->{value};
          $bad_token = $token;
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



          $ver = $token->{value};
          $bad_token = $token;
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{


      unless 
($ver eq '1.0' or $ver eq '1.1') {
        my $location;
        

{

my 
$__d = $bad_token->{type} ne '#EOF'
            ? $bad_token->{location}->{char_d}
            : 0;
$__d -= $bad_token->{location_d} if $bad_token->{location_d};
$location = {
  utf32_offset => $bad_token->{location}->{pos} - $__d,
  line_number => $bad_token->{location}->{line},
  column_number => $bad_token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-unsupported-xml-version', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $bad_token, 'http://www.w3.org/2001/04/infoset#version' => $ver, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $self->{doc};

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
$ver = '1.0';
      }
      $self->{doc}->
xml_version
 ($ver);
      $self->{xml_version} = $ver;
    


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if (($token->{type} eq 'Name') and ($token->{value} eq 'encoding')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'VI') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
my $ver;
my $bad_token;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



          $ver = $token->{value};
          $bad_token = $token;
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



          $ver = $token->{value};
          $bad_token = $token;
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{


      unless 
($ver =~ /\A[A-Za-z][A-Za-z0-9._-]*\z/) {
        my $location;
        

{

my 
$__d = $bad_token->{type} ne '#EOF'
            ? $bad_token->{location}->{char_d}
            : 0;
$__d -= $bad_token->{location_d} if $bad_token->{location_d};
$location = {
  utf32_offset => $bad_token->{location}->{pos} - $__d,
  line_number => $bad_token->{location}->{line},
  column_number => $bad_token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $ver, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-malformed-enc-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $bad_token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $self->{doc};

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $self->{doc}->
xml_encoding
 ($ver);
    


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
if (($token->{type} eq 'Name') and ($token->{value} eq 'standalone')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'VI') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
my $ver;
my $bad_token;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



          $ver = $token->{value};
          $bad_token = $token;
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



          $ver = $token->{value};
          $bad_token = $token;
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_XMLDeclaration');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{


      unless 
($ver eq 'yes' or $ver eq 'no') {
        my $location;
        

{

my 
$__d = $bad_token->{type} ne '#EOF'
            ? $bad_token->{location}->{char_d}
            : 0;
$__d -= $bad_token->{location_d} if $bad_token->{location_d};
$location = {
  utf32_offset => $bad_token->{location}->{pos} - $__d,
  line_number => $bad_token->{location}->{line},
  column_number => $bad_token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $ver, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-malformed-xml-standalone', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $bad_token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $self->{doc};

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      if ($ver eq 'yes') {
        $self->{doc}->
xml_standalone
 (
1
);
        $self->{standalone} = 
1
;
      }
    


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
if ($token->{type} eq 'PIC1') 
{


{



      $self->{entity}->[-1]->{no_xml11_eol} = 
0
;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $self->{entity}->[-1]->{no_xml11_eol} = 
0
;
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'PIC2') 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'NameChar') 
{

my $target_token;

{



        $target_token = $token;
        $target_token->{value} = 'xml'.$target_token->{value};
        $self->{entity}->[-1]->{no_xml11_eol} = 
0
;
      


}
$self->{scanner} = $self->can ('_scan_PINmtoken');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Nmtoken') 
{


{



          $target_token->{value} .= $token->{value};
        


}
$self->{scanner} = $self->can ('_scan_PIName');
$token = $self->{scanner}->($self);


}

{



        $target_token->{type} = 'Name';
        $target_token->{location_d} += 3; # 'xml'
        unshift @{$self->{token}}, $token;
        $token = $target_token;
      


}

{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{



        $self->{entity}->[-1]->{no_xml11_eol} = 
0
;
      


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');


}

MATCH_3:
{

if ($token->{type} eq 'CDO') 
{


{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{


      my 
$com = $doc->
create_comment
 ($token->{value});
      $parent->
append_child
 ($com);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


      my 
$com = $doc->
create_comment
 ('');
      $parent->
append_child
 ($com);
    


}


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentProlog');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{

last MATCH_3;


}
redo MATCH_3;


}
# MATCH_3
if ($token->{type} eq 'MDO') 
{


{

my $doc = $doc;
$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'DOCTYPE')) 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $name;
if ($token->{type} eq 'Name') 
{


{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (($self->{xml_version} eq '1.0' and
          not 
($token->{value} =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*(?::\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*)?\z/)
) or
         ($self->{xml_version} eq '1.1' and
          not 
($token->{value} =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*(?::\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*)?\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      $name = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $node;
my $decl;

{



    $node = $self->{doc}->
create_document_type_definition

                             ($name);
    $decl = $self->{dtdecl} = $node->
get_feature

                                       (
'http://suika.fam.cx/www/2006/feature/XDoctypeDeclaration'
, '3.0');
  


}
my $has_extid;
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'PUBLIC')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $decl;
my $pubid;
my $pubid_token;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



        $pubid = $token->{value};
        $pubid_token = $token;
      


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



        $pubid = $token->{value};
        $pubid_token = $token;
      


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($pubid_token) 
{


{


      if 
($pubid =~ m{[^\x20\x0D\x0Aa-zA-Z0-9'()+,./:=?;!*#\@\$_%-]}s) {
        my $location;
        

{

my 
$__d = $pubid_token->{type} ne '#EOF'
            ? $pubid_token->{location}->{char_d}
            : 0;
$__d -= $pubid_token->{location_d} if $pubid_token->{location_d};
$location = {
  utf32_offset => $pubid_token->{location}->{pos} - $__d,
  line_number => $pubid_token->{location}->{line},
  column_number => $pubid_token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                              ## Should this be other (new) error type?
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }

      ## NOTE: U+0009 is syntactically illegal.
      $pubid =~ s/[\x09\x0A\x0D\x20]+/\x20/gs;
      $pubid =~ s/\A\x20//s;
      $pubid =~ s/\x20\z//s;
             ## NOTE: Bare attribute name is written.
      $decl->public_id ($pubid);
    


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $decl;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{



        $self->{has_xref} = 
1
;
        $has_extid = 
1
;
      


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'SYSTEM')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $decl;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{



        $self->{has_xref} = 
1
;
        $has_extid = 
1
;
      


}


}


}

{



    $self->{dtdef} = $node;
    $self->{doc}->
append_child
 ($node);
    $self->{doc_cfg}->
set_parameter

                        ('schema-type' => 
'http://www.w3.org/TR/REC-xml'
);
    ## ISSUE: Should default schema language information be
    ##        preserved by some other flag?
  


}
if ($token->{type} eq 'DSO') 
{


{

my $doc = $doc;
my $doctype = $node;
$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);

MATCH_4:
{

if ($token->{type} eq 'MDO') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'ELEMENT')) 
{


{

my $doc = $doc;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
$self->{scanner} = $self->can ('_scan_ElementDeclaration');
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'MGO') 
{


{

my $doc = $doc;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'Name') 
{

unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
elsif ($token->{type} eq 'MDO') 
{

unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
elsif ($token->{type} eq 'PCDATA') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

MATCH_5:
{

if ($token->{type} eq 'OR') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{

last MATCH_5;


}
redo MATCH_5;


}
# MATCH_5
if ($token->{type} eq 'MGC') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
else 
{


;
}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'EMPTY')) 
{

$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'ANY')) 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'ATTLIST')) 
{


{

my $doc = $doc;
my $doctype = $doctype;
$self->{scanner} = $self->can ('_scan_AttlistDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $name;
if ($token->{type} eq 'Name') 
{


{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (($self->{xml_version} eq '1.0' and
          not 
($token->{value} =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*(?::\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*)?\z/)
) or
         ($self->{xml_version} eq '1.1' and
          not 
($token->{value} =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*(?::\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*)?\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      $name = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


 $name = '#ILLEGAL' 


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $docxd;
my $et;

{


    $et = $doctype->
get_element_type_definition_node
 ($name);
    unless ($et) {
      $docxd = $doc->
get_feature
 (
'http://suika.fam.cx/www/2006/feature/XDoctype'
, '3.0');
      $et = $docxd->
create_element_type_definition

                      ($name);
      $doctype->
set_element_type_definition_node
 ($et)
        unless $name eq '#ILLEGAL';
    }


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
  

MATCH_6:
{

if ($token->{type} eq 'Name') 
{

my $at;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (($self->{xml_version} eq '1.0' and
          not 
($token->{value} =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*(?::\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*)?\z/)
) or
         ($self->{xml_version} eq '1.1' and
          not 
($token->{value} =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*(?::\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*)?\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      $docxd ||= $doc->
get_feature

                         (
'http://suika.fam.cx/www/2006/feature/XDoctype'
, '3.0');
      $at = $docxd->
create_attribute_definition
 ($token->{value});
      if (exists $et->
attribute_definitions
->{$token->{value}}) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-attribute-definition-ignored', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }            
      } elsif ($self->{dont_process} and not $self->{standalone}) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-attribute-definition-not-processed', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }            
      } else {
        $et->
set_attribute_definition_node
 ($at);
        $self->{attr}->{$name}->{$token->{value}} = $at;
      }
    


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if (($token->{type} eq 'Name') and ($token->{value} eq 'NOTATION')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $kwd;

{



        $at->
declared_type
 (
9
);
        $kwd = $at->
allowed_tokens
;
      


}
if ($token->{type} eq 'EGO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{

my $has_content = 0;

MATCH_7:
{

if ($token->{type} eq 'Name') 
{

$has_content = 1;

{



            

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
            push @$kwd, $token->{value};
          


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{

if ($has_content == 0) 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'OR') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
redo MATCH_7;


}
else 
{

last MATCH_7;


}


}
# MATCH_7


}
if ($token->{type} eq 'EGC') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'Name') 
{

my $type;

{


        my 
$map = {
          CDATA => 
1
,
          ID => 
2
,
          IDREF => 
3
,
          IDREFS => 
4
,
          ENTITY => 
5
,
          ENTITIES => 
6
,
          NMTOKEN => 
7
,
          NMTOKENS => 
8
,
        };
        if ($map->{$token->{value}}) {
          $at->
declared_type
 ($map->{$token->{value}});
        } else {
          ## TODO: Exception
        }
      


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'EGO') 
{

$self->{scanner} = $self->can ('_scan_Enumeration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
my $kwd;

{



        $at->
declared_type
 (
10
);
        $kwd = $at->
allowed_tokens
;
      


}

{

my $has_content = 0;

MATCH_8:
{

if ($token->{type} eq 'Nmtoken') 
{

$has_content = 1;

{


          push 
@$kwd, $token->{value};
        


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{

if ($has_content == 0) 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'OR') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
redo MATCH_8;


}
else 
{

last MATCH_8;


}


}
# MATCH_8


}
if ($token->{type} eq 'EGC') 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'RNI') 
{

$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'REQUIRED')) 
{


{



          $at->
default_type
 (
2
);
        


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'IMPLIED')) 
{


{



          $at->
default_type
 (
3
);
        


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'FIXED')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



          $at->
default_type
 (
1
);
        


}
if ($token->{type} eq 'LIT') 
{

my $vals;

{



            $vals = {nodes => [], value => ''};
          


}

{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);

MATCH_9:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      my $text = $doc->
create_text_node
 ($token->{value});
      push @{$vals->{nodes}}, $text;
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                  (my $char = chr $num);
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                        (my $char = chr $token->{value});
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      push @{$vals->{nodes}}, $er;
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_9;


}
redo MATCH_9;


}
# MATCH_9


}

{


            for 
(@{$vals->{nodes}}) {
              $at->
append_child
 ($_);
            }
          


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

my $vals;

{



            $vals = {nodes => [], value => ''};
          


}

{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);

MATCH_10:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      my $text = $doc->
create_text_node
 ($token->{value});
      push @{$vals->{nodes}}, $text;
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                  (my $char = chr $num);
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                        (my $char = chr $token->{value});
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      push @{$vals->{nodes}}, $er;
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_10;


}
redo MATCH_10;


}
# MATCH_10


}

{


            for 
(@{$vals->{nodes}}) {
              $at->
append_child
 ($_);
            }
          


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LIT') 
{

my $vals;

{



        $at->
default_type
 (
4
);
        $vals = {nodes => [], value => ''};
      


}

{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);

MATCH_9:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      my $text = $doc->
create_text_node
 ($token->{value});
      push @{$vals->{nodes}}, $text;
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                  (my $char = chr $num);
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                        (my $char = chr $token->{value});
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      push @{$vals->{nodes}}, $er;
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_9;


}
redo MATCH_9;


}
# MATCH_9


}

{


        for 
(@{$vals->{nodes}}) {
          $at->
append_child
 ($_);
        }
      


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

my $vals;

{



        $at->
default_type
 (
4
);
        $vals = {nodes => [], value => ''};
      


}

{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);

MATCH_10:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      my $text = $doc->
create_text_node
 ($token->{value});
      push @{$vals->{nodes}}, $text;
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                  (my $char = chr $num);
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                        (my $char = chr $token->{value});
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      push @{$vals->{nodes}}, $er;
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_10;


}
redo MATCH_10;


}
# MATCH_10


}

{


        for 
(@{$vals->{nodes}}) {
          $at->
append_child
 ($_);
        }
      


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttlistDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);
redo MATCH_6;


}
else 
{

last MATCH_6;


}


}
# MATCH_6

if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'ENTITY')) 
{

{

my $doc = $doc;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $is_param_entity;
my $decl;

{



    $decl = {
      name => '#ILLEGAL',
      reptxt => \'',
      is_external_entity => 
0
,
      document_uri => $self->{location}->{document_uri},
      base_uri => $self->{location}->{base_uri},
    };
  


}
if ($token->{type} eq 'PERO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $is_param_entity = $decl->{is_param_entity} = 
1
;
    


}


}
if ($token->{type} eq 'Name') 
{


{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      $decl->{name} = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $node;

{



    $node =
    $decl->{node} = $self->{doc}->
create_general_entity

                                     ($decl->{name});
    ## TODO: Parameter entity...
  


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'LIT') 
{


{

my $decl = $decl;
$self->{scanner} = $self->can ('_scan_EntityValue');
my $vals;
my $reptxt;

{



    $vals = [];
    $reptxt = '';
  


}
$token = $self->{scanner}->($self);

MATCH_11:
{

if ($token->{type} eq 'STRING') 
{


{



      $reptxt .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PERO') 
{

$self->{scanner} = $self->can ('_scan_EntityReference');

{



      $self->{has_xref} = 
1
;
      $self->{dont_process} = 
1
;
    


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{



        

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pes-in-internal-subset', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValue');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValue');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      push @{$vals}, chr $num;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $reptxt .= $vals->[-1];
    


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValue');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValue');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      push @{$vals}, chr $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $reptxt .= $vals->[-1];
    


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValue');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValue');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      push @$vals, $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $reptxt .= '&' . $vals->[-1] . ';';
    


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValue');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValue');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_11;


}
redo MATCH_11;


}
# MATCH_11
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



    $decl->{reptxt} = \$reptxt;
    $decl->{has_replacement_text} = 
1
;
  


}


}


}
elsif ($token->{type} eq 'LITA') 
{


{

my $decl = $decl;
$self->{scanner} = $self->can ('_scan_EntityValueA');
my $vals;
my $reptxt;

{



    $vals = [];
    $reptxt = '';
  


}
$token = $self->{scanner}->($self);

MATCH_12:
{

if ($token->{type} eq 'STRING') 
{


{



      $reptxt .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PERO') 
{

$self->{scanner} = $self->can ('_scan_EntityReference');

{



      $self->{has_xref} = 
1
;
      $self->{dont_process} = 
1
;
    


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{



        

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pes-in-internal-subset', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      push @{$vals}, chr $num;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $reptxt .= $vals->[-1];
    


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      push @{$vals}, chr $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $reptxt .= $vals->[-1];
    


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      push @$vals, $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $reptxt .= '&' . $vals->[-1] . ';';
    


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_EntityValueA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_12;


}
redo MATCH_12;


}
# MATCH_12
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



    $decl->{reptxt} = \$reptxt;
    $decl->{has_replacement_text} = 
1
;
  


}


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'PUBLIC')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $node;
my $pubid;
my $pubid_token;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



        $pubid = $token->{value};
        $pubid_token = $token;
      


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



        $pubid = $token->{value};
        $pubid_token = $token;
      


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($pubid_token) 
{


{


      if 
($pubid =~ m{[^\x20\x0D\x0Aa-zA-Z0-9'()+,./:=?;!*#\@\$_%-]}s) {
        my $location;
        

{

my 
$__d = $pubid_token->{type} ne '#EOF'
            ? $pubid_token->{location}->{char_d}
            : 0;
$__d -= $pubid_token->{location_d} if $pubid_token->{location_d};
$location = {
  utf32_offset => $pubid_token->{location}->{pos} - $__d,
  line_number => $pubid_token->{location}->{line},
  column_number => $pubid_token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                              ## Should this be other (new) error type?
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }

      ## NOTE: U+0009 is syntactically illegal.
      $pubid =~ s/[\x09\x0A\x0D\x20]+/\x20/gs;
      $pubid =~ s/\A\x20//s;
      $pubid =~ s/\x20\z//s;
             ## NOTE: Bare attribute name is written.
      $decl->public_id ($pubid);
    


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $node;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $decl->{is_external_entity} = 
1
;
    


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'SYSTEM')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $node;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}

{



      $decl->{is_external_entity} = 
1
;
    


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'NDATA')) 
{

if ($is_param_entity) 
{


{


          my 
$location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        


}


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'Name') 
{


{



          

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
          $decl->{notation} = $token->{value};
          $decl->{node}->
notation_name
 ($token->{value});
        


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}


}

{


    if 
($self->{$decl->{is_param_entity} ? 'param_entity' : 'general_entity'}
             ->{$decl->{name}}) {
      ## Predefined entity
      if (not $decl->{is_param_entity} and
          {lt => 
1
, gt => 
1
, amp => 
1
,
           quot => 
1
, apos => 
1
}->{$decl->{name}}) {
        if ($decl->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $decl->{name}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-internal-predefined-entity', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }              
        } elsif (
          not ({gt => 
1
, apos => 
1
, quot => 
1
}->{$decl->{name}} and
               ${$decl->{reptxt}} eq {
                 gt => '>', apos => "'", quot => '"',
               }->{$decl->{name}}) and
          not (${$decl->{reptxt}} =~ /\A&#0*@{[{
                 lt => '60', gt => '62', amp => '38',
                 apos => '39', quot => '34',
               }->{$decl->{name}}]};\z/) and
          not (${$decl->{reptxt}} =~ /\A&#x0*(?:(?i)@{[{
                 lt => '3C', gt => '3E', amp => '26',
                 apos => '27', quot => '22',
               }->{$decl->{name}}]});\z/)
        ) {
          ## NOTE: See "SuikaWiki - Predefined Entities"
          ##       "http://suika.fam.cx/gate/2005/sw/%E5%AE%9A%E7%BE%A9%E6%B8%88%E5%AE%9F%E4%BD%93".
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $decl->{name}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-malformed-predefined-entity', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#replacement-text' => ${$decl->{reptxt}};

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }
        ${$self->{dtdecl}}->{{
          lt => 
'http://suika.fam.cx/~wakaba/archive/2004/dom/xdt#hasLtDeclaration'
,
          gt => 
'http://suika.fam.cx/~wakaba/archive/2004/dom/xdt#hasGtDeclaration'
,
          amp => 
'http://suika.fam.cx/~wakaba/archive/2004/dom/xdt#hasAmpDeclaration'
,
          apos => 
'http://suika.fam.cx/~wakaba/archive/2004/dom/xdt#hasAposDeclaration'
,
          quot => 
'http://suika.fam.cx/~wakaba/archive/2004/dom/xdt#hasQuotDeclaration'
,
        }->{$decl->{name}}} = 
1
;
      } else {  ## Dupulicating declaration
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $decl->{name}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-entity-declaration-ignored', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
    } elsif ($self->{dont_process} and not $self->{standalone}) {
      ## TODO: |standalone| and parameter entities??
      my $location;
      

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
      my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $decl->{name}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#warning-entity-declaration-not-processed', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
      unless ($continue) {
        

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
      }            
    } else {
      $self->{$decl->{is_param_entity} ? 'param_entity' : 'general_entity'}
           ->{$decl->{name}} = $decl;
      $self->{dtdef}->
set_general_entity_node
 ($decl->{node})
        unless $decl->{is_param_entity};
    }
  


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'NOTATION')) 
{


{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
my $name;
if ($token->{type} eq 'Name') 
{


{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      $name = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $name = '#INVALID';
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



    $decl = $self->{doc}->
create_notation
 ($name);
  


}
if (($token->{type} eq 'Name') and ($token->{value} eq 'PUBLIC')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $decl;
my $pubid;
my $pubid_token;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



        $pubid = $token->{value};
        $pubid_token = $token;
      


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



        $pubid = $token->{value};
        $pubid_token = $token;
      


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($pubid_token) 
{


{


      if 
($pubid =~ m{[^\x20\x0D\x0Aa-zA-Z0-9'()+,./:=?;!*#\@\$_%-]}s) {
        my $location;
        

{

my 
$__d = $pubid_token->{type} ne '#EOF'
            ? $pubid_token->{location}->{char_d}
            : 0;
$__d -= $pubid_token->{location_d} if $pubid_token->{location_d};
$location = {
  utf32_offset => $pubid_token->{location}->{pos} - $__d,
  line_number => $pubid_token->{location}->{line},
  column_number => $pubid_token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                              ## Should this be other (new) error type?
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }

      ## NOTE: U+0009 is syntactically illegal.
      $pubid =~ s/[\x09\x0A\x0D\x20]+/\x20/gs;
      $pubid =~ s/\A\x20//s;
      $pubid =~ s/\x20\z//s;
             ## NOTE: Bare attribute name is written.
      $decl->public_id ($pubid);
    


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}


}


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'SYSTEM')) 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{

my $decl = $decl;
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteral');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_SystemLiteralA');

{

my $decl = $decl;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{



      $decl->
system_id
 ($token->{value});
      $decl->
manakai_declaration_base_uri

               ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{


    if 
($self->{dtdef}->
get_notation_node
 ($name)) {
      ## Dupulication
      my $location;
      

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
      my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $name, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#vc-unique-notation-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
      unless ($continue) {
        

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
      }
    } else {
      $self->{dtdef}->
set_notation_node
 ($decl);
    }
  


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'CDO') 
{


{

$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $doctype = $doctype;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $doctype;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
      $pi->
manakai_base_uri

             ($self->{location}->{base_uri});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $doctype->
append_child
 ($pi);
  


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}


}
elsif ($token->{type} eq 'PERO') 
{

$self->{scanner} = $self->can ('_scan_EntityReference');

{



      $self->{has_xref} = 
1
;
      $self->{dont_process} = 
1
;
    


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_DTD');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DTD');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_4;


}
redo MATCH_4;


}
# MATCH_4


}
if ($token->{type} eq 'DSC') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}

{



    $self->{dont_process} = 
1 if 
$has_extid;
    $node->
manakai_set_read_only
 (
1
, 
1
);
  


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');


}

{



    $self->{doc}->
all_declarations_processed
 (
1
)
      unless $self->{dont_process};
  


}

MATCH_13:
{

if ($token->{type} eq 'CDO') 
{


{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{


      my 
$com = $doc->
create_comment
 ($token->{value});
      $parent->
append_child
 ($com);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


      my 
$com = $doc->
create_comment
 ('');
      $parent->
append_child
 ($com);
    


}


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentMisc');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{

last MATCH_13;


}
redo MATCH_13;


}
# MATCH_13
if ($token->{type} eq 'STAGO') 
{

unshift (@{$self->{token}}, $token);
$self->_parse_Element_ ($doc, $doc, undef);
$token = $self->{scanner}->($self);
if ($token->{type} eq 'TAGC') 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

MATCH_14:
{

if ($token->{type} eq 'CDO') 
{


{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{


      my 
$com = $doc->
create_comment
 ($token->{value});
      $parent->
append_child
 ($com);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


      my 
$com = $doc->
create_comment
 ('');
      $parent->
append_child
 ($com);
    


}


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $parent = $doc;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_DocumentEnd');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
else 
{

last MATCH_14;


}
redo MATCH_14;


}
# MATCH_14
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
unshift (@{$self->{token}}, $token);
}
sub _parse__ModelGroup ($$) {
my ($self, $doc) = @_;
my $token;

{

my $doc = $doc;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'MGO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'OR') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{

my $doc = $doc;
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'MGO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

MATCH_15:
{

if ($token->{type} eq 'OR') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{

my $doc = $doc;
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'MGO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{

last MATCH_15;


}
redo MATCH_15;


}
# MATCH_15


}
elsif ($token->{type} eq 'SEQ') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{

my $doc = $doc;
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'MGO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

MATCH_16:
{

if ($token->{type} eq 'SEQ') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}

{

my $doc = $doc;
if ($token->{type} eq 'Name') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'MGO') 
{

$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
unshift (@{$self->{token}}, $token);
$self->_parse__ModelGroup ($doc);
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'OPT') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'REP') 
{

$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'PLUS') 
{

$token = $self->{scanner}->($self);


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}


}
else 
{

last MATCH_16;


}
redo MATCH_16;


}
# MATCH_16


}
if ($token->{type} eq 'MGC') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
unshift (@{$self->{token}}, $token);
}
sub _parse_AttributeSpecificationList ($$$) {
my ($self, $doc, $attrs) = @_;
my $token;
$self->{scanner} = $self->can ('_scan_StartTag');
my $i;

{



    $i = 0;
  


}
$token = $self->{scanner}->($self);

MATCH_17:
{

if ($token->{type} eq 'Name') 
{

my $atqname;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (($self->{xml_version} eq '1.0' and
          not 
($token->{value} =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*(?::\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*)?\z/)
) or
         ($self->{xml_version} eq '1.1' and
          not 
($token->{value} =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*(?::\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*)?\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      $atqname = $token->{value};
    


}
my $vals;

{


      if 
($attrs->{$atqname}) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $atqname, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-unique-att-spec', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      
      $vals = $attrs->{$atqname} = {
        nodes => [],
        value => '',
        index => $i++,
      };
    


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'VI') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($token->{type} eq 'LIT') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);

MATCH_9:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      my $text = $doc->
create_text_node
 ($token->{value});
      push @{$vals->{nodes}}, $text;
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                  (my $char = chr $num);
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                        (my $char = chr $token->{value});
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      push @{$vals->{nodes}}, $er;
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteral');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_9;


}
redo MATCH_9;


}
# MATCH_9


}
if ($token->{type} eq 'LIT') 
{

$self->{scanner} = $self->can ('_scan_StartTag');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_StartTag');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'LITA') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);

MATCH_10:
{

if ($token->{type} eq 'STRING') 
{


{



      $token->{value} =~ s/[\x09\x0A\x0D]/ /g;
      my $text = $doc->
create_text_node
 ($token->{value});
      push @{$vals->{nodes}}, $text;
      $vals->{value} .= $token->{value};
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                  (my $char = chr $num);
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $doc = $doc;
my $vals = $vals;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      my $ncr = $doc->
create_text_node

                        (my $char = chr $token->{value});
      push @{$vals->{nodes}}, $ncr;
      $vals->{value} .= $char;
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{


{

my $vals = $vals;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('<');
      $vals->{value} .= '<';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('>');
      $vals->{value} .= '>';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('&');
      $vals->{value} .= '&';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ('"');
      $vals->{value} .= '"';
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{


      push 
@{$vals->{nodes}}, $self->{doc}->
create_text_node

                                              ("'");
      $vals->{value} .= "'";
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $self->{doc}->
create_entity_reference
 ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          

        if ($ent->{is_external_entity}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-external-entity-references', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          ## NOTE: |xp:wf-parsed-entity| is not checked
        } # if external entity

        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      }
      push @{$vals->{nodes}}, $er;
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_AttributeValueLiteralE');
$self->_parse_AttributeValueLiteralE_ ($er, $vals);
$token = $self->{scanner}->($self);
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_AttributeValueLiteralA');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_10;


}
redo MATCH_10;


}
# MATCH_10


}
if ($token->{type} eq 'LITA') 
{

$self->{scanner} = $self->can ('_scan_StartTag');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_StartTag');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);
redo MATCH_17;


}
else 
{

last MATCH_17;


}


}
# MATCH_17
unshift (@{$self->{token}}, $token);
}
sub _parse_Element_ ($$$$) {
my ($self, $doc, $parent, $ns) = @_;
my $token;
$self->{scanner} = $self->can ('_scan_ElementContent');
my $node;
my $nodes;
my $type;
my $types;
my $nses;

{



    $node = $parent;
    $nodes = [];
    $type = '';
    $types = [];
    $ns ||= {
      xml => 
'http://www.w3.org/XML/1998/namespace'
,
      xmlns => 
'http://www.w3.org/2000/xmlns/'
,
    };
    $nses = [];
  


}
$token = $self->{scanner}->($self);

MATCH_18:
{

if ($token->{type} eq 'CharData') 
{


{



      $node->
manakai_append_text
 (\($token->{value}));
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'STAGO') 
{

$self->{scanner} = $self->can ('_scan_StartTag');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{

my $attrs;

{



        

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (($self->{xml_version} eq '1.0' and
          not 
($token->{value} =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*(?::\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*)?\z/)
) or
         ($self->{xml_version} eq '1.1' and
          not 
($token->{value} =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*(?::\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*)?\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-qname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkQName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
        push @{$types}, $type;
        $type = $token->{value};
        $attrs = {};
      


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'S') 
{

$self->_parse_AttributeSpecificationList ($doc, $attrs);
$token = $self->{scanner}->($self);


}
my $el;

{


        push 
@{$nses}, $ns;
        $ns = {%$ns};

        ## Default attributes
        DA: for my $atqname (%{$self->{attr}->{$type}}) {
          next DA unless $self->{attr}->{$type}->{$atqname};
          next DA if exists $attrs->{$atqname}; # specified
          my $dtype = $self->{attr}->{$type}->{$atqname}
                           ->
default_type
;
          next DA unless $dtype == 
4 or
                         
$dtype == 
1
;
          $attrs->{$atqname} = {is_default => 
1
, nodes => []};
          for (@{$self->{attr}->{$type}->{$atqname}
                      ->
child_nodes
}) {
            push @{$attrs->{$atqname}->{nodes}},
                 $_->
clone_node
 (
1
);
          }
        }
        
        my %gattr;
        my %lattr;
        for my $atqname (keys %$attrs) {
          my ($pfx, $lname) = split /:/, $atqname;
          $attrs->{$atqname}->{def} = $self->{attr}->{$type}->{$atqname};
          if (defined $lname) {  ## Global attribute
            if ($pfx eq 'xmlns') {
              my $nsuri = $attrs->{$atqname}->{is_default}
                            ? $attrs->{$atqname}->{def}->
node_value
                            : 
$attrs->{$atqname}->{value};
              if (not $attrs->{$atqname}->{is_default} and
                  $attrs->{$atqname}->{def}) {
                my $dt = $attrs->{$atqname}->{def}->
declared_type
;
                if ({
                  
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
                  
5
 => 
1
,
                  
6
 => 
1
,
                  
7
 => 
1
,
                  
8
 => 
1
,
                  
9
 => 
1
,
                  
10
 => 
1
,
                }->{$dt}) {
                  ## Tokenization (XML 1 3.3.3)
                  for ($nsuri) {
                    s/^\x20+//;
                    s/\x20+\z//;
                    s/\x20+/ /g;
                  }
                }
              }
              if ($lname eq 'xml' and
                  $nsuri ne 
'http://www.w3.org/XML/1998/namespace'
) {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-prefix-xml', 'http://www.w3.org/2001/04/infoset#namespaceName' => $nsuri, 'http://www.w3.org/2001/04/infoset#prefix' => $lname, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              } elsif ($lname eq 'xmlns') {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-prefix-xmlns', 'http://www.w3.org/2001/04/infoset#namespaceName' => $nsuri, 'http://www.w3.org/2001/04/infoset#prefix' => $lname, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              }
              if ($nsuri eq '') {
                if ($self->{xml_version} eq '1.0') {
                  my $location;
                  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                  my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-empty-namespace-name', 'http://www.w3.org/2001/04/infoset#namespaceName' => $nsuri, 'http://www.w3.org/2001/04/infoset#prefix' => $lname, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                  unless ($continue) {
                    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                  }
                }
              } elsif ($nsuri eq 
'http://www.w3.org/XML/1998/namespace' and
                       
$lname ne 'xml') {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xml', 'http://www.w3.org/2001/04/infoset#namespaceName' => $nsuri, 'http://www.w3.org/2001/04/infoset#prefix' => $lname, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              } elsif ($nsuri eq 
'http://www.w3.org/2000/xmlns/'
) {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xmlns', 'http://www.w3.org/2001/04/infoset#namespaceName' => $nsuri, 'http://www.w3.org/2001/04/infoset#prefix' => $lname, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              }
              $ns->{$lname} = $nsuri;
              delete $ns->{$lname} unless length $ns->{$lname};
            }
            $gattr{$pfx}->{$lname} = $attrs->{$atqname};
          } else {               ## Local attribute
            if ($pfx eq 'xmlns') {
              $ns->{''} = $attrs->{xmlns}->{is_default}
                            ? $attrs->{xmlns}->{def}->
node_value
                            : 
$attrs->{xmlns}->{value};
              if (not $attrs->{$atqname}->{is_default} and
                  $attrs->{$atqname}->{def}) {
                my $dt = $attrs->{$atqname}->{def}->
declared_type
;
                if ({
                  
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
                  
5
 => 
1
,
                  
6
 => 
1
,
                  
7
 => 
1
,
                  
8
 => 
1
,
                  
9
 => 
1
,
                  
10
 => 
1
,
                }->{$dt}) {
                  ## Tokenization (XML 1 3.3.3)
                  for ($ns->{''}) {
                    s/^\x20+//;
                    s/\x20+\z//;
                    s/\x20+/ /g;
                  }
                }
              }
              unless ($ns->{''}) {
                delete $ns->{''};
              } elsif ($ns->{''} eq 
'http://www.w3.org/XML/1998/namespace'
) {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xml', 'http://www.w3.org/2001/04/infoset#namespaceName' => 'http://www.w3.org/XML/1998/namespace', 'http://www.w3.org/2001/04/infoset#prefix' => undef, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              } elsif ($ns->{''} eq 
'http://www.w3.org/2000/xmlns/'
) {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-reserved-namespace-name-xmlns', 'http://www.w3.org/2001/04/infoset#namespaceName' => 'http://www.w3.org/2000/xmlns/', 'http://www.w3.org/2001/04/infoset#prefix' => undef, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
              }
            } else {
              $lattr{$pfx} = $attrs->{$atqname};
            }
          }
        }
        
        my ($pfx, $lname) = split /:/, $type;
        my $nsuri;
        if (defined $lname) {  ## Prefixed namespace
          if (defined $ns->{$pfx}) {
            $nsuri = $ns->{$pfx};
          } else {
            my $location;
            

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
            my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $type, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-prefix-declared', 'http://www.w3.org/2001/04/infoset#prefix' => $pfx, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
            unless ($continue) {
              

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
            }
          }
        } else {               ## Default namespace
          $nsuri = $ns->{''};
        }
        
        $el = $doc->
create_element_ns

                         ($nsuri, $type);
        
        if ($attrs->{xmlns}) {
          my $attr = $doc->
create_attribute_ns

                             (
'http://www.w3.org/2000/xmlns/'
, 'xmlns');
          for (@{$attrs->{xmlns}->{nodes}}) {
            if ($_->
node_type
 == 
3
) {
              $attr->
manakai_append_text
 
                       (\($_->
text_content
));
            } else {
              $attr->
append_child
 ($_);
            }
          }
          if ($attrs->{xmlns}->{def}) {
            $attr->
manakai_attribute_type

                     ($attrs->{xmlns}->{def}->
declared_type
);
          }
          $el->
set_attribute_node_ns
 ($attr);
          $attr->
specified
 (
0
)
            if $attrs->{xmlns}->{is_default};
        }
        
        for my $lname (keys %lattr) {
          my $attr = $doc->
create_attribute_ns

                             (
undef
, $lname);
          for (@{$lattr{$lname}->{nodes}}) {
            if ($_->
node_type
 == 
3
) {
              $attr->
manakai_append_text

                       (\($_->
text_content
));
            } else {
              $attr->
append_child
 ($_);
            }
          }
          if ($attrs->{$lname}->{def}) {
            $attr->
manakai_attribute_type

                     ($attrs->{$lname}->{def}->
declared_type
);
          }
          $el->
set_attribute_node_ns
 ($attr);
          $attr->
specified
 (
0
)
            if $attrs->{$lname}->{is_default};
        }
        
        for my $pfx (keys %gattr) {
          LN: for my $lname (keys %{$gattr{$pfx}}) {
            my $name = $pfx.':'.$lname;
            unless (defined $ns->{$pfx}) {
              my $location;
              

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
              my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $name, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nsc-prefix-declared', 'http://www.w3.org/2001/04/infoset#prefix' => $pfx, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
              unless ($continue) {
                

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
              }
            }
            my $attr = $el->
get_attribute_node_ns

                              ($ns->{$pfx}, $lname);
            if ($attr) {
              my $another_name = $attr->
node_name
;
              if ($name ne $another_name) {
                my $location;
                

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
                my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $name, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-unique-att-spec-expanded-name', 'http://www.w3.org/2001/04/infoset#namespaceName' => $ns->{$pfx}, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#another-attribute-name' => $another_name, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://www.w3.org/2001/04/infoset#localName' => $lname;

;
                unless ($continue) {
                  

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
                }
                unless ($attr->
specified
) {
                  ## It is a default attribute
                  $attr = $doc->
create_attribute_ns

                                  ($ns->{$pfx}, $name);
                } else {
                  ## It is a specified attribute
                  next LN;
                }
              } else { ## There is default attribute
                $attr = $doc->
create_attribute_ns

                                ($ns->{$pfx}, $name);                    
              }
            } else {
              $attr = $doc->
create_attribute_ns

                               ($ns->{$pfx}, $name);
            }
            for (@{$gattr{$pfx}->{$lname}->{nodes}}) {
              if ($_->
node_type
 == 
3
) {
                $attr->
manakai_append_text

                         (\($_->
text_content
));
              } else {
                $attr->
append_child
 ($_);
              }
            }
            if ($gattr{$pfx}->{$lname}->{def}) {
              $attr->
manakai_attribute_type

                       ($gattr{$pfx}->{$lname}->{def}
                                    ->
declared_type
);
            }
            $el->
set_attribute_node_ns
 ($attr);
            $attr->
specified
 (
0
)
              if $gattr{$pfx}->{$lname}->{is_default};
          } # PFX
        }

        $node->
append_child
 ($el);            
      


}
if ($token->{type} eq 'TAGC') 
{


{


          push 
@{$nodes}, $node;
          $node = $el;
        


}
$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'NESTC') 
{

my $is_docel;

{



          $ns = pop @{$nses};
          $type = pop @{$types};
          $is_docel = (@{$types} == 0);
        


}
if ($is_docel) 
{

return ;


}
$token = $self->{scanner}->($self);
if ($token->{type} eq 'TAGC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ETAGO') 
{

$self->{scanner} = $self->can ('_scan_EndTag');
my $is_docel;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


        if 
($token->{value} eq $type) {
          $type = pop @{$types};
          if ($type eq '') {
            $is_docel = 
1
;
          }
          $node = pop @{$nodes};
          $ns = pop @{$nses};
        } else {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-element-type-match', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#actual-element-type' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#expected-element-type' => $type, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#node' => $node;

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }
      


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$token = $self->{scanner}->($self);


}
if ($is_docel) 
{


{


        if 
(@{$types}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          for my $type (reverse @{$types}) {
            my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-end-tag', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#expected-element-type' => $type, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#node' => $node;

;
            unless ($continue) {
              

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
            }
            $node = shift @{$nodes};
          }
        }
      


}
unshift (@{$self->{token}}, $token);
return ;


}
if ($token->{type} eq 'TAGC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $parent = $node;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $parent->
manakai_append_text
 (chr $num);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $parent = $node;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $parent->
manakai_append_text
 (chr $token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{

$self->_parse__GeneralEntityReferenceEC ($doc, $node, $ns);
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'CDO') 
{


{

my $doc = $doc;
my $parent = $node;
$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{


      my 
$com = $doc->
create_comment
 ($token->{value});
      $parent->
append_child
 ($com);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


      my 
$com = $doc->
create_comment
 ('');
      $parent->
append_child
 ($com);
    


}


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CDSO') 
{


{

my $doc = $doc;
my $parent = $node;
$self->{scanner} = $self->can ('_scan_CDATASectionContent');
my $cdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'CData') 
{


{



      $cdata = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $cdata = '';
    


}


}

{


    my 
$cdsect = $doc->
create_cdata_section

                         ($cdata);
    $parent->
append_child
 ($cdsect);
  


}


}
if ($token->{type} eq 'MSE') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $parent = $node;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_18;


}
redo MATCH_18;


}
# MATCH_18
if ($token->{type} eq '#NONE') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
unshift (@{$self->{token}}, $token);
}
sub _parse__GeneralEntityReferenceEC ($$$$) {
my ($self, $doc, $parent, $ns) = @_;
my $token;
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);
if (($token->{type} eq 'Name') and ($token->{value} eq 'lt')) 
{


{



      $parent->
manakai_append_text
 ('<');
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'gt')) 
{


{



      $parent->
manakai_append_text
 ('>');
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'amp')) 
{


{



      $parent->
manakai_append_text
 ('&');
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'quot')) 
{


{



      $parent->
manakai_append_text
 ('"');
    


}
$token = $self->{scanner}->($self);


}
elsif (($token->{type} eq 'Name') and ($token->{value} eq 'apos')) 
{


{



      $parent->
manakai_append_text
 ("'");
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'Name') 
{

my $er;

{



      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $er = $doc->
create_entity_reference

                       ($token->{value});
      $er->
manakai_set_read_only
 (
0
, 
1
);
      $er->
text_content
 ('');
        ## NOTE: When document entity (and entities referenced directly
        ##       or indirectly from it) is parsed, no general entity
        ##       node have its replacement tree.  During general
        ##       entity node collection construction, however,
        ##       some entity node has replacement tree.
      $parent->
append_child
 ($er);

      my $ent = $self->{general_entity}->{$token->{value}};
      if (not $ent) {  # no entity declaration
        if ($self->{standalone} or not $self->{has_xref}) { # WFC error
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }                 # Otherwise VC error
        push @{$self->{entity}}, 
{reptxt => \'', line => 1, column => 1, pos => 0,
 is_externally_declared => 1, name => $token->{value},
 fh => do { 
         open my $empty, '<', \'';
         $empty;
       },
 close_file => sub { }}
;
        $er->
manakai_expanded
 (
0
);

      } else {         # there IS entity declaration
        if (($self->{standalone} or not $self->{has_xref}) and
            $ent->{is_externally_declared} and
            not $self->{entity}->[-1]->{is_externally_declared}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-entity-declared', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        }          
        $er->
manakai_expanded

               ($ent->{has_replacement_text});
        push @{$self->{entity}}, 
{%{$self->{'general_entity'}->{$token->{value}}},
 line => 1, column => 1, pos => 0,
 fh => do {
         require IO::String;
         IO::String->new
                      (${$self->{'general_entity'}->{$token->{value}}->{reptxt}});
         ## TODO: External entities.
       },
 close_file => sub { }}
;

        if (defined $ent->{notation}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-parsed-entity', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
        } # if unparsed entity
        
        if ($ent->{is_opened}) {
          my $location;
          

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
          my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-no-recursion', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
          unless ($continue) {  
            

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
          }
          open my $empty, '<', \'';
          $self->{entity}->[-1]->{fh} = $empty;
          $er->
manakai_expanded
 (
0
);
        } # recursive
        $ent->{is_opened} = 
1
;
      } # entity declared
      $self->{location} = $self->{entity}->[-1];
      push @{$self->{entity_token}}, $self->{token};
      $self->{token} = [];
      push @{$self->{entity_char}}, $self->{char};
      $self->{char} = [];
    


}
$self->{scanner} = $self->can ('_scan_ElementContent');

{

my $parent = $er;
my $ns = $ns;
my $doc;

{



    $doc = $self->{doc};
  


}
$token = $self->{scanner}->($self);

MATCH_2:
{

if ($token->{type} eq 'CharData') 
{


{



      $parent->
manakai_append_text
 (\($token->{value}));
    


}
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'STAGO') 
{

unshift (@{$self->{token}}, $token);
$self->_parse_Element_ ($doc, $parent, $ns);
$token = $self->{scanner}->($self);
if ($token->{type} eq 'TAGC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'HCRO') 
{


{

my $parent = $parent;
$self->{scanner} = $self->can ('_scan_HexadecimalCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Hex') 
{


{


      my 
$num = hex $token->{value};
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF) or
           $num == 0x9 or $num == 0xA or $num == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $num and $num <= 0xD7FF) or
           (0xE000 <= $num and $num <= 0xFFFD) or
           (0x10000 <= $num and $num <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $num, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $parent->
manakai_append_text
 (chr $num);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CRO') 
{


{

my $parent = $parent;
$self->{scanner} = $self->can ('_scan_NumericCharacterReference');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'NUMBER') 
{


{



      $token->{value} += 0;
      unless (
        ($self->{xml_version} eq '1.0' and
          ((0x0020 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF) or
           $token->{value} == 0x9 or $token->{value} == 0xA or $token->{value} == 0xD)) or
        ($self->{xml_version} eq '1.1' and
          ((0x0001 <= $token->{value} and $token->{value} <= 0xD7FF) or
           (0xE000 <= $token->{value} and $token->{value} <= 0xFFFD) or
           (0x10000 <= $token->{value} and $token->{value} <= 0x10FFFF)))
      ) {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-legal-character', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#character-number' => $token->{value}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      $parent->
manakai_append_text
 (chr $token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'ERO') 
{

$self->_parse__GeneralEntityReferenceEC ($doc, $parent, $ns);
$token = $self->{scanner}->($self);


}
elsif ($token->{type} eq 'CDO') 
{


{

my $doc = $doc;
my $parent = $parent;
$self->{scanner} = $self->can ('_scan_CommentDeclaration');
$token = $self->{scanner}->($self);
if ($token->{type} eq 'STRING') 
{


{


      my 
$com = $doc->
create_comment
 ($token->{value});
      $parent->
append_child
 ($com);
    


}
$token = $self->{scanner}->($self);


}
else 
{


{


      my 
$com = $doc->
create_comment
 ('');
      $parent->
append_child
 ($com);
    


}


}
if ($token->{type} eq 'COM') 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_MarkupDeclaration');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
if ($token->{type} eq 'MDC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'CDSO') 
{


{

my $doc = $doc;
my $parent = $parent;
$self->{scanner} = $self->can ('_scan_CDATASectionContent');
my $cdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'CData') 
{


{



      $cdata = $token->{value};
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $cdata = '';
    


}


}

{


    my 
$cdsect = $doc->
create_cdata_section

                         ($cdata);
    $parent->
append_child
 ($cdsect);
  


}


}
if ($token->{type} eq 'MSE') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
elsif ($token->{type} eq 'PIO') 
{


{

my $doc = $doc;
my $parent = $parent;
$self->{scanner} = $self->can ('_scan_PIName');
my $pi;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'Name') 
{


{


      if 
(lc $token->{value} eq 'xml') {
        my $location;
        

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
        my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-pi-target-is-xml', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#parent' => $parent;

;
        unless ($continue) {
          

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
        }
      }
      

{

if 
(($self->{xml_version} eq '1.0' and
     not 
($token->{value} =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/)
) or
    ($self->{xml_version} eq '1.1' and
     not 
($token->{value} =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/)
)) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-invalid-character-in-node-name', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }
} elsif (index ($token->{value}, ':') > -1) {
  my $__location;
  

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$__location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$__location->{utf32_offset} = 0 if $__location->{utf32_offset} < 0;
$__location->{column_number} = 0 if $__location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
  my $__continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $__location, 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#name' => $token->{value}, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#nswf-legal-ncname', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://www.w3.org/2001/04/infoset#version' => $self->{xml_version}, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#checkNCName';

;
  unless ($__continue) {
    

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
  }            
}


}

;
      
      $pi = $doc->
create_processing_instruction

                    ($token->{value});
    


}
$token = $self->{scanner}->($self);


}
else 
{


{



      $pi = $doc->
create_processing_instruction
 ('#INVALID');
    


}

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'S') 
{

$self->{scanner} = $self->can ('_scan_PIData');
my $tdata;
$token = $self->{scanner}->($self);
if ($token->{type} eq 'DATA') 
{


{



        $tdata = $token->{value};
      


}
$token = $self->{scanner}->($self);


}
else 
{


{



        $tdata = '';
      


}


}

{



      $pi->
node_value
 ($tdata);
    


}


}

{



    $parent->
append_child
 ($pi);
  


}


}
if ($token->{type} eq 'PIC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}


}
else 
{

last MATCH_2;


}
redo MATCH_2;


}
# MATCH_2


}
if ($token->{type} eq '#EOF') 
{

$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}

{



      $self->{general_entity}->{$self->{entity}->[-1]->{name}}
           ->{is_opened} = 
0
        if 
$self->{general_entity}->{$self->{entity}->[-1]->{name}};
      $self->{token} = pop @{$self->{entity_token}};
      $self->{char} = pop @{$self->{entity_char}};
      pop (@{$self->{entity}})->{close_file}->();
      $self->{location} = $self->{entity}->[-1];

      $er->
manakai_set_read_only
 (
1
, 
1
);
    


}
$self->{scanner} = $self->can ('_scan_EntityReference');
$token = $self->{scanner}->($self);


}
else 
{


{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
if ($token->{type} eq 'REFC') 
{

$self->{scanner} = $self->can ('_scan_ElementContent');
$token = $self->{scanner}->($self);


}
else 
{

$self->{scanner} = $self->can ('_scan_ElementContent');

{


{


    my 
$location;
    

{

my 
$__d = $token->{type} ne '#EOF'
            ? $token->{location}->{char_d}
            : 0;
$__d -= $token->{location_d} if $token->{location_d};
$location = {
  utf32_offset => $token->{location}->{pos} - $__d,
  line_number => $token->{location}->{line},
  column_number => $token->{location}->{column} - $__d,
};
$location->{utf32_offset} = 0 if $location->{utf32_offset} < 0;
$location->{column_number} = 0 if $location->{column_number} < 0;
                        ## 0 or 1, which should be?


}

;
    my $continue = 
report Message::DOM::DOMCore::ManakaiDOMError -object => $self, 'loc' => $location, '-type' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#wf-syntax-error', 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token' => $token, 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ManakaiXMLParser';

;
    unless ($continue) {
      

{


{

local $Error::Depth = $Error::Depth + 1;

{


  for 
(@{$self->{entity}}) {
    $_->{close_file}->();
  }



}


;}

;

report Message::DOM::DOMLS::ManakaiDOMLSException -object => $self, '-type' => 'PARSE_ERR', 'http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#resourceURI' => 'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#ParseError';

;


}

;
    }
  


}


}


}
unshift (@{$self->{token}}, $token);
}

package Message::DOM::XMLParser::ManakaiXMLParserExceptionFormatter;
push our @ISA, 'Message::Util::Error::formatter';

sub ___rule_def {
{'character_code_point',
{'after',
sub ($$$$) {
my ($self, $name, $p, $o) = @_;

{


$p->{-result} = sprintf 'U+%04X', $o->{$p->{v}};


}
}
},
'xp_error_lines',
{'after',
sub ($$$$) {
my ($self, $name, $p, $o) = @_;

{

my 
$pos = $o->
location

            ->
utf32_offset
;
my $src = $o->{
'-object'
}->{entity}->[-1]->{reptxt};
if (defined $src and $pos > -1) {
  my $start = $pos;
  $start = rindex ($$src, "\x0A", $start - 1) for 0..2;
  $start++;
  my $end = $pos;
  $end = index ($$src, "\x0A", $end + 1) for 0..2;
  $end = length $$src if $end < 0;
  $p->{-result} = substr $$src, $start, $end - $start;
}


}
}
},
'xp_error_token_type',
{'after',
sub ($$$$) {
my ($self, $name, $p, $o) = @_;

{


$p->{-result} = $o->{
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token'
}->{type}
  if defined $o->{
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token'
}->{type};


}
}
},
'xp_error_token_value',
{'after',
sub ($$$$) {
my ($self, $name, $p, $o) = @_;

{


$p->{-result} = $o->{
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token'
}->{value}
  if defined $o->{
'http://suika.fam.cx/~wakaba/archive/2004/dom/xml-parser#error-token'
}->{value};


}
}
}};
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/15 12:54:06 $
