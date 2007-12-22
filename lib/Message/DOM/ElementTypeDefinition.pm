package Message::DOM::ElementTypeDefinition;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.14 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

sub node_name ($);

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

sub get_attribute_definition_node ($$) {
  return ${$_[0]}->{attribute_definitions}->{$_[1]};
} # get_attribute_definition_node

sub set_attribute_definition_node ($$) {
  my $self = $_[0];
  my $node = $_[1];

  my $name = $node->node_name;
  my $list = $$self->{attribute_definitions} ||= {}; # ***
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

    my $owner = $$node->{owner_element_type_definition}; # ***
    if ($owner) {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'HIERARCHY_REQUEST_ERR',
          -subtype => 'INUSE_DEFINITION_ERR';
    }
  }

  if (defined $r) {
    delete $$r->{owner_element_type_definition}; # ***
  }

  $list->{$name} = $node;
  $$node->{owner_element_type_definition} = $self; # ***
  Scalar::Util::weaken ($$node->{owner_element_type_definition}); # ***
} # set_attribute_definition_node

package Message::IF::ElementTypeDefinition;

package Message::DOM::Document;

sub create_element_type_definition ($$) {
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

  return Message::DOM::ElementTypeDefinition->____new (@_[0, 1]);
} # create_element_type_definition

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/12/22 06:29:32 $
