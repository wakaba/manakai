
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
our $VERSION = do{my @r=(q$Revision: 1.1.2.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar InXMLChar
                        InXML_deprecated_noncharacter InXML_unicode_xml_not_suitable!;
require Message::Markup::XML::Parser::Error;
require overload;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/>
}
use Message::Markup::XML::QName qw/DEFAULT_PFX/;
use Message::Util::QName::General [qw/ExpandedURI/],
    {
     (DEFAULT_PFX) => URI_CONFIG,
     _ => q<http://suika.fam.cx/~wakaba/-temp/2004/5/30/parser-internal#>,
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

sub parse_document_entity ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->document_start ($src, $p, my $pp = {}, %opt);
  if ($$src =~ /\G(?=<\?xml\P{InXMLNameChar})/gc) {
    $self->parse_xml_declaration
      ($src, $pp, %opt,
       ExpandedURI q<allow-xml-declaration> => 1,
       ExpandedURI q<allow-text-declaration> => 0);
  }
  
  pos $$src ||= 0;
  my $docelem = 0;
  while (pos $$src < length $$src) {
    if ($$src =~ /\G</gc) {
      if ($$src =~ /\G\p{InXML_NameStartChar}/gc) {
        pos ($$src) -= 2;
        if ($docelem++) {
          $self->report
            (-type => 'SYNTAX_MULTIPLE_DOCUMENT_ELEMENTS',
             -class => 'WFC',
             source => $src);
        }
        $self->parse_element
          ($src, $pp, %opt,
           ExpandedURI q<match-or-error> => 1);
      } elsif (substr ($$src, pos $$src, 1) eq '!') {
        pos ($$src)--;
        $self->parse_markup_declaration
          ($src, $pp, %opt,
           ExpandedURI q<match-or-error> => 1,
           ExpandedURI q<allow-declaration> => {
             DOCTYPE => $docelem ? 0 : 1, comment => 1,
           }) or do {
             my $s = '<!';
             pos $s = 0;
             $self->{error}->set_position ($src, moved => 1, diff => 1);
             $self->{error}->fork_position ($src => \$s);
             local $pp->{ExpandedURI q<CDATA>} = \$s;
             pos ($$src) += 2;
             $self->document_content
                   ($src, $p, $pp, %opt);
           };
      } elsif (substr ($$src, pos $$src, 1) eq '?') {
        pos ($$src)--;
        $self->parse_processing_instruction
                   ($src, $pp, %opt);
      } else {
        my $s = '<';
        pos $s = 0;
        $self->{error}->set_position ($src, moved => 1, diff => 1);
        $self->{error}->fork_position ($src => \$s);
        $self->report
          (-type => 'SYNTAX_CDATA_OUTSIDE_DOCUMENT_ELEMENT',
           -class => 'WFC',
           source => $src,
           position_diff => 1);
        local $pp->{ExpandedURI q<CDATA>} = \$s;
        $self->document_content ($src, $p, $pp, %opt);
      }
    } elsif ($$src =~ /\G($REG_S+)/gco) {
      my $s = $1;
      pos $s = 0;
      $self->{error}->set_position ($src, moved => 1, diff => length $s);
      $self->{error}->fork_position ($src => \$s);
      local $pp->{ExpandedURI q<s>} = \$s;
      $self->document_content ($src, $p, $pp, %opt);
    } elsif ($$src =~ /\G([^<]+)/gco) {
      my $s = $1;
      pos $s = 0;
      $self->{error}->set_position ($src, moved => 1, diff => length $s);
      $self->{error}->fork_position ($src => \$s);
      $self->report
        (-type => 'SYNTAX_CDATA_OUTSIDE_DOCUMENT_ELEMENT',
         -class => 'WFC',
         source => $src,
         position_diff => length $s);
      local $pp->{ExpandedURI q<CDATA>} = \$s;
      $self->document_content ($src, $p, $pp, %opt);
    } else {
      die "Buggy: parse_document_entity: ", substr $$src, pos $$src, 10;
    }
  }
  unless ($docelem) {
    $self->report
      (-type => 'SYNTAX_NO_DOCUMENT_ELEMENT',
       -class => 'WFC',
       source => $src);
  }
  $self->document_end ($src, $p, $pp, %opt);
}

sub parse_element ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $opt{ExpandedURI q<use-reference>} = 1;

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
                   ($src, $pp, %opt,
                    ExpandedURI q<allow-declaration> => {
                      comment => 1,
                      section => 1,
                    }, ExpandedURI q<allow-section> => {
                      CDATA => 1,
                      ps => 0,
                    })
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
  my $start_method = $opt{ExpandedURI q<method-start-attr-specs>} ||
                     'attribute_specifications_start';
    $self->$start_method
                 ($src, $p, my $pp = {}, %opt);
  
    my $sep = $opt{ExpandedURI q<s-before-attribute-specifications>};
    my @sep = ($sep);
    while (pos $$src < length $$src) {
      $self->{error}->set_position ($src, moved => 1);
      if ($$src =~ /\G(?=\p{InXML_NameStartChar})/gc) {
        unless ($sep) {
          $self->report
            (-type => 'SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC',
             -class => 'WFC',
             source => $src);
          my $s = '';
          pos $s = 0;
          push @sep, \$s;
        }
        $self->parse_attribute_specification
                  ($src, $pp, %opt);
        $sep = 0;
      } elsif ($$src =~ /\G($REG_S+)/goc) {
        my $s = $1;
        pos $s = 0;
        $self->{error}->fork_position ($src => \$s);
        push @sep, \$s;
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
    
  my $end_method = $opt{ExpandedURI q<method-end-attr-specs>} ||
                   'attribute_specifications_end';
    $self->$end_method
                  ($src, $p, $pp, %opt);
    return 1;
}

sub parse_attribute_specification ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->{error}->set_position ($src, moved => 1);
  if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)$REG_S*/ogc) {
    my $s = $1;
    pos $s = 0;
    $self->{error}->fork_position ($src => \$s);
    my $pp = {ExpandedURI q<attribute-name> => \$s};
    my $start_method = $opt{ExpandedURI q<method-start-attr-spec>} ||
                       'attribute_specification_start';
    $self->$start_method ($src, $p, $pp, %opt);
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
    my $end_method = $opt{ExpandedURI q<method-end-attr-spec>} ||
                     'attribute_specification_end';
    $self->$end_method ($src, $p, $pp, %opt);
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
    my $start_method = $opt{ExpandedURI q<method-start-attr-value-spec>} ||
                       'attribute_value_specification_start';
    $self->$start_method ($src, $p, $pp, %opt);
    my $content_method = $opt{ExpandedURI q<method-content-attr-value-spec>} ||
                         'attribute_value_specification_content';
    if ($litdelim eq '"') {
      while (pos $$src < length $$src) {
        $self->{error}->set_position ($src, moved => 1);
        if ($$src =~ /\G([^"&<]+)/gc) {
          my $s = $1;
          pos $s = 0;
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
        } elsif ($$src =~ /\G(?=&)/gc) {
          if (not $opt{ExpandedURI q<use-reference>} or
              not $self->parse_reference_in_attribute_value_literal
                   ($src, $pp,
                    %opt,
                    ExpandedURI q<match-or-error> => 1)) {
            my $s = '&';
            pos $s = 0;
            $self->{error}->fork_position ($src => \$s);
            local $pp->{ExpandedURI q<CDATA>} = \$s;
            pos ($$src)++;
            $self->$content_method
                   ($src, $p, $pp, %opt);
          }
        } elsif ($$src =~ /\G</gc) {
          my $s = '<';
          pos $s = 0;
          $self->{error}->fork_position ($src => \$s);
          $self->report
                   (-type => 'SYNTAX_NO_LESS_THAN_IN_ATTR_VAL',
                    -class => 'WFC',
                    source => $src,
                    position_diff => 1);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
        } else {
          my $s = '';
          pos $s = 0;
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
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
        $self->{error}->set_position ($src, moved => 1);
        if ($$src =~ /\G([^'&<]+)/gc) {
          my $s = $1;
          pos $s = 0;
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
        } elsif ($$src =~ /\G(?=&)/gc) {
          if (not $opt{ExpandedURI q<use-reference>} or
              not $self->parse_reference_in_attribute_value_literal
                   ($src, $pp,
                    %opt,
                    ExpandedURI q<match-or-error> => 1)) {
            my $s = '&';
            pos $s = 0;
            $self->{error}->fork_position ($src => \$s);
            local $pp->{ExpandedURI q<CDATA>} = \$s;
            pos ($$src)++;
            $self->$content_method
                   ($src, $p, $pp, %opt);
          }
        } elsif ($$src =~ /\G</gc) {
          my $s = '<';
          pos $s = 0;
          $self->{error}->fork_position ($src => \$s);
          $self->report
                   (-type => 'SYNTAX_NO_LESS_THAN_IN_ATTR_VAL',
                    -class => 'WFC',
                    source => $src,
                    position_diff => 1);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
        } else {
          my $s = '';
          pos $s = 0;
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
          last;
        }
      }
      unless ($$src =~ /\G'/gc) {
        $self->report (-type => 'SYNTAX_ALITAC_REQUIRED',
                       -class => 'WFC',
                       source => $src);
      }
    }
    my $end_method = $opt{ExpandedURI q<method-end-attr-value-spec>} ||
                     'attribute_value_specification_end';
    $self->$end_method ($src, $p, $pp, %opt);
    return 1;
  } elsif ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
    my $s = $1;
    my $start_method = $opt{ExpandedURI q<method-start-attr-value-spec>} ||
                       'attribute_value_specification_start';
    $self->$start_method ($src, $p, my $pp = {}, %opt);
    $self->report (-type => 'SYNTAX_ATTRIBUTE_VALUE',
                   -class => 'WFC',
                   source => $src,
                   position_diff => length $s);
    pos $s = 0;
    $self->{error}->set_position ($src, moved => 1);
    $self->{error}->fork_position ($src => \$s);
    local $pp->{ExpandedURI q<CDATA>} = \$s;
    my $content_method = $opt{ExpandedURI q<method-content-attr-value-spec>} ||
                         'attribute_value_specification_content';
    $self->$content_method
                   ($src, $p, $pp, %opt);
    my $end_method = $opt{ExpandedURI q<method-end-attr-value-spec>} ||
                     'attribute_value_specification_end';
    $self->$end_method ($src, $p, $pp, %opt);
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
    unless ($opt{ExpandedURI q<allow-declaration>}->{comment}) {
      $self->report
          (-type => 'SYNTAX_COMMENT_DECLARATION_NOT_ALLOWED',
           -class => 'WFC',
           source => $src);
    }
    $self->parse_comment_declaration ($src, $p, %opt);
  } elsif ($$src =~ /\G<!(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
    my $keyword = $1;
    my $method = {qw{
      ATTLIST        parse_attlist_declaration
      DOCTYPE        parse_doctype_declaration
      ELEMENT        parse_element_declaration
      ENTITY         parse_entity_declaration
      NOTATION       parse_notation_declaration
    }}->{$keyword} || '';
    if ($self->can ($method)) {
      pos ($$src) -= 2 + length $keyword;
      unless ($opt{ExpandedURI q<allow-declaration>}->{$keyword}) {
        $self->report
          (-type => 'SYNTAX_MARKUP_DECLARATION_NOT_ALLOWED',
           -class => 'WFC',
           source => $src,
           keyword => $keyword);
      }
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
  } elsif ($$src =~ /\G(?=<!\[)/gc) {
    unless ($opt{ExpandedURI q<allow-declaration>}->{section}) {
      $self->report
          (-type => 'SYNTAX_MARKED_SECTION_NOT_ALLOWED',
           -class => 'WFC',
           source => $src);
    }
    $self->parse_marked_section
             ($src, $p, %opt);
  } elsif ($$src =~ /\G<!>/gc) {
    unless ($opt{ExpandedURI q<allow-declaration>}->{comment}) {
      $self->report
          (-type => 'SYNTAX_COMMENT_DECLARATION_NOT_ALLOWED',
           -class => 'WFC',
           source => $src);
    }
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
    {
    local $opt{ExpandedURI q<match-or-error>} = 1;
    local $opt{ExpandedURI q<allow-comment>} = 0;
    local $opt{ExpandedURI q<allow-param-entref>} = 0;
    local $opt{ExpandedURI q<ps-required>} = 1;
    local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_DOCTYPE_PS_REQUIRED';
    local $opt{ExpandedURI q<source>} = [$src];
    $opt{ExpandedURI q<allow-ps>} = 1;
    PARAMS: {
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
               ExpandedURI q<end-with-dsc> => 1,
               ExpandedURI q<allow-declaration>
                 => {qw/ENTITY 1 ELEMENT 1 ATTLIST 1 NOTATION 1
                        comment 1 section 0/});
      }
      
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }} # PARAMS
    
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
    {
    local $opt{ExpandedURI q<match-or-error>} = 1;
    local $opt{ExpandedURI q<allow-comment>} = 0;
    local $opt{ExpandedURI q<ps-required>} = 1;
    local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_ENTITY_PS_REQUIRED';
    local $opt{ExpandedURI q<source>} = [$src];
    $opt{ExpandedURI q<allow-ps>} = 1;
    PARAMS: {
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

          ## External Entity Specification
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
              
              ## Data Type
              $self->parse_markup_declaration_parameter
                ($src, $pp,
                 %opt,
                 ExpandedURI q<match-or-error> => 0,
                 ExpandedURI q<ps-required> => 1,
                 ExpandedURI q<end-with-mdc> => 1,
                 ExpandedURI q<param-type> => {
                   Name => 1,
                   ps => 1,
                 });
              if ($pp->{ExpandedURI q<param>}->[0] and
                  $pp->{ExpandedURI q<param>}->[0]->{type} eq 'Name') {
                my $kwd = shift @{$pp->{ExpandedURI q<param>}};
                if (${$kwd->{value}} eq 'NDATA') {
                  $pp->{ExpandedURI q<entity-data-type>} = ${$kwd->{value}};
                } elsif (${$kwd->{value}} eq 'CDATA' or
                         ${$kwd->{value}} eq 'SDATA') {
                  $self->report
                    (-type => 'SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD',
                     -class => 'WFC',
                     source => $kwd->{value},
                     keyword => ${$kwd->{value}});
                  $pp->{ExpandedURI q<entity-data-type>} = ${$kwd->{value}};
                } elsif (${$kwd->{value}} eq 'SUBDOC') {
                  $self->report
                    (-type => 'SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD',
                     -class => 'WFC',
                     source => $kwd->{value},
                     keyword => ${$kwd->{value}});
                  $pp->{ExpandedURI q<entity-data-type>} = ${$kwd->{value}};
                  last ENTTEXT;
                } else {
                  $self->report
                    (-type => 'SYNTAX_ENTITY_DATA_TYPE_UNKNOWN_KEYWORD',
                     -class => 'WFC',
                     source => $kwd->{value},
                     keyword => ${$kwd->{value}});
                  last ENTTEXT;
                }
                ## Notation Name
                $self->parse_markup_declaration_parameter
                  ($src, $pp,
                   %opt,
                   ExpandedURI q<error-no-match>
                     => 'SYNTAX_ENTITY_DATA_TYPE_NOTATION_NAME_REQUIRED',
                   ExpandedURI q<ps-required> => 1,
                   ExpandedURI q<param-type> => {
                     Name => 1,
                     ps => 1,
                   });
                if ($pp->{ExpandedURI q<param>}->[0] and
                    $pp->{ExpandedURI q<param>}->[0]->{type} eq 'Name') {
                  $pp->{ExpandedURI q<entity-data-notation>}
                    = shift (@{$pp->{ExpandedURI q<param>}})->{value};
                }
              }
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
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }}
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
} # parse_entity_declaration

sub parse_notation_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!NOTATION/gc) {
    $self->notation_declaration_start
              ($src, $p, my $pp = {}, %opt);
    {
    local $opt{ExpandedURI q<match-or-error>} = 1;
    local $opt{ExpandedURI q<allow-comment>} = 0;
    local $opt{ExpandedURI q<ps-required>} = 1;
    local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_NOTATION_PS_REQUIRED';
    local $opt{ExpandedURI q<source>} = [$src];
    $opt{ExpandedURI q<allow-ps>} = 1;
    PARAMS: {
      $self->markup_declaration_parameters_start
              ($src, $p, $pp, %opt);
      $pp->{ExpandedURI q<param>} = [];
      
      ## Notation Name
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match> => 'SYNTAX_NOTATION_NAME_REQUIRED',
               ExpandedURI q<end-with-mdc> => 0,
               ExpandedURI q<param-type> => {
                 Name => 1,
                 ps => 1,
               });
      my $entname = shift @{$pp->{ExpandedURI q<param>}};
      unless ($entname) {
        last PARAMS;
      } elsif ($entname->{type} eq 'Name') {
        $pp->{ExpandedURI q<notation-name>} = $entname->{value};
      } else {
        die "$0: ".__PACKAGE__.": $entname->{type}: Buggy";
      }
      
      ## External Identifiers
      $self->parse_external_identifiers
                ($src, $pp, %opt,
                 ExpandedURI q<ps-required> => 1,
                 ExpandedURI q<error-no-match>
                   => 'SYNTAX_NOTATION_EXTERNAL_IDENTIFIER_REQUIRED',
                 ExpandedURI q<allow-public-id> => 1,
                 ExpandedURI q<allow-system-id> => 1,
                 ExpandedURI q<system-id-required> => 0,
                 ExpandedURI q<end-with-mdc> => 0);
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }}
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
} # parse_notation_declaration

sub parse_element_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!ELEMENT/gc) {
    $self->element_declaration_start
              ($src, $p, my $pp = {}, %opt);
    {
    local $opt{ExpandedURI q<match-or-error>} = 1;
    local $opt{ExpandedURI q<allow-comment>} = 0;
    local $opt{ExpandedURI q<ps-required>} = 1;
    local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_ELEMENT_PS_REQUIRED';
    local $opt{ExpandedURI q<source>} = [$src];
    $opt{ExpandedURI q<allow-ps>} = 1;
    PARAMS: {
      $self->markup_declaration_parameters_start
              ($src, $p, $pp, %opt);
      $pp->{ExpandedURI q<param>} = [];
      
      ## Element Type Name
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_ELEMENT_DECLARATION_TYPE_NAME_REQUIRED',
               ExpandedURI q<end-with-mdc> => 0,
               ExpandedURI q<param-type> => {
                 Name => 1,
                 grpo => 1,
                 ps => 1,
               });
      my $entname = shift @{$pp->{ExpandedURI q<param>}};
      unless ($entname) {
        last PARAMS;
      } elsif ($entname->{type} eq 'Name') {
        $pp->{ExpandedURI q<element-type-name>} = $entname->{value};
      } elsif ($entname->{type} eq 'grpo') {
        $self->report
              (-type => 'SYNTAX_ELEMENT_DECLARATION_TYPE_NAME_GROUP',
               -class => 'WFC',
               source => $entname->{value});
      } else {
        die "$0: ".__PACKAGE__.": $entname->{type}: Buggy";
      }
      
      ## Model
      MODEL: {
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_ELEMENT_MODEL_OR_MIN_OR_RANK_REQUIRED',
               ExpandedURI q<ps-required> => 1,
               ExpandedURI q<param-type> => {
                 Name => 1,   ## Declared content keyword or "o"
                 grpo => 1,   ## Model group open
                 minus => 1,  ## Tag minimumization disabled
                 number => 1, ## Rank suffix
                 ps => 1,
               });
        my $param = $pp->{ExpandedURI q<param>}->[-1];
        last MODEL unless $param;
        if ($param->{type} eq 'grpo') {
          $self->parse_model_group
            ($opt{ExpandedURI q<source>}->[-1], $pp, %opt);
          # exception not implemented
        } elsif ($param->{type} eq 'Name') {
          shift @{$pp->{ExpandedURI q<param>}};
          if ({qw/ANY 1 EMPTY 1/}->{${$param->{value}}}) {
            $pp->{ExpandedURI q<element-content-keyword>} = $param->{value};
          } elsif ({qw/CDATA 1 RCDATA 1/}->{${$param->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ELEMENT_SGML_CONTENT_KEYWORD',
               -class => 'WFC',
               source => $param->{value},
               keyword => ${$param->{value}});
            $pp->{ExpandedURI q<element-content-keyword>} = $param->{value};
          } elsif (${$param->{value}} eq 'o') {
            $self->report
              (-type => 'SYNTAX_ELEMENT_TAG_MIN',
               -class => 'WFC',
               source => $param->{value});
            redo MODEL;
          } else {
            $self->report
              (-type => 'SYNTAX_ELEMENT_UNKNOWN_CONTENT_KEYWORD',
               -class => 'WFC',
               source => $param->{value},
               keyword => ${$param->{value}});
          }
        } elsif ($param->{type} eq 'minus') {
          shift @{$pp->{ExpandedURI q<param>}};
          $self->report
            (-type => 'SYNTAX_ELEMENT_TAG_MIN',
             -class => 'WFC',
             source => $param->{value});
          redo MODEL;
        } elsif ($param->{type} eq 'number') {
          shift @{$pp->{ExpandedURI q<param>}};
          $self->report
            (-type => 'SYNTAX_ELEMENT_RANK_SUFFIX',
             -class => 'WFC',
             source => $param->{value});
          redo MODEL;
        } else {
          die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
        }
      } # MODEL
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }}
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'WFC',
               source => $src);
    }
    $self->element_declaration_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    return 0;
  }
} # parse_element_declaration

