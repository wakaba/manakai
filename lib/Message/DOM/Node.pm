package Message::DOM::Node;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::Node';
require Scalar::Util;

sub ____new ($$) {
  my $self = bless \({}), shift;
  $$self->{owner_document} = shift;
  Scalar::Util::weaken ($$self->{owner_document});
  return $self;
} # ____new

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    local_name => 1,
    namespace_uri => 1,
    owner_document => 1,
    parent_node => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        if (\@_ > 1) {
          require Carp;
          Carp::croak (qq<Can't modify read-only attribute>);
        }
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ({
    ## Read-write attributes (DOMString, trivial accessors)
    prefix => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        if (\@_ > 1) {
          \${\$_[0]}->{$method_name} = ''.$_[1];
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
sub local_name ($);
sub namespace_uri ($);
sub owner_document ($);
sub parent_node ($);
sub prefix ($;$);

## The |Node| interface - attribute

sub is_equal_node ($$) {
  return shift eq shift;
} # is_equal_node

sub manakai_local_name ($) {
  if (@_ > 1) {
    require Carp;
    Carp::croak (qq<Can't modify read-only attribute>);  
  }
  return ${$_[0]}->{local_name};
} # manakai_local_name

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

sub child_nodes ($) {
  ## TODO: NodeList
  return ${+shift}->{child_nodes} || [];
} # child_nodes

## NOTE: Only applied to Elements and Documents
sub append_child ($$) {
  my ($self, $new_child) = @_;
  if (defined $$new_child->{parent_node}) {
    my $parent_list = $$new_child->{parent_node}->{child_nodes};
    for (0..$#$parent_list) {
      if ($parent_list->[$_] eq $new_child) {
        splice @$parent_list, $_, 1;
      }
    }
  }
  push @{$$self->{child_nodes}}, $new_child;
  $$new_child->{parent_node} = $self;
  Scalar::Util::weaken ($$new_child->{parent_node});
  return $new_child;
} # append_child

## NOTE: Only applied to Elements and Documents
sub insert_before ($$;$) {
  my ($self, $new_child, $ref_child) = @_;
  if (defined $$new_child->{parent_node}) {
    my $parent_list = $$new_child->{parent_node}->{child_nodes};
    for (0..$#$parent_list) {
      if ($parent_list->[$_] eq $new_child) {
        splice @$parent_list, $_, 1;
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
    }
  }
  delete $$old_child->{parent_node};
  return $old_child;
} # remove_child

## NOTE: Only applied to Elements and Documents
sub has_child_nodes ($) {
  return @{${+shift}->{child_nodes}} > 0;
} # has_child_nodes

## NOTE: Only applied to Elements and Documents
sub first_child ($) {
  my $self = shift;
  return $$self->{child_nodes}->[0];
} # first_child

## NOTE: Only applied to Elements and Documents
sub last_child ($) {
  my $self = shift;
  return @{$$self->{child_nodes}} ? $$self->{child_nodes}->[-1] : undef;
} # last_child

## NOTE: Only applied to Elements and Documents
sub previous_sibling ($) {
  my $self = shift;
  my $parent = $$self->{parent_node};
  return undef unless defined $parent;
  my $r;
  for (@{$$parent->{child_nodes}}) {
    if ($_ eq $self) {
      return $r;
    } else {
      $r = $_;
    }
  }
  return undef;
} # previous_sibling

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

package Message::IF::Node;

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/13 12:04:50 $
