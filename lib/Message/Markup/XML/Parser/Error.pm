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
our $VERSION = do{my @r=(q$Revision: 1.1.2.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

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

sub _FORMATTER_PACKAGE_ () { 'Message::Markup::XML::Parser::Error::formatter' }

package Message::Markup::XML::Parser::Error::formatter;
push our @ISA, 'Message::Util::Error::TextParser::formatter';

sub ___rule_def () {+{
  code_ucs => {
    after => sub {
      my ($self, $name, $p, $o) = @_;
      my $code = ord $o->{$p->{source} || 'char'};
      $p->{-result} .= sprintf $code > 0xFFFF ? 'U-%08X' : 'U+%04X', $code;
    },
  },
  markup_declaration_parameters => {
    after => sub {
      my ($self, $name, $p, $o) = @_;
      my @result;
      for my $param (@{$o->{param} || []}) {
        my $result = '(' . $param->{type} . ') ';
        if (ref $param->{value} eq 'SCALAR') {
          $result .= '"' . ${$param->{value}} . '"';
        } else {
          $result .= '"' . $param->{value} . '"';
        }
        push @result, $result;
      }
      for (reverse @{$o->{sources} || []}) {
        push @result, '"' . substr ($$_, pos $$_, 20) . '"';
      }
      $p->{-result} = join ', ', @result;
    },
  },
}}

package Message::Markup::XML::Parser::Error::SYNTAX;
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
  SYNTAX_ATTLIST_ASSOCIATED_NAME_REQUIRED => {
    description => q(Element type name required),
    level => 'ebnf',
  },
  SYNTAX_ATTLIST_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_ATTLIST_SGML_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" cannot be used),
    level => 'ebnf',
  },
  SYNTAX_ATTLIST_UNKNOWN_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_ATTR_SPEC_REQUIRED => {
    description => q(Attribute specification expected),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_DEFAULT_NAME => {
    description => q(Attribute default value specification must be an attribute value literal, not an attribute value),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_DEFAULT_REQUIRED => {
    description => q(Attribute default value specification (rni (#) + keyword or attribute value specification) required),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_DEFAULT_SGML_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" cannot be used),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_DEFAULT_UNKNOWN_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_FIXED_LITERAL_REQUIRED => {
    description => q(Attribute value literal required),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_NOTATION_GROUP_REQUIRED => {
    description => q(Group for notation options required),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_TYPE_GROUP_GRPC_REQUIRED => {
    description => q[grpc [)] required],
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_TYPE_GROUP_NMTOKEN_REQUIRED => {
    description => q(Nmtoken required),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_TYPE_REQUIRED => {
    description => q(Attribute value type specification (keyword or group) required),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_TYPE_SGML_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" cannot be used),
    level => 'ebnf',
  },
  SYNTAX_ATTRDEF_TYPE_UNKNOWN_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_ATTRIBUTE_VALUE => {
    description => q(Attribute value specification must be an attribute value literal),
    level => 'ebnf',
  },
  SYNTAX_CDATA_OUTSIDE_DOCUMENT_ELEMENT => {
    description => q(Character data must be in document element (between explicit start and end tags)),
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
  SYNTAX_COMMENT_DECLARATION_NOT_ALLOWED => {
    description => q(Comment declaration not allowed here),
    level => 'ebnf',
  },
  SYNTAX_COMMENT_DECLARATION_REQUIRED => {
    description => q(Comment declaration expected),
    level => 'ebnf',
  },
  SYNTAX_CONNECTOR => {
    description => q(Connector "%t (name => connector);" not allowed),
    level => 'ebnf',
  },
  SYNTAX_DATA_TAG_GROUP => {
    description => q(Data tag group not allowed),
    level => 'ebnf',
  },
  SYNTAX_DOCTYPE_DECLARATION_REQUIRED => {
    description => q(Document type declaration expected),
    level => 'ebnf',
  },
  SYNTAX_DOCTYPE_IMPLIED => {
    description => q(Keyword "IMPLIED" cannot be used as document type name),
    level => 'ebnf',
  },
  SYNTAX_DOCTYPE_NAME_REQUIRED => {
    description => q(Document type name required),
    level => 'ebnf',
  },
  SYNTAX_DOCTYPE_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_DOCTYPE_RNI_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" cannot be used as document type name),
    level => 'ebnf',
  },
  SYNTAX_DOCTYPE_SUBSET_INVALID_CHAR => {
    description => q(Document type declaration subset cannot contain character "%t (name => char);"),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_DECLARATION_TYPE_NAME_GROUP => {
    description => q(Name group of generic identifiers or rank stems not allowed),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_DECLARATION_TYPE_NAME_REQUIRED => {
    description => q(Element type name (generic identifier) required),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_MODEL_OR_MIN_OR_RANK_REQUIRED => {
    description => q(Declared content keyword or model group required),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_RANK_SUFFIX => {
    description => q(Rank suffix not allowed),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_SGML_CONTENT_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" not allowed),
    level => 'ebnf', 
  },
  SYNTAX_ELEMENT_TAG_MIN => {
    description => q(Tag minimumization parameter not allowed),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_ETAGO_REQUIRED => {
    description => q(Element type name (generic identifier) required),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED => {
    description => q(Element type name (generic identifier) required),
    level => 'ebnf',
  },
  SYNTAX_ELEMENT_UNKNOWN_CONTENT_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_EMPTY_COMMENT_DECLARATION => {
    description => q(Empty comment declaration (<!>) not allowed),
    level => 'ebnf',
  },
  SYNTAX_END_TAG_NOT_ALLOWED => {
    description => q(End tag not allowed here),
    level => 'ebnf',
  },
  SYNTAX_END_TAG_REQUIRED => {
    description => q(End tag for element "%t (name => element-type-name);" required),
    level => 'MUST',
  },
  SYNTAX_ENTITY_DATA_TYPE_NOTATION_NAME_REQUIRED => {
    description => q(Data type keyword must be followed by notation name),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" not allowed),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_DATA_TYPE_UNKNOWN_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_DEFAULT => {
    description => q(Default entity not allowed),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_NAME_REQUIRED => {
    description => q(Entity name (either Name, for general entity, or pero (%) followed by one or more ps (whitespaces) and Name, for parameter entity) required),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_PARAM_NAME_REQUIRED => {
    description => q(Parameter entity name required),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_RNI_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_TEXT_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_TEXT_PRE_KEYWORD => {
    description => q(Keyword "%t (name => keyword);" not allowed),
    level => 'ebnf',
  },
  SYNTAX_ENTITY_TEXT_REQUIRED => {
    description => q(Entity text (either parameter literal containing entity value or external entity specification) required),
    level => 'ebnf',
  },
  SYNTAX_ETAGC_REQUIRED => {
    description => q(tagc (>) required),
    level => 'ebnf',
  },
  SYNTAX_EXCLAMATION_OR_QUESTION_REQUIRED => {
    description => q(EXCLAMATION MARK (!) for mdo (<!) or QUESTION MARK (?) for pio (<?) expected),
    level => 'MUST NOT',
  },
  SYNTAX_GENERAL_ENTREF => {
    description => q(General entity reference not allowed),
    level => 'ebnf',
  },
  SYNTAX_HASH_OR_NAME_REQUIRED => {
    description => q(Either "#" (for cro (&#), character reference open, or hcro (&#x), hexdecimal character reference open) or Name (for general entity reference) expected),
    level => 'MUST NOT',
  },
  SYNTAX_HCRO_CASE => {
    description => q(Third character of hcro (&#x) must be LATIN SMALL LETTER X (x), not LATIN CAPITAL LETTER X (X)),
    level => 'ebnf',
  },
  SYNTAX_HEX_CHAR_REF => {
    description => q(Hexademical character reference not allowed),
    level => 'ebnf',
  },
  SYNTAX_HEXDIGIT_REQUIRED => {
    description => q(HEXDIGIT ([0-9A-Fa-f]) required),
    level => 'ebnf',
  },
  SYNTAX_MARKED_SECTION_KEYWORD => {
    description => q(Status keyword "%t (name => keyword);" not allowed),
    level => 'ebnf',
  },
  SYNTAX_MARKED_SECTION_KEYWORD_REQUIRED => {
    description => q(Status keyword required),
    level => 'ebnf',
  },
  SYNTAX_MARKED_SECTION_KEYWORDS => {
    description => q(Multiple status keywords not allowed),
    level => 'ebnf',
  },
  SYNTAX_MARKED_SECTION_NOT_ALLOWED => {
    description => q(Marked section declaration not allowed here),
    level => 'ebnf',
  },
  SYNTAX_MARKED_SECTION_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_MARKED_SECTION_STATUS_PS => {
    description => q(ps not allowed),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_NOT_ALLOWED => {
    description => q(%t (name => keyword); declaration not allowed here),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_PS => {
    description => q(ps not allowed),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_REQUIRED => {
    description => q(Markup declaration expected),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM => {
    description => q(Too many parameters "%markup-declaration-parameters;"),
    level => 'ebnf',
  },
  SYNTAX_MARKUP_DECLARATION_UNKNOWN_KEYWORD => {
    description => q(Unknown markup declaration keyword "%t (name => keyword);" used),
    level => 'ebnf',
  },
  SYNTAX_MDC_FOR_COMMENT_REQUIRED => {
    description => q(mdc (>) required),
    level => 'ebnf',
  },
  SYNTAX_MDC_REQUIRED => {
    description => q(mdc (>) required),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_CONNECTOR_MATCH => {
    description => q(Connector "%t (name => new);" must be "%t (name => old);"),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_GRPC_REQUIRED => {
    description => q[grpc [)] required],
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_ITEM_REQUIRED => {
    description => q(Element type name or model group required),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_MIXED_CONNECTOR => {
    description => q(Connector "%t (name => connector);" cannot be used in mixed content model group; it must be or (|)),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_MIXED_NESTED => {
    description => q(Mixed content model group cannot have nested model group),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_MIXED_OCCUR => {
    description => q(Occurrence indicator for mixed content model group must be rep (*)),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_PCDATA_OCCUR => {
    description => q(Occurrence indicator for mixed content model group that only contains keyword "PCDATA" must be rep (*) if any),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_PCDATA_POSITION => {
    description => q(Keyword "PCDATA" not allowed here),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required),
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_REQUIRED => {
    description => q[GRPO [(] for model group required],
    level => 'ebnf',
  },
  SYNTAX_MODEL_GROUP_UNKNOWN_KEYWORD => {
    description => q(Unknown keyword "%t (name => keyword);"),
    level => 'ebnf',
  },
  SYNTAX_MSE => {
    description => q(GREATER-THAN SIGN (>) in "]]>" must be escaoed),
    level => 'MUST',
  },
  SYNTAX_MSE_REQUIRED => {
    description => q(MSE (]]>) required),
    level => 'ebnf',
  },
  SYNTAX_MSO_REQUIRED => {
    description => q(DSO ([) opening marked section content required),
    level => 'ebnf',
  },
  SYNTAX_MULTIPLE_COMMENT => {
    description => q(Multiple comment in one comment declaration not allowed),
    level => 'MUST NOT',
  },
  SYNTAX_MULTIPLE_DOCUMENT_ELEMENTS => {
    description => q(Multiple element cannot be the document (root) element),
    level => 'ebnf',
  },
  SYNTAX_NAMED_CHARACTER_REFERENCE => {
    description => q(Named character reference not allowed),
    level => 'ebnf',
  },
  SYNTAX_NAME_OR_DSO_OR_COM_REQUIRED => {
    description => q(Keyword or DSO ([) or COM (--) required),
    level => 'ebnf',
  },
  SYNTAX_NET_REQUIRED => {
    description => q(NET (>) required just after NESTC (/)),
    level => 'ebnf',
  },
  SYNTAX_NO_DOCUMENT_ELEMENT => {
    description => q(No document (root) element found),
    level => 'ebnf',
  },
  SYNTAX_NO_LESS_THAN_IN_ATTR_VAL => {
    description => q(LESS-THAN SIGN (<) not allowed in attribute value literal),
    level => 'MUST NOT',
  },
  SYNTAX_NOT_IN_CHAR => {
    description => q(Character %code-ucs (source => char); not included in document character set),
    level => 'ebnf',
  },
  SYNTAX_NOTATION_EXTERNAL_IDENTIFIER_REQUIRED => {
    description => q(External (public and/or system) identifier required),
    level => 'ebnf',
  },
  SYNTAX_NOTATION_NAME_REQUIRED => {
    description => q(Notation name required),
    level => 'ebnf',
  },
  SYNTAX_NOTATION_PS_REQUIRED => {
    description => q(One or more ps (whitespaces) required between parameters),
    level => 'ebnf',
  },
  SYNTAX_NUMERIC_CHAR_REF => {
    description => q(Numeric character reference not allowed),
    level => 'ebnf',
  },
  SYNTAX_PARAENT_NAME_REQUIRED => {
    description => q(Parameter entity name required),
    level => 'ebnf',
  },
  SYNTAX_PARAENT_REF_NOT_ALLOWED => {
    description => q(Parameter entity reference not allowed),
    level => 'ebnf',
  },
  SYNTAX_PARAMETER_REQUIRED => {
    description => q(Markup declaration parameter required),
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
  SYNTAX_PLITC_REQUIRED => {
    description => q(lit (") closing parameter literal required),
    level => 'ebnf',
  },
  SYNTAX_PLITAC_REQUIRED => {
    description => q(lita (') closing parameter literal required),
    level => 'ebnf',
  },
  SYNTAX_PROCESSING_INSTRUCTION_REQUIRED => {
    description => q(Processing instruction expected),
    level => 'ebnf',
  },
  SYNTAX_PS_COMMENT_NOT_ALLOWED => {
    description => q(Comment not allowed in parameter),
    level => 'ebnf',
  }, 
  SYNTAX_PUBID_LITERAL_INVALID_CHAR => {
    description => q(Public identifier literal cannot contains character "%t (name => char);"),
    level => 'ebnf',
  },
  SYNTAX_PUBID_LITERAL_REQUIRED => {
    description => q(Public identifier literal expected),
    level => 'ebnf',
  },
  SYNTAX_PUBLIC_ID => {
    description => q(Public identifier not allowed),
    level => 'ebnf',
  },
  SYNTAX_PUBLIT_MLITC_REQUIRED => {
    description => q(lit (") closing public identifier literal required),
    level => 'ebnf',
  },
  SYNTAX_PUBLIT_MLITAC_REQUIRED => {
    description => q(lita (') closing public identifier literal required),
    level => 'ebnf',
  },
  SYNTAX_REFC_REQUIRED => {
    description => q(refc (;) expected),
    level => 'MUST',
  },
  SYNTAX_REFERENCE_AMP_REQUIRED => {
    description => q(ero (&), cro (&#) or hcro (&#x) expected),
    level => 'ebnf',
  },
  SYNTAX_RESTRICTED_CHAR => {
    description => q(Character %code-ucs (source => char); cannot appear as is; it must be in character reference form),
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
  SYNTAX_SLITC_REQUIRED => {
    description => q(lit (") closing system literal required),
    level => 'ebnf',
  },
  SYNTAX_SLITAC_REQUIRED => {
    description => q(lita (') closing system literal required),
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
  SYNTAX_SYSTEM_ID => {
    description => q(System identifier not allowed),
    level => 'ebnf',
  },
  SYNTAX_SYSTEM_ID_REQUIRED => {
    description => q(System identifier required),
    level => 'ebnf',
  },
  SYNTAX_SYSTEM_LITERAL_REQUIRED => {
    description => q(System literal for system identifier required),
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
  SYNTAX_UNKNOWN_MARKUP_DECLARATION => {
    description => q(Markup declaration "%t (name => keyword);" not allowed),
    level => 'ebnf',
  },
  SYNTAX_VI_REQUIRED => {
    description => q(vi (=) expected),
    level => 'ebnf',
  },
  SYNTAX_X_OR_DIGIT_REQUIRED => {
    description => q("x" (for hex character reference) or DIGIT ([0-9]) required after "&#"),
    level => 'MUST',
  },
  SYNTAX_XML_DECLARATION_REQUIRED => {
    declaration => q(XML declaration required),
    level => 'MUST/1.1',
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
}}

=item Message::Markup::XML::Parser::Error::WFC

Well-formedness constraint violations and other fatal errors.

=cut

package Message::Markup::XML::Parser::Error::WFC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{  
  WFC_ELEMENT_TYPE_MATCH => {
    description => q(Element type name in end tag (%t (name => end-tag-type-name);) MUST match with that in start tag (%t (name => start-tag-type-name);)),
    level => 'wfc',
  },
  WFC_ENTITY_DECLARED => {
    description => q(Entity "%t (name => entity-name);" must be declared before referred in standalone document),
    level => 'wfc',
  },
  WFC_ENTITY_DECLARED__INTERNAL => {
    description => q(Entity "%t (name => entity-name);" must be declared within internal subset part of document entity),
    level => 'wfc',
  },
  # WFC_EXTERNAL_SUBSET
  # WFC_IN_DTD
  WFC_LEGAL_CHARACTER => {
    description => q(Character %code-ucs (source => char); is not in document character set),
    level => 'wfc',
  },
  WFC_NO_EXTERNAL_ENTITY_REFERENCES => {
    description => q(External entity (%t (name => entity-name);) cannot be referred in attribute value literal),
    level => 'wfc',
  },
  WFC_NO_LESS_THAN_IN_ATTR_VAL => {
    description => q(LESS-THAN SIGN (<) not allowed in replacement text of entity referred in attribute value literal),
    level => 'wfc',
  },
  WFC_NO_RECURSION => {
    description => q(Parsed entity "%t (name => entity-name);" cannot contain recursive reference to itself, either directly or indirectly),
    level => 'wfc',
  },
  WFC_PARSED_ENTITY => {
    description => q(Entity referred (%t (name => entity-name);) is unparsed entity),
    level => 'wfc',
  },
  # WFC_PE_BETWEEN_DECLARATIONS
  WFC_PES_IN_INTERNAL_SUBSET => {
    description => q(Parameter entity reference must not occur with in markup declaration in internal subset within document entity),
    level => 'wfc',
  },
  WFC_UNIQUE_ATT_SPEC => {
    description => q(Attribute "%t (name => attribute-name);" is already specified in this tag),
    level => 'wfc',
  },

  FATAL_CHARREF_IN_DTD => {
    description => q(Character reference is not allowed here),
    level => 'fatal error',
  },
  FATAL_GENTREF_IN_DTD => {
    description => q(General entity reference is not allowed here),
    level => 'fatal error',
  },
  FATAL_ILLEGAL_BYTE_SEQUENCE => {
    description => q(Illegal byte sequence found%t (name => msg, prefix => {: });),
    level => 'fatal error',
  },
  FATAL_NEW_NL_IN_XML_DECLARATION => {
    description => q(U+0085 (NEW LINE) or U+2028 (LINE SEPARATOR) cannot be used in XML or text declaration),
    level => 'fatal error',
  },
  FATAL_NO_ENCODING_INFORMATION => {
    description => q(No character encoding information available),
    level => 'fatal error',
  },
  FATAL_UNKNOWN_ENCODING => {
    description => q(Character encoding scheme "%t (name => charset);" is not implemented),
    level => 'fatal error',
  },
  SYNTAX_XML_DECLARATION_IN_MIDDLE => {
    description => q(Text declaration must be at exact first of external parsed entity),
    level => 'fatal error',
  },
}}

=item Message::Markup::XML::Parser::Error::VC

Validity constraint violations.

=cut

package Message::Markup::XML::Parser::Error::VC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
}}

=item Message::Markup::XML::Parser::Error::Error

Other (non-fatal) errors described in XML specifications.

=cut

package Message::Markup::XML::Parser::Error::Error;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
  ATTR_UNREAD_REF => {
    description => q(Reference to unread general entity found in attribute value literal),
    level => 'error',
  },
  GENTREF_TO_UNPARSED_IN_ENTITYVALUE => {
    description => q(Reference to unparsed general entity not allowed),
    level => 'error',
  },
  PREDEFINED_AMP => {
    description => q(General entity declaration for "amp" must have replacement text of a reference to AMPASAND (&)),
    level => 'MUST',
  },
  PREDEFINED_AMP_ESCAPE => {
    description => q(AMPASAND (&) in general entity declaration for "amp" must be escaped),
    level => 'REQUIRED',
  },
  PREDEFINED_APOS => {
    description => q(General entity declaration for "apos" must have replacement text of a APOSTROPHE (') or a reference to APOSTROPHE (')),
    level => 'MUST',
  },
  PREDEFINED_EXTERNAL => {
    description => q(Entity declaration for predefined entity must declare as internal entity),
    level => 'MUST',
  },
  PREDEFINED_GT => {
    description => q(General entity declaration for "gt" must have replacement text of a GERATER-THAN SIGN (>) or a reference to GREATER-THAN SIGN (>)),
    level => 'MUST',
  },
  PREDEFINED_LT => {
    description => q(General entity declaration for "lt" must have replacement text of a reference to LESS-THAN SIGN (<)),
    level => 'MUST',
  },
  PREDEFINED_LT_ESCAPE => {
    description => q(LESS-THAN SIGN (<) in general entity declaration for "lt" must be escaped),
    level => 'REQUIRED',
  },
  PREDEFINED_QUOT => {
    description => q(General entity declaration for "quot" must have replacement text of a QUOTATION MARK (") or a reference to QUOTATION MARK (")),
    level => 'MUST',
  },
  TEXT_DECLARATION_REQUIRED => {
    description => q(Text declaration required for external parsed entity that does not have external encoding information and that is not encoded in UTF-8 nor UTF-16),
    level => 'MUST',
  },
  UTF16_BOM => {
    description => q(External parsed entity encoded in UTF-16 must be begin with BOM),
    level => 'MUST',
  },
  XML_DECLARATION_REQUIRED => {
    description => q(XML declaration with "encoding" pseudo attribute required for external parsed entity that does not have external encoding information and that is not encoded in UTF-8 nor UTF-16),
    level => 'MUST',
  },
  XML_SPACE_TYPE => {
    description => q(Attribute type for "xml:space" must be either "(default|preserve)", "(default)" or "(preserve)"),
    level => 'MUST',
  },
  XML_SPACE_VALUE => {
    description => q(Attribute value of "xml:space" must be either "default" or "preserve"),
    level => 'error',
  },
}}

package Message::Markup::XML::Parser::Error::NSWFC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
}}

package Message::Markup::XML::Parser::Error::NSVC;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
}}

=item Message::Markup::XML::Parser::Error::W3C

Other recommendations referred in W3C documents.

=cut

package Message::Markup::XML::Parser::Error::W3C;
push our @ISA, 'Message::Markup::XML::Parser::Error';

sub ___error_def () {+{
  # DETERMINISTIC_CONTENT_MODEL
  DUPLICATE_ENUM_NMTOKEN => {
    description => q(Name token "%t (name => NMTOKEN);" already used in other attribute of element type "%t (name => element-type);"),
    level => 'SHOULD',
  },
  EMPTY_BUT_NOT_EMPTY_TAG => {
    description => q(Empty element tag syntax should be used for EMPTY element),
    level => 'SHOULD',
  },
  EMPTY_TAG_FOR_NON_EMPTY => {
    description => q(Empty element tag syntax should not be used for element type "%t (name => element-type);" that has been not declared as EMPTY),
    level => 'SHOULD',
  },
  ENCODING_NAME_UTF8 => {
    description => q(Encoding name "UTF-8" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_UTF16 => {
    description => q(Encoding name "UTF-16" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_UCS2 => {
    description => q(Encoding name "ISO-10646-UCS-2" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_UCS4 => {
    description => q(Encoding name "ISO-10646-UCS-4" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_ISO8859N => {
    description => q(Encoding name "ISO-8859-%t (name => iso8859-part);" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_ISO2022JP => {
    description => q(Encoding name "ISO-2022-JP" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_EUCJP => {
    description => q(Encoding name "EUC-JP" should be used),
    level => 'SHOULD',
  },
  ENCODING_NAME_SJIS => {
    description => q(Encoding name "Shift_JIS" should be used),
    level => 'SHOULD',
  },
  ENCODING_X_NAME => {
    description => q(Encoding name begin with "x-" prefix should be used),
    level => 'SHOULD',
  },
  FULLY_NORMALIZED_DOCUMENT => {
    description => q(XML 1.1 document should be fully normalized),
    level => 'SHOULD/1.1',
  },
  FULLY_NORMALIZED_PARSED_ENTITY => {
    description => q(Parsed entity should be fully normalized),
    level => 'SHOULD/1.1',
  },
  PREDEFINED_ENTITY => {
    description => q(Predefined entity "%t (name => entity-name);" should be declared before it is referred),
    level => 'SHOULD',
  },
  TEXT_DECLARATION_MISSING => {
    description => q(External parsed entity should begin with text declaration),
    level => 'SHOULD',
  },
  MODEL_GROUP_CONNECTOR_BEGIN => {
    description => q(Parameter entity referred in model group should not start with connector),
    level => 'SHOULD',
  },
  MODEL_GROUP_CONNECTOR_END => {
    description => q(Parameter entity referred in model group should not end with connector),
    level => 'SHOULD',
  },
  MODEL_GROUP_EMPTY => {
    description => q(Parameter entity referred in model group should not be empty),
    level => 'SHOULD',
  },
  XML_DECLARATION_MISSING => {
    description => q(Document entity should begin with XML declaration),
    level => 'SHOULD',
  },

  COLONED_NAME => {
    description => q(Name (%t (name => name);) should not contain COLON (:)),
    level => 'should',
  },

  RESERVED_ATTRIBUTE_NAME => {
    description => q(Attribute name "%t (name => attribute-name);" is reserved for XML specification),
    level => 'reserved',
  },
  RESERVED_ELEMENT_TYPE_NAME => {
    description => q(Element type name "%t (name => element-type-name);" is reserved for XML specification),
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
  RESERVED_NAME => {
    description => q(Name "%t (name => name);" is reserved by W3C),
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

  # ENCODING_IANAREG_NAME [recommended]
  AVOID_CONTROL_CHAR => {
    description => q(Control character %code-ucs (source => char); should not be used),
    level => 'encouraged',
  },
  AVOID_NONCHAR => {
    description => q(Noncharacter %code-ucs (source => char); should not be used),
    level => 'encouraged',
  },
  AVOID_UNICODE_COMPAT_CHAR => {
    description => q(Compatibility character %code-ucs (source => char); should not be used),
    level => 'encouraged',
  },
  LESS_THAN_ENTITY => {
    description=> q(General entity replacement text should not have bare LESS-THAN SIGN (<) character),
    level => 'strongly advised',
  },

  ATTLIST_ONE_PER_ATTR => {
    description => q(Multiple attribute definition found for attribute "%t (name => attribute-name);" of element type "%t (name => element-type);"),
    level => 'warn',
  },
  ATTLIST_ONE_PER_ELEMENT => {
    description => q(Multiple attribute definition list declaration found for element type "%t (name => element-type);"),
    level => 'warn',
  },
  GENERAL_ENTITY_NAME_USED => {
    description => q(General entity "%t (name => entity-name);" is already declared),
    level => 'warn',
  },
  PARAM_ENTITY_NAME_USED => {
    description => q(Parameter entity "%t (name => entity-name);" is already declared),
    level => 'warn',
  },

  # 1.1 Name suggestion
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

1; # $Date: 2004/06/22 07:36:20 $
