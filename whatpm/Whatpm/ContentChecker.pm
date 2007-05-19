package Whatpm::ContentChecker;
use strict;

## ISSUE: How XML and XML Namespaces conformance can (or cannot)
## be applied to an in-memory representation (i.e. DOM)?

my $XML_NS = q<http://www.w3.org/XML/1998/namespace>;
my $XMLNS_NS = q<http://www.w3.org/2000/xmlns/>;

my $AttrChecker = {
  $XML_NS => {
    space => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value eq 'default' or $value eq 'preserve') {
        #
      } else {
        ## NOTE: An XML "error"
        $self->{onerror}->(node => $attr,
                           type => 'XML error:invalid xml:space value');
      }
    },
    lang => sub {
      ## NOTE: "The values of the attribute are language identifiers
      ## as defined by [IETF RFC 3066], Tags for the Identification
      ## of Languages, or its successor; in addition, the empty string
      ## may be specified." ("may" in lower case)
      ## TODO: xml:lang MUST NOT in HTML document
    },
    base => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value =~ /[^\x{0000}-\x{10FFFF}]/) { ## ISSUE: Should we disallow noncharacters?
        $self->{onerror}->(node => $attr,
                           type => 'syntax error');
      }
      ## NOTE: Conformance to URI standard is not checked.
    },
    id => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      $value =~ s/[\x09\x0A\x0D\x20]+/ /g;
      $value =~ s/^\x20//;
      $value =~ s/\x20$//;
      ## TODO: NCName in XML 1.0 or 1.1
      ## TODO: declared type is ID?
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'xml:id error:duplicate ID');
      } else {
        $self->{id}->{$value} = 1;
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
          ->(node => $attr,
             type => 'NC:Reserved Prefixes and Namespace Names:=xml');
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'NC:Reserved Prefixes and Namespace Names:=xmlns');
      }
      if ($ln eq 'xml' and $value ne $XML_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'NC:Reserved Prefixes and Namespace Names:xmlns:xml=');
      } elsif ($ln eq 'xmlns') {
        $self->{onerror}
          ->(node => $attr,
             type => 'NC:Reserved Prefixes and Namespace Names:xmlns:xmlns=');
      }
      ## TODO: If XML 1.0 and empty
    },
    xmlns => sub {
      my ($self, $attr) = @_;
      ## TODO: In XML 1.0, URI reference [RFC 3986] or an empty string
      ## TODO: In XML 1.1, IRI reference [RFC 3987] or an empty string
      my $value = $attr->value;
      if ($value eq $XML_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'NC:Reserved Prefixes and Namespace Names:=xml');
      } elsif ($value eq $XMLNS_NS) {
        $self->{onerror}
          ->(node => $attr,
             type => 'NC:Reserved Prefixes and Namespace Names:=xmlns');
      }
    },
  },
};

$AttrChecker->{''}->{'xml:space'} = $AttrChecker->{$XML_NS}->{space};
$AttrChecker->{''}->{'xml:lang'} = $AttrChecker->{$XML_NS}->{lang};
$AttrChecker->{''}->{'xml:base'} = $AttrChecker->{$XML_NS}->{base};
$AttrChecker->{''}->{'xml:id'} = $AttrChecker->{$XML_NS}->{id};

## ANY
my $AnyChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      push @$new_todos, {type => 'element', node => $node};
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($new_todos);
}; # $AnyChecker

my $ElementDefault = {
  checker => sub {
    my ($self, $todo) = @_;
    $self->{onerror}->(node => $todo->{node}, type => 'element not supported');
    return $AnyChecker->($self, $todo);
  },
  attrs_checker => sub {
    my ($self, $todo) = @_;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker = $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr);
      }
      ## Don't check otherwise, since "element type not supported" warning
      ## will be reported by the element checker.
    }
  },
};

my $Element = {};

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;

my $HTMLMetadataElements = {
  $HTML_NS => {
    qw/link 1 meta 1 style 1 script 1 event-source 1 command 1 base 1 title 1/,
  },
};

my $HTMLSectioningElements = {
  $HTML_NS => {qw/body 1 section 1 nav 1 article 1 blockquote 1 aside 1/},
};

my $HTMLBlockLevelElements = {
  $HTML_NS => {
    qw/
      section 1 nav 1 article 1 blockquote 1 aside 1 
      h1 1 h2 1 h3 1 h4 1 h5 1 h6 1 header 1 footer 1
      address 1 p 1 hr 1 dialog 1 pre 1 ol 1 ul 1 dl 1
      ins 1 del 1 figure 1 map 1 table 1 script 1 noscript 1
      event-source 1 details 1 datagrid 1 menu 1 div 1 font 1
    /,
  },
};

