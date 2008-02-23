package Whatpm::ContentChecker;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.60 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Whatpm::URIChecker;

## ISSUE: How XML and XML Namespaces conformance can (or cannot)
## be applied to an in-memory representation (i.e. DOM)?

## TODO: Conformance of an HTML document with non-html root element.

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;
my $XML_NS = q<http://www.w3.org/XML/1998/namespace>;
my $XMLNS_NS = q<http://www.w3.org/2000/xmlns/>;

my $Namespace = {
  q<http://www.w3.org/2005/Atom> => {module => 'Whatpm::ContentChecker::Atom'},
  $HTML_NS => {module => 'Whatpm::ContentChecker::HTML'},
  $XML_NS => {loaded => 1},
  $XMLNS_NS => {loaded => 1},
};

our $AttrChecker = {
  $XML_NS => {
    space => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value eq 'default' or $value eq 'preserve') {
        #
      } else {
        ## NOTE: An XML "error"
        $self->{onerror}->(node => $attr, level => 'error',
                           type => 'invalid attribute value');
      }
    },
    lang => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value eq '') {
        #
      } else {
        require Whatpm::LangTag;
        Whatpm::LangTag->check_rfc3066_language_tag ($value, sub {
          my %opt = @_;
          my $type = 'LangTag:'.$opt{type};
          $type .= ':' . $opt{subtag} if defined $opt{subtag};
          $self->{onerror}->(node => $attr, type => $type,
                             value => $opt{value}, level => $opt{level});
        });
      }

      ## NOTE: "The values of the attribute are language identifiers
      ## as defined by [IETF RFC 3066], Tags for the Identification
      ## of Languages, or its successor; in addition, the empty string
      ## may be specified." ("may" in lower case)
      ## NOTE: Is an RFC 3066-valid (but RFC 4647-invalid) language tag
      ## allowed today?

      ## TODO: test data

      if ($attr->owner_document->manakai_is_html) { # MUST NOT
        $self->{onerror}->(node => $attr, type => 'in HTML:xml:lang');
## TODO: Test data...
      }
    },
    base => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value =~ /[^\x{0000}-\x{10FFFF}]/) { ## ISSUE: Should we disallow noncharacters?
        $self->{onerror}->(node => $attr,
                           type => 'invalid attribute value');
      }
      ## NOTE: Conformance to URI standard is not checked since there is
      ## no author requirement on conformance in the XML Base specification.
    },
    id => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      $value =~ s/[\x09\x0A\x0D\x20]+/ /g;
      $value =~ s/^\x20//;
      $value =~ s/\x20$//;
      ## TODO: NCName in XML 1.0 or 1.1
      ## TODO: declared type is ID?
      if ($self->{id}->{$value}) { ## NOTE: An xml:id error
        $self->{onerror}->(node => $attr, level => 'error', 
                           type => 'duplicate ID');
        push @{$self->{id}->{$value}}, $attr;
      } else {
        $self->{id}->{$value} = [$attr];
      }
    },
  },
  $XMLNS_NS => {
    '' => sub {
      my ($self, $attr) = @_;
      my $ln = $attr->manakai_local_name;
      my $value = $attr->value;
      if ($value eq $XML_NS and $ln ne 'xml') {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xml');
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xmlns');
      }
      if ($ln eq 'xml' and $value ne $XML_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:xmlns:xml=');
      } elsif ($ln eq 'xmlns') {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:xmlns:xmlns=');
      }
      ## TODO: If XML 1.0 and empty
    },
    xmlns => sub {
      my ($self, $attr) = @_;
      ## TODO: In XML 1.0, URI reference [RFC 3986] or an empty string
      ## TODO: In XML 1.1, IRI reference [RFC 3987] or an empty string
      ## TODO: relative references are deprecated
      my $value = $attr->value;
      if ($value eq $XML_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xml');
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr, level => 'NC',
             type => 'Reserved Prefixes and Namespace Names:=xmlns');
      }
    },
  },
};

## ISSUE: Should we really allow these attributes?
$AttrChecker->{''}->{'xml:space'} = $AttrChecker->{$XML_NS}->{space};
$AttrChecker->{''}->{'xml:lang'} = $AttrChecker->{$XML_NS}->{lang};
$AttrChecker->{''}->{'xml:base'} = $AttrChecker->{$XML_NS}->{base};
$AttrChecker->{''}->{'xml:id'} = $AttrChecker->{$XML_NS}->{id};

