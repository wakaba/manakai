=head1 NAME

Message::Markup::XML::Parser::NodeTree - manakai: XML Parsing and Tree Generating

=head1 DESCRIPTION

C<Message::Markup::XML::Parser::NodeTree> parses serialized XML
entities and constructs trees corresponding to them.  Nodes consisting
those trees are instances of C<Message::Markup::XML::Node>.

This module is part of manakai.

=cut

package Message::Markup::XML::Parser::NodeTree;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::Markup::XML::Parser::NodeTree;
push our @ISA, 'Message::Markup::XML::Parser::Base';
use Message::Markup::XML::Parser::Base;
use Message::Markup::XML::QName qw/:prefix/;
use Message::Markup::XML::Node qw/:charref :declaration :entity XML_ATTLIST/;
use Message::Util::ResourceResolver::XML;
use URI;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>
}
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG (),
   tree => URI_CONFIG,
   rr => Message::Util::ResourceResolver::Base::URI_CONFIG (),
   rrx => Message::Util::ResourceResolver::XML::URI_CONFIG (),
   infoset => q<http://www.w3.org/2001/04/infoset#>,
  };

sub _NODE_PACKAGE_ () {
  q<Message::Markup::XML::Node>
}

sub document_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $node = $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>};
  $node->base_uri ($p->{ExpandedURI q<base-uri>});
}

sub document_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  if ($pp->{ExpandedURI q<s>}) {
    $p->{ExpandedURI q<tree:current>}
      ->append_text (${$pp->{ExpandedURI q<s>}});
  } else {
    $p->{ExpandedURI q<tree:current>}
      ->append_text (${$pp->{ExpandedURI q<CDATA>}});
  }
}

sub element_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:parent>}
    = $p->{ExpandedURI q<tree:current>};
}

sub start_tag_start ($$$$%) {

}

sub start_tag_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $el = $p->{ExpandedURI q<tree:current>}
         = $p->{ExpandedURI q<tree:parent>}
             ->append_new_node
                  (type => '#element',
                   local_name => $pp->{ExpandedURI q<element-type-name>});  
  
  ## Attributes
  for (@{$pp->{ExpandedURI q<tree:attr>}}) {
    $self->____generate_attrnode (
      list => $_->{value},
      parent => $el->get_attribute (${$_->{name}}, make_new_node => 1),
    );
  }
  
  ## Null End Tag
  if ($p->{ExpandedURI q<tag-type>} eq 'empty') {
    $el->option (ExpandedURI q<s-preceding-nestc>
                   => $pp->{ExpandedURI q<s-preceding-nestc>});
    $el->option (use_EmptyElemTag => 1);
  }
}

sub ____generate_attrnode ($%) {
  my ($self, %opt) = @_;
  my $attrnode = $opt{parent};
  for (@{$opt{list}}) {
    if ($_->{type} eq 'CDATA') {
      $attrnode->append_text (${$_->{value}});
    } elsif ($_->{type} eq 'entref') {
      my $ref = $attrnode->append_new_node
                     (type => '#reference',
                      namespace_uri => SGML_GENERAL_ENTITY,
                      local_name => ${$_->{value}});
      if ($_->{entval}) {
        $self->____generate_attrnode (list => $_->{entval}, parent => $ref);
        $ref->flag (ExpandedURI q<tree:expanded> => 1);
      }
    } elsif ($_->{type} eq 'ncref') {
      $attrnode->append_new_node
                     (type => '#reference',
                      namespace_uri => SGML_NCR,
                      value => $_->{value});
    } elsif ($_->{type} eq 'hcref') {
      $attrnode->append_new_node
                     (type => '#reference',
                      namespace_uri => SGML_HEX_CHAR_REF,
                      value => $_->{value});
    } else {
      die "$0: start_tag: bug: $_->{type}";
    }
  }  
} # ____generate_attrnode

sub element_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
     ->append_text (${$pp->{ExpandedURI q<CDATA>}});
}

