package Message::DOM::Attr;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Attr';
require Message::DOM::Node;

sub ____new ($$$$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{owner_element},
   $$self->{namespace_uri},
   $$self->{prefix},
   $$self->{local_name}) = @_;
  Scalar::Util::weaken ($$self->{owner_element});
  $$self->{child_nodes} = [];
  $$self->{specified} = 1;
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    namespace_uri => 1,
    owner_element => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## |AttributeDefinition| constants

## |DeclaredValueType|
sub NO_TYPE_ATTR () { 0 }
sub CDATA_ATTR () { 1 }
sub ID_ATTR () { 2 }
sub IDREF_ATTR () { 3 }
sub IDREFS_ATTR () { 4 }
sub ENTITY_ATTR () { 5 }
sub ENTITIES_ATTR () { 6 }
sub NMTOKEN_ATTR () { 7 }
sub NMTOKENS_ATTR () { 8 }
sub NOTATION_ATTR () { 9 }
sub ENUMERATION_ATTR () { 10 }
sub UNKNOWN_ATTR () { 11 }

## |Node| attributes

sub base_uri ($) {
  my $self = $_[0];
  local $Error::Depth = $Error::Depth + 1;
  my $oe = $self->owner_element;
  if ($oe) {
    my $ln = $self->manakai_local_name;
    my $nsuri = $self->namespace_uri;
    if (($ln eq 'base' and
         defined $nsuri and $nsuri eq 'http://www.w3.org/XML/1998/namespace') or
        ($ln eq 'xml:base' and not defined $nsuri)) {
      my $oep = $oe->parent_node;
      if ($oep) {
        return $oep->base_uri;
      } else {
        return $self->owner_document->base_uri;
      }
    } else {
      return $oe->base_uri;
    }
  } else {
    return $self->owner_document->base_uri;
  }
} # base_uri

sub local_name ($) {
  ## TODO: HTML5
  return ${+shift}->{local_name};
} # local_name

sub manakai_local_name ($) {
  return ${$_[0]}->{local_name};
} # manakai_local_name

sub namespace_uri ($);

*node_name = \&name;

sub node_type () { 2 } # ATTRIBUTE_NODE

*node_value = \&Message::DOM::Node::text_content;

sub owner_element ($);

