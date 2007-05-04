package Whatpm::ContentChecker;
use strict;

my $ElementDefault = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        push @$children, $node;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($children);
  },
};

my $Element = {};

my $HTML_NS = q<http://www.w3.org/1999/xhtml>;

my $HTMLMetadataElements = [
  [$HTML_NS, 'link'],
  [$HTML_NS, 'meta'],
  [$HTML_NS, 'style'],
  [$HTML_NS, 'script'],
  [$HTML_NS, 'event-source'],
  [$HTML_NS, 'command'],
  [$HTML_NS, 'title'],
];

my $HTMLSectioningElements = [
  [$HTML_NS, 'body'],
  [$HTML_NS, 'section'],
  [$HTML_NS, 'nav'],
  [$HTML_NS, 'article'],
  [$HTML_NS, 'blockquote'],
  [$HTML_NS, 'aside'],
];

my $HTMLBlockLevelElements = [
  [$HTML_NS, 'section'],
  [$HTML_NS, 'nav'],
  [$HTML_NS, 'article'],
  [$HTML_NS, 'blockquote'],
  [$HTML_NS, 'aside'],
  [$HTML_NS, 'header'],
  [$HTML_NS, 'footer'],
  [$HTML_NS, 'address'],
  [$HTML_NS, 'p'],
  [$HTML_NS, 'hr'],
  [$HTML_NS, 'dialog'],
  [$HTML_NS, 'pre'],
  [$HTML_NS, 'ol'],
  [$HTML_NS, 'ul'],
  [$HTML_NS, 'dl'],
  [$HTML_NS, 'ins'],
  [$HTML_NS, 'del'],
  [$HTML_NS, 'figure'],
  [$HTML_NS, 'map'],
  [$HTML_NS, 'table'],
  [$HTML_NS, 'script'],
  [$HTML_NS, 'noscript'],
  [$HTML_NS, 'event-source'],
  [$HTML_NS, 'details'],
  [$HTML_NS, 'datagrid'],
  [$HTML_NS, 'menu'],
  [$HTML_NS, 'div'],
  [$HTML_NS, 'font'],
];

my $HTMLStrictlyInlineLevelElements = [
  [$HTML_NS, 'br'],
  [$HTML_NS, 'a'],
  [$HTML_NS, 'q'],
  [$HTML_NS, 'cite'],
  [$HTML_NS, 'em'],
  [$HTML_NS, 'strong'],
  [$HTML_NS, 'small'],
  [$HTML_NS, 'm'],
  [$HTML_NS, 'dfn'],
  [$HTML_NS, 'abbr'],
  [$HTML_NS, 'time'],
  [$HTML_NS, 'meter'],
  [$HTML_NS, 'progress'],
  [$HTML_NS, 'code'],
  [$HTML_NS, 'var'],
  [$HTML_NS, 'samp'],
  [$HTML_NS, 'kbd'],
  [$HTML_NS, 'sub'],
  [$HTML_NS, 'sup'],
  [$HTML_NS, 'span'],
  [$HTML_NS, 'i'],
  [$HTML_NS, 'b'],
  [$HTML_NS, 'bdo'],
  [$HTML_NS, 'ins'],
  [$HTML_NS, 'del'],
  [$HTML_NS, 'img'],
  [$HTML_NS, 'iframe'],
  [$HTML_NS, 'embed'],
  [$HTML_NS, 'object'],
  [$HTML_NS, 'video'],
  [$HTML_NS, 'audio'],
  [$HTML_NS, 'canvas'],
  [$HTML_NS, 'area'],
  [$HTML_NS, 'script'],
  [$HTML_NS, 'noscript'],
  [$HTML_NS, 'event-source'],
  [$HTML_NS, 'command'],
  [$HTML_NS, 'font'],
];

my $HTMLStructuredInlineLevelElements = [
  [$HTML_NS, 'blockquote'],
  [$HTML_NS, 'pre'],
  [$HTML_NS, 'ol'],
  [$HTML_NS, 'ul'],
  [$HTML_NS, 'dl'],
  [$HTML_NS, 'table'],
  [$HTML_NS, 'menu'],
];