sub attribute_specifications_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attr>}
    = $pp->{ExpandedURI q<tree:attr>} = [];
}
sub attribute_specifications_end ($$$$%) {

}
sub attribute_specification_start ($$$$%) {

}
sub attribute_specification_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:attr>}},
    {name => $pp->{ExpandedURI q<attribute-name>}, 
     value => $pp->{ExpandedURI q<tree:attr-val>}};
}
sub attribute_value_specification_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attr-val>} = [];
  $pp->{ExpandedURI q<tree:attr-val>}
    = $p->{ExpandedURI q<tree:attr-val>};
}
sub attribute_value_specification_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$pp->{ExpandedURI q<tree:attr-val>}},
       {type => 'CDATA', value => $pp->{ExpandedURI q<CDATA>}};
}
sub attribute_value_specification_end ($$$$%) {
  
}

sub general_entity_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entname = $pp->{ExpandedURI q<entity-name>};
  my $entval;
  if ($pp->{ExpandedURI q<entity-opened>}) {
    #
  } elsif (my $ent = $self->{ExpandedURI q<tree:general-entity>}->{$$entname}) {
    ## TODO: Isdeclaredexternally
    if ($ent->{entity_data_notation}) {
      $self->{error}->set_flag (\(my $dummy = ''),
                                ExpandedURI q<is-unparsed-entity> => 1);
      push @{$opt{ExpandedURI q<source>}}, \$dummy;
    } else {
      $self->____read_entity ($ent) if not $ent->{is_read} and $ent->{can_read};
      if ($ent->{is_read}) {
        push @{$opt{ExpandedURI q<source>}}, $ent->{replacement_text};
        $pp->{ExpandedURI q<tree:attr-val>} = $entval = [];
      } else {
        $self->{error}->report
          (-type => 'EXTERNAL_GENERAL_ENTITY_NOT_READ',
           -class => 'Misc',
           source => $entname,
           entity_name => $$entname);
      }
    }
  } else {
    $self->{error}->report
        (-type => 'VC_ENTITY_DECLARED__GENERAL',
         -class => 'VC',
         source => $entname,
         entity_name => $$entname);
  }
  push @{$p->{ExpandedURI q<tree:attr-val>}},
    {type => 'entref', value => $entname, entval => $entval};
} # general_entity_reference_in_attribute_value_literal_start

sub numeric_character_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:attr-val>}},
    {type => 'ncref', value => $pp->{ExpandedURI q<character-number>}};
}

sub hex_character_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:attr-val>}},
    {type => 'hcref', value => $pp->{ExpandedURI q<character-number>}};
}

sub general_entity_reference_in_content_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entname = $pp->{ExpandedURI q<entity-name>};
  my $ref = $pp->{ExpandedURI q<tree:current>}
          = $p->{ExpandedURI q<tree:current>}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_GENERAL_ENTITY,
                   local_name => $$entname);
  if ($pp->{ExpandedURI q<entity-opened>}) {
    return;
  } elsif (my $ent = $self->{ExpandedURI q<tree:general-entity>}->{$$entname}) {
    ## TODO: Isdeclaredexternally
    if ($ent->{entity_data_notation}) {
      $self->{error}->set_flag (\(my $dummy = ''),
                                ExpandedURI q<is-unparsed-entity> => 1);
      push @{$opt{ExpandedURI q<source>}}, \$dummy;
      return;
    }
    $self->____read_entity ($ent) if not $ent->{is_read} and $ent->{can_read};
    if ($ent->{is_read}) {
      push @{$opt{ExpandedURI q<source>}}, $ent->{replacement_text};
      $ref->flag (ExpandedURI q<tree:expanded> => 1);
    } else {
      $self->{error}->report
        (-type => 'EXTERNAL_GENERAL_ENTITY_NOT_READ',
         -class => 'Misc',
         source => $entname,
         entity_name => $$entname);
    }
  } else {
    $self->{error}->report
        (-type => 'VC_ENTITY_DECLARED__GENERAL',
         -class => 'VC',
         source => $entname,
         entity_name => $$entname);
  }
} # general_entity_reference_in_content_start


sub numeric_character_reference_in_content_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:current>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_NCR,
                value => $pp->{ExpandedURI q<character-number>});
}

