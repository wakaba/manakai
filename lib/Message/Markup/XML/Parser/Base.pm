
=head1 NAME

Message::Markup::XML::Parser --- manakai: Simple XML parser

=head1 DESCRIPTION

This is a simple XML parser intended to be used with Message::Markup::XML.
After parsing of the XML document, this module returns a Message::Markup::XML
object so that you can handle XML document with that module (and other modules
implementing same interface).

This module is part of manakai.

=cut

package Message::Markup::XML::Parser::Base;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar InXMLChar
                        InXML_deprecated_noncharacter InXML_unicode_xml_not_suitable!;
require Message::Markup::XML::Parser::Error;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/>
}
use Message::Markup::XML::QName qw/DEFAULT_PFX/;
use Message::Util::QName::General [qw/ExpandedURI/],
    {
     (DEFAULT_PFX) => URI_CONFIG,
     tree => q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/TreeConstruct/>,
    };
my $REG_S = qr/[\x09\x0A\x0D\x20]/; 
        # S := 1*(U+0020 / U+0009 / U+000D / U+000A) ;; [3]

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->{error} ||= Message::Util::Error::TextParser->new
                       (package => 'Message::Markup::XML::Parser::Error');
  $self;
}

sub parse_element ($$$%) {
  my ($self, $src, $p, %opt) = @_;

  if ($$src =~ /\G(?=<\p{InXML_NameStartChar})/gc) {
    $self->element_start ($src, $p, my $pp = {}, %opt);
    $self->parse_start_tag
             ($src, $pp, %opt);
    my $ename = $pp->{ExpandedURI q<element-type-name>};
    
    if ($pp->{ExpandedURI q<tag-type>} eq 'start') {
      my $end_tag = 0;
      while (pos $$src < length $$src) {
        if ($$src =~ /\G([^<&]+)/gc) {
          local $pp->{ExpandedURI q<CDATA>} = $1;
          $self->element_content
                   ($src, $p, $pp, %opt);
        } elsif (substr ($$src, pos $$src, 1) eq '<') {
          my $n = substr ($$src, 1 + pos $$src, 1);
          if ($n eq '/') {
            if ($$src =~ m#\G</(\p{InXML_NameStartChar}\p{InXMLNameChar}*)#gc) {
              my $type = $1;
              if ($type eq $ename) {
                $$src =~ /\G$REG_S+/gco;
                $$src =~ /\G>/gc
                  or $self->report
                    (-type => 'SYNTAX_ETAGC_REQUIRED',
                     -class => 'WFC',
                     source => $src);
              } else {
                $self->report
                  (-type => 'WFC_ELEMENT_TYPE_MATCH',
                   -class => 'WFC',
                   source => $src,
                   position_diff => length $type,
                   start_tag_type_name => $ename,
                   end_tag_type_name => $type);
                my $tag = '</' . $type;
                $$src =~ /\G($REG_S+)/gco and $tag .= $1;
                if ($$src =~ /\G>/gc) {
                  $tag .= '>';
                } else {
                  $self->report
                    (-type => 'SYNTAX_ETAGC_REQUIRED',
                     -class => 'WFC',
                     source => $src);
                }
                local $pp->{ExpandedURI q<CDATA>} = $tag;
                $self->element_content
                  ($src, $p, $pp, %opt);
              }
              $self->end_tag_start ($src, $p, $pp, %opt);
              $self->end_tag_end ($src, $p, $pp, %opt);
              $end_tag = 1;
              last;
            } else {
              pos ($$src) += 2;
              $self->report
                 (-type => 'SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_ETAGO_REQUIRED',
                  -class => 'WFC',
                  source => $src);
              local $pp->{ExpandedURI q<CDATA>} = '</';
              $self->element_content
                   ($src, $p, $pp, %opt);
            }
          } elsif ($n eq '!') {
            $self->parse_markup_declaration
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = '<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          } elsif ($n eq '?') {
            $self->parse_processing_instruction
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = '<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          } else {
            $self->parse_element
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = '<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          }
        } elsif (substr ($$src, pos $$src, 1) eq '&') {
          $self->parse_reference_in_content
            ($src, $pp,
             %opt,
             ExpandedURI q<match-or-error> => 1);
        } else {
          Carp::croak "Buggy implementation!";
        }
      }
    
      unless ($end_tag) {
        $self->report
                 (-type => 'SYNTAX_END_TAG_REQUIRED',
                  -class => 'WFC',
                  source => $src,
                  element_type_name => $ename);
      }
    } # Not empty
    
    $self->element_end ($src, $p, $pp, %opt);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      if (substr ($$src, pos $$src, 1) eq '<') {
        $self->report
                 (-type => 'SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED',
                  -class => 'WFC',
                  source => $src,
                  position_diff => -1);
      } else {
        $self->report
                 (-type => 'SYNTAX_START_TAG_REQUIRED',
                  -class => 'WFC',
                  source => $src);
      }
    }
    return 0;
  }
}

sub parse_start_tag ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G</gc) {
    my $element_type;
    if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
      $element_type = $1;
    } elsif ($$src =~ /\G>/gc) {
      pos ($$src)--;
      $self->report
                (-type => 'SYNTAX_EMPTY_START_TAG',
                 -class => 'WFC',
                 source => $src,
                 position_diff => 1);
      return 0;
    } else {
      $self->report
                (-type => 'SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED',
                 -class => 'WFC',
                 source => $src);
      pos ($$src)--;
      return 0;
    }
    
    my $pp = {};
    $pp->{ExpandedURI q<element-type-name>}
      = $p->{ExpandedURI q<element-type-name>}
      = $element_type;
    $self->start_tag_start ($src, $p, $pp, %opt);
    
    $self->parse_attribute_specifications
            ($src, $pp,
             %opt,
             ExpandedURI q<s-before-attribute-specifications> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1,
             ExpandedURI q<allow-general-entity-reference> => 1);

    if ($$src =~ m#\G/#gc) {
      $p->{ExpandedURI q<tag-type>} = 'empty';
      $pp->{ExpandedURI q<s-preceding-nestc>}
        = $pp->{ExpandedURI q<s-after-attribute-specifications>};
      $self->start_tag_end ($src, $p, $pp, %opt);
      unless ($$src =~ /\G>/gc) {
        $self->report
                (-type => 'SYNTAX_NET_REQUIRED',
                 -class => 'WFC',
                 source => $src);
      }
      $self->end_tag_start ($src, $p, $pp, %opt);
      $self->end_tag_end ($src, $p, $pp, %opt);
    } else {
      $p->{ExpandedURI q<tag-type>} = 'start';
      unless ($$src =~ /\G>/gc) {
        $self->report
                 (-type => 'SYNTAX_STAGC_OR_NESTC_REQUIRED',
                  -class => 'WFC',
                  source => $src);
      }
      $self->start_tag_end ($src, $p, $pp, %opt);
    }
        
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
                (-type => 'SYNTAX_START_TAG_REQUIRED',
                 -class => 'WFC',
                 source => $src);
    }
    return 0;
  }
}