our %AnyChecker = (
  check_start => sub { },
  check_attrs => sub {
    my ($self, $item, $element_state) = @_;
    for my $attr (@{$item->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker = $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr);
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
      }
    }
  },
  check_child_element => sub {
    my ($self, $item, $child_el, $child_nsuri, $child_ln,
        $child_is_transparent, $element_state) = @_;
    if ($self->{minus_elements}->{$child_nsuri}->{$child_ln}) {
      $self->{onerror}->(node => $child_el,
                         type => 'element not allowed:minus',
                         level => $self->{must_level});
    } elsif ($self->{plus_elements}->{$child_nsuri}->{$child_ln}) {
      #
    } else {
      #
    }
  },
  check_child_text => sub { },
  check_end => sub {
    my ($self, $item, $element_state) = @_;
    if ($element_state->{has_significant}) {
      $item->{parent_state}->{has_significant} = 1;
    }    
  },
);

our $ElementDefault = {
  %AnyChecker,
  check_start => sub {
    my ($self, $item, $element_state) = @_;
    $self->{onerror}->(node => $item->{node}, level => 'unsupported',
                       type => 'element');
  },
};

our $HTMLEmbeddedContent = {
  ## NOTE: All embedded content is also phrasing content.
  $HTML_NS => {
    img => 1, iframe => 1, embed => 1, object => 1, video => 1, audio => 1,
    canvas => 1,
  },
  ## NOTE: MathML is mentioned in the HTML5 spec.
  q<http://www.w3.org/1998/Math/MathML> => {math => 1},
  ## NOTE: SVG is mentioned in the HTML5 spec.
  q<http://www.w3.org/2000/svg> => {svg => 1},
  ## NOTE: Foreign elements with content (but no metadata) are 
  ## embedded content.
};  

my $HTMLTransparentElements = {
  $HTML_NS => {qw/ins 1 del 1 font 1 noscript 1 canvas 1/},
  ## NOTE: |html:noscript| is transparent if scripting is disabled
  ## and not in |head|.
};

## Semi-transparent: html:video, html:audio, html:object

our $Element = {};

sub check_document ($$$;$) {
  my ($self, $doc, $onerror, $onsubdoc) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;
  $self->{onsubdoc} = $onsubdoc || sub {
    warn "A subdocument is not conformance-checked";
  };

  $self->{must_level} = 'm';
  $self->{fact_level} = 'f';
  $self->{should_level} = 's';
  $self->{good_level} = 'w';
  $self->{unsupported_lavel} = 'u';

  my $docel = $doc->document_element;
  unless (defined $docel) {
    ## ISSUE: Should we check content of Document node?
    $onerror->(node => $doc, type => 'no document element');
    ## ISSUE: Is this non-conforming (to what spec)?  Or just a warning?
    return {
            class => {},
            id => {}, table => [], term => {},
           };
  }

  ## ISSUE: Unexpanded entity references and HTML5 conformance
  
  my $docel_nsuri = $docel->namespace_uri;
  $docel_nsuri = '' unless defined $docel_nsuri;
  unless ($Namespace->{$docel_nsuri}->{loaded}) {
    if ($Namespace->{$docel_nsuri}->{module}) {
      eval qq{ require $Namespace->{$docel_nsuri}->{module} } or die $@;
    } else {
      $Namespace->{$docel_nsuri}->{loaded} = 1;
    }
  }
  my $docel_def = $Element->{$docel_nsuri}->{$docel->manakai_local_name} ||
    $Element->{$docel_nsuri}->{''} ||
    $ElementDefault;
  if ($docel_def->{is_root}) {
    #
  } elsif ($docel_def->{is_xml_root}) {
    unless ($doc->manakai_is_html) {
      #
    } else {
      $onerror->(node => $docel, type => 'element not allowed:root:xml');
    }
  } else {
    $onerror->(node => $docel, type => 'element not allowed:root');
  }

  ## TODO: Check for other items other than document element
  ## (second (errorous) element, text nodes, PI nodes, doctype nodes)

  my $return = $self->check_element ($docel, $onerror, $onsubdoc);

  ## TODO: Test for these checks are necessary.
  my $charset_name = $doc->input_encoding;
  if (defined $charset_name) {
    require Message::Charset::Info;
    my $charset = $Message::Charset::Info::IANACharset->{$charset_name};

    if ($doc->manakai_is_html and
        not $doc->manakai_has_bom and
        not defined $doc->manakai_charset) {
      unless ($charset->{is_html_ascii_superset}) {
        $onerror->(node => $doc, level => $self->{must_level},
                   type => 'non ascii superset:'.$charset_name);
      }
      
      if (not $self->{has_charset} and
          not $charset->{iana_names}->{'us-ascii'}) {
        $onerror->(node => $doc, level => $self->{must_level},
                   type => 'no character encoding declaration:'.$charset_name);
      }
    }

    if ($charset->{iana_names}->{'utf-8'}) {
      #
    } elsif ($charset->{iana_names}->{'jis_x0212-1990'} or
             $charset->{iana_names}->{'x-jis0208'} or
             $charset->{iana_names}->{'utf-32'} or ## ISSUE: UTF-32BE? UTF-32LE?
             $charset->{is_ebcdic_based}) {
      $onerror->(node => $doc,
                 type => 'character encoding:'.$charset_name,
                 level => $self->{should_level});
    } elsif ($charset->{iana_names}->{'cesu-8'} or
             $charset->{iana_names}->{'utf-8'} or ## ISSUE: UNICODE-1-1-UTF-7?
             $charset->{iana_names}->{'bocu-1'} or
             $charset->{iana_names}->{'scsu'}) {
      $onerror->(node => $doc,
                 type => 'character encoding:'.$charset_name,
                 level => $self->{must_level});
    } else {
      $onerror->(node => $doc,
                 type => 'character encoding:'.$charset_name,
                 level => $self->{good_level});
    }
  } elsif ($doc->manakai_is_html) {
    ## NOTE: MUST and SHOULD requirements above cannot be tested,
    ## since the document has no input charset encoding information.
    $onerror->(node => $doc,
               type => 'character encoding:',
               level => 'unsupported');
  }

  return $return;
} # check_document