sub parse_attlist_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!ATTLIST/gc) {
    $self->attlist_declaration_start
              ($src, $p, my $pp = {}, %opt);
    {
    local $opt{ExpandedURI q<match-or-error>} = 1;
    local $opt{ExpandedURI q<allow-comment>} = 0;
    local $opt{ExpandedURI q<ps-required>} = 1;
    local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_ATTLIST_PS_REQUIRED';
    local $opt{ExpandedURI q<source>} = [$src];
    $opt{ExpandedURI q<allow-ps>} = 1;
    PARAMS: {
      $self->markup_declaration_parameters_start
              ($src, $p, $pp, %opt);
      $pp->{ExpandedURI q<param>} = [];
      
      ## Element Type Name
      NAME: {
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_ATTLIST_ASSOCIATED_NAME_REQUIRED',
               ExpandedURI q<end-with-mdc> => 0,
               ExpandedURI q<param-type> => {
                 Name => 1,
                 rniKeyword => 1,
                 ps => 1,
               });
        my $entname = shift @{$pp->{ExpandedURI q<param>}};
        unless ($entname) {
          last PARAMS;
        } elsif ($entname->{type} eq 'Name') {
          $pp->{ExpandedURI q<element-type-name>} = $entname->{value};
        } elsif ($entname->{type} eq 'rniKeyword') {
          if ({qw/ALL 1 IMPLICIT 1 NOTATION 1/}->{${$entname->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ATTLIST_SGML_KEYWORD',
               -class => 'WFC',
               source => $entname->{value},
               keyword => ${$entname->{value}});
            last NAME unless ${$entname->{value}} eq 'NOTATION';
          } else {
            $self->report
              (-type => 'SYNTAX_ATTLIST_UNKNOWN_KEYWORD',
               -class => 'WFC',
               source => $entname->{value},
               keyword => ${$entname->{value}});
          }
          redo NAME;
        } else {
          die "$0: ".__PACKAGE__.": $entname->{type}: Buggy";
        }
      }
      
      ATTRDEF: {
        ## Attribute Name
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 1,
               ExpandedURI q<end-with-mdc> => 1,
               ExpandedURI q<param-type> => {
                 ps => 1,
                 Name => 1,
               });
        my $param = $pp->{ExpandedURI q<param>}->[-1];
        last ATTRDEF unless $param and $param->{type} eq 'Name';
        shift @{$pp->{ExpandedURI q<param>}};
        my $q = {ExpandedURI q<attribute-name> => $param->{value}};
        
        ## Attribute Type
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 1,
               ExpandedURI q<ps-required> => 1,
               ExpandedURI q<error-no-match> => 'SYNTAX_ATTRDEF_TYPE_REQUIRED',
               ExpandedURI q<param-type> => {
                 ps => 1,
                 Name => 1, # Keyword
                 grpo => 1, # Enum type
               });
        $param = $pp->{ExpandedURI q<param>}->[-1];
        redo ATTRDEF unless $param;
        if ($param->{type} eq 'Name') {
          shift @{$pp->{ExpandedURI q<param>}};
          $q->{ExpandedURI q<attribute-type>} = $param->{value};
          if ({qw/CDATA 1 ENTITY 1 ENTITIES 1 ID 1 IDREF 1 IDREFS 1
                  NOTATION 1 NMTOKEN 1 NMTOKENS 1/}->{${$param->{value}}}) {
            if (${$param->{value}} eq 'NOTATION') {
              $self->parse_markup_declaration_parameter
                ($src, $pp,
                 %opt,
                 ExpandedURI q<match-or-error> => 1,
                 ExpandedURI q<ps-required> => 1,
                 ExpandedURI q<error-no-match>
                   => 'SYNTAX_ATTRDEF_NOTATION_GROUP_REQUIRED',
                 ExpandedURI q<param-type> => {
                   ps => 1,
                   grpo => 1, # Enum type
                 });
              $param = $pp->{ExpandedURI q<param>}->[-1];
              redo ATTRDEF unless $param and $param->{type} eq 'grpo';

              $self->parse_attrtype_group
                ($opt{ExpandedURI q<source>}->[-1], $pp, %opt);
            }
          } elsif ({qw/NAME 1 NAMES 1 NUTOKEN 1 NUTOKENS 1
                       NUMBER 1 NUMBERS 1 DATA 1/}->{${$param->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_TYPE_SGML_KEYWORD',
               -class => 'WFC',
               source => $param->{value},
               keyword => ${$param->{value}});
          } else {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_TYPE_UNKNOWN_KEYWORD',
               -class => 'WFC',
               source => $param->{value},
               keyword => ${$param->{value}});
          }
        } elsif ($param->{type} eq 'grpo') {
          $self->parse_attrtype_group
            ($opt{ExpandedURI q<source>}->[-1], $pp, %opt);
        } else {
          die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
        }

        ## Attribute Default
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 1,
               ExpandedURI q<ps-required> => 1,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_ATTRDEF_DEFAULT_REQUIRED',
               ExpandedURI q<param-type> => {
                 ps => 1,
                 Name => 1, # Attribute value
                 rniKeyword => 1, # Type keyword
                 attrValLit => 1, # Attribute value literal
               });
        $param = shift @{$pp->{ExpandedURI q<param>}};
        redo ATTRDEF unless $param;
        if ($param->{type} eq 'rniKeyword') {
          $q->{ExpandedURI q<attribute-default>} = $param->{value};
          if ({qw/IMPLIED 1 REQUIRED 1 FIXED 1/}->{${$param->{value}}}) {
            if (${$param->{value}} eq 'FIXED') {
              $self->parse_markup_declaration_parameter
                ($src, $pp,
                 %opt,
                 ExpandedURI q<match-or-error> => 1,
                 ExpandedURI q<ps-required> => 1,
                 ExpandedURI q<error-no-match>
                   => 'SYNTAX_ATTRDEF_FIXED_DEFAULT_REQUIRED',
                 ExpandedURI q<param-type> => {
                   ps => 1,
                   Name => 1,
                   attrValLit => 1,
                 });
              $param = shift @{$pp->{ExpandedURI q<param>}};
              redo ATTRDEF unless $param;
              if ($param->{type} eq 'attrValLit') {
                $self->parse_attribute_value_specification
                  ($opt{ExpandedURI q<source>}->[-1], $q, %opt,
                   ExpandedURI q<allow-general-entity-reference> => 1,
                   ExpandedURI q<allow-numeric-character-reference> => 1,
                   ExpandedURI q<allow-hex-character-reference> => 1)
                  or die "$0: ".__PACKAGE__.": attrValLit: Buggy";
              } elsif ($param->{type} eq 'Name') {
                $self->report
                  (-type => 'SYNTAX_ATTRDEF_DEFAULT_NAME',
                   -class => 'WFC',
                   source => $param->{value});
                $q->{ExpandedURI q<attribute-default-value>} = $param->{value};
              } else {
                die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
              }
            }
          } elsif ({qw/CURRENT 1 CONREF 1/}->{${$param->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_DEFAULT_SGML_KEYWORD',
               -class => 'WFC',
               source => $param->{value},
               keyword => ${$param->{value}});
          } else {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_DEFAULT_UNKNOWN_KEYWORD',
               -class => 'WFC',
               source => $param->{value},
               keyword => ${$param->{value}});
          }
        } elsif ($param->{type} eq 'attrValLit') {
          $q->{ExpandedURI q<attribute-default>} = \'specific';
          $self->parse_attribute_value_specification
            ($opt{ExpandedURI q<source>}->[-1], $q, %opt,
             ExpandedURI q<allow-general-entity-reference> => 1,
             ExpandedURI q<allow-numeric-character-reference> => 1,
             ExpandedURI q<allow-hex-character-reference> => 1)
            or die "$0: ".__PACKAGE__.": attrValLit: Buggy";
        } elsif ($param->{type} eq 'Name') {
          $self->report
            (-type => 'SYNTAX_ATTRDEF_DEFAULT_NAME',
             -class => 'WFC',
             source => $param->{value});
          $q->{ExpandedURI q<attribute-default>} = \'specific';
          $q->{ExpandedURI q<attribute-default-value>} = $param->{value};
        } else {
          die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
        }
        $self->attlist_declaration_content ($src, $pp, $q, %opt);
        redo ATTRDEF;
      } # ATTRDEF
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }}
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
} # parse_attlist_declaration

