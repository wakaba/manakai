
=head1 NAME

Message::Markup::SuikaWikiConfig20::Node: manakai --- SuikaWikiConfig/2.0 data object and serialization

=head1 DESCRIPTION

This module provides modeled object tree handling for SuikaWikiConfig/2.0 data
format.  It also provides a mean of serializing object data tree in
SuikaWikiConfig/2.0 format.

Note that to parse plain SuikaWikiConfig/2.0 data and compose object
tree for it, Message::Markup::SuikaWikiConfig20::Parser
can be used.

This module is part of manakai.

=cut

package Message::Markup::SuikaWikiConfig20::Node;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 METHODS

=over 4

=item $x = Message::Markup::SuikaWikiConfig20::Node->new (%options)

Returns new instance of the module.  It is itself a node.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->{type} ||= '#element';
  $self->{node} ||= [];
  $self;
}

=item $x->append_node ($node)

Appending given node to the object (as the last child).
If the type of given node is C<#fragment>, its all children, not the node
itself, are appended.

This method returns the appended node unless the type of given node is C<#fragment>.
In such cases, this node (C<$x>) is returned.

Available options: C<node_or_text>.

=cut

sub append_node ($$;%) {
  my $self = shift;
  my ($new_node, %o) = @_;
  unless (ref $new_node) {
    if ($o{node_or_text}) {
      return $self->append_text ($new_node);
    } else {
      die "append_node: Invalid node";
    }
  }
  if ($new_node->{type} eq '#fragment') {
    for (@{$new_node->{node}}) {
      push @{$self->{node}}, $_;
      $_->{parent} = $self;
    }
    $self;
  } else {
    push @{$self->{node}}, $new_node;
    $new_node->{parent} = $self;
    $new_node;
  }
}

=item $new_node = $x->append_new_node (%options)

Appending a new node.  The new node is returned.

=cut

sub append_new_node ($;%) {
  my $self = shift;
  my $new_node = __PACKAGE__->new (@_);
  push @{$self->{node}}, $new_node;
  $new_node->{parent} = $self;
  $new_node;
}

=item $new_node = $x->append_text ($text)

Appending given text as a new text node.  The new text node is returned.

=cut

sub append_text ($$;%) {
  my $self = shift;
  my $s = shift;
  unless (defined $s) {
    require Carp;
    Carp::carp (q<Use of uninitialized value in "append_text">);
  } elsif (ref ($self->{value}) eq 'ARRAY') {
    push @{$self->{value}}, $s;
  } elsif (defined $self->{value}) {
    $self->{value} .= $s;
  } else {
    $self->{value} = $s;
  }
}

sub remove_child_node ($$) {
  my ($self, $node) = @_;
  return unless ref $node;
  $node = overload::StrVal ($node);
  $self->{node} = [grep { overload::StrVal ($_) ne $node } @{$self->{node}}];
}

=item $attr_node = $x->get_attribute ($local_name, %options)

Returns the attribute node whose local-name is C<$local_name>.

=item $attr_val = $x->get_attribute_value ($local_name)

Returnes the attribute value whose attribute name is C<$local_name>.

=cut

sub get_attribute ($$;%) {
  my ($self, $name, %o) = @_;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#element'
        && $_->{local_name} eq $name) {
      return $_;
    }
  }
  ## Node is not exist
  if ($o{make_new_node}) {
    return $self->append_new_node (type => '#element', local_name => $name);
  } else {
    return undef;
  }
}
sub get_attribute_value ($$;%) {
  my ($self, $name, %opt) = @_;
  my $node = $self->get_attribute ($name);
  if (ref $node) {
    my $val = $node->value (%opt);
    if ($opt{default_list} and ref $val eq 'ARRAY' and @$val == 0) {
      return $opt{default_list};
    } else {
      return $val;
    }
  } else {
    return $opt{default_list} || $opt{default};
  }
}

sub get_element_by ($$;%) {
  my ($self, $code, %opt) = @_;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#element' and
        $code->($self, $_, %opt)) {
      return $_;
    }
  }
  ## Node is not exist
  if ($opt{make_new_node}) {
    my $n = $self->append_new_node (type => '#element', local_name => 'Node');
    $opt{make_new_node}->($self, $n, %opt)
      if ref $opt{make_new_node} eq 'CODE';
    return $n;
  } else {
    return undef;
  }
}
=item $attr_node = $x->set_attribute ($local_name => $value, %options)

Set the value of the attribute.  The attribute node is returned.

=cut

