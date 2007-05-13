package Whatpm::ContentChecker;
use strict;

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
  [$HTML_NS, 'base'],
  [$HTML_NS, 'title'],
];

my $HTMLSectioningElements = {
  $HTML_NS => {qw/body 1 section 1 nav 1 article 1 blockquote 1 aside 1/},
};

my $HTMLBlockLevelElements = [
  [$HTML_NS, 'section'],
  [$HTML_NS, 'nav'],
  [$HTML_NS, 'article'],
  [$HTML_NS, 'blockquote'],
  [$HTML_NS, 'aside'],
  [$HTML_NS, 'h1'],
  [$HTML_NS, 'h2'],
  [$HTML_NS, 'h3'],
  [$HTML_NS, 'h4'],
  [$HTML_NS, 'h5'],
  [$HTML_NS, 'h6'],
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
  [$HTML_NS, 'noscript'], ## NOTE: If scripting is disabled.
];

#my $HTMLSemiTransparentElements = [
#  [$HTML_NS, 'video'],
#  [$HTML_NS, 'audio'],
#];

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
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      if ($node->manakai_element_type_match ($HTML_NS, 'style')) {
        if ($has_non_style) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
      } else {
        $has_non_style = 1;
        CHK: {
          for (@{$HTMLBlockLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $self->{onerror}->(node => $node, type => 'element not allowed');
        } # CHK
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
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      CHK: {
        for (@{$HTMLBlockLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed');
      } # CHK
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
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      CHK: {
        for (@{$HTMLStrictlyInlineLevelElements},
             @{$HTMLStructuredInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed');
      } # CHK
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
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      CHK: {
        for (@{$HTMLStrictlyInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed');
      } # CHK
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
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      CHK: {
        for (@{$HTMLStrictlyInlineLevelElements},
             $todo->{strictly_inline} ? () : @{$HTMLStructuredInlineLevelElements}) {
          if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
            last CHK;
          }
        }
        $self->{onerror}->(node => $node, type => 'element not allowed');
      } # CHK
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
      if ($self->{minuses}->{$node_ns}->{$node_ln}) {
        $self->{onerror}->(node => $node, type => 'element not allowed');
      }
      if ($content eq 'block') {
        CHK: {
          for (@{$HTMLBlockLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $self->{onerror}->(node => $node, type => 'element not allowed');
        } # CHK
      } elsif ($content eq 'inline') {
        CHK: {
          for (@{$HTMLStrictlyInlineLevelElements},
               @{$HTMLStructuredInlineLevelElements}) {
            if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
              last CHK;
            }
          }
          $self->{onerror}->(node => $node, type => 'element not allowed');
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
            $self->{onerror}->(node => $_, type => 'element not allowed');
          }
          unless ($is_inline) {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        }
      }
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
        if ($self->{minuses}->{$node_ns}->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        if ($node->manakai_element_type_match ($elnsuri, $ellname)) {
          if ($has_non_style) {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($content eq 'block') {
          $has_non_style = 1;
          CHK: {
            for (@{$HTMLBlockLevelElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
            unless ($is_inline) {
              $self->{onerror}->(node => $node, type => 'element not allowed');
            }
          }
        }
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

$Element->{$HTML_NS}->{html} = {
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
        if ($self->{minuses}->{$node_ns}->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        if ($phase eq 'before head') {
          if ($node->manakai_element_type_match ($HTML_NS, 'head')) {
            $phase = 'after head';            
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'body')) {
            $self->{onerror}
              ->(node => $node, type => 'ps element missing:head');
            $phase = 'after body';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
            # before head
          }
        } elsif ($phase eq 'after head') {
          if ($node->manakai_element_type_match ($HTML_NS, 'body')) {
            $phase = 'after body';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
            # after head
          }
        } else { #elsif ($phase eq 'after body') {
          $self->{onerror}->(node => $node, type => 'element not allowed');
          # after body
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
        if ($self->{minuses}->{$node_ns}->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        if ($node->manakai_element_type_match ($HTML_NS, 'title')) {
          $phase = 'after base';
          unless ($has_title) {
            $has_title = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($node->manakai_element_type_match ($HTML_NS, 'meta')) {
          if ($node->has_attribute_ns (undef, 'charset')) {
            if ($phase eq 'initial') {
              $phase = 'after charset';
            } else {
              $self->{onerror}->(node => $node, type => 'element not allowed');
              ## NOTE: See also |base|'s "contexts" field in the spec
            }
          } else {
            $phase = 'after base';
          }
        } elsif ($node->manakai_element_type_match ($HTML_NS, 'base')) {
          if ($phase eq 'initial' or $phase eq 'after charset') {
            $phase = 'after base';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } else {
          $phase = 'after base';
          CHK: {
            for (@{$HTMLMetadataElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $self->{onerror}->(node => $node, type => 'element not allowed');
          } # CHK
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
    unless ($has_title) {
      $self->{onerror}->(node => $el, type => 'child element missing:title');
    }
    return ($new_todos);
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
$Element->{$HTML_NS}->{style} = {
  checker => $AnyChecker,
};

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
  checker => $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'style'),
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

$Element->{$HTML_NS}->{footer} = {
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
        if ($self->{minuses}->{$node_ns}->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        } elsif ($node_ns eq $HTML_NS and
                 {
                   qw/h1 1 h2 1 h3 1 h4 1 h5 1 h6 1 header 1 footer 1/
                 }->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        } elsif ($HTMLSectioningElements->{$node_ns}->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        if ($content eq 'block') {
          CHK: {
            for (@{$HTMLBlockLevelElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $self->{onerror}->(node => $node, type => 'element not allowed');
          } # CHK
        } elsif ($content eq 'inline') {
          CHK: {
            for (@{$HTMLStrictlyInlineLevelElements},
                 @{$HTMLStructuredInlineLevelElements}) {
              if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
                last CHK;
              }
            }
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
              $self->{onerror}->(node => $_, type => 'element not allowed');
            }
            unless ($is_inline) {
              $self->{onerror}->(node => $node, type => 'element not allowed');
            }
          }
        }
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
        ## NOTE: |minuses| list is not checked since redundant
        if ($phase eq 'before dt') {
          if ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $phase = 'before dd';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $self->{onerror}
              ->(node => $node, type => 'ps element missing:dt');
            $phase = 'before dt';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } else { # before dd
          if ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $phase = 'before dt';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
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
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{ol} = {
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
        ## NOTE: |minuses| list is not checked since redundant
        unless ($node->manakai_element_type_match ($HTML_NS, 'li')) {
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
  checker => $Element->{$HTML_NS}->{ol}->{checker},
};

## TODO: li

$Element->{$HTML_NS}->{dl} = {
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
        ## NOTE: |minuses| list is not checked since redundant
        if ($phase eq 'in dds') {
          if ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            #$phase = 'in dds';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $phase = 'in dts';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in dts') {
          if ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            #$phase = 'in dts';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
            $phase = 'in dds';
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } else { # before dt
          if ($node->manakai_element_type_match ($HTML_NS, 'dt')) {
            $phase = 'in dts';
          } elsif ($node->manakai_element_type_match ($HTML_NS, 'dd')) {
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
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{dd} = {
  checker => sub {
    my ($self, $todo) = @_;
    if ($todo->{inline}) {
      return $HTMLInlineChecker->($self, $todo);
    } else {
      return $HTMLBlockOrInlineChecker->($self, $todo);
    }
  },
};

## TODO: a

$Element->{$HTML_NS}->{q} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{cite} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{em} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{strong} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{small} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{m} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{dfn} = {
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {dfn => 1}});
    my ($sib, $ch) = $HTMLStrictlyInlineChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

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

$Element->{$HTML_NS}->{code} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{var} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{samp} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{kbd} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{sub} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{sup} = {
  checker => $HTMLStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{span} = {
  checker => $HTMLInlineOrStrictlyInlineChecker,
};

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

$Element->{$HTML_NS}->{video} = {
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
  checker => $Element->{$HTML_NS}->{audio}->{checker},
};

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
        ## NOTE: |minuses| list is not checked since redundant
        if ($phase eq 'in tbodys') {
          if ($node->manakai_element_type_match ($HTML_NS, 'tbody')) {
            #$phase = 'in tbodys';
          } elsif (not $has_tfoot and
                   $node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'after tfoot';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
        } elsif ($phase eq 'in trs') {
          if ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
            #$phase = 'in trs';
          } elsif (not $has_tfoot and
                   $node->manakai_element_type_match ($HTML_NS, 'tfoot')) {
            $phase = 'after tfoot';
            $has_tfoot = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
  checker => $HTMLSignificantStrictlyInlineChecker,
};

$Element->{$HTML_NS}->{colgroup} = {
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
        ## NOTE: |minuses| list is not checked since redundant
        unless ($node->manakai_element_type_match ($HTML_NS, 'col')) {
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
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{tbody} = {
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
        ## NOTE: |minuses| list is not checked since redundant
        if ($node->manakai_element_type_match ($HTML_NS, 'tr')) {
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
  checker => $Element->{$HTML_NS}->{tbody},
};

$Element->{$HTML_NS}->{tfoot} = {
  checker => $Element->{$HTML_NS}->{tbody},
};

$Element->{$HTML_NS}->{tr} = {
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
        ## NOTE: |minuses| list is not checked since redundant
        if ($node->manakai_element_type_match ($HTML_NS, 'td') or
            $node->manakai_element_type_match ($HTML_NS, 'th')) {
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
  checker => $HTMLBlockOrInlineChecker,
};

$Element->{$HTML_NS}->{th} = {
  checker => $HTMLBlockOrInlineChecker,
};

## TODO: forms

$Element->{$HTML_NS}->{script} = {
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
  checker => sub {
    my ($self, $todo) = @_;

    my $end = $self->_add_minuses ({$HTML_NS => {noscript => 1}});
    my ($sib, $ch) = $HTMLBlockOrInlineChecker->($self, $todo);
    push @$sib, $end;
    return ($sib, $ch);
  },
};

$Element->{$HTML_NS}->{'event-source'} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{details} = {
  checker => $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'legend'),
};

$Element->{$HTML_NS}->{datagrid} = {
  checker => $HTMLBlockChecker,
};

$Element->{$HTML_NS}->{command} = {
  checker => $HTMLEmptyChecker,
};

$Element->{$HTML_NS}->{menu} = {
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
        if ($self->{minuses}->{$node_ns}->{$node_ln}) {
          $self->{onerror}->(node => $node, type => 'element not allowed');
        }
        if ($node->manakai_element_type_match ($HTML_NS, 'li')) {
          if ($content eq 'inline') {
            $self->{onerror}->(node => $node, type => 'element not allowed');
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
            $self->{onerror}->(node => $node, type => 'element not allowed');
          } # CHK
        }
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

## TODO: legend

$Element->{$HTML_NS}->{div} = {
  checker => $GetHTMLZeroOrMoreThenBlockOrInlineChecker->($HTML_NS, 'style'),
};

$Element->{$HTML_NS}->{font} = {
  checker => $HTMLTransparentChecker,
};

my $Attr = {

};

sub new ($) {
  return bless {}, shift;
} # new

sub check_element ($$$) {
  my ($self, $el, $onerror) = @_;

  $self->{minuses} = {};
  $self->{onerror} = $onerror;

  my @todo = ({type => 'element', node => $el});
  while (@todo) {
    my $todo = shift @todo;
    if ($todo->{type} eq 'element') {
      my $nsuri = $todo->{node}->namespace_uri;
      $nsuri = '' unless defined $nsuri;
      my $ln = $todo->{node}->manakai_local_name;
      my $eldef = $Element->{$nsuri}->{$ln} ||
        $Element->{$nsuri}->{''} ||
          $ElementDefault;
      my ($new_todos) = $eldef->{checker}->($self, $todo);
      push @todo, @$new_todos;
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
    for (@{$HTMLTransparentElements}) {
      if ($node->manakai_element_type_match ($_->[0], $_->[1])) {
        unshift @$sib, @{$node->child_nodes};
        last TP;
      }
    }
    if ($node->manakai_element_type_match ($HTML_NS, 'video') or
        $node->manakai_element_type_match ($HTML_NS, 'audio')) {
      if ($node->has_attribute_ns (undef, 'src')) {
        unshift @$sib, @{$node->child_nodes};
        last TP;
      } else {
        my @cn = @{$node->child_nodes};
        CN: while (@cn) {
          my $cn = shift @cn;
          my $cnt = $cn->node_type;
          if ($cnt == 1) {
            if ($cn->manakai_element_type_match ($HTML_NS, 'source')) {
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
# $Date: 2007/05/13 08:09:15 $
