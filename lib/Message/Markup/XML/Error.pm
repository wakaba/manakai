
=head1 NAME

SuikaWiki::Markup::XML::Error --- SuikaWiki XML: Error handling module for SuikaWiki::Markup::XML::*

=head1 DESCRIPTION

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::Error;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

my %_Error = (
	## Syntax errors
	SYNTAX_DATA_OUT_OF_ROOT_ELEMENT	=> {
		description	=> 'Invalid data or markup out of root element',
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
	SYNTAX_PE_NDATA	=> {
		description	=> 'Parameter entity must be a parsed entity',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE	=> {
		description	=> 'Syntax of XML (or text) declaration is invalid',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_NO_ATTR	=> {
		description	=> 'XML (or text) declaration does not have pseudo attribute',
		level	=> 'wfc',
	},
	SYNTAX_XML_DECLARE_POSITION	=> {
		description	=> 'XML declaration must be at the top of the entity',
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
	WFC_PE_IN_INTERNAL_SUBSET	=> {
		description	=> 'Parameter entity (%s) cannot be referred in markup declaration in internal subset of DTD',
		level	=> 'wfc',
	},
	WFC_UNIQUE_ATT_SPEC	=> {
		description	=> 'Dupulicate attribute specification',
		level	=> 'wfc',
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
	VC_UNIQUE_NOTATION_NAME	=> {
		description	=> 'Notation %s is already declared',
		level	=> 'warn',
	},
	## Namespace well-formedness error
	NC_PREFIX_NOT_DEFINED	=> {
		description	=> 'Undeclared namespace prefix (%s) is used',
		level	=> 'nswfc',
	},
	NS_SYNTAX_NAME_IS_NCNAME	=> {
		description	=> 'Name with colon (%s) cannot be used within namespaced XML document',
		level	=> 'nswfc',
	},
	## Namespace validity error
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
	## Implementation's warning
	## Misc
	UNKNOWN	=> {
		description	=> 'Unknown error',
		level	=> 'wfc',
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
  require Carp;
  Carp::carp ($error_msg);
  #Carp::croak ("Line $o->{line}, position $o->{pos}: ".$error_msg);
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/06/16 09:58:26 $
