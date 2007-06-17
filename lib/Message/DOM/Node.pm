package Message::DOM::Node;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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
    '==' => sub {
      return 0 unless UNIVERSAL::isa ($_[0], 'Message::IF::Node');
      ## TODO: implement is_equal_node
      return $_[0]->is_equal_node ($_[1]);
    },
    '!=' => sub {
      return not ($_[0] == $_[1]);
    },
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

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#DocumentPosition>

sub DOCUMENT_POSITION_DISCONNECTED () { 0x01 }
sub DOCUMENT_POSITION_PRECEDING () { 0x02 }
sub DOCUMENT_POSITION_FOLLOWING () { 0x04 }
sub DOCUMENT_POSITION_CONTAINS () { 0x08 }
sub DOCUMENT_POSITION_CONTAINED_BY () { 0x10 }
sub DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC () { 0x20 }

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
  } elsif ({
    ## Read-write attributes (DOMString, trivial accessors)
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          \${\$_[0]}->{$method_name} = ''.\$_[1];
        }
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

sub first_child ($) {
  my $self = shift;
  return $$self->{child_nodes} ? $$self->{child_nodes}->[0] : undef;
} # first_child

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

## TODO:
sub is_same_node ($$) {
  return $_[0] eq $_[1];
} # is_same_node

## TODO:
sub is_equal_node ($$) {
  return $_[0]->node_name eq $_[1]->node_name &&
    $_[0]->node_value eq $_[1]->node_value;
} # is_equal_node

sub manakai_parent_element ($) {
  my $self = shift;
  my $parent = $$self->{parent_node};
  while (defined $parent) {
    if ($parent->node_type == 1) { # ELEMENT_NODE
      return $parent;
    } else {
      $parent = $$parent->{parent_node};
    }
  }
  return undef;
} # manakai_parent_element

## NOTE: Only applied to Elements and Documents
sub append_child ($$) {
  my ($self, $new_child) = @_;
  if (defined $$new_child->{parent_node}) {
    my $parent_list = ${$$new_child->{parent_node}}->{child_nodes};
    for (0..$#$parent_list) {
      if ($parent_list->[$_] eq $new_child) {
        splice @$parent_list, $_, 1;
        last;
      }
    }
  }
  push @{$$self->{child_nodes}}, $new_child;
  $$new_child->{parent_node} = $self;
  Scalar::Util::weaken ($$new_child->{parent_node});
  ## TODO:
  $$new_child->{owner_document} = $self if $self->node_type == DOCUMENT_NODE;
  return $new_child;
} # append_child

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

sub get_feature {
  ## TODO:
  return $_[0];
}

## NOTE: Only applied to Elements and Documents
sub insert_before ($$;$) {
  my ($self, $new_child, $ref_child) = @_;
  if (defined $$new_child->{parent_node}) {
    my $parent_list = ${$$new_child->{parent_node}}->{child_nodes};
    for (0..$#$parent_list) {
      if ($parent_list->[$_] eq $new_child) {
        splice @$parent_list, $_, 1;
        last;
      }
    }
  }
  my $i = @{$$self->{child_nodes}};
  if (defined $ref_child) {
    for (0..$#{$$self->{child_nodes}}) {
      if ($$self->{child_nodes}->[$_] eq $ref_child) {
        $i = $_;
        last;
      }
    }
  }
  splice @{$$self->{child_nodes}}, $i, 0, $new_child;
  $$new_child->{parent_node} = $self;
  Scalar::Util::weaken ($$new_child->{parent_node});
  return $new_child;
} # insert_before

## NOTE: Only applied to Elements and Documents
sub remove_child ($$) {
  my ($self, $old_child) = @_;
  my $parent_list = $$self->{child_nodes};
  for (0..$#$parent_list) {
    if ($parent_list->[$_] eq $old_child) {
      splice @$parent_list, $_, 1;
      last;
    }
  }
  delete $$old_child->{parent_node};
  return $old_child;
} # remove_child

## NOTE: Only applied to Elements and Documents
sub has_child_nodes ($) {
  return @{${+shift}->{child_nodes}} > 0;
} # has_child_nodes

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

package Message::IF::Node;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/17 13:37:40 $
