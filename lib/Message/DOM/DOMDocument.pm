## NOTE: This module will be renamed as Document.pm.

package Message::DOM::Document;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Document',
    'Message::IF::DocumentXDoctype',
    'Message::IF::HTMLDocument';
require Message::DOM::Node;
use Char::Class::XML
    qw/
      InXML_NameStartChar10 InXMLNameStartChar11
      InXMLNameChar10 InXMLNameChar11
      InXML_NCNameStartChar10 InXMLNCNameStartChar11
      InXMLNCNameChar10 InXMLNCNameChar11
    /;

sub ____new ($$) {
  my $self = shift->SUPER::____new (undef);
  $$self->{implementation} = $_[0];
  $$self->{strict_error_checking} = 1;
  $$self->{child_nodes} = [];
  $$self->{'http://suika.fam.cx/www/2006/dom-config/strict-document-children'} = 1;
  $$self->{'http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute'} = 1;
  $$self->{'http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree'} = 1;
  $$self->{'error-handler'} = sub { };
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    implementation => 1,
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
    document_uri => 1,
    input_encoding => 1,
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
  } elsif ({
    ## Read-write attributes (boolean, trivial accessors)
    all_declarations_processed => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\$_[0]}->{manakai_strict_error_checking} and
              \${\$_[0]}->{manakai_read_only}) {
            report Message::DOM::DOMException
                -object => \$_[0],
                -type => 'NO_MODIFICATION_ALLOWED_ERR',
                -subtype => 'READ_ONLY_NODE_ERR';
          }
          if (\$_[1]) {
            \${\$_[0]}->{$method_name} = 1;
          } else {
            delete \${\$_[0]}->{$method_name};
          }
        }
        return \${\$_[0]}->{$method_name};
      }
    };
    goto &{ $AUTOLOAD };
  } elsif (my $module_name = {
    create_attribute => 'Message::DOM::Attr',
    create_attribute_ns => 'Message::DOM::Attr',
    create_attribute_definition => 'Message::DOM::AttributeDefinition',
    create_cdata_section => 'Message::DOM::CDATASection',
    create_comment => 'Message::DOM::Comment',
    create_document_fragment => 'Message::DOM::DocumentFragment',
    create_document_type_definition => 'Message::DOM::DocumentType',
    create_element => 'Message::DOM::DOMElement', ## TODO: change module name
    create_element_ns => 'Message::DOM::DOMElement', ## TODO: change module name
    create_element_type_definition => 'Message::DOM::ElementTypeDefinition',
    create_entity_reference => 'Message::DOM::EntityReference',
    create_general_entity => 'Message::DOM::Entity',
    create_notation => 'Message::DOM::Notation',
    create_processing_instruction => 'Message::DOM::ProcessingInstruction',
    create_text_node => 'Message::DOM::Text',
  }->{$method_name}) {
    eval qq{ require $module_name } or die $@;
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD
sub implementation ($);
sub create_attribute ($$);
sub create_attribute_ns ($$$);
sub create_attribute_definition ($$);
sub create_cdata_section ($$);
sub create_comment ($$);
sub create_document_fragment ($);
sub create_document_type_definition ($$);
sub create_element ($$);
sub create_element_ns ($$$);
sub create_element_type_definition ($$);
sub create_entity_reference ($$);
sub create_general_entity ($$);
sub create_notation ($$);
sub create_processing_instruction ($$$);
sub create_text_node ($$);

## |Node| attributes

sub base_uri ($) {
  my $v = ${$_[0]}->{manakai_entity_base_uri};
  if (defined $v) {
    return $v;
  } else {
    return ${$_[0]}->{document_uri};
  }
  ## TODO: HTML5 <base>
} # base_uri

sub node_name () { '#document' }

sub node_type () { 9 } # DOCUMENT_NODE

sub text_content ($;$) {
  my $self = shift;
  if ($$self->{'http://suika.fam.cx/www/2006/dom-config/strict-document-children'}) {
    return undef;
  } else {
    local $Error::Depth = $Error::Depth + 1;
    return $self->SUPER::text_content (@_);
  }
} # text_content

## |Node| methods

sub adopt_node ($$) {
  my ($self, $source) = @_;
  ## TODO: Should we apply |copy-asis| configuration parameter to this method?

  return undef unless UNIVERSAL::isa ($source, 'Message::DOM::Node');

  my $strict = $self->strict_error_checking;
  if ($strict and $$self->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $parent = $source->parent_node;
  if ($strict and defined $parent and $$parent->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  my $nt = $source->node_type;
  my $oe;
  if ($nt == 2) { # ATTRIBUTE_NODE
    $oe = $source->owner_element;
    if ($strict and defined $oe and $$oe->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
  } elsif ($nt == 9 or $nt == 10 or $nt == 6 or $nt == 12 or
           $nt == 81001 or $nt == 81002) {
    # DOCUMENT_NODE, DOCUMENT_TYPE_NODE, ENTITY_NODE, NOTATION_NODE,
    # ELEMENT_TYPE_DEFINITION_NODE, ATTRIBUTE_DEFINITION_NODE
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NOT_SUPPORTED_ERR',
        -subtype => 'ADOPT_NODE_TYPE_NOT_SUPPORTED_ERR';
    ## ISSUE: Define ELEMENT_TYPE_DEFINITION_NODE and ATTRIBUTE_DEFINITION_NODE
  }

  my @change_od;
  my @nodes = ($source);
  while (@nodes) {
    my $node = shift @nodes;
    my $nt = $node->node_type;
    if ($strict and $$node->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    push @change_od, $node;
    push @nodes, @{$node->child_nodes}, @{$node->attributes or []};
  } # @nodes

  local $Error::Depth = $Error::Depth + 1;

  if (defined $parent) {
    $parent->remove_child ($source);
  } elsif (defined $oe) {
    $oe->remove_attribute_node ($source);
  }

  return $source if $self eq $change_od[0]->owner_document;
                         ## NOTE: The array must have more than zero
                         ##       nodes by definition.  In addition,
                         ##       it cannot contain document or document
                         ##       type nodes in current implementation.

  my @ud_node;
  for my $n (@change_od) {
    $$n->{owner_document} = $self;
    Scalar::Util::weaken ($$n->{owner_document});
    if ($$n->{user_data}) {
      push @ud_node, $n;
    }
  }

  for my $src (@ud_node) {
    my $src_ud = $$src->{user_data};
    for my $key (keys %{$src_ud}) {
      my $dh = $src_ud->{$key}->[1];
      if ($dh) {
        $dh->(5, $key, $src_ud->{$key}->[0], $src, undef); # NODE_ADOPTED
      }
    }
  }

  return $source;
} # adopt_node

sub manakai_append_text ($$) {
  my $self = shift;
  if ($$self->{'http://suika.fam.cx/www/2006/dom-config/strict-document-children'}) {
    #
  } else {
    local $Error::Depth = $Error::Depth + 1;
    return $self->SUPER::manakai_append_text (@_);
  }
} # manakai_append_text

## |Document| attributes

## NOTE: A manakai extension.
sub all_declarations_processed ($;$);

sub doctype ($) {
  my $self = $_[0];
  for (@{$self->child_nodes}) {
    if ($_->node_type == 10) { # DOCUMENT_TYPE_NODE
      return $_;
    }
  }
  return undef;
} # doctype

sub document_element ($) {
  my $self = shift;
  for (@{$self->child_nodes}) {
    if ($_->node_type == 1) { # ELEMENT_NODE
      return $_;
    }
  }
  return undef;
} # document_element

sub document_uri ($;$);

sub dom_config ($) {
  require Message::DOM::DOMConfiguration;
  return bless \\($_[0]), 'Message::DOM::DOMConfiguration';
} # dom_config

sub manakai_entity_base_uri ($;$) {
  my $self = $_[0];
  if (@_ > 1) {
    if ($$self->{strict_error_checking}) {
      if ($$self->{manakai_read_only}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NO_MODIFICATION_ALLOWED_ERR',
            -subtype => 'READ_ONLY_NODE_ERR';
      }
    }
    if (defined $_[1]) {
      $$self->{manakai_entity_base_uri} = ''.$_[1];
    } else {
      delete $$self->{manakai_entity_base_uri};
    }
  }
  
  if (defined $$self->{manakai_entity_base_uri}) {
    return $$self->{manakai_entity_base_uri};
  } else {
    return $$self->{document_uri};
  }
} # manakai_entity_base_uri

sub input_encoding ($;$);

sub strict_error_checking ($;$) {
  ## NOTE: Same as trivial boolean accessor, except no read-only checking.
  if (@_ > 1) {
    if ($_[1]) {
      ${$_[0]}->{strict_error_checking} = 1;
    } else {
      delete ${$_[0]}->{strict_error_checking};
    }
  }                   
  return ${$_[0]}->{strict_error_checking};
} # strict_error_checking

## ISSUE: Setting manakai_is_html true shadows 
## xml_* properties.  Is this desired?

sub xml_encoding ($;$) {
  my $self = $_[0];
  if (@_ > 1) {
    ## NOTE: A manakai extension.
    if ($$self->{strict_error_checking}) {
      if ($$self->{manakai_is_html}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NOT_SUPPORTED_ERR',
            -subtype => 'NON_HTML_OPERATION_ERR';
      }
      if ($$self->{manakai_read_only}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NO_MODIFICATION_ALLOWED_ERR',
            -subtype => 'READ_ONLY_NODE_ERR';
      }
    }
    if (defined $_[1]) {
      $$self->{xml_encoding} = ''.$_[1];
    } else {
      delete $$self->{xml_encoding};
    }
  }
  
  if ($$self->{manakai_is_html}) {
    return undef;
  } else {
    return $$self->{xml_encoding};
  }
} # xml_encoding

sub xml_standalone ($;$) {
  my $self = $_[0];
  if (@_ > 1) {
    if ($$self->{strict_error_checking}) {
      if ($$self->{manakai_is_html}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NOT_SUPPORTED_ERR',
            -subtype => 'NON_HTML_OPERATION_ERR';
      }
      ## NOTE: Not in DOM3.
      if ($$self->{manakai_read_only}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NO_MODIFICATION_ALLOWED_ERR',
            -subtype => 'READ_ONLY_NODE_ERR';
      }
    }
    if ($_[1]) {
      $$self->{xml_standalone} = 1;
    } else {
      delete $$self->{xml_standalone};
    }
  }
  
  if ($$self->{manakai_is_html}) {
    return 0;
  } else {
    return $$self->{xml_standalone};
  }
} # xml_standalone

sub xml_version ($;$) {
  my $self = $_[0];
  if (@_ > 1) {
    my $v = ''.$_[1];
    if ($$self->{strict_error_checking}) {
      if ($$self->{manakai_is_html}) {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NOT_SUPPORTED_ERR',
            -subtype => 'NON_HTML_OPERATION_ERR';
      }
      if ($v ne '1.0' and $v ne '1.1') {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NOT_SUPPORTED_ERR',
            -subtype => 'UNKNOWN_XML_VERSION_ERR';
      }
      if ($$self->{manakai_read_only}) {
        ## ISSUE: Not in DOM3.
        report Message::DOM::DOMException
            -object => $self,
            -type => 'NO_MODIFICATION_ALLOWED_ERR',
            -subtype => 'READ_ONLY_NODE_ERR';
      }
    }
    $$self->{xml_version} = $v;
  }
  
  if (defined wantarray) {
    if ($$self->{manakai_is_html}) {
      return undef;
    } elsif (defined $$self->{xml_version}) {
      return $$self->{xml_version};
    } else {
      return '1.0';
    }
  }
} # xml_version

## |HTMLDocument| interface

sub compat_mode ($) {
  if (${$_[0]}->{manakai_is_html}) {
    if (defined ${$_[0]}->{manakai_compat_mode} and
        ${$_[0]}->{manakai_compat_mode} eq 'quirks') {
      return 'BackCompat';
    }
  }
  return 'CSS1Compat';
} # compat_mode

sub manakai_compat_mode ($;$) {
  if (${$_[0]}->{manakai_is_html}) {
    if (@_ > 1 and defined $_[1] and
        {'no quirks' => 1, 'limited quirks' => 1, 'quirks' => 1}->{$_[1]}) {
      ${$_[0]}->{manakai_compat_mode} = $_[1];
    }
    return ${$_[0]}->{manakai_compat_mode} || 'no quirks';
  } else {
    return 'no quirks';
  }
} # manakai_compat_mode

sub manakai_is_html ($;$) {
  if (@_ > 1) {
    if ($_[1]) {
      ${$_[0]}->{manakai_is_html} = 1;
    } else {
      delete ${$_[0]}->{manakai_is_html};
      delete ${$_[0]}->{manakai_compat_mode};
    }
  }
  return ${$_[0]}->{manakai_is_html};
} # manakai_is_html

package Message::IF::Document;
package Message::IF::DocumentXDoctype;
package Message::IF::HTMLDocument;

package Message::DOM::DOMImplementation;

sub create_document ($;$$$) {
  my ($self, $nsuri, $qn, $doctype) = @_;
  ## TODO: root element
  return Message::DOM::Document->____new ($self);
} # create_document

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/07 09:11:05 $
