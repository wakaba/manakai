
=head1 NAME

SuikaWiki::Markup::XML::Validate --- SuikaWiki XML: XML Validator

=head1 DESCRIPTION

This module provides validator facilities for XML document.
With SuikaWiki::Markup::XML::Parser, it is possible to validate
an XML document.

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::Validate;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require SuikaWiki::Markup::XML::Parser;
our (%NS);
*NS = \%SuikaWiki::Markup::XML::NS;
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar!;
my %xml_re = (
	Name	=> qr/\p{InXML_NameStartChar}\p{InXMLNameChar}*/,
	_s__chars	=> qr/\x09\x0A\x0D\x20/s,
);

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  require SuikaWiki::Markup::XML::Error;
  $self->{error} = SuikaWiki::Markup::XML::Error->new ({
    ## Validity error
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAME	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a valid Name',
    	level	=> 'vc',
    },
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAMES	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a list of valid Names',
    	level	=> 'vc',
    },
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKEN	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a valid NMToken',
    	level	=> 'vc',
    },
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKENS	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a list of valid NMTokens',
    	level	=> 'vc',
    },
    VC_ATTR_DECLARED	=> {	## VC: Attribute Value Type
    	description	=> 'Attribute "%s" should (or must to be valid) be declared',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_DECLARED	=> {
    	description	=> 'Element type "%s" should (or must to be valid) be declared',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_MIXED	=> {
    	description	=> 'Element type "%s" cannot come here by definition',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_CDATA	=> {
    	description	=> 'In element content, character data (other than S) cannot be written',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_MATCH	=> {
    	description	=> 'Element (type = "%s") does not match to content model',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_REF	=> {
    	description	=> 'In element content, entity or character reference cannot be used',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_SECTION	=> {
    	description	=> 'In element content, marked section cannot be used',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_EMPTY	=> {
    	description	=> 'Content must be empty, i.e. no element, comment, PCDATA nor markup declaration can be contained',
    	level	=> 'vc',
    },
    VC_ENUMERATION	=> {
    	description	=> 'Attribute value "%s" must match one of name token defined in ATTLIST declaration',
    	level	=> 'vc',
    },
    VC_FIXED_ATTR_DEFAULT	=> {
    	description	=> 'Attribute value "%s" must match the default value ("%s")',
    	level	=> 'vc',
    },
    VC_ID_ATTR_DEFAULT	=> {
    	description	=> 'ID attribute (%s/@%s) cannot have its default value',
    	level	=> 'vc',
    },
    VC_ID_SYNTAX	=> {
    	description	=> 'Value of ID attribute ("%s") must be a valid Name',
    	level	=> 'vc',
    },
    VC_ID_UNIQUE	=> {
    	description	=> 'Value of ID attribute ("%s") must be unique in the document',
    	level	=> 'vc',
    },
    VC_IDREF_MATCH	=> {
    	description	=> 'Value of IDREF/IDREFS attribute ("%s") must be match one of ID specified in the document',
    	level	=> 'vc',
    },
    VC_IDREF_SYNTAX	=> {
    	description	=> 'Value of IDREF attribute ("%s") must be a valid Name',
    	level	=> 'vc',
    },
    VC_NAME_TOKEN_NNTOKEN	=> {
    	description	=> 'NMTOKEN attribute value "%s" must be consist only of Name characters',
    	level	=> 'vc',
    },
    VC_NAME_TOKEN_NMTOKENS	=> {
    	description	=> 'NMTOKENS attribute value "%s" must be a whitespace separated list of NMTOKENs',
    	level	=> 'vc',
    },
    VC_NO_NOTATION_ON_EMPTY_ELEMENT	=> {
    	description	=> 'For compatibility, NOTATION attribute (%s) cannot be declared on EMPTY element type (%s)',
    	level	=> 'vc',
    },
    VC_NOTATION_ATTR_DECLARED	=> {
    	description	=> 'Notation "%s" should (or must to be valid) be declared',
    	level	=> 'vc',
    },
    VC_NOTATION_ATTR_ENUMED	=> {
    	description	=> 'Notation "%s" must be included in group of the declaration',
    	level	=> 'vc',
    },
    VC_NOTATION_DECLARED	=> {
    	description	=> 'Notation "%s" should (or must to be valid) be declared',
    	level	=> 'vc',
    },
    VC_NOTATION_SYNTAX	=> {
    	description	=> 'Value of NOTATION attribute ("%s") must be a valid Name',
    	level	=> 'vc',
    },
    VC_ONE_ID_PER_ELEMENT_TYPE	=> {
    	description	=> 'ID attribute is already declared (Invalid: %s/@%s, Declared: @%s)',
    	level	=> 'vc',
    },
    VC_ONE_NOTATION_PER_ELEMENT_TYPE	=> {
    	description	=> 'NOTATION attribute is already declared (Invalid: %s/@%s, Declared: @%s)',
    	level	=> 'vc',
    },
    VC_REQUIRED_ATTR	=> {
    	description	=> 'Required attribute %s/@%s must be specified',
    	level	=> 'vc',
    },
    ## Namespace validity error
    VALID_NS_NAME_IS_NCNAME	=> {
    	description	=> 'Name with colon ("%s") cannot be used here in namespaced XML document',
    	level	=> 'nsvc',
    },
    ## XML spec. warning
    WARN_XML_ATTLIST_AT_MOST_ONE_ATTR_DEF	=> {
    	description	=> 'For interoperability, at most one definition for given attribute (%s/@%s) should be provided',
    	level	=> 'warn',
    },
    WARN_XML_ATTLIST_ELEMENT_DECLARED	=> {
    	description	=> 'Element type "%s" should be declared',
    	level	=> 'warn',
    },
    WARN_XML_ATTLIST_UNIQUE_ENUM_TOKEN	=> {
    	description	=> 'For interoperability, same enumeration token should not be used in an element type (%s/@*="%s")',
    	level	=> 'warn',
    },
    WARN_XML_EMPTY_NET	=> {
    	description	=> 'For interoperability, NET (EmptyElemTag) syntax should be used for mandatorlly empty element',
    	level	=> 'warn',
    },
    WARN_XML_NON_EMPTY_NET	=> {
    	description	=> 'For interoperability, NET (EmptyElemTag) syntax should not be used other than for mandatorlly empty element',
    	level	=> 'warn',
    },
    ## Implementation-defined warning
    WARN__PI_TARGET_NOTATION	=> {
    	description	=> 'Target name of the process instruction ("%s") should be declared as a notation name to ensure interoperability',
    	level	=> 'warn',
    },
    ## Misc.
    UNKNOWN	=> {
    	description	=> q(Unknown error (%s)),
    	level	=> q(fatal),
    },
    -error_handler => $self->{option}->{error_handler} || sub {
      my ($self, $node, $error_type, $error_msg, $err) = @_;
      return 1;
    },
  });
  $self;
}

sub validate ($$;%) {
  my ($self, $node, %opt) = @_;
  unless ($opt{entMan}) {
    $opt{entMan} = $node->_get_entity_manager;
  }
  my $valid = 1;
  for ($self->_validate_notation_declared ($node, entMan => $opt{entMan}),
       $self->_validate_attlist_declaration ($node, entMan => $opt{entMan}),
       $self->_validate_document_instance ($node, entMan => $opt{entMan})) {
    $valid &= $_;
  }
  return $valid;
}

sub _validate_attlist_declaration ($$;%) {
  my ($self, $c, %opt) = @_;
  my $valid = 1;
  my $l = [];
  
  ## Default attribute value syntacally valid?
  $opt{entMan}->get_entities ($l, namespace_uri => $NS{SGML}.'attlist');
  my %defined;
  my %edef;
  for my $attlist (@$l) {
    my $element_qname = $attlist->get_attribute ('qname', make_new_node => 1)->inner_text;
    unless ($edef{$element_qname}) {
      $edef{$element_qname} = $opt{entMan}->is_declared_entity ($element_qname,
                                                         namespace_uri => $NS{SGML}.'element');
      unless ($edef{$element_qname}) {
        $self->{error}->raise_error ($attlist, type => 'WARN_XML_ATTLIST_ELEMENT_DECLARED',
                                     t => $element_qname);
        $edef{$element_qname} = 'undeclared';
      }
    }
    for (@{$attlist->{node}}) {
      my $attr_qname = $_->get_attribute ('qname', make_new_node => 1)->inner_text;
      if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{XML}.'attlist',
          $_->{local_name} eq 'AttDef') {
        if ($defined{$element_qname}->{$attr_qname}) {
          $self->{error}->raise_error ($attlist, type => 'WARN_XML_ATTLIST_AT_MOST_ONE_ATTR_DEF',
                                       t => [$element_qname, $attr_qname]);
        } else {
          $defined{$element_qname}->{$attr_qname} = 1;
        }
        my $type = $_->get_attribute ('type', make_new_node => 1)->inner_text;
        if ({qw/ID 1 IDREF 1 IDREFS 1 NMTOKEN 1 NMTOKENS 1 NOTATION 1/}->{$type}) {
          my $dt = $_->get_attribute ('default_type', make_new_node => 1)->inner_text;
          if (!{qw/IMPLIED 1 REQUIRED 1/}->{$dt}) {
            my $dv = $_->get_attribute ('default_value')->inner_text;
            $dv =~ s/\x20\x20+/\x20/g;
            $dv =~ s/^\x20+//;  $dv =~ s/\x20+$//;
            if ({qw/ID 1 IDREF 1 NOTATION 1/}->{$type}) {
              if ($type eq 'ID') {
                $self->{error}->raise_error ($attlist, type => 'VC_ID_ATTR_DEFAULT',
                                             t => [$element_qname, $attr_qname]);
                $valid = 0;
              }
              if ($dv !~ /^$xml_re{Name}$/) {
                $self->{error}->raise_error ($attlist, type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAME',
                                             t => [$dv, $type]);
                $valid = 0;
              } elsif (index ($dv, ':') > -1) {
                $self->{error}->raise_error ($attlist, type => 'VALID_NS_NAME_IS_NCNAME',
                                             t => $dv);
                $valid = 0;
              }
            } elsif ($type eq 'NMTOKEN') {
              if ($dv =~ /\P{InXMLNameChar}/) {
                $self->{error}->raise_error ($attlist,
                                             type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKEN',
                                             t => [$dv, $type]);
                $valid = 0;
              }
            } elsif ($type eq 'NMTOKENS') {
              if ($dv =~ /[^\p{InXMLNameChar}\x20]/) {
                $self->{error}->raise_error ($attlist,
                                             type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKENS',
                                             t => [$dv, $type]);
                $valid = 0;
              }
            } else {	## IDREFS
              if ($dv !~ /^$xml_re{Name}(\x20$xml_re{Name})*$/) {
                $self->{error}->raise_error ($attlist, type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAMES',
                                             t => [$dv, $type]);
                $valid = 0;
              } elsif (index ($dv, ':') > -1) {
                $self->{error}->raise_error ($attlist, type => 'VALID_NS_NAME_IS_NCNAME',
                                             t => $dv);
                $valid = 0;
              }
            }
          }	# default attr exist
          
          if ({qw/ID 1 NOTATION 1/}->{$type}) {
                if ($defined{$element_qname}->{'>'.$type.'<'}) {
                  $self->{error}->raise_error ($attlist, type => 'VC_ONE_'.$type.'_PER_ELEMENT_TYPE',
                                               t => [$element_qname, $attr_qname,
                                                     $defined{$element_qname}->{'>'.$type.'<'}]);
                  $valid = 0;
                } else {
                  $defined{$element_qname}->{'>'.$type.'<'} = $attr_qname;
                  if ($type eq 'NOTATION') {
                    if ($edef{$element_qname}) {
                      if ($edef{$element_qname}->get_attribute ('content',
                                                                make_new_node => 1)->inner_text
                          eq 'EMPTY') {
                        $self->{error}->raise_error ($attlist,
                                                     type => 'VC_NO_NOTATION_ON_EMPTY_ELEMENT',
                                                     t => [$element_qname, $attr_qname]);
                        $valid = 0;
                      }	# EMPTY
                    }
                  }	# NOTATION
                }
          }	# NOTATION or ID
        } elsif ($type eq 'enum') {
          for my $enum (@{$_->{node}}) {
            if ($enum->{type} eq '#element' && $enum->{namespace_uri} eq $NS{XML}.'attlist',
                $enum->{local_name} eq 'enum') {
              my $enum_val = $enum->inner_text;
              if ($defined{$element_qname}->{'>enum<'}->{$enum_val}) {
                $self->{error}->raise_error ($attlist,
                                             type => 'WARN_XML_ATTLIST_UNIQUE_ENUM_TOKEN',
                                             t => [$element_qname, $enum_val]);
              } else {
                $defined{$element_qname}->{'>enum<'}->{$enum_val} = 1;
              }
            }
          }
        }	# enum
      }
    }
  }
  $valid;
}

sub _validate_notation_declared ($$;%) {
  my ($self, $c, %opt) = @_;
  my $valid = 1;
    my $l = [];
    my %defined;
    
    ## NDATA notation declared?
    $opt{entMan}->get_entities ($l, namespace_uri => $NS{SGML}.'entity');
    for my $ent (@$l) {
      for ($ent->get_attribute ('NDATA')) {
      if (ref $_) {
        my $nname = $_->inner_text;
        if ($defined{$nname} > 0
         || $opt{entMan}->get_entity ($nname, namespace_uri => $NS{SGML}.'notation')) {
          $defined{$nname} = 1;
        } else {
          $self->{error}->raise_error ($ent, type => 'VC_NOTATION_DECLARED',
                                       t => $nname);
          $defined{$nname} = -1;
          $valid = 0;
        }
      }}	# NDATA exist
    }
    
    ## PI target name notation declared?
    @$l = ();
    $opt{entMan}->get_entities ($l, parent_node => $c, type => '#pi', namespace_uri => '');
    for my $pi (@$l) {
      my $nname = $pi->local_name;
      if ($defined{$nname} > 0
       || $opt{entMan}->get_entity ($nname, namespace_uri => $NS{SGML}.'notation')) {
        $defined{$nname} = 1;
      } else {
        $self->{error}->raise_error ($pi, type => 'WARN__PI_TARGET_NOTATION',
                                     t => $nname)
          unless lc (substr ($nname, 0, 3)) eq 'xml';	## Target name xml* is maintained by W3C
        $defined{$nname} = -1;
      }
    }	# pi
  return $valid;
}

sub _validate_document_instance ($$;%) {
  my ($self, $node, %opt) = @_;
  my $valid = 1;
  $opt{_element} = {};
  $opt{entMan}->get_entities ($opt{_elements}, namespace_uri => $NS{SGML}.'element');
  $opt{_idref_attr} = [];
  $opt{_idref_value} = {};
  for (@{$node->{node}}) {
    if ($_->{type} eq '#element') {
      $valid &= $self->_validate_element ($_, \%opt);
    }
  }
  
  ## IDREF/IDREFS attribute values
  for (@{$opt{_idref_attr}}) {
    unless ($opt{_id_value}->{$_->[0]}) {
      $self->{error}->raise_error ($_->[1], type => 'VC_IDREF_MATCH', t => $_->[0]);
      $valid = 0;
    }
  }
  $valid;
}
sub _validate_element ($$$) {
  my ($self, $node, $opt) = @_;
  my $valid = 1;
  my $qname = $node->qname;
  unless ($opt->{_element}->{$qname}) {
    $opt->{_element}->{$qname} = $opt->{entMan}->is_declared_entity ($qname,
                                                 namespace_uri => $NS{SGML}.'element');
    unless ($opt->{_element}->{$qname}) {
      $self->{error}->raise_error ($_, type => 'VC_ELEMENT_VALID_DECLARED', t => $qname);
      $opt->{_element}->{$qname} = 'undeclared';
      $valid = 0;
    }
  }
  unless ($opt->{_attrs}->{$qname}) {
    $opt->{_attrs}->{$qname} = $opt->{entMan}->get_attr_definitions (qname => $qname);
  }
  #$opt->{_id_value};
  #$opt->{_idref_attr} = [[$id, $node],...]
  my %specified;
  my $has_child = 0;
  for (@{$node->{node}},
       ## NS attributes
       grep {ref $_} values %{$node->{ns_specified}}) {
    if ($_->{type} eq '#attribute') {
      my $attr_qname = $_->qname;
      $specified{$attr_qname} = 1;	## defined explicilly or by default declaration
      my $attrdef = $opt->{_attrs}->{$qname}->{attr}->{$attr_qname};
      if ($attrdef) {
        my $attr_type = $attrdef->get_attribute ('type', make_new_node => 1)->inner_text;
        my $attr_value = $_->inner_text;
        my $attr_deftype = $attrdef->get_attribute ('default_type', make_new_node => 1)->inner_text;
        if ($attr_type eq 'CDATA') {
          ## Check FIXED value
          if ($attr_deftype eq 'FIXED') {
            my $dv = $attrdef->get_attribute ('default_value')->inner_text;
            unless ($attr_value eq $dv) {
              $self->{error}->raise_error ($_, type => 'VC_FIXED_ATTR_DEFAULT',
                                           t => [$attr_value, $dv]);
              $valid = 0;
            }
          }
        } elsif ({qw/ID 1 IDREF 1 IDREFS 1 NMTOKEN 1 NMTOKENS 1 NOTATION 1/}->{$attr_type}) {
          ## Normalization
          $attr_value =~ s/\x20\x20+/\x20/g;
          $attr_value =~ s/^\x20+//;  $attr_value =~ s/\x20+$//;
          ## Check FIXED value
          if ($attr_deftype eq 'FIXED') {
            my $dv = $attrdef->get_attribute ('default_value')->inner_text;
            $dv =~ s/\x20\x20+/\x20/g;
            $dv =~ s/^\x20+//;  $dv =~ s/\x20+$//;
            unless ($attr_value eq $dv) {
              $self->{error}->raise_error ($_, type => 'VC_FIXED_ATTR_DEFAULT',
                                           t => [$attr_value, $dv]);
              $valid = 0;
            }
          }
          ## Check value syntax and semantics
          if ({qw/ID 1 IDREF 1 NOTATION 1/}->{$attr_type}) {
            if ($attr_value !~ /^$xml_re{Name}$/) {
              $self->{error}->raise_error ($_, type => 'VC_'.$attr_type.'_SYNTAX',
                                           t => $attr_value);
              $valid = 0;
            } elsif (index ($attr_value, ':') > -1) {
              $self->{error}->raise_error ($_, type => 'VALID_NS_NAME_IS_NCNAME',
                                           t => $attr_value);
              $valid = 0;
            }
            if ($attr_type eq 'ID') {
              if ($opt->{_id_value}->{$attr_value}) {
                $self->{error}->raise_error ($_, type => 'VC_ID_UNIQUE',
                                             t => $attr_value);
                $valid = 0;
              } else {
                $opt->{_id_value}->{$attr_value} = 1;
              }
            } elsif ($attr_type eq 'IDREF') {
              unless ($opt->{_id_value}->{$attr_value}) {
                ## Referred ID is not defined yet, so check later
                push @{$opt->{_idref_attr}}, [$attr_value, $_];
              }
            } elsif ($attr_type eq 'NOTATION') {
              unless ($opt->{_attrs}->{$qname}->{enum}->{$attr_qname}->{$attr_value}) {
                $self->{error}->raise_error ($_, type => 'VC_NOTATION_ATTR_ENUMED',
                                             t => $attr_value);
                $valid = 0;
              }
              unless ($opt->{entMan}->get_entity ($attr_value,
                                                  namespace_uri => $NS{SGML}.'notation')) {
                $self->{error}->raise_error ($_, type => 'VC_NOTATION_ATTR_DECLARED',
                                             t => $attr_value);
                $valid = 0;
              }
            }
          } elsif ($attr_type eq 'NMTOKEN') {
            if ($attr_value =~ /\P{InXMLNameChar}/) {
              $self->{error}->raise_error ($_, type => 'VC_NAME_TOKEN_NNTOKEN',
                                           t => $attr_value);
              $valid = 0;
            }
          } elsif ($attr_type eq 'NMTOKENS') {
            if ($attr_value =~ /[^\p{InXMLNameChar}\x20]/) {
              $self->{error}->raise_error ($_, type => 'VC_NAME_TOKEN_NMTOKENS',
                                           t => $attr_value);
              $valid = 0;
            }
          } else {	## IDREFS
            for my $anid (split /\x20/, $attr_value) {
              if ($anid !~ /^$xml_re{Name}$/) {
                $self->{error}->raise_error ($_, type => 'VC_IDREF_IDREFS_NAME',
                                             t => $anid);
                $valid = 0;
              } else {
                if (index ($anid, ':') > -1) {
                  $self->{error}->raise_error ($_, type => 'VALID_NS_NAME_IS_NCNAME',
                                               t => $anid);
                  $valid = 0;
                }
              }
              unless ($opt->{_id_value}->{$attr_value}) {
                ## Referred ID is not defined yet, so check later
                push @{$opt->{_idref_attr}}, [$attr_value, $_];
              }
            }	# IDREFS values
          }
        } elsif ($attr_type eq 'enum') {
          ## Normalization
          $attr_value =~ s/\x20\x20+/\x20/g;
          $attr_value =~ s/^\x20+//;  $attr_value =~ s/\x20+$//;
          unless ($opt->{_attrs}->{$qname}->{enum}->{$attr_qname}->{$attr_value}) {
            $self->{error}->raise_error ($_, type => 'VC_ENUMERATION', t => $attr_value);
            $valid = 0;
          }
        }	# enum
      } else {
        $self->{error}->raise_error ($_, type => 'VC_ATTR_DECLARED', t => $attr_qname);
        $valid = 0;
      }
    } else {
      $has_child = 1;
    }
  }
  
  for my $attr_qname (keys %{$opt->{_attrs}->{$qname}->{attr}}) {
    my $attrdef = $opt->{_attrs}->{$qname}->{attr}->{$attr_qname};
    if ($attrdef->get_attribute ('default_type', make_new_node => 1)->inner_text
        eq 'REQUIRED') {
      unless ($specified{$attr_qname}
       || ($attr_qname eq 'xmlns' && $node->{ns_specified}->{''})
       || (substr ($attr_qname, 0, 6) eq 'xmlns:'
           && defined $node->{ns_specified}->{substr $attr_qname, 6})) {
        $self->{error}->raise_error ($node, type => 'VC_REQUIRED_ATTR', t => [$qname, $attr_qname]);
        $valid = 0;
      }
    }
  }
  
  ## Content check
  my $cmodel = ref $opt->{_element}->{$qname}
               ? $opt->{_element}->{$qname}->get_attribute ('content',
                                                            make_new_node => 1)->inner_text
               : 'ANY';
  if ($cmodel eq 'EMPTY') {
    if ($has_child) {
      $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_EMPTY');
      $valid = 0;
    } elsif (!$node->{option}->{use_EmptyElemTag}) {
      $self->{error}->raise_error ($node, type => 'WARN_XML_EMPTY_NET');
    }
  } else {	# not EMPTY
    if (!$has_child && $node->{option}->{use_EmptyElemTag}) {
      $self->{error}->raise_error ($node, type => 'WARN_XML_NON_EMPTY_NET');
    }
    if ($cmodel eq 'ANY') {
      for (@{$node->{node}}) {
        if ($_->{type} eq '#element') {
          $valid &= $self->_validate_element ($_, $opt);
        }
      }
    } elsif ($cmodel eq 'mixed') {
      my %accepted_element_type;
      for (@{$opt->{_element}->{$qname}->{node}}) {
        if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{SGML}.'element'
         && $_->{local_name} eq 'group') {
          for my $el (@{$_->{node}}) {
            if ($el->{type} eq '#element' && $el->{namespace_uri} eq $NS{SGML}.'element'
             && $el->{local_name} eq 'element') {
              $accepted_element_type{$el->get_attribute ('qname', make_new_node => 1)->inner_text}
                = 1;
            }
          }
          last;
        }	# content model group
      }
      
      for my $child (@{$node->{node}}) {
        if ($child->{type} eq '#element') {
          my $child_qname = $child->qname;
          unless ($accepted_element_type{$child_qname}) {
            $self->{error}->raise_error ($child, type => 'VC_ELEMENT_VALID_MIXED',
                                         t => $child_qname);
            $valid = 0;
          }
          $valid &= $self->_validate_element ($child, $opt);
        }
      }
    } else {	# element content
      my $make_cmodel_arraytree;
      $make_cmodel_arraytree = sub {
        my $node = shift;
        my @r;
        for (@{$node->{node}}) {
          if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{SGML}.'element') {
            if ($_->{local_name} eq 'group') {
              push @r, &$make_cmodel_arraytree ($_);
            } elsif ($_->{local_name} eq 'element') {
              push @r, {qname => ($_->get_attribute ('qname', make_new_node => 1)->inner_text),
                        occurence => ($_->get_attribute ('occurence',
                                                          make_new_node => 1)->inner_text || '1')};
            }
          }
        }
        {connector => ($node->get_attribute ('connector', make_new_node => 1)->inner_text || '|'),
         occurence => ($node->get_attribute ('occurence', make_new_node => 1)->inner_text || '1'),
         element => \@r, type => 'group'};
      };	# $make_cmodel_arraytree
      my $tree = &$make_cmodel_arraytree ($opt->{_element}->{$qname});
      
      my $find_myname;
      $find_myname = sub {
        my ($node, $qname, $tree) = @_;
        require Data::Dump;print scalar Data::Dump::dump ($tree) if $main::DEBUG;
        print qq(\@\@ [$qname] $tree->{element_pos}..$#{$tree->{element}}\n) if $main::DEBUG;
        for my $i ($tree->{element_pos}..$#{$tree->{element}}) {
          my $match = 0;
          if ($tree->{element}->[$i]->{type} eq 'group') {	## sub group
            $match = &$find_myname ($node, $qname, $tree->{element}->[$i]);
            $match += 1 if $match > 0;
            print qq(\@\@ grpMatch[$i/$#{$tree->{element}}] "$qname" : $match\n) if $main::DEBUG;
          } else {	## Child element type
            if ($qname eq '<LAST>') {
              $match = ($tree->{element}->[$i]->{occurence} eq '1'
                     || ($tree->{element}->[$i]->{occurence_r}
                      || $tree->{element}->[$i]->{occurence}) eq '+') ? 1 : 0;
            } else {
              $match = ($qname eq $tree->{element}->[$i]->{qname}) ? 1 : 0;
            }
            print qq(\@\@ elemMatch[$i/$#{$tree->{element}}] "$qname" == "$tree->{element}->[$i]->{qname}" = $match\n) if $main::DEBUG;
          }
            if ($match > 0) {
              if ($match > 1) {	# group
                #print "$tree->{connector}#($tree->{element}->[$i]->{element_pos} > $#{$tree->{element}->[$i]->{element}})";
                if ($tree->{element}->[$i]->{connector} eq ','
                 && ($tree->{element}->[$i]->{element_pos}
                     <= $#{$tree->{element}->[$i]->{element}})) {
                  ## Don't go next to continue matching
                  $tree->{element_pos} = $i;
                } else {
                  if ($match == 2) {
                    if ($tree->{connector} eq '|'
                     && $tree->{element}->[$i]->{element_pos}
                        >= $#{$tree->{element}->[$i]->{element}}) {
                      $tree->{element_pos} = $#{$tree->{element}}+1;
                    } else {
                      $tree->{element}->[$i]->{element_pos} = $#{$tree->{element}->[$i]->{element}}+1;
                      $tree->{element_pos} = $i+1;
                    }
                    for my $j (0..$#{$tree->{element}}) {
                      $tree->{element}->[$j]->{occurence_r} = undef;
                    }
                  } else {
                    if ($tree->{connector} eq '|'
                     && $tree->{element}->[$i]->{element_pos}
                        > $#{$tree->{element}->[$i]->{element}}) {
                      ## Note: Is this case work??
                      $tree->{element_pos} = $#{$tree->{element}}+1;
                    } else {
                      $tree->{element_pos} = $i;
                    }
                  }
                }
              } elsif ($tree->{element}->[$i]->{occurence} eq '+'
               || $tree->{element}->[$i]->{occurence} eq '*') {
                $tree->{element}->[$i]->{occurence_r} = '*';
                $tree->{element_pos} = $i;	# don't change
              } else {	# child element type
                $tree->{element_pos} = $i+1;
              }
              return $match;
            } else {	## Does not match
              if ($tree->{element}->[$i]->{occurence} eq '?'
               || $tree->{element}->[$i]->{occurence_r} eq '*'
               || $tree->{element}->[$i]->{occurence} eq '*') {
                $tree->{element_pos} = $i+1;
                
              } else {
                if ($tree->{connector} eq ',') {
                  if ($match == -1) {
                    $tree->{element_pos} = $i + 1;
                  } else {
                    return 0;
                  }
                } elsif ($qname eq '<LAST>') {
                  return -1;
                } elsif ($tree->{connector} eq '|' && $tree->{element}->[$i]->{connector} eq ',') {
                  for my $i (0..$#{$tree->{element}}) {
                    $tree->{element}->[$i]->{occurence_r} = undef;
                  }
                  if ($tree->{element}->[$i]->{element_pos}) {
                    $tree->{element_pos} = undef;
                    return -1;
                  } else {
                    $tree->{element_pos} = $i+1;
                  }
                } else {
                  $tree->{element_pos} = $i;
                }
              }
            }
        }	# for content model elements
        ## No more element in this content model group
        for my $i (0..$#{$tree->{element}}) {
          $tree->{element}->[$i]->{occurence_r} = undef;
        }
        $tree->{element_pos} = undef;
        return (-1);
      };
      for my $child (@{$node->{node}}) {
        if ($child->{type} eq '#element') {
          my $child_qname = $child->qname;
          my $match = $tree->{element_pos} eq 'end' ? 0
                    : (&$find_myname ($child, $child_qname, $tree));
          unless ($match > 0) {
            $self->{error}->raise_error ($child, type => 'VC_ELEMENT_VALID_ELEMENT_MATCH',
                                         t => $child_qname);
            $valid = 0;
            if ($match == -1) {	# the very last of content model
              $tree->{element_pos} = 'end';
            }
          }
          
          $valid &= $self->_validate_element ($child, $opt);
        } elsif ($child->{type} eq '#section') {
          $self->{error}->raise_error ($child, type => 'VC_ELEMENT_VALID_ELEMENT_SECTION');
          $valid = 0;
        } elsif ($child->{type} eq '#reference') {
          $self->{error}->raise_error ($child, type => 'VC_ELEMENT_VALID_ELEMENT_REF');
          $valid = 0;
        } elsif ($child->{type} eq '#text') {
          if ($child->inner_text =~ /[^$xml_re{_s__chars}]/s) {
            $self->{error}->raise_error ($child, type => 'VC_ELEMENT_VALID_ELEMENT_CDATA',
                                         t => $child->inner_text);
            $valid = 0;
          }
        }
      }	# children
        unless ($tree->{element_pos} eq 'end') {
          my $match = (&$find_myname (undef, '<LAST>', $tree));
          unless ($match == -1) {
            $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_ELEMENT_MATCH',
                                         t => '<LAST>');	## TODO: 
            $valid = 0;
          }
        }
    }	# element content
  }	# not EMPTY
  $valid;
}

#sub _CLASS_NAME () { 'SuikaWiki::Markup::XML::Validate' }

sub option ($$;$%) {
  my ($self, $name, $value, %opt) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  if (!defined $self->{option}->{$name} && $opt{-see_parent} && $self->{parent}) {
    $self->{parent}->option ($name, $value, %opt);
  } else {
    $self->{option}->{$name};
  }
}

sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/07/16 12:10:22 $
