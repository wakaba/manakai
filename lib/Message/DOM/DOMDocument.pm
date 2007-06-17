## NOTE: This module will be renamed as Document.pm.

package Message::DOM::Document;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Document',
    'Message::IF::DocumentXDoctype';
require Message::DOM::Node;

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
    manakai_is_html => 1,
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

sub manakai_is_html ($;$);

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

package Message::IF::Document;
package Message::IF::DocumentXDoctype;

package Message::DOM::DOMImplementation;

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#Level-2-Core-DOM-createDocument>

sub create_document ($;$$$) {
  my ($self, $nsuri, $qn, $doctype) = @_;
  ## TODO: root element
  return Message::DOM::Document->____new ($self);
} # create_document

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/17 13:37:40 $
