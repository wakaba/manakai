## NOTE: This module will be renamed as Element.pm.

package Message::DOM::Element;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.10 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Element';
require Message::DOM::Node;

sub ____new ($$$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{namespace_uri},
   $$self->{prefix},
   $$self->{local_name}) = @_;
  $$self->{attributes} = {};
  $$self->{child_nodes} = [];
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    namespace_uri => 1,
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
    manakai_base_uri => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\${\$_[0]}->{owner_document}}->{strict_error_checking} and
              \${\$_[0]}->{manakai_read_only}) {
            report Message::DOM::DOMException
                -object => \$_[0],
                -type => 'NO_MODIFICATION_ALLOWED_ERR',
                -subtype => 'READ_ONLY_NODE_ERR';
          }
          if (defined \$_[1]) {
            \${\$_[0]}->{$method_name} = ''.\$_[1];
          } else {
            delete \${\$_[0]}->{$method_name};
          }
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

## |Node| attributes

sub attributes ($) {
  require Message::DOM::NamedNodeMap;
  return bless \\($_[0]), 'Message::DOM::NamedNodeMap::AttrMap';
} # attributes

sub base_uri ($) {
  my $self = $_[0];
  return $$self->{manakai_base_uri} if defined $$self->{manakai_base_uri};

  local $Error::Depth = $Error::Depth + 1;
  my $xb = $self->get_attribute_node_ns
    ('http://www.w3.org/XML/1998/namespace', 'base');
  unless (defined $xb) {
    $xb = $self->get_attribute_node_ns (undef, 'xml:base');
  }

  if ($xb) {
    my $v = $self->owner_document->implementation->create_uri_reference
      ($xb->value);
    if (not defined $v->uri_scheme) { # Relative reference
      my $xbbase = $xb->base_uri;
      if (defined $xbbase) {
        return $v->get_absolute_reference ($xbbase)->uri_reference;
      }
    }
    return $v->uri_reference;
  }

  my $pe = $$self->{parent_node};
  while (defined $pe) {
    my $nt = $pe->node_type;
    if ($nt == 1 or $nt == 6 or $nt == 9 or $nt == 11) {
      ## Element, Entity, Document, or DocumentFragment
      return $pe->base_uri;
    } elsif ($nt == 5) {
      ## EntityReference
      if ($pe->manakai_external) {
        return $pe->manakai_entity_base_uri;
      }
    }
    $pe = $$pe->{parent_node};
  }
  return $pe->base_uri if $pe;
  return $$self->{owner_document}->base_uri;
} # base_uri

sub local_name ($) { # TODO: HTML5 case
  return ${$_[0]}->{local_name};
} # local_name

sub manakai_local_name ($) {
  return ${$_[0]}->{local_name};
} # manakai_local_name

sub namespace_uri ($);

## The tag name of the element [DOM1, DOM2].
## Same as |Element.tagName| [DOM3].

*node_name = \&tag_name;

sub node_type () { 1 } # ELEMENT_NODE

