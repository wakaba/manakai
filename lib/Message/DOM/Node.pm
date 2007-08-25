package Message::DOM::Node;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.15 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::Node';
require Scalar::Util;
require Message::DOM::DOMException;

## NOTE:
##   Node
##   + Attr (2)
##   + AttributeDefinition (81002)
##   + CharacterData
##     + Comment (8)
##     + Text (3)
##       + CDATASection (4)
##   + Document (9)
##   + DocumentFragment (11)
##   + DocumentType (10)
##   + Element (1)
##   + ElementTypeDefinition (81001)
##   + Entity (6)
##   + EntityReference (5)
##   + Notation (12)
##   + ProcessingInstruction (7)

use overload
    '==' => 'is_equal_node',
    '!=' => sub {
      return not ($_[0] == $_[1]);
    },
    #eq => sub { $_[0] eq $_[1] }, ## is_same_node
    #ne => sub { $_[0] ne $_[1] }, ## not is_same_node
    fallback => 1;

## The |Node| interface - constants

## Definition group NodeType

## NOTE: Numeric codes up to 200 are reserved by W3C [DOM1SE, DOM2, DOM3].

sub ELEMENT_NODE () { 1 }
sub ATTRIBUTE_NODE () { 2 }
sub TEXT_NODE () { 3 }
sub CDATA_SECTION_NODE () { 4 }
sub ENTITY_REFERENCE_NODE () { 5 }
sub ENTITY_NODE () { 6 }
sub PROCESSING_INSTRUCTION_NODE () { 7 }
sub COMMENT_NODE () { 8 }
sub DOCUMENT_NODE () { 9 }
sub DOCUMENT_TYPE_NODE () { 10 }
sub DOCUMENT_FRAGMENT_NODE () { 11 }
sub NOTATION_NODE () { 12 }
sub ELEMENT_TYPE_DEFINITION_NODE () { 81001 }
sub ATTRIBUTE_DEFINITION_NODE () { 81002 }

## Definition group DocumentPosition

sub DOCUMENT_POSITION_DISCONNECTED () { 0x01 }
sub DOCUMENT_POSITION_PRECEDING () { 0x02 }
sub DOCUMENT_POSITION_FOLLOWING () { 0x04 }
sub DOCUMENT_POSITION_CONTAINS () { 0x08 }
sub DOCUMENT_POSITION_CONTAINED_BY () { 0x10 }
sub DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC () { 0x20 }

## |OperationType| from the |UserDataHandler| interface.
sub NODE_CLONED () { 1 }
sub NODE_IMPORTED () { 2 }
sub NODE_DELETED () { 3 }
sub NODE_RENAMED () { 4 }
sub NODE_ADOPTED () { 5 }

sub ____new ($$) {
  my $self = bless \({}), shift;
  $$self->{owner_document} = shift;
  Scalar::Util::weaken ($$self->{owner_document});
  return $self;
} # ____new

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    owner_document => 1,
    parent_node => 1,
    manakai_read_only => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## |Node| attributes

## NOTE: Overridden by |Element|.
sub attributes () { undef }

sub base_uri ($) {
  ## NOTE: Overridden by |Attr|, |CharacterData|, |Document|, |DocumentType|,
  ## |Element|, |EntityReference|, and |ProcessingInstruction|.

  local $Error::Depth = $Error::Depth + 1;
  return $_[0]->owner_document->base_uri;
} # base_uri

sub child_nodes ($) {
  ## NOTE: Overridden by |CharacterData|, |ElementTypeDefinition|,
  ## |Notation|, and |ProcessingInstruction|.
  require Message::DOM::NodeList;
  return bless \\($_[0]), 'Message::DOM::NodeList::ChildNodeList';
} # child_nodes

sub manakai_expanded_uri ($) {
  my $self = shift;
  local $Error::Depth = $Error::Depth + 1;
  my $ln = $self->local_name;
  if (defined $ln) {
    my $nsuri = $self->namespace_uri;
    if (defined $nsuri) {
      return $nsuri . $ln;
    } else {
      return $ln;
    }
  } else {
    return undef;
  } 
} # manakai_expanded_uri

sub first_child ($) {
  my $self = shift;
  return $$self->{child_nodes} ? $$self->{child_nodes}->[0] : undef;
} # first_child

