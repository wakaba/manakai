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
our $VERSION = do{my @r=(q$Revision: 1.1.2.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::Markup::XML::Parser::NodeTree;
push our @ISA, 'Message::Markup::XML::Parser';
use Message::Markup::XML::Parser;
use Message::Markup::XML::QName qw/:prefix/;
use Message::Markup::XML::Node qw/:charref :entity/;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>
}
use Message::Util::QName::General [qw/ExpandedURI/],
  {
   (DEFAULT_PFX) => Message::Markup::XML::Parser::URI_CONFIG (),
   tree => URI_CONFIG,
  };

sub _NODE_PACKAGE_ () {
  q<Message::Markup::XML::Node>
}

sub element_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:parent>}
    = $p->{ExpandedURI q<tree:current>};
}

sub start_tag_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:current>}
    = $p->{ExpandedURI q<tree:parent>}
        ->append_new_node
            (type => '#element',
             local_name => $pp->{ExpandedURI q<element-type-name>});
}

sub start_tag_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $el = $p->{ExpandedURI q<tree:current>};
  
  ## Attributes
  my %attr;
  for (@{$pp->{ExpandedURI q<tree:attribute>}}) {
    if ($attr{$_->[0]}++) {
      $self->report
                (-type => 'WFC_UNIQUE_ATT_SPEC',
                 -class => 'WFC',
                 source => $src,
                 position_diff => 1,
                 attribute_name => $_->[0]);
      next;
    }
    $el->get_attribute ($_->[0], make_new_node => 1)
       ->append_node ($_->[1]);
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
     ->append_text ($pp->{ExpandedURI q<CDATA>});
}

sub attribute_specifications_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:attribute>} = [];
}

sub attribute_specifications_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attribute>}
    = $pp->{ExpandedURI q<tree:attribute>};
  $p->{ExpandedURI q<tree:s-between-attribute-specifications>}
    = $pp->{ExpandedURI q<s-between-attribute-specifications>};
}

sub attribute_specification_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $pp->{ExpandedURI q<tree:attribute-value>}
    = ($opt{ExpandedURI q<tree:package>} || $self->_NODE_PACKAGE_)
         ->new (type => '#fragment');
}

sub attribute_specification_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<tree:attribute>}},
       [$pp->{ExpandedURI q<attribute-name>},
        $pp->{ExpandedURI q<tree:attribute-value>}];
}

sub attribute_value_specification_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  ($pp->{ExpandedURI q<tree:attribute-value>}
     = $p->{ExpandedURI q<tree:attribute-value>})
    ->flag (ExpandedURI q<tree:value-position>
               => $pp->{ExpandedURI q<position>});
}

sub attribute_value_specification_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attribute-value>}
    ->append_text ($pp->{ExpandedURI q<CDATA>});
}

sub general_entity_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attribute-value>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_GENERAL_ENTITY,
                local_name => $pp->{ExpandedURI q<entity-name>});
}

sub numeric_character_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attribute-value>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_NCR,
                value => $pp->{ExpandedURI q<character-number>});
}

sub hex_character_reference_in_attribute_value_literal_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:attribute-value>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_HEX_CHAR_REF,
                value => $pp->{ExpandedURI q<character-number>});
}

sub general_entity_reference_in_content_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<tree:current>}
    ->append_new_node
               (type => '#reference',
                namespace_uri => SGML_GENERAL_ENTITY,
                local_name => $pp->{ExpandedURI q<entity-name>});
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

