
=head1 NAME

SuikaWiki::Markup::XML::Error --- SuikaWiki XML: Error handling module for SuikaWiki::Markup::XML::*

=head1 DESCRIPTION

This module provides the common error and/or warning handling interface
for the SuikaWiki::Markup::XML::* modules.  With this module, proper error
recovering and proper message outputing (eg. output as HTML element,
localized message, etc.) is easily implementable.

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

## Prefixes:
## - 'SYNTAX_':	don't match with XML 1.0 EBNF rules
## - 'WFC_':	violation of well-formedness constraint (fatal error)
## - 'VC_':	violation of validity constraint (error)
## - 'NC_':	violation of namespace constraint (error)
## - 'NS_SYNTAX_':	don't match with XML Namespace 1.0 EBNF rules (error)
## - 'FATAL_ERR_':	fatal error specified by XML 1.0 spec
## - 'ERR_':	error specified by XML 1.0 spec
## - 'WARN_':	don't fullfil XML spec's or implementor's recommendation

## Error levels:
## - wfc:	well-formedness (including syntax error)
## - vc:	validity
## - nswfc:	namespace well-formedness
## - nsvc:	namespace validity
## - fatal:	fatal error
## - warn:	warning

my %_Error = (
	## Forward compatibility error
	SYNTAX_UNSUPPORTED_XML_VERSION	=> {
		description	=> 'Unsupported XML version (%s)',
		level	=> 'wfc',
	},
	## Syntax errors
	SYNTAX_ATTR_LITERAL_NOT_FOUND	=> {
		description	=> 'Attribute value literal of the attribute (name = %s) is expected',
		level	=> 'wfc',
	},
	SYNTAX_ATTR_NAME_OMITTED	=> {
		description	=> 'Attribute name corresponding to the value (%s) must be specified in XML',
		level	=> 'wfc',
	},
	SYNTAX_DATA_OUT_OF_ROOT_ELEMENT	=> {
		description	=> 'Invalid data or markup out of root element',
		level	=> 'wfc',
	},
	SYNTAX_DOCTYPE_NAME_NOT_FOUND	=> {
		description	=> 'Document type name must be specified in the document type declaration',
		level	=> 'wfc',
	},
	SYNTAX_DOCTYPE_PID_LITERAL_NOT_FOUND	=> {
		description	=> 'Minimum literal for the public identifier must follow the keyword PUBLIC',
		level	=> 'wfc',
	},
	SYNTAX_DOCTYPE_SYSID_LITERAL_NOT_FOUND	=> {
		description	=> 'Literal of the system identifier must follow the keyword SYSTEM or the minimum literal of the public identifier in XML',
		level	=> 'wfc',
	},
	SYNTAX_END_OF_MARKUP_NOT_FOUND	=> {
		description	=> sub {
			my ($o, $err) = @_;
			my $o_start = $err->{t}->flag ('p_o_start');
			my $r = $err->{t}->qname;
			$r = sprintf 'line %d, position %d%s', $o_start->{line},
			             $o_start->{pos}, ($r ? '; '.$r : '') if ref $o_start;
			$r ? $r = '; '.$r : 0;
			$err->{t} = $err->{t}->node_type;
			'Markup is not closed (%s'.$r.')';
		},
		level	=> 'wfc',
	},
	SYNTAX_END_TAG_NOT_FOUND	=> {
		description	=> sub {
			my ($o, $err) = @_;
			my $o_start = $err->{t}->flag ('p_o_start');
			my $r = '';
			$r = sprintf 'line %d, position %d%s', $o_start->{line},
			             $o_start->{pos}, ($r ? '; '.$r : '') if ref $o_start;
			$r ? $r = '; '.$r : 0;
			$err->{t} = $err->{t}->qname;
			'End tag of element (type = %s'.$r.') not found';
		},
		level	=> 'wfc',
	},
	SYNTAX_INVALID	=> {
		description	=> 'This type of markup (%s) cannot appear here',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_CHAR	=> {
		description	=> 'Invalid character (%s) at this context',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_DOCTYPE_POSITION	=> {
		description	=> 'DOCTYPE declaration must be between xml declaration and the root element',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_KEYWORD	=> {
		description	=> 'Invalid keyword (%s) at this context',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_LITERAL	=> {
		description	=> 'Literal cannot be here ("%s")',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_MD	=> {
		description	=> 'Invalid syntax of markup declaration',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_POSITION	=> {
		description	=> sub {
			my ($o) = shift;
				'This type of markup (%s) cannot be used '.({
  				document_entity 	=> 'out of DTD',
  				dtd_internal_subset	=> 'in the internal subset of DTD',
  				dtd_external_subset	=> 'in the external subset of DTD',
  				external_parsed_entity	=> 'in the external parsed entity',
  				general_external_parsed_entity	=> 'in the general external parsed entity',
  			}->{$o->{entity_type}||'document_entity'}||'in '.$o->{entity_type})},
		level	=> 'wfc',
	},
	SYNTAX_INVALID_PUBID	=> {
		description	=> 'This public identifier contains at least one invalid character (%s)',
		level	=> 'wfc',
	},
	SYNTAX_LEGAL_CHARACTER	=> {
		description	=> sub {
			my $r = sprintf 'The character U-%08X is not a legal XML Char',
			        $_[1]->{t};
			$_[1]->{t} = undef;
			$r;
		},
		level	=> 'wfc',
	},
	SYNTAX_MD_NAME_NOT_FOUND	=> {
		description	=> 'Name is required by this type of declaration',
		level	=> 'wfc',
	},
	SYNTAX_MD_SYSID_NOT_FOUND	=> {
		description	=> 'System identifier is required by this type of declaration',
		level	=> 'wfc',
	},
	SYNTAX_MS_IN_INTERNAL_SUBSET	=> {
		description	=> 'Marked section cannot be used in the internal subset of the DTD in XML',
		level	=> 'wfc',
	},
	SYNTAX_MS_INVALID_STATUS_STRING	=> {
		description	=> 'Invalid string in the status keyword list',
		level	=> 'wfc',
	},
	SYNTAX_MS_MULTIPLE_STATUS	=> {
		description	=> 'Multiple status keyword (%s) cannot be used',
		level	=> 'wfc',
	},
	SYNTAX_MS_NO_STATUS_KEYWORD	=> {
		description	=> 'No status keyword found',
		level	=> 'wfc',
	},
	SYNTAX_MS_NON_XML_STATUS	=> {
		description	=> 'This status keyword (%s) cannot be used in XML',
		level	=> 'wfc',
	},
	SYNTAX_MS_UNKNOWN_STATUS	=> {
		description	=> 'Unknown status keyword (%s) is used',
		level	=> 'wfc',
	},
	SYNTAX_PE_NDATA	=> {
		description	=> 'Parameter entity must be a parsed entity',
		level	=> 'wfc',
	},
	SYNTAX_ROOT_ELEMENT_NOT_FOUND	=> {
		description	=> 'There is no root element (type = %s) in this document entity',
		level	=> 'wfc',
	},
	SYNTAX_TAG_NOT_CLOSED	=> {
		description	=> 'Tag must be closed in XML',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE	=> {
		description	=> 'Syntax of XML (or text) declaration is invalid',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_NO_ATTR	=> {
		description	=> 'XML (or text) declaration has no (valid) pseudo attribute',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_NO_ENCODING_ATTR	=> {
		description	=> q(Text declaration must have 'encoding' pseudo attribute),
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_NO_VERSION_ATTR	=> {
		description	=> q(XML declaration must have 'version' pseudo attribute),
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_POSITION	=> {
		description	=> 'XML declaration must be at the top of the entity',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_STANDALONE_ATTR	=> {
		description	=> q(Text declaration cannot have 'standalone' pseudo attribute),
		level	=> 'wfc',
	},
	## Well-formedness error
	WFC_ELEMENT_TYPE_MATCH	=> {
		description	=> 'End tag (type = %s) does not match with start tag (type = %s)',
		level	=> 'wfc',
	},
	WFC_ENTITY_DECLARED	=> {
		description	=> 'Entity (%s) must be declared before it is referred',
		level	=> 'wfc',
	},
	WFC_LEGAL_CHARACTER	=> {
		description	=> sub {
			my $r = sprintf 'The character referred (U-%08X) is not a legal XML Char',
			        $_[1]->{t};
			$_[1]->{t} = undef;
			$r;
		},
		level	=> 'wfc',
	},
	WFC_NO_EXTERNAL_ENTITY_REFERENCE	=> {
		description	=> 'Attribute value must not contain reference to an external entity',
		level	=> 'wfc',
	},
	WFC_NO_LE_IN_ATTRIBUTE_VALUE	=> {
		description	=> 'Attribute value must not contain a less-than sign (<)',
		level	=> 'wfc',
	},
	WFC_NO_RECURSION	=> {
		description	=> 'Parsed entity (%s) must not contain a recursive reference to itself',
		level	=> 'wfc',
	},
	WFC_NO_LT_IN_ATTRIBUTE_VALUE	=> {
		description	=> 'Replacement text of entity reference in an attribute value literal cannot contain LESS-THAN SIGN (<) itself',
		level	=> 'wfc',
	},
	WFC_PARSED_ENTITY	=> {
		description	=> 'Entity reference (%s) must not refer non-parsed entity',
		level	=> 'wfc',
	},
	WFC_PE_IN_INTERNAL_SUBSET	=> {
		description	=> 'Parameter entity (%s) cannot be referred in markup declaration in internal subset of DTD',
		level	=> 'wfc',
	},
	WFC_UNIQUE_ATT_SPEC	=> {
		description	=> 'Dupulicate attribute specification',
		level	=> 'wfc',
	},
	FATAL_ERR_DECODE_IMPL_ERR	=> {
		description	=> 'Decode error (%s)',
		level	=> 'fatal',
	},
	FATAL_ERR_PREDEFINED_ENTITY	=> {
		description	=> 'Predefined entity (%s := %s) must be declared as of the XML specification defined',
		level	=> 'fatal',
	},
	## Validity error
	VC_ENTITY_DECLARED	=> {
		description	=> 'Entity %s should (or must to be valid) be declared before it is referred',
		level	=> 'vc',
	},
	VC_NOTATION_DECLARED	=> {
		description	=> 'Notation %s should (or must to be valid) be declared',
		level	=> 'vc',
	},
	VC_ROOT_ELEMENT_TYPE	=> {
		description	=> 'Document type name (%s) and element type name of the root element (%s) should (or must to be valid) match',
		level	=> 'vc',
	},
	VC_UNIQUE_NOTATION_NAME	=> {
		description	=> 'Notation %s is already declared',
		level	=> 'warn',
	},
	## Namespace well-formedness error
	NS_SYNTAX_LNAME_IS_NCNAME	=> {
		description	=> 'Character just after the colon (:) in QName (%s) must be one of NameStartChar in namespaced XML document',
		level	=> 'nswfc',
	},
	NC_PREFIX_NOT_DEFINED	=> {
		description	=> 'Undeclared namespace prefix (%s) is used',
		level	=> 'nswfc',
	},
	NS_SYNTAX_NAME_IS_NCNAME	=> {
		description	=> 'Name with colon (%s) cannot be used here in namespaced XML document',
		level	=> 'nswfc',
	},
	NS_SYNTAX_NAME_IS_QNAME	=> {
		description	=> 'Name with colon (%s) must match with QName in namespaced XML document',
		level	=> 'nswfc',
	},
	NC_UNIQUE_ATT_SPEC	=> {
		description	=> 'Dupulicate attribute specification (%s == <%s>:%s)',
		level	=> 'wfc',
	},
	## Namespace validity error
	## XML (non-fatal) error
	ERR_EXT_ENTITY_NOT_FOUND	=> {
		description	=> 'External entity (%s == <%s>) cannot be retrived (%s)',
		level	=> 'vc',
	},
	ERR_XML_NDATA_REF_IN_ENTITY_VALUE	=> {
		description	=> 'Unparsed entity (%s) cannot be referred in EntityValue',
		level	=> 'warn',	## Was fatal error but refined by SE Errata
	},
	ERR_XML_SYSID_HAS_FRAGMENT	=> {
		description	=> 'URI Reference converted from system identifier should not have the fragment identifier (%s)',
		level	=> 'warn',
	},
	## XML warning
	WARN_PREDEFINED_ENTITY_NOT_DECLARED	=> {
		description	=> 'Predefined general entity (%s) should be declared before it is referred for interoperability',
		level	=> 'warn',
	},
	WARN_UNICODE_COMPAT_CHARACTER	=> {
		description	=> sub {
			my $r = sprintf 'Use of the character U+%04X is deprecated, since it is classified as compatible character in the Unicode Standard',
			        $_[1]->{t};
			$_[1]->{t} = undef;
			$r;
		},
		level	=> 'warn',
	},
	WARN_UNICODE_NONCHARACTER	=> {
		description	=> sub {
			my $r = sprintf 'Use of the code point U+%04X is deprecated, since it is noncharacter in the Unicode Standard',
			        $_[1]->{t};
			$_[1]->{t} = undef;
			$r;
		},
		level	=> 'warn',
	},
	WARN_UNICODE_XML_NOT_SUITABLE_CHARACTER	=> {
		description	=> sub {
			my $r = sprintf 'Use of the character U+%04X is deprecated by W3C Note unicode-xml',
			        $_[1]->{t};
			$_[1]->{t} = undef;
			$r;
		},
		level	=> 'warn',
	},
	WARN_UNIQUE_ENTITY_NAME	=> {
		description	=> 'General entity %s is already declared',
		level	=> 'warn',
	},
	WARN_UNIQUE_PARAMETER_ENTITY_NAME	=> {
		description	=> 'Parameter entity %s is already declared',
		level	=> 'warn',
	},
	## XMLName recommendation
	WARN_XML_NS_URI_IS_RELATIVE	=> {
		description	=> 'URI of XML Namespace name is a relative URI',
		level	=> 'warn',
	},
	## RFC 3023 'SHOULD'
	WARN_MT_DTD_EXTERNAL_SUBSET	=> {
		description	=> q(Media type "application/xml-dtd" SHOULD be used for the external subset of the DTD or the external parameter entity),
		level	=> 'warn',
	},
	WARN_MT_EXTERNAL_GENERAL_PARSED_ENTITY	=> {
		description	=> q(Media type "application/xml-external-parsed-entity" SHOULD be used for the external general parsed entity),
		level	=> 'warn',
	},
	WARN_MT_XML_FOR_EXT_GENERAL_ENTITY	=> {
		description	=> 'Using media type %s for external general parsed entity is now forbidden unless the entity is also well-formed as a document entity',
		level	=> 'warn',
	},
	## Implementation's warning
	WARN_DOCTYPE_NOT_FOUND	=> {
		description	=> 'No document type definition provided for this document',
		level	=> 'warn',
	},
	WARN_ENTITY_DECLARATION_NOT_PROCESSED	=> {
		description	=> 'This entity declaration is not processed because unread parameter entity is referred before this declaration',
		level	=> 'warn',
	},
	WARN_EXTERNALLY_DEFINED_ENTITY_REFERRED	=> {
		description	=> 'The entity referred (%s) is declared in the external entity, so different groove can be constructed when external entity is not read',
		level	=> 'warn',
	},
	WARN_GUESS_ENCODING_IMPL_ERR	=> {
		description	=> 'Guessing encoding procedure cause some error (%s)',
		level	=> 'warn',
	},
	WARN_INVALID_URI_CHAR_IN_NS_NAME	=> {
		description	=> 'URI of XML Namespace name contains at least one non-URI character',
		level	=> 'warn',
	},
	WARN_INVALID_URI_CHAR_IN_SYSID	=> {
		description	=> 'System identifier has at least one character that is invalid as part of URI Reference (%s)',
		level	=> 'warn',
	},
	WARN_MT_TEXT_XML	=> {
		description	=> q(In many case, labeling with the media type "text/xml" is inappropriate.  Use "application/xml" or markup language specified type instead),
		level	=> 'warn',
	},
	WARN_MT_TEXT_XML_EXTERNAL_PARSED_ENTITY	=> {
		description	=> q(In many case, labeling with the media type "text/xml-external-parsed-entity" is inappropriate.  Use "application/xml-external-parsed-entity" instead),
		level	=> 'warn',
	},
	WARN_NO_CHARSET_PARAM	=> {	## charset parameter is optional
		description	=> 'Charset parameter should be specified (%s)',
		level	=> 'warn',
	},
	WARN_NO_CHARSET_PARAM_FOR_TEXT	=> {	## charset parameter have default value of ascii
		description	=> q(Charset parameter is not specified, so default value 'us-ascii' is assumed (%s)),
		level	=> 'warn',
	},
	WARN_NO_EXPLICIT_ENCODING_INFO	=> {	## BOM and '<?' guessing is failed (so general encoding guess is to be called)
		description	=> q(Neither upper level protocol nor XML's encoding declaration provide encoding scheme information (or cannot read the encoding declaration because of lack of guessability)),
		level	=> 'warn',
	},
	WARN_PI_TARGET_NOTATION	=> {
		description	=> 'Target name of the process instruction (%s) should be declared as a notation name to ensure interoperability',
		level	=> 'warn',
	},
	WARN_PID_EMPTY	=> {
		description	=> 'Public identifier is empty',
		level	=> 'warn',
	},
	WARN_PID_IS_INVALID_URN	=> {
		description	=> 'Public identifier (%s) seems an invalid URN',
		level	=> 'warn',
	},
	WARN_PID_IS_NOT_FPI_NOR_URN	=> {
		description	=> 'Public identifier (%s) should be a formal public identifier or a uniform resource name to ensure interoperability',
		level	=> 'warn',
	},
	WARN_PID_IS_TOO_LONG	=> {
		description	=> 'Public identifier (%s) should be shorter for interoperability',
		level	=> 'warn',
	},
	WARN_PID_IS_URN_WITH_RESERVED_CHAR	=> {
		description	=> 'Public identifier (%s) seems a URN and it contains one or more reserved character ("/" and/or "?") which should not be used',
		level	=> 'warn',
	},
	WARN_SYSID_EMPTY	=> {
		description	=> 'System identifier is empty, in most case it is wrong',
		level	=> 'warn',
	},
	WARN_XML_DECLARE_NO_VERSION_ATTR	=> {
		description	=> 'Text declaration does not have the version pseudo attribute',
		level	=> 'warn',
	},
	## Misc
	UNKNOWN	=> {
		description	=> 'Unknown error',
		level	=> 'fatal',
	},
);
## TODO: error handling should be customizable (hookable) by user of this module
sub raise ($$%) {
  my (undef, $o, %err) = @_;
  my $error_type = $_Error{$err{type}} || $_Error{UNKNOWN};
  my $error_msg = ref $error_type->{description} ? &{$error_type->{description}} ($o, \%err)
                                                 : $error_type->{description};
  my @err_msg;
  ref $err{t} eq 'ARRAY' ? @err_msg = @{$err{t}} : defined $err{t} ? @err_msg = $err{t} : undef;
  $error_msg .= ' (%s)' if scalar (@err_msg) && ($error_msg !~ /%s/);
  $error_msg = sprintf $error_msg, @err_msg;
  $error_msg = "Line $o->{line}, position $o->{pos}: " . $error_msg;
  $error_msg = 'Entity '.($err{entity}||$o->{entity}) . ": " . $error_msg if ($err{entity}||$o->{entity});
  $error_msg = '<'.($o->{uri}) . ">: " . $error_msg ;#if defined $o->{uri};
  require Carp;
  Carp::carp ($error_msg);
  #Carp::croak ("Line $o->{line}, position $o->{pos}: ".$error_msg);
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/06/30 11:06:28 $
