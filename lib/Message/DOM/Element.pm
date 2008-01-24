## NOTE: This module will be renamed as Element.pm.

package Message::DOM::Element;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.29 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Element',
    'Message::IF::ElementSelector', # MUST in Selectors API spec.
    'Message::IF::ElementCSSInlineStyle';
require Message::DOM::Document;

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
  } elsif (my $module_name = {
    query_selector => 'Message::DOM::SelectorsAPI',
    query_selector_all => 'Message::DOM::SelectorsAPI',
  }->{$method_name}) {
    eval qq{ require $module_name } or die $@;
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## TODO: Test for create_element_ns ('', ...)

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

## |Element| attributes

sub manakai_base_uri ($;$);

## Defined in |HTMLElement| interface of HTML5
sub inner_html ($;$) {
  my $self = $_[0];

  ## TODO: Setter

  if (${$$self->{owner_document}}->{manakai_is_html}) {
    require Whatpm::HTML::Serializer;
    return ${ Whatpm::HTML::Serializer->get_inner_html ($self) };
  } else {
    ## TODO: This serializer is not currenly conformant to HTML5.
    require Whatpm::XMLSerializer;
    my $r = '';
    for (@{$self->child_nodes}) {
      $r .= ${ Whatpm::XMLSerializer->get_outer_xml ($_) };
    }
    return $r;
  }
} # inner_html

sub schema_type_info ($) {
  require Message::DOM::TypeInfo;
  my $v = 0;
  return bless \$v, 'Message::DOM::TypeInfo';
## NOTE: Currently manakai does not support XML Schema, so it is 
## always a no-type |TypeInfo|.  It is expected that
## a future version of the implementation will return an
## element type definition node that also implement the
## |TypeInfo| interface when the schema language is XML DTD.
} # schema_type_info

## TODO: HTML5 capitalization
sub tag_name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # tag_name

## TODO: Documentation
sub manakai_tag_name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # manakai_tag_name

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

sub get_attribute ($$) {
  my $attr = ${$_[0]}->{attributes};
  my $name = ''.$_[1];

  ## NOTE: |sort|ing is required so that every |getAttribute|, |setAttribute|,
  ## |hasAttribute|, |removeAttribute|, or any other namespace unaware
  ## methods operates on the same node even if there is 
  ## multiple nodes with the same qualified name.

  ## NOTE: Same as |get_attribute_node|, except what is returned.

  for my $ns (sort {$a cmp $b} keys %$attr) {
    for my $ln (sort {$a cmp $b} keys %{$attr->{$ns}}) {
      my $node = $attr->{$ns}->{$ln};
      if ($node->manakai_name eq $name) {
        return $node->value;
      }
    }
  }

  return undef;
} # get_attribute

sub get_attribute_node ($$) {
  my $attr = ${$_[0]}->{attributes};
  my $name = ''.$_[1];

  ## NOTE: Same as |get_attribute|, except what is returned.

  for my $ns (sort {$a cmp $b} keys %$attr) {
    for my $ln (sort {$a cmp $b} keys %{$attr->{$ns}}) {
      my $node = $attr->{$ns}->{$ln};
      if ($node->manakai_name eq $name) {
        return $node;
      }
    }
  }

  return undef;
} # get_attribute_node

sub get_attribute_ns ($$$) {
  my $nsuri = defined $_[1] ? ''.$_[1] : '';
  my $ln = ''.$_[2];
  if (my $attr = ${$_[0]}->{attributes}->{$nsuri}->{$ln}) {
    return $attr->value;
  } else {
    return undef;
  }
} # get_attribute_ns

sub get_attribute_node_ns ($$$) {
  return ${$_[0]}->{attributes}->{defined $_[1] ? ''.$_[1] : ''}->{''.$_[2]};
} # get_attribute_node_ns

*get_elements_by_tag_name = \&Message::DOM::Document::get_elements_by_tag_name;

*get_elements_by_tag_name_ns
    = \&Message::DOM::Document::get_elements_by_tag_name_ns;

sub has_attribute ($$) {
  my $attr = ${$_[0]}->{attributes};
  my $name = ''.$_[1];

  for my $ns (keys %$attr) {
    for my $ln (keys %{$attr->{$ns}}) {
      my $node = $attr->{$ns}->{$ln};
      if ($node->manakai_name eq $name) {
        return 1;
      }
    }
  }

  return 0;
} # has_attribute

sub has_attribute_ns ($$$) {
  return ${$_[0]}->{attributes}->{defined $_[1] ? ''.$_[1] : ''}->{''.$_[2]}?1:0;
} # has_attribute_ns

sub remove_attribute ($$) {
  my $attr = ${$_[0]}->{attributes};
  my $name = ''.$_[1];

  my $list;
  my $key;
  my $attr_node;
  ATTR: {
    for my $ns (keys %$attr) {
      $list = $attr->{$ns};
      for my $ln (keys %$list) {
        $attr_node = $list->{$ln};
        if ($attr_node->manakai_name eq $name) {
          $key = $ln;
          last ATTR;
        }
      }
    }
    
    return undef; # not found
  } # ATTR

  my $od = ${$_[0]}->{owner_document};
  if ($$od->{strict_error_checking} and ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  delete $list->{$key};
  delete $$attr_node->{owner_element};
  $$attr_node->{specified} = 1;
  delete ${$_[0]}->{manakai_content_attribute_list};

  ## Default attribute
  local $Error::Depth = $Error::Depth + 1;
  my $cfg = $od->dom_config;
  if ($cfg->get_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute>)) {
    my $doctype = $od->doctype;
    if ($doctype) {
      my $et = $doctype->get_element_type_definition_node
          ($_[0]->manakai_tag_name);
      if ($et) {
        my $at = $et->get_attribute_definition_node ($name);
        if ($at) {
          local $$od->{strict_error_checking} = 0;
          my $copy_asis = $cfg->get_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree>);
          $cfg->set_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1);
          ADD: {
            my $def_attr_node;
            my $def_prefix = $attr_node->prefix;
            my $def_nsuri = '';
            my $def_ln;
            if (defined $def_prefix) {
              $def_nsuri =
                  $def_prefix eq 'xml' ? q<http://www.w3.org/XML/1998/namespace>:
                  $def_prefix eq 'xmlns' ? q<http://www.w3.org/2000/xmlns/>:
                  $_[0]->lookup_namespace_uri ($def_prefix);
              unless (defined $def_nsuri) {
                ## TODO: Namespace well-formedness error...
              }
              $def_ln = $attr_node->manakai_local_name;
            } else {
              $def_nsuri = $name eq 'xmlns'
                  ? q<http://www.w3.org/2000/xmlns/> : undef;
              $def_ln = $name;
            }
            if ($attr->{defined $def_nsuri ? $def_nsuri : ''}->{$def_ln}) {
              ## TODO: Namespace well-formedness warning?
              last ADD;
            }
            $def_attr_node = $od->create_attribute_ns
                ($def_nsuri, [$def_prefix, $def_ln]);
          
            for my $child (@{$at->child_nodes}) {
              $def_attr_node->append_child ($child->clone_node (1));
            }
            $def_attr_node->manakai_attribute_type ($at->declared_type);
            $attr->{defined $def_nsuri ? $def_nsuri : ''}->{$def_ln}
                = $def_attr_node;
            $$def_attr_node->{owner_element} = $_[0];
            Scalar::Util::weaken ($$def_attr_node->{owner_element});
            delete $$def_attr_node->{specified};
          } # ADD
          $cfg->set_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => $copy_asis);
        }
      }
    }
  }

  return undef;
} # remove_attribute

