
=head1 NAME

Message::Markup::XML::XPath --- manakai XML : XML Path Language (XPath) support

=head1 DESCRIPTION

This module implements abstracted XPath object and its
serialization to the expression.

To parse XPath expression, use Message::Markup::XML::XPath::Parser.

This module is part of manakai XML.

=cut

package Message::Markup::XML::XPath;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NCNameStartChar InXMLNCNameChar!;
use Message::Markup::XML::QName qw&DEFAULT_PFX NULL_URI UNDEF_URI&;

use overload 
      '""' => \&stringify,
      fallback => 1;

our %NS = (
           SGML	=> 'urn:x-suika-fam-cx:markup:sgml:',
           XML	=> 'urn:x-suika-fam-cx:markup:xml:',
           internal_ns_invalid	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#',
           xml	=> 'http://www.w3.org/XML/1998/namespace',
           xmlns	=> 'http://www.w3.org/2000/xmlns/',
           xpath => 'urn:x-suika-fam-cx:markup:xpath:',
           xslt => 'urn:x-suika-fam-cx:markup:xslt:',
);

=head1 METHODS

=over 4

=item $x = Message::Markup::XML::XPath->new (%options)

Returns new instance of the module.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {
                    axis => 'child',           # axis of step
                    namespace_uri => NULL_URI, # namespace name of node test
                                               #   or function call
                    node => [],                # step in location path
                                               #   or arguments of function call
                    option => {is_context_function_library => {$NS{xpath} => 1}},
                    predict => [],             # predicts in step,etc.
                    type => '#step',           # object type
                    value => '',               # string value of literal 
                                               # or number value
                    @_}, $class;
  for (@{$self->{node}}, @{$self->{predict}}) {
    $_->{parent} = $self;
  }
  $self;
}

=item $x->append_node ($step)

Appending given step to the object (as the last child).
If the type of given step is C<#fragment>, its all children, not the step
itself, are appended.

This method returns the appended step unless the type of given step 
is C<#fragment>. In such cases, this step (C<$x>) is returned.


=cut

sub append_node ($$;%) {
  my $self = shift;
  my ($new_node, %o) = @_;
  unless (ref $new_node) {
    die "append_node: Invalid node";
  }
  if ($new_node->{type} eq '#fragment') {
    for (@{$new_node->{predict}}) {
      push @{$self->{predict}}, $_;
      $_->{parent} = $self;
    }
    $self;
  } else {
    push @{$self->{node}}, $new_node;
    $new_node->{parent} = $self;
    $new_node;
  }
}

=item $new_step = $x->append_new_node (%options)

Appending a new step.  The new node is returned.

=cut

sub append_new_node ($;%) {
  my $self = shift;
  my $new_node = ref ($self)->new (@_, parent => $self);
  push @{$self->{node}}, $new_node;
  $new_node;
}

sub append_new_predict ($;%) {
  my $self = shift;
  my $new_node = ref ($self)->new (@_, parent => $self);
  push @{$self->{predict}}, $new_node;
  $new_node;
}

=item $new_node = $x->append_text ($text)

Appending given text as a new text node.  The new text node is returned.

=cut

sub append_text ($$;%) {
  my ($self, $s, %opt) = @_;
  $s->{value} .= $s;
}

## Non public interface
sub append_baretext ($$;%) {
  my ($self, $s, %opt) = @_;
  $s->{value} .= $s;
}

sub remove_child_node ($$) {
  my ($self, $node) = @_;
  return unless ref $node;
  $node = overload::StrVal ($node);
  $self->{node} = [grep { overload::StrVal ($_) ne $node } @{$self->{node}}];
}

=item \@children = $x->child_nodes

Returns an array reference to child nodes.

=item $local_name = $x->local_name ([$new_name])

Returns or set the local-name.

=item $uri = $x->namespace_uri ([$new_uri])

Returns or set namespace name (URI) of the element or the attribute

=item $uri = $x->namespace_prefix ([$new_prefix])

Returns or set namespace prefix of the element or the attribute.
You may give C<$new_prefix> in form either 'foo' or 'foo:'.
To indicate "default" prefix, use '' (length == 0 string).

=item $uri or ($uri, $name) = $x->expanded_name

Returns expanded name of the node (element or attribute).
In array context, array of namespace name (URI) and local part
is returned; otherwise, a URI which identify name of the node
(in RDF or WebDAV) is returned.

=item $type = $x->node_type

Returns the node type.

=item $node = $x->parent_node

Returns the parent node.  If there is no parent node, undef is returned.

=cut

sub child_nodes ($) { $_[0]->{node} }
sub local_name ($;$) {
  my ($self, $newname) = @_;
  $self->{local_name} = $newname if $newname;
  $self->{local_name};
}
sub node_type ($) { $_[0]->{type} }
sub parent_node ($) { $_[0]->{parent} }

sub namespace_uri ($;$) {
  my ($self, $new_uri) = @_;
  $self->{namespace_uri} = length $new_uri ? $new_uri : NULL_URI
    if defined $new_uri;
  $self->{namespace_uri};
}
sub namespace_prefix ($;$) {
  my ($self, $new_pfx) = @_;
  return DEFAULT_PFX if $self->{namespace_uri} eq NULL_URI;
  
  my $decls = $self->_get_ns_decls_node ();
  
  if (defined ($new_pfx) && $self->{namespace_uri}) {
    Message::Markup::XML::QName::register_prefix_to_name
        ($decls, $new_pfx => $self->{namespace_uri},
         check_prefix => 1, check_xml => 1, check_xmlns => 1);
  }
  Message::Markup::XML::QName::name_to_prefix
      ($decls, $self->{namespace_uri},
       make_new_prefix => 1)
  ->{prefix};
}