sub manakai_language ($;$) {
  my $self = $_[0];
  local $Error::Depth = $Error::Depth + 1;

  if (@_ > 1) {
    if ($self->node_type == 1) { # ELEMENT_NODE
      if (defined $_[1]) {
        if ($self->has_attribute_ns (undef, 'xml:lang')) {
          $self->set_attribute_ns (undef, [undef, 'xml:lang'] => $_[1]);
              # or exception
        } else {
          $self->set_attribute_ns
              (q<http://www.w3.org/XML/1998/namespace>, 'xml:lang', $_[1]);
        }
      } else {
        $self->remove_attribute_ns
            (q<http://www.w3.org/XML/1998/namespace>, 'lang');
        $self->remove_attribute_ns (undef, 'xml:lang');
      }
    }
    
    return undef unless defined wantarray;
  }

  my $target = $self;
  while (defined $target) {
    if ($target->node_type == 1) { # ELEMENT_NODE
      ## Step 1

      ## Step 1.1
      my $r = $target->get_attribute_ns
          (q<http://www.w3.org/XML/1998/namespace>, 'lang');
      return $r if defined $r;

      ## Step 1.2
      $r = $target->get_attribute_ns (undef, 'xml:lang');
      return $r if defined $r;
    }

    ## Step 2
    $target = $target->parent_node;
  }

  ## Step 3
  my $od = $self->owner_document;
  if (defined $od) {
    return $od->manakai_language;
  }

  ## Step 4
  ## TODO: from upper-level protocol, if $self isa Document

  ## Step 5
  return '';
} # manakai_language

sub last_child ($) {
  my $self = shift;
  return $$self->{child_nodes} && $$self->{child_nodes}->[0]
    ? $$self->{child_nodes}->[-1] : undef;
} # last_child

sub local_name { undef }

sub manakai_local_name { undef }

sub namespace_uri { undef }

sub next_sibling ($) {
  my $self = shift;
  my $parent = $$self->{parent_node};
  return undef unless defined $parent;
  my $has_self;
  for (@{$parent->child_nodes}) {
    if ($_ eq $self) {
      $has_self = 1;
    } elsif ($has_self) {
      return $_;
    }
  }
  return undef;
} # next_sibling

## NOTE: Overridden by subclasses.
sub node_name () { undef }

## NOTE: Overridden by subclasses.
sub node_type () { }

## NOTE: Overridden by |Attr|, |AttributeDefinition|,
## |CharacterData|, and |ProcessingInstruction|.
sub node_value () { undef }

sub owner_document ($);

sub manakai_parent_element ($) {
  my $self = shift;
  my $parent = $$self->{parent_node};
  while (defined $parent) {
    if ($parent->node_type == ELEMENT_NODE) {
      return $parent;
    } else {
      $parent = $$parent->{parent_node};
    }
  }
  return undef;
} # manakai_parent_element

sub parent_node ($);

## NOTE: Overridden by |Element| and |Attr|.
sub prefix ($;$) { undef }

sub previous_sibling ($) {
  my $self = shift;
  my $parent = $$self->{parent_node};
  return undef unless defined $parent;
  my $prev;
  for (@{$parent->child_nodes}) {
    if ($_ eq $self) {
      return $prev;
    } else {
      $prev = $_;
    }
  }
  return undef;
} # previous_sibling

sub manakai_read_only ($);

sub text_content ($;$) {
  ## NOTE: For |Element|, |Attr|, |Entity|, |EntityReference|,
  ## |DocumentFragment|, and |AttributeDefinition|.  In addition,
  ## |Document|'s |text_content| might call this attribute.
  
  ## NOTE: Overridden by |Document|, |DocumentType|, |Notation|,
  ## |CharacterData|, |ProcessingInstruction|, and |ElementTypeDefinition|.

  my $self = $_[0];

  if (@_ > 1) {
    if (${$$self->{owner_document} or $self}->{strict_error_checking} and
        $$self->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    
    local $Error::Depth = $Error::Depth + 1;
    @{$self->child_nodes} = ();
    if (defined $_[1] and length $_[1]) {
      ## NOTE: |DocumentType| don't use this code.
      my $text = ($$self->{owner_document} || $self)->create_text_node ($_[1]);
      $self->append_child ($text);
    }    
  }

  if (defined wantarray) {
    local $Error::Depth = $Error::Depth + 1;
    my $r = '';
    my @node = @{$self->child_nodes};
    while (@node) {
      my $child = shift @node;
      my $child_nt = $child->node_type;
      if ($child_nt == TEXT_NODE or $child_nt == CDATA_SECTION_NODE) {
        $r .= $child->node_value unless $child->is_element_content_whitespace;
      } elsif ($child_nt == COMMENT_NODE or
               $child_nt == PROCESSING_INSTRUCTION_NODE or
               $child_nt == DOCUMENT_TYPE_NODE) {
        #
      } else {
        unshift @node, @{$child->child_nodes};
      }
    }
    return $r;
  }
} # text_content

## |Node| methods

sub append_child ($$) {
  ## NOTE: |Element|, |Entity|, |DocumentFragment|, |EntityReference|.
  ## NOTE: |Document|, |Attr|, |CharacterData|, |AttributeDefinition|,
  ## |Notation|, |ProcessingInstruction| |ElementTypeDefinition|,
  ## and |DocumentType| define their own implementations.
  my $self = $_[0];
  
  ## NOTE: Depends on $self->node_type:
  my $self_od = $$self->{owner_document};

  ## -- Node Type check
  my @new_child;
  my $new_child_parent;
  if ($_[1]->node_type == DOCUMENT_FRAGMENT_NODE) {
    push @new_child, @{$_[1]->child_nodes};
    $new_child_parent = $_[1];
  } else {
    @new_child = ($_[1]);
    $new_child_parent = $_[1]->parent_node;
  }

  ## NOTE: Depends on $self->node_type:
  if ($$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if ($self_od ne $child_od and $child_od->node_type != DOCUMENT_TYPE_NODE) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    if ($$self->{manakai_read_only} or
        (@new_child and defined $new_child_parent and
         $$new_child_parent->{manakai_read_only})) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    ## NOTE: |Document| has children order check here.

    for my $cn (@new_child) {
      unless ({
               TEXT_NODE, 1, ENTITY_REFERENCE_NODE, 1,
               ELEMENT_NODE, 1, CDATA_SECTION_NODE, 1,
               PROCESSING_INSTRUCTION_NODE, 1, COMMENT_NODE, 1,
              }->{$cn->node_type}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    my $anode = $self;
    while (defined $anode) {
      if ($anode eq $_[1]) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'ANCESTOR_NODE_ERR';
      }
      $anode = $$anode->{parent_node};
    }
  }

  ## NOTE: "Insert at" code only in insert_before and replace_child

  ## -- Removes from parent
  if ($new_child_parent) {
    if (@new_child == 1) {
      my $v = $$new_child_parent->{child_nodes};
      RP: for my $i (0..$#$v) {
        if ($v->[$i] eq $new_child[0]) {
          splice @$v, $i, 1, ();
          last RP;
        }
      } # RP
    } else {
      @{$$new_child_parent->{child_nodes}} = ();
    }
  }

  ## -- Rewrite the |parentNode| properties
  for my $nc (@new_child) {
    $$nc->{parent_node} = $self;
    Scalar::Util::weaken ($$nc->{parent_node});
  }

  ## NOTE: Depends on method:
  push @{$$self->{child_nodes}}, @new_child;

  ## NOTE: Setting |owner_document| in |Document|.

  return $_[1];
} # apepnd_child

sub clone_node ($;$) {
  my ($self, $deep) = @_;

  ## ISSUE: Need definitions for the cloning operation
  ## for ElementTypeDefinition, and AttributeDefinition nodes,
  ## as well as new attributes introduced in DOM XML Document Type Definition
  ## module.
  ## ISSUE: Define if default attributes and attributedefinition are inconsistent

  local $Error::Depth = $Error::Depth + 1;
  my $od = $self->owner_document;
  my $strict_check = $od->strict_error_checking;
  $od->strict_error_checking (0);
  my $cfg = $od->dom_config;
  my $er_copy_asis
      = $cfg->get_parameter
          (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree>);

  my $r;
  my @udh;
  my @node = ([$self]);
  while (@node) {
    my ($node, $parent) = @{shift @node};
    my $nt = $node->node_type;
    my $clone;
    if ($nt == ELEMENT_NODE) {
      $clone = $od->create_element_ns
        ($node->namespace_uri, [$node->prefix, $node->local_name]);
      if ($parent) {
        $parent->append_child ($clone);
      } else {
        $r = $clone;
      }
      my $attrs = $node->attributes;
      my $attrsMax = @$attrs - 1;
      for my $i (0..$attrsMax) {
        my $attr = $attrs->[$i];
        push @node, [$attr, $clone] if $attr->specified;
      }
      if ($deep) {
        push @node, map {[$_, $clone]} @{$node->child_nodes};
      }
    } elsif ($nt == TEXT_NODE) {
      $clone = $od->create_text_node ($node->data);
      if ($parent) {
        $parent->append_child ($clone);
      } else {
        $r = $clone;
      }
      $clone->is_element_content_whitespace (1)
        if $node->is_element_content_whitespace;
    } elsif ($nt == ATTRIBUTE_NODE) {
      $clone = $od->create_attribute_ns
        ($node->namespace_uri, [$node->prefix, $node->local_name]);
      if ($parent) {
        $parent->set_attribute_node_ns ($clone);
      } else {
        $r = $clone;
      }
      $clone->specified (1);
      push @node, map {[$_, $clone]} @{$node->child_nodes};
    } elsif ($nt == COMMENT_NODE) {
      $clone = $od->create_comment ($node->data);
      if ($parent) {
        $parent->append_child ($clone);
      } else {
        $r = $clone;
      }
    } elsif ($nt == CDATA_SECTION_NODE) {
      $clone = $od->create_cdata_section ($node->data);
      if ($parent) {
        $parent->append_child ($clone);
      } else {
        $r = $clone;
      }
    } elsif ($nt == PROCESSING_INSTRUCTION_NODE) {
      $clone = $od->create_processing_instruction
        ($node->target, $node->data);
      if ($parent) {
        $parent->append_child ($clone);
      } else {
        $r = $clone;
      }
    } elsif ($nt == ENTITY_REFERENCE_NODE) {
      $clone = $od->create_entity_reference ($node->node_name);
      if ($er_copy_asis) {
        $clone->manakai_set_read_only (0);
        $clone->text_content (0);
        for (@{$node->child_nodes}) {
          $clone->append_child ($_->clone_node (1));
        }
        $clone->manakai_expanded ($node->manakai_expanded);
        $clone->manakai_set_read_only (1, 1);
      } # copy asis
      if ($parent) {
        $parent->append_child ($clone);
      } else {
        $r = $clone;
      }
    } elsif ($nt == DOCUMENT_FRAGMENT_NODE) {
      $clone = $od->create_document_fragment;
      $r = $clone;
      push @node, map {[$_, $clone]} @{$node->child_nodes};
    } elsif ($nt == DOCUMENT_NODE) {
      $od->strict_error_checking ($strict_check);
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_SUPPORTED_ERR',
          -subtype => 'CLONE_NODE_NOT_SUPPORTED_ERR';
    } elsif ($nt == DOCUMENT_TYPE_NODE) {
      $od->strict_error_checking ($strict_check);
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_SUPPORTED_ERR',
          -subtype => 'CLONE_NODE_NOT_SUPPORTED_ERR';
    } elsif ($nt == ENTITY_NODE) {
      $od->strict_error_checking ($strict_check);
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_SUPPORTED_ERR',
          -subtype => 'CLONE_NODE_NOT_SUPPORTED_ERR';
    } elsif ($nt == NOTATION_NODE) {
      $od->strict_error_checking ($strict_check);
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_SUPPORTED_ERR',
          -subtype => 'CLONE_NODE_NOT_SUPPORTED_ERR';
    } else {
      $od->strict_error_checking ($strict_check);
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_SUPPORTED_ERR',
          -subtype => 'CLONE_NODE_NOT_SUPPORTED_ERR';
    }

    my $udhs = $$self->{user_data};
    push @udh, [$node => $clone, $udhs] if $udhs and %$udhs;
  } # @node
  $od->strict_error_checking (1) if $strict_check;
  
  ## Calling user data handlers if any
  for my $sd (@udh) {
    my $src = $sd->[0];
    my $src_ud = $sd->[2];
    for my $key (keys %{$src_ud}) {
      my $dh = $src_ud->{$key}->[1];
      if ($dh) {     ## NODE_CLONED
        $dh->handle (1, $key, $src_ud->{$key}->[0], $src, $sd->[1]);
        ## ISSUE: |handler| method? CODE?
      }
    }
  }

  return $r;
} # clone_node

sub compare_document_position ($$) {
  ## ISSUE: There are implementation specifics
  ## (see what Gecko does if it implement this method...)

  ## ISSUE: Maybe we should overload <=> or cmp

  ## TODO: Too long method name!  Too long constant names!
  ## Too many thing to be done by a method!
  ## Maybe we should import simpler method implemented by IE.

  ## ISSUE: Need documentation for ElementTypeDefinition and AttributeDefinition
  ## concerns

  my @acontainer = ($_[0]);
  my @bcontainer = ($_[1]);
  F: {
    A: while (1) {
      if ($acontainer[-1] eq $bcontainer[-1]) {
        last F;
      } else {
        my $ap;
        my $atype = $acontainer[-1]->node_type;
        if ($atype == ATTRIBUTE_NODE) {
          $ap = $acontainer[-1]->owner_element;
        } elsif ($atype == ENTITY_NODE or $atype == NOTATION_NODE or
                 $atype == ELEMENT_TYPE_DEFINITION_NODE) {
          $ap = $acontainer[-1]->owner_document_type_definition;
        } elsif ($atype == ATTRIBUTE_DEFINITION_NODE) {
          $ap = $acontainer[-1]->owner_element_type_definition;
        } else {
          $ap = $acontainer[-1]->parent_node;
        }
        if (defined $ap) {
          push @acontainer, $ap;
        } else {
          last A;
        }
      }
    } # A

    B: while (1) {
      if ($acontainer[-1] eq $bcontainer[-1]) {
        last F;
      } else {
        my $bp;
        my $btype = $bcontainer[-1]->node_type;
        if ($btype == ATTRIBUTE_NODE) {
          $bp = $bcontainer[-1]->owner_element;
        } elsif ($btype == ENTITY_NODE or $btype == NOTATION_NODE or
                 $btype == ELEMENT_TYPE_DEFINITION_NODE) {
          $bp = $bcontainer[-1]->owner_document_type_definition;
        } elsif ($btype == ATTRIBUTE_DEFINITION_NODE) {
          $bp = $bcontainer[-1]->owner_element_type_definition;
        } else {
          $bp = $bcontainer[-1]->parent_node;
        }
        if (defined $bp) {
          push @bcontainer, $bp;
        } else {
          last B;
        }
      }
    } # B
      
    ## Disconnected
    if ($bcontainer[-1]->isa ('Message::IF::Node')) {
      ## ISSUE: Document this in manakai's DOM Perl Binding?
      return DOCUMENT_POSITION_DISCONNECTED
        | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
        | ((${$acontainer[-1]} cmp ${$bcontainer[-1]}) > 0
             ? DOCUMENT_POSITION_FOLLOWING
             : DOCUMENT_POSITION_PRECEDING);
    } else {
      ## TODO: Is there test cases for this?
      return DOCUMENT_POSITION_DISCONNECTED
        | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
        | DOCUMENT_POSITION_FOLLOWING;
    }
  } # F

  ## Common container found
  if (@acontainer >= 2) {
    if (@bcontainer >= 2) {
      my $acnt = $acontainer[-2]->node_type;
      my $bcnt = $bcontainer[-2]->node_type;
      if ($acnt == ATTRIBUTE_NODE or
          $acnt == NOTATION_NODE or 
          $acnt == ELEMENT_TYPE_DEFINITION_NODE or
          $acnt == ATTRIBUTE_DEFINITION_NODE) {
        if ($acnt == $bcnt) {
          return DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
            | (($acontainer[-2]->node_name cmp
                $bcontainer[-2]->node_name) > 0
               ? DOCUMENT_POSITION_FOLLOWING
               : DOCUMENT_POSITION_PRECEDING);
        } elsif ($bcnt == ATTRIBUTE_NODE or
                 $bcnt == NOTATION_NODE or
                 $bcnt == ELEMENT_TYPE_DEFINITION_NODE or
                 $bcnt == ATTRIBUTE_DEFINITION_NODE) {
          return (($acnt < $bcnt)
                  ? DOCUMENT_POSITION_FOLLOWING
                  : DOCUMENT_POSITION_PRECEDING);
        } else {
          ## A: Non-child and B: child
          return DOCUMENT_POSITION_FOLLOWING;
        }
      } elsif ($bcnt == ATTRIBUTE_NODE or
               $bcnt == NOTATION_NODE or
               $bcnt == ELEMENT_TYPE_DEFINITION_NODE or
               $bcnt == ATTRIBUTE_DEFINITION_NODE) {
        ## A: Child and B: non-child
        return DOCUMENT_POSITION_PRECEDING;
      } else {
        ## A and B are both children
        for my $cn (@{$acontainer[-1]->child_nodes}) {
          if ($cn eq $acontainer[-2]) {
            return DOCUMENT_POSITION_FOLLOWING;
          } elsif ($cn eq $bcontainer[-2]) {
            return DOCUMENT_POSITION_PRECEDING;
          }
        }
        die "compare_document_position: Something wrong (1)";
      }
    } else {
      ## B contains A
      return DOCUMENT_POSITION_CONTAINS
        | DOCUMENT_POSITION_PRECEDING;
    }
  } else {
    if (@bcontainer >= 2) {
      ## A contains B
      return DOCUMENT_POSITION_CONTAINED_BY
        | DOCUMENT_POSITION_FOLLOWING;
    } else {
      ## A eq B
      return 0;
    }
  }
  die "compare_document_position: Something wrong (2)";
} # compare_document_position

sub get_feature ($$;$) {
  my $feature = lc $_[1]; ## TODO: |lc|?
  $feature =~ s/^\+//;
  my $version = defined $_[2] ? $_[2] : '';
  if ($Message::DOM::DOMImplementation::HasFeature->{$feature}->{$version}) {
    return $_[0];
  } else {
    return undef;
  }
} # get_feature

sub get_user_data ($$) {
  if (${$_[0]}->{user_data}->{$_[1]}) {
    return ${$_[0]}->{user_data}->{$_[1]}->[0];
  } else {
    return undef;
  }
} # get_user_data

sub has_attributes ($) {
  for (values %{${$_[0]}->{attributes} or {}}) {
    return 1 if keys %$_;
  }
  return 0;
} # has_attributes

sub has_child_nodes ($) {
  return (@{${$_[0]}->{child_nodes} or []} > 0);
} # has_child_nodes

sub insert_before ($$) {
  ## NOTE: |Element|, |Entity|, |DocumentFragment|, |EntityReference|.
  ## NOTE: |Document|, |Attr|, |CharacterData|, |AttributeDefinition|,
  ## |Notation|, |ProcessingInstruction|, |ElementTypeDefinition|,
  ## and |DocumentType| define their own implementations.
  my $self = $_[0];

  ## NOTE: Depends on $self->node_type:
  my $self_od = $$self->{owner_document};

  ## -- Node Type check
  my @new_child;
  my $new_child_parent;
  if ($_[1]->node_type == DOCUMENT_FRAGMENT_NODE) {
    push @new_child, @{$_[1]->child_nodes};
    $new_child_parent = $_[1];
  } else {
    @new_child = ($_[1]);
    $new_child_parent = $_[1]->parent_node;
  }

  ## NOTE: Depends on $self->node_type:
  if ($$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if ($self_od ne $child_od and $child_od->node_type != DOCUMENT_TYPE_NODE) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    if ($$self->{manakai_read_only} or
        (@new_child and defined $new_child_parent and
         $$new_child_parent->{manakai_read_only})) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    ## NOTE: |Document| has children order check here.

    for my $cn (@new_child) {
      unless ({
               TEXT_NODE, 1, ENTITY_REFERENCE_NODE, 1,
               ELEMENT_NODE, 1, CDATA_SECTION_NODE, 1,
               PROCESSING_INSTRUCTION_NODE, 1, COMMENT_NODE, 1,
              }->{$cn->node_type}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    my $anode = $self;
    while (defined $anode) {
      if ($anode eq $_[1]) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'ANCESTOR_NODE_ERR';
      }
      $anode = $$anode->{parent_node};
    }
  }
  
  ## -- Insert at... ## NOTE: Only in insert_before and replace_child
  my $index = -1; # last
  if (defined $_[2]) {
    ## error if $_[1] eq $_[2];
    
    my $cns = $self->child_nodes;
    my $cnsl = @$cns;
    C: {
      $index = 0;
      for my $i (0..($cnsl-1)) {
        my $cn = $cns->[$i];
        if ($cn eq $_[2]) {
          $index += $i;
          last C;
        } elsif ($cn eq $_[1]) {
          $index = -1; # offset
        }
      }
      
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_FOUND_ERR',
          -subtype => 'NOT_CHILD_ERR';
    } # C
  }
  ## NOTE: "else" only in replace_child

  ## -- Removes from parent
  if ($new_child_parent) {
    if (@new_child == 1) {
      my $v = $$new_child_parent->{child_nodes};
      RP: for my $i (0..$#$v) {
        if ($v->[$i] eq $new_child[0]) {
          splice @$v, $i, 1, ();
          last RP;
        }
      } # RP
    } else {
      @{$$new_child_parent->{child_nodes}} = ();
    }
  }

  ## -- Rewrite the |parentNode| properties
  for my $nc (@new_child) {
    $$nc->{parent_node} = $self;
    Scalar::Util::weaken ($$nc->{parent_node});
  }

  ## NOTE: Depends on method:
  if ($index == -1) {
    push @{$$self->{child_nodes}}, @new_child;
  } else {
    splice @{$$self->{child_nodes}}, $index, 0, @new_child;
  }

  ## NOTE: Setting |owner_document| in |Document|.

  return $_[1];
} # insert_before

sub is_equal_node ($$) {
  local $Error::Depth = $Error::Depth + 1;

  return 0 unless UNIVERSAL::isa ($_[1], 'Message::IF::Node');

  my $nt = $_[0]->node_type;
  return 0 unless $nt == $_[1]->node_type;

  my @str_attr = qw/node_name local_name namespace_uri
      prefix node_value/;
  push @str_attr, qw/public_id system_id internal_subset/
      if $nt == DOCUMENT_TYPE_NODE;
  for my $attr_name (@str_attr) {
    my $v1 = $_[0]->can ($attr_name) ? $_[0]->$attr_name : undef;
    my $v2 = $_[1]->can ($attr_name) ? $_[1]->$attr_name : undef;
    if (defined $v1 and defined $v2) {
      return 0 unless ''.$v1 eq ''.$v2;
    } elsif (defined $v1 or defined $v2) {
      return 0;
    }
  }

  my @num_eq_attr = qw/child_nodes attributes/;
  push @num_eq_attr, qw/entities notations element_types/
      if $nt == DOCUMENT_TYPE_NODE;
  push @num_eq_attr, qw/attribute_definitions/
      if $nt == ELEMENT_TYPE_DEFINITION_NODE;
  push @num_eq_attr, qw/declared_type default_type allowed_tokens/
      if $nt == ATTRIBUTE_DEFINITION_NODE;
  for my $attr_name (@num_eq_attr) {
    my $v1 = $_[0]->can ($attr_name) ? $_[0]->$attr_name : undef;
    my $v2 = $_[1]->can ($attr_name) ? $_[1]->$attr_name : undef;
    if (defined $v1 and defined $v2) {
      return 0 unless $v1 == $v2;
    } elsif (defined $v1 or defined $v2) {
      return 0;
    }
  }

  return 1;
} # is_equal_node

sub is_same_node ($$) { $_[0] eq $_[1] }

sub is_supported ($$;$) {
  my $feature = lc $_[1]; ## TODO: |lc|?
  my $plus = ($feature =~ s/^\+//);
  my $version = defined $_[2] ? $_[2] : '';
  return $Message::DOM::DOMImplementation::HasFeature->{$feature}->{$version};
} # is_supported;

sub manakai_append_text ($$) {
  ## NOTE: For |Element|, |Attr|, |Entity|, |EntityReference|,
  ## |DocumentFragment|, and |AttributeDefinition|.  In addition,
  ## |Document|'s |text_content| might call this attribute.
  
  ## NOTE: Overridden by |Document|, |DocumentType|, |CharacterData|, 
  ## |ElementTypeDefinition|, |Notation|, and |ProcessingInstruction|.

  my $self = $_[0];
  local $Error::Depth = $Error::Depth + 1;
  if (@{$$self->{child_nodes}} and
      $$self->{child_nodes}->[-1]->node_type == TEXT_NODE) {
    $$self->{child_nodes}->[-1]->manakai_append_text ($_[1]);
  } else {
    my $text = ($$self->{owner_document} or $self)->create_text_node ($_[1]);
    $self->append_child ($text);
  }
} # manakai_append_text

sub is_default_namespace ($$) {
  ## TODO: Document that ElementTypeDefinition and AttributeDefinition
  ## are same as DocumentType

  local $Error::Depth = $Error::Depth + 1;
  my $namespace_uri = defined $_[1] ? $_[1] : '';
  my $nt = $_[0]->node_type;
  if ($nt == ELEMENT_NODE) {
    my $el = $_[0];
    EL: {
      unless (defined $el->prefix) {
        my $elns = $el->namespace_uri;
        if ($namespace_uri ne '' and defined $elns) {
          return $namespace_uri eq $elns;
        } else {
          return not ($namespace_uri eq '' or defined $elns);
        }
      }
      my $xmlns = $el->get_attribute_ns
        ('http://www.w3.org/2000/xmlns/', 'xmlns');
      if (defined $xmlns) {
        if ($namespace_uri ne '') {
          return ($namespace_uri eq $xmlns);
        } else {
          return ($xmlns eq '');
        }
      }
      $el = $el->manakai_parent_element;
      redo EL if defined $el;
      return 0;
    } # EL;
  } else {
    my $el = $nt == DOCUMENT_NODE
      ? $_[0]->document_element
      : $nt == ATTRIBUTE_NODE
        ? $_[0]->owner_element
        : $_[0]->manakai_parent_element;
    if (defined $el) {
      return $el->is_default_namespace ($_[1]);
    } else {
      return 0;
    }
  }
} # is_default_namespace

sub lookup_namespace_uri ($$) {
  ## TODO: Need definition for ElementTypeDefinition and AttributeDefinition

  my ($self, $prefix) = @_;
  $prefix = undef if defined $prefix and $prefix eq '';
      ## NOTE: Implementation dependent.
      ## TODO: Check what Gecko does.
  local $Error::Depth = $Error::Depth + 1;
  my $nt = $self->node_type;
  if ($nt == ELEMENT_NODE) {
    my $el = $self;
    EL: {
      my $elns = $el->namespace_uri;
      if (defined $elns) {
        my $elpfx = $el->prefix;
        if ((not defined $prefix and not defined $elpfx) or
            (defined $prefix and defined $elpfx and $prefix eq $elpfx)) {
          return $elns;
        }
      }
      AT: for my $attr (@{$el->attributes}) {
        my $attrns = $attr->namespace_uri;
        next AT if not defined $attrns or
          $attrns ne 'http://www.w3.org/2000/xmlns/';
        my $attrpfx = $attr->prefix;
        if (not defined $prefix) {
          my $attrln = $attr->local_name;
          if ($attrln eq 'xmlns') {
            my $attrval = $attr->value;
            return length $attrval ? $attrval : undef;
          }
        } elsif (defined $prefix and
                 defined $attrpfx and $attrpfx eq 'xmlns') {
          my $attrln = $attr->local_name;
          if ($attrln eq $prefix) {
            my $attrval = $attr->value;
            return length $attrval ? $attrval : undef;
          }
        }
      } # AT
      $el = $el->manakai_parent_element;
      redo EL if defined $el;
      return undef;
    } # EL;
  } else {
    my $el = $nt == DOCUMENT_NODE
      ? $self->document_element
      : $nt == ATTRIBUTE_NODE
        ? $self->owner_element
        : $self->manakai_parent_element;
    if (defined $el) {
      return $el->lookup_namespace_uri ($prefix);
    } else {
      return undef;
    }
  }
} # lookup_namespace_uri

sub lookup_prefix ($$) {
  ## ISSUE: Document ElementTypeDefinition and AttributeDefinition
  ## behavior (i.e. same as DocumentType)

  my $namespace_uri = defined $_[1] ? $_[1] : '';
  if ($namespace_uri eq '') {
    return undef;
  }

  local $Error::Depth = $Error::Depth + 1;
  my $nt = $_[0]->node_type;
  if ($nt == ELEMENT_NODE) {
    my $el = $_[0];
    EL: {
      my $elns = $el->namespace_uri;
      if (defined $elns and $elns eq $namespace_uri) {
        my $elpfx = $el->prefix;
        if (defined $elpfx) {
          my $oeluri = $_[0]->lookup_namespace_uri ($elpfx);
          if (defined $oeluri and $oeluri eq $namespace_uri) {
            return $elpfx;
          }
        }
      }
      AT: for my $attr (@{$el->attributes}) {
        my $attrpfx = $attr->prefix;
        next AT if not defined $attrpfx or $attrpfx ne 'xmlns';
        my $attrns = $attr->namespace_uri;
        next AT if not defined $attrns or
          $attrns ne 'http://www.w3.org/2000/xmlns/';
        next AT unless $attr->value eq $namespace_uri;
        my $attrln = $attr->local_name;
        my $oeluri = $el->lookup_namespace_uri ($attrln);
        next AT unless defined $oeluri;
        if ($oeluri eq $namespace_uri) {
          return $attrln;
        }
      }
      $el = $el->manakai_parent_element;
      redo EL if defined $el;
      return undef;
    } # EL
  } else {
    my $el = $nt == DOCUMENT_NODE
      ? $_[0]->document_element
      : $nt == ATTRIBUTE_NODE
        ? $_[0]->owner_element
        : $_[0]->manakai_parent_element;
    if (defined $el) {
      return $el->lookup_prefix ($_[1]);
    } else { 
      return undef;
    }
  }
} # lookup_prefix

sub normalize ($) {
  my $self = shift;
  my $ptext;
  local $Error::Depth = $Error::Depth + 1;
  
  ## Children
  my @remove;
  for my $cn (@{$self->child_nodes}) {
    if ($cn->node_type == TEXT_NODE) {
      my $nv = $cn->node_value;
      if (length $nv) {
        if (defined $ptext) {
          $ptext->manakai_append_text ($nv);
          $ptext->is_element_content_whitespace (1)
            if $cn->is_element_content_whitespace and
              $ptext->is_element_content_whitespace;
          push @remove, $cn;
        } else {
          $ptext = $cn;
        }
      } else {
        push @remove, $cn;
      }
    } else {
      $cn->normalize;
      undef $ptext;
    }
  }
  $self->remove_child ($_) for @remove;

  my $nt = $self->node_type;
  if ($nt == ELEMENT_NODE) {
    ## Attributes
    $_->normalize for @{$self->attributes};
  } elsif ($nt == DOCUMENT_TYPE_NODE) {
    ## ISSUE: Document these explicitly in DOM XML Document Type Definitions spec
    ## Element type definitions
    $_->normalize for @{$self->element_types};
    ## General entities
    $_->normalize for @{$self->general_entities};
  } elsif ($nt == ELEMENT_TYPE_DEFINITION_NODE) {
    ## Attribute definitions
    $_->normalize for @{$self->attribute_definitions};
  }
  ## TODO: normalize-characters

  ## TODO: In this implementation, if a modification raises a 
  ## |NO_MODIFICATION_ALLOWED_ERR|, then any modification before it
  ## is not reverted.
} # normalize

sub remove_child ($$) {
  my ($self, $old_child) = @_;

  if ($$self->{manakai_read_only} and
      ${$$self->{owner_document} or $self}->{strict_error_checking}) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $parent_list = $$self->{child_nodes} || [];
  for (0..$#$parent_list) {
    if ($parent_list->[$_] eq $old_child) {
      splice @$parent_list, $_, 1, ();
      delete $$old_child->{parent_node};
      return $old_child;
    }
  }

  report Message::DOM::DOMException
      -object => $self,
      -type => 'NOT_FOUND_ERR',
      -subtype => 'NOT_CHILD_ERR';
} # remove_child

sub replace_child ($$) {
  ## NOTE: |Element|, |Entity|, |DocumentFragment|, |EntityReference|.
  ## NOTE: |Document|, |Attr|, |CharacterData|, |AttributeDefinition|,
  ## |Notation|, |ProcessingInstruction|, |ElementTypeDefinition|,
  ## and |DocumentType| define their own implementations.
  my $self = $_[0];

  ## NOTE: Depends on $self->node_type:
  my $self_od = $$self->{owner_document};

  ## -- Node Type check
  my @new_child;
  my $new_child_parent;
  if ($_[1]->node_type == DOCUMENT_FRAGMENT_NODE) {
    push @new_child, @{$_[1]->child_nodes};
    $new_child_parent = $_[1];
  } else {
    @new_child = ($_[1]);
    $new_child_parent = $_[1]->parent_node;
  }

  ## NOTE: Depends on $self->node_type:
  if ($$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if ($self_od ne $child_od and $child_od->node_type != DOCUMENT_TYPE_NODE) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    if ($$self->{manakai_read_only} or
        (@new_child and defined $new_child_parent and
         $$new_child_parent->{manakai_read_only})) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    ## NOTE: |Document| has children order check here.

    for my $cn (@new_child) {
      unless ({
               TEXT_NODE, 1, ENTITY_REFERENCE_NODE, 1,
               ELEMENT_NODE, 1, CDATA_SECTION_NODE, 1,
               PROCESSING_INSTRUCTION_NODE, 1, COMMENT_NODE, 1,
              }->{$cn->node_type}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    my $anode = $self;
    while (defined $anode) {
      if ($anode eq $_[1]) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'ANCESTOR_NODE_ERR';
      }
      $anode = $$anode->{parent_node};
    }
  }
  
  ## -- Insert at... ## NOTE: Only in insertBefore and replaceChild
  my $index = -1; # last
  if (defined $_[2]) {
    ## error if $_[1] eq $_[2];
    
    my $cns = $self->child_nodes;
    my $cnsl = @$cns;
    C: {
      $index = 0;
      for my $i (0..($cnsl-1)) {
        my $cn = $cns->[$i];
        if ($cn eq $_[2]) {
          $index += $i;
          last C;
        } elsif ($cn eq $_[1]) {
          $index = -1; # offset
        }
      }
      
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_FOUND_ERR',
          -subtype => 'NOT_CHILD_ERR';
    } # C
  } else {
    ## NOTE: Only in replaceChild
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  }

  ## -- Removes from parent
  if ($new_child_parent) {
    if (@new_child == 1) {
      my $v = $$new_child_parent->{child_nodes};
      RP: for my $i (0..$#$v) {
        if ($v->[$i] eq $new_child[0]) {
          splice @$v, $i, 1, ();
          last RP;
        }
      } # RP
    } else {
      @{$$new_child_parent->{child_nodes}} = ();
    }
  }

  ## -- Rewrite the |parentNode| properties
  for my $nc (@new_child) {
    $$nc->{parent_node} = $self;
    Scalar::Util::weaken ($$nc->{parent_node});
  }

  ## NOTE: Depends on method:
  splice @{$$self->{child_nodes}}, $index, 1, @new_child;
  delete ${$_[2]}->{parent_node};

  ## NOTE: Setting |owner_document| in |Document|.

  return $_[2];
} # replace_child

sub manakai_set_read_only ($;$$) {
  my $value = 1 if $_[1];
  if ($_[2]) {
    my @target = ($_[0]);
    while (@target) {
      my $target = shift @target;
      if ($value) {
        $$target->{manakai_read_only} = 1;
      } else {
        delete $$target->{manakai_read_only};
      }
      push @target, @{$target->child_nodes};
      
      my $nt = $target->node_type;
      if ($nt == ELEMENT_NODE) {
        push @target, @{$target->attributes};
      } elsif ($nt == ELEMENT_TYPE_DEFINITION_NODE) {
        push @target, @{$target->attribute_definitions};
      } elsif ($nt == DOCUMENT_TYPE_NODE) {
        push @target, @{$target->element_types};
        push @target, @{$target->general_entities};
        push @target, @{$target->notations};
      }
    }
  } else { # not deep
    if ($value) {
      ${$_[0]}->{manakai_read_only} = 1;
    } else {
      delete ${$_[0]}->{manakai_read_only};
    }
  }
} # manakai_set_read_only

#        {NOTE:: Perl application developers are advised to be careful
#                to include direct or indirect references to the node
#                itself as user data or in user data handlers.
#                They would result in memory leak problems unless
#                the circular references are removed later.
#                
#                It would be a good practive to eusure that every user data
#                registered to a node is later unregistered by setting
#                <DOM::null> as a data for the same key.
#
sub set_user_data ($$$;$) {
  my ($self, $key, $data, $handler) = @_;

  my $v = ($$self->{user_data} ||= {});
  my $r = $v->{$key}->[0];

  if (defined $data) {
    $v->{$key} = [$data, $handler];

    if (defined $handler) {
      eval q{
        no warnings;
        sub DESTROY {
          my $uds = ${$_[0]}->{user_data};
          for my $key (keys %$uds) {
            if (defined $uds->{$key}->[1]) {
              local $Error::Depth = $Error::Depth + 1;
              $uds->{$key}->[1]->(3, $key, $uds->{$key}->[0]); # NODE_DELETED
            }
          }
        }
      };
    }
  } else {
    delete $v->{$key};
  }
  return $r;
} # set_user_data

package Message::IF::Node;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/08/25 08:41:00 $
