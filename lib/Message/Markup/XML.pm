
=head1 NAME

Message::Markup::XML --- manakai: Simple well-formed document fragment generator

=head1 DESCRIPTION

This module can be used to generate the document fragment of XML, SGML or
other well-formed (in XML meaning) data formats with the object oriented manner.

This module cannot be used to parse XML (or other marked-up) document (or its fragment)
by itself, nor is compatible with other huge packages such as XML::Parser.  The only purpose
of this module is to make it easy for tiny perl scripts to GENERATE well-formed
markup constructures.  (SuikaWiki is not "tiny"?  Oh, yes, I see:-))

=cut

package Message::Markup::XML;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.28 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload '""' => \&outer_xml,
             fallback => 1;
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar InXML_NCNameStartChar InXMLNCNameChar!;
use Message::Markup::XML::QName qw:NULL_URI UNDEF_URI DEFAULT_PFX:;
require Carp;
Carp::carp "Obsoleted module Message::Markup::XML loaded";

our %Namespace_URI_to_prefix = (
	'DAV:'	=> [qw/dav webdav/],
	'http://greenbytes.de/2002/rfcedit'	=> [qw/ed/],
	'http://icl.com/saxon'	=> [qw/saxon/],
	'http://members.jcom.home.ne.jp/jintrick/2003/02/site-concept.xml#'	=> ['', qw/sitemap/],
	'http://purl.org/dc/elements/1.1/'	=> [qw/dc dc11/],
	'http://purl.org/rss/1.0/'	=> ['', qw/rss rss10/],
	'http://suika.fam.cx/~wakaba/lang/rfc/translation/'	=> [qw/ja/],
	'http://www.mozilla.org/xbl'	=> ['', qw/xbl/],
	'http://www.w3.org/1999/02/22-rdf-syntax-ns#'	=> [qw/rdf/],
	'http://www.w3.org/1999/xhtml'	=> ['', qw/h h1 xhtml xhtml1/],
	'http://www.w3.org/1999/xlink'	=> [qw/l xlink/],
	'http://www.w3.org/1999/XSL/Format'	=> [qw/fo xslfo xsl-fo xsl/],
	'http://www.w3.org/1999/XSL/Transform'	=> [qw/t s xslt xsl/],
	'http://www.w3.org/1999/XSL/TransformAlias'	=> [qw/axslt axsl xslt xsl/],
	'http://www.w3.org/2000/01/rdf-schema#'	=> [qw/rdfs/],
	'http://www.w3.org/2000/svg'	=> ['', qw/s svg/],
	'http://www.w3.org/2002/06/hlink'	=> [qw/h hlink/],
	'http://www.w3.org/2002/06/xhtml2'	=> ['', qw/h h2 xhtml xhtml2/],
	'http://www.w3.org/2002/07/owl'	=> [qw/owl/],
	'http://www.w3.org/2002/xforms/cr'	=> [qw/f xforms/],
	'http://www.w3.org/TR/REC-smil'	=> ['', qw/smil smil1/],
	'http://www.wapforum.org/2001/wml'	=> [qw/wap/],
	'http://xml.apache.org/xalan'	=> [qw/xalan/],
	'mailto:julian.reschke@greenbytes.de?subject=rcf2629.xslt'	=> [qw/myns/],
	'urn:schemas-microsoft-com:vml'	=> [qw/v vml/],
	'urn:schemas-microsoft-com:xslt'	=> [qw/ms msxsl msxslt/],
	'urn:x-suika-fam-cx:markup:ietf:html:3:draft:00'	=> ['', qw/H HTML HTML3/],
	'urn:x-suika-fam-cx:markup:ietf:rfc:2629'	=> ['', qw/rfc rfc2629/],
);
my %Cache;
our %NS = (
	SGML	=> 'urn:x-suika-fam-cx:markup:sgml:',
	XML	=> 'urn:x-suika-fam-cx:markup:xml:',
        default_base_uri => q<about:unknown>,
	internal_attr_duplicate	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/invalid-attr#',
	internal_invalid_sysid	=> 'http://system.identifier.invalid/',
	internal_ns_invalid	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#',
	xml	=> 'http://www.w3.org/XML/1998/namespace',
	xmlns	=> 'http://www.w3.org/2000/xmlns/',
);

=head1 METHODS

=over 4

=item $x = Message::Markup::XML->new (%options)

Returns new instance of the module.  It is itself a node.

