package Message::DOM::TreeWalker;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::TreeWalker';
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    expand_entity_references => 1,
    filter => 1,
    root => 1,
    what_to_show => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) { \$_[0]->{$method_name} }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

sub ___report_error ($$) { $_[1]->throw }

## TODO: Documentation
sub clone ($) {
  return bless {%{$_[0]}}, ref $_[0];
} # clone

## |TreeWalker| attributes

sub current_node ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{current_node} = $_[1];
    } else {
      require Message::DOM::DOMException;
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NOT_SUPPORTED_ERR',
          -subtype => 'NULLPO_ERR';
    }
  }

  return $_[0]->{current_node};
} # current_node

sub expand_entity_references ($);

sub filter ($);

sub root ($);

sub what_to_show ($);

## |TreeWalker| methods

sub first_child ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $sresult = $_[0]->_test_node ($_[0]->{current_node});

  if ($sresult != 12101) { # MANAKAI_FILTER_OPAQUE
    my @target = (@{$_[0]->{current_node}->child_nodes});
    A: while (@target) {
      my $target = shift @target;
      my $result = $_[0]->_test_node ($target);
      if ($result == 1 or $result == 12101) {
        # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
        return ($_[0]->{current_node} = $target);
      } elsif ($result == 3) { # FILTER_SKIP
        unshift @target, @{$target->child_nodes};
      }
    } # A
  } # not opaque

  return undef;
} # first_child

sub last_child ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $sresult = $_[0]->_test_node ($_[0]->{current_node});
  if ($sresult != 12101) { # MANAKAI_FILTER_OPAQUE
    my @target = (@{$_[0]->{current_node}->child_nodes});
    A: while (@target) {
      my $target = pop @target;
      my $result = $_[0]->_test_node ($target);
      if ($result == 1 or $result == 12101) {
        # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
        return ($_[0]->{current_node} = $target);
      } elsif ($result == 3) { # FILTER_SKIP
        push @target, @{$target->child_nodes};
      }
    } # A
  }

  return undef;
} # last_child

sub next_node ($) {
  local $Error::Depth = $Error::Depth + 1;
  
  my $target = $_[0]->{current_node};
  my $tw = $_[0]->clone;
  $tw->{current_node} = $target;
  $tw->{root} = $target;
  my $fc = $tw->first_child;
  if (defined $fc) {
    return ($_[0]->{current_node} = $fc);
  }

  while (defined $target) {
    my $current = $target;
    undef $target;
    P: while (defined $current and not $current eq $_[0]->{root}) {
      $target = $current->next_sibling;
      last P if defined $target;
      $current = $current->parent_node;
    } # P
    return undef unless defined $target;
  
    my $result = $_[0]->_test_node ($target);
    if ($result == 1 or $result == 12101) {
      # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
      return ($_[0]->{current_node} = $target);
    } elsif ($result == 3) { # FILTER_SKIP
      my $tw = $_[0]->clone;
      $tw->{current_node} = $target;
      $tw->{root} = $target;
      my $fc = $tw->first_child;
      if (defined $fc) {
        return ($_[0]->{current_node} = $fc);
      }
    }
  }

  return undef;
} # next_node

sub next_sibling ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $target = $_[0]->{current_node};
  while (defined $target) {
    my $current = $target;
    undef $target;
    P: while (defined $current and not $current eq $_[0]->{root}) {
      $target = $current->next_sibling;
      last P if defined $target;
      $current = $current->parent_node;
      last P unless defined $current;
      my $presult = $_[0]->_test_node ($current);
      last P if $presult != 3; # FILTER_SKIP
    } # P
    return undef unless defined $target;
  
    my $result = $_[0]->_test_node ($target);
    if ($result == 1 or $result == 12101) {
      # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
      return ($_[0]->{current_node} = $target);
    } elsif ($result == 3) { # FILTER_SKIP
      my $tw = $_[0]->clone;
      $tw->{current_node} = $target;
      $tw->{root} = $target;
      my $fc = $tw->first_child;
      if (defined $fc) {
        return ($_[0]->{current_node} = $fc);
      }
    }
  }

  return undef;
} # next_sibling

sub parent_node ($) {
  local $Error::Depth = $Error::Depth + 1;

  unless ($_[0]->{current_node} eq $_[0]->{root}) {
    my $target = $_[0]->{current_node}->parent_node;
    T: while (defined $target) {
      my $result = $_[0]->_test_node ($target);
      if ($result == 1 or $result == 12101) {
        # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
        return ($_[0]->{current_node} = $target);
      } elsif ($target eq $_[0]->{root}) {
        return undef;
      }
      $target = $target->parent_node;
    } # T
  }

  return undef;
} # parent_node