my $HTMLInteractiveElements = [
  [$HTML_NS, 'a'],
  [$HTML_NS, 'details'],
  [$HTML_NS, 'datagrid'],
];

my $HTMLTransparentElements = [
  [$HTML_NS, 'ins'],
  [$HTML_NS, 'font'],
];
# TODO: script, if scripting is disabled

# TODO: semi-transparent video, audio

my $HTMLEmbededElements = [
  [$HTML_NS, 'img'],
  [$HTML_NS, 'iframe'],
  [$HTML_NS, 'embed'],
  [$HTML_NS, 'object'],
  [$HTML_NS, 'video'],
  [$HTML_NS, 'audio'],
  [$HTML_NS, 'canvas'],
];

## Empty
my $HTMLEmptyChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});

  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      $onerror->(node => $node, type => 'element not allowed');
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 3 or $nt == 4) {
      $onerror->(node => $node, type => 'character not allowed');
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
};

## Text
my $HTMLTextChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});

  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      $onerror->(node => $node, type => 'element not allowed');
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
};

## Zero or more |html:style| elements,
## followed by zero or more block-level elements
my $HTMLStylableBlockChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});
  
  my $has_non_style;
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      if ($node->manakai_element_type_match ($HTML_NS, 'style')) {
        if ($has_non_style) {
          $onerror->(node => $node, type => 'element not allowed');
        }
      } else {
        $has_non_style = 1;
        CHK: {
          for (@{$HTMLBlockLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $onerror->(node => $node, type => 'element not allowed');
        } # CHK
      }
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $onerror->(node => $node, type => 'character not allowed');
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
}; # $HTMLStylableBlockChecker

## Zero or more block-level elements
my $HTMLBlockChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      CHK: {
        for (@{$HTMLBlockLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $onerror->(node => $node, type => 'element not allowed');
      } # CHK
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $onerror->(node => $node, type => 'character not allowed');
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
}; # $HTMLBlockChecker

## Inline-level content
my $HTMLInlineChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      CHK: {
        for (@{$HTMLStrictlyInlineLevelElements},
             @{$HTMLStructuredInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $onerror->(node => $node, type => 'element not allowed');
      } # CHK
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
}; # $HTMLStrictlyInlineChecker

my $HTMLSignificantInlineChecker = $HTMLInlineChecker;
## TODO: check significant content

## Strictly inline-level content
my $HTMLStrictlyInlineChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});
  
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      CHK: {
        for (@{$HTMLStrictlyInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $onerror->(node => $node, type => 'element not allowed');
      } # CHK
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
}; # $HTMLStrictlyInlineChecker

my $HTMLSignificantStrictlyInlineChecker = $HTMLStrictlyInlineChecker;
## TODO: check significant content

my $HTMLBlockOrInlineChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});
  
  my $content = 'block-or-inline'; # or 'block' or 'inline'
  my @block_not_inline;
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      if ($content eq 'block') {
        CHK: {
          for (@{$HTMLBlockLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $onerror->(node => $node, type => 'element not allowed');
        } # CHK
      } elsif ($content eq 'inline') {
        CHK: {
          for (@{$HTMLStrictlyInlineLevelElements},
               @{$HTMLStructuredInlineLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $onerror->(node => $node, type => 'element not allowed');
        } # CHK
      } else {
        my $is_block;
        my $is_inline;
        for (@{$HTMLBlockLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            $is_block = 1;
            last;
          }
        }
        
        for (@{$HTMLStrictlyInlineLevelElements},
             @{$HTMLStructuredInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            $is_inline = 1;
            last;
          }
        }
        
        push @block_not_inline, $node if $is_block and not $is_inline;
        unless ($is_block) {
          $content = 'inline';
          for (@block_not_inline) {
            $onerror->(node => $_, type => 'element not allowed');
          }
          unless ($is_inline) {
            $onerror->(node => $node, type => 'element not allowed');
          }
        }
      }
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        if ($content eq 'block') {
          $onerror->(node => $node, type => 'character not allowed');
        } else {
          $content = 'inline';
          for (@block_not_inline) {
            $onerror->(node => $_, type => 'element not allowed');
          }
        }
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
};

my $HTMLStyledBlockOrInlineChecker = sub {
  my (undef, $el, $onerror) = @_;
  my $children = [];
  my @nodes = (@{$el->child_nodes});
  
  my $has_non_style;
  my $content = 'block-or-inline'; # or 'block' or 'inline'
  my @block_not_inline;
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($nt == 1) {
      if ($node->manakai_element_type_match ($HTML_NS, 'style')) {
        if ($has_non_style) {
          $onerror->(node => $node, type => 'element not allowed');
        }
      } elsif ($content eq 'block') {
        $has_non_style = 1;
        CHK: {
          for (@{$HTMLBlockLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $onerror->(node => $node, type => 'element not allowed');
        } # CHK
      } elsif ($content eq 'inline') {
        $has_non_style = 1;
        CHK: {
          for (@{$HTMLStrictlyInlineLevelElements},
               @{$HTMLStructuredInlineLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $onerror->(node => $node, type => 'element not allowed');
        } # CHK
      } else {
        $has_non_style = 1;
        my $is_block;
        my $is_inline;
        for (@{$HTMLBlockLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            $is_block = 1;
            last;
          }
        }
        
        for (@{$HTMLStrictlyInlineLevelElements},
             @{$HTMLStructuredInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            $is_inline = 1;
            last;
          }
        }
        
        push @block_not_inline, $node if $is_block and not $is_inline;
        unless ($is_block) {
          $content = 'inline';
          for (@block_not_inline) {
            $onerror->(node => $_, type => 'element not allowed');
          }
          unless ($is_inline) {
            $onerror->(node => $node, type => 'element not allowed');
          }
        }
      }
      TP: {
        for (@{$HTMLTransparentElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            unshift @nodes, @{$node->child_nodes};
            last TP;
          }
        }
        push @$children, $node;
      } # TP
    } elsif ($nt == 3 or $nt == 4) {
      if ($node->data =~ /[^\x09-\x0D\x20]/) {
        $has_non_style = 1;
        if ($content eq 'block') {
          $onerror->(node => $node, type => 'character not allowed');
        } else {
          $content = 'inline';
          for (@block_not_inline) {
            $onerror->(node => $_, type => 'element not allowed');
          }
        }
      }
    } elsif ($nt == 5) {
      unshift @nodes, @{$node->child_nodes};
    }
  }
  return ($children);
};

my $HTMLTransparentChecker = $HTMLBlockOrInlineChecker;

$Element->{$HTML_NS}->{html} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before head';
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($phase eq 'before head') {
          if ($node->manakai_element_type_match ($HTML_NS, 'head')) {
            $phase = 'after head';            
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'body')) {
            $onerror->(node => $node, type => 'element missing before:head');
            $phase = 'after body';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
            # before head
          }
        } elsif ($phase eq 'after head') {
          if ($node->manakai_element_type_match ($HTML_NS, 'body')) {
            $phase = 'after body';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
            # after head
          }
        } else { #elsif ($phase eq 'after body') {
          $onerror->(node => $node, type => 'element not allowed');
          # after body
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{head} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $has_meta_charset;
    my $has_title;
    my $has_base;
    my $has_non_base;
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($node->manakai_element_type_match ($HTML_NS, 'title')) {
          $has_non_base = 1;
          unless ($has_title) {
            $has_title = 1;
          } else {
            $onerror->(node => $node, type => 'duplicate:title');
          }
        } elsif ($node->manakai_element_type_match ($HTML_NS, 'meta')) {
          $has_non_base = 1;
          if ($node->has_attribute_ns (undef, 'charset')) {
            unless ($has_meta_charset) {
              if ($has_base) {
                $onerror->(node => $node, type => 'element not allowed');
                ## NOTE: See |base|'s "contexts" field in the spec
              }
              $has_meta_charset = 1;
            } else {
              $onerror->(node => $node, type => 'duplicate:meta charset');
            }
          } else {
            # metadata element
          }
        } elsif ($node->manakai_element_type_match ($HTML_NS, 'base')) {
          unless ($has_base) {
            if ($has_non_base) {
              $onerror->(node => $node, type => 'element not allowed');
            }
            $has_base = 1;
          } else {
            $onerror->(node => $node, type => 'duplicate:base');
          }
        } else {
          $has_non_base = 1;
          CHK: {
            for (@{$HTMLMetadataElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $onerror->(node => $node, type => 'element not allowed');
          } # CHK
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_title) {
      $onerror->(node => $el, type => 'element missing in:title');
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{title} = {
  checker => $HTMLTextChecker,
};

$Element->{$HTML_NS}->{base} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{link} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{meta} = {
  checker => $HTMLEmptyChecker,
};

## NOTE: |html:style| has no conformance creteria on content model

$Element->{$HTML_NS}->{body} = {
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{section} = {
  checker => $HTMLStylableBlockChecker,
};

$Element->{$HTML_NS}->{nav} = {
  checker => $HTMLBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{article} = {
  checker => $HTMLStylableBlockChecker,
};

$Element->{$HTML_NS}->{blockquote} = {
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{aside} = {
  checker => $HTMLStyledBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{h1} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h2} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h3} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h4} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h5} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{h6} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

## TODO: header

## TODO: footer

$Element->{$HTML_NS}->{address} = {
  checker => $HTMLInlineChecker,
};

$Element->{$HTML_NS}->{p} = {
  checker => $HTMLSignificantInlineChecker,
};

$Element->{$HTML_NS}->{hr} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{br} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{dialog} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before dt';
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($phase eq 'before dt') {
          if ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $phase = 'before dd';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $onerror->(node => $node, type => 'element missing before:dt');
            $phase = 'before dt';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } else { # before dd
          if ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $phase = 'before dt';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $onerror->(node => $node, type => 'element missing before:dd');
            $phase = 'before dd';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    if ($phase eq 'before dd') {
      $onerror->(node => $el, type => 'element missing before:dd');
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{pre} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{ol} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        unless ($node->manakai_element_type_match ($HTML_NS, 'li')) {
          $onerror->(node => $node, type => 'element not allowed');
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{ul} = {
  checker => $Element->{$HTML_NS}->{ol}->{checker},
};

## TODO: li

$Element->{$HTML_NS}->{dl} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before dt';
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($phase eq 'in dds') {
          if ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            #$phase = 'in dds';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $phase = 'in dts';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in dts') {
          if ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            #$phase = 'in dts';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $phase = 'in dds';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } else { # before dt
          if ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $phase = 'in dts';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $onerror->(node => $node, type => 'element missing before:dt');
            $phase = 'in dds';
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    if ($phase eq 'in dts') {
      $onerror->(node => $el, type => 'element missing before:dd');
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{dt} = {
  checker => $HTMLStrictlyInlineChecker,
};

## TODO: dd

## TODO: a

## TODO: q

$Element->{$HTML_NS}->{cite} = {
  checker => $HTMLStrictlyInlineChecker,
};

## TODO: em

## TODO: strong, small, m, dfn

$Element->{$HTML_NS}->{abbr} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{time} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{meter} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{progress} = {
  checker => $HTMLStrictlyInlineChecker,
};

## TODO: code

$Element->{$HTML_NS}->{var} = {
  checker => $HTMLStrictlyInlineChecker,
};

## TODO: samp

$Element->{$HTML_NS}->{kbd} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{sub} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{sup} = {
  checker => $HTMLStrictlyInlineChecker,
};

## TODO: span

$Element->{$HTML_NS}->{i} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{b} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{bdo} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{ins} = {
  checker => $HTMLTransparentChecker,
};

$Element->{$HTML_NS}->{del} = {
  checker => sub {
    my ($self, $el, $onerror) = @_;

    my $parent = $el->manakai_parent_element;
    if (defined $parent) {
      my $nsuri = $parent->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      my $ln = $parent->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
        $ElementDefault;
      return $eldef->{checker}->($self, $el, $onerror);
    } else {
      return $HTMLBlockOrInlineChecker->($self, $el, $onerror);
    }
  },
};

## TODO: figure

$Element->{$HTML_NS}->{img} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{iframe} = {
  checker => $HTMLTextChecker,
};

$Element->{$HTML_NS}->{embed} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{param} = {
  checker => $HTMLEmptyChecker,
};

## TODO: object

## TODO: video, audio

$Element->{$HTML_NS}->{source} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{canvas} = {
  checker => $HTMLInlineChecker,
};

$Element->{$HTML_NS}->{map} = {
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{area} = {
  checker => $HTMLEmptyChecker,
};
## TODO: only in map

$Element->{$HTML_NS}->{table} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $phase = 'before caption';
    my $has_tfoot;
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($phase eq 'in tbodys') {
          if ($node->manakai_element_type_match ($HTML_NS, 'tbody')) {
            #$phase = 'in tbodys';
          } elsif (not $has_tfoot and
                   $node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'after tfoot';
            $has_tfoot = 1;
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in trs') {
          if ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
            #$phase = 'in trs';
          } elsif (not $has_tfoot and
                   $node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'after tfoot';
            $has_tfoot = 1;
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'after thead') {
          if ($node->manakai_element_type_match ($HTML_NS, 'tbody')) {
            $phase = 'in tbodys';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
            $phase = 'in trs';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'in tbodys';
            $has_tfoot = 1;
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in colgroup') {
          if ($node->manakai_element_type_match ($HTML_NS, 'colgroup')) {
            $phase = 'in colgroup';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'thead')) {
            $phase = 'after thead';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tbody')) {
            $phase = 'in tbodys';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
            $phase = 'in trs';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'in tbodys';
            $has_tfoot = 1;
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'before caption') {
          if ($node->manakai_element_type_match ($HTML_NS, 'caption')) {
            $phase = 'in colgroup';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'colgroup')) {
            $phase = 'in colgroup';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'thead')) {
            $phase = 'after thead';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tbody')) {
            $phase = 'in tbodys';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
            $phase = 'in trs';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'in tbodys';
            $has_tfoot = 1;
          } else {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } else { # after tfoot
          $onerror->(node => $node, type => 'element not allowed');
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{caption} = {
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{colgroup} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        unless ($node->manakai_element_type_match ($HTML_NS, 'col')) {
          $onerror->(node => $node, type => 'element not allowed');
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{col} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{tbody} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $has_tr;
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
          $has_tr = 1;
        } else {
          $onerror->(node => $node, type => 'element not allowed');
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_tr) {
      $onerror->(node => $el, type => 'element missing in:tr');
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{thead} = {
  checker => $Element->{$HTML_NS}->{tbody},
};

$Element->{$HTML_NS}->{tfoot} = {
  checker => $Element->{$HTML_NS}->{tbody},
};

$Element->{$HTML_NS}->{tr} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $has_td;
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($node->manakai_element_type_match ($HTML_NS, 'td') or
            $node->manakai_element_type_match ($HTML_NS, 'th')) {
          $has_td = 1;
        } else {
          $onerror->(node => $node, type => 'element not allowed');
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $onerror->(node => $node, type => 'character not allowed');
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_td) {
      $onerror->(node => $el, type => 'element missing in:td or th');
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{td} = {
  checker => $HTMLBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{th} = {
  checker => $HTMLBlockOrInlineChecker,
};

## TODO: forms

## TODO: script

## TODO: noscript

$Element->{$HTML_NS}->{'event-source'} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{details} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});

    my $has_legend;
    my $has_non_legend;
    my $content = 'block-or-inline'; # or 'block' or 'inline'
    my @block_not_inline;
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if (not $has_legend and
            $node->manakai_element_type_match ($HTML_NS, 'legend')) {
          $has_legend = 1;
          if ($has_non_legend) {
            $onerror->(node => $node, type => 'element not allowed');
          }
        } elsif ($content eq 'block') {
          $has_non_legend = 1;
          CHK: {
            for (@{$HTMLBlockLevelElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $onerror->(node => $node, type => 'element not allowed');
          } # CHK
        } elsif ($content eq 'inline') {
          $has_non_legend = 1;
          CHK: {
            for (@{$HTMLStrictlyInlineLevelElements},
                 @{$HTMLStructuredInlineLevelElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $onerror->(node => $node, type => 'element not allowed');
          } # CHK
        } else {
          $has_non_legend = 1;
          my $is_block;
          my $is_inline;
          for (@{$HTMLBlockLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              $is_block = 1;
              last;
            }
          }
          
          for (@{$HTMLStrictlyInlineLevelElements},
               @{$HTMLStructuredInlineLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              $is_inline = 1;
              last;
            }
          }

          push @block_not_inline, $node if $is_block and not $is_inline;
          unless ($is_block) {
            $content = 'inline';
            for (@block_not_inline) {
              $onerror->(node => $_, type => 'element not allowed');
            }
            unless ($is_inline) {
              $onerror->(node => $node, type => 'element not allowed');
            }
          }
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          $has_non_legend = 1;
          if ($content eq 'block') {
            $onerror->(node => $node, type => 'character not allowed');
          } else {
            $content = 'inline';
            for (@block_not_inline) {
              $onerror->(node => $_, type => 'element not allowed');
            }
          }
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    unless ($has_legend) {
      $onerror->(node => $el, type => 'element missing in:legend');
    }
    return ($children);
  },
};

$Element->{$HTML_NS}->{datagrid} = {
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{command} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{menu} = {
  checker => sub {
    my (undef, $el, $onerror) = @_;
    my $children = [];
    my @nodes = (@{$el->child_nodes});
    
    my $content = 'li or inline';
    while (@nodes) {
      my $node = shift @nodes;
      my $nt = $node->node_type;
      if ($nt == 1) {
        if ($node->manakai_element_type_match ($HTML_NS, 'li')) {
          if ($content eq 'inline') {
            $onerror->(node => $node, type => 'element not allowed');
          } elsif ($content eq 'li or inline') {
            $content = 'li';
          }
        } else {
          CHK: {
            for (@{$HTMLStrictlyInlineLevelElements},
                 @{$HTMLStructuredInlineLevelElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                $content = 'inline';
                last CHK;
              }
            }
            $onerror->(node => $node, type => 'element not allowed');
          } # CHK
        }
        TP: {
          for (@{$HTMLTransparentElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              unshift @nodes, @{$node->child_nodes};
              last TP;
            }
          }
          push @$children, $node;
        } # TP
      } elsif ($nt == 3 or $nt == 4) {
        if ($node->data =~ /[^\x09-\x0D\x20]/) {
          if ($content eq 'li') {
            $onerror->(node => $node, type => 'character not allowed');
          } elsif ($content eq 'li or inline') {
            $content = 'inline';
          }
        }
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }
    return ($children);
  },
};

## TODO: legend

$Element->{$HTML_NS}->{div} = {
  checker => $HTMLStyledBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{font} = {
  checker => $HTMLTransparentChecker,
};

my $Attr = {

};

sub check_element ($$$) {
  my ($self, $el, $onerror) = @_;

  my @nodes = ($el);
  while (@nodes) {
    my $node = shift @nodes;
    my $nsuri = $node->namespace_uri;
    $nsuri = '' unless defined $nsuri;
    my $ln = $node->manakai_local_name;
    my $eldef = $Element->{$nsuri}->{$ln} ||
      $Element->{$nsuri}->{''} ||
      $ElementDefault;
    my ($children) = $eldef->{checker}->($self, $node, $onerror);
    push @nodes, @$children;
  }
} # check_element

1;
# $Date: 2007/05/04 09:18:20 $