sub parse_model_group ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $p->{ExpandedURI q<param>} ||= [];
  local $opt{ExpandedURI q<allow-comment>} = 0;
  local $opt{ExpandedURI q<ps-required>} = 0;
  local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_MODEL_GROUP_PS_REQUIRED';
  local $opt{ExpandedURI q<source>} = [$src];
  $opt{ExpandedURI q<allow-ps>} = 1;
  $self->parse_markup_declaration_parameter
              ($src, $p,
               %opt,
               ExpandedURI q<param-type> => {
                 grpo => 1,
                 ps => 1,
               });
  if ($p->{ExpandedURI q<param>}->[0] and
      $p->{ExpandedURI q<param>}->[0]->{type} eq 'grpo') {
    shift @{$p->{ExpandedURI q<param>}};
    $self->model_group_start
              ($src, $p, my $pp = {
                 ExpandedURI q<param> => $p->{ExpandedURI q<param>},
               }, %opt);
    local $opt{ExpandedURI q<match-or-error>} = 0;
    my $i = 0; # $i'th item currently reading
    my $has_pcdata = 0;
    my $connect;
    PARAMS: {
      $self->parse_markup_declaration_parameter
              ($src, $pp, %opt,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_MODEL_GROUP_ITEM_REQUIRED',
               ExpandedURI q<param-type> => {
                 Name => 1,  ## Element type name
                 grpo => 1,  ## Nested model group
                 dtgo => 1,  ## Data tag model group
                 rniKeyword => 1, ## #PCDATA
                 ps => 1,
               });
      my $param = $pp->{ExpandedURI q<param>}->[0];
      my $ppp = {ExpandedURI q<param> => $pp->{ExpandedURI q<param>}};
      unless ($param) {
        last PARAMS;
      } elsif ($param->{type} eq 'Name') {
        $ppp->{ExpandedURI q<element-type-name>} = $param->{value};
        $ppp->{ExpandedURI q<item-type>} = 'gi';
        shift @{$pp->{ExpandedURI q<param>}};
        my $src = $opt{ExpandedURI q<source>}->[-1];
        if ($$src =~ /\G([?+*])/gc) {
          my $del = $1;
          $self->{error}->set_position ($src, moved => 1,
                                        diff => length $del);
          $self->{error}->fork_position ($src => \$del);
          $ppp->{ExpandedURI q<occurrence>} = \$del;
        }
      } elsif ($param->{type} eq 'grpo') {
        if ($has_pcdata) {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_MIXED_NESTED',
             -class => 'WFC',
             source => $param->{value});
        }
        $self->parse_model_group
          ($opt{ExpandedURI q<source>}->[-1], $ppp, %opt);
        $ppp->{ExpandedURI q<item-type>} = 'group';
      } elsif ($param->{type} eq 'rniKeyword') {
        shift @{$p->{ExpandedURI q<param>}};
        if (${$param->{value}} eq 'PCDATA') {
          $ppp->{ExpandedURI q<item-type>} = 'PCDATA';
          $has_pcdata = 1;
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_PCDATA_POSITION',
             -class => 'WFC',
             source => $param->{value})
            if $i != 0;
        } else {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_UNKNOWN_KEYWORD',
             -class => 'WFC',
             source => $param->{value},
             keyword => ${$param->{value}});
        }
      } elsif ($param->{type} eq 'dtgo') {
        shift @{$pp->{ExpandedURI q<param>}};
        $self->report
          (-type => 'SYNTAX_DATA_TAG_GROUP',
           -class => 'WFC',
           source => $param->{value});
        redo PARAMS; # not implemented
      } else {
        die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
      }
      
      $i++;
      $self->parse_markup_declaration_parameter
              ($src, $pp, %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<param-type> => {
                 connector => 1,
                 ps => 1,
               },
               ExpandedURI q<allow-connector> => {
                 ',' => 1, '|' => 1, '&' => 0,
               });
      my $connector = $pp->{ExpandedURI q<param>}->[0];
      if ($connector and $connector->{type} eq 'connector') {
        shift @{$pp->{ExpandedURI q<param>}};
        $ppp->{ExpandedURI q<connector>} = $connector->{value};
        $connect ||= ${$connector->{value}};
        if ($connect ne ${$connector->{value}}) {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_CONNECTOR_MATCH',
             -class => 'WFC',
             source => $connector->{value},
             old => $connect,
             new => ${$connector->{value}});
        } elsif ($has_pcdata and $connect ne '|') {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_MIXED_CONNECTOR',
             -class => 'WFC',
             source => $connector->{value},
             connector => ${$connector->{value}});
        }
        $opt{ExpandedURI q<match-or-error>} = 1;
        $self->model_group_content ($src, $pp, $ppp, %opt);
        redo PARAMS;
      } else {
        $self->model_group_content ($src, $pp, $ppp, %opt);
      }
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $$src =~ /\G\)/gc
        or $self->report
              (-type => 'SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
               -class => 'WFC',
               source => $src);
      if ($$src =~ /\G([?+*])/gc) {
        my $del = $1;
        $self->{error}->set_position ($src, moved => 1,
                                      diff => length $del);
        $self->{error}->fork_position ($src => \$del);
        $p->{ExpandedURI q<occurrence>} = \$del;
        if ($has_pcdata and $del ne '*') {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_'.($i > 1 ? 'MIXED' : 'PCDATA')
                     .'_OCCUR',
             -class => 'WFC',
             source => $src,
             position_diff => 1);
        }
      } elsif ($has_pcdata and $i > 1) {
        $self->report
          (-type => 'SYNTAX_MODEL_GROUP_PCDATA_OCCUR',
           -class => 'WFC',
           source => $src,
           position_diff => 1);
      }
    }
    $self->model_group_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    return 0;
  }
} # parse_model_group

