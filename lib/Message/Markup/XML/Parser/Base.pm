
=head1 NAME

Message::Markup::XML::Parser::Base --- Manakai Simple XML Parser (Base Module)

=head1 DESCRIPTION

This is a simple XML parser.  This module is a "base" class module.
Parsing XML entities causes parsing-events (as SAX parser does,
while events of this parser is more "physical").  Derived class
modules implements those events to construct some graph structure
such as DOM tree (or converts into other event model like SAX).

This module is part of manakai.

=cut

package Message::Markup::XML::Parser::Base;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1.2.16 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML
    qw[InXML_NameStartChar10 InXMLNameChar10
       InXMLNameStartChar11 InXMLNameChar11
       InXMLChar10 InXMLChar11
       InXML_UnrestrictedChar11 InXMLRestrictedChar11];
require Message::Markup::XML::Parser::Error;
require overload;
use URI;

sub URI_CONFIG () {
  q<http://suika.fam.cx/~wakaba/-temp/2004/2/22/Parser/>
}
use Message::Markup::XML::QName qw/DEFAULT_PFX/;
use Message::Util::QName::General [qw/ExpandedURI/],
    {
     (DEFAULT_PFX) => URI_CONFIG,
     _ => q<http://suika.fam.cx/~wakaba/-temp/2004/5/30/parser-internal#>,
     Content => q<urn:x-suika-fam-cx:msgpm:header:mail:rfc822:content>,
     infoset => q<http://www.w3.org/2001/04/infoset#>,
    };
my $REG_S = qr/[\x09\x0A\x0D\x20]/; 
        # S := 1*(U+0020 / U+0009 / U+000D / U+000A) ;; [3]
my %XML_NAME = ('1.0' => qr/\p{InXML_NameStartChar10}\p{InXMLNameChar10}*/,
                '1.1' => qr/\p{InXMLNameStartChar11}\p{InXMLNameChar11}*/);
my %XML_NAMESTART = ('1.0' => qr/\p{InXML_NameStartChar10}/,
                     '1.1' => qr/\p{InXMLNameStartChar11}/);

=head1 METHODS

This module implements these common methods:

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->{error} ||= Message::Util::Error::TextParser->new
                       (package => 'Message::Markup::XML::Parser::Error');
  $self;
}

sub reset ($;%) {
  my ($self, %opt) = @_;
  for (keys %$self) {
    delete $self->{$_} unless $_ eq 'error';
  }
  $self->{error}->reset;
}

sub ____set_base_uri ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  for (ExpandedURI q<base-uri>,
       ExpandedURI q<uri>,
       ExpandedURI q<original-uri>) {
    $p->{$_} ||= $self->{error}->get_flag ($src, $_)
  }
  unless ($p->{ExpandedURI q<base-uri>} ||= $p->{ExpandedURI q<uri>}
                                        ||= $p->{ExpandedURI q<original-uri>}) {
    my $base_uri;
    $base_uri = URI->new (q<data:>);
    my $mt = $p->{ExpandedURI q<Content:Type>} ||
             q<application/xml;charset=utf-8>;
    ## BUG: This replacing cause problem if media type
    ##      has quoted-string which contains string that
    ##      seems a charset parameter.
    $mt =~ s{;\s*[Cc][Hh][Aa][Rr][Ss][Ee][Tt]\s*=\s*
                        (?>
                            [^";\s]+ |
                            "(?>[^"\\]*)(?>(?>[^"\\]*|\\.)*)"
                        )}
            {;charset=utf-8}sx or do {
      $mt .= q<;charset=utf-8> if $mt =~ m#^text/#i;
    };
    $base_uri->media_type ($mt);
    require Encode;
    $base_uri->data (Encode::encode ('utf8', $$src));
    $p->{ExpandedURI q<base-uri>} = $base_uri;
  }
  $self->{error}->default_flag ($src, ExpandedURI q<base-uri>
                                      => $p->{ExpandedURI q<base-uri>});
}

sub parse_document_entity ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->____set_base_uri ($src, $p, %opt);
  $self->____normalize_entity
           ($src, $p, %opt,
            ExpandedURI q<see-xml-declaration> => 1);
  $self->document_start ($src, $p, my $pp = {}, %opt);
  if ($$src =~ /\G(?=<\?xml\P{InXMLNameChar11})/gc) {
    $self->parse_xml_declaration
      ($src, $pp, %opt,
       ExpandedURI q<allow-xml-declaration> => 1,
       ExpandedURI q<allow-text-declaration> => 0);
  }
  
  pos $$src ||= 0;
  my $docelem = 0;
  while (pos $$src < length $$src) {
    if ($$src =~ /\G</gc) {
      if ($$src =~ /\G$XML_NAMESTART{$self->{ExpandedURI q<xml-version>}||'1.0'}/gc) {
        pos ($$src) -= 2;
        if ($docelem++) {
          $self->report
            (-type => 'SYNTAX_MULTIPLE_DOCUMENT_ELEMENTS',
             -class => 'SYNTAX',
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
           -class => 'SYNTAX',
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
         -class => 'SYNTAX',
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
       -class => 'SYNTAX',
       source => $src);
  }
  $self->document_end ($src, $p, $pp, %opt);
}

sub parse_external_parsed_entity ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->____set_base_uri ($src, $p, %opt);
  $self->____normalize_entity
           ($src, $p, %opt,
            ExpandedURI q<see-xml-declaration> => 1);
  $self->external_parsed_entity_start ($src, $p, my $pp = {}, %opt);
  if ($$src =~ /\G(?=<\?xml\P{InXMLNameChar11})/gc) {
    $self->parse_xml_declaration
      ($src, $pp, %opt,
       ExpandedURI q<allow-xml-declaration> => 0,
       ExpandedURI q<allow-text-declaration> => 1);
  }
  
  my $s = substr $$src, pos ($$src) ||= 0;
  pos $s = 0;
  $self->{error}->set_position ($src, moved => 1);
  $self->{error}->fork_position ($src => \$s);
  $pp->{ExpandedURI q<CDATA>} = \$s;
  $self->external_parsed_entity_content ($src, $p, $pp, %opt);
  $self->external_parsed_entity_end ($src, $p, $pp, %opt);
} # parse_external_parsed_entity

sub ____normalize_entity ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  unless ($self->{ExpandedURI q<xml-declaration-version>}) {
    if ($opt{ExpandedURI q<see-xml-declaration>}) {
      if ($$src =~ /^<\?xml\P{InXMLNameStartChar11}(.+?)\?>/) {
        my $data = $1;
        if ($data =~ /version="([^"]+)"/) {
          $self->{ExpandedURI q<xml-declaration-version>} ||= $1;
          $self->{ExpandedURI q<xml-version>} ||= $1 eq '1.0' ? '1.0' : '1.1';
        }
        if ($data =~ /[\x85\x{2028}]/) {
          $self->report
                   (-type => 'FATAL_NEW_NL_IN_XML_DECLARATION',
                    -class => 'WFC',
                    source => $src);
        }
      }
    }
  }
  my $xmlver = $self->{ExpandedURI q<xml-version>} || '1.0';
  
  $$src =~ s/\x0D\x0A/\x0A/g;
  $$src =~ s/\x0D\x85/\x0A/g unless $xmlver eq '1.0';
  $$src =~ s/\x0D/\x0A/g;
  
  unless ($xmlver eq '1.0') {
  ## XML 1.1
    $$src =~ s/\x85/\x0A/g;
    $$src =~ s/\x{2028}/\x0A/g;
    
    while ($$src =~ /(\P{InXML_UnrestrictedChar11})/g) {
      my $char = $1;
      if ($char =~ /\p{InXMLRestrictedChar11}/) {
        $self->report
                 (-type => 'SYNTAX_RESTRICTED_CHAR',
                  -class => 'SYNTAX',
                  source => $src,
                  position_diff => 1,
                  char => $char);
      } else {
        $self->report
                 (-type => 'SYNTAX_NOT_IN_CHAR',
                  -class => 'SYNTAX',
                  source => $src,
                  position_diff => 1,
                  char => $char);
      }
    }
  } else {
  ## XML 1.0
    while ($$src =~ /(\P{InXMLChar10})/g) {
      my $char = $1;
      $self->report
                 (-type => 'SYNTAX_NOT_IN_CHAR',
                  -class => 'SYNTAX',
                  source => $src,
                  position_diff => 1,
                  char => $char);
    }
  }

  pos $$src = 0;
  $self->{error}->reset_position ($src, preserve_flag => 1);
}

sub ____check_char ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $xmlver = $self->{ExpandedURI q<xml-version>} || '1.0';
  my $char = chr 0+$opt{ExpandedURI q<_:code>};
  if ($xmlver ne '1.0') {
    $char =~ /\P{InXMLChar11}/ and
      $self->report
               (-type => 'WFC_LEGAL_CHARACTER',
                -class => 'WFC',
                source => $src,
                position_diff => $opt{ExpandedURI q<_:position-diff>},
                char => $char);
  } else {
    $char =~ /\P{InXMLChar10}/ and
      $self->report
               (-type => 'WFC_LEGAL_CHARACTER',
                -class => 'WFC',
                source => $src,
                position_diff => $opt{ExpandedURI q<_:position-diff>},
                char => $char);
  }
}

