=head1 NAME

Whatpm::NanoDOM - A Non-Conforming Implementation of DOM Subset

=head1 DESCRIPTION

The C<Whatpm::NanoDOM> module contains a non-conforming implementation
of a subset of DOM.  It is the intention that this module is
used only for the purpose of testing the C<Whatpm::HTML> module.

See source code if you would like to know what it does.

=cut

package Whatpm::NanoDOM;
use strict;

require Scalar::Util;

package Whatpm::NanoDOM::DOMImplementation;

sub create_document ($) {
  return Whatpm::NanoDOM::Document->new;
} # create_document

package Whatpm::NanoDOM::Node;

sub new ($) {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
} # new

sub parent_node ($) {
  return shift->{parent_node};
} # parent_node

sub manakai_parent_element ($) {
  my $self = shift;
  my $parent = $self->{parent_node};
  while (defined $parent) {
    if ($parent->node_type == 1) {
      return $parent;
    } else {
      $parent = $parent->{parent_node};
    }
  }
  return undef;
} # manakai_parent_element

sub child_nodes ($) {
  return shift->{child_nodes} || [];
} # child_nodes

## NOTE: Only applied to Elements and Documents
sub append_child ($$) {
  my ($self, $new_child) = @_;
  if (defined $new_child->{parent_node}) {
    my $parent_list = $new_child->{parent_node}->{child_nodes};
    for (0..$#$parent_list) {
      if ($parent_list->[$_] eq $new_child) {
        splice @$parent_list, $_, 1;
      }
    }
  }
  push @{$self->{child_nodes}}, $new_child;
  $new_child->{parent_node} = $self;
  Scalar::Util::weaken ($new_child->{parent_node});
  return $new_child;
} # append_child

## NOTE: Only applied to Elements and Documents
sub insert_before ($$;$) {
  my ($self, $new_child, $ref_child) = @_;
  if (defined $new_child->{parent_node}) {
    my $parent_list = $new_child->{parent_node}->{child_nodes};
    for (0..$#$parent_list) {
      if ($parent_list->[$_] eq $new_child) {
        splice @$parent_list, $_, 1;
      }
    }
  }
  my $i = @{$self->{child_nodes}};
  if (defined $ref_child) {
    for (0..$#{$self->{child_nodes}}) {
      if ($self->{child_nodes}->[$_] eq $ref_child) {
        $i = $_;
        last;
      }
    }
  }
  splice @{$self->{child_nodes}}, $i, 0, $new_child;
  $new_child->{parent_node} = $self;
  Scalar::Util::weaken ($new_child->{parent_node});
  return $new_child;
} # insert_before

## NOTE: Only applied to Elements and Documents
sub remove_child ($$) {
  my ($self, $old_child) = @_;
  my $parent_list = $self->{child_nodes};
  for (0..$#$parent_list) {
    if ($parent_list->[$_] eq $old_child) {
      splice @$parent_list, $_, 1;
    }
  }
  delete $old_child->{parent_node};
  return $old_child;
} # remove_child

## NOTE: Only applied to Elements and Documents
sub has_child_nodes ($) {
  return @{shift->{child_nodes}} > 0;
} # has_child_nodes

## NOTE: Only applied to Elements and Documents
sub first_child ($) {
  my $self = shift;
  return $self->{child_nodes}->[0];
} # first_child

## NOTE: Only applied to Elements and Documents
sub last_child ($) {
  my $self = shift;
  return @{$self->{child_nodes}} ? $self->{child_nodes}->[-1] : undef;
} # last_child

## NOTE: Only applied to Elements and Documents
sub previous_sibling ($) {
  my $self = shift;
  my $parent = $self->{parent_node};
  return undef unless defined $parent;
  my $r;
  for (@{$parent->{child_nodes}}) {
    if ($_ eq $self) {
      return $r;
    } else {
      $r = $_;
    }
  }
  return undef;
} # previous_sibling

sub prefix ($;$) {
  my $self = shift;
  if (@_) {
    $self->{prefix} = shift;
  }
  return $self->{prefix};
} # prefix

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

