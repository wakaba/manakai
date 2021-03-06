package Message::DOM::DocumentType;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.17 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::DocumentType',
    'Message::IF::DocumentTypeDefinition',
    'Message::IF::DocumentTypeDeclaration';
require Message::DOM::Node;

sub ____new ($$$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{implementation} = $_[0] if defined $_[0];
  $$self->{name} = $_[1];
  $$self->{child_nodes} = [];
  $$self->{public_id} = '';
  $$self->{system_id} = '';
  $$self->{internal_subset} = '';
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    name => 1,
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
    internal_subset => 1,
    public_id => 1,
    system_id => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\$_[0]}->{strict_error_checking} and
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
sub name ($);

## |Node| attributes

*base_uri = \&declaration_base_uri;

## NOTE: A manakai extension
sub implementation ($) {
  my $self = shift;
  if (defined $$self->{implementation}) {
    return $$self->{implementation};
  } elsif (defined $$self->{owner_document}) {
    local $Error::Depth = $Error::Depth + 1;
    return $$self->{owner_document}->implementation;
  } else {
    die "DocumentType with no implementation, no owner_document";
  }
} # implementation

*node_name = \&name;

sub node_type () { 10 } # DOCUMENT_TYPE_NODE

sub text_content ($;$) { undef }

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
  if (not defined $self_od or $$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if (not defined $self_od or
        ($self_od ne $child_od and $child_od->node_type != 10)) {
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
      unless ($cn->node_type == 7) { # PROCESSING_INSTRUCTION_NODE
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }
    
    ## NOTE: Ancestor check in |Node|.
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

sub manakai_append_text () { }

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
  if (not defined $self_od or $$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if (not defined $self_od or
        ($self_od ne $child_od and $child_od->node_type != 10)) {
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
      unless ($cn->node_type == 7) { # PROCESSING_INSTRUCTION_NODE
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    ## NOTE: Ancestor check in |Node|.
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
  ## NOTE: |Element|, |Entity|, |DocumentFragment|, |EntityReference|.
  ## NOTE: |Document|, |Attr|, |CharacterData|, |AttributeDefinition|,
  ## |Notation|, |ProcessingInstruction|, |ElementTypeDefinition|,
  ## and |DocumentType| define their own implementations.
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
  if (not defined $self_od or $$self_od->{strict_error_checking}) {
    my $child_od = $_[1]->owner_document || $_[1]; # might be DocumentType
    if (not defined $self_od or
        ($self_od ne $child_od and $child_od->node_type != 10)) {
      report Message::DOM::DOMException  # DOCUMENT_TYPE_NODE
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
      unless ($cn->node_type == 7) { # PROCESSING_INSTRUCTION_NODE
        report Message::DOM::DOMException
            -object => $self,
            -type => 'HIERARCHY_REQUEST_ERR',
            -subtype => 'CHILD_NODE_TYPE_ERR';
      }
    }

    ## NOTE: Ancestor check in |Node|.
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

## |DocumentType| attributes

## NOTE: A manakai extension.
sub declaration_base_uri ($;$) {
  if (${$_[0]}->{owner_document}) {
    local $Error::Depth = $Error::Depth + 1;
    return ${$_[0]}->{owner_document}->base_uri;
  }
  return undef;
} # declaration_base_uri

*manakai_declaration_base_uri = \&declaration_base_uri;

sub entities ($) {
  require Message::DOM::NamedNodeMap;
  return bless \[$_[0], 'entities'], 'Message::DOM::NamedNodeMap';
} # entities

## NOTE: Setter is a manakai extension.
sub internal_subset ($;$);

sub notations ($) {
  require Message::DOM::NamedNodeMap;
  return bless \[$_[0], 'notations'], 'Message::DOM::NamedNodeMap';
} # notations

## NOTE: Setter is a manakai extension.
sub public_id ($;$);

## NOTE: Setter is a manakai extension.
sub system_id ($;$);

## |DocumentTypeDefinition| attributes

sub element_types ($) {
  require Message::DOM::NamedNodeMap;
  return bless \[$_[0], 'element_types'], 'Message::DOM::NamedNodeMap';
} # element_types

*general_entities = \&entities;

# *notations = \&notations;

## |DocumentTypeDefinition| methods

sub get_element_type_definition_node ($$) {
  return ${$_[0]}->{element_types}->{$_[1]};
} # get_element_type_definition_node

sub get_general_entity_node ($$) {
  return ${$_[0]}->{entities}->{$_[1]};
} # get_general_entity_node

sub get_notation_node ($$) {
  return ${$_[0]}->{notations}->{$_[1]};
} # get_notation_node

sub set_element_type_definition_node ($$) {
  my $self = $_[0];
  my $node = $_[1];

  my $name = $node->node_name;
  my $list = $$self->{element_types} ||= {}; # ***
  my $r = $list->{$name};

  if (defined $r and $r eq $node) {
    return undef; # no effect
  }

  my $od = $$self->{owner_document};
  if ($$od->{strict_error_checking}) {
    if ($$self->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if ($od ne $node->owner_document) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    my $owner = $$node->{owner_document_type_definition}; # ***
    if ($owner) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'HIERARCHY_REQUEST_ERR',
          -subtype => 'INUSE_DEFINITION_ERR';
    }
  }

  if (defined $r) {
    delete $$r->{owner_document_type_definition}; # ***
  }

  $list->{$name} = $node;
  $$node->{owner_document_type_definition} = $self; # ***
  Scalar::Util::weaken ($$node->{owner_document_type_definition}); # ***
} # set_element_type_definition_node

sub set_general_entity_node ($$) {
  my $self = $_[0];
  my $node = $_[1];

  my $name = $node->node_name;
  my $list = $$self->{entities} ||= {}; # ***
  my $r = $list->{$name};

  if (defined $r and $r eq $node) {
    return undef; # no effect
  }

  my $od = $$self->{owner_document};
  if ($$od->{strict_error_checking}) {
    if ($$self->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if ($od ne $node->owner_document) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    my $owner = $$node->{owner_document_type_definition}; # ***
    if ($owner) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'HIERARCHY_REQUEST_ERR',
          -subtype => 'INUSE_DEFINITION_ERR';
    }
  }

  if (defined $r) {
    delete $$r->{owner_document_type_definition}; # ***
  }

  $list->{$name} = $node;
  $$node->{owner_document_type_definition} = $self; # ***
  Scalar::Util::weaken ($$node->{owner_document_type_definition}); # ***
} # set_general_entity_node

sub set_notation_node ($$) {
  my $self = $_[0];
  my $node = $_[1];

  my $name = $node->node_name;
  my $list = $$self->{notations} ||= {}; # ***
  my $r = $list->{$name};

  if (defined $r and $r eq $node) {
    return undef; # no effect
  }

  my $od = $$self->{owner_document};
  if ($$od->{strict_error_checking}) {
    if ($$self->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if ($od ne $node->owner_document) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'WRONG_DOCUMENT_ERR',
          -subtype => 'EXTERNAL_OBJECT_ERR';
    }

    my $owner = $$node->{owner_document_type_definition}; # ***
    if ($owner) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'HIERARCHY_REQUEST_ERR',
          -subtype => 'INUSE_DEFINITION_ERR';
    }
  }

  if (defined $r) {
    delete $$r->{owner_document_type_definition}; # ***
  }

  $list->{$name} = $node;
  $$node->{owner_document_type_definition} = $self; # ***
  Scalar::Util::weaken ($$node->{owner_document_type_definition}); # ***
} # set_notation_node

package Message::IF::DocumentType;
package Message::IF::DocumentTypeDefinition;
package Message::IF::DocumentTypeDeclaration;

package Message::DOM::DOMImplementation;
use Char::Class::XML
    qw/
      InXML_NameStartChar10
      InXMLNameChar10
      InXML_NCNameStartChar10
      InXMLNCNameChar10
    /;

sub create_document_type ($$$$) {
  ## ISSUE: Old manakai has allowed publicId and systemId to be null.
  ## Should we continue to do so?

  if ($_[1] =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/) {
    if ($_[1] =~ /\A\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*(?>:\p{InXML_NCNameStartChar10}\p{InXMLNCNameChar10}*)?\z/) {
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

  local $Error::Depth = $Error::Depth + 1;
  my $r = Message::DOM::DocumentType->____new (undef, @_[0, 1]);
  $r->public_id ($_[2]);
  $r->system_id ($_[3]);
  $r->manakai_set_read_only (1, 1);
  return $r;
} # create_document_type

package Message::DOM::Document;

sub create_document_type_definition ($$) {
  if (${$_[0]}->{strict_error_checking}) {
    my $xv = $_[0]->xml_version;
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

  my $r = Message::DOM::DocumentType->____new ($_[0], undef, $_[1]);
  $$r->{manakai_has_predefined_entity_declaration} = 1;
  return $r;
} # create_document_type_definition

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/12/22 06:29:32 $
