
=head1 NAME

Message::Markup::XML::DOM --- manakai: Simple DOM implementation for Message::Markup::XML

=head1 DESCRIPTION

...

This module is part of manakai.

=cut

package Message::Markup::XML::DOM;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Markup::XML;
require SuikaWIki::Markup::XML::DOM::Core;

our %Feature = (
	core	=> {
		'2.0'	=> {
			implemented	=> 0,
		},
	},
	'cx.fam.suika.wiki.markup.xml.dom'	=> {
		'1.0'	=> {
			implemented	=> 1,
		},
	},
);

=head1 METHODS

WARNING: This module is under construction.  Interface of this module is not yet fixed.

=cut

package Message::Markup::XML::DOM::DOMString;
use overload '""' => \&_get_value,
             '.=' => \&_append_value,
             fallback => 1;
our $UseEncode = 1;
if ($^V <= v5.7.3) {
  $UseEncode = 0;	## Use of Encode is strongly recommended!
} else {
  require Encode;
}

sub _new ($) {
  bless {}, shift;
}

sub _set_value ($$) {
  $_[0]->{value} = $_[1];
  $_[0];
}
sub _append_value ($$) {
  $_[0]->{value} .= $_[1];
  $_[0];
}
sub _get_value ($) {
  $_[0]->{value};
}

sub _to_utf16 ($$) {
  my ($self, $s) = @_;
  if ($UseEncode) {
    return Encode::encode ('UTF-16BE', $s);
  } else {
    $s =~ s/(.)/\x00$1/gs;
    return $s;
  }
}
sub _from_utf16 ($$) {
  my ($self, $s) = @_;
  if ($UseEncode) {
    return Encode::decode ('UTF-16BE', $s);
  } else {
    $s =~ s/\x00(.)/$1/gs;
    return $s;
  }
}

package Message::Markup::XML::DOM::DOMString::utf16;
push @Message::Markup::XML::DOM::DOMString::ISA, __PACKAGE__;

sub getValue ($) {
  my $self = shift;
  $self->_to_utf16 ($self->{value});
}
sub setValue ($$) {
  my ($self, $value) = @_;
  $self->{value} = $self->_from_utf16 ($value);
}

package Message::Markup::XML::DOM::_util;
push @Message::Markup::XML::DOM::ISA, __PACKAGE__;
push @Message::Markup::XML::DOM::Core::Node::ISA, __PACKAGE__;
use Char::Class::XML qw/InXMLNCNameChar InXML_NCNameStartChar/;

sub _check_qname ($$) {
  my ($self, $name) = @_;
  if ($name =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*(?::\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*)?$/) {
    return 1;
  } else {
    return 0;
  }
}

sub _check_ncname ($$) {
  my ($self, $name) = @_;
  if ($name =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/) {
    return 1;
  } else {
    return 0;
  }
}

sub _check_ns ($$$) {
  my ($self, $prefix, $uri) = @_;
  if ($prefix eq 'xml') {
    return $uri eq $self->_NS->{xml} ? 1 : 0;
  } elsif ($prefix eq 'xmlns') {
    return $uri eq $self->_NS->{xmlns} ? 1 : 0;
  } else {
    return 0 if $uri eq $self->_NS->{xml} || $uri eq $self->_NS->{xmlns};
  }
  return 1;
}

## TODO: rewrite
sub _raise_exception ($$$;%) {
  my ($self, $exceptClass, $exception, %p) = @_;
  if ($exception=~/WARNING/) {
    warn "${exceptClass}::$exception ($p{t})";
  } else {
    die "${exceptClass}::$exception ($p{t})";
  }
}


sub _NS ($) {{
	SGML	=> 'urn:x-suika-fam-cx:markup:sgml:',
	internal_ns_invalid	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#',
	internal_attr_duplicate	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/invalid-attr#',
	xml	=> 'http://www.w3.org/XML/1998/namespace',
	xmlns	=> 'http://www.w3.org/2000/xmlns/',
}}

sub _create_dom_node_from_node_object ($$$;%) {
  my ($self, $nodeObject, %o) = @_;
  my $no = $nodeObject->flag ('dom_node_object');
  return $no if $no;
  $no = bless {}, 'Message::Markup::XML::DOM::Core::'.({
  	'#attribute'	=> 'Attr',
  	'#element'	=> 'Element',
  	'#text'	=> 'Text',
  }->{$nodeObject->node_type}||'Node');
  $no->{flag}->{dom_ownerDocument} = $self->{flag}->{dom_ownerDocument};
  $no->{nodeObject} = $nodeObject;
  $nodeObject->flag (dom_node_object => $no);
  ## TODO: default attr should be automatically created
  $no;
}

## TODO: Message::Markup::XML::Error
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
	SYNTAX_INVALID_CHAR	=> {
		description	=> 'Invalid character (%s) at this context',
		level	=> 'wfc',
	},
	SYNTAX_INVALID	=> {
		description	=> 'This type of markup (%s) cannot appear here',
		level	=> 'wfc',
	},
	SYNTAX_INVALID_DOCTYPE_POSITION	=> {
		description	=> 'DOCTYPE declaration must be between xml declaration and the root element',
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
	WFC_LEGAL_CHARACTER	=> {
		description	=> sub {
			my $r = sprintf 'The character referred (U-%08X) is not a legal XML Char',
			        $_[1]->{t};
			$_[1]->{t} = undef;
			$r;
		},
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
	## Namespace well-formedness error
	NC_PREFIX_NOT_DEFINED	=> {
		description	=> 'Undeclared namespace prefix (%s) is used',
		level	=> 'nc',
	},
	## Namespace validity error
	## Misc
	UNKNOWN	=> {
		description	=> 'Unknown error',
		level	=> 'wfc',
	},
);
## TODO: error handling should be customizable (hookable) by user of this module
sub _raise_error ($$%) {
  my ($self, $o, %err) = @_;
  my $error_type = $_Error{$err{type}} || $_Error{UNKNOWN};
  my $error_msg = ref $error_type->{description} ? &{$error_type->{description}} ($o, \%err)
                                                 : $error_type->{description};
  my @err_msg;
  ref $err{t} eq 'ARRAY' ? @err_msg = @{$err{t}} : defined $err{t} ? @err_msg = $err{t} : undef;
  $error_msg .= ' (%s)' if scalar (@err_msg) && ($error_msg !~ /%s/);
  $error_msg = sprintf $error_msg, @err_msg;
  require Carp;
  Carp::carp ("Line $o->{line}, position $o->{pos}: ".$error_msg);
  #Carp::croak ("Line $o->{line}, position $o->{pos}: ".$error_msg);
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/09/07 03:09:18 $