Available options: C<data_type>, C<default_decl>, C<type> (default: C<#element>), C<local_name>, C<namespace_uri> and C<value>.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->{type} ||= '#element';
  ## Use of "qname" parameter is deprecated
  if ($self->{qname}) {
    my $q = Message::Markup::XML::QName::split_qname 
      ($self->{qname},
       check_qname => 1,
       check_local_name => 1,
       use_prefix_default => 1);
    if ($q->{success}) {
      $self->{namespace_prefix} = $q->{prefix};
      $self->{local_name} = $q->{local_name};
    }
  }
  if (defined $self->{namespace_prefix}) {
    my $result = Message::Markup::XML::QName::register_prefix_to_name
        ($self->_get_ns_decls_node,
         $self->{namespace_prefix} => $self->{namespace_uri},
         use_prefix_default => 1, use_name_null => 1,
         check_xml => 1, check_xmlns => 1,
         check_registered_as_is => 1, ask_parent_node => 1);
    Carp::carp $result->{reason} if $result->{reason};
  }
  for (qw/local_name value/) {
    $self->__set_parent_node ($self->{$_});
  }
  $self->{node} = [];
  $self;
}

sub __set_parent_node ($$) {
  my ($parent, $child) = @_;
  if (!ref $child) {
    ## 
  } elsif (substr (ref ($child), 0, 20) eq 'Message::Markup::XML') {
    $child->{parent} = $parent;
  } elsif (ref ($child) && $parent->_is_same_class ($child)) {
    $child->{parent} = $parent;
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

Available options: C<type>, C<namespace_uri>, C<local_name>, C<value>.

=cut

sub append_new_node ($;%) {
  my $self = shift;
  my $new_node = ref ($self)->new (@_, parent => $self);
  push @{$self->{node}}, $new_node;
  $new_node;
}

=item $new_node = $x->append_text ($text)

Appending given text as a new text node.  The new text node is returned.

=cut

sub append_text ($$;%) {
  $_[0]->append_new_node (type => '#text', value => $_[1]);
}

## Non public interface
sub append_baretext ($$;%) {
  $_[0]->append_new_node (type => '#xml', value => $_[1]);
}

sub remove_child_node ($$) {
  my ($self, $node) = @_;
  return unless ref $node;
  $node = overload::StrVal ($node);
  $self->{node} = [grep { overload::StrVal ($_) ne $node } @{$self->{node}}];
}

=item $attr_node = $x->get_attribute ($local_name, %options)

Returns the attribute node whose local-name is C<$local_name>.

Available options: C<namespace_uri>, C<make_new_node>.

=cut

sub get_attribute ($$;%) {
  my ($self, $name, %o) = @_;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute'
    and $_->{local_name} eq $name) {
      if (defined $o{namespace_uri}) {
        if (defined $_->{namespace_uri}) {
          return $_ if $_->{namespace_uri} eq $o{namespace_uri};
        } elsif ($o{namespace_uri} eq NULL_URI) {
          return $_;
        }
      } else {
        return $_ if ((not defined $_->{namespace_uri})
                   or ($_->{namespace_uri} eq NULL_URI))
      }
    }
  }
  ## Node is not exist
  if ($o{make_new_node}) {
    return $self->append_new_node (type => '#attribute', local_name => $name,
                                   namespace_uri => $o{namespace_uri});
  } else {
    return undef;
  }
}

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

Set the value of the attribute.  The attribute node is returned.

Available options: C<namespace_uri>.

=cut

sub set_attribute ($$$;%) {
  my ($self, $name, $val, %o) = @_;
  if ({qw/ARRAY 1 HASH 1 CODE 1/}->{ref ($val)}) {
    die "set_attribute: new attribute value must be string or blessed object";
    #return undef;
  }
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute'
     && $_->{local_name} eq $name
     && $o{namespace_uri} eq $_->{namespace_uri}) {
      $_->{value} = $val;
      $self->__set_parent_node ($val);
      $_->{node} = [];
      return $_;
    }
  }
  return $self->append_new_node (type => '#attribute', local_name => $name,
                                 value => $val, namespace_uri => $o{namespace_uri});
}

=item $attr_node = $x->remove_attribute ($local_name, %options)

Remove the attribute.

Available options: C<namespace_uri>.

=cut