sub processing_instruction_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $target_name = $pp->{ExpandedURI q<target-name>};
  $pp->{ExpandedURI q<tree:pi-parse-style>} = {
    zml => ExpandedURI q<tree:pseudo-attribute-noref>,
    'xml-stylesheet' => ExpandedURI q<tree:pseudo-attribute>,
  }->{$target_name};
  if ($target_name eq 'xml') {
    if ($opt{ExpandedURI q<allow-xml-declaration>}) {
      $pp->{ExpandedURI q<tree:pi-parse-style>}
        = ExpandedURI q<tree:xml-declaration>;
      if ($opt{ExpandedURI q<allow-text-declaration>}) {
        $pp->{ExpandedURI q<tree:xml-pi-type>}
          = ExpandedURI q<tree:xml-or-text-declaration>;
      } else {
        $pp->{ExpandedURI q<tree:xml-pi-type>}
          = ExpandedURI q<tree:xml-declaration>;
      }
    } elsif ($opt{ExpandedURI q<allow-text-declaration>}) {
      $pp->{ExpandedURI q<tree:pi-parse-style>}
        = ExpandedURI q<tree:xml-declaration>;
      $pp->{ExpandedURI q<tree:xml-pi-type>}
        = ExpandedURI q<tree:text-declaration>;
    } else {
      $self->report
               (-type => 'SYNTAX_XML_DECLARATION_IN_MIDDLE',
                -class => 'WFC',
                source => $src,
                position_diff => 5);
    }
  } elsif (length $target_name == 3 and lc $target_name eq 'xml') {
    $self->report
               (-type => 'SYNTAX_PI_TARGET_XML',
                -class => 'WFC',
                source => $src,
                target_name => $target_name,
                position_diff => 3);
  }
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
  if ($style eq ExpandedURI q<tree:pseudo-attribute>) {

  } elsif ($style eq ExpandedURI q<tree:pseudo-attribute-noref>) {

  } elsif ($style eq ExpandedURI q<tree:xml-declaration>) {
    $style = $pp->{ExpandedURI q<tree:xml-pi-type>};
    $self->parse_attribute_specifications
              ($data, $pp,
               %opt,
               ExpandedURI q<s-before-attribute-specifications> => ' ',
               ExpandedURI q<allow-numeric-character-reference> => 0,
               ExpandedURI q<allow-hex-character-reference> => 0,
               ExpandedURI q<allow-general-entity-reference> => 0);
    my $attr = $pp->{ExpandedURI q<tree:attribute>};
    my $sep = $pp->{ExpandedURI q<tree:s-between-attribute-specifications>};
    if ($attr->[0] and $attr->[0]->[0] eq 'version') {
      my $v = $attr->[0]->[1]->inner_text;
      if ($v eq '1.0' or $v eq '1.1') {
        $opt{ExpandedURI q<tree:document>}->{ExpandedURI q<tree:xml-version>}
          = $v;
      } else {
        my $vpos = $attr->[0]->[1]->flag (ExpandedURI q<tree:value-position>)
                 || [];
        $self->{error}->reset_position
                          (\(my $pos = ''), line => $vpos->[0],
                                            char => $vpos->[1]);
        unless ($v =~ /^[0-9A-Za-z.:_-]+$/) {
          $self->report
              (-type => 'SYNTAX_XML_VERSION_INVALID',
               -class => 'WFC',
               source => \$pos,
               version => $v);
        }
        $self->report
              (-type => 'SYNTAX_XML_VERSION_UNSUPPORTED',
               -class => 'WFC',
               source => \$pos,
               version => $v);
        $opt{ExpandedURI q<tree:document>}->{ExpandedURI q<tree:xml-version>}
          = '1.1';
      }
      $pi->set_attribute (version => $v);
      shift @$attr;  shift @$sep;
    } else {
      if ($style eq ExpandedURI q<tree:xml-declaration>) {
        $self->report
              (-type => 'SYNTAX_XML_VERSION_REQUIRED',
               -class => 'WFC',
               source => $data);
      } elsif ($style eq ExpandedURI q<tree:xml-or-text-declaration>) {
        $style = ExpandedURI q<tree:text-declaration>;
      }
    }
    
    if ($attr->[0] and $attr->[0]->[0] eq 'encoding') {
      my $v = $attr->[0]->[1]->inner_text;
      unless ($v =~ /^[A-Za-z][A-Za-z0-9._-]*$/) {
        my $vpos = $attr->[0]->[1]->flag (ExpandedURI q<tree:value-position>);
        $self->{error}->reset_position
                          (\(my $pos = ''), line => $vpos->[0],
                                            char => $vpos->[1]);
        $self->report
              (-type => 'SYNTAX_XML_ENCODING_INVALID',
               -class => 'WFC',
               source => \$pos,
               encoding => $v);
      }
      $pi->set_attribute (encoding => $v);
      shift @$attr;  shift @$sep;      
    } else {
      if ($style eq ExpandedURI q<tree:text-declaration>) {
        $self->report
              (-type => 'SYNTAX_XML_ENCODING_REQUIRED',
               -class => 'WFC',
               source => $data);
        $pi->set_attribute (encoding => 'x-unknown');
      }
    }
    
    if ($attr->[0] and $attr->[0]->[0] eq 'standalone') {
      my $v = $attr->[0]->[1]->inner_text;
      my $vpos = $attr->[0]->[1]->flag (ExpandedURI q<tree:value-position>);
      $self->{error}->reset_position
                        (\(my $pos = ''), line => $vpos->[0],
                                          char => $vpos->[1]);
      unless ($v eq 'yes' or $v eq 'no') {
        $self->report
              (-type => 'SYNTAX_XML_STANDALONE_INVALID',
               -class => 'WFC',
               source => \$pos,
               standalone => $v);
      }
      if ($style eq ExpandedURI q<tree:text-declaration>) {
        $self->report
              (-type => 'SYNTAX_XML_STANDALONE',
               -class => 'WFC',
               source => \$pos);
      } elsif ($style eq ExpandedURI q<tree:xml-or-text-declaration>) {
        $style = ExpandedURI q<tree:xml-declaration>;
      }
      unless ($sep->[0] =~ /^\x20+$/) {
        if ($opt{ExpandedURI q<tree:document>}
              ->{ExpandedURI q<tree:xml-version>} eq '1.1') {
          $self->report
              (-type => 'SYNTAX_XML_STANDALONE_S',
               -class => 'WFC',
               source => \$pos);
        } else {
          $self->report
              (-type => 'COMPAT_XML_STANDALONE_S',
               -class => 'WFC',
               source => \$pos);
        }
      }
      $pi->set_attribute (standalone => $v);
      shift @$attr;  shift @$sep;
    }
    
    for (@$attr) {
      my $vpos = $_->[1]->flag (ExpandedURI q<tree:value-position>);
      $self->{error}->reset_position
                        (\(my $pos = ''), line => $vpos->[0],
                                          char => $vpos->[1]);
      $self->report
              (-type => 'SYNTAX_XML_UNKNOWN_ATTR',
               -class => 'WFC',
               source => \$pos,
               attribute_name => $_->[0]);
      $pi->get_attribute ($_->[0], make_new_node => 1)
         ->append_node ($_->[1]);
    }
  } else {
    $pi->append_text ($$data);
  }
}

sub processing_instruction_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  
  ## Empty (target-name only) Processing Instruction
  unless ($pp->{ExpandedURI q<target-data>}) {
    my $target_name = $pp->{ExpandedURI q<target-name>};
    if (length $target_name == 3 and lc $target_name eq 'xml') {
      $self->report
               (-type => 'SYNTAX_PI_TARGET_XML',
                -class => 'WFC',
                source => $src,
                position_diff => 5); # length ('xml?>')
    }
  }
}

=head1 SEE ALSO

C<Message::Markup::XML::Parser>,
C<Message::Markup::XML::Node>

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/02/24 07:25:10 $
