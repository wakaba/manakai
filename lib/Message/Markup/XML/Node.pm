
=head1 NAME

Message::Markup::XML::Node --- manakai XML : XML Node Implementation

=head1 DESCRIPTION

This module implements the XML Node object.

This module is part of manakai XML.

=cut

package Message::Markup::XML::Node;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.6.2.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload
  '""'     => \&outer_xml,
  bool     => sub { 
                    #Carp::carp ('DEBUG: XML::Node is called in bool context'); 
                    1;
                  },
  fallback => 1;
use Char::Class::XML
  qw/InXML_NameStartChar InXMLNameChar InXML_NCNameStartChar InXMLNCNameChar/;
use Message::Markup::XML::QName
  qw/NULL_URI NS_xml_URI/;
require Carp;
use Exporter;
BEGIN {our @ISA = qw(Exporter);
our @EXPORT_OK = qw(NS_SGML NS_XML
                    SGML_ATTLIST SGML_DOCTYPE SGML_ELEMENT SGML_GENERAL_ENTITY
                    SGML_PARAM_ENTITY SGML_NOTATION
                    SGML_GROUP SGML_HEX_CHAR_REF SGML_NCR
                    XML_ATTLIST);
our %EXPORT_TAGS = (
  charref => [qw(SGML_NCR SGML_HEX_CHAR_REF)],
  declaration => [qw(SGML_ATTLIST SGML_DOCTYPE SGML_ELEMENT
                     SGML_GENERAL_ENTITY SGML_PARAM_ENTITY SGML_NOTATION)],
  entity  => [qw(SGML_GENERAL_ENTITY SGML_PARAM_ENTITY)],
);
}

sub NS_SGML () { q<urn:x-suika-fam-cx:markup:sgml:> }
sub NS_XML  () { q<urn:x-suika-fam-cx:markup:xml:> }
sub SGML_ATTLIST () { q<urn:x-suika-fam-cx:markup:sgml:attlist> }
sub XML_ATTLIST  () { q<urn:x-suika-fam-cx:markup:xml:attlist> }
sub SGML_DOCTYPE () { q<urn:x-suika-fam-cx:markup:sgml:doctype> }
sub SGML_ELEMENT () { q<urn:x-suika-fam-cx:markup:sgml:element> }
sub SGML_GENERAL_ENTITY () { q<urn:x-suika-fam-cx:markup:sgml:entity> }
sub SGML_PARAM_ENTITY () { q<urn:x-suika-fam-cx:markup:sgml:entity:parameter> }
sub SGML_NOTATION () { q<urn:x-suika-fam-cx:markup:sgml:notation> }
sub SGML_GROUP   () { q<urn:x-suika-fam-cx:markup:sgml:group> } 
sub SGML_HEX_CHAR_REF () { q<urn:x-suika-fam-cx:markup:sgml:char:ref:hex> }
sub SGML_NCR     () { q<urn:x-suika-fam-cx:markup:sgml:char:ref> }

=head1 METHODS

=over 4

=item $x = Message::Markup::XML::Node->new (%options)

Constructs an new node object.

Available options: C<data_type>, C<default_decl>, C<type> (default: C<#element>), C<local_name>, C<namespace_uri> and C<value>.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = {@_};
  unless ($self->{type}) {
    Carp::carp '{type} should be specified explicitly';
    $self->{type} = '#element';
  }
  $self = bless $self, __PACKAGE__ . '::' . substr ($self->{type}, 1);
  if ($self->{qname}) {
    my $q = Message::Markup::XML::QName::split_qname 
      ($self->{qname},
       check_qname => 1, check_local_name => 1, use_prefix_default => 1);
    if ($q->{success}) {
      $self->{namespace_prefix} = $q->{prefix};
      $self->{local_name} = $q->{local_name};
    } else {
      Carp::carp qq'new: "$self->{qname}": $q->{reason}';
    }
  }
  if ($self->{namespace_prefix}) {
    my $result = Message::Markup::XML::QName::register_prefix_to_name
        ($self->_get_ns_decls_node,
         $self->{namespace_prefix} => $self->{namespace_uri},
         use_prefix_default => 1, use_name_null => 1,
         check_xml => 1, check_xmlns => 1,
         check_registered_as_is => 1, ask_parent_node => 1);
    Carp::carp (qq(new: "$self->{namespace_prefix}": $result->{reason}))
      if $result->{reason};
  }
  if ($self->{type} eq '#element' or $self->{type} eq '#attribute') {
    $self->{namespace_uri} = NULL_URI
      unless defined $self->{namespace_uri} and length $self->{namespace_uri};
  }
  if (ref $self->{value} and index (ref $self->{value}, 'Markup::XML') > -1) {
    Carp::carp qq'new: Using type "@{[ref $self->{value}]}" object as {value} is deprecated';
  }
  $self->{node} = [];
  $self;
}