sub parse_attrtype_group ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $p->{ExpandedURI q<param>} ||= [];
  $opt{ExpandedURI q<allow-ps>} = 1;
  local $opt{ExpandedURI q<allow-comment>} = 0;
  local $opt{ExpandedURI q<ps-required>} = 0;
  local $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_ATTRDEF_PS_REQUIRED';
  local $opt{ExpandedURI q<source>} = [$src];
  $self->parse_markup_declaration_parameter
              ($src, $p,
               %opt,
               ExpandedURI q<param-type> => {
                 grpo => 1,
                 ps => 1,
               });
  if ($p->{ExpandedURI q<param>}->[0] and
      $p->{ExpandedURI q<param>}->[0]->{type} eq 'grpo') {
    shift @{$p->{ExpandedURI q<param>}};
    $self->attrtype_group_start
              ($src, $p, my $pp = {
                 ExpandedURI q<param> => $p->{ExpandedURI q<param>},
               }, %opt);
    local $opt{ExpandedURI q<match-or-error>} = 0;
    PARAMS: {
      $self->parse_markup_declaration_parameter
              ($src, $pp, %opt,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_ATTRDEF_TYPE_GROUP_NMTOKEN_REQUIRED',
               ExpandedURI q<param-type> => {
                 Name => 1,
                 ps => 1,
               });
      my $param = $pp->{ExpandedURI q<param>}->[0];
      my $ppp = {ExpandedURI q<param> => $pp->{ExpandedURI q<param>}};
      unless ($param) {
        last PARAMS;
      } elsif ($param->{type} eq 'Name') {
        $ppp->{ExpandedURI q<nmtoken>} = $param->{value};
        shift @{$pp->{ExpandedURI q<param>}};
      } else {
        die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
      }
      
      $self->parse_markup_declaration_parameter
              ($src, $pp, %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<param-type> => {
                 connector => 1,
                 ps => 1,
               },
               ExpandedURI q<allow-connector> => {
                 ',' => 0, '|' => 1, '&' => 0,
               });
      my $connector = $pp->{ExpandedURI q<param>}->[0];
      if ($connector and $connector->{type} eq 'connector') {
        shift @{$pp->{ExpandedURI q<param>}};
        $ppp->{ExpandedURI q<connector>} = $connector->{value};
        $opt{ExpandedURI q<match-or-error>} = 1;
        $self->attrtype_group_content ($src, $pp, $ppp, %opt);
        redo PARAMS;
      } else {
        $self->attrtype_group_content ($src, $pp, $ppp, %opt);
      }
    } continue {
      $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<match-or-error> => 0,
               ExpandedURI q<ps-required> => 0,
               ExpandedURI q<param-type> => {
                 ps => 1,
               });
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $$src =~ /\G\)/gc
        or $self->report
              (-type => 'SYNTAX_ATTRDEF_TYPE_GROUP_GRPC_REQUIRED',
               -class => 'WFC',
               source => $src);
    }
    $self->attrtype_group_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    return 0;
  }
} # parse_attrtype_group