sub previous_node ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $target = $_[0]->{current_node};
  T: {
    return undef if $target eq $_[0]->{root};

    P: {
      my $ptarget = $target->previous_sibling;
      if (defined $ptarget) {
        my $result = $_[0]->_test_node ($ptarget);
        if ($result == 12101) { # MANAKAI_FILTER_OPAQUE
          return ($_[0]->{current_node} = $ptarget);
        } elsif ($result != 2) { # FILTER_REJECT
          my $tw = $_[0]->clone;
          $tw->{current_node} = $ptarget;
          $tw->{root} = $ptarget;
          my $lc = $tw->last_child;
          return ($_[0]->{current_node} = defined $lc ? $lc : $ptarget);
        } else {
          $target = $ptarget;
          redo P;
        }
      }
    } # P

    my $ptarget = $target->parent_node;
    if (defined $ptarget) {
      my $result = $_[0]->_test_node ($ptarget);
      if ($result == 1 or $result == 12101) {
        # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
        return ($_[0]->{current_node} = $ptarget);
      } else {
        $target = $ptarget;
        redo T;
      }
    }
  } # T

  return undef;
} # previous_node

sub previous_sibling ($) {
  local $Error::Depth = $Error::Depth + 1;

  my $target = $_[0]->{current_node};
  while (defined $target) {
    my $current = $target;
    undef $target;
    P: while (defined $current and not $current eq $_[0]->{root}) {
      $target = $current->previous_sibling;
      last P if defined $target;

      $current = $current->parent_node;
      last P unless defined $current;
      my $presult = $_[0]->_test_node ($current);
      if ($presult != 3 and $presult != 2) { # FILTER_SKIP, FILTER_REJECT
        last P;
      }
    } # P
    return undef unless defined $target;
  
    my $result = $_[0]->_test_node ($target);
    if ($result == 1 or $result == 12101) {
      # FILTER_ACCEPT, MANAKAI_FILTER_OPAQUE
      return ($_[0]->{current_node} = $target);
    } elsif ($result == 3) { # FILTER_SKIP
      my $tw = $_[0]->clone;
      $tw->{current_node} = $target;
      $tw->{root} = $target;
      my $fc = $tw->last_child;
      if (defined $fc) {
        return ($_[0]->{current_node} = $fc);
      }
    }
  }

  return undef;
} # previous_sibling

## TODO: Document Perl binding for |NodeFilter|.
## TODO: |NodeFilter| constants...

sub _test_node ($$) {
  ## NOTE: There is a code clone in |SerialWalker.pm|.

  unless ($_[0]->{expand_entity_references}) {
    my $parent = $_[1]->parent_node;
    if (defined $parent and $parent->node_type == 5) { # ENTITY_REFERENCE_NODE
      return 2; # FILTER_REJECT ## NOTE: Even if |NodeIterator|.
    }
  }
    
  if ($_[0]->{what_to_show} != 0xFFFFFFFF) { # SHOW_ALL
    my $nt = $_[1]->node_type;
    if ($nt < 33 and ($_[0]->{what_to_show} & (1 << ($nt-1)))) {
      #
    } else {
      return 3; # FILTER_SKIP
    }
  }

  if (defined $_[0]->{filter}) {
    local $Error::Depth = $Error::Depth + 1;
    return $_[0]->{filter}->($_[1]);
  } else {
    return 1; # FILTER_ACCEPT
  }
} # _test_node

package Message::IF::TreeWalker;

package Message::DOM::Document;

sub create_tree_walker ($$;$$$) {
  unless (defined $_[1]) {
    require Message::DOM::DOMException;
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_SUPPORTED_ERR',
        -subtype => 'NULLPO_ERR';
  }
  
  return bless {
                root => $_[1],
                what_to_show => 0+($_[2] or 0),
                filter => $_[3],
                expand_entity_references => $_[4] ? 1 : 0,
                current_node => $_[1],
               }, 'Message::DOM::TreeWalker';
} # create_tree_walker

