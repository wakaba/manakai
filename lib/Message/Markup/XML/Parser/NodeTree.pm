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
our $VERSION = do{my @r=(q$Revision: 1.1.2.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::Markup::XML::Parser::NodeTree;
push our @ISA, 'Message::Markup::XML::Parser::Base';
use Message::Markup::XML::Parser::Base;
use Message::Markup::XML::QName qw/:prefix/;
use Message::Markup::XML::Node qw/:charref :declaration :entity/;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>
}
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::Base::URI_CONFIG (),
   tree => URI_CONFIG,
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
  $pp->{ExpandedURI q<tree:current>}
     ->set_attribute (qname => ${$pp->{ExpandedURI q<doctype>} || \""});
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

=head1 SEE ALSO

C<Message::Markup::XML::Parser::Base>,
C<Message::Markup::XML::Node>

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/06/21 06:31:04 $
