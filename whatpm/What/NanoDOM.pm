package What::NanoDOM;
use strict;

package What::NanoDOM::Node;

sub new ($) {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
} # new

sub is_equal_node ($$) {
  return shift eq shift;
} # is_equal_node

sub parent_node ($) {
  return shift->{parent_node};
} # parent_node

## NOTE: Only applied to Elements and Documents
sub child_nodes ($) {
  return shift->{child_nodes};
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
  $new_child->{parent_node} = $self; ## TODO: weaken this ref
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
  $new_child->{parent_node} = $self; ## TODO: weaken this ref
  return $new_child;
} # insert_before

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

package What::NanoDOM::Document;
push our @ISA, 'What::NanoDOM::Node';

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
  return What::NanoDOM::Text->new (shift);
} # create_text_node

sub create_comment ($$) {
  shift;
  return What::NanoDOM::Comment->new (shift);
} # create_comment

## The second parameter only supports manakai extended way
## to specify qualified name - "[$prefix, $local_name]"
sub create_element_ns ($$$) {
  my ($self, $nsuri, $qn) = @_;
  return What::NanoDOM::Element->new ($nsuri, $qn->[0], $qn->[1]);
} # create_element_ns

## A manakai extension
sub create_document_type_definition ($$) {
  shift;
  return What::NanoDOM::DocumentType->new (shift);
} # create_document_type_definition

package What::NanoDOM::Element;
push our @ISA, 'What::NanoDOM::Node';

sub new ($$$$) {
  my $self = shift->SUPER::new;
  $self->{namespace_uri} = shift;
  $self->{prefix} = shift;
  $self->{local_name} = shift;
  $self->{attributes} = {};
  $self->{child_nodes} = [];
  return $self;
} # new

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
      $clone->{attributes}->{$ns}->{$ln} = bless {
        prefix => $self->{attributes}->{$ns}->{$ln}->{prefix},
        value => $self->{attributes}->{$ns}->{$ln}->{value},
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
    my $text = What::NanoDOM::Text->new (shift);
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

sub has_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  return defined $self->{attributes}->{$nsuri}->{$ln};
} # has_attribute_ns

## The second parameter only supports manakai extended way
## to specify qualified name - "[$prefix, $local_name]"
sub set_attribute_ns ($$$$) {
  my ($self, $nsuri, $qn, $value) = @_;
  $self->{attributes}->{$nsuri}->{$qn->[1]}
    = What::NanoDOM::Attr->new ($nsuri, $qn->[0], $qn->[1], $value);
} # set_attribute_ns

package What::NanoDOM::Attr;
push our @ISA, 'What::NanoDOM::Node';

sub new ($$$$$) {
  my $self = shift->SUPER::new;
  $self->{namespace_uri} = shift;
  $self->{prefix} = shift;
  $self->{local_name} = shift;
  $self->{value} = shift;
  return $self;
} # new

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

package What::NanoDOM::CharacterData;
push our @ISA, 'What::NanoDOM::Node';

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

package What::NanoDOM::Text;
push our @ISA, 'What::NanoDOM::CharacterData';

sub node_type () { 3 }

package What::NanoDOM::Comment;
push our @ISA, 'What::NanoDOM::CharacterData';

sub node_type () { 8 }

package What::NanoDOM::DocumentType;
push our @ISA, 'What::NanoDOM::Node';

sub new ($$) {
  my $self = shift->SUPER::new;
  $self->{name} = shift;
  return $self;
} # new

sub node_type () { 10 }

sub name ($) {
  return shift->{name};
} # name

1;
# $Date: 2007/04/30 14:12:02 $
