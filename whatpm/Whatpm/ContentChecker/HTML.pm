package Whatpm::ContentChecker;
use strict;
require Whatpm::ContentChecker;

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;

my $HTMLMetadataElements = {
  $HTML_NS => {
    qw/link 1 meta 1 style 1 script 1 event-source 1 command 1 base 1 title 1
       noscript 1 datatemplate 1
      /,
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
      datatemplate 1
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

# my $HTMLTransparentElements : in |Whatpm/ContentChecker.pm|.

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
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      if ($self->{pluses}->{$node_ns}->{$node_ln}) {
        #
      } else {
        ## NOTE: |minuses| list is not checked since redundant
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      if ($self->{pluses}->{$node_ns}->{$node_ln}) {
        #
      } else {
        ## NOTE: |minuses| list is not checked since redundant
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
        $not_allowed = 1 if $has_non_style or
            not $node->has_attribute_ns (undef, 'scoped');
      } elsif ($HTMLBlockLevelElements->{$node_ns}->{$node_ln}) {
        $has_non_style = 1;
      } elsif ($self->{pluses}->{$node_ns}->{$node_ln}) {
        #
      } else {
        $has_non_style = 1;
        $not_allowed = 1;
      }
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
        unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln} or
            $self->{pluses}->{$node_ns}->{$node_ln};
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
            $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln} or
            $self->{pluses}->{$node_ns}->{$node_ln};
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
        unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
            $self->{pluses}->{$node_ns}->{$node_ln};
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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

## Inline-level or strictly inline-level content
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
          unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
              $self->{pluses}->{$node_ns}->{$node_ln};
      } else {
        $not_allowed = 1
          unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln} or
              $self->{pluses}->{$node_ns}->{$node_ln};
      }
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
## TODO: "siginificant" concept has been gone.
## Instead, we have another SHOULD-level requirement (revision 1114).

## Block-level content or inline-level content (i.e. bimorphic content model)
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

    ## ISSUE: It is unclear whether "<rule><div><p/><nest/></div></rule>"
    ## is conforming or not.

    my $nt = $node->node_type;
    if ($nt == 1) {
      my $node_ns = $node->namespace_uri;
      $node_ns = '' unless defined $node_ns;
      my $node_ln = $node->manakai_local_name;
      my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
      if ($content eq 'block') {
        $not_allowed = 1
          unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln} or
              $self->{pluses}->{$node_ns}->{$node_ln};
      } elsif ($content eq 'inline') {
        $not_allowed = 1
          unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln} or
              $self->{pluses}->{$node_ns}->{$node_ln};
      } else {
        my $is_block = $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
        my $is_inline
          = $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} ||
            $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
        
        push @block_not_inline, $node
          if $is_block and not $is_inline and not $not_allowed;
        if (not $is_block and not $self->{pluses}->{$node_ns}->{$node_ln}) {
          $content = 'inline';
          for (@block_not_inline) {
            $self->{onerror}->(node => $_, type => 'element not allowed');
          }
          $not_allowed = 1 unless $is_inline;
        }
      }
      $self->{onerror}->(node => $node, type => 'element not allowed')
        if $not_allowed;
      my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
          if ($ellname eq 'style' and
              not $node->has_attribute_ns (undef, 'scoped')) {
            $not_allowed = 1;
          }
        } elsif ($content eq 'block') {
          $has_non_style = 1;
          $not_allowed = 1
            unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln} or
                $self->{pluses}->{$node_ns}->{$node_ln};
        } elsif ($content eq 'inline') {
          $has_non_style = 1;
          $not_allowed = 1
            unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
                $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln} or
                $self->{pluses}->{$node_ns}->{$node_ln};
        } else {
          $has_non_style = 1 unless $self->{pluses}->{$node_ns}->{$node_ln};
          my $is_block = $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
          my $is_inline
            = $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} ||
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
            
          push @block_not_inline, $node
            if $is_block and not $is_inline and not $not_allowed;
          if (not $is_block and not $self->{pluses}->{$node_ns}->{$node_ln}) {
            $content = 'inline';
            for (@block_not_inline) {
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
            $not_allowed = 1 unless $is_inline;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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

our $AttrChecker;

my $GetHTMLEnumeratedAttrChecker = sub {
  my $states = shift; # {value => conforming ? 1 : -1}
  return sub {
    my ($self, $attr) = @_;
    my $value = lc $attr->value; ## TODO: ASCII case insensitibility?
    if ($states->{$value} > 0) {
      #
    } elsif ($states->{$value}) {
      $self->{onerror}->(node => $attr, type => 'enumerated:non-conforming');
    } else {
      $self->{onerror}->(node => $attr, type => 'enumerated:invalid');
    }
  };
}; # $GetHTMLEnumeratedAttrChecker

my $GetHTMLBooleanAttrChecker = sub {
  my $local_name = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    unless ($value eq $local_name or $value eq '') {
      $self->{onerror}->(node => $attr, type => 'boolean:invalid');
    }
  };
}; # $GetHTMLBooleanAttrChecker

## Unordered set of space-separated tokens
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

## |rel| attribute (unordered set of space separated tokens,
## whose allowed values are defined by the section on link types)
my $HTMLLinkTypesAttrChecker = sub {
  my ($a_or_area, $todo, $self, $attr) = @_;
  my %word;
  for my $word (grep {length $_} split /[\x09-\x0D\x20]/, $attr->value) {
    unless ($word{$word}) {
      $word{$word} = 1;
    } else {
      $self->{onerror}->(node => $attr, type => 'duplicate token:'.$word);
    }
  }
  ## NOTE: Case sensitive match (since HTML5 spec does not say link
  ## types are case-insensitive and it says "The value should not 
  ## be confusingly similar to any other defined value (e.g.
  ## differing only in case).").
  ## NOTE: Though there is no explicit "MUST NOT" for undefined values,
  ## "MAY"s and "only ... MAY" restrict non-standard non-registered
  ## values to be used conformingly.
  require Whatpm::_LinkTypeList;
  our $LinkType;
  for my $word (keys %word) {
    my $def = $LinkType->{$word};
    if (defined $def) {
      if ($def->{status} eq 'accepted') {
        if (defined $def->{effect}->[$a_or_area]) {
          #
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'link type:bad context:'.$word);
        }
      } elsif ($def->{status} eq 'proposal') {
        $self->{onerror}->(node => $attr, level => 's',
                           type => 'link type:proposed:'.$word);
      } else { # rejected or synonym
        $self->{onerror}->(node => $attr,
                           type => 'link type:non-conforming:'.$word);
      }
      if (defined $def->{effect}->[$a_or_area]) {
        if ($word eq 'alternate') {
          #
        } elsif ($def->{effect}->[$a_or_area] eq 'hyperlink') {
          $todo->{has_hyperlink_link_type} = 1;
        }
      }
      if ($def->{unique}) {
        unless ($self->{has_link_type}->{$word}) {
          $self->{has_link_type}->{$word} = 1;
        } else {
          $self->{onerror}->(node => $attr,
                             type => 'link type:duplicate:'.$word);
        }
      }
    } else {
      $self->{onerror}->(node => $attr, level => 'unsupported',
                         type => 'link type:'.$word);
    }
  }
  $todo->{has_hyperlink_link_type} = 1
      if $word{alternate} and not $word{stylesheet};
  ## TODO: The Pingback 1.0 specification, which is referenced by HTML5,
  ## says that using both X-Pingback: header field and HTML
  ## <link rel=pingback> is deprecated and if both appears they
  ## SHOULD contain exactly the same value.
  ## ISSUE: Pingback 1.0 specification defines the exact representation
  ## of its link element, which cannot be tested by the current arch.
  ## ISSUE: Pingback 1.0 specification says that the document MUST NOT
  ## include any string that matches to the pattern for the rel=pingback link,
  ## which again inpossible to test.
  ## ISSUE: rel=pingback href MUST NOT include entities other than predefined 4.

  ## NOTE: <link rel="up index"><link rel="up up index"> is not an error.
  ## ISSUE: <link rel="up up"> is non-conforming, since rel="" is unordered.
}; # $HTMLLinkTypesAttrChecker

