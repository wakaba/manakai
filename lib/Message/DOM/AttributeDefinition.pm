package Message::DOM::AttributeDefinition;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::AttributeDefinition';
require Message::DOM::Node;
require Message::DOM::Attr;

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{node_name} = $_[0];
  $$self->{child_nodes} = [];
  $$self->{allowed_tokens} = [];
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    node_name => 1,
    owner_element_type_definition => 1,
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

## |Node| attributes

sub node_name ($); # read-only trivial accessor

sub node_type () { 81002 } # ATTRIBUTE_DEFINITION_NODE

*node_value = \&Message::DOM::Node::text_content;

## |Node| methods

*append_child = \&Message::DOM::Attr::append_child;

*insert_before = \&Message::DOM::Attr::insert_before;

*replace_child = \&Message::DOM::Attr::replace_child;

## |AttributeDefinition| attributes

sub allowed_tokens ($) {
  require Message::DOM::DOMStringList;
  return bless \[$_[0], 'allowed_tokens'], 'Message::DOM::DOMStringList';
} # allowed_tokens

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

sub owner_element_type_definition ($);

package Message::IF::AttributeDefinition;

package Message::DOM::Document;

sub create_attribute_definition ($$) {
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

  return Message::DOM::AttributeDefinition->____new (@_[0, 1]);
} # create_attribute_definition

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 09:19:11 $