sub parse_element ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $opt{ExpandedURI q<use-reference>} = 1;

  if ($$src =~ /\G(?=<$XML_NAMESTART{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
    $self->element_start ($src, $p, my $pp = {}, %opt);
    $self->parse_start_tag
             ($src, $pp, %opt);
    my $ename = $pp->{ExpandedURI q<element-type-name>};
    
    if ($pp->{ExpandedURI q<tag-type>} eq 'start') {
      my $end_tag = 0;
      while (pos $$src < length $$src) {
        my $m = substr $$src, pos ($$src), 1;
        if ($m ne '<' and $m ne '&') {
          $$src =~ /\G([^<&]+)/gc;
          my $t = $1;
          if ($t =~ /]]>/) {
            pos ($t) = 0;
            $self->{error}->set_position ($src, moved => 1,
                                          diff => length $t);
            $self->{error}->fork_position ($src => \$t);
            while ($t =~ /]]>/g) {
              $self->report
                       (-type => 'SYNTAX_MSE',
                        -class => 'SYNTAX',
                        source => \$t, position_diff => 1);
            }
          }
          local $pp->{ExpandedURI q<CDATA>} = \$t;
          $self->element_content
                   ($src, $p, $pp, %opt);
        } elsif ($m eq '<') {
          my $n = substr ($$src, 1 + pos $$src, 1);
          if ($n eq '/') {
            if ($$src =~ m#\G</($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})#gc) {
              my $type = $1;
              if ($type eq $ename) {
                $$src =~ /\G$REG_S+/gco;
                $$src =~ /\G>/gc
                  or $self->report
                    (-type => 'SYNTAX_ETAGC_REQUIRED',
                     -class => 'SYNTAX',
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
                     -class => 'SYNTAX',
                     source => $src);
                }
                local $pp->{ExpandedURI q<CDATA>} = \$tag;
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
                  -class => 'SYNTAX',
                  source => $src);
              local $pp->{ExpandedURI q<CDATA>} = \'</';
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
              or local $pp->{ExpandedURI q<CDATA>} = \'<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          } elsif ($n eq '?') {
            $self->parse_processing_instruction
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = \'<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          } else {
            $self->parse_element
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = \'<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          }
        } elsif ($m eq '&') {
          $self->parse_reference_in_content
            ($src, $pp,
             %opt,
             ExpandedURI q<match-or-error> => 1,
             ExpandedURI q<content-parser> => 'parse_content')
              or do {
                local $pp->{ExpandedURI q<CDATA>} = \'&';
                pos ($$src)++;
                $self->element_content ($src, $p, $pp, %opt);
              };
        } else {
          die "$0: parse_element: Buggy implementation: ".
              substr $$src, pos $$src, 10;
        }
      }
    
      unless ($end_tag) {
        $self->report
                 (-type => 'SYNTAX_END_TAG_REQUIRED',
                  -class => 'SYNTAX',
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
                  -class => 'SYNTAX',
                  source => $src,
                  position_diff => -1);
      } else {
        $self->report
                 (-type => 'SYNTAX_START_TAG_REQUIRED',
                  -class => 'SYNTAX',
                  source => $src);
      }
    }
    return 0;
  }
}

sub parse_content ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = $opt{pp} || {};

      while (pos $$src < length $$src) {
        if ($$src =~ /\G([^<&]+)/gc) {
          my $s = $1;
          $self->{error}->set_position ($src, diff => length $s);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->element_content
                   ($src, $p, $pp, %opt);
        } elsif (substr ($$src, pos $$src, 1) eq '<') {
          my $n = substr ($$src, 1 + pos $$src, 1);
          if ($n eq '/') {
            if ($$src =~ m#\G</($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})#gc) {
              my $type = $1;
                $self->report
                  (-type => 'SYNTAX_END_TAG_NOT_ALLOWED',
                   -class => 'SYNTAX',
                   source => $src,
                   position_diff => 2 + length $type);
                my $tag = '</' . $type;
                $$src =~ /\G($REG_S+)/gco and $tag .= $1;
                if ($$src =~ /\G>/gc) {
                  $tag .= '>';
                } else {
                  $self->report
                    (-type => 'SYNTAX_ETAGC_REQUIRED',
                     -class => 'SYNTAX',
                     source => $src);
                }
                pos $tag = 0;
                local $pp->{ExpandedURI q<CDATA>} = \$tag;
                $self->element_content
                  ($src, $p, $pp, %opt);
            } else {
              pos ($$src) += 2;
              $self->report
                 (-type => 'SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_ETAGO_REQUIRED',
                  -class => 'SYNTAX',
                  source => $src);
              local $pp->{ExpandedURI q<CDATA>} = \'</';
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
              or local $pp->{ExpandedURI q<CDATA>} = \'<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          } elsif ($n eq '?') {
            $self->parse_processing_instruction
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = \'<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          } else {
            $self->parse_element
                   ($src, $pp, %opt)
              or local $pp->{ExpandedURI q<CDATA>} = \'<',
                 pos ($$src)++,
                 $self->element_content
                   ($src, $p, $pp, %opt);
          }
        } elsif (substr ($$src, pos $$src, 1) eq '&') {
          $self->parse_reference_in_content
            ($src, $pp,
             %opt,
             ExpandedURI q<match-or-error> => 1,
             ExpandedURI q<content-parser> => 'parse_content')
              or do {
                local $pp->{ExpandedURI q<CDATA>} = \'&';
                pos ($$src)++;
                $self->element_content ($src, $p, $pp, %opt);
              };
        } else {
          die "$0: parse_content: Buggy implementation: ".
              substr $$src, pos $$src, 10;
        }
      }
    return 1;
} # parse_content

sub parse_start_tag ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G</gc) {
    my $element_type;
    if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
      $element_type = $1;
    } elsif ($$src =~ /\G>/gc) {
      pos ($$src)--;
      $self->report
                (-type => 'SYNTAX_EMPTY_START_TAG',
                 -class => 'SYNTAX',
                 source => $src,
                 position_diff => 1);
      return 0;
    } else {
      $self->report
                (-type => 'SYNTAX_ELEMENT_TYPE_NAME_FOLLOWING_STAGO_REQUIRED',
                 -class => 'SYNTAX',
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
                 -class => 'SYNTAX',
                 source => $src);
      }
      $self->end_tag_start ($src, $p, $pp, %opt);
      $self->end_tag_end ($src, $p, $pp, %opt);
    } else {
      $p->{ExpandedURI q<tag-type>} = 'start';
      unless ($$src =~ /\G>/gc) {
        $self->report
                 (-type => 'SYNTAX_STAGC_OR_NESTC_REQUIRED',
                  -class => 'SYNTAX',
                  source => $src);
      }
      $self->start_tag_end ($src, $p, $pp, %opt);
    }
        
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
                (-type => 'SYNTAX_START_TAG_REQUIRED',
                 -class => 'SYNTAX',
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
                 ($src, $p,
                  my $pp = {ExpandedURI q<used-attr-name> => {}},
                  %opt);
  
    my $sep = $opt{ExpandedURI q<s-before-attribute-specifications>};
    my @sep = ($sep);
    while (pos $$src < length $$src) {
      $self->{error}->set_position ($src, moved => 1);
      if ($$src =~ /\G(?=$XML_NAMESTART{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
        unless ($sep) {
          $self->report
            (-type => 'SYNTAX_S_REQUIRED_BETWEEN_ATTR_SPEC',
             -class => 'SYNTAX',
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
             -class => 'SYNTAX',
             source => $src);
        $$src =~ /\G(?:(?!$XML_NAMESTART{$self->{ExpandedURI q<xml-version>}||'1.0'})(?!$REG_S).)+/gcs;
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
  if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})$REG_S*/gc) {
    my $s = $1;
    pos $s = 0;
    $self->{error}->fork_position ($src => \$s);
    my $pp = {ExpandedURI q<attribute-name> => \$s};
    if ($p->{ExpandedURI q<used-attr-name>}->{$s} and
        not $opt{ExpandedURI q<allow-duplicate-attr-name>}) {
      $self->report
        (-type => 'WFC_UNIQUE_ATT_SPEC',
         -class => 'WFC',
         source => $src, position_diff => length $s,
         attribute_name => $s);
    } else {
      $p->{ExpandedURI q<used-attr-name>}->{$s} = 1;
    }
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
         -class => 'SYNTAX',
         source => $src);
    }
    my $end_method = $opt{ExpandedURI q<method-end-attr-spec>} ||
                     'attribute_specification_end';
    $self->$end_method ($src, $p, $pp, %opt);
    return 1;
  } elsif ($opt{ExpandedURI q<match-or-error>}) {
    $self->report
      (-type => 'SYNTAX_ATTR_NAME_REQUIRED',
       -class => 'SYNTAX',
       source => $src);
    return 0;
  }
}

