package Message::DOM::ElementTypeDefinition;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::ElementTypeDefinition';
require Message::DOM::Node;

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
    owner_document_type_definition => 1,
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

sub append_child ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # append_child

sub manakai_append_text () { }

sub insert_before ($;$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # insert_before

sub replace_child ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # replace_child

## |ElementTypeDefinition| attributes

sub attribute_definitions ($) {
  require Message::DOM::NamedNodeMap;
  return bless \[$_[0], 'attribute_definitions'], 'Message::DOM::NamedNodeMap';
} # attribute_definitions

sub owner_document_type_definition ($);

## |ElementTypeDefinition| methods

## TODO:
sub set_attribute_definition_node {
  ${$_[0]}->{attribute_definitions}->{$_[1]->node_name} = $_[1];
  ${$_[1]}->{owner_element_type_definition} = $_[0];
  Scalar::Util::weaken (${$_[1]}->{owner_element_type_definition});
}

package Message::IF::ElementTypeDefinition;

package Message::DOM::Document;

sub create_element_type_definition ($$) {
  return Message::DOM::ElementTypeDefinition->____new (@_[0, 1]);
} # create_element_type_definition

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/12 13:54:46 $
