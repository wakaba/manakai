
=head1 NAME

SuikaWiki::Markup::XML::DOM::Core --- SuikaWiki: Simple DOM implementation for SuikaWiki::Markup::XML

=head1 DESCRIPTION

...

This module is part of SuikaWiki.

=cut

package SuikaWiki::Markup::XML::DOM::Core;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require SuikaWiki::Markup::XML::DOM;

=head1 METHODS

WARNING: This module is under construction.  Interface of this module is not yet fixed.

=cut

package SuikaWiki::Markup::XML::DOM::Core::DOMImplementation;
push @SuikaWiki::Markup::XML::DOM::ISA, __PACKAGE__;
our @ISA;

sub hasFeature ($$;$) {
  my ($self, $feature, $version) = @_;
  my $f = $SuikaWiki::Markup::XML::DOM::Feature{lc $feature};
  if (ref $f && defined $version && $f->{$version}->{implemented}) {
    return 1;
  } elsif (ref $f && !defined $version) {	## When at least one of versions is implemented
    for (keys %$f) {
      return 1 if $f->{$_}->{implemented};
    }
  }
  return 0;
}

## TODO: $docType is not implemented
sub createDocument ($$$$) {
  my ($self, $nsURI, $qName, $docType) = @_;
  unless ($self->_check_qname ($qName)) {
    $self->_raise_exception (DOMException=>'INVALID_CHAR_ERR', t => $qName);
  } elsif ($qName =~ /^([^:]+):([^:]+)$/) {
    my ($pfx, $lname) = ($1, $2);
    $self->_raise_exception (DOMException=>'NAMESPACE_ERR', t => ($pfx||$nsURI))
      unless $self->_check_ns ($pfx, $nsURI);
    $self->_raise_exception (DOMException=>'NAMESPACE_ERR', t => $nsURI)
      if $pfx && !defined $nsURI;
  }
  my $d = bless {}, 'SuikaWiki::Markup::XML::DOM::Core::Document';
  $d->{d_implementation} = $self;
  $d->{flag}->{dom_ownerDocument} = $d;
  $d->{nodeObject} = SuikaWiki::Markup::XML->new (type => '#document');
  for ($d->{nodeObject}) {
    for ($_->append_new_node (type => '#pi', local_name => 'xml')) {
      $_->set_attribute (version => '1.0');
    }
    $_->append_text ("\n");
    $_->append_new_node (type => '#element', namespace_uri => $nsURI, qname => $qName);
    $_->append_text ("\n");
  }
  $d->{flag}->{dom_node_created_level} = 2;
  $d;
}

package SuikaWiki::Markup::XML::DOM::Core::Node;
use overload '""' => sub {shift->{nodeObject}->stringify},
             fallback => 1;

sub nodeName ($) {
  my $self = shift;
  my $type = $self->{nodeObject}->node_type;
  if ($type eq '#element' || $type eq '#attribute') {
    return $self->{nodeObject}->qname;
  } elsif ($type eq '#text') {
    return '#text'
  } elsif ($type eq '#section' && $self->{nodeObject}->local_name eq 'CDATA') {
    ## TODO: new data model of S::M::XML
    return '#cdata-section'
  } elsif ($type eq '#comment') {
    return '#comment'
  } elsif ($type eq '#document') {
    return '#document'
  } elsif ($type eq '#fragment') {
    return '#document-fragment'
  } elsif ($type eq '#declaration' && $self->{nodeObject}->namespace_uri eq $self->_NS->{SGML}.'doctype') {
    #return # name of document element
  } elsif ($type eq '#entity' || $type eq '#reference' || $type eq '#pi') {
    return $self->{nodeObject}->local_name;
  }
}

sub firstChild ($) {
  my $self = shift;
  for (@{$self->{nodeObject}->child_nodes}) {
    return $_ if $_->node_type ne '#attribute';
  }
  return undef;
}

sub lastChild ($) {
  my $self = shift;
  for (reverse @{$self->{nodeObject}->child_nodes}) {
    return $_ if $_->node_type ne '#attribute';
  }
  return undef;
}

sub localName ($) {
  my $self = shift;
  return undef if $self->{flag}->{dom_node_created_level} == 1
               || !{'#element'=>1,'#attribute'=>1}->{$self->{nodeObject}->node_type};
  $self->{nodeObject}->local_name;
}

sub namespaceURI ($) {
  my $self = shift;
  return undef if $self->{flag}->{dom_node_created_level} == 1
               || !{'#element'=>1,'#attribute'=>1}->{$self->{nodeObject}->node_type};
  $self->{nodeObject}->namespace_uri;
}

sub appendChild ($$) {
  my ($self, $newChild) = @_;
  ## Ensure $newChild is same document's
  unless (overload::StrVal ($newChild->{flag}->{dom_ownerDocument})
       eq overload::StrVal ($self->{flag}->{dom_ownerDocument})) {
    $self->_raise_exception (DOMException=>'WRONG_DOCUMENT_ERR');
  }
  ## Check $self is readonly or not
  #NO_MODIFICATION_ALLOWED_ERR
  ## Check relation between $self and $newChild
  #HIERARCHY_REQUEST_ERR
  ##BUG: #document-fragment
  ## Removing link to $newChild in the tree
  
  ## Append $newChild
  $self->{nodeObject}->append_node ($newChild->{nodeObject});
  $newChild;
}

