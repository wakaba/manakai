## NOTE: This module will be renamed as CharacterData.pm

package Message::DOM::CharacterData;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.18 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::CharacterData';
require Message::DOM::Node;
use Message::Util::Error;

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{data} = ''.(ref $_[0] eq 'SCALAR' ? ${$_[0]} : $_[0]);
  return $self;
} # ____new
             
## |Node| attributes

sub base_uri ($) {
  ## NOTE: Same as |EntityReference|'s.

  my $self = $_[0];
  local $Error::Depth = $Error::Depth + 1;
  my $pe = $$self->{parent_node};
  while (defined $pe) {
    my $nt = $pe->node_type;
    if ($nt == 1 or $nt == 2 or $nt == 6 or $nt == 9 or $nt == 11) {
      ## Element, Attr, Entity, Document, or DocumentFragment
      return $pe->base_uri;
    } elsif ($nt == 5) {
      ## EntityReference
      return $pe->manakai_entity_base_uri if $pe->manakai_external;
    }
    $pe = $$pe->{parent_node};
  }
  return $pe->base_uri if $pe;
  return $$self->{owner_document}->base_uri;
} # base_uri

sub child_nodes ($) {
  require Message::DOM::NodeList;
  return bless \\($_[0]), 'Message::DOM::NodeList::EmptyNodeList';
} # child_nodes

## |CDATASection|:
## The content of the CDATA section [DOM1, DOM2, DOM3].
## Same as |CharacterData.data| [DOM3].

## |Comment|:
## The content of the comment [DOM1, DOM2, DOM3].
## Same as |CharacterData.data| [DOM3].

## |Text|:
## The content of the text node [DOM1, DOM2, DOM3].
## Same as |CharacterData.data| [DOM3].

*node_value = \&data; # For |CDATASection|, |Comment|, and |Text|.

## ISSUE: DOM3 Core does not explicitly say setting |null|
## on read-only node is ignored.  Strictly speaking, it does not even
## say what the setter does for |CharacterData| and PI nodes.
## What if setting |null| to non read-only |CharacterData| or PI?

*text_content = \&node_value; # For |CDATASection|, |Comment|, and |Text|.

## |Node| methods

sub append_child ($$) {
  report Message::DOM::DOMException
      -object => $_[0],
      -type => 'HIERARCHY_REQUEST_ERR',
      -subtype => 'CHILD_NODE_TYPE_ERR';
} # append_child

sub manakai_append_text ($$) {
  ## NOTE: Same as |ProcessingInstruction|'s.
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

## |CharacterData| attributes

sub data ($;$) {
  if (@_ > 1) {
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and
        ${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }

    if (defined $_[1]) {
      ${$_[0]}->{data} = ''.$_[1];
    } else {
      ${$_[0]}->{data} = ''; # for |text_content|.
    }
  }

  return ${$_[0]}->{data};
} # data

sub length ($) {
  my $self = $_[0];
  my $r = CORE::length $$self->{data};
  $r++ while $$self->{data} =~ /[\x{10000}-\x{10FFFF}]/g;
  return $r;
} # length

## |CharacterData| methods

*append_data = \&manakai_append_text;

sub delete_data ($;$) {
  my $self = $_[0];
  my $offset = 0+$_[1];
  my $count = 0+$_[2];
  
  if ($offset < 0 or $count < 0) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'INDEX_SIZE_ERR',
        -subtype => 'INDEX_OUT_OF_BOUND_ERR';
  }

  require Message::DOM::StringExtended;

  my $offset32;
  try {
    $offset32 = Message::DOM::StringExtended::find_offset32
        ($$self->{data}, $offset);
  } catch Error::Simple with {
    my $err = shift;
    if ($err->text eq "String index out of bounds\n") {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'INDEX_SIZE_ERR',
          -subtype => 'INDEX_OUT_OF_BOUND_ERR';
    } else {
      $err->throw;
    }
  };

  my $eoffset32;
  try {
    $eoffset32 = Message::DOM::StringExtended::find_offset32
        ($$self->{data}, $offset + $count);
  } catch Error::Simple with {
    my $err = shift;
    if ($err->text eq "String index out of bounds\n") {
      $eoffset32 = ($offset + $count) * 2;
    } else {
      $err->throw;
    }
  };

  substr ($$self->{data}, $offset32, $eoffset32 - $offset32) = '';
  return undef;
} # delete_data