sub set_attribute ($$$;%) {
  my ($self, $name, $val, %o) = @_;
  if ({qw/HASH 1 CODE 1/}->{ref ($val)}) {
  ## TODO: common error handling
    require Carp;
    Carp::croak ("set_attribute: @{[ref $val]}: new attribute value must be a string, an array reference or a blessed object");
  }
  for (@{$self->{node}}) {
    if ($_->{type} eq '#element'
        && $_->{local_name} eq $name) {
      $_->{value} = $val;
      $_->{node} = [];
      return $_;
    }
  }
  return $self->append_new_node (type => '#element', local_name => $name,
                                 value => $val);
}

=item $x->remove_attribute ($local_name, %options)

Removes an attribute node.

=cut

sub remove_attribute ($$;%) {
  my ($self, $name, %opt) = @_;
  $self->{node} = [grep {
    if ($_->{type} eq '#element' and
        $_->{local_name} eq $name) {
      delete $_->{parent};
      0;
    } else {
      1;
    }
  } @{$self->{node}}];
  1;
}

=item \@children = $x->child_nodes

Returns an array reference to child nodes.

=item $local_name = $x->local_name ([$new_name])

Returns or set the local-name.

=item $type = $x->node_type

Returns the node type.

=item $node = $x->parent_node

Returns the parent node.  If there is no parent node, undef is returned.

=cut

sub child_nodes ($) { $_[0]->{node} }
sub local_name ($;$) {
  my ($self, $newname) = @_;
  $self->{local_name} = $newname if $newname;
  $self->{local_name}
}
sub node_type ($) { $_[0]->{type} }
sub parent_node ($) { $_[0]->{parent} }

=item $i = $x->count

Returns the number of child nodes.

=cut

# TODO: support counting by type
sub count ($;@) {
  (defined $_[0]->{value} ? 1 : 0) + scalar @{$_[0]->{node}};
}

=item $tag = $x->inner_text