sub remove_attribute ($$;%) {
  my ($self, $name, %o) = @_;
  $self->{node} = [grep {
    if ($_->{type} eq '#attribute'
     && $_->{local_name} eq $name
     && $o{namespace_uri} eq $_->{namespace_uri}) {
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
  if (ref $self->{local_name} && $self->{local_name}->{type} eq '#declaration') {
    $self->{local_name}->{local_name};
  } else {
    $self->{local_name}
  }
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

Returns the number of child nodes.

=cut

# TODO: support counting by type
sub count ($;@) {
  (defined $_[0]->{value} ? 1 : 0) + scalar @{$_[0]->{node}};
}

# $prefix = $x->_get_namespace_prefix ($namespace_uri)
sub _get_namespace_prefix ($$;%) {
}

sub _set_prefix_to_uri ($$$;%) {
}

## TODO: removing ns declare (1.1) support
# $uri or undef = $x->_prefix_to_uri ($prefix)
sub _prefix_to_uri ($$;$%) {
}

# $prefix or undef = $x->_uri_to_prefix ($uri => [$new_prefix], %options)
# use_no_prefix (default: 1): Allow default namespace (no prefix).
sub _uri_to_prefix ($$;$%) {
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
  my ($self, %opt) = @_;
  if ($self->{type} eq '#element') {
    my $result = Message::Markup::XML::QName::expanded_name_to_qname
                   ($self, $self->{namespace_uri} || NULL_URI,
                    $self->{local_name},
                    make_new_prefix => 1, check_local_name => 1,
                    use_prefix_default => 1, use_name_null => 1,
                    use_xml => 1, use_xmlns => 1,
                    ask_parent_node => 1, %opt);
    Carp::carp $result->{reason} if $result->{reason};
    return $result->{qname};
  } elsif ($self->{type} eq '#attribute') {
    my $result = Message::Markup::XML::QName::expanded_name_to_qname
                   (((defined $self->{namespace_uri}
                      and $self->{namespace_uri} ne NULL_URI) ?
                       $self->_get_ns_decls_node : undef),
                    $self->{namespace_uri} || NULL_URI, $self->{local_name},
                    make_new_prefix => 1, check_local_name => 1,
                    use_xml => 1, use_xmlns => 1,
                    ask_parent_node => 1, %opt);
    Carp::carp $result->{reason} if $result->{reason};
    return $result->{qname};
  } else {
    return $self->{qname};
  }
}

sub merge_external_subset ($) {
  my $self = shift;
  unless ($self->{type} eq '#declaration'
       && $self->{namespace_uri} eq $NS{SGML}.'doctype') {
    return unless $self->{type} eq '#document' || $self->{type} eq '#fragment';
    for (@{$self->{node}}) {
      $_->merge_external_subset;
    }
    return;
  }
  my $xsub = $self->get_attribute ('external-subset');
  return unless ref $xsub;
  for (@{$xsub->{node}}) {
    $_->{parent} = $self;
  }
  push @{$self->{node}}, @{$xsub->{node}};
  $self->remove_child_node ($xsub);
  $self->remove_child_node ($self->get_attribute ('PUBLIC'));
  $self->remove_child_node ($self->get_attribute ('SYSTEM'));
  $self->remove_marked_section;
}

sub remove_marked_section ($) {
  my $self = shift;
  my @node;
  for (@{$self->{node}}) {
    if ({'#declaration' => 1, '#element' => 1, '#section' => 1,
         '#reference' => 1, '#attribute' => 1,
         '#document' => 1, '#fragment' => 1}->{$_->{type}}) {
      $_->remove_marked_section;
    }
  }
  for (@{$self->{node}}) {
    if ($_->{type} ne '#section') {
      push @node, $_;
    } else {
      my $status = $_->get_attribute ('status', make_new_node => 1)->inner_text;
      if ($status eq 'CDATA') {
        $_->{type} = '#text';
        $_->remove_attribute ('status');
        push @node, $_;
      } elsif ($status ne 'IGNORE') {	# INCLUDE
        for my $e (@{$_->{node}}) {
          if ($e->{type} ne '#attribute') {
            $e->{parent} = $self;
            push @node, $e;
          }
        }
      }
    }
  }
  $self->{node} = \@node;
}

## TODO: references in EntityValue
sub remove_references ($) {
  my $self = shift;
  my @node;
  for (@{$self->{node}}) {
    if ({'#declaration' => 1, '#element' => 1, '#section' => 1,
         '#reference' => 1, '#attribute' => 1,
         '#document' => 1, '#fragment' => 1}->{$_->{type}}) {
      $_->remove_references;
    }
  }
  for (@{$self->{node}}) {
    if ($_->{type} ne '#reference'
    || ($self->{type} eq '#declaration'
     && $_->{namespace_uri} eq $NS{SGML}.'entity')) {
      push @node, $_;
    } else {
      if (index ($_->{namespace_uri}, 'char') > -1) {
        my $e = ref ($_)->new (type => '#text', value => chr $_->{value});
        $e->{parent} = $self;
        push @node, $e;
      } elsif ($_->{flag}->{smxp__ref_expanded}) {
        for my $e (@{$_->{node}}) {
          if ($e->{type} ne '#attribute') {
            $e->{parent} = $self;
            push @node, $e;
          }
        }
      } else {	## reference is not expanded
        push @node, $_;
      }
    }
    $_->{flag}->{smxp__defined_with_param_ref} = 0
      if $_->{flag}->{smxp__defined_with_param_ref}
      && !$_->{flag}->{smxp__non_processed_declaration};
  }
  $self->{node} = \@node;
}

sub resolve_relative_uri ($;$%) {
  my ($self, $rel, %o) = @_;  
  require URI;
  if ($rel =~ /^[0-9A-Za-z.%+-]+:/) {
    return URI->new ($rel);
  } else {
    my $base = $self->get_attribute_value ('base', namespace_uri => $NS{xml},
                                           default => '');
    if ($base !~ /^[0-9A-Za-z.%+-]+:/) {	# $base is relative
      $base = $self->_resolve_relative_uri_by_parent ($base, \%o);
    }
    eval {
      URI->new ($rel)->abs ($base || '.');
    } or return $rel;
  }
}
sub _resolve_relative_uri_by_parent ($$$) {
  my ($self, $rel, $o) = @_;
  if (ref $self->{parent}) {
    if (not $o->{use_references_base_uri}
        and $self->{parent}->{type} eq '#reference') {
      ## This case is necessary to work with
      ## <element>	<!-- element can have base URI -->
      ## text		<!-- text cannot have base URI -->
      ##   &ent;	<!-- ref's base URI is referred entity's one (in this module) -->
      ##     <!-- expantion of ent -->
      ##     entity's text	<!-- text cannot have base URI, so use <element>'s one -->
      ##     <entitys-element/>	<!-- element can have base URI, otherwise ENTITY's one -->
      ## </element>
      return $self->{parent}->_resolve_relative_uri_by_parent ($rel, $o);
    } else {
      return $self->{parent}->resolve_relative_uri ($rel, %$o);
    }
  } else {
    return length $rel ? $rel : $NS{default_base_uri};
  }
}
sub base_uri ($;$) {
  my ($self, $new_uri) = @_;
  my $base;
  if (defined $new_uri) {
    $base = $self->set_attribute (base => $new_uri, namespace_uri => $NS{xml});
  }
  $base ||= $self->get_attribute ('base', namespace_uri => $NS{xml});
  ref ($base) ? $base->inner_text : undef;
}

=item $tag = $x->start_tag

Returns the start tag (or something that marks the start of something, such as '<!--'
for C<#comment> nodes).

=cut

sub start_tag ($) {
  my $self = shift;
  if ($self->{type} eq '#element' && $self->_check_ncname ($self->{local_name})) {
    my $r = '';
    $self->qname; # dummy
    for (@{$self->{node}}) {
      $r .= ' ' . $_->outer_xml if $_->node_type eq '#attribute';
    }
    for my $prefix (sort grep !/^-/, keys %{$self->{ns}||{}}) {
      if ($prefix ne DEFAULT_PFX) {
        $r .= ' xmlns:'.$prefix;
      } else {
        $r .= ' xmlns';
      }
      $r .= '="';
      $r .= $self->_escape ($self->{ns}->{$prefix})
        if $self->{ns}->{$prefix} ne NULL_URI
        && $self->{ns}->{$prefix} ne NULL_URI;
      $r .= '"';
    }
    $r .= '>';
    '<' . $self->qname . $r;
  } elsif ($self->{type} eq '#comment') {
    '<!--';
  } elsif ($self->{type} eq '#pi' && $self->_check_ncname ($self->{local_name})) {
    '<?' . ($self->{local_name});
  } elsif ($self->{type} eq '#reference') {
    if ($self->{namespace_uri} eq $NS{SGML}.'char:ref:hex') {
      '&#x';
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'char:ref') {
      '&#';
    } elsif ($self->_check_ncname ($self->{local_name})) {
      if ($self->{namespace_uri} eq $NS{SGML}.'entity:parameter') {
        '%';
      } else {
        '&';
      }
    } else {	# error
      '';
    }
  } elsif ($self->{type} eq '#declaration' && $self->{namespace_uri}) {
    '<!' . {
    	$NS{SGML}.'attlist'	=> 'ATTLIST',
    	$NS{SGML}.'doctype'	=> 'DOCTYPE',
    	$NS{SGML}.'element'	=> 'ELEMENT',
    	$NS{SGML}.'entity'	=> 'ENTITY',
    	$NS{SGML}.'entity:parameter'	=> 'ENTITY',
    	$NS{SGML}.'notation'	=> 'NOTATION',
    }->{$self->{namespace_uri}} . ' ' .
    ($self->{namespace_uri} eq $NS{SGML}.'entity:parameter' ?
    ($self->{flag}->{smxp__defined_with_param_ref}?'':'% '):'');
  } elsif ($self->{type} eq '#section') {
    '<![';
  } else {
    '';
  }
}

=item $tag = $x->end_tag

Returns the end tag (or something that marks the end of something, such as '-->'
for C<#comment> nodes).

=cut

sub end_tag ($) {
  my $self = shift;
  if ($self->{type} eq '#element' && $self->_check_ncname ($self->{local_name})) {
    '</' . $self->qname . '>';
  } elsif ($self->{type} eq '#comment') {
    '-->';
  } elsif ($self->{type} eq '#pi' && $self->_check_ncname ($self->{local_name})) {
    '?>';
  } elsif ($self->{type} eq '#reference') {
    ';';
  } elsif ($self->{type} eq '#declaration' && $self->{namespace_uri}) {
    '>';
  } elsif ($self->{type} eq '#declaration' && $self->_check_ncname ($self->{local_name})) {
    '>';
  } elsif ($self->{type} eq '#section') {
    ']]>';
  } else {
    '';
  }
}

=item $tag = $x->attribute_name

Returns the attribute name.

=cut

sub attribute_name ($) {
  my $self = shift;
  $self->qname;
}

=item $tag = $x->attribute_value

Returns the attribute value.

=cut

sub attribute_value ($;%) {
  my ($self, %o) = @_;
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    my $r = '"';
    my $isc = $self->_is_same_class ($self->{value});
    $r .= $self->_escape ($self->{value}, keep_wsp => 1)
      if !$isc and defined $self->{value};
    for (($isc?$self->{value}:()), @{$self->{node}}) {
      my $nt = $_->{type};
      if ($nt eq '#reference' || $nt eq '#xml') {
        $r .= $_->outer_xml;
      } elsif ($nt ne '#attribute') {
        $r .= $self->_escape ($_->inner_text, keep_wsp => 1);
      }
    }
    return $r . '"';
  } else {
    '';
  }
}

sub entity_value ($;%) {
  my ($self, %o) = @_;
  my $_escape = sub {
    my $s = shift;
    return '' unless defined $s;
    $s =~ s/&/&#x26;/g;
    $s =~ s/&#x26;(\p{InXML_NameStartChar}\p{InXMLNameChar}*);/&$1;/g;
    $s =~ s/([\x0D%"])/sprintf '&#x%02X;', ord $1/ge;
    $s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F\x7F])/sprintf '&amp;#x%02X;', ord $1/ge;
    $s;
  };
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    my $r = '"' . &$_escape ($self->{value});
    for (@{$self->{node}}) {
      my $nt = $_->{type};
      if ($nt eq '#reference' || $nt eq '#xml') {
        $r .= $_->outer_xml;
      } elsif ($nt ne '#attribute') {
        $r .= &$_escape ($_->inner_text);
      }
    }
    return $r . '"';
  } else {
    '';
  }
}

## This method should be called only from Message::Markup::XML::* family modules,
## since this is NOT a FORMAL interface.
sub _entity_parameter_literal_value ($;%) {
  my $self = shift;
  my $r = '';
  my $isc = $self->_is_same_class ($self->{value});
  $r = $self->{value} unless $isc;
  for (($isc?$self->{value}:()), @{$self->{node}}) {
    my $nt = $_->{type};
    ## Bare node and general entity reference node
    if ($nt eq '#xml' || ($nt eq '#reference' && $_->{namespace_uri} eq $NS{SGML}.'entity')) {
      $r .= $_->outer_xml;
    ## Text node and parameter entity reference node
    } elsif ($nt ne '#attribute') {
      $r .= $_->inner_text;
    }
  }
  $r;
}

=item $tag = $x->attribute

Returns the attribute (name and value pair).

=cut

sub attribute ($) {
  my $self = shift;
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    $self->attribute_name . '=' . $self->attribute_value;
  } else {
    '';
  }
}

sub external_id ($;%) {
  my $self = shift;
  my %o = @_;
  my ($pubid, $sysid, $ndata);
      for (@{$self->{node}}) {
        if ($_->{type} eq '#attribute' && !$_->{namespace_uri}) {
          if ($_->{local_name} eq 'PUBLIC') {
            $pubid = $_->inner_text;
          } elsif ($_->{local_name} eq 'SYSTEM') {
            $sysid = $_->inner_text;
          } elsif ($_->{local_name} eq 'NDATA') {
            $ndata = $_->inner_text;
            undef $ndata unless $self->_check_ncname ($ndata);
          }
        }
      }
      my $r = '';
      if (defined $pubid) {
        $pubid =~ s|([^\x0A\x0D\x20A-Za-z0-9'()+,./:=?;!*#\@\$_%-])|sprintf '%%%02X', ord $1|ges;
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
      if ($pubid && $sysid) {
        $r = 'PUBLIC ' . $pubid . ' ' . $sysid;
      } elsif ($sysid) {
        $r = 'SYSTEM ' . $sysid;
      } elsif ($pubid && $o{allow_pubid_only}) {
        $r = 'PUBLIC ' . $pubid;
      }
  if ($r && $ndata && $o{use_ndata}) {
    $r .= ' NDATA ' . $ndata;
  }
  $r;
}

=item $tag = $x->inner_xml

Returns the content of the node in XML syntax.  (In case of the C<#element> nodes,
element content without start- and end-tags is returned.)

Note that for not all node types the behavior of this method is defined.
For example, returned value of C<#attribute> might be unexpected one
in this version of this module.

=cut

sub inner_xml ($;%) {
  my ($self, %o) = @_;
  my $r = '';
  if ($self->{type} eq '#comment') {
    $r = $self->inner_text;
    $r =~ s/--/-&#45;/g;
    $r =~ s/-$/&#45;/;
  } elsif ($self->{type} eq '#pi') {
    my $isc = $self->_is_same_class ($self->{value});
    if (!$isc and defined $self->{value} and length ($self->{value})) {
      $r = ' ' . $self->{value};
      #$r =~ s/\?>/? >/g;	## Same replacement as of the recommendation of XSLT:p.i.
      $r =~ s/\?>/?&gt;/g;	## Some PI (such as xml-stylesheet) support predefined entity reference
    }
    for (($isc?$self->{value}:()), @{$self->{node}}) {
      if ($_->node_type eq '#attribute') {
        $r .= ' ' . $_->attribute;
      } else {
        my $s = $_->inner_text;
        if (length $s) {
          $s =~ s/\?>/? >/g;
          $r .= ' ' . $s;
        }
      }
    }
  } elsif ($self->{type} eq '#reference') {
    if ($self->{namespace_uri} eq $NS{SGML}.'char:ref:hex') {
      $r = sprintf '%02X', $self->{value};
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'char:ref') {
      $r = sprintf '%02d', $self->{value};
    } elsif (ref ($self->{local_name}) && $self->{local_name}->{type} eq '#declaration') {
      $r = $self->{local_name}->{local_name};
    } elsif ($self->_check_ncname ($self->{local_name})) {
      $r = ($self->{local_name});
    } else {	# error
      $r = '';
    }
  } elsif ($self->{type} eq '#declaration') {
    if ($self->{namespace_uri} eq $NS{SGML}.'doctype') {
      my $root = $self->get_attribute ('qname');
      $root = (ref $root ? $root->inner_text : undef) || (ref $self->{parent} ? (do {
        for (@{$self->{parent}->{node}}) {
          if ($_->{type} eq '#element') {
            $root = $_->qname;
            last if $root;
          }
        }
        $root || '#IMPLIED';
      }) : '#IMPLIED');	## error!
      my ($isub, $xid) = ('', $self->external_id);
      for (@{$self->{node}}) {
        $isub .= $_->outer_xml if $_->{type} ne '#attribute';
      }
      if ($xid) {
        $r = $xid;
        if ($isub) {
          $r .= " [" . $isub . "]";
        }
      } else {
        if ($isub) {
          $r = "[" . $isub . "]";
        } else {
          $r = "[]";
        }
      }
      $r = $root . ' ' . $r;
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'entity'
          || $self->{namespace_uri} eq $NS{SGML}.'entity:parameter'
          || $self->{namespace_uri} eq $NS{SGML}.'notation') {
      my %xid_opt;
      $r = $self->{local_name} . ' ' if !$self->{flag}->{smxp__defined_with_param_ref}
                                        && $self->_check_ncname ($self->{local_name});
      if ($self->{namespace_uri} eq $NS{SGML}.'entity:parameter') {
        #$r = '% ' . $r;
      } elsif ($self->{namespace_uri} eq $NS{SGML}.'entity') {
        $xid_opt{use_ndata} = 1;
      } elsif ($self->{namespace_uri} eq $NS{SGML}.'notation') {
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
          $r .= $entity_value->entity_value;
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
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'element') {
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
              and $_->namespace_uri eq $NS{SGML}.'element') {
                if ($_->local_name eq 'group') {
                  my $tt = &$make_cmodel ($_);
                  push @tt, '(' . $tt . ')'
                     . $_->get_attribute_value ('occurence', default => '')
                    if $tt;
                } elsif ($_->local_name eq 'element') {
                  push @tt, $_->get_attribute_value ('qname')
                     . $_->get_attribute_value ('occurence', default => '');
                }
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
            and $_->namespace_uri eq $NS{SGML}.'element'
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
              $r .= '(#PCDATA)'
                  . ($grp_node->get_attribute_value ('occurence') eq '*'
                     ? '*' : '');
            }
          } else {	## element content
            if ($tt) {
              $r .= '(' . $tt . ')'
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
                 and $_->{namespace_uri} eq $NS{SGML}.'group') {
              $r .= $_->outer_xml;
            }
          }
      }
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'attlist') {
      $r = $self->get_attribute_value ('qname')
        unless $self->{flag}->{smxp__defined_with_param_ref};
      if ($r) {
        unless ($self->_check_name ($r)) {
          Carp::carp qq'inner_xml: "$r": QName expected';
          $r = '';
        }
        for (@{$self->{node}}) {
          if ($_->{type} eq '#element'
          and $_->{namespace_uri} eq $NS{XML}.'attlist'
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
                and $item->{namespace_uri} eq $NS{XML}.'attlist'
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
               and $_->{namespace_uri} eq $NS{SGML}.'group') {
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
  } elsif ($self->{type} eq '#section') {
    my $status = $self->get_attribute_value ('status', default => '');
    if ($status eq 'CDATA') {
      $r = $self->inner_text;
      $r =~ s/]]>/]]>]]<![CDATA[>/g;
      $r = 'CDATA['.$r;
    } else {
      my $sl = $self->get_attribute ('status_list', make_new_node => 1);
      if ($sl->{flag}->{smxp__defined_with_param_ref}) {
        my $isc = $self->_is_same_class ($self->{value});
        $status = (defined $sl->{value} and !$isc) ? $sl->{value} : '';
        for (($isc?$sl->{value}:()), @{$sl->{node}}) {
          $status .= $_->outer_xml unless $_->{type} eq '#attribute';
        }
        $r = $status.'['.$r;
      } elsif ($status) {
        $r = $status.'['.$r;
      } else {
        ## Must be an ignore*d* section
        $r = '[';
      }
      my $isc = $self->_is_same_class ($self->{value});
      if (not $isc and defined $self->{value}) {
        my $s = $self->{value};
        $s =~ s/\]\]>/]]&gt;/g;
        $r .= $s;
      }
      for (($isc?$self->{value}:()), @{$self->{node}}) {
        if ($_->{type} eq '#text') {
          my $s = $_->inner_text;
          $s =~ s/\]\]>/]]&gt;/g;
          $r .= $s;  ## But this will be non well-formed.
        } elsif ($_->{type} ne '#attribute') {
          $r .= $_->outer_xml;
        }
      }
    }
  } else {
    my $isc = $self->_is_same_class ($self->{value});
    unless ($isc) {
      if ($self->{type} ne '#xml') {
        $r = defined $self->{value} ? $self->_escape ($self->{value}) : '';
      } else {
        $r = $self->{value};
      }
    }
    for (($isc?$self->{value}:()), @{$self->{node}}) {
      my $nt = $_->{type};
      if (($self->{option}->{indent})
       && ($nt eq '#element' || $nt eq '#comment' || $nt eq '#pi' || $nt eq '#declaration')) {
        $r .= "\n";
      }
      $r .= $_->outer_xml unless $_->node_type eq '#attribute';
    }
  }
  $r;
}


