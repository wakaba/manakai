=head1 NAME

Message::Markup::XML::Parser::Error - manakai: XML Parsing Errors

=head1 DESCRIPTION

C<Message::Markup::XML::Parser::Error> module defines XML parsing
errors including well-formedness error and validness error
(but not limited to them).

This module is part of manakai.

=cut

package Message::Markup::XML::Parser::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::Markup::XML::Parser::Error;
require Message::Util::Error::TextParser;
push our @ISA, 'Message::Util::Error::TextParser::error';

sub ___error_def () {+{
  
}}

sub text {
  my $self = shift;
  $self->_FORMATTER_PACKAGE_->new
       ->replace ('%err-line;.%err-char;: '.$self->{-def}->{description}.' %err-at (prefix => {at "}, suffix => {"}, before => 20, after => 20);', param => $self);
}

package Message::Markup::XML::Parser::Error::WFC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
  SYNTAX_ATTR_NAME_REQUIRED => {
    description => q(Attribute name expected),
    level => 'ebnf',
  },
  SYNTAX_ALITC_REQUIRED => {
    description => q(lit (") closing attribute value literal expected),
    level => 'ebnf',
  },
  SYNTAX_ALITAC_REQUIRED => {
    description => q(lita (') closing attribute value literal expected),
    level => 'ebnf',
  },
  SYNTAX_ALITO_OR_ALITAO_REQUIRED => {
    description => q(lit (") or lita (') opening attribute value literal expected),
    level => 'ebnf',
  },
  SYNTAX_COMC_REQUIRED => {
    description => q(com (--) closing comment required),
    level => 'ebnf',
  },
  SYNTAX_COMO_REQUIRED => {
    description => q(com (--) opening comment required),
    level => 'ebnf',
  },
  SYNTAX_COMMENT_DECLARATION_REQUIRED => {
    description => q(Comment declaration expected),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_ETAGO_REQUIRED => {
    description => q(Element type name (generic identifier) required just after etago (</)),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED => {
    description => q(Element type name (generic identifier) required just after stago (<)),
  },
  SYNTAX_EMPTY_COMMENT_DECLARATION => {
    description => q(Empty comment declaration (<!>) not allowed),
    level => 'ebnf',
  },
  SYNTAX_END_TAG_NOT_ALLOWED => {
    description => q(End tag not allowed),
    level => 'ebnf',
  },
  SYNTAX_END_TAG_REQUIRED => {
    description => q(End tag for element "%t (name => element-type-name);" required),
    level => 'ebnf',
  },
  SYNTAX_ETAGC_REQUIRED => {
    description => q(tagc (>) terminating end tag required),
    level => 'ebnf',
  },
  SYNTAX_HASH_OR_NAME_REQUIRED => {
    description => q("#" or Name expected after "&"),
    level => 'ebnf',
  },
  SYNTAX_HCRO_CASE => {
    description => q(Third character of hcro (&#x) must be a LATIN SMALL LETTER X (x)),
    level => 'ebnf',
  },
  SYNTAX_HEXDIGIT_REQUIRED => {
    description => q(HEXDIGIT ([0-9A-Fa-f]) required after hcro (&#x)),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_REQUIRED => {
    description => q(Markup declaration expected),
    level => 'ebnf',
  },
  SYNTAX_MDC_FOR_COMMENT_REQUIRED => {
    description => q(mdc (>) closing comment declaration required),
    level => 'ebnf',
  },
  SYNTAX_MULTIPLE_COMMENT => {
    description => q(Multiple comment in one comment declaration not allowed),
    level => 'ebnf',
  },
  SYNTAX_NAMED_CHARACTER_REFERENCE => {
    description => q(Named character reference not allowed),
    level => 'ebnf',
  },
  SYNTAX_NAME_OR_DSO_OR_COM_REQUIRED => {
    description => q(Keyword or dso ([) or com (--) required),
    level => 'ebnf',
  },
  SYNTAX_NET_REQUIRED => {
    description => q(net (>) required just after nestc (/)),
    level => 'ebnf',
  },
  SYNTAX_PI_TARGET_XML => {
    description => q(Name "%t (name => target-name);" cannot be used as target name for processing instruction),
    level => 'ebnf',
  },
  SYNTAX_PIC_REQUIRED => {
    description => q(pic (?>) terminating processing instruction required),
    level => 'ebnf',
  },
  SYNTAX_PROCESSING_INSTRUCTION_REQUIRED => {
    description => q(Processing instruction expected),
    level => 'ebnf',
  },
  SYNTAX_REFC_REQUIRED => {
    description => q(refc (;) expected),
    level => 'ebnf',
  },
  SYNTAX_REFERENCE_AMP_REQUIRED => {
    description => q(ero (&), cro (&#) or hcro (&#x) expected),
    level => 'ebnf',
  },
  SYNTAX_S_IN_COMMENT_DECLARATION => {
    description => q(s (SPACE, TAB, CR or LF) not allowed in comment declaration (out of comment)),
    level => 'ebnf',
  },
  SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC => {
    description => q(s (SPACE, TAB, CR or LF) required between attribute specification),
    level => 'ebnf',
  },
  SYNTAX_SLASH_OR_ELEMENT_TYPE_NAME_REQUIRED => {
    description => q(Element type name or SOLIDUS (/) expected),
    level => 'ebnf',
  },
  SYNTAX_SLASH_REQUIRED => {
    description => q(SOLIDUS (/) expected),
    level => 'ebnf',
  },
  SYNTAX_STAGC_OR_NESTC_REQUIRED => {
    description => q(stagc (>) or nestc (/) expected),
    level => 'ebnf',
  },
  SYNTAX_START_TAG_REQUIRED => {
    description => q(Start tag expected),
    level => 'ebnf',
  },
  SYNTAX_START_TAG_NOT_ALLOWED => {
    description => q(Start tag not allowed),
    level => 'ebnf',
  },
  SYNTAX_TAG_REQUIRED => {
    description => q(Tag expected),
    level => 'ebnf',
  },
  SYNTAX_TARGET_NAME_REQUIRED => {
    description => q(Target name for processing instruction required),
    level => 'ebnf',
  },
  SYNTAX_VI_REQUIRED => {
    description => q(vi (=) expected),
    level => 'ebnf',
  },
  SYNTAX_X_OR_DIGIT_REQUIRED => {
    description => q("x" (for hex character reference) or DIGIT ([0-9]) required after "&#"),
    level => 'ebnf',
  },
  SYNTAX_XML_DECLARATION_IN_MIDDLE => {
    description => q(XML or text declaration must be at exact first of entity),
    level => 'ebnf',
  },
  SYNTAX_XML_DECLARATION_REQUIRED => {
    declaration => q(XML declaration required in XML 1.1),
    level => 'ebnf/1.1',
  },
  SYNTAX_XML_ENCODING_INVALID => {
    description => q(Encoding declaration "%t (name => encoding);" contains invalid character),
    level => 'ebnf',
  },
  SYNTAX_XML_ENCODING_REQUIRED => {
    description => q(Encoding declaration required in text declaration),
    level => 'ebnf',
  },
  SYNTAX_XML_STANDALONE => {
    description => q(Standalone document declaration not allowed in text declaration),
    level => 'ebnf',
  },
  SYNTAX_XML_STANDALONE_INVALID => {
    description => q(Standalone document declaration must be either "yes" or "no"),
    level => 'ebnf',
  },
  SYNTAX_XML_STANDALONE_S => {
    description => q(Whitespaces just before "standalone" pseudo-attribute must be more than one SPACEs in XML 1.1),
    level => 'ebnf/1.1',
  },
  SYNTAX_XML_UNKNOWN_ATTR => {
    description => q(Unknown pseudo-attribute "%t (name => attribute-name);" in XML or text declaration),
    level => 'ebnf',
  },
  SYNTAX_XML_VERSION_INVALID => {
    description => q(XML Version "%t (name => version);" contains invalid character),
    level => 'ebnf',
  },
  SYNTAX_XML_VERSION_OR_ENCODING_REQUIRED => {
    description => q("version" or "encoding" pseudo-attribute required in XML or text declaration),
    level => 'ebnf',
  },
  SYNTAX_XML_VERSION_REQUIRED => {
    description => q("version" pseudo-attribute required in XML declaration),
    level => 'ebnf',
  },
  SYNTAX_XML_VERSION_UNKNOWN => {
    description => q(XML Version "%t (name => version);" not supported),
    level => 'ebnf',
  },
  
  WFC_ELEMENT_TYPE_MATCH => {
    description => q(Element type name in end tag (%t (name => end-tag-type-name);) MUST match with that in start tag (%t (name => start-tag-type-name);)),
    level => 'wfc',
  },
  WFC_NO_LESS_THAN_IN_ATTR_VAL => {
    description => q(LESS-THAN SIGN (<) not allowed in attribute value literal),
    level => 'wfc',
  },
  WFC_UNIQUE_ATT_SPEC => {
    description => q(Attribute "%t (name => attribute-name);" is already specified in this tag),
    level => 'wfc',
  },
}}

package Message::Markup::XML::Parser::Error::VC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
}}

package Message::Markup::XML::Parser::Error::NSWFC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
}}

package Message::Markup::XML::Parser::Error::NSVC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
}}

package Message::Markup::XML::Parser::Error::W3C;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
  RESERVED_ATTRIBUTE_NAME => {
    description => q(Attribute name "%t (name => attribute-name);" is reserved by W3C),
    level => 'reserved',
  },
  RESERVED_ELEMENT_TYPE_NAME => {
    description => q(Element type name "%t (name => element-type-name);" is reserved by W3C),
    level => 'reserved',
  },
  RESERVED_ENTITY_NAME => {
    description => q(Entity name "%t (name => entity-name);" is reserved by W3C),
    level => 'reserved',
  },
  RESERVED_ID => {
    description => q(ID "%t (name => id);" is reserved by W3C),
    level => 'reserved',
  },
  RESERVED_LOCAL_NAME => {
    description => q(Local name "%t (name => local-name);" should not be used, since it is considered as reserved when used without prefix),
    level => 'reserved',
  },
  RESERVED_NAMESPACE_PREFIX => {
    description => q(Namespace prefix "%t (name => ns-prefix);" is reserved by W3C),
    level => 'reserved/names',
  },
  RESERVED_NOTATION_NAME => {
    description => q(Notation name "%t (name => notation-name);" is reserved by W3C),
    level => 'reserved',
  },
  RESERVED_PI_TARGET => {
    description => q(Processing instruction target name "%t (name => target-name);" is reserved by W3C),
    level => 'reserved',
  },

  TEXT_DECLARATION_MISSING => {
    description => q(External parsed entity SHOULD begin with text declaration),
    level => 'SHOULD',
  },
}}

package Message::Markup::XML::Parser::Error::Misc;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
  COMPAT_XML_STANDALONE_S => {
    description => q(S just before "standalone" pseudo-attribute should only contain SPACEs for compatibility with XML 1.1),
    level => 'compat/1.1',
  },
  
  MARKSECT_IN_XENT_IN_INT_SUBSET => {
    description => q(Some XML processors written before XML 1.0 SE Errata do not support marked sections in external entities referred from internal subset),
    level => 'implementation',
  },
  PI_TARGET_NOT_DECLARED => {
    description => q(Processing instruction target name "%t (name => target-name);" should be declared as notation),
    level => 'not_declared',
  },

  XML_DECLARATION_MISSING => {
    description => q(XML declaration missing, so that it is assumed as XML 1.0 document),
    level => 'message',
  },
}}

=head1 SEE ALSO

C<Message::Markup::XML::Parser>,
XML 1.0 Specification <http://www.w3.org/TR/REC-xml>,
XML 1.1 Specification <http://www.w3.org/TR/xml11>,
Namespace of XML <http://www.w3.org/TR/REC-xml-names>,
Namespace of XML 1.1 <http://www.w3.org/TR/xml-names11>,
RFC 3023 <urn:ietf:rfc:3023>.

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/02/24 07:25:10 $