sub check_element ($$$;$) {
  my ($self, $el, $onerror, $onsubdoc) = @_;
  $self = bless {}, $self unless ref $self;
  $self->{onerror} = $onerror;
  $self->{onsubdoc} = $onsubdoc || sub {
    warn "A subdocument is not conformance-checked";
  };

  $self->{must_level} = 'm';
  $self->{fact_level} = 'f';
  $self->{should_level} = 's';
  $self->{good_level} = 'w';
  $self->{unsupported_lavel} = 'u';

  $self->{pluses} = {};
  $self->{minuses} = {};
  $self->{id} = {};
  $self->{term} = {};
  $self->{usemap} = [];
  $self->{contextmenu} = [];
  $self->{map} = {};
  $self->{menu} = {};
  $self->{has_link_type} = {};
  $self->{flag} = {};
  #$self->{has_uri_attr};
  #$self->{has_hyperlink_element};
  #$self->{has_charset};
  #$self->{has_base};
  $self->{return} = {
    class => {},
    id => $self->{id}, table => [], term => $self->{term},
  };

  my @item = ({type => 'element', node => $el, parent_state => {}});
  while (@item) {
    my $item = shift @item;
    if (ref $item eq 'ARRAY') {
      my $code = shift @$item;
next unless $code;## TODO: temp.
      $code->(@$item);
    } elsif ($item->{type} eq 'element') {
      my $el_nsuri = $item->{node}->namespace_uri;
      $el_nsuri = '' unless defined $el_nsuri;
      my $el_ln = $item->{node}->manakai_local_name;
      
      unless ($Namespace->{$el_nsuri}->{loaded}) {
        if ($Namespace->{$el_nsuri}->{module}) {
          eval qq{ require $Namespace->{$el_nsuri}->{module} } or die $@;
        } else {
          $Namespace->{$el_nsuri}->{loaded} = 1;
        }
      }
      my $eldef = $Element->{$el_nsuri}->{$el_ln} ||
          $Element->{$el_nsuri}->{''} ||
          $ElementDefault;
      my $content_def = $item->{parent_def} || $eldef;

      my $element_state = {};
      my @new_item;
      push @new_item, [$eldef->{check_start}, $self, $item, $element_state];
      push @new_item, [$eldef->{check_attrs}, $self, $item, $element_state];
        
      my @child = @{$item->{node}->child_nodes};
      while (@child) {
        my $child = shift @child;
        my $child_nt = $child->node_type;
        if ($child_nt == 1) { # ELEMENT_NODE
          my $child_nsuri = $child->namespace_uri;
          $child_nsuri = '' unless defined $child_nsuri;
          my $child_ln = $child->manakai_local_name;
          if ($HTMLTransparentElements->{$child_nsuri}->{$child_ln} and
              not (($self->{flag}->{in_head} or
                    ($el_nsuri eq q<http://www.w3.org/1999/xhtml> and
                     $el_ln eq 'head')) and
                   $child_nsuri eq q<http://www.w3.org/1999/xhtml> and
                   $child_ln eq 'noscript')) {
            push @new_item, [$content_def->{check_child_element},
                             $self, $item, $child,
                             $child_nsuri, $child_ln, 1, $element_state];
            push @new_item, {type => 'element', node => $child,
                             parent_state => $element_state,
                             parent_def => $item->{parent_def} || $eldef,
                             transparent => 1};
          } else {
            push @new_item, [$content_def->{check_child_element},
                             $self, $item, $child,
                             $child_nsuri, $child_ln, 0, $element_state];
            push @new_item, {type => 'element', node => $child,
                             parent_state => $element_state};
          }

          if ($HTMLEmbeddedContent->{$child_nsuri}->{$child_ln}) {
            $element_state->{has_significant} = 1;
          }
        } elsif ($child_nt == 3 or # TEXT_NODE
                 $child_nt == 4) { # CDATA_SECTION_NODE
          my $has_significant = ($child->data =~ /[^\x09-\x0D\x20]/);
          push @new_item, [$content_def->{check_child_text},
                           $self, $item, $child, $has_significant,
                           $element_state];
          $element_state->{has_significant} ||= $has_significant;
        } elsif ($child_nt == 5) { # ENTITY_REFERENCE_NODE
          push @child, @{$child->child_nodes};
        }
        ## TODO: PI_NODE
        ## TODO: Unknown node type
      }
      
      push @new_item, [$eldef->{check_end}, $self, $item, $element_state];
      
      unshift @item, @new_item;
    } else {
      die "$0: Internal error: Unsupported checking action type |$item->{type}|";
    }
  }

  for (@{$self->{usemap}}) {
    unless ($self->{map}->{$_->[0]}) {
      $self->{onerror}->(node => $_->[1], type => 'no referenced map');
    }
  }

  for (@{$self->{contextmenu}}) {
    unless ($self->{menu}->{$_->[0]}) {
      $self->{onerror}->(node => $_->[1], type => 'no referenced menu');
    }
  }

  delete $self->{pluses};
  delete $self->{minuses};
  delete $self->{onerror};
  delete $self->{id};
  delete $self->{usemap};
  delete $self->{map};
  return $self->{return};
} # check_element