sub remove_attribute_node ($$) {
  my $od = ${$_[0]}->{owner_document};
  if ($$od->{strict_error_checking} and ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $attr_node = $_[1];
  my $ln = $attr_node->manakai_local_name;
  my $attr = ${$_[0]}->{attributes};
  FIND: {
    my $nsuri = $attr_node->namespace_uri;
    my $list = $attr->{defined $nsuri ? $nsuri : ''};
    my $list_node = $list->{$ln};
    if (defined $list_node and $list_node eq $attr_node) {
      delete $list->{$ln};
      last FIND;
    }

    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  } # FIND

  delete ${$_[0]}->{manakai_content_attribute_list};
  delete $$attr_node->{owner_element};
  $$attr_node->{specified} = 1;
      
  ## Default attribute
  ## Same as |remove_attribute|'s, except where marked as "***".
  local $Error::Depth = $Error::Depth + 1;
  my $cfg = $od->dom_config;
  if ($cfg->get_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute>)) {
    my $doctype = $od->doctype;
    if ($doctype) {
      my $et = $doctype->get_element_type_definition_node
          ($_[0]->manakai_tag_name);
      if ($et) {
        my $at = $et->get_attribute_definition_node ($_[1]->manakai_name); # ***
        if ($at) {
          local $$od->{strict_error_checking} = 0;
          my $copy_asis = $cfg->get_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree>);
          $cfg->set_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1);
          ADD: {
            my $def_attr_node;
            my $def_prefix = $attr_node->prefix;
            my $def_nsuri = '';
            my $def_ln;
            if (defined $def_prefix) {
              $def_nsuri =
                  $def_prefix eq 'xml' ? q<http://www.w3.org/XML/1998/namespace>:
                  $def_prefix eq 'xmlns' ? q<http://www.w3.org/2000/xmlns/>:
                  $_[0]->lookup_namespace_uri ($def_prefix);
              unless (defined $def_nsuri) {
                ## TODO: Namespace well-formedness error...
              }
              $def_ln = $attr_node->manakai_local_name;
            } else {
              $def_nsuri = $attr_node->manakai_name eq 'xmlns'
                  ? q<http://www.w3.org/2000/xmlns/> : undef;
              $def_ln = $attr_node->manakai_local_name; ## ***
            }
            if ($attr->{defined $def_nsuri ? $def_nsuri : ''}->{$def_ln}) {
              ## TODO: Namespace well-formedness warning?
              last ADD;
            }
            $def_attr_node = $od->create_attribute_ns
                ($def_nsuri, [$def_prefix, $def_ln]);
          
            for my $child (@{$at->child_nodes}) {
              $def_attr_node->append_child ($child->clone_node (1));
            }
            $def_attr_node->manakai_attribute_type ($at->declared_type);
            $attr->{defined $def_nsuri ? $def_nsuri : ''}->{$def_ln}
                = $def_attr_node;
            $$def_attr_node->{owner_element} = $_[0];
            Scalar::Util::weaken ($$def_attr_node->{owner_element});
            delete $$def_attr_node->{specified};
          } # ADD
          $cfg->set_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => $copy_asis);
        }
      }
    }
  }

  return $_[1];
} # remove_attribute_node

