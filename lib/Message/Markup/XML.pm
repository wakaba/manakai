
=head1 NAME

SuikaWiki::Markup::XML --- SuikaWiki: Simple well-formed document fragment generator

=head1 DESCRIPTION

This module can be used to generate the document fragment of XML, SGML or
other well-formed (in XML meaning) data formats with the object oriented manner.

This module cannot be used to parse XML (or other marked-up) document (or its fragment)
by itself, nor is compatible with other huge packages such as XML::Parser.  The only purpose
of this module is to make it easy for tiny perl scripts to GENERATE well-formed
markup constructures.  (SuikaWiki is not "tiny"?  Oh, yes, I see:-))

=cut

package SuikaWiki::Markup::XML;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.13 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload '""' => \&outer_xml,
             fallback => 1;
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar InXML_NCNameStartChar InXMLNCNameChar!;
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
	internal_attr_duplicate	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/invalid-attr#',
	internal_invalid_sysid	=> 'http://system.identifier.invalid/',
	internal_ns_invalid	=> 'http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#',
	xml	=> 'http://www.w3.org/XML/1998/namespace',
	xmlns	=> 'http://www.w3.org/2000/xmlns/',
);

=head1 METHODS

=over 4

=item $x = SuikaWiki::Markup::XML->new (%options)

Returns new instance of the module.  It is itself a node.

Available options: C<data_type>, C<default_decl>, C<type> (default: C<#element>), C<local_name>, C<namespace_uri> and C<value>.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->{type} ||= '#element';
  if ($self->{qname}) {
    ($self->{namespace_prefix}, $self->{local_name}) = $self->_ns_parse_qname ($self->{qname});
    $self->{_qname} = $self->{qname};
  }
  if (defined $self->{namespace_prefix}) {
    $self->{namespace_prefix} .= ':' if $self->{namespace_prefix}
                                     && substr ($self->{namespace_prefix}, -1) ne ':';
    $self->{ns}->{$self->{namespace_prefix}||''} = $self->{namespace_uri}
      if defined $self->{namespace_uri};
  }
  for (qw/local_name value/) {
    if ($self->_is_same_class ($self->{$_})) {
      $self->{$_}->{parent} = $self;
    }
  }
  $self->{node} ||= [];
  $self;
}