sub prefix ($;$) {
  ## NOTE: No check for new value as Firefox doesn't do.
  ## See <http://suika.fam.cx/gate/2005/sw/prefix>.

  ## NOTE: Same as trivial setter except "" -> undef

  ## NOTE: Same as |Element|'s |prefix|.
  
  if (@_ > 1) {
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and 
        ${$_[0]}->{manakai_read_only}) {
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

## |Node| methods

sub append_child ($$) {
  my $self = $_[0];
  
  ## NOTE: Depends on $self->node_type:
  my $self_od = $$self->{owner_document};

  ## -- Node Type check
  my @new_child;
  my $new_child_parent;
  if ($_[1]->node_type == 11) { # DOCUMENT_FRAGMENT_NODE
    push @new_child, @{$_[1]->child_nodes};
    $new_child_parent = $_[1];
  } else {
    @new_child = ($_[1]);
    $new_child_parent = $_[1]->parent_node;
  }

  ## NOTE: Depends on $self->node_type:
  if ($$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if ($self_od ne $child_od and $child_od->node_type != 10) {
      report Message::DOM::DOMException # DOCUMENT_TYPE_NODE
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    if ($$self->{manakai_read_only} or
        (@new_child and defined $new_child_parent and
         $$new_child_parent->{manakai_read_only})) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    ## NOTE: |Document| has children order check here.

    for my $cn (@new_child) {
      unless ({
               3, 1, 5, 1, # TEXT_NODE, ENTITY_REFERENCE_NODE
              }->{$cn->node_type}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    ## NOTE: Ancestor check here in |Node|.
  }

  ## NOTE: "Insert at" code only in insert_before and replace_child

  ## -- Removes from parent
  if ($new_child_parent) {
    if (@new_child == 1) {
      my $v = $$new_child_parent->{child_nodes};
      RP: for my $i (0..$#$v) {
        if ($v->[$i] eq $new_child[0]) {
          splice @$v, $i, 1, ();
          last RP;
        }
      } # RP
    } else {
      @{$$new_child_parent->{child_nodes}} = ();
    }
  }

  ## -- Rewrite the |parentNode| properties
  for my $nc (@new_child) {
    $$nc->{parent_node} = $self;
    Scalar::Util::weaken ($$nc->{parent_node});
  }

  ## NOTE: Depends on method:
  push @{$$self->{child_nodes}}, @new_child;

  ## NOTE: Setting |owner_document| in |Document|.

  return $_[1];
} # apepnd_child

sub insert_before ($$) {
  my $self = $_[0];

  ## NOTE: Depends on $self->node_type:
  my $self_od = $$self->{owner_document};

  ## -- Node Type check
  my @new_child;
  my $new_child_parent;
  if ($_[1]->node_type == 11) { # DOCUMENT_FRAGMENT_NODE
    push @new_child, @{$_[1]->child_nodes};
    $new_child_parent = $_[1];
  } else {
    @new_child = ($_[1]);
    $new_child_parent = $_[1]->parent_node;
  }

  ## NOTE: Depends on $self->node_type:
  if ($$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if ($self_od ne $child_od and $child_od->node_type != 10) {
      report Message::DOM::DOMException # DOCUMENT_TYPE_NODE
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    if ($$self->{manakai_read_only} or
        (@new_child and defined $new_child_parent and
         $$new_child_parent->{manakai_read_only})) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    ## NOTE: |Document| has children order check here.

    for my $cn (@new_child) {
      unless ({
               3, 1, 5, 1, # TEXT_NODE, ENTITY_REFERENCE_NODE
              }->{$cn->node_type}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    ## NOTE: Ancestor check here in |Node|.
  }
  
  ## -- Insert at... ## NOTE: Only in insert_before and replace_child
  my $index = -1; # last
  if (defined $_[2]) {
    ## error if $_[1] eq $_[2];
    
    my $cns = $self->child_nodes;
    my $cnsl = @$cns;
    C: {
      $index = 0;
      for my $i (0..($cnsl-1)) {
        my $cn = $cns->[$i];
        if ($cn eq $_[2]) {
          $index += $i;
          last C;
        } elsif ($cn eq $_[1]) {
          $index = -1; # offset
        }
      }
      
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_FOUND_ERR',
          -subtype => 'NOT_CHILD_ERR';
    } # C
  }
  ## NOTE: "else" only in replace_child

  ## -- Removes from parent
  if ($new_child_parent) {
    if (@new_child == 1) {
      my $v = $$new_child_parent->{child_nodes};
      RP: for my $i (0..$#$v) {
        if ($v->[$i] eq $new_child[0]) {
          splice @$v, $i, 1, ();
          last RP;
        }
      } # RP
    } else {
      @{$$new_child_parent->{child_nodes}} = ();
    }
  }

  ## -- Rewrite the |parentNode| properties
  for my $nc (@new_child) {
    $$nc->{parent_node} = $self;
    Scalar::Util::weaken ($$nc->{parent_node});
  }

  ## NOTE: Depends on method:
  if ($index == -1) {
    push @{$$self->{child_nodes}}, @new_child;
  } else {
    splice @{$$self->{child_nodes}}, $index, 0, @new_child;
  }

  ## NOTE: Setting |owner_document| in |Document|.

  return $_[1];
} # insert_before

sub replace_child ($$) {
  my $self = $_[0];

  ## NOTE: Depends on $self->node_type:
  my $self_od = $$self->{owner_document};

  ## -- Node Type check
  my @new_child;
  my $new_child_parent;
  if ($_[1]->node_type == 11) { # DOCUMENT_FRAGMENT_NODE
    push @new_child, @{$_[1]->child_nodes};
    $new_child_parent = $_[1];
  } else {
    @new_child = ($_[1]);
    $new_child_parent = $_[1]->parent_node;
  }

  ## NOTE: Depends on $self->node_type:
  if ($$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if ($self_od ne $child_od and $child_od->node_type != 10) {
      report Message::DOM::DOMException # DOCUMENT_TYPE_NODE
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    if ($$self->{manakai_read_only} or
        (@new_child and defined $new_child_parent and
         $$new_child_parent->{manakai_read_only})) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    ## NOTE: |Document| has children order check here.

    for my $cn (@new_child) {
      unless ({
               3, 1, 5, 1, # TEXT_NODE, ENTITY_REFERENCE_NODE
              }->{$cn->node_type}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    ## NOTE: Ancestor check here in |Node|.
  }
  
  ## -- Insert at... ## NOTE: Only in insertBefore and replaceChild
  my $index = -1; # last
  if (defined $_[2]) {
    ## error if $_[1] eq $_[2];
    
    my $cns = $self->child_nodes;
    my $cnsl = @$cns;
    C: {
      $index = 0;
      for my $i (0..($cnsl-1)) {
        my $cn = $cns->[$i];
        if ($cn eq $_[2]) {
          $index += $i;
          last C;
        } elsif ($cn eq $_[1]) {
          $index = -1; # offset
        }
      }
      
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NOT_FOUND_ERR',
          -subtype => 'NOT_CHILD_ERR';
    } # C
  } else {
    ## NOTE: Only in replaceChild
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NOT_FOUND_ERR',
        -subtype => 'NOT_CHILD_ERR';
  }

  ## -- Removes from parent
  if ($new_child_parent) {
    if (@new_child == 1) {
      my $v = $$new_child_parent->{child_nodes};
      RP: for my $i (0..$#$v) {
        if ($v->[$i] eq $new_child[0]) {
          splice @$v, $i, 1, ();
          last RP;
        }
      } # RP
    } else {
      @{$$new_child_parent->{child_nodes}} = ();
    }
  }

  ## -- Rewrite the |parentNode| properties
  for my $nc (@new_child) {
    $$nc->{parent_node} = $self;
    Scalar::Util::weaken ($$nc->{parent_node});
  }

  ## NOTE: Depends on method:
  splice @{$$self->{child_nodes}}, $index, 1, @new_child;
  delete ${$_[2]}->{parent_node};

  ## NOTE: Setting |owner_document| in |Document|.

  return $_[2];
} # replace_child

## |Attr| attributes

sub manakai_attribute_type ($;$) {
  my $self = $_[0];
  if (@_ > 1) {
    if (${$$self->{owner_document}}->{strict_error_checking}) {
      if ($$self->{manakai_read_only}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NO_MODIFICATION_ALLOWED_ERR',
            -subtype => 'READ_ONLY_NODE_ERR';
      }
    }
    if ($_[1]) {
      $$self->{manakai_attribute_type} = 0+$_[1];
    } else {
      delete $$self->{manakai_attribute_type};
    }
  }
  
  return $$self->{manakai_attribute_type} || 0;
} # manakai_attribute_type

sub is_id ($;$) {
  my $self = $_[0];

  if (@_ > 1) {
    ## NOTE: The setter is a manakai extension.
    ## TODO: Document.

    if (${$$self->{owner_document}}->{strict_error_checking}) {
      if ($$self->{manakai_read_only}) {
        report Message::DOM::DOMException
              -object => $self,
              -type => 'NO_MODIFICATION_ALLOWED_ERR',
              -subtype => 'READ_ONLY_NODE_ERR';
      }
    }

    if ($_[1]) {
      $$self->{manakai_user_determined_id} = 1;
    } else {
      delete $$self->{manakai_user_determined_id};
    }
  }
  return unless defined wantarray;
  
  ## DTD Attribute Type
  my $type = $$self->{manakai_attribute_type};
  if (defined $type and $type == 2) { # ID_ATTR
    return 1;
  }
  
  ## User-determined ID
  if ($$self->{manakai_user_determined_id}) {
    return 1;
  }

  ## Application-determined ID
  my $nsuri = $self->namespace_uri;
  my $ln = $self->manakai_local_name;
  if (defined $nsuri) {
    if ($ln eq 'id') {
      if ($nsuri eq q<http://www.w3.org/XML/1998/namespace>) {
        return 1;
      }
    }
  } else {
    if ($ln eq 'xml:id') {
      return 1;
    }

    my $oe = $$self->{owner_element};
    if ($oe) {
      my $oe_nsuri = $oe->namespace_uri;
      if (defined $oe_nsuri) {
        if ($ln eq 'id') {
          if ($oe_nsuri eq q<http://www.w3.org/1999/xhtml>) {
            return 1;
          }
        }
      }
    }
  }

  return 0;
} # is_id

## TODO: HTML5 case stuff?
sub name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # name

## TODO: Documentation
sub manakai_name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # manakai_name

sub schema_type_info ($) {
  require Message::DOM::TypeInfo;
  my $v = ${$_[0]}->{manakai_attribute_type} || 0;
  return bless \$v, 'Message::DOM::TypeInfo';
} # schema_type_info

sub specified ($;$) {
  if (@_ > 1) {
    ## NOTE: A manakai extension.
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and 
        ${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    if ($_[1] or not defined ${$_[0]}->{owner_element}) {
      ${$_[0]}->{specified} = 1;
    } else {
      delete ${$_[0]}->{specified};
    }
  }
  return ${$_[0]}->{specified}; 
} # specified

*value = \&node_value;

package Message::IF::Attr;

package Message::DOM::Document;

sub create_attribute ($$) {
  if (${$_[0]}->{strict_error_checking}) {
    my $xv = $_[0]->xml_version;
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
            -object => $_[0],
            -type => 'INVALID_CHARACTER_ERR',
            -subtype => 'MALFORMED_NAME_ERR';
      }
    }
  }
  ## TODO: HTML5
  return Message::DOM::Attr->____new ($_[0], undef, undef, undef, $_[1]);
} # create_attribute

sub create_attribute_ns ($$$) {
  my ($prefix, $lname);
  if (ref $_[2] eq 'ARRAY') {
    ($prefix, $lname) = @{$_[2]};
  } else {
    ($prefix, $lname) = split /:/, $_[2], 2;
    ($prefix, $lname) = (undef, $prefix) unless defined $lname;
  }
  my $nsuri = defined $_[1] ? $_[1] eq '' ? undef : $_[1] : undef;

  if (${$_[0]}->{strict_error_checking}) {
    my $xv = $_[0]->xml_version;
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
                  -object => $_[0],
                  -type => 'NAMESPACE_ERR',
                  -subtype => 'MALFORMED_QNAME_ERR';
            }
          }
          if ($lname =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*\z/) {
            #
          } else {
            report Message::DOM::DOMException
                -object => $_[0],
                -type => 'NAMESPACE_ERR',
                -subtype => 'MALFORMED_QNAME_ERR';
          }
        } else {
          report Message::DOM::DOMException
              -object => $_[0],
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
                  -object => $_[0],
                  -type => 'NAMESPACE_ERR',
                  -subtype => 'MALFORMED_QNAME_ERR';
            }
          }
          if ($lname =~ /\A\p{InXMLNCNameStartChar11}\p{InXMLNCNameChar11}*\z/) {
            #
          } else {
            report Message::DOM::DOMException
                -object => $_[0],
                -type => 'NAMESPACE_ERR',
                -subtype => 'MALFORMED_QNAME_ERR';
          }
        } else {
          report Message::DOM::DOMException
              -object => $_[0],
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
            -object => $_[0],
            -type => 'NAMESPACE_ERR',
            -subtype => 'PREFIXED_NULLNS_ERR';
      } elsif ($prefix eq 'xml' and 
               $nsuri ne q<http://www.w3.org/XML/1998/namespace>) {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLPREFIX_NONXMLNS_ERR';
      } elsif ($prefix eq 'xmlns' and
               $nsuri ne q<http://www.w3.org/2000/xmlns/>) {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLNSPREFIX_NONXMLNSNS_ERR';
      } elsif ($nsuri eq q<http://www.w3.org/2000/xmlns/> and
               $prefix ne 'xmlns') {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'NAMESPACE_ERR',
            -subtype => 'NONXMLNSPREFIX_XMLNSNS_ERR';
      }
    } else { # no prefix
      if ($lname eq 'xmlns' and
          (not defined $nsuri or $nsuri ne q<http://www.w3.org/2000/xmlns/>)) {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'NAMESPACE_ERR',
            -subtype => 'XMLNS_NONXMLNSNS_ERR';
      } elsif (not defined $nsuri) {
        #
      } elsif ($nsuri eq q<http://www.w3.org/2000/xmlns/> and
               $lname ne 'xmlns') {
        report Message::DOM::DOMException
            -object => $_[0],
            -type => 'NAMESPACE_ERR',
            -subtype => 'NONXMLNSPREFIX_XMLNSNS_ERR';
      }
    }
  }

  ## TODO: Older version of manakai set |attribute_type|
  ## attribute for |xml:id| attribute.  Should we support this?

  return Message::DOM::Attr->____new ($_[0], undef, $nsuri, $prefix, $lname);
} # create_attribute_ns

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/29 03:48:59 $
