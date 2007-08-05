package Whatpm::ContentChecker;
use strict;
require Whatpm::ContentChecker;

require Whatpm::URIChecker;

my $ATOM_NS = q<http://www.w3.org/2005/Atom>;

## MUST be well-formed XML (RFC 4287 references XML 1.0 REC 20040204)

## NOTE: Commants and PIs are not explicitly allowed.

our $AttrChecker;

## Any element MAY have xml:base, xml:lang
my $GetAtomAttrsChecker = sub {
  my $element_specific_checker = shift;
  return sub {
    my ($self, $todo) = @_;
    for my $attr (@{$todo->{node}->attributes}) {
      my $attr_ns = $attr->namespace_uri;
      $attr_ns = '' unless defined $attr_ns;
      my $attr_ln = $attr->manakai_local_name;
      my $checker;
      if ($attr_ns eq '') {
        $checker = $element_specific_checker->{$attr_ln};
      } else {
        $checker = $AttrChecker->{$attr_ns}->{$attr_ln}
            || $AttrChecker->{$attr_ns}->{''};
      }
      if ($checker) {
        $checker->($self, $attr, $todo);
      } else {
        $self->{onerror}->(node => $attr, level => 'unsupported',
                           type => 'attribute');
        ## ISSUE: No comformance createria for unknown attributes in the spec
      }
    }
  };
}; # $GetAtomAttrsChecker

my $AtomTextConstruct = {
  attrs_checker => $GetAtomAttrsChecker->({
    type => sub { 1 }, # checked in |checker|
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my $attr = $todo->{node}->get_attribute_node_ns (undef, 'type');
    my $value = 'text';
    if ($attr) {
      $value = $attr->value;
      if ($value eq 'text' or $value eq 'html' or $value eq 'xhtml') {
        # MUST
      } else {
        $self->{onerror}->(node => $attr, type => 'keyword:invalid');
      }
      # IMT MUST NOT be used
    }

    if ($value eq 'text') {
      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST NOT
          $self->{onerror}->(node => $node, type => 'element not allowed');
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      return ($new_todos);
    } elsif ($value eq 'html') {
      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST NOT
          $self->{onerror}->(node => $node, type => 'element not allowed');
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      ## TODO: SHOULD be suitable for handling as HTML [HTML4]
      # markup MUST be escaped
      ## TODO: HTML SHOULD be valid as if within <div>

      return ($new_todos);
    } elsif ($value eq 'xhtml') {
      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      my $has_div;
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST
          my $nsuri = $node->namespace_uri;
          if (defined $nsuri and
              $nsuri eq q<http://www.w3.org/1999/xhtml> and
              $node->manakai_local_name eq 'div' and
              not $has_div) {
            ## TODO: SHOULD be suitable for handling as HTML [XHTML10]
            $has_div = 1;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          ## TODO: Are white spaces allowed?
          $self->{onerror}->(node => $node, type => 'character not allowed');
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      unless ($has_div) {
        $self->{onerror}->(node => $todo->{node},
                           type => 'element missing:div');
      }

      return ($new_todos);
    }
    
  },
}; # $AtomTextConstruct

my $AtomPersonConstruct = {
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];
      
    my $has_name;
    my $has_uri;
    my $has_email;
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        # MUST
        my $nsuri = $node->namespace_uri;
        $nsuri = '' unless defined $nsuri;
        my $not_allowed;
        if ($nsuri eq $ATOM_NS) {
          my $ln = $node->manakai_local_name;
          if ($ln eq 'name') {
            unless ($has_name) {
              $has_name = 1;
            } else {
              $not_allowed = 1;
            }
          } elsif ($ln eq 'uri') {
            unless ($has_uri) {
              $has_uri = 1;
            } else {
              $not_allowed = 1; # MUST NOT
            }
          } elsif ($ln eq 'email') {
            unless ($has_email) {
              $has_email = 1;
            } else {
              $not_allowed = 1; # MUST NOT
            }
          } else {
            $not_allowed = 1;
          }
        } else {
          ## TODO: extension element
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
            if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        ## TODO: Are white spaces allowed?
        $self->{onerror}->(node => $node, type => 'character not allowed');
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    unless ($has_name) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.name');
    }

    return ($new_todos);
  },
}; # $AtomPersonConstruct

our $Element;

