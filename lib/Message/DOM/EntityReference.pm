package Message::DOM::EntityReference;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::EntityReference';
require Message::DOM::Node;

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{node_name} = $_[0];
  $$self->{child_nodes} = [];
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
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ({
    ## Read-write attributes (boolean, trivial accessors)
    manakai_expanded => 1,
    manakai_external => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\${\$_[0]}->{owner_document}}->{manakai_strict_error_checking} and
              \${\$_[0]}->{manakai_read_only}) {
            report Message::DOM::DOMException
                -object => \$_[0],
                -type => 'NO_MODIFICATION_ALLOWED_ERR',
                -subtype => 'READ_ONLY_NODE_ERR';
          }
          if (\$_[1]) {
            \${\$_[0]}->{$method_name} = 1;
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
  ## NOTE: Same as |CharacterData|'s.

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

sub node_name ($); # read-only trivial accessor

sub node_type () { 5 } # ENTITY_REFERENCE_NODE

## |EntityReference| attributes

sub manakai_entity_base_uri ($;$) {
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
    if (defined $_[1]) {
      $$self->{manakai_entity_base_uri} = ''.$_[1];
    } else {
      delete $$self->{manakai_entity_base_uri};
    }
  }
  
  if (defined $$self->{manakai_entity_base_uri}) {
    return $$self->{manakai_entity_base_uri};
  } else {
    local $Error::Depth = $Error::Depth + 1;
    return $self->base_uri;
  }
} # manakai_entity_base_uri

sub manakai_expanded ($;$);

sub manakai_external ($;$);

package Message::IF::EntityReference;

package Message::DOM::Document;

sub create_entity_reference ($$) {
  our $CreateEntityReference_OpenEntity;
      ## TODO: This is Multithread unsafe

  my $self = $_[0];
  my $orig_strict = $self->strict_error_checking;
  if ($orig_strict) {
    my $xv = $self->xml_version;
    if (defined $xv) {
      if ($xv eq '1.0' and
          $_[1] =~ /\A\p{InXML_NameStartChar10}\p{InXMLNameChar10}*\z/) {
        #
      } elsif ($xv eq '1.1' and
               $_[1] =~ /\A\p{InXMLNameStartChar11}\p{InXMLNameChar11}*\z/) {
        #
      } else {
        report Message::DOM::DOMException
            -object => $self,
            -type => 'INVALID_CHARACTER_ERR',
            -subtype => 'MALFORMED_NAME_ERR';
      }
    }
  }

  my $r = Message::DOM::EntityReference->____new ($self, $_[1]);

  ## Expansion
  unless ($CreateEntityReference_OpenEntity->{$_[1]}) {
    local $CreateEntityReference_OpenEntity->{$_[1]} = 1;
    local $Error::Depth = $Error::Depth + 1;

    my $doctype = $self->doctype;
    unless ($doctype) {
      $r->manakai_set_read_only (1, 1);
      return $r;
    }

    my $ent = $doctype->get_general_entity_node ($_[1]);
    unless ($ent) {
      $r->manakai_set_read_only (1, 1);
      return $r;
    }

    $self->strict_error_checking (0);
    for my $c (@{$ent->child_nodes}) {
      my $clone = $c->clone_node (1);
      $r->append_child ($clone);
    }
    $r->manakai_expanded ($ent->has_replacement_tree);
    $self->strict_error_checking ($orig_strict);
  }
  $r->manakai_set_read_only (1, 1);
  return $r;
} # create_entity_reference

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/14 16:32:28 $
