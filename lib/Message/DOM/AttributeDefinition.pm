package Message::DOM::AttributeDefinition;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::AttributeDefinition';
require Message::DOM::Node;

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{node_name} = $_[0];
  $$self->{child_nodes} = [];
  $$self->{allowed_token} = [];
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    node_name => 1,
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

## |DefaultValueType|
sub UNKNOWN_DEFAULT () { 0 }
sub FIXED_DEFAULT () { 1 }
sub REQUIRED_DEFAULT () { 2 }
sub IMPLIED_DEFAULT () { 3 }
sub EXPLICIT_DEFAULT () { 4 }

## The |Node| interface - attribute

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-F68D095>
## <http://suika.fam.cx/gate/2005/sw/AttributeDefinition>

sub node_name ($); # read-only trivial accessor

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-111237558>

sub node_type ($) { 81002 } # ATTRIBUTE_DEFINITION_NODE

## Spec:
## <http://suika.fam.cx/gate/2005/sw/AttributeDefinition#anchor-2>

## TODO: node_value

## |AttributeDefinition| attributes

sub allowed_token ($) {
  ## TODO:
  return ${$_[0]}->{allowed_token};
} 

sub declared_type ($;$) {
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
      $$self->{declared_type} = 0+$_[1];
    } else {
      delete $$self->{declared_type};
    }
  }
  
  return $$self->{declared_type} || 0;
} # declared_type

sub default_type ($;$) {
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
      $$self->{default_type} = 0+$_[1];
    } else {
      delete $$self->{default_type};
    }
  }
  
  return $$self->{default_type} || 0;
} # default_type

package Message::IF::AttributeDefinition;

package Message::DOM::Document;

## Spec: 
## <http://suika.fam.cx/gate/2005/sw/DocumentXDoctype>

sub create_attribute_definition ($$) {
  return Message::DOM::AttributeDefinition->____new (@_[0, 1]);
} # create_attribute_definition

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/17 14:15:38 $