## URI (or IRI)
my $HTMLURIAttrChecker = sub {
  my ($self, $attr) = @_;
  ## ISSUE: Relative references are allowed? (RFC 3987 "IRI" is an absolute reference with optional fragment identifier.)
  my $value = $attr->value;
  Whatpm::URIChecker->check_iri_reference ($value, sub {
    my %opt = @_;
    $self->{onerror}->(node => $attr, level => $opt{level},
                       type => 'URI::'.$opt{type}.
                       (defined $opt{position} ? ':'.$opt{position} : ''));
  });
  $self->{has_uri_attr} = 1;
}; # $HTMLURIAttrChecker

## A space separated list of one or more URIs (or IRIs)
my $HTMLSpaceURIsAttrChecker = sub {
  my ($self, $attr) = @_;
  my $i = 0;
  for my $value (split /[\x09-\x0D\x20]+/, $attr->value) {
    Whatpm::URIChecker->check_iri_reference ($value, sub {
      my %opt = @_;
      $self->{onerror}->(node => $attr, level => $opt{level},
                         type => 'URIs:'.':'.
                         $opt{type}.':'.$i.
                         (defined $opt{position} ? ':'.$opt{position} : ''));
    });
    $i++;
  }
  ## ISSUE: Relative references?
  ## ISSUE: Leading or trailing white spaces are conformant?
  ## ISSUE: A sequence of white space characters are conformant?
  ## ISSUE: A zero-length string is conformant? (It does contain a relative reference, i.e. same as base URI.)
  ## NOTE: Duplication seems not an error.
  $self->{has_uri_attr} = 1;
}; # $HTMLSpaceURIsAttrChecker

my $HTMLDatetimeAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  ## ISSUE: "space", not "space character" (in parsing algorihtm, "space character")
  if ($value =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})(?>[\x09-\x0D\x20]+(?>T[\x09-\x0D\x20]*)?|T[\x09-\x0D\x20]*)([0-9]{2}):([0-9]{2})(?>:([0-9]{2}))?(?>\.([0-9]+))?[\x09-\x0D\x20]*(?>Z|[+-]([0-9]{2}):([0-9]{2}))\z/) {
    my ($y, $M, $d, $h, $m, $s, $f, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    if (0 < $M and $M < 13) { ## ISSUE: This is not explicitly specified (though in parsing algorithm)
      $self->{onerror}->(node => $attr, type => 'datetime:bad day')
          if $d < 1 or
              $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->{onerror}->(node => $attr, type => 'datetime:bad day')
          if $M == 2 and $d == 29 and
              not ($y % 400 == 0 or ($y % 4 == 0 and $y % 100 != 0));
    } else {
      $self->{onerror}->(node => $attr, type => 'datetime:bad month');
    }
    $self->{onerror}->(node => $attr, type => 'datetime:bad hour') if $h > 23;
    $self->{onerror}->(node => $attr, type => 'datetime:bad minute') if $m > 59;
    $self->{onerror}->(node => $attr, type => 'datetime:bad second')
        if defined $s and $s > 59;
    $self->{onerror}->(node => $attr, type => 'datetime:bad timezone hour')
        if $zh > 23;
    $self->{onerror}->(node => $attr, type => 'datetime:bad timezone minute')
        if $zm > 59;
    ## ISSUE: Maybe timezone -00:00 should have same semantics as in RFC 3339.
  } else {
    $self->{onerror}->(node => $attr, type => 'datetime:syntax error');
  }
}; # $HTMLDatetimeAttrChecker

my $HTMLIntegerAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  unless ($value =~ /\A-?[0-9]+\z/) {
    $self->{onerror}->(node => $attr, type => 'integer:syntax error');
  }
}; # $HTMLIntegerAttrChecker

my $GetHTMLNonNegativeIntegerAttrChecker = sub {
  my $range_check = shift;
  return sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if ($value =~ /\A[0-9]+\z/) {
      unless ($range_check->($value + 0)) {
        $self->{onerror}->(node => $attr, type => 'nninteger:out of range');
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'nninteger:syntax error');
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
        $self->{onerror}->(node => $attr, type => 'float:out of range');
      }
    } else {
      $self->{onerror}->(node => $attr,
                         type => 'float:syntax error');
    }
  };
}; # $GetHTMLFloatingPointNumberAttrChecker