sub prefix ($;$) {
  ## NOTE: No check for new value as Firefox doesn't do.
  ## See <http://suika.fam.cx/gate/2005/sw/prefix>.

  ## NOTE: Same as trivial setter except "" -> undef

  ## NOTE: Same as |Attr|'s |prefix|.
  
  if (@_ > 1) {
    if (${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    if (defined $_[1] and $_[1] ne '') {
      ${$_[0]}->{prefix} = ''.$_[1];
    } else {
      delete ${$_[0]}->{prefix};
    }
  }
  return ${$_[0]}->{prefix}; 
} # prefix

## The |Node| interface - method

sub clone_node ($$) {
  my ($self, $deep) = @_; ## NOTE: Deep cloning is not supported
## TODO: constructor
  my $clone = $self->owner_document->create_element_ns
      ($self->namespace_uri, [$self->prefix, $self->local_name]);
  for my $ns (keys %{$$self->{attributes}}) {
    for my $ln (keys %{$$self->{attributes}->{$ns}}) {
      my $attr = $$self->{attributes}->{$ns}->{$ln};
## TODO: Attr constructor
      my $attr_clone = $clone->owner_document->create_attribute_ns
          ($attr->namespace_uri, [$attr->prefix, $attr->local_name]);
      $attr_clone->value ($attr->value);
      $clone->set_attribute_node_ns ($attr_clone);
    }
  }
  return $clone;
} # clone_node

## The |Element| interface - attribute

sub manakai_base_uri ($;$);

## TODO: HTML5 capitalization
sub tag_name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # tag_name

## The |Element| interface - methods

sub manakai_element_type_match ($$$) {
  my ($self, $nsuri, $ln) = @_;
  if (defined $nsuri) {
    if (defined $$self->{namespace_uri} and $nsuri eq $$self->{namespace_uri}) {
      return ($ln eq $$self->{local_name});
    } else {
      return 0;
    }
  } else {
    if (not defined $$self->{namespace_uri}) {
      return ($ln eq $$self->{local_name});
    } else {
      return 0;
    }
  }
} # manakai_element_type_match

sub get_attribute {
  ## TODO
  return $_[0]->get_attribute_ns (undef, $_[1]);
}

sub get_attribute_node {
  ## TODO
  return $_[0]->get_attribute_node_ns (undef, $_[1]);
}

sub get_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return defined $$self->{attributes}->{$nsuri}->{$ln}
    ? $$self->{attributes}->{$nsuri}->{$ln}->value : undef;
} # get_attribute_ns

sub get_attribute_node_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return $$self->{attributes}->{$nsuri}->{$ln};
} # get_attribute_node_ns

sub has_attribute ($$) {
  return $_[0]->has_attribute_ns (undef, $_[1]);
}

sub has_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return defined $$self->{attributes}->{$nsuri}->{$ln};
} # has_attribute_ns

sub remove_attribute {
## TODO:
  delete ${$_[0]}->{attributes}->{''}->{$_[1]};
}

sub remove_attribute_node {
  ## TODO:
  delete ${$_[0]}->{attributes}->{$_[1]->namespace_uri}->{$_[1]->manakai_local_name};
  delete ${$_[1]}->{owner_element};
}

sub set_attribute {
  ## TODO:
  shift->set_attribute_ns (undef, [undef, $_[0]]);
}