sub hex_character_reference_in_content_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:current>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_HEX_CHAR_REF,
                value => $pp->{ExpandedURI q<character-number>});
}

sub doctype_declaration_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
    = my $doctype
    = $p->{ExpandedURI q<tree:current>}
        ->append_new_node
            (type => '#declaration',
             namespace_uri => SGML_DOCTYPE);
}

sub doctype_internal_subset_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $opt{ppp}->{ExpandedURI q<tree:current>}
      = $pp->{ExpandedURI q<tree:current>}
          ->append_new_node
              (type => '#element',
               namespace_uri => SGML_DOCTYPE,
               local_name => 'subset');
} # doctype_internal_subset_start

sub doctype_external_subset_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $ref = $pp->{ExpandedURI q<tree:current>};
  $self->____read_entity (my $ent = {
    name => '!DOCTYPE',
    public_id => ${$pp->{ExpandedURI q<tree:PUBLIC>}||\undef},
    system_id => ${$pp->{ExpandedURI q<tree:SYSTEM>}||\undef},
    base_uri => $self->{error}->get_flag ($src, ExpandedURI q<base-uri>),
    is_read => 0, can_read => 1,
  });
  if ($ent->{is_read}) {
    $pp->{ExpandedURI q<external-subset-source>} = $ent->{replacement_text};
    $ref->flag (ExpandedURI q<tree:expanded> => 1);
  } else {
    $self->{error}->report
        (-type => 'EXTERNAL_SUBSET_NOT_READ',
         -class => 'Misc',
         source => $src);
  }
} # doctype_external_subset_start

sub doctype_declaration_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $doctype = $pp->{ExpandedURI q<tree:current>};
  $doctype->set_attribute (qname => ${$pp->{ExpandedURI q<doctype>} || \""});
  for ($pp->{ExpandedURI q<tree:PUBLIC>}) {
    $doctype->set_attribute (PUBLIC => $$_) if $_;
  }
  for ($pp->{ExpandedURI q<tree:SYSTEM>}) {
    $doctype->set_attribute (SYSTEM => $$_) if $_;
  }
}

sub doctype_subset_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $type = $opt{ExpandedURI q<subset-type>} || '';
  $pp->{ExpandedURI q<tree:current>} ||= $p->{ExpandedURI q<tree:current>};
}

sub doctype_subset_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  if ($pp->{ExpandedURI q<s>}) {
    $pp->{ExpandedURI q<tree:current>}
       ->append_text (${$pp->{ExpandedURI q<s>}});
  } elsif ($pp->{ExpandedURI q<CDATA>}) {
    $pp->{ExpandedURI q<tree:current>}
       ->append_text (${$pp->{ExpandedURI q<CDATA>}});
  }
}

sub entity_declaration_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entity = $pp->{ExpandedURI q<tree:current>}
             = $p->{ExpandedURI q<tree:current>}
                 ->append_new_node
                     (type => '#declaration',
                      namespace_uri => SGML_GENERAL_ENTITY);
  $entity->base_uri ($pp->{ExpandedURI q<infoset:baseURI>});
}

sub entity_value_content ($$$$%) {

}