$Element->{$ATOM_NS}->{name} = {
  ## NOTE: Strictly speaking, structure and semantics for atom:name
  ## element outside of Person construct is not defined.
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## NOTE: No constraint.
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        #
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{uri} = {
  ## NOTE: Strictly speaking, structure and semantics for atom:uri
  ## element outside of Person construct is not defined.
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    my $s = '';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## NOTE: Not explicitly disallowed.
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        $s .= $node->data;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri_reference ($s, sub {
      my %opt = @_;
      $self->{onerror}->(node => $todo->{node}, level => $opt{level},
                         type => 'URI::'.$opt{type}.
                         (defined $opt{position} ? ':'.$opt{position} : ''));
    });

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{email} = {
  ## NOTE: Strictly speaking, structure and semantics for atom:email
  ## element outside of Person construct is not defined.
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    my $s = '';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## NOTE: Not explicitly disallowed.
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        $s .= $node->data;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## TODO: addr-spec
    $self->{onerror}->(node => $todo->{node}, type => 'addr-spec',
                       level => 'unsupported');

    return ($new_todos);
  },
};

## MUST NOT be any white space
my $AtomDateConstruct = {
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    my $s = '';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## NOTE: It does not explicitly say that there MUST NOT be any element.
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        $s .= $node->data;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## TODO: $s =~ MUST RFC 3339 date-time, uppercase T, Z
    # SHOULD be accurate as possible

    return ($new_todos);
  },
}; # $AtomDateConstruct