sub _add_minus_elements ($$@) {
  my $self = shift;
  my $element_state = shift;
  for my $elements (@_) {
    for my $nsuri (keys %$elements) {
      for my $ln (keys %{$elements->{$nsuri}}) {
        unless ($self->{minus_elements}->{$nsuri}->{$ln}) {
          $element_state->{minus_elements_original}->{$nsuri}->{$ln} = 0;
          $self->{minus_elements}->{$nsuri}->{$ln} = 1;
        }
      }
    }
  }
} # _add_minus_elements

sub _remove_minus_elements ($$) {
  my $self = shift;
  my $element_state = shift;
  for my $nsuri (keys %{$element_state->{minus_elements_original}}) {
    for my $ln (keys %{$element_state->{minus_elements_original}->{$nsuri}}) {
      delete $self->{minus_elements}->{$nsuri}->{$ln};
    }
  }
} # _remove_minus_elements

sub _add_plus_elements ($$@) {
  my $self = shift;
  my $element_state = shift;
  for my $elements (@_) {
    for my $nsuri (keys %$elements) {
      for my $ln (keys %{$elements->{$nsuri}}) {
        unless ($self->{plus_elements}->{$nsuri}->{$ln}) {
          $element_state->{plus_elements_original}->{$nsuri}->{$ln} = 0;
          $self->{plus_elements}->{$nsuri}->{$ln} = 1;
        }
      }
    }
  }
} # _add_plus_elements

sub _remove_plus_elements ($$) {
  my $self = shift;
  my $element_state = shift;
  for my $nsuri (keys %{$element_state->{plus_elements_original}}) {
    for my $ln (keys %{$element_state->{plus_elements_original}->{$nsuri}}) {
      delete $self->{plus_elements}->{$nsuri}->{$ln};
    }
  }
} # _remove_plus_elements

sub _add_minuses ($@) {
  my $self = shift;
  my $r = {};
  for my $list (@_) {
    for my $ns (keys %$list) {
      for my $ln (keys %{$list->{$ns}}) {
        unless ($self->{minuses}->{$ns}->{$ln}) {
          $self->{minuses}->{$ns}->{$ln} = 1;
          $r->{$ns}->{$ln} = 1;
        }
      }
    }
  }
  return {type => 'plus', list => $r};
} # _add_minuses

sub _add_pluses ($@) {
  my $self = shift;
  my $r = {};
  for my $list (@_) {
    for my $ns (keys %$list) {
      for my $ln (keys %{$list->{$ns}}) {
        unless ($self->{pluses}->{$ns}->{$ln}) {
          $self->{pluses}->{$ns}->{$ln} = 1;
          $r->{$ns}->{$ln} = 1;
        }
      }
    }
  }
  return {type => 'minus', list => $r};
} # _add_pluses