sub entity_declaration_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entity = $pp->{ExpandedURI q<tree:current>};
  my $entname = $pp->{ExpandedURI q<entity-name>};
  my $parament = $pp->{ExpandedURI q<entity-type>} eq 'parameter' ? 1 : 0;
  my $entman = ($parament ?
                   $self->{ExpandedURI q<tree:param-entity>}:
                   $self->{ExpandedURI q<tree:general-entity>}) ||= {};

  $entity->namespace_uri (SGML_PARAM_ENTITY) if $parament;
  $entity->local_name ($$entname);
  $self->report
               (-type => $parament ? 'PARAM_ENTITY_NAME_USED' :
                                     'GENERAL_ENTITY_NAME_USED',
                -class => 'W3C',
                source => $entname,
                entity_name => $$entname)
     if $entman->{$$entname};
  if ($pp->{ExpandedURI q<entity-value>}) {
    my $entval = '';
    my $value = $entity->get_attribute ('value', make_new_node => 1);
    for (@{$pp->{ExpandedURI q<entity-value>}
              ->{ExpandedURI q<tree:entity-value>}}) {
      if ($_->{type} eq 'CDATA') {
        $entval .= ${$_->{value}};
        $value->append_text (${$_->{value}});
      } elsif ($_->{type} eq 'param-ref' and $_->{value}) {
        $entval .= ${$_->{value}};
        $value->append_text (${$_->{value}});
      } elsif ($_->{type} eq 'ncr') {
        $entval .= chr $_->{value};
        $value->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_NCR,
                   value => $_->{value});
      } elsif ($_->{type} eq 'hcr') {
        $entval .= chr $_->{value};
        $value->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_HEX_CHAR_REF,
                   value => $_->{value});
      } elsif ($_->{type} eq 'general-ref') {
        $entval .= '&'.${$_->{name}}.';';
        $value->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_GENERAL_ENTITY,
                   value => ${$_->{name}});
      }
    }
    pos ($entval) = 0;
    $self->{error}->fork_position
                      ($src => \$entval,
                       line => 0, char => 0,
                       ExpandedURI q<entity-type> => $parament ? 'parameter' :
                                                                 'general',
                       ExpandedURI q<entity-name> => $entname);
    $entman->{$$entname} ||= {name => $$entname,
                              type => $parament ? 'parameter' : 'general',
                              replacement_text => \$entval,
                              is_read => 1, can_read => 1};
  }
  if ($pp->{ExpandedURI q<tree:SYSTEM>}) {
    $entity->set_attribute (SYSTEM => ${$pp->{ExpandedURI q<tree:SYSTEM>}});
    $entman->{$$entname}
               ||= my $ent = {name => $$entname,
                              type => $parament ? 'parameter' : 'general',
                              system_id => ${$pp->{ExpandedURI q<tree:SYSTEM>}},
                              is_read => 0, can_read => 1};
    if ($pp->{ExpandedURI q<tree:PUBLIC>}) {
      $entity->set_attribute (PUBLIC => ${$pp->{ExpandedURI q<tree:PUBLIC>}});
      $ent->{public_id} = ${$pp->{ExpandedURI q<tree:PUBLIC>}};
    }
    if ($pp->{ExpandedURI q<entity-data-notation>}) {
      $entity->set_attribute
                 (NDATA => ${$pp->{ExpandedURI q<entity-data-notation>}});
      $ent->{entity_data_notation}
               = ${$pp->{ExpandedURI q<entity-data-notation>}};
    }
    $ent->{base_uri} = $pp->{ExpandedURI q<infoset:baseURI>};
  }
}

sub notation_declaration_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
             = $p->{ExpandedURI q<tree:current>}
                 ->append_new_node
                     (type => '#declaration',
                      namespace_uri => SGML_NOTATION);
}

sub notation_declaration_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  for my $NOTATION ($pp->{ExpandedURI q<tree:current>}) {
    $NOTATION->local_name (${$pp->{ExpandedURI q<notation-name>}})
      if $pp->{ExpandedURI q<notation-name>};
    $NOTATION->set_attribute (PUBLIC => ${$pp->{ExpandedURI q<tree:PUBLIC>}})
      if $pp->{ExpandedURI q<tree:PUBLIC>};
    $NOTATION->set_attribute (SYSTEM => ${$pp->{ExpandedURI q<tree:SYSTEM>}})
      if $pp->{ExpandedURI q<tree:SYSTEM>};
  }
}

sub element_declaration_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
             = $p->{ExpandedURI q<tree:current>}
                 ->append_new_node
                     (type => '#declaration',
                      namespace_uri => SGML_ELEMENT);
}

sub model_group_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  ($pp->{ExpandedURI q<tree:physical>} = $p->{ExpandedURI q<tree:physical>})
     ->{$opt{ExpandedURI q<source>}->[-1]}
             = $pp->{ExpandedURI q<tree:current>}
             = $p->{ExpandedURI q<tree:current>}
                 ->append_new_node
                     (type => '#element',
                      namespace_uri => SGML_ELEMENT,
                      local_name => 'group');
}

