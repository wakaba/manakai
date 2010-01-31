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
use warnings;
our $VERSION = '1.31';

require Scalar::Util;

package Whatpm::NanoDOM::DOMImplementation;

sub new ($) {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
} # new

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

sub node_name ($) { return $_[0]->{node_name} }

sub namespace_uri ($) { return undef }

## NOTE: Only applied to Elements and Documents
sub append_child ($$) {
  my ($self, $new_child) = @_;
  if (defined $new_child->{parent_node}) {
    my $parent_list = $new_child->{parent_node}->{child_nodes};
    for (reverse 0..$#$parent_list) {
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

sub text_content ($;$) {
  my $self = shift;
  if (@_) {
    @{$self->{child_nodes}} = (); ## NOTE: parent_node not unset.
    $self->append_child (Whatpm::NanoDOM::Text->new ($_[0])) if length $_[0];
    return unless wantarray;
  }
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

sub get_user_data ($$) {
  return $_[0]->{$_[1]};
} # get_user_data

sub set_user_data ($$;$$) {
  $_[0]->{$_[1]} = $_[2];
} # set_user_data

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
sub create_attribute_ns ($$$) {
  my ($self, $nsuri, $qn) = @_;
  return Whatpm::NanoDOM::Attr->new (undef, $nsuri, $qn->[0], $qn->[1], '');

  ## NOTE: Created attribute node should be set to an element node
  ## as far as possible.  |onwer_document| of the attribute node, for
  ## example, depends on the definedness of the |owner_element| attribute.
} # create_attribute_ns

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

## A manakai extension.
sub create_element_type_definition ($$) {
  shift;
  return Whatpm::NanoDOM::ElementTypeDefinition->new (shift);
} # create_element_type_definition

## A manakai extension.
sub create_general_entity ($$) {
  shift;
  return Whatpm::NanoDOM::Entity->new (shift);
} # create_general_entity

## A manakai extension.
sub create_notation ($$) {
  shift;
  return Whatpm::NanoDOM::Notation->new (shift);
} # create_notation

## A manakai extension.
sub create_attribute_definition ($$) {
  shift;
  return Whatpm::NanoDOM::AttributeDefinition->new (shift);
} # create_attribute_definition

sub create_processing_instruction ($$$) {
  return Whatpm::NanoDOM::ProcessingInstruction->new (@_);
} # creat_processing_instruction

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

sub dom_config ($) {
  return {};
} # dom_config

sub adopt_node ($$) {
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

sub manakai_is_html ($;$) {
  if (@_ > 1) {
    if ($_[1]) {
      $_[0]->{manakai_is_html} = 1;
    } else {
      delete $_[0]->{manakai_is_html};
      delete $_[0]->{manakai_compat_mode};
    }
  }
  return $_[0]->{manakai_is_html};
} # manakai_is_html

sub compat_mode ($) {
  if ($_[0]->{manakai_is_html}) {
    if ($_[0]->{manakai_compat_mode} eq 'quirks') {
      return 'BackCompat';
    }
  }
  return 'CSS1Compat';
} # compat_mode

sub manakai_compat_mode ($;$) {
  if ($_[0]->{manakai_is_html}) {
    if (@_ > 1 and defined $_[1] and
        {'no quirks' => 1, 'limited quirks' => 1, 'quirks' => 1}->{$_[1]}) {
      $_[0]->{manakai_compat_mode} = $_[1];
    }
    return $_[0]->{manakai_compat_mode} || 'no quirks';
  } else {
    return 'no quirks';
  }
} # manakai_compat_mode

sub manakai_head ($) {
  my $html = $_[0]->manakai_html;
  return undef unless defined $html;
  for my $el (@{$html->child_nodes}) {
    next unless $el->node_type == 1; # ELEMENT_NODE
    my $nsuri = $el->namespace_uri;
    next unless defined $nsuri;
    next unless $nsuri eq q<http://www.w3.org/1999/xhtml>;
    next unless $el->manakai_local_name eq 'head';
    return $el;
  }
  return undef;
} # manakai_head

sub manakai_html ($) {
  my $de = $_[0]->document_element;
  my $nsuri = $de->namespace_uri;
  if (defined $nsuri and $nsuri eq q<http://www.w3.org/1999/xhtml> and
      $de->manakai_local_name eq 'html') {
    return $de;
  } else {
    return undef;
  }
} # manakai_html

## NOTE: Manakai extension.
sub all_declarations_processed ($;$) {
  $_[0]->{all_declarations_processed} = $_[1] if @_ > 1;
  return $_[0]->{all_declarations_processed};
} # all_declarations_processed

sub input_encoding ($;$) {
  $_[0]->{input_encoding} = $_[1] if @_ > 1;
  return $_[0]->{input_encoding};
}

sub manakai_charset ($;$) {
  $_[0]->{manakai_charset} = $_[1] if @_ > 1;
  return $_[0]->{manakai_charset};
}

sub manakai_has_bom ($;$) {
  $_[0]->{manakai_has_bom} = $_[1] if @_ > 1;
  return $_[0]->{manakai_has_bom};
}

sub xml_version ($;$) {
  $_[0]->{xml_version} = $_[1] if @_ > 1;
  return $_[0]->{xml_version};
}

sub xml_encoding ($;$) {
  $_[0]->{xml_encoding} = $_[1] if @_ > 1;
  return $_[0]->{xml_encoding};
}

sub xml_standalone ($;$) {
  $_[0]->{xml_standalone} = $_[1] if @_ > 1;
  return $_[0]->{xml_standalone};
}

sub document_uri ($;$) {
  $_[0]->{document_uri} = $_[1] if @_ > 1;
  return $_[0]->{document_uri};
}

sub get_element_by_id ($$) {
  my @nodes = @{$_[0]->child_nodes};
  N: while (@nodes) {
    my $node = shift @nodes;
    next N unless $node->node_type == 1; # ELEMENT_NODE
    for my $attr (@{$node->attributes}) {
      if ($attr->manakai_local_name eq 'id' and $attr->value eq $_[1]) {
        return $node;
      }
    }
    unshift @nodes, @{$node->child_nodes};
  } # N
  return undef;
} # get_element_by_id

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
  $self->{attributes}->{defined $nsuri ? $nsuri : ''}->{$qn->[1]}
    = Whatpm::NanoDOM::Attr->new ($self, $nsuri, $qn->[0], $qn->[1], $value);
} # set_attribute_ns

sub set_attribute_node_ns ($$) {
  my $self = shift;
  my $attr = shift;
  my $ns = $attr->namespace_uri;
  $self->{attributes}->{defined $ns ? $ns : ''}->{$attr->manakai_local_name}
      = $attr;
  $attr->{owner_element} = $self;
  Scalar::Util::weaken ($attr->{owner_element});
} # set_attribute_node_ns

sub manakai_ids ($) {
  my $self = shift;
  my $id = $self->get_attribute_ns (undef, 'id');
  if (defined $id) {
    return [$id];
  } else {
    return [];
  }
} # manakai_ids

sub inner_html ($;$) {
  my $self = $_[0];

  if (@_ > 1) {
    require Whatpm::HTML;
    Whatpm::HTML->set_inner_html ($self, $_[1]);
    return unless defined wantarray;
  }
  
  require Whatpm::HTML::Serializer;
  return ${ Whatpm::HTML::Serializer->get_inner_html ($self) };
} # inner_html

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
  $self->{specified} = 1;
  return $self;
} # new

sub namespace_uri ($) {
  return shift->{namespace_uri};
} # namespace_uri

sub manakai_local_name ($) {
  return shift->{local_name};
} # manakai_local_name

sub node_type { 2 }

sub owner_document ($) {
  return shift->owner_element->owner_document;
} # owner_document

## TODO: HTML5 case stuff?
sub name ($) {
  my $self = shift;
  if (defined $self->{prefix}) {
    return $self->{prefix} . ':' . $self->{local_name};
  } else {
    return $self->{local_name};
  }
} # name

sub value ($;$) {
  if (@_ > 1) {
    $_[0]->{value} = $_[1];
  }
  return shift->{value};
} # value

sub owner_element ($) {
  return shift->{owner_element};
} # owner_element

sub specified ($;$) {
  $_[0]->{specified} = $_[1] if @_ > 1;
  return $_[0]->{specified} || 0;
}

sub manakai_attribute_type ($;$) {
  $_[0]->{manakai_attribute_type} = $_[1] if @_ > 1;
  return $_[0]->{manakai_attribute_type} || 0;
}

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
  $self->{element_types} = {};
  $self->{entities} = {};
  $self->{notations} = {};
  $self->{child_nodes} = [];
  return $self;
} # new

sub node_type () { 10 }

sub name ($) {
  return shift->{name};
} # name

sub public_id ($;$) {
  $_[0]->{public_id} = $_[1] if @_ > 1;
  return $_[0]->{public_id};
} # public_id

sub system_id ($;$) {
  $_[0]->{system_id} = $_[1] if @_ > 1;
  return $_[0]->{system_id};
} # system_id

sub element_types ($) {
  return $_[0]->{element_types};
} # element_types

sub entities ($) {
  return $_[0]->{entities};
} # entities

sub notations ($) {
  return $_[0]->{notations};
} # notations

sub get_element_type_definition_node ($$) {
  return $_[0]->{element_types}->{$_[1]};
} # get_element_type_definition_node

sub set_element_type_definition_node ($$) {
  $_[0]->{element_types}->{$_[1]->node_name} = $_[1];
} # set_element_type_definition_node

sub get_general_entity_node ($$) {
  return $_[0]->{entities}->{$_[1]};
} # get_general_entity_node

sub set_general_entity_node ($$) {
  $_[0]->{entities}->{$_[1]->node_name} = $_[1];
} # set_general_entity_node

sub get_notation_node ($$) {
  return $_[0]->{notations}->{$_[1]};
} # get_notation_node

sub set_notation_node ($$) {
  $_[0]->{notations}->{$_[1]->node_name} = $_[1];
} # set_notation_node

package Whatpm::NanoDOM::ProcessingInstruction;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$$$) {
  my $self = shift->SUPER::new;
  shift;
#  $self->{owner_document} = shift;
#  Scalar::Util::weaken ($self->{owner_document});
  $self->{target} = shift;
  $self->{data} = shift;
  return $self;
} # new

sub node_type () { 7 }

sub target ($) {
  return $_[0]->{target};
} # target

sub data ($;$) {
  $_[0]->{data} = $_[1] if @_ > 1;
  return $_[0]->{data};
} # data

package Whatpm::NanoDOM::Entity;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{node_name} = shift;
  $self->{child_nodes} = [];
  return $self;
} # new

