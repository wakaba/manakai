package Message::DOM::ElementTypeDefinition;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::ElementTypeDefinition';
require Message::DOM::Node;

## Spec:
## <http://suika.fam.cx/gate/2005/sw/ElementTypeDefinition>

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{node_name} = $_[0];
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

## |Node| attributes

sub child_nodes ($) {
  require Message::DOM::NodeList;
  return bless \\($_[0]), 'Message::DOM::NodeList::EmptyNodeList';
} # child_nodes

sub node_name ($); # read-only trivial accessor

sub node_type () { 81001 } # ELEMENT_TYPE_DEFINITION_NODE

sub text_content () { undef }

## |Node| methods

sub manakai_append_text () { }

## |ElementTypeDefinition| attributes

## TODO:
sub attribute_definitions {
  return [values %{${$_[0]}->{attribute_definitions} or {}}];
}

## |ElementTypeDefinition| methods

## TODO:
sub set_attribute_definition_node {
  ${$_[0]}->{attribute_definitions}->{$_[1]->node_name} = $_[1];
  ${$_[1]}->{owner_element_type_definition} = $_[0];
  Scalar::Util::weaken (${$_[1]}->{owner_element_type_definition});
}

package Message::IF::ElementTypeDefinition;

package Message::DOM::Document;

## Spec: 
## <http://suika.fam.cx/gate/2005/sw/DocumentXDoctype>

sub create_element_type_definition ($$) {
  return Message::DOM::ElementTypeDefinition->____new (@_[0, 1]);
} # create_element_type_definition

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/17 13:37:40 $