sub model_group_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  if ($pp->{ExpandedURI q<item-type>} eq 'gi') {
    my $el = $p->{ExpandedURI q<tree:current>}
               ->append_new_node
                     (type => '#element',
                      namespace_uri => SGML_ELEMENT,
                      local_name => 'element');
    $el->set_attribute (qname => ${$pp->{ExpandedURI q<element-type-name>}});
    $el->set_attribute (occurence => ${$pp->{ExpandedURI q<occurrence>}})
      if $pp->{ExpandedURI q<occurrence>};
  }
}

sub model_group_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $grp = $pp->{ExpandedURI q<tree:current>};
  $grp->set_attribute (occurence => ${$pp->{ExpandedURI q<occurrence>}})
    if $pp->{ExpandedURI q<occurrence>};
  $grp->set_attribute (connector => ${$pp->{ExpandedURI q<connector>}})
    if $pp->{ExpandedURI q<connector>};
}

sub element_declaration_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  for my $ELEMENT ($pp->{ExpandedURI q<tree:current>}) {
    $ELEMENT->set_attribute (qname => ${$pp->{ExpandedURI q<element-type-name>}})
      if $pp->{ExpandedURI q<element-type-name>};
    if ($pp->{ExpandedURI q<element-content-keyword>}) {
      if (${$pp->{ExpandedURI q<element-content-keyword>}} eq 'EMPTY') {
        $ELEMENT->set_attribute (content => 'EMPTY');
      } elsif (${$pp->{ExpandedURI q<element-content-keyword>}} eq 'ANY') {
        $ELEMENT->set_attribute (content => 'ANY');
      } else {
        $ELEMENT->set_attribute (content => 'mixed');
      }
    } else {
      $ELEMENT->set_attribute (content => 'element');
    }
  }
}

sub attlist_declaration_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
             = $p->{ExpandedURI q<tree:current>}
                 ->append_new_node
                     (type => '#declaration',
                      namespace_uri => SGML_ATTLIST);
}

sub attribute_definition ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $attrdef = $pp->{ExpandedURI q<tree:current>}
              = $p->{ExpandedURI q<tree:current>}
                  ->append_new_node
                     (type => '#element',
                      namespace_uri => XML_ATTLIST,
                      local_name => 'AttDef');
  $attrdef->set_attribute (qname => ${$pp->{ExpandedURI q<attribute-name>}})
    if $pp->{ExpandedURI q<attribute-name>};
  if ($pp->{ExpandedURI q<attribute-type>}) {
    if (${$pp->{ExpandedURI q<attribute-type>}} eq 'group') {
      $attrdef->set_attribute (type => 'enum');
    } else {
      $attrdef->set_attribute (type => ${$pp->{ExpandedURI q<attribute-type>}});
    }
# TODO: enum & NOTATION
  }
  if ($pp->{ExpandedURI q<attribute-default>}) {
    if (${$pp->{ExpandedURI q<attribute-default>}} eq 'specific') {
      
    } else {
      $attrdef->set_attribute
                  (default_type => ${$pp->{ExpandedURI q<attribute-default>}});
    }
# TODO: specific & FIXED
  }
} # attribute_definition

sub attlist_declaration_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  for my $ELEMENT ($pp->{ExpandedURI q<tree:current>}) {
    $ELEMENT->set_attribute (qname => ${$pp->{ExpandedURI q<element-type-name>}})
      if $pp->{ExpandedURI q<element-type-name>};
  }
}

sub markup_declaration_parameters_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:physical>}
     ->{$opt{ExpandedURI q<source>}->[-1]}
       = $pp->{ExpandedURI q<tree:current>};
}