my $HTMLStrictlyInlineLevelElements = {
  $HTML_NS => {
    qw/
      br 1 a 1 q 1 cite 1 em 1 strong 1 small 1 m 1 dfn 1 abbr 1
      time 1 meter 1 progress 1 code 1 var 1 samp 1 kbd 1
      sub 1 sup 1 span 1 i 1 b 1 bdo 1 ins 1 del 1 img 1
      iframe 1 embed 1 object 1 video 1 audio 1 canvas 1 area 1
      script 1 noscript 1 event-source 1 command 1 font 1
    /,
  },
};

my $HTMLStructuredInlineLevelElements = {
  $HTML_NS => {qw/blockquote 1 pre 1 ol 1 ul 1 dl 1 table 1 menu 1/},
};

my $HTMLInteractiveElements = {
  $HTML_NS => {a => 1, details => 1, datagrid => 1},
};
## NOTE: |html:a| and |html:datagrid| are not allowed as a descendant
## of interactive elements

my $HTMLTransparentElements = {
  $HTML_NS => {qw/ins 1 font 1 noscript 1/},
  ## NOTE: |html:noscript| is transparent if scripting is disabled.
};

#my $HTMLSemiTransparentElements = {
#  $HTML_NS => {qw/video 1 audio 1/},
#};

my $HTMLEmbededElements = {
  $HTML_NS => {qw/img 1 iframe 1 embed 1 object 1 video 1 audio 1 canvas 1/},
};

## Empty
my $HTMLEmptyChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});

  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      ## NOTE: |minuses| list is not checked since redundant
      $self->{onerror}->(node => $node, type => 'element not allowed');
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $node, type => 'character not allowed');
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($new_todos);
};

## Text
my $HTMLTextChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});

  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      ## NOTE: |minuses| list is not checked since redundant
      $self->{onerror}->(node => $node, type => 'element not allowed');
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($new_todos);
};

## Zero or more |html:style| elements,
## followed by zero or more block-level elements
my $HTMLStylableBlockChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  
  my $has_non_style;
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      if ($node_ns eq $HTML_NS and $node_ln eq 'style') {
        $not_allowed = 1 if $has_non_style;
      } elsif ($HTMLBlockLevelElements->{$node_ns}->{$node_ln}) {
        $has_non_style = 1;
      } else {
        $has_non_style = 1;
        $not_allowed = 1;
      }
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $node, type => 'character not allowed');
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($new_todos);
}; # $HTMLStylableBlockChecker

## Zero or more block-level elements
my $HTMLBlockChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH'; 

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      $not_allowed = 1
        unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $node, type => 'character not allowed');
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($new_todos);
}; # $HTMLBlockChecker

## Inline-level content
my $HTMLInlineChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      $not_allowed = 1
        unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
          $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }

  for (@$new_todos) {
    $_->{inline} = 1;
  }
  return ($new_todos);
}; # $HTMLInlineChecker

my $HTMLSignificantInlineChecker = $HTMLInlineChecker;
## TODO: check significant content

## Strictly inline-level content
my $HTMLStrictlyInlineChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      $not_allowed = 1
        unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln};
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }

  for (@$new_todos) {
    $_->{inline} = 1;
    $_->{strictly_inline} = 1;
  }
  return ($new_todos);
}; # $HTMLStrictlyInlineChecker

my $HTMLSignificantStrictlyInlineChecker = $HTMLStrictlyInlineChecker;
## TODO: check significant content

## Inline-level or strictly inline-kevek content
my $HTMLInlineOrStrictlyInlineChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      if ($todo->{strictly_inline}) {
        $not_allowed = 1
          unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln};
      } else {
        $not_allowed = 1
          unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
            $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
      }
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }

  for (@$new_todos) {
    $_->{inline} = 1;
    $_->{strictly_inline} = 1;
  }
  return ($new_todos);
}; # $HTMLInlineOrStrictlyInlineChecker

my $HTMLSignificantInlineOrStrictlyInlineChecker
    = $HTMLInlineOrStrictlyInlineChecker;
## TODO: check significant content

my $HTMLBlockOrInlineChecker = sub {
  my ($self, $todo) = @_;
  my $el = $todo->{node};
  my $new_todos = [];
  my @nodes = (@{$el->child_nodes});
  
  my $content = 'block-or-inline'; # or 'block' or 'inline'
  my @block_not_inline;
  while (@nodes) {
    my $node = shift @nodes;
    $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      if ($content eq 'block') {
        $not_allowed = 1
          unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
      } elsif ($content eq 'inline') {
        $not_allowed = 1
          unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
            $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
      } else {
        my $is_block = $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
        my $is_inline
          = $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} ||
            $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
        
        push @block_not_inline, $node
          if $is_block and not $is_inline and not $not_allowed;
        unless ($is_block) {
          $content = 'inline';
          for (@block_not_inline) {
            $self->{onerror}->(node => $_, type => 'element not allowed');
          }
          $not_allowed = 1 unless $is_inline;
        }
      }
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node);
      unshift @nodes, @$sib;
      push @$new_todos, @$ch;
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        if ($content eq 'block') {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        } else {
          $content = 'inline';
          for (@block_not_inline) {
            $self->{onerror}->(node => $_, type => 'element not allowed');
          }
        }
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }

  if ($content eq 'inline') {
    for (@$new_todos) {
      $_->{inline} = 1;
    }
  }
  return ($new_todos);
};