sub parse_attribute_value_specification ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G(["'])/gc) {
    my $pp = {};
    $pp->{ExpandedURI q<literal-delimiter>} = my $litdelim = $1;
    my $start_method = $opt{ExpandedURI q<method-start-attr-value-spec>} ||
                       'attribute_value_specification_start';
    $self->$start_method ($src, $p, $pp, %opt);
    if ($litdelim eq '"') {
      if ($$src =~ /\G([^"]*)/gc) {
        my $s = $1; pos $s = 0;
        $self->{error}->set_position ($src, moved => 1, diff => length $s);
        $self->{error}->fork_position ($src => \$s);
        $self->parse_avdata
                      (\$s, $p, %opt, pp => $pp);
      }
      unless ($$src =~ /\G"/gc) {
        $self->report (-type => 'SYNTAX_ALITC_REQUIRED',
                       -class => 'SYNTAX',
                       source => $src);
      }
    } else { #if ($litdelim eq "'")
      if ($$src =~ /\G([^']*)/gc) {
        my $s = $1; pos $s = 0;
        $self->{error}->set_position ($src, moved => 1, diff => length $s);
        $self->{error}->fork_position ($src => \$s);
        $self->parse_avdata
                      (\$s, $p, %opt, pp => $pp);
      }
      unless ($$src =~ /\G'/gc) {
        $self->report (-type => 'SYNTAX_ALITAC_REQUIRED',
                       -class => 'SYNTAX',
                       source => $src);
      }
    }
    my $end_method = $opt{ExpandedURI q<method-end-attr-value-spec>} ||
                     'attribute_value_specification_end';
    $self->$end_method ($src, $p, $pp, %opt);
    return 1;
  } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
    my $s = $1;
    my $start_method = $opt{ExpandedURI q<method-start-attr-value-spec>} ||
                       'attribute_value_specification_start';
    $self->$start_method ($src, $p, my $pp = {}, %opt);
    $self->report (-type => 'SYNTAX_ATTRIBUTE_VALUE',
                   -class => 'SYNTAX',
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
                   -class => 'SYNTAX',
                   source => $src);
    }
    return 0;
  }
}

sub parse_avdata ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = $opt{pp} || {};
  my $content_method = $opt{ExpandedURI q<method-content-attr-value-spec>} ||
                       'attribute_value_specification_content';
      while (pos $$src < length $$src) {
        if ($$src =~ /\G([^&<]+)/gc) {
          my $s = $1;
          $s =~ s/[\x09\x0A\x0D]/\x20/g
            if $opt{ExpandedURI q<normalize-attr-val>};
          pos $s = 0;
          $self->{error}->set_position ($src, moved => 1, diff => length $s);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
        } elsif ($$src =~ /\G(?=&)/gc) {
          if (not $opt{ExpandedURI q<use-reference>} or
              not $self->parse_reference_in_attribute_value_literal
                   ($src, $p,
                    %opt, pp => $pp,
                    ExpandedURI q<match-or-error> => 1,
                    ExpandedURI q<error-avdata-lt>
                      => 'WFC_NO_LESS_THAN_IN_ATTR_VAL',
                    ExpandedURI q<error-class-avdata-lt> => 'WFC')) {
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
          $self->{error}->set_position ($src, moved => 1, diff => 1);
          $self->{error}->fork_position ($src => \$s);
          $self->report
                   (-type => $opt{ExpandedURI q<error-avdata-lt>} ||
                             'SYNTAX_NO_LESS_THAN_IN_ATTR_VAL',
                    -class => $opt{ExpandedURI q<error-class-avdata-lt>} ||
                              'SYNTAX',
                    source => $src,
                    position_diff => 1);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
        } else { # Dummy report
          my $s = '';
          pos $s = 0;
          $self->{error}->set_position ($src, moved => 1);
          $self->{error}->fork_position ($src => \$s);
          local $pp->{ExpandedURI q<CDATA>} = \$s;
          $self->$content_method
                   ($src, $p, $pp, %opt);
          last;
        }
      }
  return 1;
}

sub parse_reference_in_attribute_value_literal ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = $opt{pp};
  if ($$src =~ /\G&/gc) {
    if ($$src =~ /\G\#/gc) {
      if ($$src =~ /\Gx/gc) {
        if ($$src =~ /\G([0-9A-Fa-f]+)/gc) {
          my $code = hex $1;
          unless ($opt{ExpandedURI q<allow-hex-character-reference>}) {
            $self->report
              (-type => 'SYNTAX_HEX_CHAR_REF',
               -class => 'SYNTAX',
               source => $src,
               position_diff => 3 + length $1);
          }
          $self->____check_char
                    ($src, $pp, %opt,
                     ExpandedURI q<_:code> => $code,
                     ExpandedURI q<_:position-diff> => 3 + length $1);
          $self->hex_character_reference_in_attribute_value_literal_start
               ($src,
                $pp,
                {ExpandedURI q<character-number> => $code},
                %opt);
        } else {
          $self->report
            (-type => 'SYNTAX_HEXDIGIT_REQUIRED',
             -class => 'SYNTAX',
             source => $src);
          pos ($$src) -= 3;
          return 0;
        }
      } elsif ($$src =~ /\G([0-9]+)/gc) {
        unless ($opt{ExpandedURI q<allow-numeric-character-reference>}) {
          $self->report
            (-type => 'SYNTAX_NUMERIC_CHAR_REF',
             -class => 'SYNTAX',
             source => $src,
             position_diff => 2 + length $1);
        }
        $self->____check_char
                    ($src, $pp, %opt,
                     ExpandedURI q<_:code> => 0 + $1,
                     ExpandedURI q<_:position-diff> => 2 + length $1);
        $self->numeric_character_reference_in_attribute_value_literal_start
               ($src,
                $pp,
                {ExpandedURI q<character-number> => 0 + $1},
                %opt);
      } elsif ($$src =~ /\GX/gc) {
        $self->report
               (-type => 'SYNTAX_HCRO_CASE',
                -class => 'SYNTAX',
                source => $src,
                position_diff => 1);
        pos ($$src) -= 3;
        return 0;
      } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
        my $name = $1;
        $self->report
               (-type => 'SYNTAX_NAMED_CHARACTER_REFERENCE',
                -class => 'SYNTAX',
                source => $src,
                function_name => $name,
                position_diff => length $name);
        pos ($$src) -= 2 + length $name;
        return 0;
      } else {
        $self->report
               (-type => 'SYNTAX_X_OR_DIGIT_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
        pos ($$src) -= 2;
        return 0;
      }
    } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
      my $s = $1; pos $s = 0;
      unless ($opt{ExpandedURI q<allow-general-entity-reference>}) {
        $self->report
               (-type => 'SYNTAX_GENERAL_ENTREF',
                -class => 'SYNTAX',
                source => $src,
                position_diff => 1 + length $s);
      }
      $self->{error}->set_position ($src, moved => 1, diff => length $s);
      $self->{error}->fork_position ($src => \$s);
      my $ppp = {ExpandedURI q<entity-name> => \$s};
      if ($self->{ExpandedURI q<_:opened-general-entity>}->{$s}) {
        $self->report
          (-type => 'WFC_NO_RECURSION',
           -class => 'WFC',
           source => $src,
           position_diff => length $s,
           entity_name => $s);
        $ppp->{ExpandedURI q<entity-opened>} = 1;
      }
      $opt{ExpandedURI q<source>} = [$src];
      $self->general_entity_reference_in_attribute_value_literal_start
               ($src, $pp, $ppp, %opt);
      EXPAND: {
        last EXPAND if $ppp->{ExpandedURI q<entity-opened>};
        if (overload::StrVal ($src) ne
            overload::StrVal ($opt{ExpandedURI q<source>}->[-1])) {
          if ($self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-external-entity>)) {
            $self->report
               (-type => 'WFC_NO_EXTERNAL_ENTITY_REFERENCES',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
            last EXPAND;
          } elsif ($self->{ExpandedURI q<is-standalone>} and
                   $self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-declared-externally>)) {
            $self->report
               (-type => 'WFC_ENTITY_DECLARED__INTERNAL',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
          } elsif ($self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-unparsed-entity>)) {
            ## This code will never be executed, since all unparsed entities
            ## are external entities.
            $self->report
               (-type => 'WFC_PARSED_ENTITY',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
            shift @{$opt{ExpandedURI q<source>}};
            last EXPAND;
          }
          local $self->{ExpandedURI q<_:opened-general-entity>}->{$s} = 1;
          $self->parse_avdata
               ($opt{ExpandedURI q<source>}->[-1], $pp, %opt, pp => $ppp);
          $pp->{ExpandedURI q<reference-expanded>} = 1;
        } elsif ($self->{ExpandedURI q<is-standalone>}) {
          $self->report
               (-type => 'WFC_ENTITY_DECLARED',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
        }
      }
      $self->general_entity_reference_in_attribute_value_literal_end
               ($src, $pp, $ppp, %opt);
    } else {
      $self->report
               (-type => 'SYNTAX_HASH_OR_NAME_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
    
    $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_REFERENCE_AMP_REQUIRED',
                -class => 'SYNTAX',
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
          $self->____check_char
                    ($src, $p, %opt,
                     ExpandedURI q<_:code> => hex $1,
                     ExpandedURI q<_:position-diff> => 3 + length $1);
          $self->hex_character_reference_in_content_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => hex $1},
                %opt);
        } else {
          $self->report
            (-type => 'SYNTAX_HEXDIGIT_REQUIRED',
             -class => 'SYNTAX',
             source => $src);
          pos ($$src) -= 3;
          return 0;
        }
      } elsif ($$src =~ /\G([0-9]+)/gc) {
        $self->____check_char
                    ($src, $p, %opt,
                     ExpandedURI q<_:code> => 0 + $1,
                     ExpandedURI q<_:position-diff> => 2 + length $1);
        $self->numeric_character_reference_in_content_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => 0 + $1},
                %opt);
      } elsif ($$src =~ /\GX/gc) {
        $self->report
               (-type => 'SYNTAX_HCRO_CASE',
                -class => 'SYNTAX',
                source => $src,
                position_diff => 1);
        pos ($$src) -= 3;
        return 0;
      } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
        my $name = $1;
        $self->report
               (-type => 'SYNTAX_NAMED_CHARACTER_REFERENCE',
                -class => 'SYNTAX',
                source => $src,
                function_name => $name,
                position_diff => length $name);
        pos ($$src) -= 2 + length $name;
        return 0;
      } else {
        $self->report
               (-type => 'SYNTAX_X_OR_DIGIT_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
        pos ($$src) -= 2;
        return 0;
      }
    } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
      my $s = $1; pos $s = 0;
      $self->{error}->set_position ($src, moved => 1, diff => length $s);
      $self->{error}->fork_position ($src => \$s);
      my $pp = {ExpandedURI q<entity-name> => \$s};
      if ($self->{ExpandedURI q<_:opened-general-entity>}->{$s}) {
        $self->report
          (-type => 'WFC_NO_RECURSION',
           -class => 'WFC',
           source => $src,
           position_diff => length $s,
           entity_name => $s);
        $pp->{ExpandedURI q<entity-opened>} = 1;
      }
      $opt{ExpandedURI q<source>} = [];
      $self->general_entity_reference_in_content_start
               ($src, $p, $pp, %opt);
      EXPAND: {
        last EXPAND if $pp->{ExpandedURI q<entity-opened>};
        if (@{$opt{ExpandedURI q<source>}}) {
          if ($self->{ExpandedURI q<is-standalone>} and
                   $self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-declared-externally>)) {
            $self->report
               (-type => 'WFC_ENTITY_DECLARED__INTERNAL',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
          } elsif ($self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-unparsed-entity>)) {
            $self->report
               (-type => 'WFC_PARSED_ENTITY',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
            shift @{$opt{ExpandedURI q<source>}};
            last EXPAND;
          }
          local $self->{ExpandedURI q<_:opened-general-entity>}->{$s} = 1;
          my $parser = $opt{ExpandedURI q<content-parser>};
          $self->$parser
               ($opt{ExpandedURI q<source>}->[-1], $p, %opt, pp => $pp);
          $pp->{ExpandedURI q<reference-expanded>} = 1;
        } elsif ($self->{ExpandedURI q<is-standalone>}) {
          $self->report
               (-type => 'WFC_ENTITY_DECLARED',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
        }
      }
      $self->general_entity_reference_in_content_end
               ($src, $p, $pp, %opt);
    } else {
      $self->report
               (-type => 'SYNTAX_HASH_OR_NAME_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
    
    $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_REFERENCE_AMP_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
    }
    return 0;
  }
}