## "A valid MIME type, optionally with parameters. [RFC 2046]"
## ISSUE: RFC 2046 does not define syntax of media types.
## ISSUE: The definition of "a valid MIME type" is unknown.
## Syntactical correctness?
my $HTMLIMTAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  ## ISSUE: RFC 2045 Content-Type header field allows insertion
  ## of LWS/comments between tokens.  Is it allowed in HTML?  Maybe no.
  ## ISSUE: RFC 2231 extension?  Maybe no.
  my $lws0 = qr/(?>(?>\x0D\x0A)?[\x09\x20])*/;
  my $token = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
  my $qs = qr/"(?>[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\x7E]|\x0D\x0A[\x09\x20]|\x5C[\x00-\x7F])*"/;
  if ($value =~ m#\A$lws0($token)$lws0/$lws0($token)$lws0((?>;$lws0$token$lws0=$lws0(?>$token|$qs)$lws0)*)\z#) {
    my @type = ($1, $2);
    my $param = $3;
    while ($param =~ s/^;$lws0($token)$lws0=$lws0(?>($token)|($qs))$lws0//) {
      if (defined $2) {
        push @type, $1 => $2;
      } else {
        my $n = $1;
        my $v = $2;
        $v =~ s/\\(.)/$1/gs;
        push @type, $n => $v;
      }
    }
    require Whatpm::IMTChecker;
    Whatpm::IMTChecker->check_imt (sub {
      my %opt = @_;
      $self->{onerror}->(node => $attr, level => $opt{level},
                         type => 'IMT:'.$opt{type});
    }, @type);
  } else {
    $self->{onerror}->(node => $attr, type => 'IMT:syntax error');
  }
}; # $HTMLIMTAttrChecker

my $HTMLLanguageTagAttrChecker = sub {
  ## NOTE: See also $AtomLanguageTagAttrChecker in Atom.pm.

  my ($self, $attr) = @_;
  my $value = $attr->value;
  require Whatpm::LangTag;
  Whatpm::LangTag->check_rfc3066_language_tag ($value, sub {
    my %opt = @_;
    my $type = 'LangTag:'.$opt{type};
    $type .= ':' . $opt{subtag} if defined $opt{subtag};
    $self->{onerror}->(node => $attr, type => $type, value => $opt{value},
                       level => $opt{level});
  });
  ## ISSUE: RFC 4646 (3066bis)?

  ## TODO: testdata
}; # $HTMLLanguageTagAttrChecker

## "A valid media query [MQ]"
my $HTMLMQAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr, level => 'unsupported',
                     type => 'media query');
  ## ISSUE: What is "a valid media query"?
}; # $HTMLMQAttrChecker

my $HTMLEventHandlerAttrChecker = sub {
  my ($self, $attr) = @_;
  $self->{onerror}->(node => $attr, level => 'unsupported',
                     type => 'event handler');
  ## TODO: MUST contain valid ECMAScript code matching the
  ## ECMAScript |FunctionBody| production. [ECMA262]
  ## ISSUE: MUST be ES3? E4X? ES4? JS1.x?
  ## ISSUE: Automatic semicolon insertion does not apply?
  ## ISSUE: Other script languages?
}; # $HTMLEventHandlerAttrChecker

my $HTMLUsemapAttrChecker = sub {
  my ($self, $attr) = @_;
  ## MUST be a valid hashed ID reference to a |map| element
  my $value = $attr->value;
  if ($value =~ s/^#//) {
    ## ISSUE: Is |usemap="#"| conformant? (c.f. |id=""| is non-conformant.)
    push @{$self->{usemap}}, [$value => $attr];
  } else {
    $self->{onerror}->(node => $attr, type => '#idref:syntax error');
  }
  ## NOTE: Space characters in hashed ID references are conforming.
  ## ISSUE: UA algorithm for matching is case-insensitive; IDs only different in cases should be reported
}; # $HTMLUsemapAttrChecker

my $HTMLTargetAttrChecker = sub {
  my ($self, $attr) = @_;
  my $value = $attr->value;
  if ($value =~ /^_/) {
    $value = lc $value; ## ISSUE: ASCII case-insentitive?
    unless ({
             _self => 1, _parent => 1, _top => 1,
            }->{$value}) {
      $self->{onerror}->(node => $attr,
                         type => 'reserved browsing context name');
    }
  } else {
    #$ ISSUE: An empty string is conforming?
  }
}; # $HTMLTargetAttrChecker

my $HTMLAttrChecker = {
  id => sub {
    ## NOTE: |map| has its own variant of |id=""| checker
    my ($self, $attr) = @_;
    my $value = $attr->value;
    if (length $value > 0) {
      if ($self->{id}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'duplicate ID');
        push @{$self->{id}->{$value}}, $attr;
      } else {
        $self->{id}->{$value} = [$attr];
      }
      if ($value =~ /[\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $attr, type => 'space in ID');
      }
    } else {
      ## NOTE: MUST contain at least one character
      $self->{onerror}->(node => $attr, type => 'empty attribute value');
    }
  },
  title => sub {}, ## NOTE: No conformance creteria
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
        $self->{onerror}->(node => $attr, type => $type, value => $opt{value},
                           level => $opt{level});
      });
    }
    ## ISSUE: RFC 4646 (3066bis)?
    unless ($attr->owner_document->manakai_is_html) {
      $self->{onerror}->(node => $attr, type => 'in XML:lang');
    }

    ## TODO: test data
  },
  dir => $GetHTMLEnumeratedAttrChecker->({ltr => 1, rtl => 1}),
  class => sub {
    my ($self, $attr) = @_;
    my %word;
    for my $word (grep {length $_} split /[\x09-\x0D\x20]/, $attr->value) {
      unless ($word{$word}) {
        $word{$word} = 1;
        push @{$self->{return}->{class}->{$word}||=[]}, $attr;
      } else {
        $self->{onerror}->(node => $attr, type => 'duplicate token:'.$word);
      }
    }
  },
  contextmenu => sub {
    my ($self, $attr) = @_;
    my $value = $attr->value;
    push @{$self->{contextmenu}}, [$value => $attr];
    ## ISSUE: "The value must be the ID of a menu element in the DOM."
    ## What is "in the DOM"?  A menu Element node that is not part
    ## of the Document tree is in the DOM?  A menu Element node that
    ## belong to another Document tree is in the DOM?
  },
  irrelevant => $GetHTMLBooleanAttrChecker->('irrelevant'),
  tabindex => $HTMLIntegerAttrChecker
## TODO: ref, template, registrationmark
};