package Whatpm::NanoDOM::Document;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($) {
  my $self = shift->SUPER::new;
  $self->{child_nodes} = [];
  return $self;
} # new

## A manakai extension
sub manakai_append_text ($$) {
  my $self = shift;
  if (@{$self->{child_nodes}} and
      $self->{child_nodes}->[-1]->node_type == 3) {
    $self->{child_nodes}->[-1]->manakai_append_text (shift);
  } else {
    my $text = $self->create_text_node (shift);
    $self->append_child ($text);
  }
} # manakai_append_text

sub node_type () { 9 }

sub strict_error_checking {
  return 0;
} # strict_error_checking

sub create_text_node ($$) {
  shift;
  return Whatpm::NanoDOM::Text->new (shift);
} # create_text_node

sub create_comment ($$) {
  shift;
  return Whatpm::NanoDOM::Comment->new (shift);
} # create_comment

## The second parameter only supports manakai extended way
## to specify qualified name - "[$prefix, $local_name]"
sub create_element_ns ($$$) {
  my ($self, $nsuri, $qn) = @_;
  return Whatpm::NanoDOM::Element->new ($self, $nsuri, $qn->[0], $qn->[1]);
} # create_element_ns

## A manakai extension
sub create_document_type_definition ($$) {
  shift;
  return Whatpm::NanoDOM::DocumentType->new (shift);
} # create_document_type_definition

sub implementation ($) {
  return 'Whatpm::NanoDOM::DOMImplementation';
} # implementation

sub document_element ($) {
  my $self = shift;
  for (@{$self->child_nodes}) {
    if ($_->node_type == 1) {
      return $_;
    }
  }
  return undef;
} # document_element

sub adopt_node {
  my @node = ($_[1]);
  while (@node) {
    my $node = shift @node;
    $node->{owner_document} = $_[0];
    Scalar::Util::weaken ($node->{owner_document});
    push @node, @{$node->child_nodes};
    push @node, @{$node->attributes or []} if $node->can ('attributes');
  }
  return $_[1];
} # adopt_node

package Whatpm::NanoDOM::Element;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$$$$) {
  my $self = shift->SUPER::new;
  $self->{owner_document} = shift;
  Scalar::Util::weaken ($self->{owner_document});
  $self->{namespace_uri} = shift;
  $self->{prefix} = shift;
  $self->{local_name} = shift;
  $self->{attributes} = {};
  $self->{child_nodes} = [];
  return $self;
} # new

sub owner_document ($) {
  return shift->{owner_document};
} # owner_document

sub clone_node ($$) {
  my ($self, $deep) = @_; ## NOTE: Deep cloning is not supported
  my $clone = bless {
    namespace_uri => $self->{namespace_uri},
    prefix => $self->{prefix},
    local_name => $self->{local_name},      
    child_nodes => [],
  }, ref $self;
  for my $ns (keys %{$self->{attributes}}) {
    for my $ln (keys %{$self->{attributes}->{$ns}}) {
      my $attr = $self->{attributes}->{$ns}->{$ln};
      $clone->{attributes}->{$ns}->{$ln} = bless {
        namespace_uri => $attr->{namespace_uri},
        prefix => $attr->{prefix},
        local_name => $attr->{local_name},
        value => $attr->{value},
      }, ref $self->{attributes}->{$ns}->{$ln};
    }
  }
  return $clone;
} # clone

## A manakai extension
sub manakai_append_text ($$) {
  my $self = shift;
  if (@{$self->{child_nodes}} and
      $self->{child_nodes}->[-1]->node_type == 3) {
    $self->{child_nodes}->[-1]->manakai_append_text (shift);
  } else {
    my $text = Whatpm::NanoDOM::Text->new (shift);
    $self->append_child ($text);
  }
} # manakai_append_text

sub text_content ($) {
  my $self = shift;
  my $r = '';
  for my $child (@{$self->child_nodes}) {
    if ($child->can ('data')) {
      $r .= $child->data;
    } else {
      $r .= $child->text_content;
    }
  }
  return $r;
} # text_content