sub parse_attribute_specifications ($$$%) {
  my ($self, $src, $p, %opt) = @_;
    $self->attribute_specifications_start
                 ($src, $p, my $pp = {}, %opt);
    my $sep = $opt{ExpandedURI q<s-before-attribute-specifications>};
    my @sep = ($sep);
    while (pos $$src < length $$src) {
      if ($$src =~ /\G(?=\p{InXML_NameStartChar})/gc) {
        unless ($sep) {
          $self->report
            (-type => 'SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC',
             -class => 'WFC',
             source => $src);
          push @sep, ' ';
        }
        $self->parse_attribute_specification
                  ($src, $pp, %opt);
        $sep = 0;
      } elsif ($$src =~ /\G($REG_S+)/goc) {
        my $s = $1;
        push @sep, $s;
        $sep = 1;
      } elsif ($opt{ExpandedURI q<attr-specs-only>}) {
        $self->report
            (-type => 'SYNTAX_ATTR_SPEC_REQUIRED',
             -class => 'WFC',
             source => $src);
        $$src =~ /\G(?:(?!\p{InXML_NameStartChar})(?!$REG_S).)+/gocs;
      } else {
        last;
      }
    }
    $pp->{ExpandedURI q<s-between-attribute-specifications>} = \@sep;
    $p->{ExpandedURI q<s-after-attribute-specifications>} = $sep;
    
    $self->attribute_specifications_end
                  ($src, $p, $pp, %opt);
    return 1;
}

sub parse_attribute_specification ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)$REG_S*/ogc) {
    my $pp = {ExpandedURI q<attribute-name> => $1};
    $self->attribute_specification_start ($src, $p, $pp, %opt);
    if ($$src =~ /\G=$REG_S*/ogc) {
      $self->parse_attribute_value_specification 
        ($src, $pp,
         %opt,
         ExpandedURI q<match-or-error> => 1);
    } else {
      $self->report
        (-type => 'SYNTAX_VI_REQUIRED',
         -class => 'WFC',
         source => $src);
    }
    $self->attribute_specification_end ($src, $p, $pp, %opt);
    return 1;
  } elsif ($opt{ExpandedURI q<match-or-error>}) {
    $self->report
      (-type => 'SYNTAX_ATTR_NAME_REQUIRED',
       -class => 'WFC',
       source => $src);
    return 0;
  }
}