for (qw/
         onabort onbeforeunload onblur onchange onclick oncontextmenu
         ondblclick ondrag ondragend ondragenter ondragleave ondragover
         ondragstart ondrop onerror onfocus onkeydown onkeypress
         onkeyup onload onmessage onmousedown onmousemove onmouseout
         onmouseover onmouseup onmousewheel onresize onscroll onselect
         onsubmit onunload 
     /) {
  $HTMLAttrChecker->{$_} = $HTMLEventHandlerAttrChecker;
}

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
        $checker->($self, $attr, $todo);
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }
    }
  };
}; # $GetHTMLAttrsChecker

our $Element;
our $ElementDefault;
our $AnyChecker;

$Element->{$HTML_NS}->{''} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $ElementDefault->{checker},
};

$Element->{$HTML_NS}->{html} = {
  is_root => 1,
  attrs_checker => $GetHTMLAttrsChecker->({
    xmlns => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ($value eq $HTML_NS) {
        $self->{onerror}->(node => $attr, type => 'invalid attribute value');
      }
      unless ($attr->owner_document->manakai_is_html) {
        $self->{onerror}->(node => $attr, type => 'in XML:xmlns');
  ## TODO: Test
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($phase eq 'before head') {
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
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'title') {
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
          } elsif ($node->has_attribute_ns (undef, 'name') or
                   $node->has_attribute_ns (undef, 'http-equiv')) {
            $phase = 'after base';
          } else {
            $phase = 'after base';
            $not_allowed = 1;
          }
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'base') {
          if ($phase eq 'initial' or $phase eq 'after charset') {
            $phase = 'after base';
          } else {
            $not_allowed = 1;
          }
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'style') {
          $phase = 'after base';
          if ($node->has_attribute_ns (undef, 'scoped')) {
            $not_allowed = 1;
          }
        } elsif ($HTMLMetadataElements->{$node_ns}->{$node_ln}) {
          $phase = 'after base';
        } else {
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        local $todo->{flag}->{in_head} = 1;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
  attrs_checker => sub {
    my ($self, $todo) = @_;

    if ($self->{has_uri_attr} and
        $todo->{node}->has_attribute_ns (undef, 'href')) {
      ## ISSUE: Are these examples conforming?
      ## <head profile="a b c"><base href> (except for |profile|'s 
      ## non-conformance)
      ## <title xml:base="relative"/><base href/> (maybe it should be)
      ## <unknown xmlns="relative"/><base href/> (assuming that
      ## |{relative}:unknown| is allowed before XHTML |base| (unlikely, though))
      ## <?xml-stylesheet href="relative"?>...<base href=""/>
      ## NOTE: These are non-conformant anyway because of |head|'s content model:
      ## <style>@import 'relative';</style><base href>
      ## <script>location.href = 'relative';</script><base href>
      $self->{onerror}->(node => $todo->{node},
                         type => 'basehref after URI attribute');
    }
    if ($self->{has_hyperlink_element} and
        $todo->{node}->has_attribute_ns (undef, 'target')) {
      ## ISSUE: Are these examples conforming?
      ## <head><title xlink:href=""/><base target="name"/></head>
      ## <xbl:xbl>...<svg:a href=""/>...</xbl:xbl><base target="name"/>
      ## (assuming that |xbl:xbl| is allowed before |base|)
      ## NOTE: These are non-conformant anyway because of |head|'s content model:
      ## <link href=""/><base target="name"/>
      ## <link rel=unknown href=""><base target=name>
      $self->{onerror}->(node => $todo->{node},
                         type => 'basetarget after hyperlink');
    }

    return $GetHTMLAttrsChecker->({
      href => $HTMLURIAttrChecker,
      target => $HTMLTargetAttrChecker,
    })->($self, $todo);

    ## TOOD: <base/> is non-conforming (revision 1115)
  },
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{link} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    $GetHTMLAttrsChecker->({
      href => $HTMLURIAttrChecker,
      rel => sub { $HTMLLinkTypesAttrChecker->(0, $todo, @_) },
      media => $HTMLMQAttrChecker,
      hreflang => $HTMLLanguageTagAttrChecker,
      type => $HTMLIMTAttrChecker,
      ## NOTE: Though |title| has special semantics,
      ## syntactically same as the |title| as global attribute.
    })->($self, $todo);
    if ($todo->{node}->has_attribute_ns (undef, 'href')) {
      $self->{has_hyperlink_element} = 1 if $todo->{has_hyperlink_link_type};
    } else {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:href');
    }
    unless ($todo->{node}->has_attribute_ns (undef, 'rel')) {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:rel');
    }
  },
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
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
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
                           type => 'enumerated:invalid');
      }
    }

    if (defined $charset_attr) {
      unless ($todo->{node}->owner_document->manakai_is_html) {
        $self->{onerror}->(node => $charset_attr,
                           type => 'in XML:charset');
      }
      ## TODO: charset
    }
  },
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{style} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    type => $HTMLIMTAttrChecker, ## TODO: MUST be a styling language
    media => $HTMLMQAttrChecker,
    scoped => $GetHTMLBooleanAttrChecker->('scoped'),
    ## NOTE: |title| has special semantics for |style|s, but is syntactically
    ## not different
  }),
  checker => sub {
    ## NOTE: |html:style| has no conformance creteria on content model
    my ($self, $todo) = @_;
    my $type = $todo->{node}->get_attribute_ns (undef, 'type');
    $type = 'text/css' unless defined $type;
    $self->{onerror}->(node => $todo->{node}, level => 'unsupported',
                       type => 'style:'.$type); ## TODO: $type normalization
    return $AnyChecker->($self, $todo);
  },
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
  checker => sub {
    my ($self, $todo) = @_;
    $todo->{flag}->{has_heading}->[0] = 1;
    return $HTMLSignificantStrictlyInlineChecker->($self, $todo);
  },
};

$Element->{$HTML_NS}->{h2} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{h1}->{checker},
};

$Element->{$HTML_NS}->{h3} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{h1}->{checker},
};

$Element->{$HTML_NS}->{h4} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{h1}->{checker},
};

$Element->{$HTML_NS}->{h5} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{h1}->{checker},
};

$Element->{$HTML_NS}->{h6} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{h1}->{checker},
};

