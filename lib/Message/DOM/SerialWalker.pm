package Message::DOM::SerialWalker;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::SerialWalker';

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    current_index => 1,
    current_node => 1,
    current_phase => 1,
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

## |SerialWalker| constants

## |SerialWalkerPhase|
sub PRE_PHASE () { 1 }
sub IN_PHASE () { 2 }
sub POST_PHASE () { 3 }

## |SerialWalker| attributes

sub current_index ($);

sub current_node ($);

sub current_phase ($);

sub expand_entity_references ($);

sub filter ($);

sub root ($);

sub what_to_show ($);

## |SerialWalker| methods

sub next_node ($) {
  my $self = $_[0];

  A: {
    unless (@{$self->{next}}) {
      #
    } elsif ($self->{next}->[0]->[1] != 0) {
      my $v = shift @{$self->{next}};
      $self->{current_phase} = $v->[1];
      $self->{current_index} = $self->{_index}->{$v->[2]}++;
      return ($self->{current_node} = $v->[0]);
    } else {
      my $v = shift @{$self->{next}};
      my $vresult = $self->_test_node ($v->[0]);
      
      my @pnext;
      if ($vresult == 1) { # FILTER_ACCEPT
        my $key = $v->[2].'.'.$self->{_index}->{$v->[2]};

        push @pnext, [$v->[3], IN_PHASE, $v->[4]]
            if defined $v->[3] and $self->{_index}->{$v->[4].'.1'};

        $self->{_index}->{$key} = 0;
        push @pnext, [$v->[0], PRE_PHASE, $key];
  
        push @pnext, [$_, 0, $key, $v->[0], $key]
            for @{$v->[0]->child_nodes};
        push @pnext, [$v->[0], POST_PHASE, $key];
      } elsif ($vresult == 3) { # FILTER_SKIP
        push @pnext, [$_, 0, $v->[2], $v->[3], $v->[4]]
            for @{$v->[0]->child_nodes};
      } elsif ($vresult == 12101) { # MANAKAI_FILTER_OPAQUE
        my $key = $v->[2].'.'.$self->{_index}->{$v->[2]};
        
        push @pnext, [$v->[3], IN_PHASE, $v->[4]]
            if defined $v->[3] and $self->{_index}->{$v->[4].'.1'};

        $self->{_index}->{$key} = 0;
        push @pnext, [$v->[0], PRE_PHASE, $key];
        push @pnext, [$v->[0], POST_PHASE, $key];
      }
      unshift @{$self->{next}}, @pnext;
      redo A;
    }
  } # A

  return undef;
} # next_node