=item $tag = $x->outer_xml

Returns the node in XML syntax.

=cut

sub outer_xml ($) {
  my $self = shift;
  if ($self->{type} eq '#attribute') {
    return $self->attribute;
  } else {
      $self->qname; ## Register undeclared namespace
      my $c = $self->inner_xml;
      my $r = $self->start_tag;
      if ($self->{type} eq '#element'
      and $self->{option}->{use_EmptyElemTag}
      and not length $c) {
        substr ($r, -1) = ' />';
      } else {
        $r .= $c . $self->end_tag;
      }
      return $r;
      #return '{'.$self->{type}.': '.$r.'}';	## DEBUG: show structure
  }
}

=item $tag = $x->inner_text

Returns the text content of the node.  (In many case the returned value is same
as WinIE DOM C<inner_text ()> function's or XPath C<text()> function's.
But some classes that inherits this module might implement to return other
value (eg. to return the value of the alt attribute of html:img element).

Available options: C<output_ref_as_is>.

=cut

sub inner_text ($;%) {
  my $self = shift;
  my %o = @_;
  my $r = '';
  if ($self->{type} eq '#reference'
      && ($self->{namespace_uri} eq $NS{SGML}.'char:ref'
       || $self->{namespace_uri} eq $NS{SGML}.'char:ref:hex')) {
    $r = chr $self->{value};
  } elsif ($self->{type} eq '#declaration'
       && ($self->{namespace_uri} eq $NS{SGML}.'entity'
        || $self->{namespace_uri} eq $NS{SGML}.'entity:parameter')) {
    ## TODO: 
    $r = $self->set_attribute ('value')->inner_text;
  } else {	# not #reference nor #declaration(ENTITY)
    my $isc = $self->_is_same_class ($self->{value});
    $r = $self->{value} if !$isc && defined $self->{value};
    if ($o{output_ref_as_is}) {	## output as if RCDATA
      $r =~ s/&/&amp;/g;
      for my $node (($isc?$self->{value}:()), @{$self->{node}}) {
        my $nt = $node->node_type;
        if ($nt eq '#reference' || $nt eq '#xml') {
          $r .= $node->outer_xml;
        } elsif ($nt ne '#attribute') {
          $r .= map {s/&/&amp;/g; $_} $node->inner_text;
        }
      }
    } else {
      for (($isc?$self->{value}:()), @{$self->{node}}) {
        $r .= $_->inner_text unless $_->{type} eq '#attribute';
      }
    }
  }
  $r;
}

sub stringify ($;%) { shift->outer_xml (@_) }

sub _is_same_class ($$) {
  my ($self, $something) = @_;
  return 0 if {qw/ARRAY 1 HASH 1 CODE 1 :nonref: 1/}->{ref ($something) || ':nonref:'};
  eval q{$self->_CLASS_NAME eq $something->_CLASS_NAME} ? 1 : 0;
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

sub _get_ns_decls_node ($;%) {
  my ($self, %opt) = @_;
  if ($self->{type} eq '#element') {
    return $self;
  } elsif (ref $self->{parent}) {
    return $self->{parent}->_get_ns_decls_node;
  } elsif (exists $opt{default}) {
    return $opt{default};
  } else {
    Carp::carp qq(There is no namespace declarations node (type $self->{type}));
    return {};
  }
}

sub _get_entity_manager ($) {
  my $self = shift;
  if ($self->{type} eq '#document') {
    unless ($self->{flag}->{smx__entity_manager}) {
      require Message::Markup::XML::EntityManager;
      $self->{flag}->{smx__entity_manager} = Message::Markup::XML::EntityManager->new ($self);
    }
    return $self->{flag}->{smx__entity_manager};
  } elsif (ref $self->{parent}) {
    return $self->{parent}->_get_entity_manager;
  } else {
    unless ($self->{flag}->{smx__entity_manager}) {
      require Message::Markup::XML::EntityManager;
      $self->{flag}->{smx__entity_manager} = Message::Markup::XML::EntityManager->new ($self);
    }
    return $self->{flag}->{smx__entity_manager};
  }
}

sub _CLASS_NAME { 'SuikaWiki::Markup::XML' }

# $s = $x->_escape ($s)
sub _escape ($$;%) {
  my ($self, $s, %o) = (shift, shift, @_);
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  ## XML 1.0
  $s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F])/sprintf '&amp;#%d;', ord $1/ge;
  ## XML 1.1
  #$s =~ s/(\x00)/sprintf '&amp;#%d;', ord $1/ge;
  #$s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F])/sprintf '&#x%02X;', ord $1/ge;
  $s =~ s/([\x09\x0A\x0D])/sprintf '&#%d;', ord $1/ge if $o{keep_wsp};
  $s;
}