$Element->{$HTML_NS}->{header} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;
    my $old_flag = $todo->{flag}->{has_heading} || [];
    my $new_flag = [];
    local $todo->{flag}->{has_heading} = $new_flag;
    my $node = $todo->{node};

    my $end = $self->_add_minuses
        ({$HTML_NS => {qw/header 1 footer 1/}},
         $HTMLSectioningElements);
    my ($new_todos, $ch) = $HTMLBlockChecker->($self, $todo);
    push @$new_todos, $end, 
        {type => 'code', code => sub {
           if ($new_flag->[0]) {
             $old_flag->[0] = 1;
           } else {
             $self->{onerror}->(node => $node, type => 'element missing:hn');
           }
         }};
    return ($new_todos, $ch);
  },
};

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
            unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln} or
                $self->{pluses}->{$node_ns}->{$node_ln};
        } elsif ($content eq 'inline') {
          $not_allowed = 1
            unless $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} or
                $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln} or
                $self->{pluses}->{$node_ns}->{$node_ln};
        } else {
          my $is_block = $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
          my $is_inline
            = $HTMLStrictlyInlineLevelElements->{$node_ns}->{$node_ln} ||
              $HTMLStructuredInlineLevelElements->{$node_ns}->{$node_ln};
          
          push @block_not_inline, $node
            if $is_block and not $is_inline and not $not_allowed;
          if (not $is_block and not $self->{pluses}->{$node_ns}->{$node_ln}) {
            $content = 'inline';
            for (@block_not_inline) {
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
            $not_allowed = 1 unless $is_inline;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
          if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($phase eq 'before dt') {
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
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
      $self->{onerror}->(node => $el, type => 'child element missing:dd');
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif (not ($node_ns eq $HTML_NS and $node_ln eq 'li')) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
          $self->{onerror}->(node => $attr, level => 'unsupported',
                             type => 'attribute');
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($phase eq 'in dds') {
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
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
      $self->{onerror}->(node => $el, type => 'child element missing:dd');
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
  attrs_checker => sub {
    my ($self, $todo) = @_;
    my %attr;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = {
                     target => $HTMLTargetAttrChecker,
                     href => $HTMLURIAttrChecker,
                     ping => $HTMLSpaceURIsAttrChecker,
                     rel => sub { $HTMLLinkTypesAttrChecker->(1, $todo, @_) },
                     media => $HTMLMQAttrChecker,
                     hreflang => $HTMLLanguageTagAttrChecker,
                     type => $HTMLIMTAttrChecker,
                   }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr) if ref $checker;
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }
    }

    if (defined $attr{href}) {
      $self->{has_hyperlink_element} = 1;
    } else {
      for (qw/target ping rel media hreflang type/) {
        if (defined $attr{$_}) {
          $self->{onerror}->(node => $attr{$_},
                             type => 'attribute not allowed');
        }
      }
    }
  },
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ($HTMLInteractiveElements);
    my ($new_todos, $ch)
      = $HTMLSignificantInlineOrStrictlyInlineChecker->($self, $todo);
    push @$new_todos, $end;

    $_->{flag}->{has_a} = 1 for @$new_todos;
    ## TODO: <a> -> <a href> (revision 1115)

    return ($new_todos, $ch);
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

$Element->{$HTML_NS}->{dfn} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {dfn => 1}});
    my ($sib, $ch) = $HTMLStrictlyInlineChecker->($self, $todo);
    push @$sib, $end;

    my $node = $todo->{node};
    my $term = $node->get_attribute_ns (undef, 'title');
    unless (defined $term) {
      for my $child (@{$node->child_nodes}) {
        if ($child->node_type == 1) { # ELEMENT_NODE
          if (defined $term) {
            undef $term;
            last;
          } elsif ($child->manakai_local_name eq 'abbr') {
            my $nsuri = $child->namespace_uri;
            if (defined $nsuri and $nsuri eq $HTML_NS) {
              my $attr = $child->get_attribute_node_ns (undef, 'title');
              if ($attr) {
                $term = $attr->value;
              }
            }
          }
        } elsif ($child->node_type == 3 or $child->node_type == 4) {
          ## TEXT_NODE or CDATA_SECTION_NODE
          if ($child->data =~ /\A[\x09-\x0D\x20]+\z/) { # Inter-element whitespace
            next;
          }
          undef $term;
          last;
        }
      }
      unless (defined $term) {
        $term = $node->text_content;
      }
    }
    if ($self->{term}->{$term}) {
      $self->{onerror}->(node => $node, type => 'duplicate term');
      push @{$self->{term}->{$term}}, $node;
    } else {
      $self->{term}->{$term} = [$node];
    }
## ISSUE: The HTML5 algorithm does not work with |ruby| unless |dfn|
## has |title|.

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