## Zero or more XXX element, then either block-level or inline-level
my $GetHTMLZeroOrMoreThenBlockOrInlineChecker = sub ($$) {
  my ($elnsuri, $ellname) = @_;
  return sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});
    
    my $has_non_style;
    my $content = 'block-or-inline'; # or 'block' or 'inline'
    my @block_not_inline;
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
        if ($node_ns eq $elnsuri and $node_ln eq $ellname) {
          $not_allowed = 1 if $has_non_style;
        } elsif ($content eq 'block') {
          $has_non_style = 1;
          $not_allowed = 1
            unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
        } elsif ($content eq 'inline') {
          $has_non_style = 1;
          $not_allowed = 1
            unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
        } else {
          $has_non_style = 1;
          my $is_block = $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
          my $is_inline
            = $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} ||
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
            
          push @block_not_inline, $node
            if $is_block and not $is_inline and not $not_allowed;
          unless ($is_block) {
            $content = 'inline';
            for (@block_not_inline) {
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
            $not_allowed = 1 unless $is_inline;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $has_non_style = 1;
          if ($content eq 'block') {
            $self->{onerror}->(node => $node, type => 'character not allowed');
          } else {
            $content = 'inline';
            for (@block_not_inline) {
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
          }
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    if ($content eq 'inline') {
      for (@$new_todos) {
        $_->{inline} = 1;
      }
    }
    return ($new_todos);
  };
}; # $GetHTMLZeroOrMoreThenBlockOrInlineChecker

my $HTMLTransparentChecker = $HTMLBlockOrInlineChecker;

my $GetHTMLEnumeratedAttrChecker = sub {
  my $states = shift; # {value => conforming ? 1 : -1}
  return sub {
    my ($self, $attr) = @_;
    my $value = lc $attr->value; ## TODO: ASCII case insensitibility?
    if ($states->{$value} > 0) {
      #
    } elsif ($states->{$value}) {
      $self->{onerror}->(node => $attr,
                         type => 'non-conforming enumerated attribute value');
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'invalid enumerated attribute value');
    }
  };
}; # $GetHTMLEnumeratedAttrChecker

my $GetHTMLBooleanAttrChecker = sub {
  my $local_name = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    unless ($value eq $local_name or $value eq '') {
      $self->{onerror}->(node => $attr,
                         type => 'invalid boolean attribute value');
    }
  };
}; # $GetHTMLBooleanAttrChecker

my $HTMLUnorderedSetOfSpaceSeparatedTokensAttrChecker = sub {
  my ($self, $attr) = @_;
  my %word;
  for my $word (grep {length $_} split /[\x09-\x0D\x20]/, $attr->value) {
    unless ($word{$word}) {
      $word{$word} = 1;
    } else {
      $self->{onerror}->(node => $attr, type => 'duplicate token:'.$word);
    }
  }
}; # $HTMLUnorderedSetOfSpaceSeparatedTokensAttrChecker

my $HTMLURIAttrChecker = sub {
  my ($self, $attr) = @_;
  ## TODO: URI or IRI check
}; # $HTMLURIAttrChecker

my $HTMLIntegerAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  unless ($value =~ /\A-?[0-9]+\z/) {
    $self->{onerror}->(node => $attr, type => 'syntax error');
  }
}; # $HTMLIntegerAttrChecker

my $GetHTMLNonNegativeIntegerAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A[0-9]+\z/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'out of range');
      }
    } else {
      $self->{onerror}->(node => $attr, type => 'syntax error');
    }
  };
}; # $GetHTMLNonNegativeIntegerAttrChecker

my $GetHTMLFloatingPointNumberAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A-?[0-9.]+\z/ and $value =~ /[0-9]/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'out of range');
      }
    } else {
      $self->{onerror}->(node => $attr, type => 'syntax error');
    }
  };
}; # $GetHTMLFloatingPointNumberAttrChecker