sub insert_data ($$$) {
  my $self = $_[0];
  my $offset = 0+$_[1];

  if (${$$self->{owner_document}}->{strict_error_checking} and
      $$self->{manakai_read_only}) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'NO_MODIFICATION_ALLOWED_ERR',
        -subtype => 'READ_ONLY_NODE_ERR';
  }

  if ($offset < 0) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'INDEX_SIZE_ERR',
        -subtype => 'INDEX_OUT_OF_BOUND_ERR';
  }

  require Message::DOM::StringExtended;
  my $offset32;
  try {
    $offset32 = Message::DOM::StringExtended::find_offset32
        ($$self->{data}, $offset);
  } catch Error::Simple with {
    my $err = shift;
    if ($err->text eq "String index out of bounds\n") {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'INDEX_SIZE_ERR',
          -subtype => 'INDEX_OUT_OF_BOUND_ERR';
    } else {
      $err->throw;
    }
  };
  substr ($$self->{data}, $offset32, 0) = $_[2];
} # insert_data

sub replace_data ($;$$) {
  my $self = $_[0];
  my $offset = 0+$_[1];
  my $count = 0+$_[2];
  
  if ($offset < 0 or $count < 0) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'INDEX_SIZE_ERR',
        -subtype => 'INDEX_OUT_OF_BOUND_ERR';
  }

  require Message::DOM::StringExtended;

  my $offset32;
  try {
    $offset32 = Message::DOM::StringExtended::find_offset32
        ($$self->{data}, $offset);
  } catch Error::Simple with {
    my $err = shift;
    if ($err->text eq "String index out of bounds\n") {
      report Message::DOM::DOMException
          -object => $self,
          -type => 'INDEX_SIZE_ERR',
          -subtype => 'INDEX_OUT_OF_BOUND_ERR';
    } else {
      $err->throw;
    }
  };

  my $eoffset32;
  try {
    $eoffset32 = Message::DOM::StringExtended::find_offset32
        ($$self->{data}, $offset + $count);
  } catch Error::Simple with {
    my $err = shift;
    if ($err->text eq "String index out of bounds\n") {
      $eoffset32 = ($offset + $count) * 2;
    } else {
      $err->throw;
    }
  };

  substr ($$self->{data}, $offset32, $eoffset32 - $offset32) = $_[3];
  return undef;
} # replace_data

sub substring_data ($;$$) {
  my $self = $_[0];
  my $offset = 0+$_[1];
  my $count = 0+$_[2];
  
  if ($offset < 0 or $count < 0) {
    report Message::DOM::DOMException
        -object => $self,
        -type => 'INDEX_SIZE_ERR',
        -subtype => 'INDEX_OUT_OF_BOUND_ERR';
  }

  require Message::DOM::StringExtended;

  my $eoffset32;
  try {
    $eoffset32 = Message::DOM::StringExtended::find_offset32
        ($$self->{data}, $offset + $count);
  } catch Error::Simple with {
    my $err = shift;
    if ($err->text eq "String index out of bounds\n") {
      $eoffset32 = ($offset + $count) * 2;
    } else {
      $err->throw;
    }
  };
   
  local $Error::Depth = $Error::Depth + 1;
  my $offset32 = Message::DOM::StringExtended::find_offset32
      ($$self->{data}, $offset);
  return substr $$self->{data}, $offset32, $eoffset32 - $offset32;
} # substring_data

package Message::DOM::CharacterData::Comment;
push our @ISA, 'Message::DOM::CharacterData', 'Message::IF::Comment';

## |Node| attributes

sub node_name () { '#comment' }

sub node_type () { 8 } # COMMENT_NODE

package Message::IF::CharacterData;
package Message::IF::Comment;

package Message::DOM::Document;

sub create_comment ($$) {
  return Message::DOM::CharacterData::Comment->____new ($_[0], $_[1]);
} # create_comment

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/29 08:31:14 $
