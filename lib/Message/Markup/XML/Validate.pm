
=head1 NAME

Message::Markup::XML::Validate --- manakai: XML Validator

=head1 DESCRIPTION

This module provides validator facilities for XML document.
With Message::Markup::XML::Parser, it is possible to validate
an XML document.

This module is part of manakai.

=cut

package Message::Markup::XML::Validate;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Markup::XML::Parser;
our (%NS);
*NS = \%Message::Markup::XML::NS;
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar!;
my %xml_re = (
	Name	=> qr/\p{InXML_NameStartChar}\p{InXMLNameChar}*/,
	_s__chars	=> qr/\x09\x0A\x0D\x20/s,
);

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  require Message::Markup::XML::Error;
  $self->{error} = Message::Markup::XML::Error->new ({
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
    	description	=> 'Child element (type = "%s") cannot appear here, since it does not match to the content model',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_MATCH_EMPTY	=> {
    	description	=> 'Required child element does not found',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_MATCH_NEED_MORE_ELEMENT	=> {
    	description	=> 'Required child element does not found',
    	level	=> 'vc',
    },
    VC_ELEMENT_VALID_ELEMENT_MATCH_TOO_MANY_ELEMENT	=> {
    	description	=> 'Child element (type = "%s") does not match to the content model',
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
  for (
       $self->_validate_notation_declared ($node, entMan => $opt{entMan}),
       $self->_validate_attlist_declaration ($node, entMan => $opt{entMan}),
       $self->_validate_document_instance ($node, entMan => $opt{entMan})
      ) {
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
      $edef{$element_qname} = $opt{entMan}->get_entity ($element_qname,
                                                         namespace_uri => $NS{SGML}.'element');
      unless ($edef{$element_qname}) {
        $self->{error}->raise_error ($attlist, type => 'WARN_XML_ATTLIST_ELEMENT_DECLARED',
                                     t => $element_qname);
        $edef{$element_qname} = 'undeclared';
      }
    }
    for (@{$attlist->{node}}) {
      my $attr_qname = $_->get_attribute ('qname', make_new_node => 1)->inner_text;
      if ($_->{type} eq '#element'
      and $_->{namespace_uri} eq $NS{XML}.'attlist'
      and $_->{local_name} eq 'AttDef') {
        if ($defined{$element_qname}->{$attr_qname}) {
          $self->{error}->raise_error ($attlist, type => 'WARN_XML_ATTLIST_AT_MOST_ONE_ATTR_DEF',
                                       t => [$element_qname, $attr_qname]);
        } else {
          $defined{$element_qname}->{$attr_qname} = 1;
        }
        my $type = $_->get_attribute_value ('type');
        if ({qw/ID 1 IDREF 1 IDREFS 1 NMTOKEN 1 NMTOKENS 1 NOTATION 1/}->{$type}) {
          my $dt = $_->get_attribute_value ('default_type');
          if (not {qw/IMPLIED 1 REQUIRED 1/}->{$dt}) {
            my $dv = $_->get_attribute_value ('default_value');
            $dv =~ s/\x20\x20+/\x20/g;
            $dv =~ s/^\x20+//;  $dv =~ s/\x20+$//;
            if ({qw/ID 1 IDREF 1 NOTATION 1/}->{$type}) {
              if ($type eq 'ID') {
                $self->{error}->raise_error ($attlist,
                                             type => 'VC_ID_ATTR_DEFAULT',
                                             t => [$element_qname, $attr_qname]);
                $valid = 0;
              }
              if ($dv !~ /^$xml_re{Name}$/) {
                $self->{error}->raise_error ($attlist,
                                             type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAME',
                                             t => [$dv, $type]);
                $valid = 0;
              } elsif (index ($dv, ':') > -1) {
                $self->{error}->raise_error ($attlist,
                                             type => 'VALID_NS_NAME_IS_NCNAME',
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
              if ($dv !~ /^$xml_re{Name}(?:\x20$xml_re{Name})*$/) {
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
                      if ($edef{$element_qname}->get_attribute_value ('content')
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
            if ($enum->{type} eq '#element'
            and $enum->{namespace_uri} eq $NS{XML}.'attlist'
            and $enum->{local_name} eq 'enum') {
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
      if (($defined{$nname} and $defined{$nname} > 0)
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
  ### DEBUG: 
  #Carp::croak join qq!\t!, caller(0) unless eval q{$node->qname};
  my $qname = $node->qname;
  unless ($opt->{_element}->{$qname}) {
    $opt->{_element}->{$qname} = $opt->{entMan}->get_entity ($qname,
                                                 namespace_uri => $NS{SGML}.'element');
    unless ($opt->{_element}->{$qname}) {
      $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_DECLARED', t => $qname);
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
      if (ref $attrdef) {
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
    if ($attrdef->get_attribute_value ('default_type') eq 'REQUIRED') {
      unless ($specified{$attr_qname}
       || ($attr_qname eq 'xmlns' and $node->{ns_specified}->{''})
       || (substr ($attr_qname, 0, 6) eq 'xmlns:'
           and defined $node->{ns_specified}->{substr $attr_qname, 6})) {
        $self->{error}->raise_error ($node, type => 'VC_REQUIRED_ATTR',
                                     t => [$qname, $attr_qname]);
        $valid = 0;
      }
    }
  }
  
  ## Content check
  my $cmodel = ref $opt->{_element}->{$qname}
               ? $opt->{_element}->{$qname}->get_attribute_value ('content',
                                                                  default => '')
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
              push @r, {qname => ($_->get_attribute_value ('qname')),
                        occurence => ($_->get_attribute_value
                                            ('occurence', default => '1')),
                        type => 'element'};
            }
          }
        }
        my $tree =
        {connector => ($node->get_attribute ('connector', make_new_node => 1)->inner_text || '|'),
         occurence => ($node->get_attribute ('occurence', make_new_node => 1)->inner_text || '1'),
         element => \@r, type => 'group'};
        if ($tree->{connector} eq '|') {
          if ($tree->{occurence} eq '1' || $tree->{occurence} eq '+') {
            for (@{$tree->{element}}) {
              if ($_->{occurence} eq '?' || $_->{occurence} eq '*') {
                $tree->{occurence} = {'1'=>'?','+'=>'*'}->{$tree->{occurence}};
                last;
              }
            }
          }
        }
        $tree;
      };	# $make_cmodel_arraytree
      my $tree = &$make_cmodel_arraytree ($opt->{_element}->{$qname});
      
      my $find_myname;
      $find_myname = sub {
        my ($nodes=>$idx, $tree, $opt) = @_;
        if ($tree->{type} eq 'group') {
          my $return = {match => 1, some_match => 0, actually_no_match => 1};
          my $original_idx = $$idx;
          for (my $i = 0; $i <= $#{$tree->{element}}; $i++) {
            my $result = (&$find_myname ($nodes=>$idx, $tree->{element}->[$i],
                                         {depth => 1+$opt->{depth},
                                          nodes_max => $opt->{nodes_max}}));
            print STDERR qq(** Lower level match [$opt->{depth}] ("$nodes->[$$idx]->[1]") : Exact = $result->{match}, Some = $result->{some_match}\n) if $main::DEBUG;
            if ($result->{match} == 1 && !$result->{actually_no_match}) {
              $return->{actually_no_match} = 0;
              if ($tree->{connector} eq '|') {
                $return->{match} = 1;
                $return->{some_match} = 1;
                if (($tree->{element}->[$i]->{occurence} eq '*'
                  || $tree->{element}->[$i]->{occurence} eq '+')
                  && $$idx <= $opt->{nodes_max}) {
                  print STDERR qq(** More matching chance ($tree->{element}->[$i]->{occurence}) [$opt->{depth}] : "$tree->{element}->[$i]->{qname}" (model) vs "$nodes->[$$idx]->[1]" (instance)\n) if $main::DEBUG;
                  $return->{more} = 1;
                  $i--;
                  #$$idx++;
                  next;
                } else {
                  return $return;
                }
              } else {	# ','
                $return->{match} &= 1;
                $return->{some_match} = 1;
                if ($$idx > $opt->{nodes_max}) {	# already last of instance's nodes
                  if ($i == $#{$tree->{element}}) {
                    return $return;
                  } else {	## (foo1,foo2,foo3,foo4) and <foo1/><foo2/>.
                          	## If foo3 and foo4 is optional, valid, otherwise invalid
                    my $isopt = 1;
                    for ($i+1..$#{$tree->{element}}) {
                      if ($tree->{element}->[$_]->{occurence} ne '*'
                       && $tree->{element}->[$_]->{occurence} ne '?') {
                        $isopt = 0;
                        last;
                      }
                    }
                    $return->{match} = 0 unless $isopt;
                    return $return;
                  }
                } else {	# not yet last of instance's nodes
                  if ($tree->{element}->[$i]->{occurence} eq '*'
                   || $tree->{element}->[$i]->{occurence} eq '+') {
                    $return->{more} = 1;
                    $i--;
                    #$$idx++;
                    next;
                  } elsif ($i == $#{$tree->{element}}) {	# already last of model group
                    return $return;
                  } else {
                    #$$idx++;
                    next;
                  }
                }
              }
            } else {	# doesn't match
              # <$return->{match} == 1>
              if ($return->{more}	## (something*) but not matched
              || ($tree->{element}->[$i]->{occurence} eq '?'
               && $tree->{connector} eq ',')) {
                $return->{more} = 0;
                $return->{match} = 0 if $result->{some_match};
                if ($tree->{connector} eq '|') {
                  return $return;
                } else {	# ','
                  next;
                }
              } elsif ($result->{some_match} && $tree->{connector} eq '|') {
                $$idx = $original_idx;
              }
              if ($tree->{element}->[$i]->{occurence} eq '*') {
                $return->{match} = 1;
                #$return->{actually_no_match} &= 1;	# default
              } else {
                $return->{match} = 0;
                if ($tree->{connector} eq ',') {
                  return $return;
                }
              }
            }	# match or nomatch
          }	# content group elements
          ## - ',' and all matched
          ## - '|' and match to no elements
          return $return;
        } else {	# terminal element
          print STDERR qq(** Element match [$opt->{depth}] : "$tree->{qname}" (model) vs "$nodes->[$$idx]->[1]" (instance)\n) if $main::DEBUG;
          if ($tree->{qname} eq $nodes->[$$idx]->[1]) {
            $$idx++;
            return {match => 1, some_match => 1};
          #} elsif ($tree->{occurence} eq '*' || $tree->{occurence} eq '?') {
          #  return {match => 1, some_match => 1, actually_no_match => 1};
          } else {
            return {match => 0, some_match => 0};
          }
        }
      };
      my @nodes;
      for my $child (@{$node->{node}}) {
        if ($child->{type} eq '#element') {
          push @nodes, [$child, $child->qname];
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
      
      my $nodes_max = $#nodes;
      if (@nodes == 0) {	## Empty
        my $check_empty_ok;
        $check_empty_ok = sub {
          my ($tree) = @_;
          if ($tree->{occurence} eq '*'
           || $tree->{occurence} eq '?') {
            return 1;
          } elsif ($tree->{type} eq 'group') {
            if ($tree->{connector} eq ',') {
              my $ok = 1;
              for (@{$tree->{element}}) {
                $ok &= &$check_empty_ok ($_);
                last unless $ok;
              }
              return $ok;
            } else {	# '|'
              my $ok = 0;
              for (@{$tree->{element}}) {
                $ok ||= &$check_empty_ok ($_);
                last if $ok;
              }
              return $ok;
            }
          } else {
            return 0;
          }
        };
        if (&$check_empty_ok ($tree)) {
          
        } else {
          $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_ELEMENT_MATCH_EMPTY');
          $valid = 0;
        }
      } else {	## Non-empty
        my $i = 0;
        my $result = &$find_myname (\@nodes, \$i, $tree, {depth => 0, nodes_max => $nodes_max});
        if ($result->{match}) {
          if ($i > $nodes_max) {
            ## All child elements match to the model
          } else {
            ## Some more child element does not match to the model
            $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_ELEMENT_MATCH_TOO_MANY_ELEMENT', t => $nodes[$i]->[1]);
            $valid = 0;
          }
        } else {
          if ($i <= $nodes_max) {
            ## Some more child element is required by the model
            $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_ELEMENT_MATCH_NEED_MORE_ELEMENT');
            $valid = 0;
          } else {
            $self->{error}->raise_error ($node, type => 'VC_ELEMENT_VALID_ELEMENT_MATCH', t => $nodes[$i]->[1]);
            $valid = 0;
          }
        }
      }
      for (0..$nodes_max) {
        $valid &= $self->_validate_element ($nodes[$_]->[0], $opt);
      }
      
    }	# element content
  }	# not EMPTY
  $valid;
}

#sub _CLASS_NAME () { 'Message::Markup::XML::Validate' }

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

1; # $Date: 2003/10/31 08:41:35 $