Returns the text content of the node.  (In many case the returned value is same
as WinIE DOM C<inner_text ()> function's or XPath C<text()> function's.
But some classes that inherits this module might implement to return other
value (eg. to return the value of the alt attribute of html:img element).

=cut

sub inner_text ($;%) {
  my $self = shift;
  my %o = @_;
  my $r = '';
  if (defined $o{new_value}) {
    $self->{value} = $o{new_value};
  }
  ref ($self->{value}) eq 'ARRAY' ? join "\x0A", @{$self->{value}} :
                                    $self->{value};
}

sub value ($;%) {
  my ($self, %opt) = @_;
  if ($opt{as_array} and ref $self->{value} ne 'ARRAY') {
    defined $self->{value} ? [$self->{value}] : [];
  } else {
    $self->{value};
  }
}

sub stringify ($;%) {
  my ($self, %opt) = @_;
  my $r = '';
  if ($self->{type} eq '#document') {
    if ($opt{output_header}) {
      $r = "#?SuikaWikiConfig/2.0\x0A";
    }
    my $ptype = '#';
    for (@{$self->{node}}) {
      $r .= "\x0A" if $ptype eq '#comment' && $_->{type} eq '#comment';
      $ptype = $_->{type};
      $r .= $_->stringify;
    }
  } elsif ($self->{type} eq '#element') {
    $r = $self->inner_text;
    if (scalar @{$self->{node}}) {
      if (defined $r) {
        $r =~ s/(^|\x0A)(?=([\\\@\#\s]|$))?/$1."  ".(defined $2?"\\":"")/ges;
        $r = $self->{local_name}
           . ":\x0A  \@\@"
           . (ref ($self->{value}) eq 'ARRAY' ? '[list]' : '')
           . ":" . (($r !~ /[\x0D\x0A:]/) && (length ($r) < 50) ? '' : "\x0A")
           . (length $r ? $r : '\\') . "\x0A";
      } else {
        $r = $self->{local_name}
           . ":\x0A";
      }
      for (@{$self->{node}}) {
        next unless $_->{type} eq '#element';
        my $rc = $_->stringify;
        $rc =~ s/\x0A  /\x0A     /gs;
        $rc =~ s/(\x0A +\@)/$1\@/gs;
        $r .= '  @' . $rc;
      }
    } else {
      $r = '' unless defined $r;
      $r =~ s/(^|\x0A)(?=([\\\@\#\s]|$))?/$1."  ".(defined $2?"\\":"")/ges;
      $r = $self->{local_name}
         . (ref ($self->{value}) eq 'ARRAY' ? '[list]' : '')
         . ":" . ((($r !~ /[\x0D\x0A:]/) && (length ($r) < 50)) ? '' : "\x0A")
         . (length $r ? $r : '\\') . "\x0A";
    }
    $r = "\\" . $r if substr ($r, 0, 1) =~ /[\\\@\#\s]/;
  } else {
    $r = $self->inner_text;
    $r =~ s/\x0A/\x0A#/gs;
    $r = '#' . $r . "\n";
  }
  $r;
}

sub root_node ($) {
  my $self = shift;
  if ($self->{type} eq '#document') {
    return $self;
  } elsif (ref $self->{parent}) {
    return $self->{parent}->root_node;
  } else {
    return $self;
  }
}

=item $node->node_path (key => attr-name)

Represent position in the tree in informal XPath-like expression.

Note: In current implementation, the format of expressions
is insufficient to identify a node uniquely and it is
not XPath compatible.

Options:

=over 4

=item key => ( attr-name | [attr-name1, attr-name2, ...] )

An attribute name or an array reference of attribute names that 
are used as 'key's.

=back

=cut

sub node_path ($;%) {
  my ($self, %opt) = @_;
  my $r;
  if ($self->{parent}) {
    $r = $self->{parent}->node_path (%opt);
  } else {
    $r = '';
  }
  if ($self->node_type eq '#element') {
    $r .= '/' . $self->local_name;
    if ($opt{key}) {
      for (ref $opt{key} eq 'ARRAY' ? @{$opt{key}} : $opt{key}) {
        my $key = $self->get_attribute_value ($_);
        if (defined $key) {
          $r .= '[@' . $_ . '=' . $key . ']';
        }
      }
    }
  } elsif ($self->node_type eq '#comment') {
    $r .= q</comment ()>;
  } elsif ($self->node_type eq '#document') {
    $r .= '/document ()';
  } elsif ($self->node_type eq '#fragment') {
    $r .= '/fragment ()';
  }
  $r;
}


sub flag ($$;$%) {
  my ($self, $name, $value, %opt) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  defined $self->{flag}->{$name} ?
    $self->{flag}->{$name} : $opt{default};
}

sub option ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
}

sub clone ($;%) {
  my $self = shift;
  my $clone = bless {node => []}, ref $self;
  ## TODO: Cloning recursively
  $clone->{flag} = {%{$self->{flag}||{}}};
  $clone->{option} = {%{$self->{option}||{}}};
  for (qw/local_name value type/) {
    $clone->{$_} = $self->{$_};
  }
  for (@{$self->{node}}) {
    push @{$clone->{node}}, $_->clone;
  }
  $_->{parent} = $clone for @{$clone->{node}};
  $clone;
}

=back

=head1 NODE TYPES

This module uses three types of node.

=over 4 

=item #comment

Comment.  Only #document (root) node and #fragment node
in well-formed tree can contain this type of node as children.

Comment has a value, but no child.

=item #document

Document.  This type of node must be the root node.

Document can have any number of #element and #comment, in any order,
but no value.

=item #element

Element.

Element can have any number of children.  Children must also be #element's.
Element has a value, which can be C<undef> (that is different from
empty) in case the element has one or more children (cannot be
C<undef> if it does not have child).

A value is either a scalar or a list.  List is represented as a reference
to an array in this module.  Note that list with some multiple-line strings
cannot be serialized, since SuikaWikiConfig/2.0 text format
does not allow it.

=item #fragment

Fragment of nodes.  It's similar to DOM's fragment node.

=back

=head1 SEE ALSO

C<Message::Markup::SuikaWikiConfig20::Parser>:
Perl module that parses SuikaWikiConfig/2.0 text format
document and constructs C<Message::Markup::SuikaWikiConfig20::Node>
tree instance.

SuikaWikiConfig/2.0 
<http://suika.fam.cx/~wakaba/-temp/wiki/wiki?SuikaWikiConfig/2.0>:
Formal specification and informal descriptions of 
the SuikaWikiConfig/2.0 format.

Latest version of this module is available at the
manakai CVS repository
<http://suika.fam.cx/gate/cvs/messaging/manakai/lib/Message/Markup/SuikaWikiConfig20/Parser.pm>.

=head1 HISTORY

SuikaWikiConfig/2.0 format was originally defined
for SuikaWiki <http://suika.fam.cx/~wakaba/-temp/wiki?SuikaWiki>.

This module, formally known as C<SuikaWiki::Markup::SuikaWikiConfig20>,
was part of SuikaWiki distribution.

=head1 LICENSE

Copyright 2003-2004 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/02/18 06:13:52 $