sub markup_declaration_parameter ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $param = $pp->{ExpandedURI q<parameter>};
  if ($param->{type} eq 'ps' or
      $param->{type} eq 'Name' or
      $param->{type} eq 'peroName') {
    $p->{ExpandedURI q<tree:physical>}
      ->{$opt{ExpandedURI q<source>}->[-1]}
      ->append_text (${$param->{value}});
  } elsif ($param->{type} eq 'rniKeyword') {
    $p->{ExpandedURI q<tree:physical>}
      ->{$opt{ExpandedURI q<source>}->[-1]}
      ->append_text ('#'.${$param->{value}});
  } elsif ($param->{type} eq 'syslit' or $param->{type} eq 'publit') {
    $p->{ExpandedURI q<tree:physical>}
      ->{$opt{ExpandedURI q<source>}->[-1]}
      ->append_new_node (type => '#xml',
                         value => $param->{delimiter}.
                                  ${$param->{value}}.
                                  $param->{delimiter});
  } elsif ($param->{type} eq 'pero') {
    $p->{ExpandedURI q<tree:physical>}
      ->{$opt{ExpandedURI q<source>}->[-1]}
      ->append_new_node (type => '#xml', value => '%');
  }
}

sub parameter_entity_reference_in_subset_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entname = $pp->{ExpandedURI q<entity-name>};
  my $ref = $pp->{ExpandedURI q<tree:current>}
          = $p->{ExpandedURI q<tree:current>}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_PARAM_ENTITY,
                   local_name => $$entname);
  if (my $ent = $self->{ExpandedURI q<tree:param-entity>}->{$$entname}) {
    ## TODO: Isdeclaredexternally
    if ($ent->{entity_data_notation}) {
      $self->{error}->set_flag (\(my $dummy = ''),
                                ExpandedURI q<is-unparsed-entity> => 1);
      push @{$opt{ExpandedURI q<source>}}, \$dummy;
      $p->{ExpandedURI q<tree:physical>}->{\$dummy} = $ref;
      return;
    }
    $self->____read_entity ($ent) if not $ent->{is_read} and $ent->{can_read};
    if ($ent->{is_read}) {
      my $value = \(' '.${$ent->{replacement_text}}.' ');
      pos ($$value) = 0;
      $self->{error}->fork_position ($ent->{replacement_text} => $value);
      push @{$opt{ExpandedURI q<source>}}, $value;
      $p->{ExpandedURI q<tree:physical>}->{$value} = $ref;
      $ref->flag (ExpandedURI q<tree:expanded> => 1);
    } else {
      $self->{error}->report
        (-type => 'EXTERNAL_PARAM_ENTITY_NOT_READ',
         -class => 'Misc',
         source => $entname,
         entity_name => $$entname);
    }
  } else {
    $self->{error}->report
        (-type => 'VC_ENTITY_DECLARED__PARAM',
         -class => 'VC',
         source => $entname,
         entity_name => $$entname);
  }
} # parameter_entity_reference_in_subset_start

sub parameter_entity_reference_in_parameter_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entname = $pp->{ExpandedURI q<entity-name>};
  my $ref = $p->{ExpandedURI q<tree:physical>}
              ->{$opt{ExpandedURI q<source>}->[-1]}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_PARAM_ENTITY,
                   local_name => $$entname);
  if (my $ent = $self->{ExpandedURI q<tree:param-entity>}->{$$entname}) {
    ## TODO: Isdeclaredexternally
    if ($ent->{entity_data_notation}) {
      $self->{error}->set_flag (\(my $dummy = ''),
                                ExpandedURI q<is-unparsed-entity> => 1);
      push @{$opt{ExpandedURI q<source>}}, \$dummy;
      $p->{ExpandedURI q<tree:physical>}->{\$dummy} = $ref;
      return;
    }
    $self->____read_entity ($ent) if not $ent->{is_read} and $ent->{can_read};
    if ($ent->{is_read}) {
      my $value = \(' '.${$ent->{replacement_text}}.' ');
      pos ($$value) = 0;
      $self->{error}->fork_position ($ent->{replacement_text} => $value);
      push @{$opt{ExpandedURI q<source>}}, $value;
      $p->{ExpandedURI q<tree:physical>}->{$value} = $ref;
      $ref->flag (ExpandedURI q<tree:expanded> => 1);
    } else {
      $self->{error}->report
        (-type => 'EXTERNAL_PARAM_ENTITY_NOT_READ',
         -class => 'Misc',
         source => $entname,
         entity_name => $$entname);
    }
  } else {
    $self->{error}->report
        (-type => 'VC_ENTITY_DECLARED__PARAM',
         -class => 'VC',
         source => $entname,
         entity_name => $$entname);
  }
}