sub parse_attribute_value_specification ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G(["'])/gc) {
    my $pp = {};
    $pp->{ExpandedURI q<literal-delimiter>} = my $litdelim = $1;
    $self->{error}->set_position ($src, moved => 1);
    $pp->{ExpandedURI q<position>} = [$self->{error}->get_position ($src)];
    $self->attribute_value_specification_start ($src, $p, $pp, %opt);
    if ($litdelim eq '"') {
      while (pos $$src < length $$src) {
        if ($$src =~ /\G([^"&<]+)/gc) {
          my $s = $1;
          pos $s = 0;
          $self->{error}->set_position ($src, moved => 1);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
        } elsif ($$src =~ /\G(?=&)/gc) {
          unless ($self->parse_reference_in_attribute_value_literal
                   ($src, $pp,
                    %opt,
                    ExpandedURI q<match-or-error> => 1)) {
            my $s = '&';
            pos $s = 0;
            $self->{error}->set_position ($src, moved => 1);
            $self->{error}->fork_position ($src => \$s);
            local $pp->{ExpandedURI q<CDATA>} = \$s;
            pos ($$src)++;
            $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
          }
        } elsif ($$src =~ /\G</gc) {
          $self->report
                   (-type => 'WFC_NO_LESS_THAN_IN_ATTR_VAL',
                    -class => 'WFC',
                    source => $src,
                    position_diff => 1);
          my $s = '<';
          pos $s = 0;
          $self->{error}->set_position ($src, moved => 1);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
        } else {
          last;
        }
      }
      unless ($$src =~ /\G"/gc) {
        $self->report (-type => 'SYNTAX_ALITC_REQUIRED',
                       -class => 'WFC',
                       source => $src);
      }
    } else { #if ($litdelim eq "'")
      while (pos $$src < length $$src) {
        if ($$src =~ /\G([^'&<]+)/gc) {
          my $s = $1;
          pos $s = 0;
          $self->{error}->set_position ($src, moved => 1);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
        } elsif ($$src =~ /\G(?=&)/gc) {
          unless ($self->parse_reference_in_attribute_value_literal
                   ($src, $pp, 
                    %opt,
                    ExpandedURI q<match-or-error> => 1)) {
            my $s = '&';
            pos $s = 0;
            $self->{error}->set_position ($src, moved => 1);
            $self->{error}->fork_position ($src => \$s);
            local $pp->{ExpandedURI q<CDATA>} = \$s;
            pos ($$src)++;
            $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
          }
        } elsif ($$src =~ /\G</gc) {
          $self->report
                   (-type => 'WFC_NO_LESS_THAN_IN_ATTR_VAL',
                    -class => 'WFC',
                    source => $src,
                    position_diff => 1);
          my $s = '<';
          pos $s = 0;
          $self->{error}->set_position ($src, moved => 1);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
        } else {
          last;
        }
      }
      unless ($$src =~ /\G'/gc) {
        $self->report (-type => 'SYNTAX_ALITAC_REQUIRED',
                       -class => 'WFC',
                       source => $src);
      }
    }
    $self->attribute_value_specification_end ($src, $p, $pp, %opt);
    return 1;
  } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
    my $s = $1;
    $self->attribute_value_specification_start ($src, $p, my $pp = {}, %opt);
    $self->report (-type => 'SYNTAX_ATTRIBUTE_VALUE',
                   -class => 'WFC',
                   source => $src,
                   position_diff => length $s);
    pos $s = 0;
    $self->{error}->set_position ($src, moved => 1);
    $self->{error}->fork_position ($src => \$s);
    local $pp->{ExpandedURI q<CDATA>} = \$s;
    $self->attribute_value_specification_content
                   ($src, $p, $pp, %opt);
    $self->attribute_value_specification_end ($src, $p, $pp, %opt);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
                  (-type => 'SYNTAX_ALITO_OR_ALITAO_REQUIRED',
                   -class => 'WFC',
                   source => $src);
    }
    return 0;
  }
}

sub parse_reference_in_attribute_value_literal ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G&/gc) {
    if ($$src =~ /\G\#/gc) {
      if ($$src =~ /\Gx/gc) {
        if ($$src =~ /\G([0-9A-Fa-f]+)/gc) {
          unless ($opt{ExpandedURI q<allow-hex-character-reference>}) {
            $self->report
              (-type => 'SYNTAX_HEX_CHAR_REF',
               -class => 'WFC',
               source => $src,
               position_diff => 3 + length $1);
          }
          $self->hex_character_reference_in_attribute_value_literal_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => hex $1},
                %opt);
        } else {
          $self->report
            (-type => 'SYNTAX_HEXDIGIT_REQUIRED',
             -class => 'WFC',
             source => $src);
          pos ($$src) -= 3;
          return 0;
        }
      } elsif ($$src =~ /\G([0-9]+)/gc) {
        unless ($opt{ExpandedURI q<allow-numeric-character-reference>}) {
          $self->report
            (-type => 'SYNTAX_NUMERIC_CHAR_REF',
             -class => 'WFC',
             source => $src,
             position_diff => 2 + length $1);
        }
        $self->numeric_character_reference_in_attribute_value_literal_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => 0 + $1},
                %opt);
      } elsif ($$src =~ /\GX/gc) {
        $self->report
               (-type => 'SYNTAX_HCRO_CASE',
                -class => 'WFC',
                source => $src,
                position_diff => 1);
        pos ($$src) -= 3;
        return 0;
      } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
        my $name = $1;
        $self->report
               (-type => 'SYNTAX_NAMED_CHARACTER_REFERENCE',
                -class => 'WFC',
                source => $src,
                function_name => $name,
                position_diff => length $name);
        pos ($$src) -= 2 + length $name;
        return 0;
      } else {
        $self->report
               (-type => 'SYNTAX_X_OR_DIGIT_REQUIRED',
                -class => 'WFC',
                source => $src);
        pos ($$src) -= 2;
        return 0;
      }
    } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
      unless ($opt{ExpandedURI q<allow-general-entity-reference>}) {
        $self->report
               (-type => 'SYNTAX_GENERAL_ENTREF',
                -class => 'WFC',
                source => $src,
                position_diff => 1 + length $1);
      }
      $self->general_entity_reference_in_attribute_value_literal_start
               ($src,
                $p,
                {ExpandedURI q<entity-name> => $1},
                %opt);
    } else {
      $self->report
               (-type => 'SYNTAX_HASH_OR_NAME_REQUIRED',
                -class => 'WFC',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
    
    $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'WFC',
                source => $src);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_REFERENCE_AMP_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }
}

sub parse_reference_in_content ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G&/gc) {
    if ($$src =~ /\G\#/gc) {
      if ($$src =~ /\Gx/gc) {
        if ($$src =~ /\G([0-9A-Fa-f]+)/gc) {
          $self->hex_character_reference_in_content_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => hex $1},
                %opt);
        } else {
          $self->report
            (-type => 'SYNTAX_HEXDIGIT_REQUIRED',
             -class => 'WFC',
             source => $src);
          pos ($$src) -= 3;
          return 0;
        }
      } elsif ($$src =~ /\G([0-9]+)/gc) {
        $self->numeric_character_reference_in_content_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => 0 + $1},
                %opt);
      } elsif ($$src =~ /\GX/gc) {
        $self->report
               (-type => 'SYNTAX_HCRO_CASE',
                -class => 'WFC',
                source => $src,
                position_diff => 1);
        pos ($$src) -= 3;
        return 0;
      } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
        my $name = $1;
        $self->report
               (-type => 'SYNTAX_NAMED_CHARACTER_REFERENCE',
                -class => 'WFC',
                source => $src,
                function_name => $name,
                position_diff => length $name);
        pos ($$src) -= 2 + length $name;
        return 0;
      } else {
        $self->report
               (-type => 'SYNTAX_X_OR_DIGIT_REQUIRED',
                -class => 'WFC',
                source => $src);
        pos ($$src) -= 2;
        return 0;
      }
    } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
     $self->general_entity_reference_in_content_start
               ($src,
                $p,
                {ExpandedURI q<entity-name> => $1},
                %opt);
    } else {
      $self->report
               (-type => 'SYNTAX_HASH_OR_NAME_REQUIRED',
                -class => 'WFC',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
    
    $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'WFC',
                source => $src);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_REFERENCE_AMP_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }
}