sub parse_reference_in_rpdata ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G%/gc) {
    if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
      my $s = $1; pos $s = 0;
      $self->{error}->set_position ($src, moved => 1, diff => length $s);
      $self->{error}->fork_position ($src => \$s);
      my $pp = {ExpandedURI q<entity-name> => \$s};
      if ($self->{ExpandedURI q<_:opened-parameter-entity>}->{$s}) {
        $self->report
          (-type => 'WFC_NO_RECURSION',
           -class => 'WFC',
           source => $src,
           position_diff => length $s,
           entity_name => $s);
        $pp->{ExpandedURI q<entity-opened>} = 1;
      }
      $opt{ExpandedURI q<source>} = [$src];
      $self->parameter_entity_reference_in_rpdata_start
               ($src, $p, $pp, %opt);
      EXPAND: {
        last EXPAND if $pp->{ExpandedURI q<entity-opened>};
        if (overload::StrVal ($src) ne
            overload::StrVal ($opt{ExpandedURI q<source>}->[-1])) {
          if ($self->{ExpandedURI q<is-standalone>} and
                   $self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-declared-externally>)) {
            $self->report
               (-type => 'WFC_ENTITY_DECLARED__INTERNAL',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
          } elsif ($self->{error}->get_flag
               ($opt{ExpandedURI q<source>}->[-1],
                ExpandedURI q<is-unparsed-entity>)) {
            $self->report
               (-type => 'WFC_PARSED_ENTITY',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
            shift @{$opt{ExpandedURI q<source>}};
            last EXPAND;
          }
          local $self->{ExpandedURI q<_:opened-parameter-entity>}->{$s} = 1;
          local $pp->{ExpandedURI q<CDATA>} = $opt{ExpandedURI q<source>}->[-1];
          #$self->rpdata_content
          #     ($opt{ExpandedURI q<source>}->[-1], $p, $pp, %opt);
          $pp->{ExpandedURI q<reference-expanded>} = 1;
        } elsif ($self->{ExpandedURI q<is-standalone>}) {
          $self->report
               (-type => 'WFC_ENTITY_DECLARED',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
        }
      }
      $self->parameter_entity_reference_in_rpdata_end
               ($src, $p, $pp, %opt);
      
      $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
      return 1;
    } else {
      $self->report
               (-type => 'SYNTAX_PARAENT_NAME_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
  } elsif ($$src =~ /\G&/gc) {
    if ($$src =~ /\G\#/gc) {
      if ($$src =~ /\Gx/gc) {
        if ($$src =~ /\G([0-9A-Fa-f]+)/gc) {
          $self->____check_char
                    ($src, $p, %opt,
                     ExpandedURI q<_:code> => hex $1,
                     ExpandedURI q<_:position-diff> => 3 + length $1);
          $self->hex_character_reference_in_rpdata_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => hex $1},
                %opt);
        } else {
          $self->report
            (-type => 'SYNTAX_HEXDIGIT_REQUIRED',
             -class => 'SYNTAX',
             source => $src);
          pos ($$src) -= 3;
          return 0;
        }
      } elsif ($$src =~ /\G([0-9]+)/gc) {
        $self->____check_char
                    ($src, $p, %opt,
                     ExpandedURI q<_:code> => 0 + $1,
                     ExpandedURI q<_:position-diff> => 2 + length $1);
        $self->numeric_character_reference_in_rpdata_start
               ($src,
                $p,
                {ExpandedURI q<character-number> => 0 + $1},
                %opt);
      } elsif ($$src =~ /\GX/gc) {
        $self->report
               (-type => 'SYNTAX_HCRO_CASE',
                -class => 'SYNTAX',
                source => $src,
                position_diff => 1);
        pos ($$src) -= 3;
        return 0;
      } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
        my $name = $1;
        $self->report
               (-type => 'SYNTAX_NAMED_CHARACTER_REFERENCE',
                -class => 'SYNTAX',
                source => $src,
                function_name => $name,
                position_diff => length $name);
        pos ($$src) -= 2 + length $name;
        return 0;
      } else {
        $self->report
               (-type => 'SYNTAX_X_OR_DIGIT_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
        pos ($$src) -= 2;
        return 0;
      }
    } elsif ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
      my $s = $1; pos $s = 0;
      $self->{error}->set_position ($src, moved => 1, diff => length $s);
      $self->{error}->fork_position ($src => \$s);
      my $pp = {ExpandedURI q<entity-name> => \$s};
      $self->general_entity_reference_in_rpdata_start
               ($src, $p, $pp, %opt);
      $self->general_entity_reference_in_rpdata_end
               ($src, $p, $pp, %opt);
    } else {
      $self->report
               (-type => 'SYNTAX_HASH_OR_NAME_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
      pos ($$src) -= 1;
      return 0;
    }
    
    $$src =~ /\G;/gc or $self->report
               (-type => 'SYNTAX_REFC_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_REFERENCE_AMP_REQUIRED',
                -class => 'SYNTAX',
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
           -class => 'SYNTAX',
           source => $src);
    }
    $self->parse_comment_declaration ($src, $p, %opt);
  } elsif ($$src =~ /\G<!($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
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
           -class => 'SYNTAX',
           source => $src,
           keyword => $keyword);
      }
      $self->$method
             ($src, $p, %opt);
    } else {
      $self->report
             (-type => 'SYNTAX_UNKNOWN_MARKUP_DECLARATION',
              -class => 'SYNTAX',
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
           -class => 'SYNTAX',
           source => $src);
    }
    $self->parse_marked_section
             ($src, $p, %opt);
  } elsif ($$src =~ /\G<!>/gc) {
    unless ($opt{ExpandedURI q<allow-declaration>}->{comment}) {
      $self->report
          (-type => 'SYNTAX_COMMENT_DECLARATION_NOT_ALLOWED',
           -class => 'SYNTAX',
           source => $src);
    }
    $self->report
             (-type => 'SYNTAX_EMPTY_COMMENT_DECLARATION',
              -class => 'SYNTAX',
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
              -class => 'SYNTAX',
              source => $src);
    } else {
      $self->report
             (-type => 'SYNTAX_MARKUP_DECLARATION_REQUIRED',
              -class => 'SYNTAX',
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
    my $has_internal_subset;
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
        next PARAMS;
      } elsif ($doctype->{type} eq 'rniKeyword') {
        if (${$doctype->{value}} eq 'IMPLIED') {
          $self->report
              (-type => 'SYNTAX_DOCTYPE_IMPLIED',
               -class => 'SYNTAX',
               source => $doctype->{value});
        } else {
          $self->report
              (-type => 'SYNTAX_DOCTYPE_RNI_KEYWORD',
               -class => 'SYNTAX',
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
      next PARAMS unless $dso;
      if ($dso->{type} eq 'dso') {
        $has_internal_subset = 1;
        $self->doctype_internal_subset_start ($src, $p, $pp, %opt,
                                              ppp => my $ppp = {});
        $self->parse_doctype_subset
              ($src, $pp,
               %opt, pp => $ppp,
               ExpandedURI q<subset-type> => 'internal',
               ExpandedURI q<end-with-dsc> => 1,
               ExpandedURI q<allow-declaration>
                 => {qw/ENTITY 1 ELEMENT 1 ATTLIST 1 NOTATION 1
                        comment 1 section 0/});
        $self->doctype_internal_subset_end ($src, $p, $pp, %opt, ppp => $ppp);
      }
    } continue {
      unless ($has_internal_subset) {
        local $opt{ExpandedURI q<doctype-internal-subset-null>} = 1;
        $self->doctype_internal_subset_start ($src, $p, $pp, %opt,
                                              ppp => my $ppp = {});
        $self->doctype_internal_subset_end ($src, $p, $pp, %opt, ppp => $ppp);
      }
      ## External subset
      if ($pp->{ExpandedURI q<has-external-id>}) {
        $self->doctype_external_subset_start ($src, $p, $pp, %opt,
                                              ppp => my $ppp = {});
        if ($pp->{ExpandedURI q<external-subset-source>}) {
          local $opt{ExpandedURI q<source>}
            = [$pp->{ExpandedURI q<external-subset-source>}];
          $self->parse_doctype_subset
              ($opt{ExpandedURI q<source>}->[-1],
               $pp, %opt, pp => $ppp,
               ExpandedURI q<subset-type> => 'external',
               ExpandedURI q<allow-declaration>
                 => {qw/ENTITY 1 ELEMENT 1 ATTLIST 1 NOTATION 1
                        comment 1 section 1/});
        }
        $self->doctype_external_subset_end ($src, $p, $pp, %opt, ppp => $ppp);
      }

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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
    }
    $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    } # PARAMS
    
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'SYNTAX',
               source => $src);
    }
    $self->doctype_declaration_end
              ($src, $p, $pp, %opt);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
              (-type => 'SYNTAX_DOCTYPE_DECLARATION_REQUIRED',
               -class => 'SYNTAX',
               source => $src);
    }
    return 0;
  }
}