$Element->{$ATOM_NS}->{entry} = {
  is_root => 1,
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    ## TODO: MUST author+ unless (child::source/child::author)
    ## or (parent::feed/child::author)

    my $has_element = {};
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        # MUST
        my $nsuri = $node->namespace_uri;
        $nsuri = '' unless defined $nsuri;
        my $not_allowed;
        if ($nsuri eq $ATOM_NS) {
          my $ln = $node->manakai_local_name;
          if ({ # MUST (0, 1)
               content => 1,
               id => 1,
               published => 1,
               rights => 1,
               source => 1,
               summary => 1,
               ## TODO: MUST if child::content/@src | child::content/@type = IMT, !text/ !/xml !+xml
               title => 1,
               updated => 1,
              }->{$ln}) {
            unless ($has_element->{$ln}) {
              $has_element->{$ln} = 1;
              $not_allowed = $has_element->{entry};
            } else {
              $not_allowed = 1;
            }
          } elsif ($ln eq 'link') { # MAY
            ## TODO: MUST link rel=alternate + unless child::content
            ## TODO: MUST NOT rel=alternate with same (type, hreflang) +
            ## NOTE: MAY
            # 
            $not_allowed = $has_element->{entry};
          } elsif ({ # MAY
                    author => 1,
                    category => 1,
                    contributor => 1,
              }->{$ln}) {
            $not_allowed = $has_element->{entry};
          } else {
            $not_allowed = 1;
          }
        } else {
          ## TODO: extension element
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
            if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        ## TODO: Are white spaces allowed?
        $self->{onerror}->(node => $node, type => 'character not allowed');
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## NOTE: metadata elements, followed by atom:entry* (no explicit MAY)

    ## TODO: If entry's with same id, then updated SHOULD be different

    unless ($has_element->{id}) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.id');
    }
    unless ($has_element->{title}) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.title');
    }
    unless ($has_element->{updated}) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.updated');
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{feed} = {
  is_root => 1,
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    ## TODO: MUST author+ unless all entry child has author+.

    my $has_element = {};
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        my $nsuri = $node->namespace_uri;
        $nsuri = '' unless defined $nsuri;
        my $not_allowed;
        if ($nsuri eq $ATOM_NS) {
          my $ln = $node->manakai_local_name;
          if ($ln eq 'entry') {
            $has_element->{entry} = 1;
          } elsif ({ # MUST (0, 1)
               generator => 1,
               icon => 1,
               id => 1,
               logo => 1,
               rights => 1,
               subtitle => 1,
               title => 1,
               updated => 1,
              }->{$ln}) {
            unless ($has_element->{$ln}) {
              $has_element->{$ln} = 1;
              $not_allowed = $has_element->{entry};
            } else {
              $not_allowed = 1;
            }
          } elsif ($ln eq 'link') { # MAY
            ## TODO: SHOULD rel=self
            ## TODO: MUST NOT rel=alternate with same (type, hreflang)
            # 
            $not_allowed = $has_element->{entry};
          } elsif ({ # MAY
                    author => 1,
                    category => 1,
                    contributor => 1,
                   }->{$ln}) {
            $not_allowed = $has_element->{entry};
          } else {
            $not_allowed = 1;
          }
        } else {
          ## TODO: extension element
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
            if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        ## TODO: Are white spaces allowed?
        $self->{onerror}->(node => $node, type => 'character not allowed');
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## NOTE: metadata elements, followed by atom:entry* (no explicit MAY)

    ## TODO: If entry's with same id, then updated SHOULD be different

    unless ($has_element->{id}) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.id');
    }
    unless ($has_element->{title}) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.title');
    }
    unless ($has_element->{updated}) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'element missing:atom.updated');
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{content} = {
  attrs_checker => $GetAtomAttrsChecker->({
    src => sub { 1 }, # checked in |checker|
    type => sub { 1 }, # checked in |checker|
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my $attr = $todo->{node}->get_attribute_node_ns (undef, 'type');
    my $src_attr = $todo->{node}->get_attribute_node_ns (undef, 'src');
    my $value;
    if ($attr) {
      $value = $attr->value;
      if ($value eq 'text' or $value eq 'html' or $value eq 'xhtml') {
        # MUST
      } else {

      }
      # IMT MUST NOT be used
    } elsif ($src_attr) {
      $value = '';
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:type', level => 's');
    } else {
      $value = 'text';
    }

    ## TODO: type MUST be text/html/xhtml or MIME media type

    ## TODO: This implementation is not optimal.

    if ($src_attr) {
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri_reference ($src_attr->value, sub {
        my %opt = @_;
        $self->{onerror}->(node => $todo->{node}, level => $opt{level},
                           type => 'URI::'.$opt{type}.
                           (defined $opt{position} ? ':'.$opt{position} : ''));
      });

      ## NOTE: If @src, the element MUST be empty.  What is "empty"?
      ## Is |<e><!----></e>| empty?  |<e>&e;</e>| where |&e;| has
      ## empty replacement tree shuld be empty, since Atom is defined
      ## in terms of XML Information Set where entities are expanded.
      ## (but what if |&e;| is an unexpanded entity?)
    }

    if ($value eq 'text') {
      $self->{onerror}->(node => $attr, type => 'not IMT') if $src_attr;

      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST NOT
          $self->{onerror}->(node => $node, type => 'element not allowed');
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          $self->{onerror}->(node => $node, type => 'character not allowed')
              if $src_attr;
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      return ($new_todos);
    } elsif ($value eq 'html') {
      $self->{onerror}->(node => $attr, type => 'not IMT') if $src_attr;

      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST NOT
          $self->{onerror}->(node => $node, type => 'element not allowed');
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          $self->{onerror}->(node => $node, type => 'character not allowed')
              if $src_attr;
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      ## TODO: SHOULD be suitable for handling as HTML [HTML4]
      # markup MUST be escaped
      ## TODO: HTML SHOULD be valid as if within <div>

      return ($new_todos);
    } elsif ($value eq 'xhtml') {
      $self->{onerror}->(node => $attr, type => 'not IMT') if $src_attr;

      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      my $has_div;
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST
          my $nsuri = $node->namespace_uri;
          if (defined $nsuri and
              $nsuri eq q<http://www.w3.org/1999/xhtml> and
              $node->manakai_local_name eq 'div' and
              not $has_div) {
            ## TODO: SHOULD be suitable for handling as HTML [XHTML10]
            $has_div = 1;
            $self->{onerror}->(node => $node, type => 'element not allowed')
                if $src_attr;
          } else {
            $self->{onerror}->(node => $node, type => 'element not allowed');
          }
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          ## TODO: Are white spaces allowed?
          $self->{onerror}->(node => $node, type => 'character not allowed');
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      unless ($has_div) {
        $self->{onerror}->(node => $todo->{node},
                           type => 'element missing:div');
      }

      return ($new_todos);
    } elsif ($value =~ m![+/][Xx][Mm][Ll]\z!) {
      ## ISSUE: There is no definition for "XML media type" in RFC 3023.
      ## Is |application/xml-dtd| an XML media type?

      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          ## MAY contain elements
          $self->{onerror}->(node => $node, type => 'element not allowed')
              if $src_attr;
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          ## TODO: Are white spaces allowed?
          $self->{onerror}->(node => $node, type => 'character not allowed');
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      ## TODO: SHOULD be suitable for handling as $value.
      ## If no @src, this would normally mean it contains a 
      ## single child element that would serve as the root element.

      return ($new_todos);
    } elsif ($value =~ m!^[Tt][Ee][Xx][Tt]/!) {
      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];
      
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          # MUST NOT
          $self->{onerror}->(node => $node, type => 'element not allowed');
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          $self->{onerror}->(node => $node, type => 'character not allowed')
              if $src_attr;
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      ## NOTE: No further restriction (such as to conform to the type).

      return ($new_todos);
    } else {
      my @nodes = (@{$todo->{node}->child_nodes});
      my $new_todos = [];

      if ($value =~ m!^(?>message|multipart)/!i) { # MUST NOT
        $self->{onerror}->(node => $attr, type => 'IMT:composite');
      }

      my $s = '';
      while (@nodes) {
        my $node = shift @nodes;
        $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
        my $nt = $node->node_type;
        if ($nt == 1) {
          ## not explicitly disallowed
          $self->{onerror}->(node => $node, type => 'element not allowed');
          my ($sib, $ch) = $self->_check_get_children ($node, $todo);
          unshift @nodes, @$sib;
          push @$new_todos, @$ch;
        } elsif ($nt == 3 or $nt == 4) {
          $s .= $node->data;
          $self->{onerror}->(node => $node, type => 'character not allowed')
              if $src_attr;
        } elsif ($nt == 5) {
          unshift @nodes, @{$node->child_nodes};
        }
      }

      ## TODO: $s = valid Base64ed [RFC 3548] where 
      ## MAY leading and following "white space" (what?)
      ## and lines separated by a single U+000A
      ## SHOULD be suitable for the indicated media type

      return ($new_todos);
    }
  },
};