sub parse_markup_declaration_parameter ($$$%) {
  my ($self, undef, $p, %opt) = @_;
  my $allow = $opt{ExpandedURI q<param-type>};
  my $src = $opt{ExpandedURI q<source>}->[-1];
  
  my $param = $p->{ExpandedURI q<param>};
  CHKPARAM: {
  if (@$param) {
    if ($allow->{$param->[0]->{type}}) {
      return 1;
    }
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => $opt{ExpandedURI q<error-no-match>}
                         || 'SYNTAX_PARAMETER_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
    return 0;
  }}

  if ($allow->{ps}) {
    my $has_ps = 0;
    my $pos = pos $$src;
    EATPS: while (1) {
      if ($$src =~ /\G$REG_S+/gco) {
        if ($opt{ExpandedURI q<end-with-mdc>} and
            $$src =~ /\G>/gc) {
          pos ($$src)--;
          return 1; ## Note: <allow-ps> don't work in this case
        }
        $has_ps = 1;
      } elsif ($$src =~ /\G%/gc) {
        if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
          $self->report
            (-type => $opt{ExpandedURI q<error-param-entref>} ||
                      'SYNTAX_PARAENT_REF_NOT_ALLOWED',
             -class => 'WFC',
             position_diff => $+[0] - $-[0] + 1,
             source => $src)
            if not $opt{ExpandedURI q<allow-param-entref>};
          $self->parameter_entity_reference_in_parameter_start
            ($src, $p,
             my $pp = {ExpandedURI q<entity-name> => $1,
             ExpandedURI q<param> => []},
             %opt);
          $$src =~ /\G;/gc or
            $self->report
              (-type => 'SYNTAX_REFC_REQUIRED',
               -class => 'WFC',
               source => $src,
               entity_name => $pp->{ExpandedURI q<entity-name>});
          $has_ps = 1;

          ## Entity replacement text prepared (in param...start method above)
          ## NOTE: Removing $src from @{$opt{<source>}} in param...start
          ##       is not expected.  Only either push'ing new text or do
          ## no operation is allowed in param...start method.
          if (overload::StrVal ($src) ne
              overload::StrVal ($opt{ExpandedURI q<source>}->[-1])) {
            local $Error::Depth = $Error::Depth + 1;
            $self->parse_markup_declaration_parameter
                  ($src, $p,
                   %opt,
                   ExpandedURI q<ps-required> => 0,
                   ExpandedURI q<end-with-mdc> => 0);
            ## Found
            if (@$param) {
              if (not $opt{ExpandedURI q<allow-ps>}) {
                $self->report
                  (-type => $opt{ExpandedURI q<error-ps>}
                         || 'SYNTAX_MARKUP_DECLARATION_PS',
                   -class => 'WFC',
                   position_diff => pos ($$src) - $pos,
                   source => $src);
              }
              return 1;
            }
          }
        } else { # pero not followed by Name
          pos ($$src)--;
          last EATPS;
        }
      } elsif ($$src =~ /\G(?=--)/gc) {
        $self->report
          (-type => 'SYNTAX_PS_COMMENT',
           -class => 'WFC',
           source => $src);
        $self->parse_comment ($src, $p, %opt);
      ## Reach to end of source text
      } elsif (pos $$src and length $$src == pos $$src) {
        if (@{$opt{ExpandedURI q<source>}} > 1) {
          pop @{$opt{ExpandedURI q<source>}};
          $src = $opt{ExpandedURI q<source>}->[-1];
          redo EATPS;
        } else {
          last EATPS;
        }
      } else { # neither s, pero nor comment
        last EATPS;
      }
    } # EATPS
      
    unless ($has_ps) {
      if ($opt{ExpandedURI q<end-with-mdc>} and
          $$src =~ /\G>/gc) {
        pos ($$src)--;
        return 1;
      } elsif ($opt{ExpandedURI q<end-with-mso>} and
               $$src =~ /\G(?=\[)/gc) {
        return 1;
      } elsif ($opt{ExpandedURI q<ps-required>}) {
        $self->report
              (-type => $opt{ExpandedURI q<error-ps-required>}
                        || 'SYNTAX_MARKUP_DECLARATION_PS_REQUIRED',
               -class => 'WFC',
               source => $src);
      }
    } elsif (not $opt{ExpandedURI q<allow-ps>}) {
      $self->report
              (-type => $opt{ExpandedURI q<error-ps>}
                        || 'SYNTAX_MARKUP_DECLARATION_PS',
               -class => 'WFC',
               position_diff => pos ($$src) - $pos,
               source => $src);
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
    ## ISSUE: Should we cause error if RNI not followed by Name occurs?
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
      ($pubid) = ($$src =~ /\G([^"]*)/gc);
      $$src =~ /\G"/gc or
        $self->report
               (-type => 'SYNTAX_PUBLIT_MLITC_REQUIRED',
                -class => 'WFC',
                source => $src);
    } else {
      ($pubid) = ($$src =~ /\G([^']*)/gc);
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
      ($sysid) = ($$src =~ /\G([^"]*)/gc);
      $$src =~ /\G"/gc or
        $self->report
               (-type => 'SYNTAX_SLITC_REQUIRED',
                -class => 'WFC',
                source => $src);
    } else {
      ($sysid) = ($$src =~ /\G([^']*)/gc);
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
  } elsif ($allow->{attrValLit} and
           $$src =~ /\G(?=["'])/gc) {
    push @$param, {type => 'attrValLit'};
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
  } elsif ($allow->{connector} and $$src =~ /\G([,|&])/gc) {
    my $del = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $del);
    $self->{error}->fork_position ($src => \$del);
    unless ($opt{ExpandedURI q<allow-connector>}->{$del}) {
      $self->report
        (-type => 'SYNTAX_CONNECTOR',
         -class => 'WFC',
         source => $src,
         position_diff => 1,
         connector => $del);
    }
    push @$param, {type => 'connector', value => \$del};
  } elsif ($allow->{grpo} and $$src =~ /\G(\()/gc) {
    my $del = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $del);
    $self->{error}->fork_position ($src => \$del);
    push @$param, {type => 'grpo', value => \$del};
  } elsif ($allow->{grpc} and $$src =~ /\G(\))/gc) {
    my $del = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $del);
    $self->{error}->fork_position ($src => \$del);
    push @$param, {type => 'grpc', value => \$del};
  } elsif ($allow->{dso} and $$src =~ /\G\[/gc) {
    push @$param, {type => 'dso'};
  } elsif ($allow->{dsc} and $$src =~ /\G\]/gc) {
    push @$param, {type => 'dsc'};
  } elsif ($allow->{minus} and $$src =~ /\G(-)/gc) {
    my $min = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $min);
    $self->{error}->fork_position ($src => \$min);
    push @$param, {type => 'minus', value => \$min};
  } elsif ($allow->{number} and $$src =~ /\G([0-9]+)/gc) {
    my $num = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $num);
    $self->{error}->fork_position ($src => \$num);
    push @$param, {type => 'number', value => \$num};
  } elsif ($allow->{dtgo} and $$src =~ /\G(\[)/gc) {
    my $del = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $del);
    $self->{error}->fork_position ($src => \$del);
    push @$param, {type => 'dtgo', value => \$del};
  } elsif ($allow->{dtgc} and $$src =~ /\G(\])/gc) {
    my $del = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $del);
    $self->{error}->fork_position ($src => \$del);
    push @$param, {type => 'dtgc', value => \$del};
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
    local $opt{ExpandedURI q<end-with-mdc>} = 0;
    if ($opt{ExpandedURI q<allow-system-id>}) {
      $opt{ExpandedURI q<match-or-error>}
        = $opt{ExpandedURI q<system-id-required>};
      $opt{ExpandedURI q<end-with-mdc>}
        = not $opt{ExpandedURI q<system-id-required>};
    }
    $self->parse_markup_declaration_parameter
            ($src, $p,
             %opt,
             ExpandedURI q<ps-required> => 1,
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
    $opt{ExpandedURI q<allow-declaration>} ||= {
                     ENTITY => 1, NOTATION => 1,
                     ELEMENT => 1, ATTLIST => 1,
                     comment => 1, section => 1,
                   };
    $opt{ExpandedURI q<allow-section>} ||= {
                     INCLUDE => 1, IGNORE => 1,
                   };
    $opt{ExpandedURI q<allow-section-ps>} = 1;
    $opt{ExpandedURI q<section-content-parser>} ||= 'parse_doctype_subset';
    $opt{ExpandedURI q<source>} = [$src];
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
      } elsif ($$src =~ /\G($REG_S+)/gc) {
        my $cdata = $1;
        $self->{error}->set_position ($src, moved => 1,
                                      diff => length $cdata);
        $self->{error}->fork_position ($src => \$cdata);
        $self->doctype_subset_s ($src, $p, {ExpandedURI q<s> => \$cdata}, %opt);
      } elsif ($$src =~ /\G%/gc) {
        if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
          $self->parameter_entity_reference_in_subset_start
            ($src, $p,
             my $pp = {ExpandedURI q<entity-name> => $1,
             ExpandedURI q<param> => []},
             %opt);
          $$src =~ /\G;/gc or
            $self->report
              (-type => 'SYNTAX_REFC_REQUIRED',
               -class => 'WFC',
               source => $src,
               entity_name => $pp->{ExpandedURI q<entity-name>});
          
          ## Entity Text found
          if (overload::StrVal ($src) ne
              overload::StrVal ($opt{ExpandedURI q<source>}->[-1])) {
            local $Error::Depth = $Error::Depth + 1;
            local $opt{ExpandedURI q<allow-declaration>}->{section} = 1,
            local $opt{ExpandedURI q<allow-param-entref>} = 1
              if $self->{error}->get_flag
                   ($opt{ExpandedURI q<source>}->[-1], 
                    ExpandedURI q<is-external-entity>);
            $self->parse_doctype_subset
                  ($opt{ExpandedURI q<source>}->[-1],
                   $p, %opt,
                   ExpandedURI q<end-with-dsc> => 0,
                   ExpandedURI q<end-with-mse> => 0);
          }
        } else { # pero not followed by Name
          $self->report
                  (-type => 'SYNTAX_DOCTYPE_SUBSET_INVALID_CHAR',
                   -class => 'WFC',
                   position_diff => 1,
                   source => $src,
                   char => '%');
        }
      } elsif ($opt{ExpandedURI q<end-with-mse>} and
               $$src =~ /\G\]\]>/gc) {
        last SUBSET;
      } elsif ($opt{ExpandedURI q<end-with-dsc>} and
               $$src =~ /\G\]/gc) {
        last SUBSET;
      } elsif ($$src =~ /\G(.)/gcs) {
        $self->report
                  (-type => 'SYNTAX_DOCTYPE_SUBSET_INVALID_CHAR',
                   -class => 'WFC',
                   position_diff => 1,
                   source => $src,
                   char => $1);
      } else {
        die substr $$src, pos $$src;
      }
    }
    if ($opt{ExpandedURI q<end-with-mse>}) {
      $self->report
                  (-type => 'SYNTAX_MSE_REQUIRED',
                   -class => 'WFC',
                   source => $src);
    } elsif ($opt{ExpandedURI q<end-with-dsc>}) {
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


sub parse_marked_section ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!\[/gc) {
    $self->marked_section_start
              ($src, $p, my $pp = {}, %opt);
    $opt{ExpandedURI q<end-with-mdc>} = 0;
    $opt{ExpandedURI q<match-or-error>} = 1;
    $opt{ExpandedURI q<allow-comment>} = 0;
    $opt{ExpandedURI q<ps-required>} = 0;
    $opt{ExpandedURI q<error-ps-required>}
        = 'SYNTAX_MARKED_SECTION_PS_REQUIRED';
    $opt{ExpandedURI q<source>} = [$src];
    $opt{ExpandedURI q<end-with-mso>} = 0;
    $opt{ExpandedURI q<error-ps>} = 'SYNTAX_MARKED_SECTION_STATUS_PS';
    my %kwd;
    PARAMS: {
      $self->markup_declaration_parameters_start
              ($src, $p, $pp, %opt);
      $pp->{ExpandedURI q<param>} = [];
      
      ## Status Keyword
      KEYWORD: {
        $self->parse_markup_declaration_parameter
              ($src, $pp,
               %opt,
               ExpandedURI q<error-no-match>
                 => 'SYNTAX_MARKED_SECTION_KEYWORD_REQUIRED',
               ExpandedURI q<param-type> => {
                 Name => 1,
                 ps => 1,
               },
               ExpandedURI q<allow-ps> => $opt{ExpandedURI q<allow-section-ps>});
        my $entname = shift @{$pp->{ExpandedURI q<param>}};
        unless ($entname) {
          last PARAMS;
        } elsif ($entname->{type} eq 'Name') {
          $kwd{${$entname->{value}}}++;
          $self->report
            (-type => 'SYNTAX_MARKED_SECTION_KEYWORDS',
             -class => 'WFC',
             source => $entname->{value})
            if $opt{ExpandedURI q<ps-required>};
          if ($opt{ExpandedURI q<allow-section>}->{${$entname->{value}}}) {
            # 
          } else {
            $self->report
              (-type => 'SYNTAX_MARKED_SECTION_KEYWORD',
               -class => 'WFC',
               source => $entname->{value},
               keyword => ${$entname->{value}});
          }
        } else {
          die "$0: ".__PACKAGE__.": $entname->{type}: Buggy";
        }
        $opt{ExpandedURI q<ps-required>} = 1;
        $opt{ExpandedURI q<match-or-error>} = 0;
        $opt{ExpandedURI q<end-with-mso>} = 1;
        redo KEYWORD;
      }
    } continue {
      if (@{$pp->{ExpandedURI q<param>}} or
          @{$opt{ExpandedURI q<source>}} > 1) {
        $self->report
              (-type => 'SYNTAX_MARKUP_DECLARATION_TOO_MANY_PARAM',
               -class => 'WFC',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }
    unless ($$src =~ /\G\[/gc) {
      $self->report
              (-type => 'SYNTAX_MSO_REQUIRED',
               -class => 'WFC',
               source => $src);
    }
    $pp->{ExpandedURI q<section-status>} = \%kwd;
    $self->marked_section_content_start
             ($src, $p, $pp, %opt);
    if ($kwd{IGNORE}) {
      $pp->{ExpandedURI q<section-type>} = 'ignore';
      $self->parse_ignored_section_content
             ($src, $pp, %opt, 
              ExpandedURI q<end-with-mse> => 1);
    } elsif ($kwd{CDATA} || $kwd{RCDATA}) { ## RCDATA not implemented
      $$src =~ /\G((?>(?!\]\]>).)*)/gcs;
      my $cdata = $1;
      $self->{error}->set_position ($src, moved => 1,
                                    diff => length $cdata);
      $self->{error}->fork_position ($src => \$cdata);
      $pp->{ExpandedURI q<section-type>} = 'cdata';
      $pp->{ExpandedURI q<cdata>} = \$cdata;
      $$src =~ /\G\]\]>/gc
        or $self->report
             (-type => 'SYNTAX_MSE_REQUIRED',
              -class => 'WFC',
              source => $src);
    } elsif (my $parser = $opt{ExpandedURI q<section-content-parser>}) {
      $pp->{ExpandedURI q<section-type>} = 'include';
      $self->$parser
             ($src, $pp, %opt,
              ExpandedURI q<end-with-mse> => 1);
    } else { ## Error: parse as if CDATA section
      $$src =~ /\G((?>(?!\]\]>).)*)/gcs;
      my $cdata = $1;
      $self->{error}->set_position ($src, moved => 1,
                                    diff => length $cdata);
      $self->{error}->fork_position ($src => \$cdata);
      $pp->{ExpandedURI q<section-type>} = 'cdata';
      $pp->{ExpandedURI q<cdata>} = \$cdata;
      $$src =~ /\G\]\]>/gc
        or $self->report
             (-type => 'SYNTAX_MSE_REQUIRED',
              -class => 'WFC',
              source => $src);
    }
    $self->marked_section_content_end
              ($src, $p, $pp, %opt);
    $self->marked_section_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    return 0;
  }
} # parse_marked_section