sub parse_entity_declaration ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<!ENTITY/gc) {
    $self->entity_declaration_start
              ($src, $p,
               my $pp = {ExpandedURI q<infoset:baseURI>
                           => $self->{error}
                                   ->get_flag ($src, ExpandedURI q<base-uri>)},
               %opt);
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
               -class => 'SYNTAX',
               source => $entname->{value});
        } else {
          $self->report
              (-type => 'SYNTAX_ENTITY_RNI_KEYWORD',
               -class => 'SYNTAX',
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
            $pp->{ExpandedURI q<entity-value>} = $enttext->{value};
            $self->entity_value_content
              ($src, $p, $pp, %opt);
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
                     -class => 'SYNTAX',
                     source => $kwd->{value},
                     keyword => ${$kwd->{value}});
                  $pp->{ExpandedURI q<entity-data-type>} = ${$kwd->{value}};
                } elsif (${$kwd->{value}} eq 'SUBDOC') {
                  $self->report
                    (-type => 'SYNTAX_ENTITY_DATA_TYPE_SGML_KEYWORD',
                     -class => 'SYNTAX',
                     source => $kwd->{value},
                     keyword => ${$kwd->{value}});
                  $pp->{ExpandedURI q<entity-data-type>} = ${$kwd->{value}};
                  last ENTTEXT;
                } else {
                  $self->report
                    (-type => 'SYNTAX_ENTITY_DATA_TYPE_UNKNOWN_KEYWORD',
                     -class => 'SYNTAX',
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
                 -class => 'SYNTAX',
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
              if ($enttext2) {
                $pp->{ExpandedURI q<entity-value>} = $enttext2->{value};
                $pp->{ExpandedURI q<entity-value-keyword>} = $enttext->{value};
                $self->entity_value_content
                  ($src, $p, $pp, %opt);
              }
            } else {
              $self->report
                (-type => 'SYNTAX_ENTITY_TEXT_KEYWORD',
                 -class => 'SYNTAX',
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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
    }
    $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'SYNTAX',
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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
    }
    $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'SYNTAX',
               source => $src);
    }
    $self->notation_declaration_end
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
               -class => 'SYNTAX',
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
          # exception (SGML) not implemented
        } elsif ($param->{type} eq 'Name') {
          shift @{$pp->{ExpandedURI q<param>}};
          if ({qw/ANY 1 EMPTY 1/}->{${$param->{value}}}) {
            $pp->{ExpandedURI q<element-content-keyword>} = $param->{value};
          } elsif ({qw/CDATA 1 RCDATA 1/}->{${$param->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ELEMENT_SGML_CONTENT_KEYWORD',
               -class => 'SYNTAX',
               source => $param->{value},
               keyword => ${$param->{value}});
            $pp->{ExpandedURI q<element-content-keyword>} = $param->{value};
          } elsif (${$param->{value}} eq 'o') {
            $self->report
              (-type => 'SYNTAX_ELEMENT_TAG_MIN',
               -class => 'SYNTAX',
               source => $param->{value});
            redo MODEL;
          } else {
            $self->report
              (-type => 'SYNTAX_ELEMENT_UNKNOWN_CONTENT_KEYWORD',
               -class => 'SYNTAX',
               source => $param->{value},
               keyword => ${$param->{value}});
          }
        } elsif ($param->{type} eq 'minus') {
          shift @{$pp->{ExpandedURI q<param>}};
          $self->report
            (-type => 'SYNTAX_ELEMENT_TAG_MIN',
             -class => 'SYNTAX',
             source => $param->{value});
          redo MODEL;
        } elsif ($param->{type} eq 'number') {
          shift @{$pp->{ExpandedURI q<param>}};
          $self->report
            (-type => 'SYNTAX_ELEMENT_RANK_SUFFIX',
             -class => 'SYNTAX',
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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
    }
    $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt)}
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'SYNTAX',
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
          next PARAMS;
        } elsif ($entname->{type} eq 'Name') {
          $pp->{ExpandedURI q<element-type-name>} = $entname->{value};
        } elsif ($entname->{type} eq 'rniKeyword') {
          if ({qw/ALL 1 IMPLICIT 1 NOTATION 1/}->{${$entname->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ATTLIST_SGML_KEYWORD',
               -class => 'SYNTAX',
               source => $entname->{value},
               keyword => ${$entname->{value}});
            last NAME unless ${$entname->{value}} eq 'NOTATION';
          } else {
            $self->report
              (-type => 'SYNTAX_ATTLIST_UNKNOWN_KEYWORD',
               -class => 'SYNTAX',
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
               -class => 'SYNTAX',
               source => $param->{value},
               keyword => ${$param->{value}});
          } else {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_TYPE_UNKNOWN_KEYWORD',
               -class => 'SYNTAX',
               source => $param->{value},
               keyword => ${$param->{value}});
          }
        } elsif ($param->{type} eq 'grpo') {
          $q->{ExpandedURI q<attribute-type>} = \'group';
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
                   -class => 'SYNTAX',
                   source => $param->{value});
                $q->{ExpandedURI q<attribute-default-value>} = $param->{value};
              } else {
                die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
              }
            }
          } elsif ({qw/CURRENT 1 CONREF 1/}->{${$param->{value}}}) {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_DEFAULT_SGML_KEYWORD',
               -class => 'SYNTAX',
               source => $param->{value},
               keyword => ${$param->{value}});
          } else {
            $self->report
              (-type => 'SYNTAX_ATTRDEF_DEFAULT_UNKNOWN_KEYWORD',
               -class => 'SYNTAX',
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
             -class => 'SYNTAX',
             source => $param->{value});
          $q->{ExpandedURI q<attribute-default>} = \'specific';
          $q->{ExpandedURI q<attribute-default-value>} = $param->{value};
        } else {
          die "$0: ".__PACKAGE__.": $param->{type}: Buggy";
        }
        $self->attribute_definition ($src, $pp, $q, %opt);
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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
    }
    $self->markup_declaration_parameters_end
              ($src, $p, $pp, %opt);
    }
    unless ($$src =~ /\G>/gc) {
      $self->report
              (-type => 'SYNTAX_MDC_REQUIRED',
               -class => 'SYNTAX',
               source => $src);
    }
    $self->attlist_declaration_end
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
    $opt{ExpandedURI q<match-or-error>} = 1;
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
             -class => 'SYNTAX',
             source => $param->{value});
        }
        $self->parse_model_group
          ($opt{ExpandedURI q<source>}->[-1], $pp, %opt);
        $ppp->{ExpandedURI q<item-type>} = 'group';
      } elsif ($param->{type} eq 'rniKeyword') {
        shift @{$p->{ExpandedURI q<param>}};
        if (${$param->{value}} eq 'PCDATA') {
          $ppp->{ExpandedURI q<item-type>} = 'PCDATA';
          $has_pcdata = 1;
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_PCDATA_POSITION',
             -class => 'SYNTAX',
             source => $param->{value})
            if $i != 0;
        } else {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_UNKNOWN_KEYWORD',
             -class => 'SYNTAX',
             source => $param->{value},
             keyword => ${$param->{value}});
        }
      } elsif ($param->{type} eq 'dtgo') {
        shift @{$pp->{ExpandedURI q<param>}};
        $self->report
          (-type => 'SYNTAX_DATA_TAG_GROUP',
           -class => 'SYNTAX',
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
             -class => 'SYNTAX',
             source => $connector->{value},
             old => $connect,
             new => ${$connector->{value}});
        } elsif ($has_pcdata and $connect ne '|') {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_MIXED_CONNECTOR',
             -class => 'SYNTAX',
             source => $connector->{value},
             connector => ${$connector->{value}});
        }
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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $$src =~ /\G\)/gc
        or $self->report
              (-type => 'SYNTAX_MODEL_GROUP_GRPC_REQUIRED',
               -class => 'SYNTAX',
               source => $src);
      if ($$src =~ /\G([?+*])/gc) {
        my $del = $1;
        $self->{error}->set_position ($src, moved => 1,
                                      diff => length $del);
        $self->{error}->fork_position ($src => \$del);
        $pp->{ExpandedURI q<occurrence>} = \$del;
        if ($has_pcdata and $del ne '*') {
          $self->report
            (-type => 'SYNTAX_MODEL_GROUP_'.($i > 1 ? 'MIXED' : 'PCDATA')
                     .'_OCCUR',
             -class => 'SYNTAX',
             source => $src,
             position_diff => 1);
        }
      } elsif ($has_pcdata and $i > 1) {
        $self->report
          (-type => 'SYNTAX_MODEL_GROUP_PCDATA_OCCUR',
           -class => 'SYNTAX',
           source => $src,
           position_diff => 1);
      }
    }
    $pp->{ExpandedURI q<connector>} = \$connect;
    $p->{ExpandedURI q<element-content-keyword>} = \'#PCDATA'
      if $has_pcdata;
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
               -class => 'SYNTAX',
               source => ($pp->{ExpandedURI q<param>}->[0] ?
                            $pp->{ExpandedURI q<param>}->[0]->{value} :
                            $opt{ExpandedURI q<source>}->[-1]),
               param => $pp->{ExpandedURI q<param>},
               sources => $opt{ExpandedURI q<source>});
      }
      $$src =~ /\G\)/gc
        or $self->report
              (-type => 'SYNTAX_ATTRDEF_TYPE_GROUP_GRPC_REQUIRED',
               -class => 'SYNTAX',
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
                -class => 'SYNTAX',
                source => $src);
    }
    return 0;
  }}

  if ($allow->{ps}) {
    my $has_ps = 0;
    my $pos = pos $$src;
    EATPS: while (1) {
      if ($$src =~ /\G($REG_S+)/gco) {
        my $s = $1;
        $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> =>
                          {type => 'ps', value => \$s}}, %opt);
        if ($opt{ExpandedURI q<end-with-mdc>} and
            $$src =~ /\G>/gc) {
          pos ($$src)--;
          return 1; ## Note: <allow-ps> don't work in this case
        }
        $has_ps = 1;
      } elsif ($$src =~ /\G%/gc) {
        if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
          $self->report
                  (-type => $opt{ExpandedURI q<error-ps>} ||
                            'SYNTAX_MARKUP_DECLARATION_PS',
                   -class => 'SYNTAX',
                   position_diff => $+[0] - $-[0] + 1,
                   source => $src)
                if not $opt{ExpandedURI q<allow-ps>};
          $self->report
                  (-type => $opt{ExpandedURI q<error-param-entref>} ||
                            'SYNTAX_PARAENT_REF_NOT_ALLOWED',
                   -class => 'SYNTAX',
                   position_diff => $+[0] - $-[0] + 1,
                   source => $src)
                if not $opt{ExpandedURI q<allow-param-entref>};
          
          my $s = $1; pos $s = 0;
          $self->{error}->set_position ($src, moved => 1, diff => length $s);
          $self->{error}->fork_position ($src => \$s);
          my $pp = {ExpandedURI q<entity-name> => \$s,
                    ExpandedURI q<param> => []};
          if ($self->{ExpandedURI q<_:opened-parameter-entity>}->{$s}) {
            $self->report
                     (-type => 'WFC_NO_RECURSION',
                      -class => 'WFC',
                      source => $src,
                      position_diff => length $s,
                      entity_name => $s);
            $pp->{ExpandedURI q<entity-opened>} = 1;
          }
          $self->parameter_entity_reference_in_parameter_start
            ($src, $p, $pp, %opt);

          $$src =~ /\G;/gc or
            $self->report
              (-type => 'SYNTAX_REFC_REQUIRED',
               -class => 'SYNTAX',
               source => $src,
               entity_name => $pp->{ExpandedURI q<entity-name>});

          EXPAND: {
            last EXPAND if $pp->{ExpandedURI q<entity-opened>};
            ## Entity replacement text prepared (in param...start method above)
            ## NOTE: Removing $src from @{$opt{<source>}} in param...start
            ##       is not expected.  Only either push'ing new text or do
            ##       no operation is allowed in param...start method.
            if (overload::StrVal ($src) ne
                overload::StrVal ($opt{ExpandedURI q<source>}->[-1])) {
              if ($self->{ExpandedURI q<is-standalone>} and
                  $self->{error}->get_flag
                  ($opt{ExpandedURI q<source>}->[-1],
                   ExpandedURI q<is-declared-externally>)) {
                $self->report
                         (-type => 'WFC_ENTITY_DECLARED__INTERNAL',
                          -class => 'WFC',
                          source => $src,
                          position_diff => 1 + length $s,
                          entity_name => $s);
              } elsif ($self->{error}->get_flag
                         ($opt{ExpandedURI q<source>}->[-1],
                          ExpandedURI q<is-unparsed-entity>)) {
                $self->report
                         (-type => 'WFC_PARSED_ENTITY',
                          -class => 'WFC',
                          source => $src,
                          position_diff => 1 + length $s,
                          entity_name => $s);
                shift @{$opt{ExpandedURI q<source>}};
                last EXPAND;
              }

              local $self->{ExpandedURI q<_:opened-parameter-entity>}->{$s} = 1;
              local $Error::Depth = $Error::Depth + 1;
              $self->parse_markup_declaration_parameter
                  ($src, $p,
                   %opt,
                   ExpandedURI q<ps-required> => 0,
                   ExpandedURI q<end-with-mdc> => 0);
              $pp->{ExpandedURI q<reference-expanded>} = 1;
              
              ## Requested Parameter Found
              if (@$param) {
                $self->parameter_entity_reference_in_parameter_end
                  ($src, $p, $pp, %opt);
                return 1;
              }
            } elsif ($self->{ExpandedURI q<is-standalone>}) {
              $self->report
               (-type => 'WFC_ENTITY_DECLARED',
                -class => 'WFC',
                source => $src,
                position_diff => 1 + length $s,
                entity_name => $s);
            }
          }

          $self->parameter_entity_reference_in_parameter_end
               ($src, $p, $pp, %opt);
          $has_ps = 1;
        } else { # pero not followed by Name
          pos ($$src)--;
          last EATPS;
        }
      } elsif ($$src =~ /\G(?=--)/gc) {
        $self->report
          (-type => 'SYNTAX_PS_COMMENT',
           -class => 'SYNTAX',
           source => $src);
        $self->parse_comment ($src, $p, %opt);
      ## Reach to end of source text
      } elsif (defined pos $$src and length $$src == pos $$src) {
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
               -class => 'SYNTAX',
               source => $src);
      }
    } elsif (not $opt{ExpandedURI q<allow-ps>}) {
      $self->report
              (-type => $opt{ExpandedURI q<error-ps>}
                        || 'SYNTAX_MARKUP_DECLARATION_PS',
               -class => 'SYNTAX',
               position_diff => pos ($$src) - $pos,
               source => $src);
    }
  }
  if ($allow->{Name} and
      $$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
    my $name = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $name);
    $self->{error}->fork_position ($src => \$name);
    push @$param, {type => 'Name', value => \$name};
    $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> => $param->[-1]}, %opt);
    return 1;
  } elsif ($allow->{rniKeyword} and
           $$src =~ /\G\#($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
    ## ISSUE: Should we cause error if RNI not followed by Name occurs?
    my $name = $1;
    $self->{error}->set_position ($src, moved => 1,
                                  diff => length $name);
    $self->{error}->fork_position ($src => \$name);
    push @$param, {type => 'rniKeyword', value => \$name};
    $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> => $param->[-1]}, %opt);
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
                -class => 'SYNTAX',
                source => $src);
    } else {
      $$src =~ /\G'/gc or
        $self->report
               (-type => 'SYNTAX_PLITAC_REQUIRED',
                -class => 'SYNTAX',
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
                -class => 'SYNTAX',
                source => $src);
    } else {
      ($pubid) = ($$src =~ /\G([^']*)/gc);
      $$src =~ /\G'/gc or
        $self->report
               (-type => 'SYNTAX_PUBLIT_MLITAC_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
    }
    $self->{error}->reset_position
               (\$pubid,
                line => $pos->[0],
                char => $pos->[1],
                preserve_flag => 1);
    if ($pubid =~ m{([^-'()+,./:=?;!*\#\@\$_%A-Za-z0-9\x0A\x0D\x20])}g) {
      my $s = $1;
      $self->report
               (-type => 'SYNTAX_PUBID_LITERAL_INVALID_CHAR',
                -class => 'SYNTAX',
                source => \$pubid,
                position_diff => 1,
                char => $s);
      pos ($pubid) = 0;
      $self->{error}->reset_position
               (\$pubid,
                line => $pos->[0],
                char => $pos->[1],
                preserve_flag => 1);
    }
    push @$param, {type => 'publit', value => \$pubid, delimiter => $lit};
    $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> => $param->[-1]}, %opt);
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
                -class => 'SYNTAX',
                source => $src);
    } else {
      ($sysid) = ($$src =~ /\G([^']*)/gc);
      $$src =~ /\G'/gc or
        $self->report
               (-type => 'SYNTAX_SLITAC_REQUIRED',
                -class => 'SYNTAX',
                source => $src);
    }
    pos ($sysid) = 0;
    $self->{error}->set_position
               (\$sysid,
                line => $pos->[0],
                char => $pos->[1]);
    push @$param, {type => 'syslit', value => \$sysid, delimiter => $lit};
    $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> => $param->[-1]}, %opt);
  } elsif ($allow->{attrValLit} and
           $$src =~ /\G(?=["'])/gc) {
    push @$param, {type => 'attrValLit'};
  } elsif ($allow->{peroName} and
           $$src =~ /\G%($REG_S+)/gco) {
    $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> => {type => 'pero'}}, %opt);
    my $s = $1;
    $self->markup_declaration_parameter
              ($src, $p,
               {ExpandedURI q<parameter> => {type => 'ps', value => \$s}},
               %opt);
    if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
      my $name = $1;
      $self->{error}->set_position ($src, moved => 1,
                                    diff => length $name);
      $self->{error}->fork_position ($src => \$name);
      push @$param, {type => 'peroName', value => \$name};
      $self->markup_declaration_parameter
              ($src, $p, {ExpandedURI q<parameter> => $param->[-1]}, %opt);
      return 1;
    } else {
      $self->report
         (-type => 'SYNTAX_ENTITY_PARAM_NAME_REQUIRED',
          -class => 'SYNTAX',
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
         -class => 'SYNTAX',
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
                -class => 'SYNTAX',
                source => $src);
    }
    return 0;
  }
}

sub parse_rpdata ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  my $pp = $opt{pp} || {};
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
             -class => 'SYNTAX',
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
    my $pp = {ExpandedURI q<original-public-id> => $pubid->{value}};
    $pubid = ${$pubid->{value}};
    $pubid =~ s/$REG_S+/\x20/go;
    $pubid =~ s/^\x20//; $pubid =~ s/\x20$//;
    $pp->{ExpandedURI q<public-id>} = \$pubid;
    $p->{ExpandedURI q<has-external-id>} = 1;
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
             -class => 'SYNTAX',
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
             -class => 'SYNTAX',
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
    $p->{ExpandedURI q<has-external-id>} = 1;
    $self->system_identifier_start 
            ($src, $p, $pp, %opt);
    return 1;
  }
  
  $self->report
            (-type => 'SYNTAX_MARKUP_DECLARATION_UNKNOWN_KEYWORD',
             -class => 'SYNTAX',
             source => $keyword->{value},
             keyword => ${$keyword->{value}});
  if ($opt{ExpandedURI q<public-id-required>}) {
    $self->report
            (-type => 'SYNTAX_PUBLIC_ID_REQUIRED'.
             -class => 'SYNTAX',
             source => $src);
  } elsif ($opt{ExpandedURI q<system-id-required>}) {
    $self->report
            (-type => 'SYNTAX_SYSTEM_ID_REQUIRED',
             -class => 'SYNTAX',
             source => $src);
  }
  return 1;
}