sub public_identifier_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:PUBLIC>} = $pp->{ExpandedURI q<public-id>};
}

sub system_identifier_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:SYSTEM>} = $pp->{ExpandedURI q<system-id>};
}

sub parameter_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:physical>}
    = $p->{ExpandedURI q<tree:physical>};
}

sub rpdata_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:entity-value>}
    = $p->{ExpandedURI q<tree:entity-value>} = [];
  $pp->{ExpandedURI q<tree:physical>}
    = $p->{ExpandedURI q<tree:physical>};
  $pp->{ExpandedURI q<tree:physical>}
     ->{$opt{ExpandedURI q<source>}->[-1]}
     ->append_new_node (type => '#xml', value => '"');
}

sub rpdata_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:entity-value>}},
       {type => 'CDATA', value => $pp->{ExpandedURI q<CDATA>}};
  $pp->{ExpandedURI q<tree:physical>}
     ->{$opt{ExpandedURI q<source>}->[-1]}
     ->append_new_node (type => '#xml', value => ${$pp->{ExpandedURI q<CDATA>}});
}

sub numeric_character_reference_in_rpdata_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $cn = $pp->{ExpandedURI q<character-number>} + 0;
  my $ref = $p->{ExpandedURI q<tree:physical>}
              ->{$opt{ExpandedURI q<source>}->[-1]}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_NCR,
                   value => $cn);
  push @{$p->{ExpandedURI q<tree:entity-value>}},
       {type => 'ncr', value => $cn};
}

sub hex_character_reference_in_rpdata_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $cn = $pp->{ExpandedURI q<character-number>} + 0;
  my $ref = $p->{ExpandedURI q<tree:physical>}
              ->{$opt{ExpandedURI q<source>}->[-1]}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_HEX_CHAR_REF,
                   value => $cn);
  push @{$p->{ExpandedURI q<tree:entity-value>}},
    {type => 'hcr', value => $cn};
}

sub general_entity_reference_in_rpdata_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $cn = $pp->{ExpandedURI q<entity-name>};
  my $ref = $p->{ExpandedURI q<tree:physical>}
              ->{$opt{ExpandedURI q<source>}->[-1]}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_GENERAL_ENTITY,
                   local_name => $cn);
  push @{$p->{ExpandedURI q<tree:entity-value>}},
    {type => 'general-ref', name => $cn};
}

sub parameter_entity_reference_in_rpdata_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $entname = $pp->{ExpandedURI q<entity-name>};
  my $ref = $p->{ExpandedURI q<tree:physical>}
              ->{$opt{ExpandedURI q<source>}->[-1]}
              ->append_new_node
                  (type => '#reference',
                   namespace_uri => SGML_PARAM_ENTITY,
                   local_name => $$entname);
  if (my $ent = $self->{ExpandedURI q<tree:param-entity>}->{$$entname}) {
    ## TODO: Isdeclaredexternally
    if ($ent->{entity_data_notation}) {
      $self->{error}->set_flag (\(my $dummy = ''),
                                ExpandedURI q<is-unparsed-entity> => 1);
      push @{$opt{ExpandedURI q<source>}}, \$dummy;
      $p->{ExpandedURI q<tree:physical>}->{\$dummy} = $ref;
      push @{$p->{ExpandedURI q<tree:entity-value>}},
           {type => 'param-ref', name => $entname};
      return;
    }
    $self->____read_entity ($ent) if not $ent->{is_read} and $ent->{can_read};
    if ($ent->{is_read}) {
      my $value = $ent->{replacement_text};
      $self->{error}->fork_position ($ent->{replacement_text} => $value);
      push @{$opt{ExpandedURI q<source>}}, $value;
      $p->{ExpandedURI q<tree:physical>}->{$value} = $ref;
      $ref->flag (ExpandedURI q<tree:expanded> => 1);
      push @{$p->{ExpandedURI q<tree:entity-value>}},
           {type => 'param-ref', name => $entname, value => $value};
    } else {
      ## TODO: warning of unread
      
      push @{$p->{ExpandedURI q<tree:entity-value>}},
           {type => 'param-ref', name => $entname};
    }
  } else {
    $self->{error}->report
        (-type => 'VC_ENTITY_DECLARED__PARAM',
         -class => 'VC',
         source => $entname,
         entity_name => $$entname);
    push @{$p->{ExpandedURI q<tree:entity-value>}},
         {type => 'param-ref', name => $entname};
  }
}