my $HTMLAttrChecker = {
  id => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    unless (length $value > 0) {
      ## NOTE: MUST contain at least one character
      $self->{onerror}->(node => $attr, type => 'attribute value is empty');
    } else {
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'duplicate ID');
      } else {
        $self->{id}->{$value} = 1;
      }
    }
  },
  title => sub {}, ## NOTE: No conformance creteria
  lang => sub {
    ## TODO: RFC 3066 test
    ## ISSUE: RFC 4646 (3066bis)?
    ## TODO: HTML vs XHTML
  },
  dir => $GetHTMLEnumeratedAttrChecker->({ltr => 1, rtl => 1}),
  class => $HTMLUnorderedSetOfSpaceSeparatedTokensAttrChecker,
  irrelevant => $GetHTMLBooleanAttrChecker->('irrelevant'),
  ## TODO: tabindex
};

my $GetHTMLAttrsChecker = sub {
  my $element_specific_checker = shift;
  return sub {
    my ($self, $todo) = @_;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = $element_specific_checker->{$attr_ln}
          || $HTMLAttrChecker->{$attr_ln};
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr);
      } else {
        $self->{onerror}->(node => $attr, type => 'attribute not supported');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }
    }
  };
}; # $GetHTMLAttrsChecker

$Element->{$HTML_NS}->{''} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $ElementDefault->{checker},
};

$Element->{$HTML_NS}->{html} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    xmlns => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ($value eq $HTML_NS) {
        $self->{onerror}->(node => $attr, type => 'syntax error');
        ## TODO: only in HTML documents
      }
    },
  }),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before head';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
        if ($phase eq 'before head') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'head') {
            $phase = 'after head';            
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'body') {
            $self->{onerror}->(node => $node, type => 'ps element missing:head');
            $phase = 'after body';
          } else {
            $not_allowed = 1;
            # before head
          }
        } elsif ($phase eq 'after head') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'body') {
            $phase = 'after body';
          } else {
            $not_allowed = 1;
            # after head
          }
        } else { #elsif ($phase eq 'after body') {
          $not_allowed = 1;
          # after body
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    if ($phase eq 'before head') {
      $self->{onerror}->(node => $el, type => 'child element missing:head');
      $self->{onerror}->(node => $el, type => 'child element missing:body');
    } elsif ($phase eq 'after head') {
      $self->{onerror}->(node => $el, type => 'child element missing:body');
    }

    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{head} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $has_title;
    my $phase = 'initial'; # 'after charset', 'after base'
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
        if ($node_ns eq $HTML_NS and $node_ln eq 'title') {
          $phase = 'after base';
          unless ($has_title) {
            $has_title = 1;
          } else {
            $not_allowed = 1;
          }
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'meta') {
          if ($node->has_attribute_ns (undef, 'charset')) {
            if ($phase eq 'initial') {
              $phase = 'after charset';
            } else {
              $not_allowed = 1;
              ## NOTE: See also |base|'s "contexts" field in the spec
            }
          } else {
            $phase = 'after base';
          }
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'base') {
          if ($phase eq 'initial' or $phase eq 'after charset') {
            $phase = 'after base';
          } else {
            $not_allowed = 1;
          }
        } elsif ($HTMLMetadataElements->{$node_ns}->{$node_ln}) {
          $phase = 'after base';
        } else {
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_title) {
      $self->{onerror}->(node => $el, type => 'child element missing:title');
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{title} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLTextChecker,
};

$Element->{$HTML_NS}->{base} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    href => $HTMLURIAttrChecker,
    ## TODO: target
  }),
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{link} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{meta} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    my $name_attr;
    my $http_equiv_attr;
    my $charset_attr;
    my $content_attr;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        if ($attr_ln eq 'content') {
          $content_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'name') {
          $name_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'http-equiv') {
          $http_equiv_attr = $attr;
          $checker = 1;
        } elsif ($attr_ln eq 'charset') {
          $charset_attr = $attr;
          $checker = 1;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln}
            || $AttrChecker->{$attr_ns}->{$attr_ln}
              || $AttrChecker->{$attr_ns}->{''};
        }
      } else {
        $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
          || $AttrChecker->{$attr_ns}->{''};
      }
      if ($checker) {
        $checker->($self, $attr) if ref $checker;
      } else {
        $self->{onerror}->(node => $attr, type => 'attribute not supported');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }
    }
    
    if (defined $name_attr) {
      if (defined $http_equiv_attr) {
        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'attribute not allowed');
      } elsif (defined $charset_attr) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'attribute not allowed');
      }
      my $metadata_name = $name_attr->value;
      my $metadata_value;
      if (defined $content_attr) {
        $metadata_value = $content_attr->value;
      } else {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:content');
        $metadata_value = '';
      }
    } elsif (defined $http_equiv_attr) {
      if (defined $charset_attr) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'attribute not allowed');
      }
      unless (defined $content_attr) {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:content');
      }
    } elsif (defined $charset_attr) {
      if (defined $content_attr) {
        $self->{onerror}->(node => $content_attr,
                           type => 'attribute not allowed');
      }
      ## TODO: Allowed only in HTML documents
    } else {
      if (defined $content_attr) {
        $self->{onerror}->(node => $content_attr,
                           type => 'attribute not allowed');
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:name|http-equiv');
      } else {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:name|http-equiv|charset');
      }
    }

    ## TODO: metadata conformance

    ## TODO: pragma conformance
    if (defined $http_equiv_attr) { ## An enumerated attribute
      my $keyword = lc $http_equiv_attr->value; ## TODO: ascii case?
      if ({
           'refresh' => 1,
           'default-style' => 1,
          }->{$keyword}) {
        #
      } else {
        $self->{onerror}->(node => $http_equiv_attr,
                           type => 'invalid enumerated attribute value');
      }
    }

    ## TODO: charset
  },
  checker => $HTMLEmptyChecker,
};