sub node_type () { 6 }

sub public_id ($;$) {
  $_[0]->{public_id} = $_[1] if @_ > 1;
  return $_[0]->{public_id};
} # public_id

sub system_id ($;$) {
  $_[0]->{system_id} = $_[1] if @_ > 1;
  return $_[0]->{system_id};
} # system_id

sub notation_name ($;$) {
  $_[0]->{notation_name} = $_[1] if @_ > 1;
  return $_[0]->{notation_name};
} # notation_name

package Whatpm::NanoDOM::Notation;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{node_name} = shift;
  return $self;
} # new

sub node_type () { 12 }

sub public_id ($;$) {
  $_[0]->{public_id} = $_[1] if @_ > 1;
  return $_[0]->{public_id};
} # public_id

sub system_id ($;$) {
  $_[0]->{system_id} = $_[1] if @_ > 1;
  return $_[0]->{system_id};
} # system_id

package Whatpm::NanoDOM::ElementTypeDefinition;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{node_name} = shift;
  $self->{content_model} = '';
  $self->{attribute_definitions} = {};
  return $self;
} # new

sub node_type () { 81001 }

sub content_model_text ($;$) {
  $_[0]->{content_model} = $_[1] if @_ > 1;
  return $_[0]->{content_model};
} # content_model_text

sub attribute_definitions ($) { return $_[0]->{attribute_definitions} }

sub get_attribute_definition_node ($$) {
  return $_[0]->{attribute_definitions}->{$_[1]};
} # get_attribute_definition_node

sub set_attribute_definition_node ($$) {
  $_[0]->{attribute_definitions}->{$_[1]->node_name} = $_[1];
} # set_attribute_definition_node

package Whatpm::NanoDOM::AttributeDefinition;
push our @ISA, 'Whatpm::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{node_name} = shift;
  $self->{allowed_tokens} = [];
  return $self;
} # new

sub node_type () { 81002 }

sub allowed_tokens ($) { return $_[0]->{allowed_tokens} }

sub default_type ($;$) {
  $_[0]->{default_type} = $_[1] if @_ > 1;
  return $_[0]->{default_type} || 0;
} # default_type

sub declared_type ($;$) {
  $_[0]->{declared_type} = $_[1] if @_ > 1;
  return $_[0]->{declared_type} || 0;
} # declared_type

=head1 SEE ALSO

L<Whatpm::HTML|Whatpm::HTML>

L<Whatpm::XML::Parser|Whatpm::XML::Parser>

L<Whatpm::ContentChecker|Whatpm::ContentChecker>

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2007-2008, 2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
