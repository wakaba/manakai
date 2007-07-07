## NOTE: This module will be renamed as Element.pm.

package Message::DOM::Element;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

## The |Node| interface - attributes

sub attributes ($) {
  my $self = shift;
  my $r = []; ## TODO: NamedNodeMap
  ## Order MUST be stable
  for my $ns (sort {$a cmp $b} keys %{$$self->{attributes}}) {
    for my $ln (sort {$a cmp $b} keys %{$$self->{attributes}->{$ns}}) {
      push @$r, $$self->{attributes}->{$ns}->{$ln}
        if defined $$self->{attributes}->{$ns}->{$ln};
    }
  }
  return $r;
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

  delete $$self->{____content_attribute_list};
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
  ## TODO: HTML5
  return Message::DOM::Element->____new ($_[0], undef, undef, $_[1]);
} # create_element

sub create_element_ns ($$$) {
  my ($prefix, $lname);
  if (ref $_[2] eq 'ARRAY') {
    ($prefix, $lname) = @{$_[2]};
  } else {
    ($prefix, $lname) = split /:/, $_[2], 2;
    ($prefix, $lname) = (undef, $prefix) unless defined $lname;
  }
  return Message::DOM::Element->____new ($_[0], $_[1], $prefix, $lname);
} # create_element_ns

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/07/07 07:36:58 $