## Make a node object my child by setting child's {parent} property
sub __set_parent_node ($$) {
  my ($parent, $child) = @_;
  if (not ref $child) {
    ## 
  ## My family modules
  } elsif (substr (ref ($child), 0, 20) eq 'Message::Markup::XML') {
    $child->{parent} = $parent;
  ## Inheriting modules
  } elsif ($parent->_is_same_class ($child)) {
    $child->{parent} = $parent;
  ## Other incompatible modules
  }
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
  my ($new_node, %opt) = @_;
  unless (ref $new_node) {
    if ($opt{node_or_text}) {
      if ($opt{ignore_empty_string} and not length $new_node) {
        return undef;
      } else {
        return $self->append_text ($new_node);
      }
    } else {
      Carp::croak "append_node: Something other than node object is given";
    }
  }
  if ($new_node->{type} eq '#fragment') {
    for (@{$new_node->{node}}) {
      push @{$self->{node}}, $_;
      $_->{parent} = $self;
    }
    $new_node->{node} = [];
    $self;
  } else {
    ## Does not check whether $new_node has other parent node.
    ## Such check should be done by caller.
    push @{$self->{node}}, $new_node;
    $new_node->{parent} = $self;
    $new_node;
  }
}

=item $new_node = $x->append_new_node (%options)

Appending a new node.  The new node is returned.

Available options: C<type>, C<namespace_uri>, C<local_name>, C<value>.

=cut

sub append_new_node ($;%) {
  my $self = shift;
  my $new_node = ref ($self)->new (@_, parent => $self);
  push @{$self->{node}}, $new_node;
  $new_node;
}

=item $new_node = $x->append_text ($text)

Appends an text as a new text node child and returns it.

=cut

sub append_text ($$;%) {
  my $self = shift;
  my $new_node = ref ($self)->new (type => '#text', value => shift,
                                   parent => $self);
  push @{$self->{node}}, $new_node;
  $new_node;
}

=item $x->remove_child_node ($node)

Removes parent-and-child-relationship between $x and $node.

=cut

sub remove_child_node ($$;%) {
  my ($self, $node) = @_;
  return unless ref $node;
  my $node_str = overload::StrVal ($node);
  $self->{node} = [grep { overload::StrVal ($_) ne $node_str } @{$self->{node}}];
  delete $node->{parent};
  1;
}

=item $attr_node = $x->get_attribute ($local_name, %options)

Returns the attribute node whose local-name is C<$local_name>.

Available options: C<namespace_uri>, C<make_new_node>.

=cut

sub get_attribute ($$;%) {
  my ($self, $name, %opt) = @_;
  $opt{namespace_uri} ||= NULL_URI;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute'
    and $_->{local_name} eq $name) {
      if (defined $_->{namespace_uri}) {
        return $_ if $_->{namespace_uri} eq $opt{namespace_uri};
      } elsif ($opt{namespace_uri} eq NULL_URI) {
        return $_;
      }
    }
  }
  ## Node is not exist
  if ($opt{make_new_node}) {
    return $self->append_new_node (type => '#attribute', local_name => $name,
                                   namespace_uri => $opt{namespace_uri});
  } else {
    return undef;
  }
}

=item $string = $x->get_attribute_value ($name, %option)

Returnst the value (not node) of the attribute name is given.

Available options: C<namespace_uri>, C<make_new_node>, C<default>

=cut

sub get_attribute_value ($$;%) {
  my ($self, $name, %opt) = @_;
  my $node = $self->get_attribute ($name, %opt);
  if (ref $node) {
    return $node->inner_text;
  } else {
    return $opt{default};
  }
}

=item $attr_node = $x->set_attribute ($local_name => $value, %options)

Sets the value of the attribute.  The attribute node is returned.

Available options: C<namespace_uri>.

=cut

sub set_attribute ($$$;%) {
  my ($self, $name => $val, %opt) = @_;
  if ({qw/ARRAY 1 HASH 1 CODE 1/}->{ref $val}) {
    Carp::croak qq'set_attribute: "@{[ref $val]}": Attribute value must be string or blessed object';
  }
  $opt{namespace_uri} ||= NULL_URI;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute'
    and $_->{local_name} eq $name
    and $opt{namespace_uri} eq $_->{namespace_uri}) {
      $_->{value} = $val;
      $self->__set_parent_node ($val);
      for (@{$_->{node}}) {
        delete $_->{parent};
      }
      $_->{node} = [];
      return $_;
    }
  }
  return $self->append_new_node (type => '#attribute', local_name => $name,
                                 value => $val,
                                 namespace_uri => $opt{namespace_uri});
}

=item $x->remove_attribute ($local_name, %options)

Removes an attribute node.

Available options: C<namespace_uri>.

=cut

sub remove_attribute ($$;%) {
  my ($self, $name, %opt) = @_;
  $opt{namespace_uri} ||= NULL_URI;
  $self->{node} = [grep {
    if ($_->{type} eq '#attribute'
    and $_->{local_name} eq $name
    and $opt{namespace_uri} eq $_->{namespace_uri}) {
      delete $_->{parent};
      0;
    } else {
      1;
    }
  } @{$self->{node}}];
  1;
}

=item \@children = $x->child_nodes

Returns the reference to the array of children nodes.

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
  $self->{namespace_uri} = $new_uri if defined $new_uri;
  $self->{namespace_uri};
}
sub namespace_prefix ($;$%) {
  my ($self, $new_pfx, %opt) = @_;
  my $decls = $self->_get_ns_decls_node;
  if (defined ($new_pfx)) {
    my $result = Message::Markup::XML::QName::register_prefix_to_name
      ($decls, $new_pfx => $self->{namespace_uri}, ask_parent_node => 1,
       check_prefix => 1, check_xml => 1, check_xmlns => 1,
       check_prefix_xml_ => 1, check_registered_as_is => 1,
       use_prefix_default => 1, use_name_null => 1, %opt);
    Carp::carp $result->{reason} if $result->{reason};
  }
  my $result = Message::Markup::XML::QName::name_to_prefix
    ($decls, $self->{namespace_uri}, make_new_prefix => 1, 
     use_prefix_default => 1, use_name_null => 1,
     check_registered_as_is => 1, %opt);
  if ($result->{success}) {
    return $result->{prefix};
  } else {
    return undef;
  }
}

