## NOTE: This module will be renamed as Document.pm.

package Message::DOM::Document;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Document',
    'Message::IF::DocumentXDoctype';
require Message::DOM::Node;

sub ____new ($$) {
  my $self = shift->SUPER::____new (undef);
  $$self->{implementation} = $_[0];
  $$self->{strict_error_checking} = 1;
  $$self->{child_nodes} = [];
  $$self->{'http://suika.fam.cx/www/2006/dom-config/strict-document-children'} = 1;
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
    strict_error_checking => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        if (\@_ > 1) {
          \${\$_[0]}->{$method_name} = ''.$_[1];
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
sub strict_error_checking ($;$);
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

## The |Document| interface - attribute

sub document_element ($) {
  my $self = shift;
  for (@{$self->child_nodes}) {
    if ($_->node_type == 1) { # ELEMENT_NODE
      return $_;
    }
  }
  return undef;
} # document_element

sub dom_config ($) {
  require Message::DOM::DOMConfiguration;
  return bless \\($_[0]), 'Message::DOM::DOMConfiguration';
} # dom_config

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
## $Date: 2007/06/16 15:27:45 $