# 1/0 = $x->_check_name ($s)
sub _check_name ($$) {
  my $self = shift;
  my $s = shift;
  return 0 unless defined $s;
  return $Cache{name}->{$s} if defined $Cache{name}->{$s};
  if ($s =~ /^\p{InXML_NameStartChar}/ && $s !~ /\P{InXMLNameChar}/) {
  # \p{...}('*'/'+'/'{n,}') does not work...
    $Cache{name}->{$s} = 1;
    1;
  } else {
    $Cache{name}->{$s} = 0;
    0;
  }
}
# 1/0 = $x->_check_ncname ($s)
sub _check_ncname ($$) {
  my $self = shift;
  my $s = shift;
  return 0 unless defined $s;
  return $Cache{ncname}->{$s} if defined $Cache{ncname}->{$s};
  if ($s =~ /^\p{InXML_NCNameStartChar}/ && $s !~ /\P{InXMLNCNameChar}/) {
  # \p{...}('*'/'+'/'{n,}') does not work...
    $Cache{ncname}->{$s} = 1;
    1;
  } else {
    $Cache{ncname}->{$s} = 0;
    0;
  }
}

# 1/0 = $x->_check_namespace_prefix ($s)
sub _check_namespace_prefix ($$) {
  my $self = shift;
  my $s = shift;
  return 0 unless defined $s;
  return 1 if $s eq '';
  substr ($s, -1, 1) = '' if substr ($s, -1, 1) eq ':';
  $self->_check_ncname ($s);
}

## TODO: cleaning $self->{node} before outputing, to ensure nodes not to have
## multiple parents.
## TODO: normalize namespace URI (removing non URI chars)

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

=item #attribute

Attribute.  Its XML representation takes the form of NAME="VALUE".

=item #comment

Comment declarement. <!-- -->

=item #declarement

SGML's declarements, such as SGML, DOCTYPE, ENTITY, etc.
<!SGML ...>, <!DOCTYPE root []>, <!ENTITY % name "value">

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

=cut

=head1 RESTRICTIONS

=over 4

=item XML without XML Namespace is not supported.

=item Before default namespace without bounded URI (xmlns="") is outputed, it must be declared.

For example, next code generates invalid (non-well-formed) XML Namespace document.

  my $x = Message::Markup::XML->new (local_name => 'elementType');
  print $x	# <ns1:elementType xmlns:ns1=""></ns1:elementType>

So you must write like:

  my $x = Message::Markup::XML->new (local_name => 'elementType');
  $x->define_new_namespace ('' => '');
  print $x;	# <elementType xmlns=""></elementType>

=back

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/10/31 12:29:59 $