## NOTE: |html:style| has no conformance creteria on content model
$Element->{$HTML_NS}->{style} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    ## TODO: type
    ## TODO: media
    scoped => $GetHTMLBooleanAttrChecker->('scoped'),
    ## NOTE: |title| has special semantics for |style|s, but is syntactically
    ## not different
  }),
  checker => $AnyChecker,
};

$Element->{$HTML_NS}->{body} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{section} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStylableBlockChecker,
};

$Element->{$HTML_NS}->{nav} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{article} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStylableBlockChecker,
};

$Element->{$HTML_NS}->{blockquote} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }),
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{aside} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'style'),
};

$Element->{$HTML_NS}->{h1} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h2} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h3} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h4} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h5} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h6} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

## TODO: header

$Element->{$HTML_NS}->{footer} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub { ## block -hn -header -footer -sectioning or inline
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});
  
    my $content = 'block-or-inline'; # or 'block' or 'inline'
    my @block_not_inline;
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;  
        my $node_ln = $node->manakai_local_name;
        my $not_allowed;
        if ($self->{minuses}->{$node_ns}->{$node_ln}) {
          $not_allowed = 1;
        } elsif ($node_ns eq $HTML_NS and
                 {
                   qw/h1 1 h2 1 h3 1 h4 1 h5 1 h6 1 header 1 footer 1/
                 }->{$node_ln}) {
          $not_allowed = 1;
        } elsif ($HTMLSectioningElements->{$node_ns}->{$node_ln}) {
          $not_allowed = 1;
        }
        if ($content eq 'block') {
          $not_allowed = 1
            unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
        } elsif ($content eq 'inline') {
          $not_allowed = 1
            unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
        } else {
          my $is_block = $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
          my $is_inline
            = $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} ||
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
          
          push @block_not_inline, $node
            if $is_block and not $is_inline and not $not_allowed;
          unless ($is_block) {
            $content = 'inline';
            for (@block_not_inline) {
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
            $not_allowed = 1 unless $is_inline;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          if ($content eq 'block') {
            $self->{onerror}->(node => $node, type => 'character not allowed');
          } else {
            $content = 'inline';
            for (@block_not_inline) {
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
          }
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    my $end = $self->_add_minuses
      ({$HTML_NS => {qw/h1 1 h2 1 h3 1 h4 1 h5 1 h6 1/}},
       $HTMLSectioningElements);
    push @$new_todos, $end;

    if ($content eq 'inline') {
      for (@$new_todos) {
        $_->{inline} = 1;
      }
    }

    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{address} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLInlineChecker,
};

$Element->{$HTML_NS}->{p} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantInlineChecker,
};

$Element->{$HTML_NS}->{hr} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{br} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{dialog} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before dt';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        if ($phase eq 'before dt') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'dt') {
            $phase = 'before dd';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'dd') {
            $self->{onerror}
              ->(node => $node, type => 'ps element missing:dt');
            $phase = 'before dt';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } else { # before dd
          if ($node_ns eq $HTML_NS and $node_ln eq 'dd') {
            $phase = 'before dt';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'dt') {
            $self->{onerror}
              ->(node => $node, type => 'ps element missing:dd');
            $phase = 'before dd';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    if ($phase eq 'before dd') {
      $self->{onerror}->(node => $el, type => 'ps element missing:dd');
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{pre} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{ol} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    start => $HTMLIntegerAttrChecker,
  }),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        unless ($node_ns eq $HTML_NS and $node_ln eq 'li') {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    if ($todo->{inline}) {
      for (@$new_todos) {
        $_->{inline} = 1;
      }
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{ul} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{ol}->{checker},
};


$Element->{$HTML_NS}->{li} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    start => sub {
      my ($self, $attr) = @_;
      my $parent = $attr->owner_element->manakai_parent_element;
      if (defined $parent) {
        my $parent_ns = $parent->namespace_uri;
        $parent_ns = '' unless defined $parent_ns;
        my $parent_ln = $parent->manakai_local_name;
        unless ($parent_ns eq $HTML_NS and $parent_ln eq 'ol') {
          $self->{onerror}->(node => $attr, type => 'attribute not supported');
        }
      }
      $HTMLIntegerAttrChecker->($self, $attr);
    },
  }),
  checker => sub {
    my ($self, $todo) = @_;
    if ($todo->{inline}) {
      return $HTMLInlineChecker->($self, $todo);
    } else {
      return $HTMLBlockOrInlineChecker->($self, $todo);
    }
  },
};