sub _ns_parse_qname ($$) {
  my $qname = $_[1];
  if ($qname =~ /:/) {
    return split /:/, $qname, 2;
  } else {
    return (undef, $qname);
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
  $self->append_new_node (type => '#text', value => $s);
}

sub append_baretext ($$;%) {
  my $self = shift;
  my $s = shift;
  $self->append_new_node (type => '#xml', value => $s);
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
     && $_->{local_name} eq $name
     && $o{namespace_uri} eq $_->{namespace_uri}) {
      return $_;
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

=item $attr_node = $x->set_attribute ($local_name => $value, %options)

Set the value of the attribute.  The attribute node is returned.

Available options: C<namespace_uri>.

=cut

sub set_attribute ($$$;%) {
  my ($self, $name, $val, %o) = @_;
  if ({qw/ARRAY 1 HASH 1 CODE 1/}->{ref ($val)}) {
  ## TODO: common error handling
    require Carp;
    Carp::croak "set_attribute: new attribute value must be string or blessed object";
  }
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute'
     && $_->{local_name} eq $name
     && $o{namespace_uri} eq $_->{namespace_uri}) {
      $_->{value} = $val;
      $_->{node} = [];
      return $_;
    }
  }
  return $self->append_new_node (type => '#attribute', local_name => $name,
                                 value => $val, namespace_uri => $o{namespace_uri});
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
sub namespace_prefix ($;$) {
  my ($self, $new_pfx) = @_;
  if (defined $new_pfx && $self->{namespace_uri}) {
    $new_pfx .= ':' if $new_pfx;
    $self->{namespace_prefix} = $new_pfx;
    $self->{ns}->{$new_pfx} = $self->{namespace_uri};
  }
  $self->_get_namespace_prefix ($self->{namespace_uri});
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
  my ($self, $uri, %o) = @_;
  if (defined (my $p = $self->_uri_to_prefix ($uri, undef, %o))) {
    return $p if $self->_prefix_to_uri ($p) eq $uri;
  } if ($Namespace_URI_to_prefix{$uri}) {
    for (@{$Namespace_URI_to_prefix{$uri}}) {
      my $pfx = $_; $pfx .= ':' if $pfx;
      if ($self->_check_namespace_prefix ($pfx) && !$self->_prefix_to_uri ($pfx)) {
        return $self->_uri_to_prefix ($uri => $pfx, %o);
      }
    }
  } else {
    my ($u_r_i, $pfx) = ($uri);
    $u_r_i =~ s/[^0-9A-Za-z._-]+/ /g;
    my @u_r_i = split / /, $u_r_i;
    for (reverse @u_r_i) {
      if (s/([A-Za-z][0-9A-Za-z._-]+)//) {
        my $p_f_x = $1 . ':';
        next if lc (substr ($p_f_x, 0, 3)) eq 'xml';
        unless ($self->_prefix_to_uri ($p_f_x)) {
          $pfx = $p_f_x;
          last;
        }
      }
    }
    if ($pfx) {
      return $self->_uri_to_prefix ($uri => $pfx, %o);
    } else {
      while (1) {
        my $pfx = 'ns'.(++$self->{ns}->{-anonymous}).':';
        unless ($self->_prefix_to_uri ($pfx)) {
          return $self->_uri_to_prefix ($uri => $pfx, %o);
        }
      }
    }
  }
}

sub _set_prefix_to_uri ($$$;%) {
  my ($self, $prefix => $uri, %o) = @_;
  return undef unless $self->_check_namespace_prefix ($prefix);
  $self->{ns}->{$prefix} = $uri;
  $self->_prefix_to_uri ($prefix);
}

## TODO: removing ns declare (1.1) support
# $uri or undef = $x->_prefix_to_uri ($prefix)
sub _prefix_to_uri ($$;$%) {
  my ($self, $prefix, %o) = @_;
  return undef unless $self->_check_namespace_prefix ($prefix);
  if (uc (substr $prefix, 0, 3) eq 'XML') {
    return $NS{xml} if $prefix eq 'xml:';
    return $NS{xmlns} if $prefix eq 'xmlns:';
  }
  if (defined $self->{ns}->{$prefix}) {
    $self->{ns}->{$prefix};
  } elsif (ref $self->{parent}) {
    shift;	# $self
    $self->{parent}->_prefix_to_uri (@_);
  } else {
    undef;
  }
}

# $prefix or undef = $x->_uri_to_prefix ($uri => [$new_prefix], %options)
# use_no_prefix (default: 1): Allow default namespace (no prefix).
sub _uri_to_prefix ($$;$%) {
  my ($self, $uri, $new_prefix, %o) = @_;
  if (defined $new_prefix && $self->_check_namespace_prefix ($new_prefix)) {
    $self->{ns}->{$new_prefix} = $uri;
    $new_prefix;
  } else {
    return 'xml:' if $uri eq $NS{xml};
    return 'xmlns:' if $uri eq $NS{xmlns};
    for (keys %{$self->{ns}||{}}) {
      next if ($_ eq '') && !(!defined $o{use_no_prefix} || $o{use_no_prefix});
      return $_ if $self->{ns}->{$_} eq $uri;
    }
    if (ref ($self->{parent}) && $self->{parent}->{type} ne '#declaration') {
      shift;	# $self
      $self->{parent}->_uri_to_prefix (@_);
    } else {
      undef;
    }
  }
}

=item $x->define_new_namespace ($prefix => $uri)

Defines a new XML Namespace.  This method is useful for root or section-level
element node.

Returned value is unspecified in this version of this module.

=cut

## TODO: structured URI (such as http://&server;/) support
sub define_new_namespace ($$$) {
  my ($self, $prefix, $uri) = @_;
  if ($prefix eq '' || $self->_check_ncname ($prefix)) {
    $prefix .= ':' if $prefix && substr ($prefix, -1) ne ':';
    $self->_set_prefix_to_uri ($prefix => $uri);
  } else {
    undef;
  }
}

=item $uri = $x->defined_namespace_prefix ($prefix)

Query whether the namespace prefix is defined or not.
If defined, return namespace name (URI).

=cut

sub defined_namespace_prefix ($$) {
  my ($self, $prefix) = @_;
  $prefix .= ':' if $prefix;
  $self->_prefix_to_uri ($prefix);
}

=item $qname = $x->qname

Returns QName ((namespace-)qualified name) of the element type.
Undef is retuened when the type does not have its QName
(ie. when type is neither C<#element> or C<#attribute>).

=cut

sub qname ($) {
  my $self = shift;
  if ($self->_check_ncname ($self->{local_name})) {
    if ($self->{type} eq '#element') {
      $self->{_qname} = $self->_get_namespace_prefix ($self->{namespace_uri}) . $self->{local_name}
        unless $self->{_qname};
      return $self->{_qname};
    } elsif ($self->{type} eq '#attribute') {
      return $self->attribute_name;
    }
  }
  undef;
}

sub merge_external_subset ($) {
  my $self = shift;
  unless ($self->{type} eq '#declaration' && $self->{namespace_uri} eq $NS{SGML}.'doctype') {
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
    $_->remove_marked_section;
  }
  for (@{$self->{node}}) {
    if ($_->{type} ne '#section') {
      push @node, $_;
    } else {
      my $status = $_->get_attribute ('status', make_new_node => 1)->inner_text;
      if ($status eq 'CDATA') {
        $_->{type} = '#text';
        $_->remove_child_node ($_->get_attribute ('status'));
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

sub remove_references ($) {
  my $self = shift;
  my @node;
  for (@{$self->{node}}) {
    $_->remove_references;
  }
  for (@{$self->{node}}) {
    if ($_->{type} ne '#reference'
    || ($self->{type} eq '#declaration' && $_->{namespace_uri} eq $NS{SGML}.'entity')) {
      push @node, $_;
    } else {
      if ($_->{namespace_uri} =~ /char/) {
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
  require URI;
  my ($self, $rel, %o) = @_;
  my $base = $self->get_attribute ('base', namespace_uri => $NS{xml});
  $base = ref ($base) ? $base->inner_text : undef;
  if ($base !~ /^(?:[0-9A-Za-z.+-]|%[0-9A-Fa-f]{2})+:/) {	# $base is relative
    $base = $self->_resolve_relative_uri_by_parent ($base, \%o);
  }
  eval q{	## Catch error such as $base is 'data:,foo' (non hierarchic scheme,...)
    return URI->new ($rel)->abs ($base || '.');	## BUG (or spec) of URI: $base == false
  } or return $rel;
}
sub _resolve_relative_uri_by_parent ($$$) {
  my ($self, $rel, $o) = @_;
  if (ref $self->{parent}) {
    if (!$o->{use_references_base_uri} && $self->{parent}->{type} eq '#reference') {
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
    return $rel;
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
    my $r = '<';
    $r .= $self->qname;
    for (@{$self->{node}}) {
      $r .= ' ' . $_->outer_xml if $_->node_type eq '#attribute';
    }
    for my $prefix (grep !/^-/, keys %{$self->{ns}||{}}) {
      if ($prefix) {
        $r .= ' xmlns:'.substr ($prefix, 0, length ($prefix)-1);
      } else {
        $r .= ' xmlns';
      }
      $r .= '="'.$self->_entitize ($self->{ns}->{$prefix}).'"';
    }
    $r .= '>';
    $r;
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
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    ($self->{namespace_uri} ?
      (ref $self->{parent} ? $self->{parent} : $self)
      ->_get_namespace_prefix ($self->{namespace_uri}, use_no_prefix => 0) : '')
    .$self->{local_name};
  } else {
    '';
  }
}

=item $tag = $x->attribute_value

Returns the attribute value.

=cut

sub attribute_value ($;%) {
  my ($self, %o) = @_;
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    my $r = '"';
    my $isc = $self->_is_same_class ($self->{value});
    $r .= $self->_entitize ($self->{value}, keep_wsp => 1) unless $isc;
    for (($isc?$self->{value}:()), @{$self->{node}}) {
      my $nt = $_->{type};
      if ($nt eq '#reference' || $nt eq '#xml') {
        $r .= $_->outer_xml;
      } elsif ($nt ne '#attribute') {
        $r .= $self->_entitize ($_->inner_text, keep_wsp => 1);
      }
    }
    return $r . '"';
  } else {
    '';
  }
}

sub entity_value ($;%) {
  my ($self, %o) = @_;
  my $_entitize = sub {
    my $s = shift;
    $s =~ s/&/&#x26;/g;
    $s =~ s/&#x26;(\p{InXML_NameStartChar}\p{InXMLNameChar}*);/&$1;/g;
    $s =~ s/([\x0D%"])/sprintf '&#x%02X;', ord $1/ge;
    $s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F\x7F])/sprintf '&amp;#x%02X;', ord $1/ge;
    $s;
  };
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    my $r = '"' . &$_entitize ($self->{value});
    for (@{$self->{node}}) {
      my $nt = $_->{type};
      if ($nt eq '#reference' || $nt eq '#xml') {
        $r .= $_->outer_xml;
      } elsif ($nt ne '#attribute') {
        $r .= &$_entitize ($_->inner_text);
      }
    }
    return $r . '"';
  } else {
    '';
  }
}

## This method should be called only from SuikaWiki::Markup::XML::* family modules,
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

=item $s = $x->content_spec

Generates contentspec of element type declaration (ex. C<(E1 | E2 | E3)>)
or AttDef of attribute declaration (ex. C<name CDATA #REQUIRED>).

=cut

sub content_spec ($) {
  my $self = shift;
  if ($self->{type} eq '#element') {
    my $text = 0;
    my $contentspec = join ' | ', map {$_->qname} grep {$text = 1 if $_->{type} eq '#text'; $_->{type} eq '#element'} @{$self->{node}};
        $contentspec = '#PCDATA' . ($contentspec ? ' | ' . $contentspec : '') if $text;
        
    return $contentspec ? '(' . $contentspec . ')' : 'EMPTY';
  } elsif ($self->{type} eq '#attribute') {
    my $attdef = $self->qname . "\t" . ($self->{data_type} || 'CDATA') . "\t";
    my $default = $self->{default_decl};
    $default .= ' ' . $self->attribute_value if $default eq '#FIXED';
    unless ($default) {
      $default = defined $self->{value} ? $self->attribute_value : '#IMPLIED';
    }
    return $attdef . $default;
  }
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
    $r =~ s/--/-&#x45;/g;
  } elsif ($self->{type} eq '#pi') {
    my $isc = $self->_is_same_class ($self->{value});
    if (!$isc && length ($self->{value})) {
      $r = ' ' . $self->{value};
      $r =~ s/\?>/? >/g;	# Same replacement as of the recommendation of XSLT:p.i.
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
      ref $root ? ($root = $root->inner_text) : (ref $self->{parent} ? (do {
        for (@{$self->{parent}->{node}}) {
          if ($_->{type} eq '#element') {
            $root = $_->qname;
            last if $root;
          }
        }
        $root = '#IMPLIED';
      }) : ($root = '#IMPLIED'));	## error!
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
      
      my ($v, $xid) = ($self->{value});
      $xid = $self->external_id (%xid_opt) unless $self->{flag}->{smxp__defined_with_param_ref};
      if ($xid) {	## External ID
        $r .= $xid;
      } else {	## EntityValue
        my $entity_value = $self->get_attribute ('value');
        undef $entity_value if $self->{flag}->{smxp__defined_with_param_ref};
        if ($entity_value) {	# <!ENTITY foo "bar">
          $r .= $entity_value->entity_value;
        } else {	## Parameter entity reference
          my $isc = $self->_is_same_class ($self->{value});
          $r .= $self->{value} unless $isc;
          for (($isc?$self->{value}:()), @{$self->{node}}) {
            $r .= $_->outer_xml unless $_->{type} eq '#attribute';
          }
        }
      }
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'element') {
      if (!$self->{flag}->{smxp__defined_with_param_ref}) {
        $r = $self->get_attribute ('qname');
        $r = $r->inner_text if $r;
        unless ($self->_check_ncname ($r)) {
          $r = undef;
        } else {
          $r .= ' ';
        }
        
        my $cmodel = $self->get_attribute ('content', make_new_node => 1)->inner_text;
        if ($cmodel && $cmodel ne 'mixed') {
          $r .= $cmodel;
        } else {
          my $make_cmodel;
          $make_cmodel = sub {
            my $c = shift;
            my @tt;
            for (@{$c->child_nodes}) {
              if ($_->node_type eq '#element' && $_->namespace_uri eq $NS{SGML}.'element') {
                if ($_->local_name eq 'group') {
                  my $tt = &$make_cmodel ($_);
                  push @tt, '(' . $tt . ')'
                     . ($_->get_attribute ('occurence', make_new_node => 1)->inner_text)
                    if $tt;
                } elsif ($_->local_name eq 'element') {
                  push @tt, $_->get_attribute ('qname', make_new_node => 1)->inner_text;
                }
              }
            }
            return join scalar ($c->get_attribute ('connector', make_new_node => 1)->inner_text
                                || '|'),
                   grep {$_} @tt;
          };
          my $tt;
          my $grp_node;
          for (@{$self->child_nodes}) {
            if ($_->node_type eq '#element' && $_->namespace_uri eq $NS{SGML}.'element'
             && $_->local_name eq 'group') {
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
                  . ($grp_node->get_attribute ('connector', make_new_node => 1)->inner_text eq '*'
                     ? '*' : '');
            }
          } else {	## element content
            if ($tt) {
              $r .= '(' . $tt . ')'
                  . ($grp_node->get_attribute ('occurence', make_new_node => 1)->inner_text);
            } else {
              $r .= 'EMPTY';
            }
          }	# mixed or element content
        }	# content model group
      } else {	## Save source doc's description as far as possible
          my $isc = $self->_is_same_class ($self->{value});
          $r .= $self->{value} unless $isc;
          for (($isc?$self->{value}:()), @{$self->{node}}) {
            unless ($_->{type} eq '#attribute' || $_->{type} eq '#element') {
              $r .= $_->outer_xml;
            } elsif ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{SGML}.'group') {
              $r .= $_->outer_xml;
            }
          }
      }
    } elsif ($self->{namespace_uri} eq $NS{SGML}.'attlist') {
      if (!$self->{flag}->{smxp__defined_with_param_ref}) {
        $r = $self->get_attribute ('qname');
        $r = $r->inner_text if $r;
        unless ($self->_check_ncname ($r)) {
          $r = undef;
        } else {
          $r .= ' ';
        }
        for (@{$self->{node}}) {
          if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{XML}.'attlist'
           && $_->{local_name} eq 'AttDef') {
            $r .= "\n\t" . $_->get_attribute ('qname', make_new_node => 1)->inner_text;
            my $attr_type = $_->get_attribute ('type', make_new_node => 1)->inner_text;
            if ($attr_type ne 'enum') {
              $r .= "\t" . $attr_type;
            }
            if ($attr_type eq 'enum' || $attr_type eq 'NOTATION') {
              my @l;
              for my $item (@{$_->{node}}) {
                if ($item->{type} eq '#element' && $item->{namespace_uri} eq $NS{XML}.'attlist'
                 && $item->{local_name} eq 'enum') {
                  push @l, $item->inner_text;
                }
              }
              $r .= "\t(" . join ('|', @l) . ')';
            }
            ## DefaultDecl
            my $deftype = $_->get_attribute ('default_type', make_new_node => 1)->inner_text;
            if ($deftype) {
              $r .= "\t#" . $deftype;
            }
            if (!$deftype || $deftype eq 'FIXED') {
              $r .= "\t" . $_->get_attribute ('default_value', make_new_node => 1)
                             ->attribute_value;
            }
          }	# AttDef
        }
      } else {	## Save source doc's description as far as possible
          my $isc = $self->_is_same_class ($self->{value});
          $r .= $self->{value} unless $isc;
          for (($isc?$self->{value}:()), @{$self->{node}}) {
            unless ($_->{type} eq '#attribute' || $_->{type} eq '#element') {
              $r .= $_->outer_xml;
            } elsif ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{SGML}.'group') {
              $r .= $_->outer_xml;
            }
          }
      }
    } else {	# unknown
        for (@{$self->{node}}) {
          $r .= $_->outer_xml;
        }
    }
  } elsif ($self->{type} eq '#section') {
    my $status = $self->get_attribute ('status', make_new_node => 1)->inner_text;
    if ($status eq 'CDATA') {
      $r = $self->inner_text;
      $r =~ s/]]>/]]>]]<![CDATA[>/g;
      $r = 'CDATA['.$r;
    } else {
      my $sl = $self->get_attribute ('status_list', make_new_node => 1);
      if ($sl->{flag}->{smxp__defined_with_param_ref}) {
        my $isc = $self->_is_same_class ($self->{value});
        $status = '';
        $status = $sl->{value} unless $isc;
        for (($isc?$sl->{value}:()), @{$sl->{node}}) {
          $status .= $_->outer_xml unless $_->{type} eq '#attribute';
        }
        $r = $status.'['.$r;
      } elsif ($status) {
        $r = $status.'['.$r;
      } else {
        ## Must be an ignored section
      }
      my $isc = $self->_is_same_class ($self->{value});
      $r .= join '', map {s/\]\]>/]]&gt;/g; $_} $self->{value} unless $isc;
      for (($isc?$self->{value}:()), @{$self->{node}}) {
        if ($_->{type} eq '#text') {
          $r .= join '', map {s/\]\]>/]]&gt;/g; $_} $_->inner_text;	## Anyway, this is error
        } elsif ($_->{type} ne '#attribute') {
          $r .= $_->outer_xml;
        }
      }
    }
  } else {
    my $isc = $self->_is_same_class ($self->{value});
    unless ($isc) {
      if ($self->{type} ne '#xml') {
        $r = $self->_entitize ($self->{value});
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
    if ($self->{option}->{indent} && $self->{type} eq '#element') {
      my $r = $self->start_tag;
      my $c = $self->inner_xml;
      if (!length ($c) && $self->{option}->{use_EmptyElemTag}) {
        substr ($r, -1) = ' />';
      } else {
        if ($c) {
          $c =~ s/\n/\n  /g;
          $r .= "\n  " . $c . "\n";
        }
        $r .= $self->end_tag;
      }
      return $r;
    } else {
      my $r = $self->start_tag;
      my $c = $self->inner_xml;
      if ($self->{type} eq '#element' && !length ($c) && $self->{option}->{use_EmptyElemTag}) {
        substr ($r, -1) = ' />';
      } else {
        $r .= $c . $self->end_tag;
      }
      return $r;
      #return '{'.$self->{type}.': '.$r.'}';	## DEBUG: show structure
    }
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
    $r = $self->{value} unless $isc;
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

sub _get_entity_manager ($) {
  my $self = shift;
  if ($self->{type} eq '#document') {
    unless ($self->{flag}->{smx__entity_manager}) {
      require SuikaWiki::Markup::XML::EntityManager;
      $self->{flag}->{smx__entity_manager} = SuikaWiki::Markup::XML::EntityManager->new ($self);
    }
    return $self->{flag}->{smx__entity_manager};
  } elsif (ref $self->{parent}) {
    return $self->{parent}->_get_entity_manager;
  } else {
    unless ($self->{flag}->{smx__entity_manager}) {
      require SuikaWiki::Markup::XML::EntityManager;
      $self->{flag}->{smx__entity_manager} = SuikaWiki::Markup::XML::EntityManager->new ($self);
    }
    return $self->{flag}->{smx__entity_manager};
  }
}

sub _CLASS_NAME ($) { 'SuikaWiki::Markup::XML' }

# $s = $x->_entitize ($s)
sub _entitize ($$;%) {
  my ($self, $s, %o) = (shift, shift, @_);
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  $s =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F])/sprintf '&amp;#%d;', ord $1/ge;
  $s =~ s/([\x09\x0A\x0D])/sprintf '&#%d;', ord $1/ge if $o{keep_wsp};
  $s;
}

# 1/0 = $x->_check_name ($s)
sub _check_name ($$) {
  my $self = shift;
  my $s = shift;
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

  my $x = SuikaWiki::Markup::XML->new (local_name => 'elementType');
  print $x	# <ns1:elementType xmlns:ns1=""></ns1:elementType>

So you must write like:

  my $x = SuikaWiki::Markup::XML->new (local_name => 'elementType');
  $x->define_new_namespace ('' => '');
  print $x;	# <elementType xmlns=""></elementType>

=back

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/07/13 02:32:24 $