sub parse_ignored_section_content ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  while (pos $$src < length $$src) {
    if ($$src =~ /\G((?>(?!<!\[|\]\]>).)+)/gco) {
      my $cdata = $1;
      $self->{error}->set_position ($src, moved => 1,
                                    diff => length $cdata);
      $self->{error}->fork_position ($src => \$cdata);
      $self->ignored_section_content
        ($src, $p,
         {ExpandedURI q<cdata> => $cdata}, %opt);
    } elsif ($$src =~ /\G<!\[/gc) {
      $self->parse_ignored_section_content
        ($src, $p, %opt,
         ExpandedURI q<end-with-mse> => 1);
    } elsif ($$src =~ /\G\]\]>/gc) {
      return 1;
    } else {
      die "$0: ".__PACKAGE__.": ignored_section: Buggy";
    }
  }
  if ($opt{ExpandedURI q<end-with-mse>}) {
    $self->report
      (-type => 'SYNTAX_MSE_REQUIRED',
       -class => 'WFC',
       source => $src);
  }
  return 1;
} # parse_ignored_section_content

sub parse_processing_instruction ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<\?/gc) {
    my $pp = {};
    if ($$src =~ /\G(\p{InXML_NameStartChar}\p{InXMLNameChar}*)/gc) {
      my $tn = $1;
      if ($tn eq 'xml') {
        $self->report
               (-type => 'SYNTAX_XML_DECLARATION_IN_MIDDLE',
                -class => 'WFC',
                source => $src,
                position_diff => 5);
      } elsif (lc $tn eq 'xml') {
        $self->report
               (-type => 'SYNTAX_PI_TARGET_XML',
                -class => 'WFC',
                source => $src,
                target_name => $tn,
                position_diff => 3);
      }
      $pp->{ExpandedURI q<target-name>} = $tn;
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
      ## Note: _content called iif there is S after target name
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
    return 1;
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

sub parse_xml_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<\?xml\b/gc) {
    my $s = '';
    my $data = '';
    $self->{error}->set_position ($src, moved => 1);
    $self->{error}->fork_position ($src => \$s);
    ## Get target data
    if ($$src =~ /\G($REG_S)/gco) {
      $s = $1;
      $self->{error}->set_position ($src, moved => 1);
      if ($$src =~ /\G((?:(?!\?>).)+)/gcs) {
        $data = $1;
      }
    }
    pos ($data) = 0;
    $self->{error}->fork_position ($src => \$data);

    ## Parse target data
    my $type = $opt{ExpandedURI q<allow-xml-declaration>} ?
                 $opt{ExpandedURI q<allow-text-declaration>} ?
                   'xml-or-text' : 'xml' :
                 $opt{ExpandedURI q<allow-text-declaration>} ?
                   'text' : die "Bug: Neither XML or text declaration allowed";
    $self->parse_attribute_specifications
              (\$data, my $pp = {},
               %opt,
               ExpandedURI q<s-before-attribute-specifications> => \$s,
               ExpandedURI q<use-reference> => 0,
               ExpandedURI q<match-or-error> => 1,
               ExpandedURI q<attr-specs-only> => 1,
               ExpandedURI q<method-start-attr-specs> 
                 => '____xml_declaration_pseudo_attr_specs_start',
               ExpandedURI q<method-end-attr-specs>
                 => '____xml_declaration_pseudo_attr_specs_end',
               ExpandedURI q<method-start-attr-spec>
                 => '____xml_declaration_pseudo_attr_spec_start',
               ExpandedURI q<method-end-attr-spec>
                 => '____xml_declaration_pseudo_attr_spec_end',
               ExpandedURI q<method-start-attr-value-spec>
                 => '____xml_declaration_pseudo_attr_value_spec_start',
               ExpandedURI q<method-content-attr-value-spec>
                 => '____xml_declaration_pseudo_attr_value_spec_content',
               ExpandedURI q<method-end-attr-value-spec>
                 => '____xml_declaration_pseudo_attr_value_spec_end');
    my $attr = $pp->{ExpandedURI q<_:attr>};
    my $sep = $pp->{ExpandedURI q<_:attr-s>};
    my $xmlver = '1.0';
    if ($attr->[0] and ${$attr->[0]->{name}} eq 'version') {
      $xmlver = ${$attr->[0]->{value}};
      if ($xmlver eq '1.0' or $xmlver eq '1.1') {
        # 
      } else {
        unless ($xmlver =~ /^[0-9A-Za-z.:_-]+$/) {
          $self->report
              (-type => 'SYNTAX_XML_VERSION_INVALID',
               -class => 'WFC',
               source => $attr->[0]->{value},
               version => $xmlver);
        }
        $self->report
              (-type => 'SYNTAX_XML_VERSION_UNSUPPORTED',
               -class => 'WFC',
               source => $attr->[0]->{value},
               version => $xmlver);
      }
      shift @$attr;  shift @$sep;
    } else {
      if ($type eq 'xml') {
        $self->report
              (-type => 'SYNTAX_XML_VERSION_REQUIRED',
               -class => 'WFC',
               source => $attr->[0] ? $attr->[0]->{name} : $src);
      } elsif ($type eq 'xml-or-text') {
        $type = 'text';
      }
    }
    
    my $encoding;
    if ($attr->[0] and ${$attr->[0]->{name}} eq 'encoding') {
      $encoding = ${$attr->[0]->{value}};
      unless ($encoding =~ /^[A-Za-z][A-Za-z0-9._-]*$/) {
        $self->report
              (-type => 'SYNTAX_XML_ENCODING_INVALID',
               -class => 'WFC',
               source => $attr->[0]->{value},
               encoding => $encoding);
      }
      shift @$attr;  shift @$sep;      
    } else {
      if ($type eq 'text') {
        $self->report
              (-type => 'SYNTAX_XML_ENCODING_REQUIRED',
               -class => 'WFC',
               source => $attr->[0] ? $attr->[0]->{name} : $src);
      }
    }
    
    my $standalone;
    if ($attr->[0] and ${$attr->[0]->{name}} eq 'standalone') {
      $standalone = ${$attr->[0]->{value}};
      if ($type eq 'text') {
        $self->report
              (-type => 'SYNTAX_XML_STANDALONE',
               -class => 'WFC',
               source => $attr->[0]->{name});
      } elsif ($type eq 'xml-or-text') {
        $type = 'xml';
      }
      unless ($standalone eq 'yes' or $standalone eq 'no') {
        $self->report
              (-type => 'SYNTAX_XML_STANDALONE_INVALID',
               -class => 'WFC',
               source => $attr->[0]->{value},
               standalone => $standalone
);
      }
      unless (${$sep->[0]} =~ /^\x20+$/) {
        if ($xmlver ne '1.0') { # 1.1
          $self->report
              (-type => 'SYNTAX_XML_STANDALONE_S',
               -class => 'WFC',
               source => $sep->[0]);
        }
      }
      shift @$attr;  shift @$sep;
    }
    
    my $q = {};
    $q->{ExpandedURI q<xml-declaration-version>} = $xmlver;
    $q->{ExpandedURI q<xml-declaration-encoding>} = $encoding;
    $q->{ExpandedURI q<xml-declaration-standalone>} = $standalone;
    $q->{ExpandedURI q<xml-declaration-type>} = $type;
    
    for (@$attr) {
      $self->report
              (-type => 'SYNTAX_XML_UNKNOWN_ATTR',
               -class => 'WFC',
               source => $_->{name},
               attribute_name => ${$_->{name}});
      $q->{ExpandedURI q<xml-declaration-pseudo-attr-misc>} = $attr;
    }
    $self->xml_declaration ($src, $p, $q, %opt);

    ## Check pic
    unless ($$src =~ /\G\?>/gc) {
      $self->report
               (-type => 'SYNTAX_PIC_REQUIRED',
                -class => 'WFC',
                source => $src);
    }
  }
} # parse_xml_declaration