$Element->{$HTML_NS}->{time} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    datetime => sub { 1 }, # checked in |checker|
  }),
  ## TODO: Write tests
  checker => sub {
    my ($self, $todo) = @_;

    my $attr = $todo->{node}->get_attribute_node_ns (undef, 'datetime');
    my $input;
    my $reg_sp;
    my $input_node;
    if ($attr) {
      $input = $attr->value;
      $reg_sp = qr/[\x09-\x0D\x20]*/;
      $input_node = $attr;
    } else {
      $input = $todo->{node}->text_content;
      $reg_sp = qr/\p{Zs}*/;
      $input_node = $todo->{node};

      ## ISSUE: What is the definition for "successfully extracts a date
      ## or time"?  If the algorithm says the string is invalid but
      ## return some date or time, is it "successfully"?
    }

    my $hour;
    my $minute;
    my $second;
    if ($input =~ /
      \A
      [\x09-\x0D\x20]*
      ([0-9]+) # 1
      (?>
        -([0-9]+) # 2
        -([0-9]+) # 3
        [\x09-\x0D\x20]*
        (?>
          T
          [\x09-\x0D\x20]*
        )?
        ([0-9]+) # 4
        :([0-9]+) # 5
        (?>
          :([0-9]+(?>\.[0-9]*)?|\.[0-9]*) # 6
        )?
        [\x09-\x0D\x20]*
        (?>
          Z
          [\x09-\x0D\x20]*
        |
          [+-]([0-9]+):([0-9]+) # 7, 8
          [\x09-\x0D\x20]*
        )?
        \z
      |
        :([0-9]+) # 9
        (?>
          :([0-9]+(?>\.[0-9]*)?|\.[0-9]*) # 10
        )?
        [\x09-\x0D\x20]*\z
      )
    /x) {
      if (defined $2) { ## YYYY-MM-DD T? hh:mm
        if (length $1 != 4 or length $2 != 2 or length $3 != 2 or
            length $4 != 2 or length $5 != 2) {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error');
        }

        if (1 <= $2 and $2 <= 12) {
          $self->{onerror}->(node => $input_node, type => 'datetime:bad day')
              if $3 < 1 or
                  $3 > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$2];
          $self->{onerror}->(node => $input_node, type => 'datetime:bad day')
              if $2 == 2 and $3 == 29 and
                  not ($1 % 400 == 0 or ($1 % 4 == 0 and $1 % 100 != 0));
        } else {
          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad month');
        }

        ($hour, $minute, $second) = ($4, $5, $6);
          
        if (defined $7) { ## [+-]hh:mm
          if (length $7 != 2 or length $8 != 2) {
            $self->{onerror}->(node => $input_node,
                               type => 'dateortime:syntax error');
          }

          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad timezone hour')
              if $7 > 23;
          $self->{onerror}->(node => $input_node,
                             type => 'datetime:bad timezone minute')
              if $8 > 59;
        }
      } else { ## hh:mm
        if (length $1 != 2 or length $9 != 2) {
          $self->{onerror}->(node => $input_node,
                             type => qq'dateortime:syntax error');
        }

        ($hour, $minute, $second) = ($1, $9, $10);
      }

      $self->{onerror}->(node => $input_node, type => 'datetime:bad hour')
          if $hour > 23;
      $self->{onerror}->(node => $input_node, type => 'datetime:bad minute')
          if $minute > 59;

      if (defined $second) { ## s
        ## NOTE: Integer part of second don't have to have length of two.
          
        if (substr ($second, 0, 1) eq '.') {
          $self->{onerror}->(node => $input_node,
                             type => 'dateortime:syntax error');
        }
          
        $self->{onerror}->(node => $input_node, type => 'datetime:bad second')
            if $second >= 60;
      }        
    } else {
      $self->{onerror}->(node => $input_node,
                         type => 'dateortime:syntax error');
    }

    return $HTMLStrictlyInlineChecker->($self, $todo);
  },
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
    datetime => $HTMLDatetimeAttrChecker,
  }),
  checker => $HTMLTransparentChecker,
};

$Element->{$HTML_NS}->{del} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    cite => $HTMLURIAttrChecker,
    datetime => $HTMLDatetimeAttrChecker,
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
## TODO: Test for <nest/> in <figure/>

## TODO: |alt|
$Element->{$HTML_NS}->{img} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    $GetHTMLAttrsChecker->({
      alt => sub { }, ## NOTE: No syntactical requirement
      src => $HTMLURIAttrChecker,
      usemap => $HTMLUsemapAttrChecker,
      ismap => sub {
        my ($self, $attr, $parent_todo) = @_;
        if (not $todo->{flag}->{has_a}) {
          $self->{onerror}->(node => $attr, type => 'attribute not allowed');
        }
        $GetHTMLBooleanAttrChecker->('ismap')->($self, $attr, $parent_todo);
      },
      ## TODO: height
      ## TODO: width
    })->($self, $todo);
    unless ($todo->{node}->has_attribute_ns (undef, 'alt')) {
      $self->{onerror}->(node => $todo->{node}, type => 'attribute missing:alt');
    }
    unless ($todo->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $todo->{node}, type => 'attribute missing:src');
    }
  },
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{iframe} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
  }),
  checker => $HTMLTextChecker,
};

$Element->{$HTML_NS}->{embed} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    my $has_src;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        if ($attr_ln eq 'src') {
          $checker = $HTMLURIAttrChecker;
          $has_src = 1;
        } elsif ($attr_ln eq 'type') {
          $checker = $HTMLIMTAttrChecker;
        } else {
          ## TODO: height
          ## TODO: width
          $checker = $HTMLAttrChecker->{$attr_ln}
            || sub { }; ## NOTE: Any local attribute is ok.
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr);
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No comformance createria for global attributes in the spec
      }
    }

    unless ($has_src) {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:src');
    }
  },
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{object} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    $GetHTMLAttrsChecker->({
      data => $HTMLURIAttrChecker,
      type => $HTMLIMTAttrChecker,
      usemap => $HTMLUsemapAttrChecker,
      ## TODO: width
      ## TODO: height
    })->($self, $todo);
    unless ($todo->{node}->has_attribute_ns (undef, 'data')) {
      unless ($todo->{node}->has_attribute_ns (undef, 'type')) {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:data|type');
      }
    }
  },
  checker => $ElementDefault->{checker}, ## TODO
## TODO: Tests for <nest/> in <object/>
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

