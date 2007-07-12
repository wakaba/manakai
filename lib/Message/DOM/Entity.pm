package Message::DOM::Entity;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Entity';
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
  } elsif ({
    ## Read-write attributes (boolean, trivial accessors)
    has_replacement_tree => 1,
    is_externally_declared => 1,
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
  } elsif ({
    ## Read-write attributes (DOMString, trivial accessors)
    input_encoding => 1,
    notation_name => 1,
    public_id => 1,
    system_id => 1,
    xml_encoding => 1,
    xml_version => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\$_[0]}->{strict_error_checking} and
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

sub node_name ($); # read-only trivial accessor

sub node_type () { 6 } # ENTITY_NODE

## |Entity| attributes

sub manakai_declaration_base_uri ($;$) {
  ## NOTE: Same as |Notation|'s.

  if (@_ > 1) {
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and 
        ${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    if (defined $_[1]) {
      ${$_[0]}->{manakai_declaration_base_uri} = ''.$_[1];
    } else {
      delete ${$_[0]}->{manakai_declaration_base_uri};
    }
  }
  
  if (defined wantarray) {
    if (defined ${$_[0]}->{manakai_declaration_base_uri}) {
      return ${$_[0]}->{manakai_declaration_base_uri};
    } else {
      local $Error::Depth = $Error::Depth + 1;
      return $_[0]->base_uri;
    }  
  }
} # manakai_declaration_base_uri

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

  if (defined wantarray) {
    if (defined $$self->{manakai_entity_base_uri}) {
      return $$self->{manakai_entity_base_uri};
    } else {
      local $Error::Depth = $Error::Depth + 1;
      my $v = $self->manakai_entity_uri;
      return $v if defined $v;
      return $self->base_uri;
    }
  }
} # manakai_entity_base_uri

sub manakai_entity_uri ($;$) {
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
      $$self->{manakai_entity_uri} = ''.$_[1];
    } else {
      delete $$self->{manakai_entity_uri};
    }
  }

  if (defined wantarray) {
    return $$self->{manakai_entity_uri} if defined $$self->{manakai_entity_uri};

    local $Error::Depth = $Error::Depth + 1;
    my $v = $$self->{system_id};
    if (defined $v) {
      $v = ${$$self->{owner_document}}->{implementation}->create_uri_reference
        ($v);
      if (not defined $v->uri_scheme) {
        my $base = $self->manakai_declaration_base_uri;
        return $v->get_absolute_reference ($base)->uri_reference
            if defined $base;
      }
      return $v->uri_reference;
    } else {
      return undef;
    }
  }
} # manakai_entity_uri

## NOTE: Setter is a manakai extension.
## TODO: Document it.
sub input_encoding ($;$);

## NOTE: Setter is a manakai extension.
## TODO: Document it.
sub is_externally_declared ($;$);
#    @@enDesc:
#      Whether the entity is declared by an external markup declaration,
#      i.e. a markup declaration occuring in the external subset or
#      in a parameter entity.
#    @@Type: boolean
#    @@TrueCase:
#      @@@enDesc:
#        If the entity is declared by an external markup declaration.
#    @@FalseCase:
#      @@@enDesc:
#        If the entity is declared by a markup declaration in
#        the internal subset, or if the <IF::Entity> node
#        is created in memory.

## NOTE: Setter is a manakai extension.
sub notation_name ($;$);

## NOTE: A manakai extension.
sub owner_document_type_definition ($);

## NOTE: Setter is a manakai extension.
sub public_id ($;$);

## NOTE: Setter is a manakai extension.
sub system_id ($;$);

## NOTE: Setter is a manakai extension.
sub xml_encoding ($;$);

## NOTE: Setter is a manakai extension.
## TODO: Document it. ## TODO: e.g. xml_version = '3.7'
## TODO: Spec does not mention |null| case
## TODO: Should we provide default?
sub xml_version ($;$);

## |Entity| methods

## NOTE: A manakai extension
sub has_replacement_tree ($;$);

package Message::IF::Entity;

package Message::DOM::Document;

sub create_general_entity ($$) {
  return Message::DOM::Entity->____new (@_[0, 1]);
} # create_general_entity

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/12 13:54:46 $