sub ____xml_declaration_pseudo_attr_specs_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<_:attr>}
    = $pp->{ExpandedURI q<_:attr>} = [];
}
sub ____xml_declaration_pseudo_attr_specs_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<_:attr-s>} 
    = $pp->{ExpandedURI q<s-between-attribute-specifications>};
}
sub ____xml_declaration_pseudo_attr_spec_start ($$$$%) {

}
sub ____xml_declaration_pseudo_attr_spec_end ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  my $value = join '', map {$$_} @{$pp->{ExpandedURI q<_:attr-val>}};
  pos ($value) = 0;
  if ($pp->{ExpandedURI q<_:attr-val>}->[0]) {
    $self->{error}->fork_position
      ($pp->{ExpandedURI q<_:attr-val>}->[0] => \$value);
  } else {
    $self->{error}->set_position ($src, moved => 1, diff => 1);
    $self->{error}->fork_position ($src => \$value);
  }
  push @{$p->{ExpandedURI q<_:attr>}},
    {name => $pp->{ExpandedURI q<attribute-name>}, value => \$value};
}
sub ____xml_declaration_pseudo_attr_value_spec_start ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  $p->{ExpandedURI q<_:attr-val>} = [];
}
sub ____xml_declaration_pseudo_attr_value_spec_content ($$$$%) {
  my ($self, $src, $p, $pp, %opt) = @_;
  push @{$p->{ExpandedURI q<_:attr-val>}}, $pp->{ExpandedURI q<CDATA>};
}
sub ____xml_declaration_pseudo_attr_value_spec_end ($$$$%) {
  
}