sub parse_reference_in_rpdata ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G%/gc) {
    if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
      $self->parameter_entity_reference_in_rpdata_start
               ($src,
                $p,
                {ExpandedURI q<entity-name> => $1},
                %opt);
      
      $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'WFC',
                source => $src);
      return 1;
    } else {
      $self->report
               (-type => 'SYNTAX_PARAENT_NAME_REQUIRED',
                -class => 'WFC',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
  } elsif ($$src =~ /\G&/gc) {
    if ($$src =~ /\G\#/gc) {
      if ($$src =~ /\Gx/gc) {
        if ($$src =~ /\G([0-9A-Fa-f]+)/gc) {
          $self->hex_character_reference_in_rpdata_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => hex $1},
                %opt);
        } else {
          $self->report
            (-type => 'SYNTAX_HEXDIGIT_REQUIRED',
             -class => 'WFC',
             source => $src);
          pos ($$src) -= 3;
          return 0;
        }
      } elsif ($$src =~ /\G([0-9]+)/gc) {
        $self->numeric_character_reference_in_rpdata_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => 0 + $1},
                %opt);
      } elsif ($$src =~ /\GX/gc) {
        $self->report
               (-type => 'SYNTAX_HCRO_CASE',
                -class => 'WFC',
                source => $src,
                position_diff => 1);
        pos ($$src) -= 3;
        return 0;
      } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
        my $name = $1;
        $self->report
               (-type => 'SYNTAX_NAMED_CHARACTER_REFERENCE',
                -class => 'WFC',
                source => $src,
                function_name => $name,
                position_diff => length $name);
        pos ($$src) -= 2 + length $name;
        return 0;
      } else {
        $self->report
               (-type => 'SYNTAX_X_OR_DIGIT_REQUIRED',
                -class => 'WFC',
                source => $src);
        pos ($$src) -= 2;
        return 0;
      }
    } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
     $self->general_entity_reference_in_rpdata_start
               ($src,
                $p,
                {ExpandedURI q<entity-name> => $1},
                %opt);
    } else {
      $self->report
               (-type => 'SYNTAX_HASH_OR_NAME_REQUIRED',
                -class => 'WFC',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
    
    $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'WFC',
                source => $src);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_REFERENCE_AMP_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }
}


sub parse_markup_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G(?=<!--)/gc) {
    $self->parse_comment_declaration ($src, $p, %opt);
  } elsif ($$src =~ /\G<!(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
    my $keyword = $1;
    my $method = {qw{
      DOCTYPE        parse_doctype_declaration
    }}->{$keyword} || '';
    if ($self->can ($method)) {
      pos ($$src) -= 2 + length $keyword;
      $self->$method
             ($src, $p, %opt);
    } else {
      $self->report
             (-type => 'SYNTAX_UNKNOWN_MARKUP_DECLARATION',
              -class => 'WFC',
              source => $src,
              position_diff => length $keyword,
              keyword => $keyword);
      pos ($$src) -= 2 + length $keyword;
      return 0;
    }
  } elsif ($$src =~ /\G<!\[/gc) {
    
  } elsif ($$src =~ /\G<!>/gc) {
    $self->report
             (-type => 'SYNTAX_EMPTY_COMMENT_DECLARATION',
              -class => 'WFC',
              source => $src,
              position_diff => 3);
    $self->comment_declaration_start
             ($src, $p, my $pp = {}, %opt);
    $self->comment_declaration_end
             ($src, $p, $pp, %opt);
  } elsif ($opt{ExpandedURI q<match-or-error>}) {
    if (substr ($$src, pos $$src, 2) eq '<!') {
      $self->report
             (-type => 'SYNTAX_NAME_OR_DSO_OR_COM_REQUIRED',
              -class => 'WFC',
              source => $src);
    } else {
      $self->report
             (-type => 'SYNTAX_MARKUP_DECLARATION_REQUIRED',
              -class => 'WFC',
              source => $src);
    }
    return 0;
  }
  return 1;
}

sub parse_doctype_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!DOCTYPE/gc) {
    $self->doctype_declaration_start
              ($src, $p, my $pp = {}, %opt);
    PARAMS: {
      local $opt{ExpandedURI q<match-or-error>} = 1;
      local $opt{ExpandedURI q<allow-comment>} = 0;
      local $opt{ExpandedURI q<allow-param-entref>} = 0;
      local $opt{ExpandedURI q<ps-required>} = 1;
      local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_DOCTYPE_PS_REQUIRED';
      $self->markup_declaration_parameters_start
              ($src, $p, $pp, %opt);
      $pp->{ExpandedURI q<param>} = [];
      
      ## Document Type Name
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match> => 'SYNTAX_DOCTYPE_NAME_REQUIRED',
               ExpandedURI q<end-with-mdc> => 0,
               ExpandedURI q<param-type> => {
                 Name => 1,
                 rniKeyword => 1,
                 ps => 1,
               });
      my $doctype = shift @{$pp->{ExpandedURI q<param>}};
      unless ($doctype) {
        last PARAMS;
      } elsif ($doctype->{type} eq 'rniKeyword') {
        if (${$doctype->{value}} eq 'IMPLIED') {
          $self->report
              (-type => 'SYNTAX_DOCTYPE_IMPLIED',
               -class => 'WFC',
               source => $doctype->{value});
        } else {
          $self->report
              (-type => 'SYNTAX_DOCTYPE_RNI_KEYWORD',
               -class => 'WFC',
               source => $doctype->{value},
               keyword => ${$doctype->{value}});
        }
      } else {
        $pp->{ExpandedURI q<doctype>} = $doctype->{value};
      }
      
      ## External Identifiers
      local $opt{ExpandedURI q<match-or-error>} = 0;
      $self->parse_external_identifiers
              ($src, $pp, %opt,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<allow-public-id> => 1,
               ExpandedURI q<allow-system-id> => 1,
               ExpandedURI q<system-id-required> => 1,
               ExpandedURI q<end-with-mdc> => 1);
      
      ## Internal Subset
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<end-with-mdc> => 0,
               ExpandedURI q<param-type> => {
                 dso => 1,
                 ps => 1,
               });
      my $dso = shift @{$pp->{ExpandedURI q<param>}};
      last PARAMS unless $dso;
      if ($dso->{type} eq 'dso') {
        $self->parse_doctype_subset
              ($src, $pp,
               %opt,
               ExpandedURI q<end-with-dsc> => 1);
      }
      
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}}) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => $pp->{ExpandedURI q<param>}->[0]->{value},
               param => $pp->{ExpandedURI q<param>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }; # PARAMS
    
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'WFC',
               source => $src);
    }
    $self->doctype_declaration_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
              (-type => 'SYNTAX_DOCTYPE_DECLARATION_REQUIRED',
               -class => 'WFC',
               source => $src);
    }
    return 0;
  }
}