sub expanded_name ($) {
  my $self = shift;
  wantarray ? ($self->{namespace_uri}, $self->{local_name})
            : $self->{namespace_uri} . $self->{local_name};
}

=item $i = $x->count

Returns the number of children nodes.

=cut

sub count ($;@) {
  (defined $_[0]->{value} ? 1 : 0) + scalar @{$_[0]->{node}};
}

=item $x->define_new_namespace ($prefix => $uri)

Defines a new XML Namespace.  This method is useful for root or section-level
element node.

Returned value is unspecified in this version of this module.

=cut

sub define_new_namespace ($$$;%) {
  my ($self, $prefix, $uri, %opt) = @_;
  my $result = Message::Markup::XML::QName::register_prefix_to_name 
    ($self->_get_ns_decls_node, $prefix => $uri,
     check_name => 1, check_prefix => 1, check_xml => 1,
     check_xmlns => 1, check_prefix_xml_ => 1,
     use_prefix_default => 1, use_name_null => 1,
     %opt);
  Carp::carp $result->{reason} if $result->{reason};
  $result->{success};
}

=item $uri = $x->defined_namespace_prefix ($prefix)

Query whether the namespace prefix is defined or not.
If defined, return namespace name (URI).

=cut

sub defined_namespace_prefix ($$;%) {
  my ($self, $prefix, %opt) = @_;
  my $result = Message::Markup::XML::QName::prefix_to_name 
    ($self->_get_ns_decls_node, $prefix,
     use_prefix_default => 1, use_name_null => 1, 
     use_xml => 1, use_xmlns => 1,
     ask_parent_node => 1, %opt);
  $result->{name};
}

=item $qname = $x->qname