sub remove_attribute_ns ($$$) {
  my $attr = ${$_[0]}->{attributes};

  my $list = $attr->{defined $_[1] ? $_[1] : ''};
  my $key = ''.$_[2];
  my $attr_node = $list->{$key};
  return undef unless defined $attr_node;

  ## NOTE: Anything below is same as |remove_attribute|'s except "***"

  my $od = ${$_[0]}->{owner_document};
  if ($$od->{strict_error_checking} and ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  delete $list->{$key};
  delete $$attr_node->{owner_element};
  $$attr_node->{specified} = 1;
  delete ${$_[0]}->{manakai_content_attribute_list};

  ## Default attribute
  local $Error::Depth = $Error::Depth + 1;
  my $cfg = $od->dom_config;
  if ($cfg->get_parameter 
      (q<http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute>)) {
    my $doctype = $od->doctype;
    if ($doctype) {
      my $et = $doctype->get_element_type_definition_node
          ($_[0]->manakai_tag_name);
      if ($et) {
        my $at = $et->get_attribute_definition_node
            ($attr_node->manakai_name); # ***
        if ($at) {
          local $$od->{strict_error_checking} = 0;
          my $copy_asis = $cfg->get_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree>);
          $cfg->set_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => 1);
          ADD: {
            my $def_attr_node;
            my $def_prefix = $attr_node->prefix;
            my $def_nsuri = '';
            my $def_ln;
            if (defined $def_prefix) {
              $def_nsuri =
                  $def_prefix eq 'xml' ? q<http://www.w3.org/XML/1998/namespace>:
                  $def_prefix eq 'xmlns' ? q<http://www.w3.org/2000/xmlns/>:
                  $_[0]->lookup_namespace_uri ($def_prefix);
              unless (defined $def_nsuri) {
                ## TODO: Namespace well-formedness error...
              }
            } else {
              $def_nsuri = $attr_node->manakai_name eq 'xmlns'
                  ? q<http://www.w3.org/2000/xmlns/> : undef;
            }
            $def_ln = $attr_node->manakai_local_name; # ***
            if ($attr->{defined $def_nsuri ? $def_nsuri : ''}->{$def_ln}) {
              ## TODO: Namespace well-formedness warning?
              last ADD;
            }
            $def_attr_node = $od->create_attribute_ns
                ($def_nsuri, [$def_prefix, $def_ln]);
          
            for my $child (@{$at->child_nodes}) {
              $def_attr_node->append_child ($child->clone_node (1));
            }
            $def_attr_node->manakai_attribute_type ($at->declared_type);
            $attr->{defined $def_nsuri ? $def_nsuri : ''}->{$def_ln}
                = $def_attr_node;
            $$def_attr_node->{owner_element} = $_[0];
            Scalar::Util::weaken ($$def_attr_node->{owner_element});
            delete $$def_attr_node->{specified};
          } # ADD
          $cfg->set_parameter
              (q<http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree> => $copy_asis);
        }
      }
    }
  }

  return undef;
} # remove_attribute_ns