$Element->{$HTML_NS}->{video} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    src => $HTMLURIAttrChecker,
    ## TODO: start, loopstart, loopend, end
    ## ISSUE: they MUST be "value time offset"s.  Value?
    ## ISSUE: playcount has no conformance creteria
    autoplay => $GetHTMLBooleanAttrChecker->('autoplay'),
    controls => $GetHTMLBooleanAttrChecker->('controls'),
    poster => $HTMLURIAttrChecker, ## TODO: not for audio!
    ## TODO: width, height (not for audio!)
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
  attrs_checker => sub {
    my ($self, $todo) = @_;
    $GetHTMLAttrsChecker->({
      src => $HTMLURIAttrChecker,
      type => $HTMLIMTAttrChecker,
      media => $HTMLMQAttrChecker,
    })->($self, $todo);
    unless ($todo->{node}->has_attribute_ns (undef, 'src')) {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:src');
    }
  },
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
  attrs_checker => sub {
    my ($self, $todo) = @_;
    my $has_id;
    $GetHTMLAttrsChecker->({
      id => sub {
        ## NOTE: same as global |id=""|, with |$self->{map}| registeration
        my ($self, $attr) = @_;
        my $value = $attr->value;
        if (length $value > 0) {
          if ($self->{id}->{$value}) {
            $self->{onerror}->(node => $attr, type => 'duplicate ID');
            push @{$self->{id}->{$value}}, $attr;
          } else {
            $self->{id}->{$value} = [$attr];
          }
        } else {
          ## NOTE: MUST contain at least one character
          $self->{onerror}->(node => $attr, type => 'empty attribute value');
        }
        if ($value =~ /[\x09-\x0D\x20]/) {
          $self->{onerror}->(node => $attr, type => 'space in ID');
        }
        $self->{map}->{$value} ||= $attr;
        $has_id = 1;
      },
    })->($self, $todo);
    $self->{onerror}->(node => $todo->{node}, type => 'attribute missing:id')
        unless $has_id;
  },
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{area} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;
    my %attr;
    my $coords;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = {
                     alt => sub { },
                         ## NOTE: |alt| value has no conformance creteria.
                     shape => $GetHTMLEnumeratedAttrChecker->({
                       circ => -1, circle => 1,
                       default => 1,
                       poly => 1, polygon => -1,
                       rect => 1, rectangle => -1,
                     }),
                     coords => sub {
                       my ($self, $attr) = @_;
                       my $value = $attr->value;
                       if ($value =~ /\A-?[0-9]+(?>,-?[0-9]+)*\z/) {
                         $coords = [split /,/, $value];
                       } else {
                         $self->{onerror}->(node => $attr,
                                            type => 'coords:syntax error');
                       }
                     },
                     target => $HTMLTargetAttrChecker,
                     href => $HTMLURIAttrChecker,
                     ping => $HTMLSpaceURIsAttrChecker,
                     rel => sub { $HTMLLinkTypesAttrChecker->(1, $todo, @_) },
                     media => $HTMLMQAttrChecker,
                     hreflang => $HTMLLanguageTagAttrChecker,
                     type => $HTMLIMTAttrChecker,
                   }->{$attr_ln};
        if ($checker) {
          $attr{$attr_ln} = $attr;
        } else {
          $checker = $HTMLAttrChecker->{$attr_ln};
        }
      }
      $checker ||= $AttrChecker->{$attr_ns}->{$attr_ln}
        || $AttrChecker->{$attr_ns}->{''};
      if ($checker) {
        $checker->($self, $attr) if ref $checker;
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }
    }

    if (defined $attr{href}) {
      $self->{has_hyperlink_element} = 1;
      unless (defined $attr{alt}) {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:alt');
      }
    } else {
      for (qw/target ping rel media hreflang type alt/) {
        if (defined $attr{$_}) {
          $self->{onerror}->(node => $attr{$_},
                             type => 'attribute not allowed');
        }
      }
    }

    my $shape = 'rectangle';
    if (defined $attr{shape}) {
      $shape = {
                circ => 'circle', circle => 'circle',
                default => 'default',
                poly => 'polygon', polygon => 'polygon',
                rect => 'rectangle', rectangle => 'rectangle',
               }->{lc $attr{shape}->value} || 'rectangle';
      ## TODO: ASCII lowercase?
    }

    if ($shape eq 'circle') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords == 3) {
            if ($coords->[2] < 0) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range:2');
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number:3:'.@$coords);
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:coords');
      }
    } elsif ($shape eq 'default') {
      if (defined $attr{coords}) {
        $self->{onerror}->(node => $attr{coords},
                           type => 'attribute not allowed');
      }
    } elsif ($shape eq 'polygon') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords >= 6) {
            unless (@$coords % 2 == 0) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:number:even:'.@$coords);
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number:>=6:'.@$coords);
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:coords');
      }
    } elsif ($shape eq 'rectangle') {
      if (defined $attr{coords}) {
        if (defined $coords) {
          if (@$coords == 4) {
            unless ($coords->[0] < $coords->[2]) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range:0');
            }
            unless ($coords->[1] < $coords->[3]) {
              $self->{onerror}->(node => $attr{coords},
                                 type => 'coords:out of range:1');
            }
          } else {
            $self->{onerror}->(node => $attr{coords},
                               type => 'coords:number:4:'.@$coords);
          }
        } else {
          ## NOTE: A syntax error has been reported.
        }
      } else {
        $self->{onerror}->(node => $todo->{node},
                           type => 'attribute missing:coords');
      }
    }
  },
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($phase eq 'in tbodys') {
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
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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

    ## Table model errors
    require Whatpm::HTMLTable;
    Whatpm::HTMLTable->form_table ($todo->{node}, sub {
      my %opt = @_;
      $self->{onerror}->(type => 'table:'.$opt{type}, node => $opt{node});
    });
    push @{$self->{return}->{table}}, $todo->{node};

    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{caption} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{colgroup} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    span => $GetHTMLNonNegativeIntegerAttrChecker->(sub { shift > 0 }),
      ## NOTE: Defined only if "the |colgroup| element contains no |col| elements"
      ## TODO: "attribute not supported" if |col|.
      ## ISSUE: MUST NOT if any |col|?
      ## ISSUE: MUST NOT for |<colgroup span="1"><any><col/></any></colgroup>| (though non-conforming)?
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif (not ($node_ns eq $HTML_NS and $node_ln eq 'col')) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'tr') {
          $has_tr = 1;
        } else {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
  checker => $Element->{$HTML_NS}->{tbody}->{checker},
};