$Element->{$HTML_NS}->{dl} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before dt';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        if ($phase eq 'in dds') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'dd') {
            #$phase = 'in dds';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'dt') {
            $phase = 'in dts';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in dts') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'dt') {
            #$phase = 'in dts';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'dd') {
            $phase = 'in dds';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } else { # before dt
          if ($node_ns eq $HTML_NS and $node_ln eq 'dt') {
            $phase = 'in dts';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'dd') {
            $self->{onerror}
              ->(node => $node, type => 'ps element missing:dt');
            $phase = 'in dds';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    if ($phase eq 'in dts') {
      $self->{onerror}->(node => $el, type => 'ps element missing:dd');
    }

    if ($todo->{inline}) {
      for (@$new_todos) {
        $_->{inline} = 1;
      }
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{dt} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{dd} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{li}->{checker},
};

$Element->{$HTML_NS}->{a} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ($HTMLInteractiveElements);
    my ($sib, $ch)
      = $HTMLSignificantInlineOrStrictlyInlineChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

$Element->{$HTML_NS}->{q} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
  }),
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{cite} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{em} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{strong} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{small} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{m} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{dfn} = { ## TODO: term duplication
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {dfn => 1}});
    my ($sib, $ch) = $HTMLStrictlyInlineChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

$Element->{$HTML_NS}->{abbr} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    ## NOTE: |title| has special semantics for |abbr|s, but is syntactically
    ## not different.  The spec says that the |title| MAY be omitted
    ## if there is a |dfn| whose defining term is the abbreviation,
    ## but it does not prohibit |abbr| w/o |title| in other cases.
  }),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{time} = { ## TODO: validate content
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO: datetime
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{meter} = { ## TODO: "The recommended way of giving the value is to include it as contents of the element"
  attrs_checker => $GetHTMLAttrsChecker->({
    value => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    min => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    low => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    high => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    max => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
    optimum => $GetHTMLFloatingPointNumberAttrChecker->(sub { 1 }),
  }),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{progress} = { ## TODO: recommended to use content
  attrs_checker => $GetHTMLAttrsChecker->({
    value => $GetHTMLFloatingPointNumberAttrChecker->(sub { shift >= 0 }),
    max => $GetHTMLFloatingPointNumberAttrChecker->(sub { shift > 0 }),
  }),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{code} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  ## NOTE: Though |title| has special semantics,
  ## syntatically same as the |title| as global attribute.
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{var} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  ## NOTE: Though |title| has special semantics,
  ## syntatically same as the |title| as global attribute.
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{samp} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  ## NOTE: Though |title| has special semantics,
  ## syntatically same as the |title| as global attribute.
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{kbd} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{sub} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{sup} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{span} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  ## NOTE: Though |title| has special semantics,
  ## syntatically same as the |title| as global attribute.
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{i} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  ## NOTE: Though |title| has special semantics,
  ## syntatically same as the |title| as global attribute.
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{b} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{bdo} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    $GetHTMLAttrsChecker->({})->($self, $todo);
    unless ($todo->{node}->has_attribute_ns (undef, 'dir')) {
      $self->{onerror}->(node => $todo->{node}, type => 'attribute missing:dir');
    }
  },
  ## ISSUE: The spec does not directly say that |dir| is a enumerated attr.
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{ins} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    ## TODO: datetime
  }),
  checker => $HTMLTransparentChecker,
};

$Element->{$HTML_NS}->{del} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    ## TODO: datetime
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my $parent = $todo->{node}->manakai_parent_element;
    if (defined $parent) {
      my $nsuri = $parent->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      my $ln = $parent->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
        $ElementDefault;
      return $eldef->{checker}->($self, $todo);
    } else {
      return $HTMLBlockOrInlineChecker->($self, $todo);
    }
  },
};

## TODO: figure

$Element->{$HTML_NS}->{img} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{iframe} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }),
  checker => $HTMLTextChecker,
};

$Element->{$HTML_NS}->{embed} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{param} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    $GetHTMLAttrsChecker->({
      name => sub { },
      value => sub { },
    })->($self, $todo);
    unless ($todo->{node}->has_attribute_ns (undef, 'name')) {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:name');
    }
    unless ($todo->{node}->has_attribute_ns (undef, 'value')) {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:value');
    }
  },
  checker => $HTMLEmptyChecker,
};