sub _test_node ($$) {
  ## NOTE: There is a code clone in |TreeWalker.pm|.

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

package Message::IF::SerialWalker;

package Message::DOM::Document;

sub manakai_create_serial_walker ($$;$$$) {
  unless (defined $_[1]) {
    require Message::DOM::DOMException;
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_SUPPORTED_ERR',
        -subtype => 'NULLPO_ERR';
  }

  ## TODO: Initials for current_index and current_phase
  return bless {
                root => $_[1],
                what_to_show => 0+($_[2] or 0),
                filter => $_[3],
                expand_entity_references => $_[4] ? 1 : 0,
                current_node => $_[1],
                next => [[$_[1], 0, '']],
                _index => {'' => 0},
               }, 'Message::DOM::SerialWalker';
} # manakai_create_serial_walker

=pod

## TODO: Documentation

  @LXMethod:
    @@Name: manakaiCreateSerialWalker
    @@enDesc:
      Creates a new <IF::SerialWalker> object.
    @@Param:
      @@@Name: root
      @@@Type: Node
      @@@enDesc:
        The node that will serve as the root for the <IF::SerialWalker>.

        The <P::whatToShow> flags and the <IF::NodeFilter>
        are not considered when setting this value; any node type
        will be accepted as the root.

        The <A::TreeWalker.currentNode> of the created <IF::TreeWalker>
        is initialized to the <P::root> node, whether or not it 
        is visible.  

        The <P::root> functions as a stopping point for traversal
        methods that look upwards in the document structure, i.e.
        <M::SerialWalker.nextNode>.

        The <P::root> <kwd:MUST-NOT> be <DOM::null>.  If it is,
        the implementation <kwd:MUST> throw an exception.
    @@Param:
      @@@Name: whatToShow
      @@@Type: unsignedShort
      @@@actualType: WhatToShow
      @@@enDesc:
        The flags that specifies which node types may appear in the
        logical view of the tree presented by the <IF::SerialWalker>.

        The set of the flags are defined in the <IF::NodeFilter> interface.
        They can be combined using the binary <CODE::OR> operation.
    @@Param:
      @@@Name: filter
      @@@Type: NodeFilter
      @@@enDesc:
        The <IF::NodeFilter> to be used with the created <IF::SerialWalker>.
      @@@nullCase:
        @@@@enDesc:
          Indicates that no filter is used.
    @@Param:
      @@@Name: entityReferenceExpansion
      @@@Type: boolean
      @@@enDesc:
        The <A::SerialWalker.expandEntityReferences> flag of 
        the created <IF::TreeWalker>.
      @@@TrueCase:
        @@@@enDesc:
          The contents of the <IF::tx|EntityReference> nodes
          <EM::are> presented in the logical view.
      @@@FalseCase:
        @@@@enDesc:
          The contents of the <IF::tx|EntityReference> nodes
          are <EM::not> presented in the logical view.
    @@Return:
      @@@Type: SerialWalker
      @@@enDesc:
        {P:: The newly created <IF::SerialWalker>.  It <kwd:MUST>
             have attributes set as:

             - <A::SerialWalker.currentNode>::: <P::root>.

             - <A::SerialWalker.expandEntityReferences>:::
                   <P::entityReferenceExpansion>.

             - <A::SerialWalker.filter>::: <P::filter>.

             - <A::SerialWalker.root>::: <P::root>.

             - <A::SerialWalker.whatToShow>::: <P::whatToShow>.

        }
      @@@dx:raises:
        @@@@@: c|SET_TO_NULL_ERR
        @@@@enDesc:
          If the specified <P::root> is <DOM::null>.
    {ISSUE::
      Better name?
    }

    A <IF::SerialWalker> object can be used to traverse
    the subtree rooted by a node in document order.
    Unlike <IF::TreeWalker> and <IF::NodeIterator>, the
    <IF::SerialWalker> object cannot go back toward
    nodes that had already been seen.  The
    <IF::SerialWalker>, however, revisits a node after its
    children are visited.  This might be useful when
    an application wants to serialize a subtree in a format
    where delimiter and / or terminator should be inserted
    between and / or after nodes.

    How the <IF::SerialWalker> works is defined by the following
    reference algorithm.  An implementation does not have to
    implement this exact algorithm, but it <kwd:MUST> implement
    its method so that it has the same effect as the
    reference algorithm when the underlying subtree has not
    been modified.

    At the time of creation of the <IF::SerialWalker>, 
    the implementation <kwd:MUST> prepare a queue and
    <kwd:MUST> initialize it by pushing the <A::SerialWalker.root> node.

    {P:: When the <M::SerialWalker.nextNode> method is invoked,

       - If the queue is empty, the method <kwd:MUST> return
         <DOM::null>.  It <kwd:MUST-NOT> change 
         <A::SerialWalker.currentNode>, <A::SerialWalker.currentPhase>,
         and <A::SerialWalker.currentIndex> attributes.

       {LI:: Otherwise, 

          - Shift a node from the queue.  If the node has
            the phase value, the method <kwd:MUST> return
            the node.  In addition, it <kwd:MUST> set
            the <A::SerialWalker.currentNode> attribute to the node,
            the <A::SerialWalker.currentPhase> attribute to
            the associated phase value, and the
            <A::SerialWalker.currentIndex> attribute to
            the integer value that is large by one than
            the most recent <A::SerialWalker.currentIndex> value
            when the <A::SerialWalker.currentNode> was
            same as the shiftted node.  If it is the first time
            the node is set to the <A::SerialWalker.currentNode>
            attribute, the <A::SerialWalker.currentIndex>
            attribute <kwd:MUST> set to zero.

          {LI:: Otherwise, determine whether the shifted node
                should be accepted or not, using 
                <A::SerialWalker.expandEntityReferences>,
                <A::SerialWalker.whatToShow>, and
                <A::SerialWalker.filter> attributes, as defined
                for the <IF::TreeWalker> interface.

             {LI:: If the node is <C::NodeFilter.FILTER_ACCEPT>ed,

                = Prepend the node to the queue, with
                  phase value set to <C::SerialWalker.POST_PHASE>.
 
                = Prepend the child nodes of the node, if any,
                  to the queue keeping the document order,
                  without phase value.  That is, the first child
                  <kwd:MUST> be located at the top (first
                  position) of the queue.

                = Prepend the node to the queue, with
                  phase value set to <C::SerialWalker.PRE_PHASE>.
               
                = If the node has a previous sibling in the logical view,
                  preprend the parent node of the node in the logical
                  view, with phase value set to <C::SerialWalker.IN_PHASE>.

                = Invoke the algorithm recursively.

             }

             {LI:: If the node is <C::NodeFilter.FILTER_SKIP>ped,

                = Prepend the child nodes of the node, if any,
                  to the queue keeping the document order,
                  without phase value.  That is, the first child
                  <kwd:MUST> be located at the top (first
                  position) of the queue.

                = Invoke the algorithm recursively.

             }

             {LI:: If the node is <C::NodeFilter.MANAKAI_FILTER_OPAQUE>,
 
                = Prepend the node to the queue, with
                  phase value set to <C::SerialWalker.POST_PHASE>.

                = Prepend the node to the queue, with
                  phase value set to <C::SerialWalker.PRE_PHASE>.
               
                = If the node has a previous sibling in the logical view,
                  preprend the parent node of the node in the logical
                  view, with phase value set to <C::SerialWalker.IN_PHASE>.

                = Invoke the algorithm recursively.

             }

             - Otherwise, invoke the algorithm recursively.

          }
       }

    }

    {NOTE::
      This algorithm will stop unless nodes are simulataneously
      populated to the underlying tree by application via
      e.g. <IF::NodeFilter>.
    }

    Implementation <kwd:MAY> choose to implement the <IF::SerialWalker>
    using another algorithm.  In particular, when the <IF::NodeFilter>
    is invoked might vary across implementations.  Implementations
    should try to return the same effect as the reference algorithm
    even if the underlying subtree is modified, but applications
    <kwd:MUST-NOT> rely on the particular implementation's behavior.

    As long as the underlying subtree is not modified, a node will
    never set to the <A::SerialWalker.currentNode> attribute
    with the <A::SerialWalker.currentPhase> of <C::SerialWalker.PRE_PHASE>.
    If the underlying subtree is modified, depending on how
    the method is implemented, it might be in case.  For 
    the purpose of description below, such duplication was considered
    as if they were different nodes.

    {P:: Even if the underlying subtree has been modified during
         the traversal, the implementation <kwd:MUST> ensure
         the following conditions are met:

      - A node <kwd:MUST-NOT> be set to the <A::SerialWalker.currentNode>
        attribute with the <A::SerialWalker.currentPhase> of
        <C::SerialWalker.PRE_PHASE> or <C::SerialWalker.POST_PHASE>
        more than once respectively.

      - A node <kwd:MUST-NOT> be set to the <A::SerialWalker.currentNode>
        attribute with the <A::SerialWalker.currentPhase> of
        <C::SerialWalker.IN_PHASE> before it is once set to
        the same node with the <A::SerialWalker.currentPhase>
        of <C::SerialWalker.PRE_PHASE>, or after it is once set
        to the same node with the <A::SerialWalker.currentPhase>
        of <C::SerialWalker.POST_PHASE>.

      - A node <kwd:MUST-NOT> be set to the <A::SerialWalker.currentNode>
        attribute with the <A::SerialWalker.currentPhase> of
        <C::SerialWalker.POST_PHASE> before it is once set to
        the same node with the <A::SerialWalker.currentPhase>
        of <C::SerialWalker.PRE_PHASE>.

      - A node <kwd:MUST> be set to the <A::SerialWalker.currentNode>
        attribute with the <A::SerialWalker.currentPhase> of
        <C::SerialWalker.POST_PHASE> later if it is once set to
        the same node with the <A::SerialWalker.currentPhase>
        of <C::SerialWalker.PRE_PHASE>.

      - The <A::SerialWalker.currentPhase> <kwd:MUST-NOT> set
        to <C::SerialWalker.PRE_PHASE> unless its value is
        <C::SerialWalker.PRE_PHASE> or <C::SerialWalker.IN_PHASE>.

      - The <A::SerialWalker.currentPhase> <kwd:MUST-NOT> set
        to <C::SerialWalker.IN_PHASE> unless its value is
        <C::SerialWalker.POST_PHASE>.

      - The <A::SerialWalker.currentPhase> <kwd:MUST-NOT> set
        to <C::SerialWalker.POST_PHASE> unless its value is
        <C::SerialWalker.PRE_PHASE> or <C::SerialWalker.POST_PHASE>.

      - If a node <VAR::N> is set to the <A::SerialWalker.currentNode>
        attribute and then another node <VAR::M> is set to the attribute
        with both <A::SerialWalker.currentPhase> of <C::SerialWalker.PRE_PHASE>,
        the <A::SerialWalker.currentNode> attribute <kwd:MUST-NOT> be set to
        <VAR::N> with <A::SerialWalker.currentPhase> of
        <C::SerialWalker.POST_PHASE> before once the
        <A::SerialWalker.currentNode> attribute is set to
        <VAR::M> with <A::SerialWalker.currentPhase> of 
        <C::SerialWalker.POST_PHASE>.

      - For each time the <A::SerialWalker.currentNode> attribute is
        set to a node, the <A::SerialWalker.currentIndex> <kwd:MUST>
        be increased by one.  If the node is set to the attribute
        for the first time, the <A::SerialWalker.currentIndex> 
        <kwd:MUST> be set to zero.  That is, with and only with
        <C::SerialWalker.PRE_PHASE> the <A::SerialWalker.currentIndex>
        can be zero.
    }

  @LXAttr:
    @@Name: root
    @@enDesc:
      The root node of the <IF::SerialWalker>.
    @@Type: Node
    @@Get:
      @@@enDesc:
        The root node set when the <IF::SerialWalker> is created.

  @LXAttr:
    @@Name: currentNode
    @@enDesc:
      The current node of the <IF::SerialWalker>.

        {NOTE::
          Unlike <IF::TreeWalker>, the <A::SerialWalker.currentNode>
          attribute is read-only.
        }
    @@Type: Node
    @@Get:
      @@@enDesc:
        The current node.

  @mShortConstGroup:
    @@IFQName: SerialWalkerPhase
    @@enDesc:
      An integer to indicate a phase of <IF::SerialWalker>.

    @@mConst:
      @@@Name: PRE_PHASE
      @@@intValue: 1
      @@@enDesc:
        The <A::SerialWalker.currentNode> is visited by
        the <IF::SerialWalker> for the first time.  It is
        expected that the same node will be revisited
        with <A::SerialWalker.currentPhase> of 
        <C::SerialWalker.IN_PHASE> (optionally) and
        <C::SerialWalker.POST_PHASE> later.
    @@mConst:
      @@@Name: IN_PHASE
      @@@intValue: 2
      @@@enDesc:
        The <A::SerialWalker.currentNode> is visited
        by the <IF::SerialWalker>, not for the first
        or last time, between visitings to its two child nodes.
    @@mConst:
      @@@Name: POST_PHASE
      @@@intValue: 3
      @@@enDesc:
        The <A::SerialWalker.currentNode> is visited
        by the <IF::SerialWalker> for the last time.

  @LXAttr:
    @@Name: currentPhase
    @@enDesc:
      The current phase of the <IF::SerialWalker>.
    @@Type: unsignedShort
    @@actualType: SerialWalkerPhase
    @@Get:
      @@@enDesc:
        An integer to indicate the current phase.

  @LXAttr:
    @@Name: currentIndex
    @@enDesc:
      The current index of the <IF::SerialWalker>.  The 
      <DFN::current index> represents how many times the
      <A::SerialWalker.currentNode> is exposed through
      the <IF::SerialWalker>.
    @@Type: unsignedLong
    @@Get:
      @@@enDesc:
        An integer to indicate the current index.

  @LXAttr:
    @@Name: expandEntityReferences
    @@enDesc:
      The value of the flag that determines whether the children of
      <IF::tx|EntityReference> nodes are visible to the <IF::SerialWalker>.

      {NOTE::
        To produce a view of the document that has entity references
        expanded and does not expose the <IF::tx|EntityReference> nodes
        themselves, use the <A::SerialWalker.whatToShow> flags to hide the
        <IF::tx|EntityReference> nodes and set the
        <A::SerialWalker.expandEntityReferences> flag to <DOM::true>
        when creating the <IF::SerialWalker>.

        To produce a view of the document that has <IF::tx|EntityReference>
        nodes but no entity expansion, use the <A::SerialWalker.whatToShow>
        flags to show the <IF::tx|EntityReference> nodes and set the
        <A::SerialWalker.expandEntityReferences> flag to <DOM::false>
        when creating the <IF::SerialWalker>.
      }
    @@Type: boolean
    @@Get:
      @@@enDesc:
        The <CODE::entityReferenceExpansion> value that
        was specified when the <IF::SerialWalker> was created.
      @@@TrueCase:
        @@@@enDesc:
          The children and their descendants of <IF::tx|EntityReference>
          nodes will <EM::not> be rejected.  Note that
          the <A::SerialWalker.whatToShow> flags and the
          <A::SerialWalker.filter> set to the <IF::SerialWalker>
          might reject them as usual way.
      @@@FalseCase:
        @@@@enDesc:
          The children and their descendants of entity reference nodes
          will be rejected.  This rejection takes precedence over
          the <A::SerialWalker.whatToShow> flags and the
          <A::SerialWalker.filter> set to the 
          <IF::SerialWalker>, if any.

  @LXAttr:
    @@Name: filter
    @@enDesc:
      The filter used to screen nodes.
    @@Type: NodeFilter
    @@Get:
      @@@enDesc:
        The <IF::NodeFilter> that was specified when the
        <IF::SerialWalker> was created.
      @@@nullCase:
        @@@@enDesc:
          If no <IF::NodeFilter> was specified when the
          <IF::SerialWalker> was created.

  @LXAttr:
    @@Name: whatToShow
    @@enDesc:
      The flags that determines which node types are presented
      via the <IF::SerialWalker>.  The available set of constants
      is defined in the <IF::NodeFilter> interface.

      Nodes not accepted by the <A::SerialWalker.whatToShow>
      flags will be skipped, but their children may still be
      considered.  This skip takes precedence over the 
      <A::SerialWalker.filter> set to the <IF::SerialWalker>, if any.
    @@Type: unsignedShort
    @@actualType: WhatToShow
    @@Get:
      @@@enDesc:
        The <CODE::whatToShow> value that was specified
        when the <IF::SerialWalker> was created.

  @LXMethod:
    @@Name: nextNode
    @@enDesc:
      Returns the node next to the <A::SerialWalker.currentNode>
      of the <IF::SerialWalker>.
    @@Return:
      @@@Type: Node
      @@@enDesc:
        The next node.
      @@@nullCase:
        @@@@enDesc:
          If no next node.

=cut

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 16:32:28 $
