
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
use overload '""' => \&stringify;
use Char::Class::XML qw!InXML_NCNameStartChar InXMLNCNameChar!;
our %Namespace_URI_to_prefix = (
	'DAV:'	=> [qw/dav webdav/],
	'http://greenbytes.de/2002/rfcedit'	=> [qw/ed/],
	'http://icl.com/saxon'	=> [qw/saxon/],
	'http://members.jcom.home.ne.jp/jintrick/2003/02/site-concept.xml#'	=> ['', qw/sitemap/],
	'http://purl.org/dc/elements/1.1/'	=> [qw/dc dc11/],
	'http://purl.org/rss/1.0/'	=> ['', qw/rss rss10/],
	'http://suika.fam.cx/~wakaba/lang/rfc/translation/'	=> [qw/ja/],
	'http://www.mozilla.org/xbl'	=> ['', qw/xbl/],
	'http://www.w3.org/1999/02/22-rdf-syntax-ns#'	=> [qw/rdf RDF/],
	'http://www.w3.org/1999/xhtml'	=> ['', qw/h h1 xhtml xhtml1/],
	'http://www.w3.org/1999/xlink'	=> [qw/l xlink/],
	'http://www.w3.org/1999/XSL/Format'	=> [qw/fo xslfo xsl-fo xsl/],
	'http://www.w3.org/1999/XSL/Transform'	=> [qw/t s xslt xsl/],
	'http://www.w3.org/1999/XSL/TransformAlias'	=> [qw/axslt axsl xslt xsl/],
	'http://www.w3.org/2000/01/rdf-schema#'	=> [qw/rdfs/],
	'http://www.w3.org/2000/svg'	=> ['', qw/s svg/],
	'http://www.w3.org/2002/06/hlink'	=> [qw/h hlink/],
	'http://www.w3.org/2002/06/xhtml2'	=> ['', qw/h h2 xhtml xhtml2/],
	'http://www.w3.org/Graphics/SVG/svg-19990412.dtd'	=> ['', qw/svg/],
	'http://www.w3.org/TR/REC-smil'	=> ['', qw/smil smil1/],
	'http://xml.apache.org/xalan'	=> [qw/xalan/],
	'mailto:julian.reschke@greenbytes.de?subject=rcf2629.xslt'	=> [qw/myns/],
	'urn:schemas-microsoft-com:office:excel'	=> [qw/x excel/],
	'urn:schemas-microsoft-com:office:office'	=> [qw/o office/],
	'urn:schemas-microsoft-com:office:word'	=> [qw/w word/],
	'urn:schemas-microsoft-com:vml'	=> [qw/v vml/],
	'urn:schemas-microsoft-com:xslt'	=> [qw/ms msxsl msxslt/],
	'urn:x-suika-fam-cx:markup:ietf:html:3:draft:00'	=> ['', qw/H HTML HTML3/],
);
my %Cache;

=head1 METHODS

=over 4

=item $x = SuikaWiki::Markup::XML->new (%options)

Returns new instance of the module.  It is itself a node.

Available options: C<type> (default: C<#element>), C<local_name>, C<namespace_uri>,
C<value>.

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

=cut

sub append_node ($$) {
  my $self = shift;
  my $new_node = shift;
  die "append_node: Invalid node" unless ref $new_node;
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
  my %o = @_;
  my $new_node = __PACKAGE__->new (%o);
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
  #if (@{$self->{node}}[-1]->{type} eq '#text') {
  #  $self->{node}}[-1]->append_new_node (type => '#text', value => $s);
  #} else {
    $self->append_new_node (type => '#text', value => $s);
  #}
}

=item $attr_node = $x->get_attribute ($local_name, %options)

Returns the attribute node whose local-name is C<$local_name>.

Available options: C<namespace_uri>, C<make_new_node>.

=cut

sub get_attribute ($$;%) {
  my $self = shift;
  my ($name, %o) = @_;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute' && $_->{local_name} eq $name && $o{namespace_uri} eq $_->{namespace_uri}) {
      return $_;
    }
  }
  ## Node is not exist
  if ($o{make_new_node}) {
    return $self->append_new_node (type => '#attribute', local_name => $name, namespace_uri => $o{namespace_uri});
  } else {
    return undef;
  }
}

=item $attr_node = $x->set_attribute ($local_name => $value, %options)

Set the value of the attribute.  The attribute node is returned.

Available options: C<namespace_uri>.

=cut

