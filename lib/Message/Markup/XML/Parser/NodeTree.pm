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
our $VERSION = do{my @r=(q$Revision: 1.1.2.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::Markup::XML::Parser::NodeTree;
push our @ISA, 'Message::Markup::XML::Parser::Base';
use Message::Markup::XML::Parser::Base;
use Message::Markup::XML::QName qw/:prefix/;
use Message::Markup::XML::Node qw/:charref :declaration :entity/;
use Message::Util::ResourceResolver::XML;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>
}
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG (),
   tree => URI_CONFIG,
   rr => Message::Util::ResourceResolver::Base::URI_CONFIG (),
   rrx => Message::Util::ResourceResolver::XML::URI_CONFIG (),
  };

sub _NODE_PACKAGE_ () {
  q<Message::Markup::XML::Node>
}

sub document_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>};
}

sub document_end ($$$$%) {
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
  for my $attrspec (@{$pp->{ExpandedURI q<tree:attr>}}) {
    my $attrnode = $el->get_attribute (${$attrspec->{name}}, make_new_node => 1);
    for (@{$attrspec->{value}}) {
      if ($_->{type} eq 'CDATA') {
        $attrnode->append_text (${$_->{value}});
      } elsif ($_->{type} eq 'entref') {
        $attrnode->append_new_node
                     (type => '#reference',
                      namespace_uri => SGML_GENERAL_ENTITY,
                      local_name => ${$_->{value}});
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
  }
  
  ## Null End Tag
  if ($p->{ExpandedURI q<tag-type>} eq 'empty') {
    $el->option (ExpandedURI q<s-preceding-nestc>
                   => $pp->{ExpandedURI q<s-preceding-nestc>});
    $el->option (use_EmptyElemTag => 1);
  }
}

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
}
sub attribute_value_specification_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:attr-val>}},
       {type => 'CDATA', value => $pp->{ExpandedURI q<CDATA>}};
  $pp->{ExpandedURI q<tree:attr-val>}
    = $p->{ExpandedURI q<tree:attr-val>};
}
sub attribute_value_specification_end ($$$$%) {
  
}

sub general_entity_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:attr-val>}},
    {type => 'entref', value => $pp->{ExpandedURI q<entity-name>}};
}

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
  $p->{ExpandedURI q<tree:current>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_GENERAL_ENTITY,
                local_name => ${$pp->{ExpandedURI q<entity-name>}});
}

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
  $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>}
        ->append_new_node
              (type => '#element',
               namespace_uri => SGML_DOCTYPE,
               local_name => 'subset');
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
      }
    }
    pos ($entval) = 0;
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
      $param->{type} eq 'peroName' or
      $param->{type} eq 'rniKeyword') {
    $p->{ExpandedURI q<tree:physical>}
      ->{$opt{ExpandedURI q<source>}->[-1]}
      ->append_text (${$param->{value}});
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
     ->append_text (${$pp->{ExpandedURI q<CDATA>}});
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
                       ExpandedURI q<SYSTEM> => $ent->{system_id},
                       ExpandedURI q<PUBLIC> => $ent->{public_id},
                       ExpandedURI q<entity-data-notation>
                                              => $ent->{entity_data_notation},
                       ExpandedURI q<entity-name> => $ent->{name});
    if ($result->{ExpandedURI q<rr:success>}) {
      $self->parse_external_parsed_entity
               (\ $result->{ExpandedURI q<rrx:literal-entity-value>},
                my $pp = {},
                %opt);
      if ($pp->{ExpandedURI q<tree:replacement-text>}) {
        $ent->{replacement_text} = $pp->{ExpandedURI q<tree:replacement-text>};
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

1; # $Date: 2004/06/27 06:34:07 $