sub expanded_name ($) {
  my $self = shift;
  wantarray ? ($self->{namespace_uri}, $self->{local_name})
            : $self->{namespace_uri} . $self->{local_name};
}

=item $i = $x->count

Returns the number of child nodes.

=cut

sub count ($;@) {
  scalar @{$_[0]->{node}};
}

=item $qname = $x->qname

Returns QName ((namespace-)qualified name) of the element type.
Undef is retuened when the type does not have its QName
(ie. when type is neither C<#element> or C<#attribute>).

=cut

sub qname ($;%) {
  my ($self, %opt) = @_;
  my $decls = $self->_get_ns_decls_node ();
  my $q = Message::Markup::XML::QName::expanded_name_to_qname
            ($decls,
             (($opt{use_context_function_library}
               && $self->{option}->{is_context_function_library}
                                 ->{$self->{namespace_uri}}) ?
              NULL_URI : $self->{namespace_uri})
             => ($self->{local_name} || '*'),
             make_new_prefix => 1);
  warn $q->{reason} unless $q->{success};
  $q->{qname};
}

sub _is_same_class ($$) {
  my ($self, $something) = @_;
  eval q{$self->_CLASS_NAME eq $something->_CLASS_NAME} ? 1 : 0;
}

sub root_node ($) {
  my $self = shift;
  if (ref ($self->{parent}) && $self->_is_same_class ($self->{parent})) {
    return $self->{parent}->root_node;
  } else {
    return $self;
  }
}

sub _get_ns_decls_node ($) {
  my $self = shift;
  my $root = $self->root_node;
  if (ref $root->{parent}) {
    return $root->{parent}->_get_ns_decls_node;
  } elsif (ref $root) {
    return $root;
  } else {
    require Carp;
    Carp::carp 'expression holder node not specified';
    return {};
  }
}

sub stringify ($;%) {
  my ($self, %opt) = @_;
  my $r = '';
  if ($self->{type} eq '#step') {
    if ($self->{axis} ne '::root') {
      $r = $self->{axis} . '::' . ($self->qname || '*');
      $r .= $self->__stringify_predicts (\%opt);
    } else {  ## Root node selection
      $r = '/';
    }
  } elsif ($self->{type} eq '#path') {
    $r = join '/', grep {$_ ne '/'} map {
      my $v = $_->stringify;
      if ($_->{type} eq '#expression') {
        $v = '(' . $v . ')';
      }
      $v;
    } @{$self->{node}};
    $r = '/' . $r if $self->{node}->[0]->{type} eq '#step'
                  && $self->{node}->[0]->{axis} eq '::root';
    $r = '-' . $r if $self->{option}->{negated};
  } elsif ($self->{type} eq '#expression') {
    $r = join ' '.($self->{option}->{operator} || '+').' ',
              map {
                my $v = $_->stringify;
                if ($_->{type} eq '#expression') {
                  $v = '(' . $v . ')';
                }
                $v;
              } @{$self->{node}};
    my $predicts = $self->__stringify_predicts;
    $r = '(' . $r . ')' . $predicts if $predicts;
  } elsif ($self->{type} eq '#function') {
    if ($self->{namespace_uri} eq $NS{xpath}) {
      ## Strictly, these are not functions
      if ({qw/comment 1 text 1 processing-instruction 1 node 1/}
          ->{$self->{local_name}}) {
        $r = $self->{axis} . '::';
      }
    }
    $r .= $self->qname (use_context_function_library => 1)
       .  '(' . join (', ', map {$_->stringify} @{$self->{node}})
       .  ')';
    $r .= $self->__stringify_predicts;
  } elsif ($self->{type} eq '#literal') {
    my $v = '' . $self->{value}; # kill "live" object
    if (index ($v, "'") > -1) {
      my @v = split /"/, $v; # ";
      if (@v == 1) {
        $r = '"' . $v . '"';
      } else {
        $r = q<concat ("> . join (q<", '"', ">, @v) . q<")>;
      }
    } else { 
      $r = "'" . $v . "'";
    }
    $r .= $self->__stringify_predicts;
  } elsif ($self->{type} eq '#number') {
    if ($self->{value} =~ /^-?(?:[0-9]+(\.[0-9]*)?|\.[0-9]+)$/) {
      $r = $self->{value};
    } else {
      $r = '0';
    }
  }
  return $r;
}

sub __stringify_predicts ($$) {
  my ($self, $opt) = @_;
  my $r = '';
  for (@{$self->{predict}}) {
    $r .= '[' . $_->stringify . ']';
  }
  $r;
}

sub _CLASS_NAME { 'Message::Markup::XML::XPath' }

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

=back

=head1 NODE TYPES

=over 4 

=item #bare

Bare expression fragment.  This node type should not be used 
unless there is no other way.

=item #expression

An expression.

=item #fragment

Fragment of steps.  It's similar to DOM's fragment node.

=item #function

A function call.

=item #number

A number.

=item #path

A (location) path.

=item #step

A step or root node selection ("/").

=item #text

A literal.

=item #variable

A variable reference.

=cut

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/09/30 01:58:41 $