sub parse_doctype_subset ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  $self->doctype_subset_start
                  ($src, $p, my $pp = $opt{pp} || {}, %opt); 
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
                   -class => 'SYNTAX',
                   source => $src);
        }
      } elsif ($$src =~ /\G($REG_S+)/gco) {
        my $cdata = $1;
        $self->{error}->set_position ($src, moved => 1,
                                      diff => length $cdata);
        $self->{error}->fork_position ($src => \$cdata);
        local $pp->{ExpandedURI q<s>} = \$cdata;
        $self->doctype_subset_content
                  ($src, $p, $pp, %opt);
      } elsif ($$src =~ /\G%/gc) {
        if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
          my $s = $1; pos $s = 0;
          $self->{error}->set_position ($src, moved => 1, diff => length $s);
          $self->{error}->fork_position ($src => \$s);
          my $ppp = {ExpandedURI q<entity-name> => \$s,
                     ExpandedURI q<param> => []};
          if ($self->{ExpandedURI q<_:opened-parameter-entity>}->{$s}) {
            $self->report
                     (-type => 'WFC_NO_RECURSION',
                      -class => 'WFC',
                      source => $src,
                      position_diff => length $s,
                      entity_name => $s);
            $ppp->{ExpandedURI q<entity-opened>} = 1;
          }
          $opt{ExpandedURI q<source>} = [$src];
          $self->parameter_entity_reference_in_subset_start
            ($src, $pp, $ppp, %opt);
          EXPAND: {
            last EXPAND if $pp->{ExpandedURI q<entity-opened>};
            if (overload::StrVal ($src) ne
                overload::StrVal ($opt{ExpandedURI q<source>}->[-1])) {
              if ($self->{ExpandedURI q<is-standalone>} and
                  $self->{error}->get_flag
                  ($opt{ExpandedURI q<source>}->[-1],
                   ExpandedURI q<is-declared-externally>)) {
                $self->report
                         (-type => 'WFC_ENTITY_DECLARED__INTERNAL',
                          -class => 'WFC',
                          source => $src,
                          position_diff => length $s,
                          entity_name => $s);
              } elsif ($self->{error}->get_flag
                         ($opt{ExpandedURI q<source>}->[-1],
                          ExpandedURI q<is-unparsed-entity>)) {
                $self->report
                         (-type => 'WFC_PARSED_ENTITY',
                          -class => 'WFC',
                          source => $src,
                          position_diff => length $s,
                          entity_name => $s);
                shift @{$opt{ExpandedURI q<source>}};
                last EXPAND;
              }
              local $self->{ExpandedURI q<_:opened-parameter-entity>}->{$s} = 1;
              local $opt{ExpandedURI q<allow-declaration>}->{section} = 1,
              local $opt{ExpandedURI q<allow-param-entref>} = 1
                  if $self->{error}->get_flag
                   ($opt{ExpandedURI q<source>}->[-1], 
                    ExpandedURI q<is-external-entity>);
              local $Error::Depth = $Error::Depth + 1;
              $self->parse_doctype_subset
                  ($opt{ExpandedURI q<source>}->[-1],
                   $ppp, %opt,
                   ExpandedURI q<end-with-dsc> => 0,
                   ExpandedURI q<end-with-mse> => 0);
              $ppp->{ExpandedURI q<reference-expanded>} = 1;
            } elsif ($self->{ExpandedURI q<is-standalone>}) {
              $self->report
               (-type => 'WFC_ENTITY_DECLARED',
                -class => 'WFC',
                source => $src,
                position_diff => length $s,
                entity_name => $s);
            }
          }
          $self->parameter_entity_reference_in_subset_end
               ($src, $p, $pp, %opt);

          $$src =~ /\G;/gc or
            $self->report
              (-type => 'SYNTAX_REFC_REQUIRED',
               -class => 'SYNTAX',
               source => $src,
               entity_name => $pp->{ExpandedURI q<entity-name>});
        } else { # pero not followed by Name
          $self->report
                  (-type => 'SYNTAX_DOCTYPE_SUBSET_INVALID_CHAR',
                   -class => 'SYNTAX',
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
        my $cdata = $1;
        $self->report
                  (-type => 'SYNTAX_DOCTYPE_SUBSET_INVALID_CHAR',
                   -class => 'SYNTAX',
                   position_diff => 1,
                   source => $src,
                   char => $cdata);
        $self->{error}->set_position ($src, moved => 1,
                                      diff => length $cdata);
        $self->{error}->fork_position ($src => \$cdata);
        local $pp->{ExpandedURI q<CDATA>} = \$cdata;
        $self->doctype_subset_content
                  ($src, $p, $pp, %opt);
      } else {
        die substr $$src, pos $$src;
      }
    }
    if ($opt{ExpandedURI q<end-with-mse>}) {
      $self->report
                  (-type => 'SYNTAX_MSE_REQUIRED',
                   -class => 'SYNTAX',
                   source => $src);
    } elsif ($opt{ExpandedURI q<end-with-dsc>}) {
      $self->report
                  (-type => 'SYNTAX_ISC_REQUIRED',
                   -class => 'SYNTAX',
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
                   -class => 'SYNTAX',
                   source => $src);
    return 0;
  }
  while (pos $$src < length $$src) {
    if ($$src =~ /\G(?=--)/gc) {
      $self->report (-type => 'SYNTAX_MULTIPLE_COMMENT',
                     -class => 'SYNTAX',
                     source => $src);
      $self->parse_comment ($src, $pp, %opt);
    } elsif ($$src =~ /\G$REG_S+/gco) {
      $self->report (-type => 'SYNTAX_S_IN_COMMENT_DECLARATION',
                     -class => 'SYNTAX',
                     source => $src,
                     position_diff => $+[0] - $-[0]);
    } else {
      last;
    }
  }
  unless ($$src =~ /\G>/gc) {
    $self->report (-type => 'SYNTAX_MDC_FOR_COMMENT_REQUIRED',
                   -class => 'SYNTAX',
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
                     -class => 'SYNTAX',
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
              -class => 'SYNTAX',
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
             -class => 'SYNTAX',
             source => $entname->{value})
            if $opt{ExpandedURI q<ps-required>};
          if ($opt{ExpandedURI q<allow-section>}->{${$entname->{value}}}) {
            # 
          } else {
            $self->report
              (-type => 'SYNTAX_MARKED_SECTION_KEYWORD',
               -class => 'SYNTAX',
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
               -class => 'SYNTAX',
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
               -class => 'SYNTAX',
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
      $pp->{ExpandedURI q<CDATA>} = \$cdata;
      $$src =~ /\G\]\]>/gc
        or $self->report
             (-type => 'SYNTAX_MSE_REQUIRED',
              -class => 'SYNTAX',
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
      $pp->{ExpandedURI q<CDATA>} = \$cdata;
      $$src =~ /\G\]\]>/gc
        or $self->report
             (-type => 'SYNTAX_MSE_REQUIRED',
              -class => 'SYNTAX',
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
         {ExpandedURI q<CDATA> => $cdata}, %opt);
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
       -class => 'SYNTAX',
       source => $src);
  }
  return 1;
} # parse_ignored_section_content

