
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
our $VERSION = do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

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
  if (ref ($self->{value}) eq 'ARRAY') {
    push @{$self->{value}}, $s;
  } else {
    $self->{value} .= $s;
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
    return $node->value;
  } else {
    return $opt{default};
  }
}

=item $attr_node = $x->set_attribute ($local_name => $value, %options)

Set the value of the attribute.  The attribute node is returned.

=cut

sub set_attribute ($$$;%) {
  my ($self, $name, $val, %o) = @_;
  if ({qw/HASH 1 CODE 1/}->{ref ($val)}) {
  ## TODO: common error handling
    die "set_attribute: @{[ref $val]}: new attribute value must be a string, an array reference or a blessed object";
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

sub value ($) {
  shift->{value};
}

sub stringify ($;%) {
  my ($self, %opt) = @_;
  my $r = '';
  if ($self->{type} eq '#document') {
    if ($opt{output_header}) {
      $r = "#?SuikaWiki/0.9\x0A";
    }
    my $ptype = '#';
    for (@{$self->{node}}) {
      $r .= "\x0A" if $ptype eq '#comment' && $_->{type} eq '#comment';
      $ptype = $_->{type};
      $r .= $_->stringify;
    }
  } elsif ($self->{type} eq '#element') {
    $r = $self->inner_text;
    $r =~ s/(^|\x0A)(?=([\\\@\#\s]))?/$1."  ".($2?"\\":"")/ges;
    if (scalar @{$self->{node}}) {
      $r = $self->{local_name}
         . ":\x0A  \@\@"
         . (ref ($self->{value}) eq 'ARRAY' ? '[list]' : '')
         . ":" . (($r !~ /[\x0D\x0A:]/) && (length ($r) < 50) ? '' : "\x0A")
         . $r . "\x0A";
      for (@{$self->{node}}) {
        next unless $_->{type} eq '#element';
        my $rc = $_->stringify;
        $rc =~ s/\x0A  /\x0A     /gs;
        $rc =~ s/(\x0A +\@)/$1\@/gs;
        $r .= '  @' . $rc;
      }
    } else {
      $r = $self->{local_name}
         . (ref ($self->{value}) eq 'ARRAY' ? '[list]' : '')
         . ":" . ((($r !~ /[\x0D\x0A:]/) && (length ($r) < 50)) ? '' : "\x0A")
         . $r . "\x0A";
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

sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
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

=over 4 

=item #comment

Comment declarement. <!-- -->

=item #element

Element.  Its XML representation consists of start tag, content and end tag,
like <TYPE>content</TYPE>.

=item #fragment

Fragment of nodes.  It's similar to DOM's fragment node.

=back

=head1 SEE ALSO

Message::Markup::SuikaWikiConfig20::Parser,
SuikaWikiConfig/2.0 
<http://suika.fam.cx/~wakaba/-temp/wiki/wiki?SuikaWikiConfig/2.0>

=head1 HISTORY

This module was part of SuikaWiki 2, with name of 
C<SuikaWiki::Markup::SuikaWikiConfig20>.

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/07/25 07:17:02 $