sub set_attribute ($$$) {
  my $od = ${$_[0]}->{owner_document};
  if ($$od->{strict_error_checking}) {
    if (${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
  }

  my $name = ''.$_[1];
  my $attr = ${$_[0]}->{attributes};  
  my $attr_node;
  NS: for my $ns (keys %$attr) {
    for my $ln (keys %{$attr->{$ns}}) {
      my $node = $attr->{$ns}->{$ln};
      if ($node->manakai_name eq $name) {
        $attr_node = $node;
        last NS;
      }
    }
  }
  
  local $Error::Depth = $Error::Depth + 1;
  if (defined $attr_node) {
    if ($$od->{strict_error_checking}) {
      $od->create_attribute ($name); # or exception
    }
  } else {
    $attr_node = $od->create_attribute ($name); # return or exception
    delete ${$_[0]}->{manakai_content_attribute_list};
    $attr->{''}->{$name} = $attr_node;
    $$attr_node->{owner_element} = $_[0];
    Scalar::Util::weaken ($$attr_node->{owner_element});

    if ($od->dom_config->get_parameter
          (q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type>)) {
      my $doctype = $od->doctype;
      if (defined $doctype) {
        my $et = $doctype->get_element_type_definition_node
            ($_[0]->manakai_tag_name);
        if (defined $et) {
          my $at = $et->get_attribute_definition_node ($attr_node->manakai_name);
          if (defined $at) {
            $attr_node->manakai_attribute_type ($at->declared_type);
          }
        }
      }
    }
  }

  $attr_node->value ($_[2]); # set or exception
  $attr_node->specified (1);
  return undef;
} # set_attribute

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
## to specify qualified name - "[$prefix, $local_name]" ## TODO: Document
sub set_attribute_ns ($$$$) {
  my $prefix;
  my $lname;
  if (ref $_[2] eq 'ARRAY') {
    ($prefix, $lname) = @{$_[2]};
  } else {
    ($prefix, $lname) = split /:/, $_[2], 2;
    ($prefix, $lname) = (undef, $prefix) unless defined $lname;
  }

  my $od = ${$_[0]}->{owner_document};
  if ($$od->{strict_error_checking}) {
    if (${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
  }

  my $attr = ${$_[0]}->{attributes};  
  my $attr_node = $attr->{defined $_[1] ? ''.$_[1] : ''}->{$lname};
  
  local $Error::Depth = $Error::Depth + 1;
  if (defined $attr_node) {
    if ($$od->{strict_error_checking}) {
      $od->create_attribute_ns ($_[1], [$prefix, $lname]); # name exception
    }
  } else {
    $attr_node = $od->create_attribute_ns
        ($_[1], [$prefix, $lname]); # or exception
    delete ${$_[0]}->{manakai_content_attribute_list};
    $attr->{defined $_[1] ? ''.$_[1] : ''}->{$lname} = $attr_node;
    $$attr_node->{owner_element} = $_[0];
    Scalar::Util::weaken ($$attr_node->{owner_element});

    if ($od->dom_config->get_parameter
          (q<http://suika.fam.cx/www/2006/dom-config/dtd-attribute-type>)) {
      my $doctype = $od->doctype;
      if (defined $doctype) {
        my $et = $doctype->get_element_type_definition_node
            ($_[0]->manakai_tag_name);
        if (defined $et) {
          my $at = $et->get_attribute_definition_node ($attr_node->manakai_name);
          if (defined $at) {
            $attr_node->manakai_attribute_type ($at->declared_type);
          }
        }
      }
    }
  }

  $attr_node->value ($_[3]); # set or exception
  $attr_node->prefix ($prefix);
  $attr_node->specified (1);
  return undef;
} # set_attribute_ns

sub set_id_attribute ($$$) {
  if (${${$_[0]}->{owner_document}}->{strict_error_checking} and
      ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }
  
  my $attr = $_[0]->get_attribute_node ($_[1]);
  if (not defined $attr) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  } else {
    local $Error::Depth = $Error::Depth + 1;
    $attr->is_id ($_[2]); # or exception
  }
  return;
} # set_id_attribute

sub set_id_attribute_ns ($$$$) {
  if (${${$_[0]}->{owner_document}}->{strict_error_checking} and
      ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }
  
  my $attr = $_[0]->get_attribute_node_ns ($_[1], $_[2]);
  if (not defined $attr) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  } else {
    local $Error::Depth = $Error::Depth + 1;
    $attr->is_id ($_[2]);
  }
  return;
} # set_id_attribute_ns

sub set_id_attribute_node ($$$$) {
  if (${${$_[0]}->{owner_document}}->{strict_error_checking} and
      ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $oe = $_[1]->owner_element;  
  if ($oe ne $_[0]) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  } else {
    local $Error::Depth = $Error::Depth + 1;
    $_[1]->is_id ($_[2]);
  }
  return;
} # set_id_attribute_node

## |ElementSelector| methods

sub query_selector ($$;$);

sub query_selector_all ($$;$);

## |ElementCSSInlineStyle| attributes

## TODO: documentation
sub manakai_computed_style ($) {
  ## TODO: If not part of document tree

  ## ISSUE: Neither |getComputedStyle| nor |currentStyle| represent
  ## the set of computed values in the real world (in fact what is
  ## represented by them disagree in browsers and even |getComputedStyle|
  ## and |currentStyle| are different in the same Opera browser).
  
  local $Error::Depth = $Error::Depth + 1;
  my $self = shift;
  my $view = $self->owner_document->default_view;
  return undef unless defined $view;  ## ISSUE: Not defined in the spec yet.
  
  return $view->manakai_get_computed_style ($self);
} # manakai_computed_style

## TODO: |current_style|, |style|, |runtime_style|

package Message::IF::Element;
package Message::IF::ElementSelector;
package Message::IF::ElementCSSInlineStyle;

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
  my $nsuri = defined $_[1] ? $_[1] eq '' ? undef : $_[1] : undef;

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
      if (not defined $nsuri) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'PREFIXED_NULLNS_ERR';
      } elsif ($prefix eq 'xml' and 
               $nsuri ne q<http://www.w3.org/XML/1998/namespace>) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLPREFIX_NONXMLNS_ERR';
      } elsif ($prefix eq 'xmlns' and
               $nsuri ne q<http://www.w3.org/2000/xmlns/>) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLNSPREFIX_NONXMLNSNS_ERR';
      } elsif ($nsuri eq q<http://www.w3.org/2000/xmlns/> and
               $prefix ne 'xmlns') {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'NONXMLNSPREFIX_XMLNSNS_ERR';
      }
    } else { # no prefix
      if ($lname eq 'xmlns' and
          (not defined $nsuri or $nsuri ne q<http://www.w3.org/2000/xmlns/>)) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLNS_NONXMLNSNS_ERR';
      } elsif (not defined $nsuri) {
        #
      } elsif ($nsuri eq q<http://www.w3.org/2000/xmlns/> and
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
  if (defined $nsuri) {
    if ($nsuri eq q<http://www.w3.org/1999/xhtml>) {
      require Message::DOM::HTML::HTMLElement;
      $class = {
        a => 'Message::DOM::HTML::HTMLAnchorElement',
        area => 'Message::DOM::HTML::HTMLAreaElement',
        audio => 'Message::DOM::HTML::HTMLAudioElement',
        base => 'Message::DOM::HTML::HTMLBaseElement',
        body => 'Message::DOM::HTML::HTMLBodyElement',
        canvas => 'Message::DOM::HTML::HTMLCanvasElement',
        command => 'Message::DOM::HTML::HTMLCommandElement',
        datagrid => 'Message::DOM::HTML::HTMLDataGridElement',
        details => 'Message::DOM::HTML::HTMLDetailsElement',
        embed => 'Message::DOM::HTML::HTMLEmbedElement',
        'event-source' => 'Message::DOM::HTML::HTMLEventSourceElement',
        font => 'Message::DOM::HTML::HTMLFontElement',
        head => 'Message::DOM::HTML::HTMLHeadElement',
        html => 'Message::DOM::HTML::HTMLHtmlElement',
        iframe => 'Message::DOM::HTML::HTMLIFrameElement',
        img => 'Message::DOM::HTML::HTMLImageElement',
        li => 'Message::DOM::HTML::HTMLLIElement',
        link => 'Message::DOM::HTML::HTMLLinkElement',
        map => 'Message::DOM::HTML::HTMLMapElement',
        menu => 'Message::DOM::HTML::HTMLMenuElement',
        meta => 'Message::DOM::HTML::HTMLMetaElement',
        meter => 'Message::DOM::HTML::HTMLMeterElement',
        del => 'Message::DOM::HTML::HTMLModElement',
        ins => 'Message::DOM::HTML::HTMLModElement',
        object => 'Message::DOM::HTML::HTMLObjectElement', 
        ol => 'Message::DOM::HTML::HTMLOListElement',
        param => 'Message::DOM::HTML::HTMLParamElement',
        progress => 'Message::DOM::HTML::HTMLProgressElement',
        blockquote => 'Message::DOM::HTML::HTMLQuoteElement',
        q => 'Message::DOM::HTML::HTMLQuoteElement',
        script => 'Message::DOM::HTML::HTMLScriptElement',
        source => 'Message::DOM::HTML::HTMLSourceElement',
        style => 'Message::DOM::HTML::HTMLStyleElement',
        table => 'Message::DOM::HTML::HTMLTableElement',
        td => 'Message::DOM::HTML::HTMLTableCellElement',
        col => 'Message::DOM::HTML::HTMLTableColElement',
        colgroup => 'Message::DOM::HTML::HTMLTableColElement',
        th => 'Message::DOM::HTML::HTMLTableHeaderCellElement',
        tr => 'Message::DOM::HTML::HTMLTableRowElement',
        tbody => 'Message::DOM::HTML::HTMLTableSectionElement',
        tfoot => 'Message::DOM::HTML::HTMLTableSectionElement',
        thead => 'Message::DOM::HTML::HTMLTableSectionElement',
        time => 'Message::DOM::HTML::HTMLTimeElement',
        video => 'Message::DOM::HTML::HTMLVideoElement',
      }->{$lname} || 'Message::DOM::HTML::HTMLElement';
    } elsif ($nsuri eq q<http://www.w3.org/2005/Atom>) {
      require Message::DOM::Atom::AtomElement;
      $class = {
                author => 'Message::DOM::Atom::AtomElement::AtomPersonConstruct',
                category => 'Message::DOM::Atom::AtomElement::AtomCategoryElement',
                content => 'Message::DOM::Atom::AtomElement::AtomContentElement',
                contributor => 'Message::DOM::Atom::AtomElement::AtomPersonConstruct',
                entry => 'Message::DOM::Atom::AtomElement::AtomEntryElement',
                feed => 'Message::DOM::Atom::AtomElement::AtomFeedElement',
                generator => 'Message::DOM::Atom::AtomElement::AtomGeneratorElement',
                link => 'Message::DOM::Atom::AtomElement::AtomLinkElement',
                published => 'Message::DOM::Atom::AtomElement::AtomDateConstruct',
                rights => 'Message::DOM::Atom::AtomElement::AtomTextConstruct',
                source => 'Message::DOM::Atom::AtomElement::AtomSourceElement',
                subtitle => 'Message::DOM::Atom::AtomElement::AtomTextConstruct',
                summary => 'Message::DOM::Atom::AtomElement::AtomTextConstruct',
                title => 'Message::DOM::Atom::AtomElement::AtomTextConstruct',
                updated => 'Message::DOM::Atom::AtomElement::AtomDateConstruct',
               }->{$lname} || 'Message::DOM::Atom::AtomElement';
    }
  }

  my $r = $class->____new ($self, $nsuri, $prefix, $lname);

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
## $Date: 2008/01/24 11:25:19 $
