package Message::DOM::DocumentType;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::DocumentType',
    'Message::IF::DocumentTypeDefinition',
    'Message::IF::DocumentTypeDeclaration';
require Message::DOM::Node;

sub ____new ($$$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{implementation} = $_[0] if defined $_[0];
  $$self->{name} = $_[1];
  $$self->{child_nodes} = [];
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

## The document type name [DOM1, DOM2].
## Same as |DocumentType.name| [DOM3].

*node_name = \&name;

sub node_type { 10 } # DOCUMENT_TYPE_NODE

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
## $Date: 2007/06/16 08:05:48 $