sub report ($@) {
  shift->{error}->report (@_);
}

sub document_start ($$$$%) {}
sub xml_declaration ($$$$%) {}
sub document_content ($$$$%) {}
sub document_end ($$$$%) {}

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
sub attlist_declaration_content ($$$$%) {}
sub attlist_declaration_end ($$$$%) {}

sub notation_declaration_start ($$$$%) {}
sub notation_declaration_end ($$$$%) {}

sub markup_declaration_parameters_start ($$$$%) {}
sub markup_declaration_parameter ($$$$%) {}
sub markup_declaration_parameters_end ($$$$%) {}

sub model_group_start ($$$$%) {}
sub model_group_content ($$$$%) {}
sub model_group_end ($$$$%) {}

sub attrtype_group_start ($$$$%) {}
sub attrtype_group_content ($$$$%) {}
sub attrtype_group_end ($$$$%) {}

sub public_identifier_start ($$$$%) {}
sub system_identifier_start ($$$$%) {}

sub rpdata_start ($$$$%) {}
sub rpdata_content ($$$$%) {}
sub rpdata_end ($$$$%) {}

sub parameter_literal_start ($$$$%) {}
sub parameter_literal_content ($$$$%) {}
sub parameter_literal_end ($$$$%) {}

sub doctype_subset_start ($$$$%) {}
sub doctype_subset_s ($$$$%) {}
sub doctype_subset_end ($$$$%) {}

sub comment_declaration_start ($$$$%) {}
sub comment_declaration_end ($$$$%) {}

sub marked_section_start ($$$$%) {}
sub marked_section_status ($$$$%) {}
sub marked_section_content_start ($$$$%) {}
sub ignored_section_content ($$$$%) {}
sub marked_section_content_end ($$$$%) {}
sub marked_section_end ($$$$%) {}

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

1; # $Date: 2004/05/31 00:48:44 $