## TODO: object

$Element->{$HTML_NS}->{video} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
    ## TODO: start, loopstart, loopend, end
    ## ISSUE: they MUST be "value time offset"s.  Value?
    ## ISSUE: loopcount has no conformance creteria
    autoplay => $GetHTMLBooleanAttrChecker->('autoplay'),
    controls => $GetHTMLBooleanAttrChecker->('controls'),
  }),
  checker => sub {
    my ($self, $todo) = @_;

    if ($todo->{node}->has_attribute_ns (undef, 'src')) {
      return $HTMLBlockOrInlineChecker->($self, $todo);
    } else {
      return $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'source')
        ->($self, $todo);
    }
  },
};

$Element->{$HTML_NS}->{audio} = {
  attrs_checker => $Element->{$HTML_NS}->{video}->{attrs_checker},
  checker => $Element->{$HTML_NS}->{video}->{checker},
};

$Element->{$HTML_NS}->{source} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{canvas} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    height => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
    width => $GetHTMLNonNegativeIntegerAttrChecker->(sub { 1 }),
  }),
  checker => $HTMLInlineChecker,
};

$Element->{$HTML_NS}->{map} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{area} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLEmptyChecker,
};
## TODO: only in map

$Element->{$HTML_NS}->{table} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before caption';
    my $has_tfoot;
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        if ($phase eq 'in tbodys') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'tbody') {
            #$phase = 'in tbodys';
          } elsif (not $has_tfoot and
                   $node_ns eq $HTML_NS and $node_ln eq 'tfoot') {
            $phase = 'after tfoot';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in trs') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'tr') {
            #$phase = 'in trs';
          } elsif (not $has_tfoot and
                   $node_ns eq $HTML_NS and $node_ln eq 'tfoot') {
            $phase = 'after tfoot';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'after thead') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'tbody') {
            $phase = 'in tbodys';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tr') {
            $phase = 'in trs';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tfoot') {
            $phase = 'in tbodys';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in colgroup') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'colgroup') {
            $phase = 'in colgroup';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'thead') {
            $phase = 'after thead';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tbody') {
            $phase = 'in tbodys';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tr') {
            $phase = 'in trs';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tfoot') {
            $phase = 'in tbodys';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'before caption') {
          if ($node_ns eq $HTML_NS and $node_ln eq 'caption') {
            $phase = 'in colgroup';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'colgroup') {
            $phase = 'in colgroup';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'thead') {
            $phase = 'after thead';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tbody') {
            $phase = 'in tbodys';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tr') {
            $phase = 'in trs';
          } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tfoot') {
            $phase = 'in tbodys';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } else { # after tfoot
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{caption} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{colgroup} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        unless ($node_ns eq $HTML_NS and $node_ln eq 'col') {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{col} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
  }),
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{tbody} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $has_tr;
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        if ($node_ns eq $HTML_NS and $node_ln eq 'tr') {
          $has_tr = 1;
        } else {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_tr) {
      $self->{onerror}->(node => $el, type => 'child element missing:tr');
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{thead} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{tbody},
};

$Element->{$HTML_NS}->{tfoot} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{tbody},
};

$Element->{$HTML_NS}->{tr} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $has_td;
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        ## NOTE: |minuses| list is not checked since redundant
        if ($node_ns eq $HTML_NS and ($node_ln eq 'td' or $node_ln eq 'th')) {
          $has_td = 1;
        } else {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_td) {
      $self->{onerror}->(node => $el, type => 'child element missing:td|th');
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{td} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
  }),
  checker => $HTMLBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{th} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    colspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    rowspan => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
    scope => $GetHTMLEnumeratedAttrChecker
        ->({row => 1, col => 1, rowgroup => 1, colgroup => 1}),
  }),
  checker => $HTMLBlockOrInlineChecker,
};

## TODO: table model error checking

## TODO: forms

$Element->{$HTML_NS}->{script} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => sub {
    my ($self, $todo) = @_;

    if ($todo->{node}->has_attribute_ns (undef, 'src')) {
      return $HTMLEmptyChecker->($self, $todo);
    } else {
      ## NOTE: No content model conformance in HTML5 spec.
      return $AnyChecker->($self, $todo);
    }
  },
};

## NOTE: When script is disabled.
$Element->{$HTML_NS}->{noscript} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {noscript => 1}});
    my ($sib, $ch) = $HTMLBlockOrInlineChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

$Element->{$HTML_NS}->{'event-source'} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }),
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{details} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    open => $GetHTMLBooleanAttrChecker->('open'),
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {a => 1, datagrid => 1}});
    my ($sib, $ch)
      = $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'legend')
        ->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