sub removeChild ($$) {
  my ($self, $oldChild) = @_;
  my $children = $self->{nodeObject}->child_nodes;
  ## Check $self is readonly or not
  # NO_MODIFICATION_ALLOWED_ERR
  ## Seek $oldChild
  for my $i (0..$#$children) {
    #$ TODO: check $children->[$i] is DOM-children or not
    if (overload::StrVal ($children->[$i]) eq overload::StrVal ($oldChild->{nodeObject})) {
      my $oldNode = $children->[$i];
      splice (@$children, $i, 1);
      ## TODO: use public interface, not private interface here
      $oldNode->{parent} = undef;
      return $oldChild;
    }
  }
  $self->_raise_exception (DOMException=>'NOT_FOUND_ERR');
}

sub hasAttributes ($) {
  my $self = shift;
  for (@{$self->{nodeObject}->child_nodes}) {
    return 1 if $_->node_type eq '#attribute';
  }
  ## TODO: support namespace attr!
  return 0;
}

## TODO: more strict!
sub hasChildren ($) {
  my $self = shift;
  for (@{$self->{nodeObject}->child_nodes}) {
    return 1 if {
    	## BUG: CDATA section
    	'#comment'	=> 1,
    	'#element'	=> 1,
    	'#pi'	=> 1,
    	'#reference'	=> 1,
    	'#text'	=> 1,
    }->{$_->node_type};
  }
  return 0;
}

## TODO: implement this method
sub isSupported ($$;$) {
  return 0;
}

package SuikaWiki::Markup::XML::DOM::Core::Document;
our @ISA; push @ISA, 'SuikaWiki::Markup::XML::DOM::Core::Node';

# attr readonly Document.doctype
sub doctype ($) {
  my $self = shift;
  for (@{$self->{nodeObject}->child_nodes}) {
    if ($_->node_type eq '#declaration') {
      return $self->_create_dom_node_from_node_object ($_, $self);
    }
  }
}

# attr readonly Document.implementation
sub implementation ($) {
  shift->{d_implementation};
}

# attr readonly Document.implementation
sub documentElement ($) {
  my $self = shift;
  for (@{$self->{nodeObject}->child_nodes}) {
    if ($_->node_type eq '#element') {
      return $self->_create_dom_node_from_node_object ($_, $self);
    }
  }
}

# method Document.createElement (elementTypeName)
sub createElement ($$) {
  my ($self, $elementTypeName) = @_;
  $self->_raise_exception (implementation=>'WARNING_USE_NS_VER', t => 'createElement');
  unless ($self->_check_ncname ($elementTypeName)) {
    unless ($self->_check_qname ($elementTypeName)) {
      $self->_raise_exception (DOMException=>'INVALID_CHARACTER_ERR', t => $elementTypeName);
    } else {
      $self->_raise_exception (implementation=>'WARNING_INVALID_AS_QNAME', t => $elementTypeName);
      ## Note: Since SuikaWiki::Markup::XML does not support XML document without namespace,
      ##       use of QName with this method is discouraged.
    }
    ## BUG: Strictly speaking, this method should accept invalid-QName-but-valid-Names
    ##      such as ':foo' or 'abc::def'', since SuikaWiki::Markup::XML does not support them.
    ##      Those names are invalid as namespaced XML document so that should not be used.
  }
  my $n = ref ($self->{nodeObject})->new (type => '#element', qname => $elementTypeName);
  my $nn = $self->_create_dom_node_from_node_object ($n, $self);
  $nn->{flag}->{dom_node_created_level} = 1;
  $nn;
}

# method Document.createElementNS (nsURI, elementTypeName)
sub createElementNS ($$) {
  my ($self, $nsURI, $elementTypeName) = @_;
  unless ($self->_check_qname ($elementTypeName)) {
    $self->_raise_exception (DOMException=>'INVALID_CHARACTER_ERR', t => $elementTypeName);
  } else {
    my $prefix = '';
    $prefix = $1 if $elementTypeName =~ /^([^:]+):/;
    $self->_raise_exception (DOMException=>'NAMESPACE_ERR', t => ($prefix||$nsURI))
      unless $self->_check_ns ($prefix, $nsURI);
    $self->_raise_exception (DOMException=>'NAMESPACE_ERR', t => ($prefix||$nsURI))
      if $prefix && !defined $nsURI;
    $self->_raise_exception (implementation=>'WARNING_INVALID_NS_URI', t => $prefix) if $prefix && !$nsURI;
  }
  my $n = ref ($self->{nodeObject})->new (type => '#element', qname => $elementTypeName, namespace_uri => $nsURI);
  my $nn = $self->_create_dom_node_from_node_object ($n, $self);
  $nn->{flag}->{dom_node_created_level} = 2;
  $nn;
}

# method Document.createTextNode (nsURI, data)
sub createTextNode ($$) {
  my ($self, $data) = @_;
  my $n = ref ($self->{nodeObject})->new (type => '#text', value => $data);
  my $nn = $self->_create_dom_node_from_node_object ($n, $self);
  $nn->{flag}->{dom_node_created_level} = 1;
  $nn;
}

package SuikaWiki::Markup::XML::DOM::Core::Element;
our @ISA; push @ISA, 'SuikaWiki::Markup::XML::DOM::Core::Node';

package SuikaWiki::Markup::XML::DOM::Core::Text;
our @ISA; push @ISA, 'SuikaWiki::Markup::XML::DOM::Core::Node';

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/06/16 09:58:26 $