sub parse_entity_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!ENTITY/gc) {
    $self->entity_declaration_start
              ($src, $p, my $pp = {}, %opt);
    PARAMS: {
      local $opt{ExpandedURI q<match-or-error>} = 1;
      local $opt{ExpandedURI q<allow-comment>} = 0;
      local $opt{ExpandedURI q<allow-param-entref>} = 1;
      local $opt{ExpandedURI q<ps-required>} = 1;
      local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_ENTITY_PS_REQUIRED';
      $self->markup_declaration_parameters_start
              ($src, $p, $pp, %opt);
      $pp->{ExpandedURI q<param>} = [];
      
      ## Entity Name
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match> => 'SYNTAX_ENTITY_NAME_REQUIRED',
               ExpandedURI q<end-with-mdc> => 0,
               ExpandedURI q<param-type> => {
                 Name => 1,
                 rniKeyword => 1,
                 peroName => 1,
                 ps => 1,
               });
      my $entname = shift @{$pp->{ExpandedURI q<param>}};
      unless ($entname) {
        last PARAMS;
      } elsif ($entname->{type} eq 'peroName') {
        $pp->{ExpandedURI q<entity-type>} = 'parameter';
        $pp->{ExpandedURI q<entity-name>} = $entname->{value};
      } elsif ($entname->{type} eq 'Name') {
        $pp->{ExpandedURI q<entity-type>} = 'general';
        $pp->{ExpandedURI q<entity-name>} = $entname->{value};
      } elsif ($entname->{type} eq 'rniKeyword') {
        if (${$entname->{value}} eq 'DEFAULT') {
          $self->report
              (-type => 'SYNTAX_ENTITY_DEFAULT',
               -class => 'WFC',
               source => $entname->{value});
        } else {
          $self->report
              (-type => 'SYNTAX_ENTITY_RNI_KEYWORD',
               -class => 'WFC',
               source => $entname->{value},
               keyword => ${$entname->{value}});
        }
      } else {
        die "$0: ".__PACKAGE__.": $entname->{type}: Buggy";
      }
      
      ## Entity Text
      ENTTEXT: {
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match> => 'SYNTAX_ENTITY_TEXT_REQUIRED',
               ExpandedURI q<ps-required> => 1,
               ExpandedURI q<param-type> => {
                 Name => 1,
                 paralit => 1,
                 ps => 1,
               });
        my $enttext = $pp->{ExpandedURI q<param>}->[0];
        if ($enttext) {
          if ($enttext->{type} eq 'paralit') {
            $self->literal_entity_value_content
              ($src, $pp, 
               {ExpandedURI q<literal-entity-value> => $enttext->{value}},
               %opt);
            shift @{$pp->{ExpandedURI q<param>}};
          } elsif ($enttext->{type} eq 'Name') {
            if (${$enttext->{value}} eq 'PUBLIC' or
                ${$enttext->{value}} eq 'SYSTEM') {
              ## External Identifiers
              $self->parse_external_identifiers
                ($src, $pp, %opt,
                 ExpandedURI q<ps-required> => 0,
                 ExpandedURI q<allow-public-id> => 1,
                 ExpandedURI q<allow-system-id> => 1,
                 ExpandedURI q<system-id-required> => 1,
                 ExpandedURI q<end-with-mdc> => 1);
            } elsif ({qw/CDATA 1 SDATA 1 STARTTAG 1
                         ENDTAG 1 MD 1 MS 1 PI 1/}->{${$enttext->{value}}}) {
              $self->report
                (-type => 'SYNTAX_ENTITY_TEXT_PRE_KEYWORD',
                 -class => 'WFC',
                 source => $enttext->{value},
                 keyword => ${$enttext->{value}});
              shift @{$pp->{ExpandedURI q<param>}};
              
              $self->parse_markup_declaration_parameter
                ($src, $pp,
                 %opt,
                 ExpandedURI q<error-no-match> => 'SYNTAX_PARALIT_REQUIRED',
                 ExpandedURI q<ps-required> => 1,
                 ExpandedURI q<param-type> => {
                   paralit => 1,
                   ps => 1,
                 });
              my $enttext2 = shift @{$pp->{ExpandedURI q<param>}};
              $self->literal_entity_value_content
                ($src, $pp, 
                 {ExpandedURI q<literal-entity-value> => $enttext2->{value},
                  ExpandedURI q<entity-value-keyword> => ${$enttext->{value}}},
                 %opt)
                if $enttext2;
            } else {
              $self->report
                (-type => 'SYNTAX_ENTITY_TEXT_KEYWORD',
                 -class => 'WFC',
                 source => $enttext->{value},
                 keyword => ${$enttext->{value}});
              shift @{$pp->{ExpandedURI q<param>}};
              redo ENTTEXT;
            }
          } else {
            die "$0: ".__PACKAGE__.": $enttext->{type}: buggy";
          }
        } else { ## Don't match to paralit nor keyword
          last PARAMS;
        }
      } # ENTTEXT
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}}) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => $pp->{ExpandedURI q<param>}->[0]->{value},
               param => $pp->{ExpandedURI q<param>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'WFC',
               source => $src);
    }
    $self->entity_declaration_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    return 0;
  }
}