sub rpdata_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:physical>}
     ->{$opt{ExpandedURI q<source>}->[-1]}
     ->append_new_node (type => '#xml', value => '"');
}

sub comment_declaration_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>}
        ->append_new_node
            (type => '#comment');
}

sub comment_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>};
}

sub comment_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
     ->append_text ($pp->{ExpandedURI q<CDATA>});
}

sub xml_declaration ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $xml = $p->{ExpandedURI q<tree:current>}
              ->append_new_node
                   (type => '#pi',
                    local_name => 'xml');
  $xml->set_attribute (version => $pp->{ExpandedURI q<xml-declaration-version>})
    if defined $pp->{ExpandedURI q<xml-declaration-version>};
  $xml->set_attribute (encoding
                       => $pp->{ExpandedURI q<xml-declaration-encoding>})
    if defined $pp->{ExpandedURI q<xml-declaration-encoding>};
  $xml->set_attribute (standalone
                       => $pp->{ExpandedURI q<xml-declaration-standalone>})
    if defined $pp->{ExpandedURI q<xml-declaration-standalone>};
  for (@{$pp->{ExpandedURI q<xml-declaration-pseudo-attr-misc>}||[]}) {
    $xml->set_attribute (${$_->[0]->{name}} => ${$_->[0]->{value}});
  }
}

sub processing_instruction_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $target_name = $pp->{ExpandedURI q<target-name>};
  $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>}
        ->append_new_node
               (type => '#pi',
                local_name => $target_name);
}

sub processing_instruction_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $style = $pp->{ExpandedURI q<tree:pi-parse-style>} || '';
  my $pi = $pp->{ExpandedURI q<tree:current>};
  my $data = $pp->{ExpandedURI q<target-data>};
  $pi->append_text ($$data);
}

sub processing_instruction_end ($$$$%) {

}

sub ____read_entity ($$;%) {
  my ($self, $ent, %opt) = @_;
  if (my $rr = $self->{ExpandedURI q<tree:resource-resolver>}) {
    my $result = $rr->get_resource
                      (%opt,
                       ExpandedURI q<rrx:convert-into-internal> => 1,
                       ExpandedURI q<infoset:declarationBaseURI>
                                             => $ent->{base_uri},
                       ExpandedURI q<infoset:systemIdentifier>
                                             => $ent->{system_id},
                       ExpandedURI q<infoset:publicIdentifier>
                                             => $ent->{public_id},
                       ExpandedURI q<infoset:notationName>
                                              => $ent->{entity_data_notation},
                       ExpandedURI q<infoset:name> => $ent->{name});
    if ($result->{ExpandedURI q<rr:success>}) {
      my $litval = \($result->{ExpandedURI q<rrx:literal-entity-value>});
      $self->{error}->reset_position
                        ($litval,
                         ExpandedURI q<uri>
                                => $result->{ExpandedURI q<uri>});
      $self->parse_external_parsed_entity
               ($litval, $result, %opt);
      if ($result->{ExpandedURI q<tree:replacement-text>}) {
        $ent->{replacement_text}
            = $result->{ExpandedURI q<tree:replacement-text>};
        $ent->{is_read} = 1;
      } else {
        $ent->{can_read} = 0;
      }
    } else {
      $ent->{can_read} = 0;
    }
  } else {
    $ent->{can_read} = 0;
  }
}

sub external_parsed_entity_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
    = $self->_NODE_PACKAGE_->new (type => '#fragment');
}

sub external_parsed_entity_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:replacement-text>} = $pp->{ExpandedURI q<CDATA>};
}

=head1 SEE ALSO

C<Message::Markup::XML::Parser::Base>,
C<Message::Markup::XML::Node>

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/08/03 04:19:53 $