Returns QName ((namespace-)qualified name) of the element type.
Undef is retuened when the type does not have its QName
(ie. when type is neither C<#element> or C<#attribute>).

=cut

sub qname ($;%) {
  Carp::carp qq'qname: QName for type "@{[$_[0]->{type}]}" is not defined';
  undef;
}

=item $uri = $x->base_uri ([$new_uri])

Sets and/or gets the base URI of the node.

=cut

sub base_uri ($;$) {
  my ($self, $new_uri) = @_;
  my $base;
  if (defined $new_uri) {
    $base = $self->set_attribute (base => $new_uri, namespace_uri => NS_xml_URI);
  }
  $base ||= $self->get_attribute_value ('base', namespace_uri => NS_xml_URI,
                                        default => undef);
}

=item $tag = $x->start_tag

Returns the start tag (or something that marks the start of something, such as '<!--'
for C<#comment> nodes).

=item $tag = $x->end_tag

Returns the end tag (or something that marks the end of something, such as '-->'
for C<#comment> nodes).

=cut

sub start_tag ($;%) { '' }
sub end_tag ($;%) { '' }

=item $string = $x->attribute_name

Returns the attribute name.

=item $string = $x->attribute_value

Returns the attribute value specification.

=item $string = $x->attribute

Returns the attribute specification (name and value pair).

=item $string = $x->external_id

Returns public identifier and system identifier if any.

Available options: C<allow_pubid_only>, C<use_ndata>

=cut

sub attribute_name ($;%) { undef }
sub attribute_value ($;%) { undef }
sub attribute ($;%) { undef }

# entity_value : Obsoleted (See ::attribute->_entity_value)

sub external_id ($;%) { undef }

=item $tag = $x->inner_xml

Returns the content of the node in XML syntax.  (In case of the C<#element> nodes,
element content without start- and end-tags is returned.)

Note that for not all node types the behavior of this method is defined.
For example, returned value of C<#attribute> might be unexpected one
in this version of this module.

=cut

sub inner_xml ($;%) {
  my $self = shift;
  my $r = '';
  $r = $self->_escape ($self->{value}) if defined $self->{value};
  for (@{$self->{node}}) {
    $r .= $_->outer_xml unless $_->{type} eq '#attribute';
  }
  $r;
}

=item $tag = $x->outer_xml

Returns the node in XML syntax.

=cut

sub outer_xml ($;%) {
  my $self = shift;
  my $r = $self->start_tag . $self->inner_xml . $self->end_tag;
  $r;
  #return '{'.$self->{type}.': '.$r.'}';	## DEBUG: show structure
}

=item $tag = $x->inner_text

Returns the text content of the node.  (In many case the returned value is same
as WinIE DOM C<inner_text ()> function's or XPath C<text()> function's.
But some classes that inherits this module might implement to return other
value (eg. to return the value of the alt attribute of html:img element).

=cut

sub inner_text ($;%) {
  my ($self, %opt) = @_;
  my $r = '';
  $r = $self->{value} if defined $self->{value};
  for (@{$self->{node}}) {
    $r .= $_->inner_text unless $_->{type} eq '#attribute';
  }
  $r;
}

sub value ($;%) { shift->inner_text (@_) }

sub stringify ($;%) { shift->outer_xml (@_) }

## obsolete
sub _is_same_class ($$) {
  my ($self, $something) = @_;
  return 0 unless ref $something;
  return $something->isa (__PACKAGE__) ? 1 : 0;
}

sub _get_ns_decls_node ($;%) {
  my ($self, %opt) = @_;
  if ($self->{type} eq '#element') {
    return $self;
  } elsif (ref $self->{parent} and $self->{parent}->can ('_get_ns_decls_node')) {
    return $self->{parent}->_get_ns_decls_node;
  } elsif (exists $opt{default}) {
    return $opt{default};
  } else {
    Carp::carp qq(There is no namespace declarations node (type $self->{type}));
    return $opt{default} || {};
  }
}

# $s = $x->_escape ($s)
sub _escape ($$;%) {
  my ($self, $s, %opt) = (@_);
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  ## XML 1.0
  $s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F])/sprintf '&amp;#%d;', ord $1/ge;
  ## XML 1.1
  #$s =~ s/(\x00)/sprintf '&amp;#%d;', ord $1/ge;
  #$s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F])/sprintf '&#x%02X;', ord $1/ge;
  $s =~ s/([\x09\x0A\x0D])/sprintf '&#%d;', ord $1/ge if $opt{keep_wsp};
  $s;
}

{my %Cache;
# 1/0 = $x->_check_name ($s)
sub _check_name ($$;%) {
  my ($self, $s) = @_;
  return 0 unless defined $s;
  return $Cache{name}->{$s} if defined $Cache{name}->{$s};
  if ($s =~ /^\p{InXML_NameStartChar}/ && $s !~ /\P{InXMLNameChar}/) {
  # \p{...}('*'/'+'/'{n,}') does not work in some version of perl
    $Cache{name}->{$s} = 1;
    1;
  } else {
    $Cache{name}->{$s} = 0;
    0;
  }
}
# 1/0 = $x->_check_ncname ($s)
sub _check_ncname ($$;%) {
  my ($self, $s) = @_;
  return 0 unless defined $s;
  return $Cache{ncname}->{$s} if defined $Cache{ncname}->{$s};
  return $Cache{name}->{$s} if defined $Cache{name}->{$s};
  if ($s =~ /^\p{InXML_NCNameStartChar}/ && $s !~ /\P{InXMLNCNameChar}/) {
  # \p{...}('*'/'+'/'{n,}') does not work...
    $Cache{ncname}->{$s} = 1;
    $Cache{name}->{$s} = 1;
    1;
  } else {
    $Cache{ncname}->{$s} = 0;
    $Cache{name}->{$s} = 0;
    0;
  }
}
}

=item $value = $x->flag ($name [=> $value)

Gets or sets a flag of the node.

User of this module can use this flagging mechanism to remember
something related to the node.

=item $value = $x->option ($name [=> $value])

Gets or sets a flag of the node.

Available options : 

=over 4

=item use_EmptyElemTag => 0/1 (Default 0)

For #element node.  If content is exactly an empty string,
"EmptyElemTag" syntax (<name />) is used by ->outer_xml,
in place of start tag and end tag pair.

=back

=cut

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

## Per-node-type method definitions

package Message::Markup::XML::Node::attribute;
our @ISA = 'Message::Markup::XML::Node';
use Char::Class::XML qw/InXML_NameStartChar InXMLNameChar/;
use Message::Markup::XML::QName qw/NULL_URI/;
BEGIN {Message::Markup::XML::Node->import (qw(SGML_GENERAL_ENTITY))}

sub qname ($;%) {
  my ($self, %opt) = @_;
  my $result = Message::Markup::XML::QName::expanded_name_to_qname
    (
     (
      (defined $self->{namespace_uri} and $self->{namespace_uri} ne NULL_URI) ?
      $self->_get_ns_decls_node : undef
     ),
     $self->{namespace_uri}, $self->{local_name},
     make_new_prefix => 1, check_local_name => 1,
     use_xml => 1, use_xmlns => 1,
     use_prefix_default_null => 1,
     ask_parent_node => 1, %opt);
  Carp::carp $result->{reason} if $result->{reason};
  return $result->{qname};
}

sub attribute_name ($;%) { $_[0]->qname }

sub attribute_value ($;%) {
  my ($self) = @_;
  my $r = '"';
  
  ## {value}
  my $isc = 0;
  if (defined $self->{value}) {
    $isc = $self->_is_same_class ($self->{value});
    $r .= $self->_escape ($self->{value}, keep_wsp => 1) unless $isc;
  }
  for (($isc ? $self->{value} : ()), @{$self->{node}}) {
    my $nt = $_->{type};
    if ($nt eq '#reference' || $nt eq '#xml') {
      $r .= $_->outer_xml;
    } elsif ($nt ne '#attribute') {
      $r .= $self->_escape ($_->inner_text, keep_wsp => 1);
    }
  }
  return $r . '"';
}

sub attribute ($;%) {
  my $self = shift;
  $self->qname . '=' . $self->attribute_value;
}

## Returns EntityValue
sub _entity_value ($;%) {
  my ($self) = @_;
  my $_escape = sub {
    my $s = shift;
    $s =~ s/&/&#x26;/g;
    $s =~ s/&#x26;(\p{InXML_NameStartChar}\p{InXMLNameChar}*);/&$1;/g;
    $s =~ s/([\x0D%"])/sprintf '&#x%02X;', ord $1/ge;
    $s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F\x7F])/sprintf '&amp;#x%02X;', ord $1/ge;
    $s;
  };
  my $r = '';
  if (defined $self->{value}) {
    $r .= $_escape->($self->{value});
  }
  for (@{$self->{node}}) {
    my $nt = $_->{type};
    if ($nt eq '#reference' or $nt eq '#xml') {
      $r .= $_->outer_xml;
    } elsif ($nt ne '#attribute') {
      $r .= $_escape->($_->inner_text);
    }
  }
  '"' . $r . '"';
}

## This method should be called only from Message::Markup::XML::* family modules,
## since this is NOT a FORMAL interface.
sub _entity_parameter_literal_value ($;%) {
  my $self = shift;
  my $r = '';
  my $isc = 0;
  if (defined $self->{value}) {
    $isc = $self->_is_same_class ($self->{value});
    $r .= $self->{value} unless $isc;
  }
  for (($isc ? $self->{value} : ()), @{$self->{node}}) {
    my $nt = $_->{type};
    ## Bare node and general entity reference node
    if ($nt eq '#xml'
    or ($nt eq '#reference' and $_->{namespace_uri} eq SGML_GENERAL_ENTITY)) {
      $r .= $_->outer_xml;
    ## Text node and parameter entity reference node
    } elsif ($nt ne '#attribute') {
      $r .= $_->inner_text;
    }
  }
  $r;
}

sub inner_xml ($;%) {
  Carp::carp 'inner_xml: Currently inner_xml of #attribute is not defined';
}

sub outer_xml ($;%) {
  $_[0]->attribute;
}

package Message::Markup::XML::Node::comment;
our @ISA = 'Message::Markup::XML::Node';

sub start_tag ($;%) { '<!--' }
sub end_tag ($;%) { '-->' }

sub inner_xml ($;%) {
  my $self = shift;
  my $r = $self->inner_text;
  $r =~ s/--/-&#45;/g;
  $r =~ s/-$/&#45;/;
  $r;
}

package Message::Markup::XML::Node::declaration;
our @ISA = 'Message::Markup::XML::Node';
use Message::Markup::XML::QName qw/NULL_URI/;
BEGIN {Message::Markup::XML::Node->import 
         (qw(SGML_ATTLIST SGML_ELEMENT
             SGML_GENERAL_ENTITY SGML_PARAM_ENTITY
             SGML_NOTATION SGML_DOCTYPE
             SGML_GROUP XML_ATTLIST))}

sub qname ($;%) {
  my ($self) = @_;
  $self->get_attribute_value ('qname', default => undef);
}

sub start_tag ($;%) {
  my $self = shift;
  if ($self->{namespace_uri} eq SGML_PARAM_ENTITY
      and $self->{flag}->{smxp__defined_with_param_ref}) {
    '<!ENTITY ';
  } else {
    '<!' . {
            (SGML_ATTLIST)          => 'ATTLIST',
            (SGML_DOCTYPE)          => 'DOCTYPE',
            (SGML_ELEMENT)          => 'ELEMENT',
            (SGML_GENERAL_ENTITY)   => 'ENTITY',
            (SGML_PARAM_ENTITY)     => 'ENTITY %',
            (SGML_NOTATION)         => 'NOTATION',
           }->{$self->{namespace_uri}} . ' ';
  }
}

sub end_tag ($;%) { '>' }

sub external_id ($;%) {
  my ($self, %opt) = @_;
  my ($pubid, $sysid, $ndata);
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute' and $_->{namespace_uri} eq NULL_URI) {
      if ($_->{local_name} eq 'PUBLIC') {
        $pubid = $_->inner_text;
      } elsif ($_->{local_name} eq 'SYSTEM') {
        $sysid = $_->inner_text;
      } elsif ($_->{local_name} eq 'NDATA') { # Notation
        $ndata = $_->inner_text;
        #undef $ndata unless $self->_check_ncname ($ndata);
      }
    }
  }
  
  my $r = '';
  if (defined $pubid) {
    $pubid =~ s|([^\x0A\x0D\x20A-Za-z0-9'()+,./:=?;!*#\@\$_%-])|
                sprintf '%%%02X', ord $1|ges;
    $pubid = '"' . $pubid . '"';
  }
  if (defined $sysid) {
    if (index ($sysid, '"') > -1) {
      if (index ($sysid, "'") > -1) {
        $sysid =~ s/"/%22/; $sysid = '"' . $sysid . '"';
      } else {
        $sysid = "'" . $sysid . "'";
      }
    } else {
      $sysid = '"' . $sysid . '"';
    }
  }
  
  if ($pubid and $sysid) {
    $r = 'PUBLIC ' . $pubid . ' ' . $sysid;
  } elsif ($sysid) {
    $r = 'SYSTEM ' . $sysid;
  } elsif ($pubid and $opt{allow_pubid_only}) {
    $r = 'PUBLIC ' . $pubid;
  }
  if ($r and $ndata and $opt{use_ndata}) {
    $r .= ' NDATA ' . $ndata;
  }
  $r;
}

sub inner_xml ($;%) {
  my $self = shift;
  ## DOCTYPE declaration
  if ($self->{namespace_uri} eq SGML_DOCTYPE) {
    my $root = $self->get_attribute_value ('qname', default => undef);
    if (not $root and ref $self->{parent}) {
      for (@{$self->{parent}->{node}}) {
        if ($_->{type} eq '#element') {
          $root = $_->qname;
          last;
        }
      }
    }
    Carp::carp 'inner_xml: Document type name unknown' unless $root;
    
    my ($isub, $xid) = ('', $self->external_id);
    for (@{$self->{node}}) {
      if ($_->{type} eq '#element' and
          $_->{namespace_uri} eq SGML_DOCTYPE and
          $_->{local_name} eq 'subset') {
        $isub .= $_->inner_xml;
        last;
      }
    }
    my $r;
    if ($xid) {
      $r = $xid;
      $r .= " [" . $isub . "]" if $isub;
    } else {
      $r = "[" . $isub . "]";
    }
    return $root . ' ' . $r;
  } else { # ATTLIST / ELEMENT / ENTITY / NOTATION
    my $r = '';
    if ($self->{namespace_uri} eq SGML_GENERAL_ENTITY
          || $self->{namespace_uri} eq SGML_PARAM_ENTITY
          || $self->{namespace_uri} eq SGML_NOTATION) {
      my %xid_opt;
      $r = $self->{local_name} . ' ' if !$self->{flag}->{smxp__defined_with_param_ref}
                                        && $self->_check_ncname ($self->{local_name});
      if ($self->{namespace_uri} eq SGML_PARAM_ENTITY) {
        #$r = '% ' . $r;
      } elsif ($self->{namespace_uri} eq SGML_GENERAL_ENTITY) {
        $xid_opt{use_ndata} = 1;
      } elsif ($self->{namespace_uri} eq SGML_NOTATION) {
        $xid_opt{allow_pubid_only} = 1;
      }
      
      my $xid;
      $xid = $self->external_id (%xid_opt)
        unless $self->{flag}->{smxp__defined_with_param_ref};
      if ($xid) {	## External ID
        $r .= $xid;
      } else {	## EntityValue
        my $entity_value;
        $entity_value = $self->get_attribute ('value')
          unless $self->{flag}->{smxp__defined_with_param_ref};
        if (ref $entity_value) {	# <!ENTITY foo "bar">
          $r .= $entity_value->_entity_value;
        } else {	## Consist of parameters
          my $params = '';
          Carp::carp qq({value} property ("$self->{value}") is not allowed for this type of node)
              if defined $self->{value};
          for (@{$self->{node}}) {
            $params .= $_->outer_xml unless $_->{type} eq '#attribute';
          }
          $r .= length $params ? $params : '""';
        }
      }
    } elsif ($self->{namespace_uri} eq SGML_ELEMENT) {
      $r = $self->get_attribute_value ('qname')
        unless $self->{flag}->{smxp__defined_with_param_ref};
      if ($r) {
        unless ($self->_check_name ($r)) {
          Carp::carp qq'"$r": QName expected';
          $r = '';
        } else {
          $r .= ' ';
        }
        
        my $cmodel = $self->get_attribute_value ('content', default => 'EMPTY');
        if ($cmodel ne 'mixed' and $cmodel ne 'element') {
          $r .= $cmodel;
        } else {  # element content or mixed content
          my $make_cmodel;
          $make_cmodel = sub {
            my $c = shift;
            my @tt;
            for (@{$c->child_nodes}) {
              if ($_->node_type eq '#element'
              and $_->namespace_uri eq SGML_ELEMENT) {
                if ($_->local_name eq 'group') {
                  my $tt = &$make_cmodel ($_);
                  push @tt, '(' . $tt . ')'         # [sic]
                     . $_->get_attribute_value ('occurence', default => '')
                    if $tt;
                } elsif ($_->local_name eq 'element') {
                  push @tt, $_->get_attribute_value ('qname')
                     . $_->get_attribute_value ('occurence', default => '');
                }                                   # [sic]
              }
            }
            return join scalar ($c->get_attribute_value ('connector')
                                || '|'),
                   grep {$_} @tt;
          };
          my $tt;
          my $grp_node;
          for (@{$self->{node}}) {
            if ($_->node_type eq '#element'
            and $_->namespace_uri eq SGML_ELEMENT
            and $_->local_name eq 'group') {
              $grp_node = $_;
              $tt = &$make_cmodel ($grp_node);
              last;
            }
          }
          if ($cmodel eq 'mixed') {	## mixed content
            if ($tt) {
              $r .= '(#PCDATA|' . $tt . ')*';
            } else {
              $r .= '(#PCDATA)'                       # [sic]
                  . ($grp_node->get_attribute_value ('occurence', default => '')
                     eq '*'
                     ? '*' : '');
            }
          } else {	## element content
            if ($tt) {
              $r .= '(' . $tt . ')'                   # [sic]
                  . $grp_node->get_attribute_value ('occurence', default => '');
            } else { ## Error
              $r .= 'EMPTY';
            }
          }	# mixed or element content
        }	# content model group
      } else {	## Save source doc's description as far as possible
          my $isc = $self->_is_same_class ($self->{value});
          $r .= $self->{value} if defined $self->{value} and !$isc;
          for (($isc?$self->{value}:()), @{$self->{node}}) {
            unless ($_->{type} eq '#attribute' || $_->{type} eq '#element') {
              $r .= $_->outer_xml;
            } elsif ($_->{type} eq '#element'
                 and $_->{namespace_uri} eq SGML_GROUP) {
              $r .= $_->outer_xml;
            }
          }
      }
    } elsif ($self->{namespace_uri} eq SGML_ATTLIST) {
      $r = $self->get_attribute_value ('qname')
        unless $self->{flag}->{smxp__defined_with_param_ref};
      if ($r) {
        unless ($self->_check_name ($r)) {
          Carp::carp qq'inner_xml: "$r": QName expected';
          $r = '';
        }
        for (@{$self->{node}}) {
          if ($_->{type} eq '#element'
          and $_->{namespace_uri} eq XML_ATTLIST
          and $_->{local_name} eq 'AttDef') {
            $r .= "\n\t" . $_->get_attribute_value ('qname');
            my $attr_type = $_->get_attribute_value ('type', default => 'CDATA');
            if ($attr_type ne 'enum') {
              $r .= "\t" . $attr_type;
            }
            if ($attr_type eq 'enum' or $attr_type eq 'NOTATION') {
              my @l;
              for my $item (@{$_->{node}}) {
                if ($item->{type} eq '#element'
                and $item->{namespace_uri} eq XML_ATTLIST
                and $item->{local_name} eq 'enum') {
                  push @l, $item->inner_text;
                }
              }
              $r .= "\t(" . join ('|', @l) . ')';
            }
            ## DefaultDecl -- Keyword
            my $deftype = $_->get_attribute_value ('default_type');
            if ($deftype) {
              $r .= "\t#" . $deftype;
            }
            ## DefaultDecl -- Attribute value specification
            if (not $deftype or $deftype eq 'FIXED') {
              $r .= "\t" 
                 . $_->get_attribute ('default_value', make_new_node => 1)
                     ->attribute_value;
            }
          }	# AttDef
        }
      } else {	## Save source doc's description as far as possible
        Carp::carp '{value} should not be used here' if defined $self->{value};
        for (@{$self->{node}}) {
          unless ($_->{type} eq '#attribute' || $_->{type} eq '#element') {
            $r .= $_->outer_xml;
          } elsif ($_->{type} eq '#element'
               and $_->{namespace_uri} eq SGML_GROUP) {
            $r .= $_->outer_xml;
          }
        }
      }
    } else {	# unknown declaration
      Carp::carp qq'Unsupported type (<$self->{namespace_uri}>) of markup declaration';
      for (@{$self->{node}}) {
        $r .= $_->outer_xml;
      }
    }
    $r;
  }
}

sub inner_text ($;%) {
  my ($self, %opt) = @_;
  if (   $self->{namespace_uri} eq SGML_GENERAL_ENTITY
      or $self->{namespace_uri} eq SGML_PARAM_ENTITY) {
    return $self->get_attribute_value ('value', default => '');
    ## Note: If parameter reference is not resolved, empty string is returned.
  } elsif ($self->{namespace_uri} eq SGML_DOCTYPE) {
    return $self->SUPER::inner_text (%opt);
  } else {
    return '';
  }
}

package Message::Markup::XML::Node::document;
our @ISA = 'Message::Markup::XML::Node';

package Message::Markup::XML::Node::element;
our @ISA = 'Message::Markup::XML::Node';
use Message::Markup::XML::QName qw/DEFAULT_PFX NULL_URI/;

sub qname ($;%) {
  my ($self, %opt) = @_;
  my $result = Message::Markup::XML::QName::expanded_name_to_qname
    ($self, $self->{namespace_uri}, $self->{local_name},
     make_new_prefix => 1, check_local_name => 1,
     use_prefix_default => 1, use_name_null => 1,
     use_xml => 1, use_xmlns => 1,
     ask_parent_node => 1, %opt);
  Carp::carp $result->{reason} if $result->{reason};
  return $result->{qname};
}

sub start_tag ($;%) {
  my $self = shift;
  my $r = '';
  $self->qname; # dummy to register namespace prefix
  ## Attribute specifications for attribute nodes
  for (@{$self->{node}}) {
    $r .= ' ' . $_->outer_xml if $_->{type} eq '#attribute';
  }
  ## Attribute specifications for namespace nodes
  for my $prefix (sort keys %{$self->{ns}||{}}) {
    $r .= ' xmlns';
    $r .= ':'.$prefix unless $prefix eq DEFAULT_PFX;
    $r .= '="';
    $r .= $self->_escape ($self->{ns}->{$prefix})
      if $self->{ns}->{$prefix} ne NULL_URI;
    $r .= '"';
  }
  '<' . $self->qname . $r . '>';
}

sub end_tag ($;%) {
  my $self = shift;
  '</' . $self->qname . '>';
}

sub outer_xml ($;%) {
  my $self = shift;
  $self->qname; ## Register undeclared namespace
  my $c = $self->inner_xml;
  my $r = $self->start_tag;
  if ($self->{option}->{use_EmptyElemTag} and not length $c) {
    substr ($r, -1) = ' />';
  } else {
    $r .= $c . $self->end_tag;
  }
  return $r;
  #return '{'.$self->{type}.': '.$r.'}';	## DEBUG: show structure
}

package Message::Markup::XML::Node::fragment;
our @ISA = 'Message::Markup::XML::Node';

package Message::Markup::XML::Node::pi;
our @ISA = 'Message::Markup::XML::Node';

sub start_tag ($;%) {
  my $self = shift;
  '<?' . $self->{local_name};
}

sub end_tag ($;%) { '?>' }

sub inner_xml ($;%) {
  my $self = shift;
  ## Target data
  my $data = '';
  my $isc = 0;
  if (defined $self->{value}) {
    $isc = $self->_is_same_class ($self->{value});
    $data = $self->{value} unless $isc;
    if (length $data) {
      $data =~ s/\?>/?&gt;/g;
      $data = ' ' . $data;
    }
  }
  
  for (($isc?$self->{value}:()), @{$self->{node}}) {
    if ($_->{type} eq '#attribute') {
      $data .= ' ' . $_->attribute;
    } else {
      my $s = $_->inner_text;
      if (length $s) {
        $s =~ s/\?>/?&gt;/g;
        $data .= ' ' . $s;
      }
    }
  }
  $data;
}

package Message::Markup::XML::Node::reference;
our @ISA = 'Message::Markup::XML::Node';
BEGIN {Message::Markup::XML::Node->import
        (qw(:charref :entity))}

sub start_tag ($;%) {
  my $self = shift;
  +{
    (SGML_GENERAL_ENTITY) => '&',
    (SGML_PARAM_ENTITY)   => '%',
    (SGML_NCR)            => '&#',
    (SGML_HEX_CHAR_REF)   => '&#x',
  }->{$self->{namespace_uri}}
    or
  Carp::carp qq'start_tag: <@{[$self->{namespace_uri}]}>: Unsupported type of #reference';
}

sub end_tag ($;%) { ';' }

sub inner_xml ($;%) {
  my $self = shift;
  if ($self->{namespace_uri} eq SGML_HEX_CHAR_REF) {
    return sprintf '%02X', $self->{value};
  } elsif ($self->{namespace_uri} eq SGML_NCR) {
    return sprintf '%02d', $self->{value};
  } else {  ## Entity reference
    return $self->{local_name};
  }
}

sub inner_text ($;%) {
  my ($self, %opt) = @_;
  if (   $self->{namespace_uri} eq SGML_NCR
      or $self->{namespace_uri} eq SGML_HEX_CHAR_REF) {
    return chr $self->{value};
  } else { # Entity reference
    return $self->SUPER::inner_text (%opt);
    ## Note that when reference is not resolved, empty string is returned.
  }
}

sub value ($;%) { inner_text (@_) }

package Message::Markup::XML::Node::section;
our @ISA = 'Message::Markup::XML::Node';

sub start_tag ($;%) { '<![' }
sub end_tag ($;%) { ']]>' }

sub inner_xml ($;%) {
  my $self = shift;
  my $status = $self->get_attribute_value ('status', default => '');
  if ($status eq 'CDATA') {
    my $r = $self->inner_text;
    $r =~ s/]]>/]]>]]<![CDATA[>/g;
    return 'CDATA['.$r;
  } else { # INCLUDE or IGNORE
    my $r;
    ## Status keyword and dso
    my $sl = $self->get_attribute ('status_list', make_new_node => 1);
    if ($sl->{flag}->{smxp__defined_with_param_ref}) {
      my $isc = $self->_is_same_class ($self->{value});
      $status = (defined $sl->{value} and !$isc) ? $sl->{value} : '';
      for (($isc?$sl->{value}:()), @{$sl->{node}}) {
        $status .= $_->outer_xml unless $_->{type} eq '#attribute';
      }
      $r = $status.'[';
    } elsif ($status) {
      $r = $status.'[';
    } else {
      ## Must be an ignore*d* section
      $r = '[';
    }
    ## Content
    if (defined $self->{value}) {
      my $s = $self->{value};
      $s =~ s/\]\]>/]]&gt;/g;
      $r .= $s;
    }
    for (@{$self->{node}}) {
      if ($_->{type} eq '#text') {
        my $s = $_->inner_text;
        $s =~ s/\]\]>/]]&gt;/g;
        $r .= $s;  ## But this will be non well-formed.
      } elsif ($_->{type} ne '#attribute') {
        $r .= $_->outer_xml;
      }
    }
    $r;
  }
}

