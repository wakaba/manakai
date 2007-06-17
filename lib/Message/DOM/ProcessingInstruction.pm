package Message::DOM::ProcessingInstruction;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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
    data => 1,
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
sub target ($);
sub data ($);

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

## The target of the processing instruction [DOM1, DOM2].
## Same as |ProcessingInstruction.target| [DOM3].

*node_name = \&target;

sub node_type () { 7 } # PROCESSING_INSTRUCTION_NODE

## The entire content exclude the target [DOM1, DOM2].
## Same as |ProcessingInstruction.data| [DOM3].

*node_value = \&data;

*text_content = \&node_value;

## |Node| methods

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

## |ProcessingInstruction| attributes

sub manakai_base_uri ($;$);

package Message::IF::ProcessingInstruction;

package Message::DOM::Document;

sub create_processing_instruction ($$$) {
  return Message::DOM::ProcessingInstruction->____new (@_[0, 1, 2]);
} # create_processing_instruction

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/17 13:37:40 $