=pod 

 TODO: Documentation...

 FirstChild:
          If the <IF::NodeFilter>, if any, returns 
          <C::NodeFilter.MANAKAI_FILTER_OPAQUE> for the
          <A::TreeWalker.currentNode>, this method
          <kwd:MUST> return <DOM::null>.

            {NOTE::
              By definition, the parent of the
              <M::TreeWalker.firstChild> node, if any, is
              either a child of the <A::TreeWalker.currentNode>
              or a descendant of the <A::TreeWalker.currentNode>
              where all ancestors between <A::TreeWalker.currentNode>
              and that node is <C::NodeFilter.FILTER_SKIP>ped.
              That means that the only node that might be
              <C::NodeFilter.MANAKAI_FILTER_OPAQUE> is the
              <A::TreeWalker.currentNode>.
            }


  @L2Method:
    @@Name: lastChild

          If the <IF::NodeFilter>, if any, returns 
          <C::NodeFilter.MANAKAI_FILTER_OPAQUE> for the
          <A::TreeWalker.currentNode>, this method
          <kwd:MUST> return <DOM::null>.

            {NOTE::
              By definition, the parent of the
              <M::TreeWalker.lastChild> node, if any, is
              either a child of the <A::TreeWalker.currentNode>
              or a descendant of the <A::TreeWalker.currentNode>
              where all ancestors between <A::TreeWalker.currentNode>
              and that node is <C::NodeFilter.FILTER_SKIP>ped.
              That means that the only node that might be
              <C::NodeFilter.MANAKAI_FILTER_OPAQUE> is the
              <A::TreeWalker.currentNode>.
            }

 parentNode:
          For the purpose of this method, <C::NodeFilter.MANAKAI_FILTER_OPAQUE>
          <kwd:MUST> be handled by the same way as 
          <C::NodeFilter.FILTER_ACCEPT>.

nextNode:
          If the <A::TreeWalker.currentNode> is marked as 
          <C::NodeFilter.MANAKAI_FILTER_OPAQUE> by the <IF::NodeFilter>,
          the method <kwd:MUST-NOT> return any descendant of
          the <A::TreeWalker.currentNode>.  Otherwise,
          it <kwd:MUST> be treated as if <C::NodeFilter.FILTER_ACCEPT>.

 nextSibling:
      The <C::NodeFilter.MANAKAI_FILTER_OPAQUE> value <kwd:MUST>
      be treated as if <C::NodeFilter.FILTER_ACCEPT> is specified.

 previousNode:
      This method <kwd:MUST-NOT> return a descendant
      of a sibling of the <A::TreeWalker.currentNode> if 
      an ancestor between the descendant and the parent
      of the <A::TreeWalker.currentNode> (exclusive)
      is marked as <C::NodeFilter.MANAKAI_FILTER_OPAQUE> by
      the <IF::NodeFilter> if any.  If the node that is
      a candidate to return is an ancestor of the
      <A::TreeWalker.currentNode>, the <C::NodeFilter.MANAKAI_FILTER_OPAQUE>
      value returned by a <IF::NodeFilter> <kwd:MUST> be
      treated as if the <C::NodeFilter.FILTER_ACCEPT> value
      is returned.

 previousSibling:
      If a node that is a candicate to be returned is marked as
      <C::NodeFilter.MANAKAI_FILTER_OPAQUE>, it <kwd:MUST>
      be treated as <C::NodeFilter.FILTER_ACCEPT> when the
      node is a sibling of the <A::TreeWalker.currentNode>,
      or as in <M::TreeWalker.lastChild> where the
      <A::TreeWalker.currentNode> would be the sibling
      of the actual <A::TreeWalker.currentNode> otherwise.

    @@mConst:
      @@@Name: MANAKAI_FILTER_OPAQUE
      @@@intValue: 12101
      @@@enDesc:
        Accept the node itself while rejecting its children if any.

        If the <C::NodeFilter.MANAKAI_FILTER_OPAQUE> value is 
        specified for a node, the node itself <kwd:MUST> be treated
        as if the <C::NodeFilter.FILTER_ACCEPT> value is specified.
        However, any descendant of the node <kwd:MUST> be
        hidden from the logical view as if the
        <C::NodeFilter.FILTER_REJECT> value is specified for
        the ancestor node.

          {NOTE::
            This value can be used to emulate the
            <A::TreeWalker.expandEntityReferences> flag.
            However, unlike that flag, this filtering option
            makes the engine behave for descendants as if the node is
            rejected rather than the descendants of the node
            is rejected.
          }

          {ISSUE::
            Better name?  Any verb?
          }

          {ISSUE::
            Interaction to <IF::NodeIterator>s
          }

        {NOTE::
          The <C::Node.ELEMENT_TYPE_DEFINITION_NODE> and
          <C::Node.ATTRIBUTE_TYPE_DEFINITION> <A::Node.nodeType>s,
          extended by manakai, has values greater than <CODE::32>
          so that it cannot be controled by the <CODE::whatToShow>
          flags.
        }

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 16:32:28 $