package Message::Markup::XML::Node::text;
our @ISA = 'Message::Markup::XML::Node';

package Message::Markup::XML::Node::xml;
our @ISA = 'Message::Markup::XML::Node';

sub inner_xml ($;%) {
  my $self = shift;
  my $r = '';
  my $isc = 0;
  if (defined $self->{value}) {
    $isc = $self->_is_same_class ($self->{value});
    $r = $self->{value} unless $isc;
  }
  for (($isc?$self->{value}:()), @{$self->{node}}) {
    $r .= $_->outer_xml unless $_->{type} eq '#attribute';
  }
  $r;
}

=back

=head1 NODE TYPES

=over 4 

=item #attribute

Attribute.  Its XML representation takes the form of NAME="VALUE".

=item #comment

Comment declarement. <!-- -->

=item #declaration

XML's declarations, such as DOCTYPE, ENTITY, etc.
<!DOCTYPE root []>, <!ENTITY % name "value">

=item #element

Element.  Its XML representation consists of start tag, content and end tag,
like <TYPE>content</TYPE>.

=item #fragment

Fragment of nodes.  It's similar to DOM's fragment node.

=item #pi

Prosessing instruction. <?NAME VALUE?>

=item #reference

Character reference or general or parameter entity reference.
&#nnnn;, &#xhhhh;, &name;, %name;.

=item #section

Markup section.  CDATA, INCLUDE and IGNORE are supported by XML.
<![%type;[...]]>

=item #text

Text.

=item #xml

Preformatted XML text.

Warning: Value of #xml is unchecked in any case, even if bare delimiter
character is involved.

=cut

=head1 EXAMPLE

  use Message::Markup::XML::Node;
  my $node = Message::Markup::XML::Node->new
               (type => '#element',
                namespace_uri => q<http://something.example/namespace>,
                local_name => 'element-type');
  $node->set_attribute (something => 'cool');
  $node->append_text ('Love & Peace');
  
  print $node->outer_xml;
    # <namespace:element-type something="cool"
    # xmlns:namespace="http://something.example/namespace">
    # Love & Peace</namespace:element-type>
    # (in one line)

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/07/30 09:37:50 $