sub parse_processing_instruction ($$$%) {
  my ($self, $src, $p, %opt) = @_;
  if ($$src =~ /\G<\?/gc) {
    my $pp = {};
    if ($$src =~ /\G($XML_NAME{$self->{ExpandedURI q<xml-version>}||'1.0'})/gc) {
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
                -class => 'SYNTAX',
                source => $src,
                target_name => $tn,
                position_diff => 3);
      }
      $pp->{ExpandedURI q<target-name>} = $tn;
    } else {
      $self->report
               (-type => 'SYNTAX_TARGET_NAME_REQUIRED',
                -class => 'SYNTAX',
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
                -class => 'SYNTAX',
                source => $src);
    }
    
    $self->processing_instruction_end
               ($src, $p, $pp, %opt);
    return 1;
  } else {
    if ($opt{ExpandedURI q<match-or-error>}) {
      $self->report
               (-type => 'SYNTAX_PROCESSING_INSTRUCTION_REQUIRED',
                -class => 'SYNTAX',
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
    my $xmlver;
    if ($attr->[0] and ${$attr->[0]->{name}} eq 'version') {
      $xmlver = ${$attr->[0]->{value}};
      if ($xmlver eq '1.0' or $xmlver eq '1.1') {
        # 
      } else {
        unless ($xmlver =~ /^[0-9A-Za-z.:_-]+$/) {
          $self->report
              (-type => 'SYNTAX_XML_VERSION_INVALID',
               -class => 'SYNTAX',
               source => $attr->[0]->{value},
               version => $xmlver);
        }
        $self->report
              (-type => 'SYNTAX_XML_VERSION_UNSUPPORTED',
               -class => 'SYNTAX',
               source => $attr->[0]->{value},
               version => $xmlver);
      }
      shift @$attr;  shift @$sep;
    } else {
      if ($type eq 'xml') {
        $self->report
              (-type => 'SYNTAX_XML_VERSION_REQUIRED',
               -class => 'SYNTAX',
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
               -class => 'SYNTAX',
               source => $attr->[0]->{value},
               encoding => $encoding);
      }
      shift @$attr;  shift @$sep;      
    } else {
      if ($type eq 'text') {
        $self->report
              (-type => 'SYNTAX_XML_ENCODING_REQUIRED',
               -class => 'SYNTAX',
               source => $attr->[0] ? $attr->[0]->{name} : $src);
      }
    }
    
    my $standalone;
    if ($attr->[0] and ${$attr->[0]->{name}} eq 'standalone') {
      $standalone = ${$attr->[0]->{value}};
      if ($type eq 'text') {
        $self->report
              (-type => 'SYNTAX_XML_STANDALONE',
               -class => 'SYNTAX',
               source => $attr->[0]->{name});
      } elsif ($type eq 'xml-or-text') {
        $type = 'xml';
      }
      unless ($standalone eq 'yes' or $standalone eq 'no') {
        $self->report
              (-type => 'SYNTAX_XML_STANDALONE_INVALID',
               -class => 'SYNTAX',
               source => $attr->[0]->{value},
               standalone => $standalone
);
      }
      unless (${$sep->[0]} =~ /^\x20+$/) {
        if ($xmlver ne '1.0') { # 1.1
          $self->report
              (-type => 'SYNTAX_XML_STANDALONE_S',
               -class => 'SYNTAX',
               source => $sep->[0]);
        }
      }
      shift @$attr;  shift @$sep;
    }
    
    my $q = {};
    $q->{ExpandedURI q<xml-declaration-version>} = $xmlver;
    $xmlver ||= '1.0';
    if ($type eq 'xml') {
      $self->{ExpandedURI q<xml-version>} = $xmlver eq '1.0' ? '1.0' : '1.1';
    } else {
      $self->{ExpandedURI q<xml-version>} ||= $xmlver eq '1.0' ? '1.0' : '1.1';
    }
    $q->{ExpandedURI q<xml-declaration-encoding>} = $encoding;
    $q->{ExpandedURI q<xml-declaration-standalone>} = $standalone;
    $q->{ExpandedURI q<xml-declaration-type>} = $type;
    
    for (@$attr) {
      $self->report
              (-type => 'SYNTAX_XML_UNKNOWN_ATTR',
               -class => 'SYNTAX',
               source => $_->{name},
               attribute_name => ${$_->{name}});
      $q->{ExpandedURI q<xml-declaration-pseudo-attr-misc>} = $attr;
    }
    $self->xml_declaration ($src, $p, $q, %opt);

    ## Check pic
    unless ($$src =~ /\G\?>/gc) {
      $self->report
               (-type => 'SYNTAX_PIC_REQUIRED',
                -class => 'SYNTAX',
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

=head1 EVENT METHODS

When parser finds some structure in parsing entity,
it reports what it sees as "call back" event.
Derived modules are able to receive these message by
implementing event handler methods listed below.

All event methods will receive five common arguments:
C<$self>, C<$src>, C<$p>, C<$pp>, C<%opt>.

=over 4

=item $self

Parser object itself, as general manner of Perl object.

=item $p

Hash reference.  This hash has information for "parent" construct,
for example parent element information for C<element_content> method.

=item $pp

Hash reference.  This hash provides information for "this"
constructs - about that element if C<element_end>.

In general, not all of information that construct should have
might be available at stage of C<*_start> or C<*_content> methods,
since that is not processed.  It is expected to be available from
C<*_end> method.

In addition, some required information will not available
if fatal error detected but recovered from it so that
process it continued.

=item %opt

Options.  Some options are specified by parser and somes are came
from outside.

=back

Available event methods are:

=over 4

=item document_start, xml_declaration, document_content, document_end

Document entity is processed.

Method C<xml_declaration> is called when document has the XML declaration.

Method C<document_content> is called when document has C<s> or
(illegally) some character data as direct child (not part of some
element).

=back

=cut

sub document_start ($$$$%) {}
sub xml_declaration ($$$$%) {}
sub document_content ($$$$%) {}
sub document_end ($$$$%) {}

=item external_parsed_entity_start, external_parsed_entity_content, external_parsed_entity_end

Called when external parsed entity (except document entity) is processed.
Method C<xml_declaration> is also called just after 
C<external_parsed_entity_start> in case that entity has a text declaration.

Method C<external_parsed_entity_content> is called once
with entity content as is.

=cut

sub external_parsed_entity_start ($$$$%) {}
sub external_parsed_entity_content ($$$$%) {}
sub external_parsed_entity_end ($$$$%) {}

=item element_start, element_content, element_end

Element occurs.

Method C<element_content> is called when element has
terminal text node (or might be C<s> separator node, if content model
is element content; directly or indirectly, as long as not
part of child element).

=cut

sub element_start ($$$$%) {}
sub element_content ($$$$%) {}
sub element_end ($$$$%) {}

=item start_tag_start, start_tag_end

Start tag occurs.

=cut

sub start_tag_start ($$$$%) {}
sub start_tag_end ($$$$%) {}

=item end_tag_start, end_tag_end

End tag occurs.  These methods called even if empty element tag
syntax is used.

=cut

sub end_tag_start ($$$$%) {}
sub end_tag_end ($$$$%) {}

=item attribute_specifications_start, attribute_specifications_end

Attribute specifications occurs.

Note that if you use method C<parse_attribute_value_specifications>
to parse pseudo-attribute style processing instructions,
these methods will be called even C<start_tag_start> is not called before.

=cut

sub attribute_specifications_start ($$$$%) {}
sub attribute_specifications_end ($$$$%) {}

=item attribute_specification_start, attribute_specification_end

Attribute specification occurs.

=cut

sub attribute_specification_start ($$$$%) {}
sub attribute_specification_end ($$$$%) {}

=item attribute_value_specification_start, attribute_value_specification_content, attribute_value_specification_end

Attribute value specification.

Method C<attribute_value_specification_content> is called
when terminal character data occurs in attribute value specification.

Note that these methods will be called (1) in start tag
or (2) in attribute definition list declaration.

=cut

sub attribute_value_specification_start ($$$$%) {}
sub attribute_value_specification_content ($$$$%) {}
sub attribute_value_specification_end ($$$$%) {}

=item doctype_declaration_start, doctype_declaration_end

Document type declaration.

=item doctype_internal_subset_start, doctype_internal_subset_end, doctype_external_subset_start, doctype_external_subset_end

Document type declaration internal subset and external subset.
These methods are called before/after C<doctype_subset_start>
or C<doctype_subset_end> is called.

Note that C<doctype_internal_subset_start> and
C<doctype_internal_subset_end> are called even if doctype declaration
does not have dso ([) and dsc (]).

=cut

sub doctype_declaration_start ($$$$%) {}
sub doctype_internal_subset_start ($$$$%) {}
sub doctype_internal_subset_end ($$$$%) {}
sub doctype_external_subset_start ($$$$%) {}
sub doctype_external_subset_end ($$$$%) {}
sub doctype_declaration_end ($$$$%) {}

=item doctype_subset_start, doctype_subset_content, doctype_subset_end

Either document type declaration internal subset, 
document type declaration external subset or
external parameter entity referred within C<DeclSep> part of
document type declaration subset is processed.

Method C<doctype_subset_content> is called when
C<S> or (illegall) unparsable character data occurs.

=cut

sub doctype_subset_start ($$$$%) {}
sub doctype_subset_content ($$$$%) {}
sub doctype_subset_end ($$$$%) {}

=item entity_declaration_start, entity_value_content, entity_declaration_end

Entity declaration.

Method C<entity_value_content> is called if entity declaration
has parameter literal that defines internal entity.

=cut

sub entity_declaration_start ($$$$%) {}
sub entity_declaration_end ($$$$%) {}
sub entity_value_content ($$$$%) {}

=item element_declaration_start, element_declaration_end

Element type declaration.

=cut

sub element_declaration_start ($$$$%) {}
sub element_declaration_end ($$$$%) {}

=item attlist_declaration_start, attribute_definition, attlist_declaration_end

Attribute definition list declaration.

Method C<attribute_definition> is called with each attribute definition.

=cut

sub attlist_declaration_start ($$$$%) {}
sub attribute_definition ($$$$%) {}
sub attlist_declaration_end ($$$$%) {}

=item notation_declaration_start, notation_declaration_end

Notation declaration.

=cut

sub notation_declaration_start ($$$$%) {}
sub notation_declaration_end ($$$$%) {}

=item markup_declaration_parameters_start, markup_declaration_parameter, markup_declaration_parameters_end

Parameters part of markup declarations.

Method C<markup_declaration_parameter> is called
with each markup declaration parameter, such as keyword or parameter
literal.

=cut

sub markup_declaration_parameters_start ($$$$%) {}
sub markup_declaration_parameter ($$$$%) {}
sub markup_declaration_parameters_end ($$$$%) {}

=item model_group_start, model_group_content, model_group_end

Model group, used to describe element content model.

Method C<model_group_content> is called with each occurence
of terminal token (i.e element type name).

=cut

sub model_group_start ($$$$%) {}
sub model_group_content ($$$$%) {}
sub model_group_end ($$$$%) {}

=item attrtype_group_start, attrtype_group_content, attrtype_group_end

Group for enumeration types, used in attribute definition.

Method C<attrtype_group_content> is called with each
NMTOKEN in group.

=cut

sub attrtype_group_start ($$$$%) {}
sub attrtype_group_content ($$$$%) {}
sub attrtype_group_end ($$$$%) {}

=item public_identifier_start, system_identifier_start

Called when public identifier or system identifier
specified in markup declaration.

=cut

sub public_identifier_start ($$$$%) {}
sub system_identifier_start ($$$$%) {}

=item parameter_literal_start, parameter_literal_end

Parameter literal.

=cut

sub parameter_literal_start ($$$$%) {}
sub parameter_literal_end ($$$$%) {}

=item rpdata_start, rpdata_content, rpdata_end

Replaceable parameter data (i.e content of parameter literal).

Method C<rpdata_content> is called with terminal character data.

Remember that methods C<parameter_literal_start> and
C<parameter_literal_end> are called only onces for a parameter
literal, while C<rpdata_start> and C<rpdata_end> are also called
with each expansion of parameter entity references in parameter
literal.

=cut

sub rpdata_start ($$$$%) {}
sub rpdata_content ($$$$%) {}
sub rpdata_end ($$$$%) {}

=item marked_section_start, marked_section_end

Marked section.

=item marked_section_status

Marked section status keyword.  This method is called only once
if input is well-formed XML document.

=item marked_section_content_start, marked_section_content_end

Content of marked section.

=item ignored_section_content

Content of ignored marked section.

=cut

sub marked_section_start ($$$$%) {}
sub marked_section_status ($$$$%) {}
sub marked_section_content_start ($$$$%) {}
sub ignored_section_content ($$$$%) {}
sub marked_section_content_end ($$$$%) {}
sub marked_section_end ($$$$%) {}

=item comment_declaration_start, comment_declaration_end

Comment declaration.

=cut

sub comment_declaration_start ($$$$%) {}
sub comment_declaration_end ($$$$%) {}

=item comment_start, comment_content, comment_end

Comment.  These methods are called only once in comment
declaration if input is well-formed XML document.

=cut

sub comment_start ($$$$%) {}
sub comment_content ($$$$%) {}
sub comment_end ($$$$%) {}

=item processing_instruction_start, processing_instruction_content, processing_instruction_end

Processing instruction.

Note that XML declaration and text declaration are not processing
instruction in XML sense and these methods are not called.

=cut

sub processing_instruction_start ($$$$%) {}
sub processing_instruction_content ($$$$%) {}
sub processing_instruction_end ($$$$%) {}

=item numeric_character_reference_in_attribute_value_literal_start, numeric_character_reference_in_content_start, numeric_character_reference_in_rpdata_start

Numeric character reference.

=cut

sub numeric_character_reference_in_attribute_value_literal_start
    ($$$$%) {}
sub numeric_character_reference_in_content_start ($$$$%) {}
sub numeric_character_reference_in_rpdata_start ($$$$%) {}

=item hex_character_reference_in_attribute_value_literal_start, hex_character_reference_in_content_start, hex_character_reference_in_rpdata_start

Hexdecimal character reference.

=cut

sub hex_character_reference_in_attribute_value_literal_start
    ($$$$%) {}
sub hex_character_reference_in_content_start ($$$$%) {}
sub hex_character_reference_in_rpdata_start ($$$$%) {}

=pod

NOTE: Methods C<ncr_in_attribute_value_literal_start>
C<hcr_in_attribute_value_literal_start>
are required to check C<normalize-attr-val> option
to normalize attribute value as specified by XML.
That is: when these method received U+0009, U+000A or
U+000D as referred character code, and Q<normalize-attr-val>
option turned on, it MUST be treated as U+0020
in case I<character reference belongs to some parsed entity>.
(Character reference directly belong to attribute value literal
is not concern to this normalization.)

=item general_entity_reference_in_attribute_value_literal_start, general_entity_reference_in_attribute_value_literal_end

General entity reference in attribute value literal.

=cut

sub general_entity_reference_in_attribute_value_literal_start
    ($$$$%) {}
sub general_entity_reference_in_attribute_value_literal_end
    ($$$$%) {}

=item general_entity_reference_in_content_start, general_entity_reference_in_content_end

General entity reference in content (between start-tag and end-tag).

=cut

sub general_entity_reference_in_content_start ($$$$%) {}
sub general_entity_reference_in_content_end ($$$$%) {}

=item general_entity_reference_in_rpdata_start, general_entity_reference_in_rpdata_end

General entity reference in parameter literal.

NOTE: General entity reference in parameter literal is syntatically 
checked but not processed yet in XML.

=cut

sub general_entity_reference_in_rpdata_start ($$$$%) {}
sub general_entity_reference_in_rpdata_end ($$$$%) {}

=item parameter_entity_reference_in_subset_start, parameter_entity_reference_in_subset_end

Parameter entity reference in document type declaration subset
(out of markup declarations).

=cut

sub parameter_entity_reference_in_subset_start ($$$$%) {}
sub parameter_entity_reference_in_subset_end ($$$$%) {}

=item parameter_entity_reference_in_parameter_start, parameter_entity_reference_in_parameter_end

Parameter entity reference in markup declaration
(out of parameter literal).

=cut

sub parameter_entity_reference_in_parameter_start ($$$$%) {}
sub parameter_entity_reference_in_parameter_end ($$$$%) {}

=item parameter_entity_reference_in_rpdata_start, parameter_entity_reference_in_rpdata_end

Parameter entity reference in parameter literal.

=cut

sub parameter_entity_reference_in_rpdata_start ($$$$%) {}
sub parameter_entity_reference_in_rpdata_end ($$$$%) {}

=back

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/08/03 04:19:53 $