sub set_attribute ($$$;%) {
  my $self = shift;
  my ($name, $val, %o) = @_;
  for (@{$self->{node}}) {
    if ($_->{type} eq '#attribute' && $_->{local_name} eq $name && $o{namespace_uri} eq $_->{namespace_uri}) {
      $_->{value} = $val;
      $_->{node} = [];
      return $_;
    }
  }
  return $self->append_new_node (type => '#attribute', local_name => $name, value => $val, namespace_uri => $o{namespace_uri});
}

=item \@children = $x->child_nodes

Returns an array reference to child nodes.

=item $local_name = $x->local_name

Returns the local-name.

=item $type = $x->node_type

Returns the node type.

=item $node = $x->parent_node

Returns the parent node.  If there is no parent node, undef is returned.

=cut

sub child_nodes ($) { shift->{node} }
sub local_name ($) { shift->{local_name} }
sub node_type ($) { shift->{type} }
sub parent_node ($) { shift->{parent} }

=item $i = $x->count

Returns the number of child nodes.

=cut

# TODO: support counting by type
sub count ($;@) {
  scalar @{shift->{node}};
}

# $prefix = $x->_get_namespace_prefix ($namespace_uri)
sub _get_namespace_prefix ($$;%) {
  my ($self, $uri) = (shift, shift);
  my %o = @_;
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
    while ($u_r_i =~ s/([A-Za-z][0-9A-Za-z-]+)[^0-9A-Za-z-]*$//) {
      my $p_f_x = $1 . ':';
      next if uc (substr ($p_f_x, 0, 3)) eq 'XML';
      unless ($self->_prefix_to_uri ($p_f_x)) {
        $pfx = $p_f_x;
        last;
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

# $uri or undef = $x->_prefix_to_uri ($prefix => [$new_uri])
sub _prefix_to_uri ($$;$%) {
  my ($self, $prefix, $new_uri, %o) = @_;
  return undef unless $self->_check_namespace_prefix ($prefix);
  if ($new_uri) {
    $self->{ns}->{$prefix} = $new_uri;
  }
  if (uc (substr $prefix, 0, 3) eq 'XML') {
    return 'http://www.w3.org/XML/1998/namespace' if $prefix eq 'xml:';
    return 'http://www.w3.org/2000/xmlns/' if $prefix eq 'xmlns:';
  } if (defined $self->{ns}->{$prefix}) {
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
    return 'xml:' if $uri eq 'http://www.w3.org/XML/1998/namespace';
    return 'xmlns:' if $uri eq 'http://www.w3.org/2000/xmlns/';
    for (keys %{$self->{ns}||{}}) {
      next if ($_ eq '') && !(!defined $o{use_no_prefix} || $o{use_no_prefix});
      return $_ if $self->{ns}->{$_} eq $uri;
    }
    if (ref $self->{parent}) {
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

sub define_new_namespace ($$$) {
  my ($self, $prefix, $uri) = @_;
  if ($prefix eq '' || $self->_check_ncname ($prefix)) {
    $prefix .= ':' if $prefix && substr ($prefix, -1) ne ':';
    $self->_prefix_to_uri ($prefix => $uri);
  } else {
    undef;
  }
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

=item $tag = $x->start_tag

Returns the start tag (or something that marks the start of something, such as '<!-- '
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
    '<!-- ';
  } elsif ($self->{type} eq '#pi' && $self->_check_ncname ($self->{local_name})) {
    '<?' . $self->{local_name};
  } elsif ($self->{type} eq '#declaration' && $self->_check_ncname ($self->{local_name})) {
    my $r = '<!' . $self->{local_name} . ' ';
    if ($self->{local_name} eq 'DOCTYPE' && ref $self->{parent}) {
      my $qname;
      for (@{$self->{parent}->{node}}) {
        if ($_->{type} eq '#element') {
          $qname = $_->qname;
          last if $qname;
        }
      }
      $r .= ($qname ? $qname : '#IMPLIED') . ' ';
      $r;
    }
  } else {
    '';
  }
}

=item $tag = $x->end_tag

Returns the end tag (or something that marks the end of something, such as ' -->'
for C<#comment> nodes).

=cut

sub end_tag ($) {
  my $self = shift;
  if ($self->{type} eq '#element' && $self->_check_ncname ($self->{local_name})) {
    '</' . $self->qname . '>';
  } elsif ($self->{type} eq '#comment') {
    ' -->';
  } elsif ($self->{type} eq '#pi' && $self->_check_ncname ($self->{local_name})) {
    '?>';
  } elsif ($self->{type} eq '#declaration' && $self->_check_ncname ($self->{local_name})) {
    my $r = '';
    $r .= '>';
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
  } elsif ($self->{type} eq '#pair' && $self->_check_ncname ($self->{local_name})) {
    $self->{local_name};
  } else {
    '';
  }
}

=item $tag = $x->attribute_value

Returns the attribute value.

=cut

sub attribute_value ($) {
  my $self = shift;
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    '"' . $self->_entitize ($self->inner_text) . '"';
  } elsif ($self->{type} eq '#pair' && $self->_check_ncname ($self->{local_name})) {
    my $t = $self->inner_text;
    if ($t =~ /"/) {
      if ($t =~ /'/) {
        $t =~ s/"/&quot;/g;
        return '"' . $t . '"';
      } else {
        return "'" . $t . "'";
      }
    } else {
       return '"' . $t . '"';
    }
  } else {
    '';
  }
}

=item $tag = $x->attribute

Returns the attribute (name and value pair).

=cut

sub attribute ($) {
  my $self = shift;
  if ($self->{type} eq '#attribute' && $self->_check_ncname ($self->{local_name})) {
    $self->attribute_name . '=' . $self->attribute_value;
  } elsif ($self->{type} eq '#pair' && $self->_check_ncname ($self->{local_name})) {
    $self->attribute_name . ' ' . $self->attribute_value;
  } else {
    '';
  }
}

=item $tag = $x->inner_xml

Returns the content of the node in XML syntax.  (In case of the C<#element> nodes,
element content without start- and end-tags is returned.)

Note that for not all node types the behavior of this method is defined.
For example, returned value of C<#attribute> might be unexpected one
in this version of this module.

=cut

sub inner_xml ($) {
  my $self = shift;
  my $r = '';
  if ($self->{type} eq '#comment') {
    $r = $self->inner_text;
    $r =~ s/--/-&#x45;/g;
  } elsif ($self->{type} eq '#pi') {
    if (length $self->{value}) {
      $r = ' ' . $self->{value};
      $r =~ s/\?>/?&gt;/g;
    }
    for (@{$self->{node}}) {
      if ($_->node_type eq '#attribute') {
        $r .= ' ' . $_->attribute;
      } else {
        my $s = $_->inner_text;
        $s =~ s/\?>/?&gt;/g;
        $r .= ' ' . $s if length $s;
      }
    }
  } elsif ($self->{type} eq '#declaration') {
    my ($isub, $pubid, $sysid) = ('');
    for (@{$self->{node}}) {
      if ($_->{type} eq '#pair') {
        if ($_->{local_name} eq 'PUBLIC') {
          $pubid = $_;
        } elsif ($_->{local_name} eq 'SYSTEM') {
          $sysid = $_;
        }
      } else {
        $isub .= $_->outer_xml;
      }
    }
    if ($sysid) {
      if ($pubid) {
        $r = $pubid->attribute . ' ' . $sysid->attribute_value;
      } else {
        $r = $sysid->attribute;
      }
      if ($isub) {
        $r .= " [\n" . $isub . "\n]";
      }
    } else {
      if ($isub) {
        $r = "[\n" . $isub . "\n]";
      } else {
        $r = "[]";
      }
    }
  } else {
    if ($self->{type} ne '#xml') {
      $r = $self->_entitize ($self->{value});
    } else {
      $r = $self->{value};
    }
    for (@{$self->{node}}) {
      my $nt = $_->node_type;
      if ((0||$self->{option}->{indent}) && ($nt eq '#element' || $nt eq '#comment' || $nt eq '#pi' || $nt eq '#declaration')) {
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
    $self->attribute;
  } else {
    if ((0||$self->{option}->{indent}) && $self->{type} eq '#element') {
      my $r = $self->start_tag;
      my $c = $self->inner_xml;
      if ($c) {
        $c =~ s/\n/\n  /g;
        $r .= "\n  " . $c . "\n";
      }
      $r .= $self->end_tag;
      $r;
    } else {
      $self->start_tag . $self->inner_xml . $self->end_tag;
    }
  }
}

=item $tag = $x->inner_text

Returns the text content of the node.  (In many case the returned value is same
as WinIE DOM C<inner_text ()> function's or XPath C<text()> function's.
But some classes that inherits this module might implement to return other
value (eg. to return the value of the alt attribute of html:img element).

=cut

sub inner_text ($) {
  my $self = shift;
  my $r = $self->{value};
  for (@{$self->{node}}) {
    $r .= $_->inner_text unless $_->node_type eq '#attribute';
  }
  $r;
}

{no warnings;	# prototype mismatch
*stringify = \&outer_xml;
}

# $s = $x->_entitize ($s)
sub _entitize ($$) {
  my ($self, $s) = (shift, shift);
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  $s;
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

=back

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/04/27 11:45:59 $