$Element->{$HTML_NS}->{datagrid} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    multiple => $GetHTMLBooleanAttrChecker->('multiple'),
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {a => 1, datagrid => 1}});
    my ($sib, $ch) = $HTMLBlockChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

$Element->{$HTML_NS}->{command} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{menu} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => sub {
    my ($self, $todo) = @_;
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});
    
    my $content = 'li or inline';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';

      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
        if ($node_ns eq $HTML_NS and $node_ln eq 'li') {
          if ($content eq 'inline') {
            $not_allowed = 1;
          } elsif ($content eq 'li or inline') {
            $content = 'li';
          }
        } else {
          if ($HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln}) {
            $content = 'inline';
          } else {
            $not_allowed = 1;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          if ($content eq 'li') {
            $self->{onerror}->(node => $node, type => 'character not allowed');
          } elsif ($content eq 'li or inline') {
            $content = 'inline';
          }
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    for (@$new_todos) {
      $_->{inline} = 1;
    }
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{legend} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my $parent = $todo->{node}->manakai_parent_element;
    if (defined $parent) {
      my $nsuri = $parent->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      my $ln = $parent->manakai_local_name;
      if ($nsuri eq $HTML_NS and $ln eq 'figure') {
        return $HTMLInlineChecker->($self, $todo);
      } else {
        return $HTMLSignificantStrictlyInlineChecker->($self, $todo);
      }
    } else {
      return $HTMLInlineChecker->($self, $todo);
    }

    ## ISSUE: Content model is defined only for fieldset/legend,
    ## details/legend, and figure/legend.
  },
};

$Element->{$HTML_NS}->{div} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'style'),
};

$Element->{$HTML_NS}->{font} = {
  attrs_checker => $GetHTMLAttrsChecker->({}), ## TODO
  checker => $HTMLTransparentChecker,
};

sub new ($) {
  return bless {}, shift;
} # new

sub check_element ($$$) {
  my ($self, $el, $onerror) = @_;

  $self->{minuses} = {};
  $self->{onerror} = $onerror;
  $self->{id} = {};

  my @todo = ({type => 'element', node => $el});
  while (@todo) {
    my $todo = shift @todo;
    if ($todo->{type} eq 'element') {
      my $prefix = $todo->{node}->prefix;
      if (defined $prefix and $prefix eq 'xmlns') {
        $self->{onerror}
          ->(node => $todo->{node},
             type => 'NC:Reserved Prefixes and Namespace Names:<xmlns:>');
      }
      my $nsuri = $todo->{node}->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      my $ln = $todo->{node}->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
          $ElementDefault;
      $eldef->{attrs_checker}->($self, $todo);
      my ($new_todos) = $eldef->{checker}->($self, $todo);
      push @todo, @$new_todos;
    } elsif ($todo->{type} eq 'element-attributes') {
      my $prefix = $todo->{node}->prefix;
      if (defined $prefix and $prefix eq 'xmlns') {
        $self->{onerror}
          ->(node => $todo->{node},
             type => 'NC:Reserved Prefixes and Namespace Names:<xmlns:>');
      }
      my $nsuri = $todo->{node}->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      my $ln = $todo->{node}->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
          $ElementDefault;
      $eldef->{attrs_checker}->($self, $todo);
    } elsif ($todo->{type} eq 'plus') {
      $self->_remove_minuses ($todo);
    }
  }
} # check_element

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

sub _remove_minuses ($$) {
  my ($self, $todo) = @_;
  for my $ns (keys %{$todo->{list}}) {
    for my $ln (keys %{$todo->{list}->{$ns}}) {
      delete $self->{minuses}->{$ns}->{$ln} if $todo->{list}->{$ns}->{$ln};
    }
  }
  1;
} # _remove_minuses

sub _check_get_children ($$) {
  my ($self, $node) = @_;
  my $new_todos = [];
  my $sib = [];
  TP: {
    my $node_ns = $node->namespace_uri;
    $node_ns = '' unless defined $node_ns;
    my $node_ln = $node->manakai_local_name;
    if ($node_ns eq $HTML_NS) {
      if ($node_ln eq 'noscript') {
        my $end = $self->_add_minuses ({$HTML_NS, {noscript => 1}});
        push @$sib, $end;
      }
    }
    if ($HTMLTransparentElements->{$node_ns}->{$node_ln}) {
      unshift @$sib, @{$node->child_nodes};
      push @$new_todos, {type => 'element-attributes', node => $node};
      last TP;
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
    }
    push @$new_todos, {type => 'element', node => $node};
  } # TP
  return ($sib, $new_todos);
} # _check_get_children

1;
# $Date: 2007/05/19 14:29:09 $
