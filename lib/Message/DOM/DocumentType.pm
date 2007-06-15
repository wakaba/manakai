package Message::DOM::DocumentType;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::DocumentType',
    'Message::IF::DocumentTypeDefinition',
    'Message::IF::DocumentTypeDeclaration';
require Message::DOM::Node;

## Spec:
## <http://suika.fam.cx/gate/2005/sw/DocumentTypeDefinition>
## <http://suika.fam.cx/gate/2005/sw/DocumentTypeDeclaration>

sub ____new ($$$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{implementation} = $_[0] if defined $_[0];
  $$self->{name} = $_[1];
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
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD
sub name ($);

## The |Node| interface - attribute

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-F68D095>
## Modified: <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-1841493061>

## The document type name [DOM1, DOM2].
## Same as |DocumentType.nam| [DOM3].

*node_name = \&name;

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-111237558>

sub node_type ($) { 10 } # DOCUMENT_TYPE_NODE

package Message::IF::DocumentType;
package Message::IF::DocumentTypeDefinition;
package Message::IF::DocumentTypeDeclaration;

package Message::DOM::DOMImplementation;

sub create_document_type ($$;$$) {
  return Message::DOM::DocumentType->____new (undef, @_[0, 1]);
} # create_document_type

package Message::DOM::Document;

## Spec: 
## <http://suika.fam.cx/gate/2005/sw/DocumentXDoctype>

sub create_document_type_definition ($$) {
  return Message::DOM::DocumentType->____new ($_[0], undef, $_[1]);
} # create_document_type_definition

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/15 14:32:50 $