sub parse_markup_declaration_parameter ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $allow = $opt{ExpandedURI q<param-type>};
  
  my $param = $p->{ExpandedURI q<param>};
  if (@$param) {
    if ($allow->{$param->[0]->{type}}) {
      return 1;
    } elsif ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => $opt{ExpandedURI q<error-no-match>}
                         || 'SYNTAX_PARAMETER_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }

  if ($allow->{ps}) {
    if ($$src =~ /\G$REG_S+/gco) {
      if ($opt{ExpandedURI q<end-with-mdc>} and
          $$src =~ /\G>/gc) {
        pos ($$src)--;
        return 1;
      }
      
# pararef
    } else {
      if ($opt{ExpandedURI q<end-with-mdc>} and
          $$src =~ /\G>/gc) {
        pos ($$src)--;
        return 1;
      } elsif ($opt{ExpandedURI q<ps-required>}) {
        $self->report
              (-type => $opt{ExpandedURI q<error-ps-required>}
                        || 'SYNTAX_MARKUP_DECLARATION_PS_REQUIRED',
               -class => 'WFC',
               source => $src);
      }
    }
  }
  if ($allow->{Name} and
      $$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
    my $name = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $name);
    $self->{error}->fork_position ($src => \$name);
    push @$param, {type => 'Name', value => \$name};
    return 1;
  } elsif ($allow->{rniKeyword} and
           $$src =~ /\G\#(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
    my $name = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $name);
    $self->{error}->fork_position ($src => \$name);
    push @$param, {type => 'rniKeyword', value => \$name};
    return 1;
  } elsif ($allow->{paralit} and
           $$src =~ /\G(["'])/gc) {
    my $pp = {};
    my $lit = $pp->{ExpandedURI q<literal-delimiter>} = $1;
    $self->parameter_literal_start
      ($src, $p, $pp, %opt);
    $self->parse_rpdata ($src, $pp, %opt);
    if ($lit eq '"') {
      $$src =~ /\G"/gc or
        $self->report
               (-type => 'SYNTAX_PLITC_REQUIRED',
                -class => 'WFC',
                source => $src);
    } else {
      $$src =~ /\G'/gc or
        $self->report
               (-type => 'SYNTAX_PLITAC_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    $self->parameter_literal_end
      ($src, $p, $pp, %opt);
    push @$param, {type => 'paralit', value => $pp};
  } elsif ($allow->{publit} and
           $$src =~ /\G(["'])/gc) {
    my $lit = $1;
    $self->{error}->set_position ($src, moved => 1);
    my $pos = [$self->{error}->get_position ($src)];
    my $pubid;
    if ($lit eq '"') {
      ($pubid) = ($$src =~ /\G([^"]+)/gc);
      $$src =~ /\G"/gc or
        $self->report
               (-type => 'SYNTAX_PUBLIT_MLITC_REQUIRED',
                -class => 'WFC',
                source => $src);
    } else {
      ($pubid) = ($$src =~ /\G([^']+)/gc);
      $$src =~ /\G'/gc or
        $self->report
               (-type => 'SYNTAX_PUBLIT_MLITAC_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    $self->{error}->reset_position
               (\$pubid,
                line => $pos->[0],
                char => $pos->[1]);
    if ($pubid =~ m{([^-'()+,./:=?;!*\#\@\$_%A-Za-z0-9\x0A\x0D\x20])}g) {
      my $s = $1;
      $self->report
               (-type => 'SYNTAX_PUBID_LITERAL_INVALID_CHAR',
                -class => 'WFC',
                source => \$pubid,
                position_diff => 1,
                char => $s);
      pos ($pubid) = 0;
      $self->{error}->reset_position
               (\$pubid,
                line => $pos->[0],
                char => $pos->[1]);
    }
    push @$param, {type => 'publit', value => \$pubid};
  } elsif ($allow->{syslit} and
           $$src =~ /\G(["'])/gc) {
    my $lit = $1;
    my $pos = [$self->{error}->get_position ($src)];
    my $sysid;
    if ($lit eq '"') {
      $sysid = ($$src =~ /\G([^"]+)/gc);
      $$src =~ /\G"/gc or
        $self->report
               (-type => 'SYNTAX_SLITC_REQUIRED',
                -class => 'WFC',
                source => $src);
    } else {
      $sysid = ($$src =~ /\G([^']+)/gc);
      $$src =~ /\G'/gc or
        $self->report
               (-type => 'SYNTAX_SLITAC_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    pos ($sysid) = 0;
    $self->{error}->set_position
               (\$sysid,
                line => $pos->[0],
                char => $pos->[1]);
    push @$param, {type => 'syslit', value => \$sysid};
  } elsif ($allow->{peroName} and
           $$src =~ /\G%$REG_S+/gco) {
    if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
      my $name = $1;
      $self->{error}->set_position ($src, moved => 1,
                                    diff => length $name);
      $self->{error}->fork_position ($src => \$name);
      push @$param, {type => 'peroName', value => \$name};
      return 1;
    } else {
      $self->report
         (-type => 'SYNTAX_ENTITY_PARAM_NAME_REQUIRED',
          -class => 'WFC',
          source => $src);
      return 1;
    }
  } elsif ($opt{ExpandedURI q<end-with-mdc>} and
           $$src =~ /\G>/gc) {
    pos ($$src)--;
    return 1;
  } elsif ($allow->{dso} and $$src =~ /\G\[/gc) {
    push @$param, {type => 'dso'};
  } elsif ($allow->{dsc} and $$src =~ /\G\]/gc) {
    push @$param, {type => 'dsc'};
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => $opt{ExpandedURI q<error-no-match>}
                         || 'SYNTAX_PARAMETER_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }
}

sub parse_rpdata ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = {};
  my $litdelim = $p->{ExpandedURI q<literal-delimiter>};
  my $datachar = $litdelim ?
                   $litdelim eq '"' ? qr/[^"&%]/ :
                   $litdelim eq "'" ? qr/[^'&%]/ :
                   die "$0: ".__PACKAGE__.": $litdelim: buggy" :
                                      qr/[^&%]/;
  $self->{error}->set_position ($src, moved => 1);
  $pp->{ExpandedURI q<position>} = [$self->{error}->get_position ($src)];
  $self->rpdata_start ($src, $p, $pp, %opt);
  while (pos $$src < length $$src) {
    if ($$src =~ /\G($datachar+)/gc) {
      my $s = $1;
      pos $s = 0;
      $self->{error}->set_position ($src, moved => 1);
      $self->{error}->fork_position ($src => \$s);
      local $pp->{ExpandedURI q<CDATA>} = \$s;
      $self->rpdata_content
                   ($src, $p, $pp, %opt);
    } elsif ($$src =~ /\G(?=[&%])/gc) {
      unless ($self->parse_reference_in_rpdata
                   ($src, $pp,
                    %opt,
                    ExpandedURI q<match-or-error> => 1)) {
        my ($s) = ($$src =~ /\G(.)/gc);
        pos $s = 0;
        $self->{error}->set_position ($src, moved => 1);
        $self->{error}->fork_position ($src => \$s);
        local $pp->{ExpandedURI q<CDATA>} = \$s;
        pos ($$src)++;
        $self->rpdata_content
                   ($src, $p, $pp, %opt);
      }
    } else {
      last;
    }
  }
  $self->rpdata_end ($src, $p, $pp, %opt);
  return 1;
}

sub parse_external_identifiers ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->parse_markup_declaration_parameter
           ($src,
            $p,
            %opt,
            ExpandedURI q<param-type> => {
              ps => 1,
              Name => 1,
            });
  my $keyword = shift @{$p->{ExpandedURI q<param>}};
  return 1 unless $keyword;
  if (${$keyword->{value}} eq 'PUBLIC') {
    unless ($opt{ExpandedURI q<allow-public-id>}) {
      $self->report
            (-type => 'SYNTAX_PUBLIC_ID',
             -class => 'WFC',
             source => $keyword->{value});
    }
    $self->parse_markup_declaration_parameter
            ($src, $p,
             %opt,
             ExpandedURI q<ps-required> => 1,
             ExpandedURI q<match-or-error> => 1,
             ExpandedURI q<error-no-match> => 'SYNTAX_PUBID_LITERAL_REQUIRED',
             ExpandedURI q<end-with-mdc> => 0,
             ExpandedURI q<param-type> => {
               ps => 1,
               publit => 1,
             });
    my $pubid = shift @{$p->{ExpandedURI q<param>}};
    return 1 unless $pubid;
    my $pp = {ExpandedURI q<public-id> => $pubid->{value}};
    $self->public_identifier_start 
            ($src, $p, $pp, %opt);
    
    local $opt{ExpandedURI q<match-or-error>} = 0;
    local $opt{ExpandedURI q<error-no-match>} = 'SYNTAX_SYSTEM_LITERAL_REQUIRED';
    if ($opt{ExpandedURI q<allow-system-id>}) {
      if ($opt{ExpandedURI q<system-id-required>}) {
        $opt{ExpandedURI q<match-or-error>} = 1;
      }
    }
    $self->parse_markup_declaration_parameter
            ($src, $p,
             %opt,
             ExpandedURI q<ps-required> => 1,
             ExpandedURI q<end-with-mdc> => 0,
             ExpandedURI q<param-type> => {
               ps => 1,
               syslit => 1,
             });
    my $sysid = shift @{$p->{ExpandedURI q<param>}};
    return 1 unless $sysid;
    unless ($opt{ExpandedURI q<allow-system-id>}) {
      $self->report
            (-type => 'SYNTAX_SYSTEM_LITERAL',
             -class => 'WFC',
             source => $sysid->{value},
             position_diff => 1);
    }
    $pp->{ExpandedURI q<system-id>} = $sysid->{value};
    $self->system_identifier_start 
            ($src, $p, $pp, %opt);
    return 1;
  } elsif (${$keyword->{value}} eq 'SYSTEM') {
    unless ($opt{ExpandedURI q<allow-system-id>}) {
      $self->report
            (-type => 'SYNTAX_SYSTEM_ID',
             -class => 'WFC',
             source => $keyword->{value});
    }
    $self->parse_markup_declaration_parameter
            ($src, $p,
             %opt,
             ExpandedURI q<ps-required> => 1,
             ExpandedURI q<match-or-error> => 1,
             ExpandedURI q<error-no-match> => 'SYNTAX_SYSTEM_LITERAL_REQUIRED',
             ExpandedURI q<end-with-mdc> => 0,
             ExpandedURI q<param-type> => {
               ps => 1,
               syslit => 1,
             });
    my $sysid = shift @{$p->{ExpandedURI q<param>}};
    return 1 unless $sysid;
    my $pp = {ExpandedURI q<system-id> => $sysid->{value}};
    $self->system_identifier_start 
            ($src, $p, $pp, %opt);
    return 1;
  }
  
  $self->report
            (-type => 'SYNTAX_MARKUP_DECLARATION_UNKNOWN_KEYWORD',
             -class => 'WFC',
             source => $keyword->{value},
             keyword => ${$keyword->{value}});
  if ($opt{ExpandedURI q<public-id-required>}) {
    $self->report
            (-type => 'SYNTAX_PUBLIC_ID_REQUIRED'.
             -class => 'WFC',
             source => $src);
  } elsif ($opt{ExpandedURI q<system-id-required>}) {
    $self->report
            (-type => 'SYNTAX_SYSTEM_ID_REQUIRED',
             -class => 'WFC',
             source => $src);
  }
  return 1;
}

sub parse_doctype_subset ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->doctype_subset_start
                  ($src, $p, my $pp = {}, %opt); 
  SUBSET: {
    SUBSETDECL: while (pos $$src < length $$src) {
      if (substr ($$src, pos $$src, 1) eq '<') {
        my $n = substr ($$src, 1 + pos $$src, 1);
        if ($n eq '!') {
          $self->parse_markup_declaration
                  ($src, $pp, %opt)
            or pos ($$src)++;
        } elsif ($n eq '?') {
          $self->parse_processing_instruction
                  ($src, $pp, %opt)
            or pos ($$src)++;
        } else {
          pos ($$src)++;
          $self->report
                  (-type => 'SYNTAX_EXCLAMATION_OR_QUESTION_REQUIRED',
                   -class => 'WFC',
                   source => $src);
        }
      } elsif ($$src =~ /\G$REG_S+/gc) {
        
      } elsif (substr ($$src, pos $$src, 0) eq '%') {
        ## TODO: 
      } elsif ($opt{ExpandedURI q<end-with-dsc>} and
               $$src =~ /\G\]/gc) {
        last SUBSET;
      } else {
        (my $char) = ($$src =~ /\G(.)/gcs);
        $self->report
                  (-type => 'SYNTAX_DOCTYPE_SUBSET_INVALID_CHAR',
                   -class => 'WFC',
                   source => $src);
      }
    }
    if ($opt{ExpandedURI q<end-with-dsc>}) {
      $self->report
                  (-type => 'SYNTAX_ISC_REQUIRED',
                   -class => 'WFC',
                   source => $src);
    }
  };
  $self->doctype_subset_end
                  ($src, $p, $pp, %opt);
}

sub parse_comment_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = {};
  if ($$src =~ /\G<!(?=--)/gc) {
    $self->comment_declaration_start ($src, $p, $pp, %opt);
    $self->parse_comment ($src, $pp, %opt);
  } elsif ($opt{ExpandedURI q<match-or-error>}) {
    $self->report (-type => 'SYNTAX_COMMENT_DECLARATION_REQUIRED',
                   -class => 'WFC',
                   source => $src);
    return 0;
  }
  while (pos $$src < length $$src) {
    if ($$src =~ /\G(?=--)/gc) {
      $self->report (-type => 'SYNTAX_MULTIPLE_COMMENT',
                     -class => 'WFC',
                     source => $src);
      $self->parse_comment ($src, $pp, %opt);
    } elsif ($$src =~ /\G$REG_S+/gco) {
      $self->report (-type => 'SYNTAX_S_IN_COMMENT_DECLARATION',
                     -class => 'WFC',
                     source => $src,
                     position_diff => $+[0] - $-[0]);
    } else {
      last;
    }
  }
  unless ($$src =~ /\G>/gc) {
    $self->report (-type => 'SYNTAX_MDC_FOR_COMMENT_REQUIRED',
                   -class => 'WFC',
                   source => $src);
  }
  $self->comment_declaration_end ($src, $p, $pp, %opt);
  return 1;
}

sub parse_comment ($$$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = {};
  unless ($$src =~ /\G--/gc) {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report (-type => 'SYNTAX_COMO_REQUIRED',
                     -class => 'WFC',
                     source => $src);
    }
    return 0;
  }
  $self->comment_start ($src, $p, $pp, %opt);
  if ($$src =~ /\G((?:(?!--).)+)/gcs) {
    $pp->{ExpandedURI q<CDATA>} = $1;
    $self->comment_content
             ($src,
              $p, $pp,
              %opt);
  }
  unless ($$src =~ /\G--/gc) {
    $self->report
             (-type => 'SYNTAX_COMC_REQUIRED',
              -class => 'WFC',
              source => $src);
  }
  $self->comment_end ($src, $p, $pp, %opt);
  return 1;
}


sub parse_processing_instruction ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<\?/gc) {
    my $pp = {};
    if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
      $pp->{ExpandedURI q<target-name>} = $1;
    } else {
      $self->report
               (-type => 'SYNTAX_TARGET_NAME_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    $self->processing_instruction_start
               ($src, $p, $pp, %opt);
    
    if ($$src =~ /\G$REG_S/gco) {
      $self->{error}->set_position ($src, moved => 1);
      my $data = '';
      if ($$src =~ /\G((?:(?!\?>).)+)/gcs) {
        $data = $1;
      }
      $pp->{ExpandedURI q<target-data>} = \$data;
      pos $data = 0;
      $self->{error}->fork_position ($src => \$data);
      ## Note: _content called if there is S after target name
      $self->processing_instruction_content
               ($src, $p, $pp, %opt);
    }
    
    unless ($$src =~ /\G\?>/gc) {
      $self->report
               (-type => 'SYNTAX_PIC_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    
    $self->processing_instruction_end
               ($src, $p, $pp, %opt);
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_PROCESSING_INSTRUCTION_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }
}


sub report ($@) {
  shift->{error}->report (@_);
}

sub element_start ($$$$%) {}
sub element_content ($$$$%) {}
sub element_end ($$$$%) {}

sub start_tag_start ($$$$%) {}
sub start_tag_end ($$$$%) {}

sub end_tag_start ($$$$%) {}
sub end_tag_end ($$$$%) {}

sub attribute_specifications_start ($$$$%) {}
sub attribute_specifications_end ($$$$%) {}

sub attribute_specification_start ($$$$%) {}
sub attribute_specification_end ($$$$%) {}

sub attribute_value_specification_start ($$$$%) {}
sub attribute_value_specification_content ($$$$%) {}
sub attribute_value_specification_end ($$$$%) {}

sub doctype_declaration_start ($$$$%) {}
sub doctype_declaration_end ($$$$%) {}

sub entity_declaration_start ($$$$%) {}
sub entity_declaration_end ($$$$%) {}
sub literal_entity_value_content ($$$$%) {}

sub element_declaration_start ($$$$%) {}
sub element_declaration_end ($$$$%) {}

sub attlist_declaration_start ($$$$%) {}
sub attlist_declaration_end ($$$$%) {}

sub notation_declaration_start ($$$$%) {}
sub notation_declaration_end ($$$$%) {}

sub markup_declaration_parameters_start ($$$$%) {}
sub markup_declaration_parameters_end ($$$$%) {}

sub public_identifier_start ($$$$%) {}
sub system_identifier_start ($$$$%) {}

sub rpdata_start ($$$$%) {}
sub rpdata_content ($$$$%) {}
sub rpdata_end ($$$$%) {}

sub parameter_literal_start ($$$$%) {}
sub parameter_literal_content ($$$$%) {}
sub parameter_literal_end ($$$$%) {}

sub doctype_subset_start ($$$$%) {}
sub doctype_subset_end ($$$$%) {}

sub comment_declaration_start ($$$$%) {}
sub comment_declaration_end ($$$$%) {}

sub comment_start ($$$$%) {}
sub comment_content ($$$$%) {}
sub comment_end ($$$$%) {}

sub processing_instruction_start ($$$$%) {}
sub processing_instruction_content ($$$$%) {}
sub processing_instruction_end ($$$$%) {}

sub numeric_character_reference_in_attribute_value_literal_start
    ($$$$%) {}
sub numeric_character_reference_in_content_start ($$$$%) {}
sub numeric_character_reference_in_rpdata_start ($$$$%) {}

sub hex_character_reference_in_attribute_value_literal_start
    ($$$$%) {}
sub hex_character_reference_in_content_start ($$$$%) {}
sub hex_character_reference_in_rpdata_start ($$$$%) {}

sub general_entity_reference_in_attribute_value_literal_start
    ($$$$%) {}
sub general_entity_reference_in_content_start ($$$$%) {}
sub general_entity_reference_in_rpdata_start
  ($$$$%) {}

sub parameter_entity_reference_in_rpdata_start ($$$$%) {}
sub parameter_entity_reference_in_parameter_start ($$$$%) {}
sub parameter_entity_reference_in_subset_start ($$$$%) {}

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/05/08 07:37:04 $