$Element->{$ATOM_NS}->{author} = $AtomPersonConstruct;

$Element->{$ATOM_NS}->{category} = {
  attrs_checker => $GetAtomAttrsChecker->({
    label => sub { 1 }, # no value constraint
    scheme => sub { # NOTE: No MUST.
      my ($self, $attr) = @_;
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri ($attr->value, sub {
        my %opt = @_;
        $self->{onerror}->(node => $attr, level => $opt{level},
                           type => 'URI::'.$opt{type}.
                           (defined $opt{position} ? ':'.$opt{position} : ''));
      });
    },
    term => sub { 1 }, # no value constraint
  }),
  checker => sub {
    my ($self, $todo) = @_;

    unless ($todo->{node}->has_attribute_ns (undef, 'term')) {
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:term');
    }

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];
    
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        #
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{contributor} = $AtomPersonConstruct;

$Element->{$ATOM_NS}->{generator} = {
  attrs_checker => $GetAtomAttrsChecker->({
    uri => sub { # MUST
      my ($self, $attr) = @_;
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri_reference ($attr->value, sub {
        my %opt = @_;
        $self->{onerror}->(node => $attr, level => $opt{level},
                           type => 'URI::'.$opt{type}.
                           (defined $opt{position} ? ':'.$opt{position} : ''));
      });
      ## NOTE: Dereferencing SHOULD produce a representation
      ## that is relevant to the agent.
    },
    version => sub { 1 }, # no value constraint
  }),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];
    
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## not explicitly disallowed
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        ## MUST be a string that is a human-readable name for
        ## the generating agent
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{icon} = {
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];
    
    my $s = '';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## not explicitly disallowed
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        $s .= $node->data;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## NOTE: No MUST.
    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri_reference ($s, sub {
      my %opt = @_;
      $self->{onerror}->(node => $todo->{node}, level => $opt{level},
                         type => 'URI::'.$opt{type}.
                         (defined $opt{position} ? ':'.$opt{position} : ''));
    });

    ## NOTE: Image SHOULD be 1:1 and SHOULD be small

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{id} = {
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    my $s = '';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## not explicitly disallowed
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        $s .= $node->data;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri ($s, sub { # MUST
      my %opt = @_;
      $self->{onerror}->(node => $todo->{node}, level => $opt{level},
                         type => 'URI::'.$opt{type}.
                         (defined $opt{position} ? ':'.$opt{position} : ''));
    });
    ## TODO: SHOULD be normalized

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{link} = {
  attrs_checker => $GetAtomAttrsChecker->({
    href => sub {
      my ($self, $attr) = @_;
      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri_reference ($attr->value, sub {
        my %opt = @_;
        $self->{onerror}->(node => $attr, level => $opt{level},
                           type => 'URI::'.$opt{type}.
                           (defined $opt{position} ? ':'.$opt{position} : ''));
      });
    },
    hreflang => sub { }, # TODO: MUST be an RFC 3066 language tag
    length => sub { }, # No MUST; in octets.
    rel => sub { # MUST
      my ($self, $attr) = @_;
      my $value = $attr->value;
      if ($value =~ /\A(?>[0-9A-Za-z._~!\$&'()*+,;=\x{A0}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}-]|%[0-9A-Fa-f][0-9A-Fa-f]|\@)+\z/) {
        $value = q<http://www.iana.org/assignments/relation/> . $value;
      }

      ## NOTE: There MUST NOT be any white space.
      Whatpm::URIChecker->check_iri ($value, sub {
        my %opt = @_;
        $self->{onerror}->(node => $attr, level => $opt{level},
                           type => 'URI::'.$opt{type}.
                           (defined $opt{position} ? ':'.$opt{position} : ''));
      });

      ## TODO: Warn if unregistered
    },
    type => sub { }, # TODO: MUST be a MIME media type
  }),
  checker => sub {
    my ($self, $todo) = @_;

    unless ($todo->{node}->has_attribute_ns (undef, 'href')) { # MUST
      $self->{onerror}->(node => $todo->{node},
                         type => 'attribute missing:href');
    }

    if ($todo->{node}->rel eq
            q<http://www.iana.org/assignments/relation/enclosure> and
        not $todo->{node}->has_attribute_ns (undef, 'length')) {
      $self->{onerror}->(node => $todo->{node}, level => 's',
                         type => 'attribute missing:length');
    }

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];
    
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        #
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{logo} = {
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];

    my $s = '';
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
      
      my $nt = $node->node_type;
      if ($nt == 1) {
        ## not explicitly disallowed
        $self->{onerror}->(node => $node, type => 'element not allowed');
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        $s .= $node->data;
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    ## NOTE: There MUST NOT be any white space.
    Whatpm::URIChecker->check_iri_reference ($s, sub {
      my %opt = @_;
      $self->{onerror}->(node => $todo->{node}, level => $opt{level},
                         type => 'URI::'.$opt{type}.
                         (defined $opt{position} ? ':'.$opt{position} : ''));
    });
    
    ## NOTE: Image SHOULD be 2:1

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{published} = $AtomDateConstruct;

$Element->{$ATOM_NS}->{rights} = $AtomDateConstruct;
## SHOULD NOT be used to convey machine-readable information.

$Element->{$ATOM_NS}->{source} = {
  attrs_checker => $GetAtomAttrsChecker->({}),
  checker => sub {
    my ($self, $todo) = @_;

    my @nodes = (@{$todo->{node}->child_nodes});
    my $new_todos = [];
    my $has_element = {};
    while (@nodes) {
      my $node = shift @nodes;
      $self->_remove_minuses ($node) and next if ref $node eq 'HASH';
        
      my $nt = $node->node_type;
      if ($nt == 1) {
        my $nsuri = $node->namespace_uri;
        $nsuri = '' unless defined $nsuri;
        my $not_allowed;
        if ($nsuri eq $ATOM_NS) {
          my $ln = $node->manakai_local_name;
          if ($ln eq 'entry') {
            $has_element->{entry} = 1;
          } elsif ({
               generator => 1,
               icon => 1,
               id => 1,
               logo => 1,
               rights => 1,
               subtitle => 1,
               title => 1,
               updated => 1,
              }->{$ln}) {
            unless ($has_element->{$ln}) {
              $has_element->{$ln} = 1;
              $not_allowed = $has_element->{entry};
            } else {
              $not_allowed = 1;
            }
          } elsif ($ln eq 'link') {
            ## TODO: MUST NOT rel=alternate with same (type, hreflang)
            # 
            $not_allowed = $has_element->{entry};
          } elsif ({
                    author => 1,
                    category => 1,
                    contributor => 1,
                   }->{$ln}) {
            $not_allowed = $has_element->{entry};
          } else {
            $not_allowed = 1;
          }
        } else {
          ## TODO: extension element
          $not_allowed = 1;
        }
        $self->{onerror}->(node => $node, type => 'element not allowed')
            if $not_allowed;
        my ($sib, $ch) = $self->_check_get_children ($node, $todo);
        unshift @nodes, @$sib;
        push @$new_todos, @$ch;
      } elsif ($nt == 3 or $nt == 4) {
        ## TODO: Are white spaces allowed?
        $self->{onerror}->(node => $node, type => 'character not allowed');
      } elsif ($nt == 5) {
        unshift @nodes, @{$node->child_nodes};
      }
    }

    return ($new_todos);
  },
};

$Element->{$ATOM_NS}->{subtitle} = $AtomTextConstruct;

$Element->{$ATOM_NS}->{summary} = $AtomTextConstruct;

$Element->{$ATOM_NS}->{title} = $AtomTextConstruct;

$Element->{$ATOM_NS}->{updated} = $AtomDateConstruct;

## TODO: signature element

## TODO: simple extension element and structured extension element

$Whatpm::ContentChecker::Namespace->{$ATOM_NS}->{loaded} = 1;

1;