sub _remove_minuses ($$) {
  my ($self, $todo) = @_;
  if ($todo->{type} eq 'minus') {
    for my $ns (keys %{$todo->{list}}) {
      for my $ln (keys %{$todo->{list}->{$ns}}) {
        delete $self->{pluses}->{$ns}->{$ln} if $todo->{list}->{$ns}->{$ln};
      }
    }
  } elsif ($todo->{type} eq 'plus') {
    for my $ns (keys %{$todo->{list}}) {
      for my $ln (keys %{$todo->{list}->{$ns}}) {
        delete $self->{minuses}->{$ns}->{$ln} if $todo->{list}->{$ns}->{$ln};
      }
    }
  } else {
    die "$0: Unknown +- type: $todo->{type}";
  }
  1;
} # _remove_minuses

## NOTE: Priority for "minuses" and "pluses" are currently left
## undefined and implemented inconsistently; it is not a problem for
## now, since no element belongs to both lists.

sub _check_get_children ($$$) {
  my ($self, $node, $parent_todo) = @_;
  my $new_todos = [];
  my $sib = [];
  TP: {
    my $node_ns = $node->namespace_uri;
    $node_ns = '' unless defined $node_ns;
    my $node_ln = $node->manakai_local_name;
    if ($HTMLTransparentElements->{$node_ns}->{$node_ln}) {
      if ($node_ns eq $HTML_NS and $node_ln eq 'noscript') {
        if ($parent_todo->{flag}->{in_head}) {
          #
        } else {
          my $end = $self->_add_minuses ({$HTML_NS, {noscript => 1}});
          push @$sib, $end;
          
          unshift @$sib, @{$node->child_nodes};
          push @$new_todos, {type => 'element-attributes', node => $node};
          last TP;
        }
      } elsif ($node_ns eq $HTML_NS and $node_ln eq 'del') {
        my $sig_flag = $parent_todo->{flag}->{has_descendant}->{significant};
        unshift @$sib, @{$node->child_nodes};
        push @$new_todos, {type => 'element-attributes', node => $node};
        push @$new_todos,
            {type => 'code',
             code => sub {
               $parent_todo->{flag}->{has_descendant}->{significant} = 0
                   if not $sig_flag;
             }};
        last TP;
      } else {
        unshift @$sib, @{$node->child_nodes};
        push @$new_todos, {type => 'element-attributes', node => $node};
        last TP;
      }
    }
    if ($node_ns eq $HTML_NS and ($node_ln eq 'video' or $node_ln eq 'audio')) {
      if ($node->has_attribute_ns (undef, 'src')) {
        unshift @$sib, @{$node->child_nodes};
        push @$new_todos, {type => 'element-attributes', node => $node};
        last TP;
      } else {
        my @cn = @{$node->child_nodes};
        CN: while (@cn) {
          my $cn = shift @cn;
          my $cnt = $cn->node_type;
          if ($cnt == 1) {
            my $cn_nsuri = $cn->namespace_uri;
            $cn_nsuri = '' unless defined $cn_nsuri;
            if ($cn_nsuri eq $HTML_NS and $cn->manakai_local_name eq 'source') {
              #
            } else {
              last CN;
            }
          } elsif ($cnt == 3 or $cnt == 4) {
            if ($cn->data =~ /[^\x09-\x0D\x20]/) {
              last CN;
            }
          }
        } # CN
        unshift @$sib, @cn;
      }
    } elsif ($node_ns eq $HTML_NS and $node_ln eq 'object') {
      my @cn = @{$node->child_nodes};
      CN: while (@cn) {
        my $cn = shift @cn;
        my $cnt = $cn->node_type;
        if ($cnt == 1) {
          my $cn_nsuri = $cn->namespace_uri;
          $cn_nsuri = '' unless defined $cn_nsuri;
          if ($cn_nsuri eq $HTML_NS and $cn->manakai_local_name eq 'param') {
            #
          } else {
            last CN;
          }
        } elsif ($cnt == 3 or $cnt == 4) {
          if ($cn->data =~ /[^\x09-\x0D\x20]/) {
            last CN;
          }
        }
      } # CN
      unshift @$sib, @cn;
    }
    push @$new_todos, {type => 'element', node => $node};
  } # TP
  
  for my $new_todo (@$new_todos) {
    $new_todo->{flag} = {%{$parent_todo->{flag} or {}}};
  }
  
  return ($sib, $new_todos);
} # _check_get_children

=head1 LICENSE

Copyright 2007-2008 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2008/02/23 10:35:00 $