sub set_attribute_node ($$) {
  my ($self, $new_attr) = @_;
  local $Error::Depth = $Error::Depth + 1;
  my $check = ${$$self->{owner_document}}->{strict_error_checking};
  if ($check and $$self->{owner_document} ne $new_attr->owner_document) {
    local $Error::Depth = $Error::Depth - 1;
    report Message::DOM::DOMException
        -object => $self,
        -type => 'WRONG_DOCUMENT_ERR';
  }

  my $nsuri = $$new_attr->{namespace_uri};
  $nsuri = '' unless defined $nsuri;
  my $ln = $$new_attr->{local_name};

  delete $$self->{manakai_content_attribute_list};
  my $attrs = $$self->{attributes};
  my $current = $attrs->{$nsuri}->{$ln};

  if (defined $$new_attr->{owner_element}) {
    if (defined $current and $current eq $new_attr) {
      ## No effect
      return undef; # no return value
    } else {
      local $Error::Depth = $Error::Depth - 1;
      report Message::DOM::DOMException
          -object => $self,
          -type => 'INUSE_ATTRIBUTE_ERR';
    }
  } elsif ($check and $$self->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  $attrs->{$nsuri}->{$ln} = $new_attr;
  $$new_attr->{owner_element} = $self;
  Scalar::Util::weaken ($$new_attr->{owner_element});
  $$new_attr->{specified} = 1;

  if (defined $current) {
    delete $$current->{owner_element};
    $$current->{specified} = 1;
  }
  return $current;
} # set_attribute_node

*set_attribute_node_ns = \&set_attribute_node;

## The second parameter only supports manakai extended way
## to specify qualified name - "[$prefix, $local_name]"
sub set_attribute_ns ($$$$) {
  my ($self, $nsuri, $qn, $value) = @_;
  $qn = [split /:/, $qn, 2] unless ref $qn;
  $qn = [undef, $qn->[0]] if not defined $qn->[1];
  require Message::DOM::Attr;
  my $attr = Message::DOM::Attr->____new
    ($$self->{owner_document}, $self, $nsuri, $qn->[0], $qn->[1]);
  $nsuri = '' unless defined $nsuri;
  $$self->{attributes}->{$nsuri}->{$qn->[1]} = $attr;
  $attr->value ($value);
} # set_attribute_ns

package Message::IF::Element;

package Message::DOM::Document;

sub create_element ($$) {
  my $self = $_[0];
  if ($$self->{strict_error_checking}) {
    my $xv = $self->xml_version;
    ## TODO: HTML Document ??
    if (defined $xv) {
      if ($xv eq '1.0' and
          $_[1] =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/) {
        #
      } elsif ($xv eq '1.1' and
               $_[1] =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/) {
        # 
      } else {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'INVALID_CHARACTER_ERR',
            -subtype => 'MALFORMED_NAME_ERR';
      }
    }
  }
  ## TODO: HTML5

  my $r = Message::DOM::Element->____new ($self, undef, undef, $_[1]);

  ## -- Default attributes
  {
    local $Error::Depth = $Error::Depth + 1;
    my $cfg = $self->dom_config;
    return $r
        unless $cfg->get_parameter
            (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute>);

    my $doctype = $self->doctype;
    return $r unless defined $doctype;

    my $et = $doctype->get_element_type_definition_node ($_[1]);
    return $r unless defined $et;

    my $orig_strict = $self->strict_error_checking;
    $self->strict_error_checking (0);

    my %gattr;
    my %has_attr;
    my %pfx_to_uri;
    my $copy_asis = $cfg->get_parameter
        (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree>);
    $cfg->set_parameter
        (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1);
    
    for my $at (@{$et->attribute_definitions}) {
      my $at_default = $at->default_type;
      if ($at_default == 4 or $at_default == 1) {
        # EXPLICIT_DEFAULT, FIXED_DEFAULT
        my ($nn1, $nn2) = split /:/, $at->node_name;
        if (defined $nn2) { # prefixed
          if ($nn1 eq 'xmlns') {
            ## TODO: NCName check, prefix check and NSURI check
            my $attr = $self->create_attribute_ns
                (q<http://www.w3.org/2000/xmlns/>, [$nn1, $nn2]);
            for my $at_child (@{$at->child_nodes}) {
              $attr->append_child ($at_child->clone_node (1));
            }
            $attr->manakai_attribute_type ($at->declared_type);
            my $nsuri = $attr->value;
            ## TODO: Namespace well-formedness check (NSURI), v1.1 chk
            $pfx_to_uri{$nn2} = $nsuri;
            $r->set_attribute_node_ns ($attr);
                ## NOTE: This method changes |specified| flag
            $attr->specified (0);
            $has_attr{q<http://www.w3.org/2000/xmlns/>}->{$nn2} = 1;
          } else {
            ## TODO: NCName check
            $gattr{$nn1}->{$nn2} = $at;
          }
        } else {            # no prefixed
          my $attr;
          if ($nn1 eq 'xmlns') {
            $attr = $self->create_attribute_ns
                (q<http://www.w3.org/2000/xmlns/>, 'xmlns');
            $has_attr{q<http://www.w3.org/2000/xmlns/>}->{xmlns} = 1;
          } else {
            $attr = $self->create_attribute_ns (undef, $nn1);
            ## TODO: NCName check
          }
          for my $at_child (@{$at->child_nodes}) {
            $attr->append_child ($at_child->clone_node (1));
          }
          $attr->manakai_attribute_type ($at->declared_type);
          ## TODO: Namespace well-formedness check (NSURI)
          $r->set_attribute_node_ns ($attr);
              ## NOTE: This method changes |specified| flag
          $attr->specified (0);
        }
      }
    } # attrdefs
    for my $pfx (keys %gattr) {
      my $nsuri = $pfx_to_uri{$pfx};
      unless (defined $nsuri) {
        ## TODO: Namespace well-formedness error
      }
      LN: for my $ln (keys %{$gattr{$pfx}}) {
        if ($has_attr{defined $nsuri ? $nsuri : ''}->{$ln}) {
          ## TODO: Namespace well-formedness error
          next LN;
        }
        ## TODO: NCName check, prefix check and NSURI check
        my $at = $gattr{$pfx}->{$ln};
        my $attr = $self->create_attribute_ns ($nsuri, [$pfx, $ln]);
        for my $at_child (@{$at->child_nodes}) {
          $attr->append_child ($at_child->clone_node (1));
        }
        $attr->manakai_attribute_type ($at->declared_type);
        $r->set_attribute_node_ns ($attr);
            ## NOTE: This method changes |specified| flag
        $attr->specified (0);
        $has_attr{defined $nsuri ? $nsuri : ''}->{$ln} = 1;
      } # LN
    } # pfx
    $cfg->set_parameter
        (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => $copy_asis);
    $self->strict_error_checking ($orig_strict);
  }

  return $r;
} # create_element

sub create_element_ns ($$$) {
  my $self = $_[0];
  my ($prefix, $lname);
  if (ref $_[2] eq 'ARRAY') {
    ($prefix, $lname) = @{$_[2]};
  } else {
    ($prefix, $lname) = split /:/, $_[2], 2;
    ($prefix, $lname) = (undef, $prefix) unless defined $lname;
  }

  if ($$self->{strict_error_checking}) {
    my $xv = $self->xml_version;
    ## TODO: HTML Document ?? (NOT_SUPPORTED_ERR is different from what Web browsers do)
    if (defined $xv) {
      if ($xv eq '1.0') {
        if (ref $_[2] eq 'ARRAY' or
            $_[2] =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/) {
          if (defined $prefix) {
            if ($prefix =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
              #
            } else {
              report Message::DOM::DOMException
                  -object => $self,
                  -type => 'NAMESPACE_ERR',
                  -subtype => 'MALFORMED_QNAME_ERR';
            }
          }
          if ($lname =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
            #
          } else {
            report Message::DOM::DOMException
                -object => $self,
                -type => 'NAMESPACE_ERR',
                -subtype => 'MALFORMED_QNAME_ERR';
          }
        } else {
          report Message::DOM::DOMException
              -object => $self,
              -type => 'INVALID_CHARACTER_ERR',
              -subtype => 'MALFORMED_NAME_ERR';
        }
      } elsif ($xv eq '1.1') {
        if (ref $_[2] eq 'ARRAY' or
            $_[2] =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/) {
          if (defined $prefix) {
            if ($prefix =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*\z/) {
              #
            } else {
              report Message::DOM::DOMException
                  -object => $self,
                  -type => 'NAMESPACE_ERR',
                  -subtype => 'MALFORMED_QNAME_ERR';
            }
          }
          if ($lname =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*\z/) {
            #
          } else {
            report Message::DOM::DOMException
                -object => $self,
                -type => 'NAMESPACE_ERR',
                -subtype => 'MALFORMED_QNAME_ERR';
          }
        } else {
          report Message::DOM::DOMException
              -object => $self,
              -type => 'INVALID_CHARACTER_ERR',
              -subtype => 'MALFORMED_NAME_ERR';
        }
      } else {
        die "create_attribute_ns: XML version |$xv| is not supported";
      }
    }

    if (defined $prefix) {
      if (not defined $_[1]) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'PREFIXED_NULLNS_ERR';
      } elsif ($prefix eq 'xml' and 
               $_[1] ne q<http://www.w3.org/XML/1998/namespace>) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLPREFIX_NONXMLNS_ERR';
      } elsif ($prefix eq 'xmlns' and
               $_[1] ne q<http://www.w3.org/2000/xmlns/>) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLNSPREFIX_NONXMLNSNS_ERR';
      } elsif ($_[1] eq q<http://www.w3.org/2000/xmlns/> and
               $prefix ne 'xmlns') {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'NONXMLNSPREFIX_XMLNSNS_ERR';
      }
    } else { # no prefix
      if ($lname eq 'xmlns' and
          (not defined $_[1] or $_[1] ne q<http://www.w3.org/2000/xmlns/>)) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLNS_NONXMLNSNS_ERR';
      } elsif (not defined $_[1]) {
        #
      } elsif ($_[1] eq q<http://www.w3.org/2000/xmlns/> and
               $lname ne 'xmlns') {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'NONXMLNSPREFIX_XMLNSNS_ERR';
      }
    }
  }

  ## -- Choose the most apppropriate class for the element
  my $class = 'Message::DOM::Element';
  my $nsuri = defined $_[1] ? $_[1] : '';

  ## TODO: Choose a class for $nsuri:$lname
  ## TODO: Choose a class for $nsuri:*

  my $r = $class->____new ($self, $_[1], $prefix, $lname);

  ## -- Default attributes
  {
    local $Error::Depth = $Error::Depth + 1;
    my $cfg = $self->dom_config;
    return $r
        unless $cfg->get_parameter
            (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute>);

    my $doctype = $self->doctype;
    return $r unless defined $doctype;

    my $et = $doctype->get_element_type_definition_node
        (defined $prefix ? $prefix . ':' . $lname : $lname);
    return $r unless defined $et;

    my $orig_strict = $self->strict_error_checking;
    $self->strict_error_checking (0);

    my %gattr;
    my %has_attr;
    my %pfx_to_uri;
    my $copy_asis = $cfg->get_parameter
        (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree>);
    $cfg->set_parameter
        (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1);
    
    for my $at (@{$et->attribute_definitions}) {
      my $at_default = $at->default_type;
      if ($at_default == 4 or $at_default == 1) {
        # EXPLICIT_DEFAULT, FIXED_DEFAULT
        my ($nn1, $nn2) = split /:/, $at->node_name;
        if (defined $nn2) { # prefixed
          if ($nn1 eq 'xmlns') {
            ## TODO: NCName check, prefix check and NSURI check
            my $attr = $self->create_attribute_ns
                (q<http://www.w3.org/2000/xmlns/>, [$nn1, $nn2]);
            for my $at_child (@{$at->child_nodes}) {
              $attr->append_child ($at_child->clone_node (1));
            }
            $attr->manakai_attribute_type ($at->declared_type);
            my $nsuri = $attr->value;
            ## TODO: Namespace well-formedness check (NSURI), v1.1 chk
            $pfx_to_uri{$nn2} = $nsuri;
            $r->set_attribute_node_ns ($attr);
                ## NOTE: This method changes |specified| flag
            $attr->specified (0);
            $has_attr{q<http://www.w3.org/2000/xmlns/>}->{$nn2} = 1;
          } else {
            ## TODO: NCName check
            $gattr{$nn1}->{$nn2} = $at;
          }
        } else {            # no prefixed
          my $attr;
          if ($nn1 eq 'xmlns') {
            $attr = $self->create_attribute_ns
                (q<http://www.w3.org/2000/xmlns/>, 'xmlns');
            $has_attr{q<http://www.w3.org/2000/xmlns/>}->{xmlns} = 1;
          } else {
            $attr = $self->create_attribute_ns (undef, $nn1);
            ## TODO: NCName check
          }
          for my $at_child (@{$at->child_nodes}) {
            $attr->append_child ($at_child->clone_node (1));
          }
          $attr->manakai_attribute_type ($at->declared_type);
          ## TODO: Namespace well-formedness check (NSURI)
          $r->set_attribute_node_ns ($attr);
              ## NOTE: This method changes |specified| flag
          $attr->specified (0);
        }
      }
    } # attrdefs
    for my $pfx (keys %gattr) {
      my $nsuri = $pfx_to_uri{$pfx};
      unless (defined $nsuri) {
        ## TODO: Namespace well-formedness error
      }
      LN: for my $ln (keys %{$gattr{$pfx}}) {
        if ($has_attr{defined $nsuri ? $nsuri : ''}->{$ln}) {
          ## TODO: Namespace well-formedness error
          next LN;
        }
        ## TODO: NCName check, prefix check and NSURI check
        my $at = $gattr{$pfx}->{$ln};
        my $attr = $self->create_attribute_ns ($nsuri, [$pfx, $ln]);
        for my $at_child (@{$at->child_nodes}) {
          $attr->append_child ($at_child->clone_node (1));
        }
        $attr->manakai_attribute_type ($at->declared_type);
        $r->set_attribute_node_ns ($attr);
            ## NOTE: This method changes |specified| flag
        $attr->specified (0);
        $has_attr{defined $nsuri ? $nsuri : ''}->{$ln} = 1;
      } # LN
    } # pfx
    $cfg->set_parameter
        (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => $copy_asis);
    $self->strict_error_checking ($orig_strict);
  }

  return $r;
} # create_element_ns

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 07:59:02 $