$Element->{$HTML_NS}->{tfoot} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
  checker => $Element->{$HTML_NS}->{tbody}->{checker},
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($node_ns eq $HTML_NS and
                 ($node_ln eq 'td' or $node_ln eq 'th')) {
          $has_td = 1;
        } else {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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

## TODO: forms
## TODO: Tests for <nest/> in form elements

$Element->{$HTML_NS}->{script} = {
  attrs_checker => $GetHTMLAttrsChecker->({
      src => $HTMLURIAttrChecker,
      defer => $GetHTMLBooleanAttrChecker->('defer'),
      async => $GetHTMLBooleanAttrChecker->('async'),
      type => $HTMLIMTAttrChecker,
  }),
  checker => sub {
    my ($self, $todo) = @_;

    if ($todo->{node}->has_attribute_ns (undef, 'src')) {
      return $HTMLEmptyChecker->($self, $todo);
    } else {
      ## NOTE: No content model conformance in HTML5 spec.
      my $type = $todo->{node}->get_attribute_ns (undef, 'type');
      my $language = $todo->{node}->get_attribute_ns (undef, 'language');
      if ((defined $type and $type eq '') or
          (defined $language and $language eq '')) {
        $type = 'text/javascript';
      } elsif (defined $type) {
        #
      } elsif (defined $language) {
        $type = 'text/' . $language;
      } else {
        $type = 'text/javascript';
      }
      $self->{onerror}->(node => $todo->{node}, level => 'unsupported',
                         type => 'script:'.$type); ## TODO: $type normalization
      return $AnyChecker->($self, $todo);
    }
  },
};

## NOTE: When script is disabled.
$Element->{$HTML_NS}->{noscript} = {
  attrs_checker => sub {
    my ($self, $todo) = @_;

    ## NOTE: This check is inserted in |attrs_checker|, rather than |checker|,
    ## since the later is not invoked when the |noscript| is used as a
    ## transparent element.
    unless ($todo->{node}->owner_document->manakai_is_html) {
      $self->{onerror}->(node => $todo->{node}, type => 'in XML:noscript');
    }

    $GetHTMLAttrsChecker->({})->($self, $todo);
  },
  checker => sub {
    my ($self, $todo) = @_;

    if ($todo->{flag}->{in_head}) {
      my $new_todos = [];
      my @nodes = (@{$todo->{node}->child_nodes});
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH'; 
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          my $node_ns = $node->namespace_uri;
          $node_ns = '' unless defined $node_ns;
          my $node_ln = $node->manakai_local_name;
          if ($self->{pluses}->{$node_ns}->{$node_ln}) {
            #
          } elsif ($node_ns eq $HTML_NS) {
            if ({link => 1, style => 1}->{$node_ln}) {
              #
            } elsif ($node_ln eq 'meta') {
              if ($node->has_attribute_ns (undef, 'name')) {
                #
              } else {
                $self->{onerror}->(node => $node,
                                   type => 'element not allowed');
              }
            } else {
              $self->{onerror}->(node => $node, type => 'element not allowed');
            }
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }

          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
    } else {
      my $end = $self->_add_minuses ({$HTML_NS => {noscript => 1}});
      my ($sib, $ch) = $HTMLBlockOrInlineChecker->($self, $todo);
      push @$sib, $end;
      return ($sib, $ch);
    }
  },
};

## ISSUE: Scripting is disabled: <head><noscript><html a></noscript></head>

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
    my $el = $todo->{node};
    my $new_todos = [];
    my @nodes = (@{$el->child_nodes});

    my $end = $self->_add_minuses ({$HTML_NS => {a => 1, datagrid => 1}});
    
    ## Block-table Block* | table | select | datalist | Empty
    my $mode = 'any';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH'; 
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        my $node_ns = $node->namespace_uri;
        $node_ns = '' unless defined $node_ns;
        my $node_ln = $node->manakai_local_name;
        my $not_allowed = $self->{minuses}->{$node_ns}->{$node_ln};
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($mode eq 'block') {
          $not_allowed = 1
              unless $HTMLBlockLevelElements->{$node_ns}->{$node_ln};
        } elsif ($mode eq 'any') {
          if ($node_ns eq $HTML_NS and
              {table => 1, select => 1, datalist => 1}->{$node_ln}) {
            $mode = 'none';
          } elsif ($HTMLBlockLevelElements->{$node_ns}->{$node_ln}) {
            $mode = 'block';
          } else {
            $not_allowed = 1;
          }
        } else {
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
            if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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

    push @$new_todos, $end;
    return ($new_todos);
  },
};

$Element->{$HTML_NS}->{command} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    checked => $GetHTMLBooleanAttrChecker->('checked'),
    default => $GetHTMLBooleanAttrChecker->('default'),
    disabled => $GetHTMLBooleanAttrChecker->('disabled'),
    hidden => $GetHTMLBooleanAttrChecker->('hidden'),
    icon => $HTMLURIAttrChecker,
    label => sub { }, ## NOTE: No conformance creteria
    radiogroup => sub { }, ## NOTE: No conformance creteria
    ## NOTE: |title| has special semantics, but no syntactical difference
    type => sub {
      my ($self, $attr) = @_;
      my $value = $attr->value;
      unless ({command => 1, checkbox => 1, radio => 1}->{$value}) {
        $self->{onerror}->(node => $attr, type => 'attribute value not allowed');
      }
    },
  }),
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{menu} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    autosubmit => $GetHTMLBooleanAttrChecker->('autosubmit'),
    id => sub {
      ## NOTE: same as global |id=""|, with |$self->{menu}| registeration
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if (length $value > 0) {
        if ($self->{id}->{$value}) {
          $self->{onerror}->(node => $attr, type => 'duplicate ID');
          push @{$self->{id}->{$value}}, $attr;
        } else {
          $self->{id}->{$value} = [$attr];
        }
      } else {
        ## NOTE: MUST contain at least one character
        $self->{onerror}->(node => $attr, type => 'empty attribute value');
      }
      if ($value =~ /[\x09-\x0D\x20]/) {
        $self->{onerror}->(node => $attr, type => 'space in ID');
      }
      $self->{menu}->{$value} ||= $attr;
      ## ISSUE: <menu id=""><p contextmenu=""> match?
    },
    label => sub { }, ## NOTE: No conformance creteria
    type => $GetHTMLEnumeratedAttrChecker->({context => 1, toolbar => 1}),
  }),
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif ($node_ns eq $HTML_NS and $node_ln eq 'li') {
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
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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

$Element->{$HTML_NS}->{datatemplate} = {
  attrs_checker => $GetHTMLAttrsChecker->({}),
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
        if ($self->{pluses}->{$node_ns}->{$node_ln}) {
          #
        } elsif (not ($node_ns eq $HTML_NS and $node_ln eq 'rule')) {
          $self->{onerror}->(node => $node,
                             type => 'element not allowed:datatemplate');
        }
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
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
  is_xml_root => 1,
};

$Element->{$HTML_NS}->{rule} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    ## TODO: |condition| attribute
    mode => $HTMLUnorderedSetOfSpaceSeparatedTokensAttrChecker,
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_pluses ({$HTML_NS => {nest => 1}});
    my ($sib, $ch) = $AnyChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
  ## NOTE: "MAY be anything that, when the parent |datatemplate|
  ## is applied to some conforming data, results in a conforming DOM tree.":
  ## We don't check against this.
};

$Element->{$HTML_NS}->{nest} = {
  attrs_checker => $GetHTMLAttrsChecker->({
    ## TODO: |filter| attribute
    mode => $HTMLUnorderedSetOfSpaceSeparatedTokensAttrChecker,
  }),
  checker => $HTMLEmptyChecker,
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

$Whatpm::ContentChecker::Namespace->{$HTML_NS}->{loaded} = 1;

1;