sub attributes ($) {
  my $self = shift;
  my $r = [];
  ## Order MUST be stable
  for my $ns (sort {$a cmp $b} keys %{$self->{attributes}}) {
    for my $ln (sort {$a cmp $b} keys %{$self->{attributes}->{$ns}}) {
      push @$r, $self->{attributes}->{$ns}->{$ln}
        if defined $self->{attributes}->{$ns}->{$ln};
    }
  }
  return $r;
} # attributes

sub local_name ($) { # TODO: HTML5 case
  return shift->{local_name};
} # local_name

sub manakai_local_name ($) {
  return shift->{local_name}; # no case fixing for HTML5
} # manakai_local_name

sub namespace_uri ($) {
  return shift->{namespace_uri};
} # namespace_uri

sub manakai_element_type_match ($$$) {
  my ($self, $nsuri, $ln) = @_;
  if (defined $nsuri) {
    if (defined $self->{namespace_uri} and $nsuri eq $self->{namespace_uri}) {
      return ($ln eq $self->{local_name});
    } else {
      return 0;
    }
  } else {
    if (not defined $self->{namespace_uri}) {
      return ($ln eq $self->{local_name});
    } else {
      return 0;
    }
  }
} # manakai_element_type_match

sub node_type { 1 }

## TODO: HTML5 capitalization
sub tag_name ($) {
  my $self = shift;
  if (defined $self->{prefix}) {
    return $self->{prefix} . ':' . $self->{local_name};
  } else {
    return $self->{local_name};
  }
} # tag_name

sub get_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return defined $self->{attributes}->{$nsuri}->{$ln}
    ? $self->{attributes}->{$nsuri}->{$ln}->value : undef;
} # get_attribute_ns

sub get_attribute_node_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return $self->{attributes}->{$nsuri}->{$ln};
} # get_attribute_node_ns

sub has_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return defined $self->{attributes}->{$nsuri}->{$ln};
} # has_attribute_ns

## The second parameter only supports manakai extended way
## to specify qualified name - "[$prefix, $local_name]"
sub set_attribute_ns ($$$$) {
  my ($self, $nsuri, $qn, $value) = @_;
  $self->{attributes}->{$nsuri}->{$qn->[1]}
    = Whatpm::NanoDOM::Attr->new ($self, $nsuri, $qn->[0], $qn->[1], $value);
} # set_attribute_ns

package Whatpm::NanoDOM::Attr;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$$$$$) {
  my $self = shift->SUPER::new;
  $self->{owner_element} = shift;
  Scalar::Util::weaken ($self->{owner_element});
  $self->{namespace_uri} = shift;
  $self->{prefix} = shift;
  $self->{local_name} = shift;
  $self->{value} = shift;
  return $self;
} # new

sub namespace_uri ($) {
  return shift->{namespace_uri};
} # namespace_uri

sub manakai_local_name ($) {
  return shift->{local_name};
} # manakai_local_name

sub node_type { 2 }

## TODO: HTML5 case stuff?
sub name ($) {
  my $self = shift;
  if (defined $self->{prefix}) {
    return $self->{prefix} . ':' . $self->{local_name};
  } else {
    return $self->{local_name};
  }
} # name

sub value ($) {
  return shift->{value};
} # value

sub owner_element ($) {
  return shift->{owner_element};
} # owner_element

package Whatpm::NanoDOM::CharacterData;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{data} = shift;
  return $self;
} # new

## A manakai extension
sub manakai_append_text ($$) {
  my ($self, $s) = @_;
  $self->{data} .= $s;
} # manakai_append_text

sub data ($) {
  return shift->{data};
} # data

package Whatpm::NanoDOM::Text;
push our @ISA, 'Whatpm::NanoDOM::CharacterData';

sub node_type () { 3 }

package Whatpm::NanoDOM::Comment;
push our @ISA, 'Whatpm::NanoDOM::CharacterData';

sub node_type () { 8 }

package Whatpm::NanoDOM::DocumentType;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{name} = shift;
  return $self;
} # new

sub node_type () { 10 }

sub name ($) {
  return shift->{name};
} # name

=head1 SEE ALSO

L<Whatpm::HTML>

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2007/06/23 06:38:12 $
