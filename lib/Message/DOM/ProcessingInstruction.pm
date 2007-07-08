package Message::DOM::ProcessingInstruction;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::ProcessingInstruction';
require Message::DOM::Node;

sub ____new ($$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{target}, $$self->{data}) = @_;
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    target => 1,
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
    manakai_base_uri => 1,
    data => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\${\$_[0]}->{owner_document}}->{strict_error_checking} and
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
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## |Node| attributes

sub base_uri ($) {
  my $self = $_[0];
  return $$self->{manakai_base_uri} if defined $$self->{manakai_base_uri};
  
  local $Error::Depth = $Error::Depth + 1;
  my $node = $$self->{parent_node};
  while (defined $node) {
    my $nt = $node->node_type;
    if ($nt == 1 or $nt == 6 or $nt == 9 or $nt == 10 or $nt == 11) {
      ## Element, Entity, Document, DocumentType, or DocumentFragment
      return $node->base_uri;
    } elsif ($nt == 5) {
      ## EntityReference
      return $node->manakai_entity_base_uri if $node->manakai_external;
    }
    $node = $$node->{parent_node};
  }
  return $node->base_uri if $node;
  return $self->owner_document->base_uri;
} # base_uri

sub child_nodes ($) {
  require Message::DOM::NodeList;
  return bless \\($_[0]), 'Message::DOM::NodeList::EmptyNodeList';
} # child_nodes

*node_name = \&target;

sub node_type () { 7 } # PROCESSING_INSTRUCTION_NODE

*node_value = \&data;

*text_content = \&node_value;

## |Node| methods

sub append_child ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # append_child

sub manakai_append_text ($$) {
  ## NOTE: Same as |CharacterData|'s.
  if (${${$_[0]}->{owner_document}}->{strict_error_checking} and
      ${$_[0]}->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }
  ${$_[0]}->{data} .= ref $_[1] eq 'SCALAR' ? ${$_[1]} : $_[1];
} # manakai_append_text

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

## |ProcessingInstruction| attributes

sub manakai_base_uri ($;$);

sub data ($;$);

sub target ($);

package Message::IF::ProcessingInstruction;

package Message::DOM::Document;

sub create_processing_instruction ($$$) {
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

  return Message::DOM::ProcessingInstruction->____new (@_[0, 1, 2]);
} # create_processing_instruction

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 13:04:37 $
