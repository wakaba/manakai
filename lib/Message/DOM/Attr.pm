package Message::DOM::Attr;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Attr';
require Message::DOM::Node;

sub ____new ($$$$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{owner_element},
   $$self->{namespace_uri},
   $$self->{prefix},
   $$self->{local_name}) = @_;
  Scalar::Util::weaken ($$self->{owner_element});
  $$self->{child_nodes} = [];
  $$self->{specified} = 1;
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    namespace_uri => 1,
    owner_element => 1,
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
sub owner_element ($);

## |Node| attributes

sub base_uri ($) {
  my $self = $_[0];
  local $Error::Depth = $Error::Depth + 1;
  my $oe = $self->owner_element;
  if ($oe) {
    my $ln = $self->local_name;
    my $nsuri = $self->namespace_uri;
    if (($ln eq 'base' and
         defined $nsuri and $nsuri eq 'http://www.w3.org/XML/1998/namespace') or
        ($ln eq 'xml:base' and not defined $nsuri)) {
      my $oep = $oe->parent_node;
      if ($oep) {
        return $oep->base_uri;
      } else {
        return $self->owner_document->base_uri;
      }
    } else {
      return $oe->base_uri;
    }
  } else {
    return $self->owner_document->base_uri;
  }
} # base_uri

sub local_name ($) {
  ## TODO: HTML5
  return ${+shift}->{local_name};
} # local_name

sub manakai_local_name ($) {
  return ${$_[0]}->{local_name};
} # manakai_local_name

sub namespace_uri ($);

## The name of the attribute [DOM1, DOM2].
## Same as |Attr.name| [DOM3].

*node_name = \&name;

sub node_type () { 2 } # ATTRIBUTE_NODE

## The value of the attribute [DOM1, DOM2].
## Same as |Attr.value| [DOM3].

*node_value = \&value;

sub prefix ($;$) {
  ## NOTE: No check for new value as Firefox doesn't do.
  ## See <http://suika.fam.cx/gate/2005/sw/prefix>.

  ## NOTE: Same as trivial setter except "" -> undef

  ## NOTE: Same as |Element|'s |prefix|.
  
  if (@_ > 1) {
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and 
        ${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    if (defined $_[1] and $_[1] ne '') {
      ${$_[0]}->{prefix} = ''.$_[1];
    } else {
      delete ${$_[0]}->{prefix};
    }
  }
  return ${$_[0]}->{prefix}; 
} # prefix

## |Attr| attributes

sub manakai_attribute_type ($;$) {
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
      $$self->{manakai_attribute_type} = 0+$_[1];
    } else {
      delete $$self->{manakai_attribute_type};
    }
  }
  
  return $$self->{manakai_attribute_type} || 0;
} # manakai_attribute_type

## TODO: HTML5 case stuff?
sub name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # name

sub specified ($;$) {
  if (@_ > 1) {
    ## NOTE: A manakai extension.
    if (${${$_[0]}->{owner_document}}->{strict_error_checking} and 
        ${$_[0]}->{manakai_read_only}) {
      report Message::DOM::DOMException
          -object => $_[0],
          -type => 'NO_MODIFICATION_ALLOWED_ERR',
          -subtype => 'READ_ONLY_NODE_ERR';
    }
    if ($_[1] or not defined ${$_[0]}->{owner_element}) {
      ${$_[0]}->{specified} = 1;
    } else {
      delete ${$_[0]}->{specified};
    }
  }
  return ${$_[0]}->{specified}; 
} # specified

sub value ($;$) {
  ## TODO:
  shift->text_content (@_);
} # value

package Message::IF::Attr;

package Message::DOM::Document;

sub create_attribute ($$) {
  ## TODO: HTML5
  return Message::DOM::Attr->____new ($_[0], undef, undef, undef, $_[1]);
} # create_attribute

sub create_attribute_ns ($$$) {
  my ($prefix, $lname);
  if (ref $_[2] eq 'ARRAY') {
    ($prefix, $lname) = @{$_[2]};
  } else {
    ($prefix, $lname) = split /:/, $_[2], 2;
    ($prefix, $lname) = (undef, $prefix) unless defined $lname;
  }
  return Message::DOM::Attr->____new ($_[0], undef, $_[1], $prefix, $lname);
} # create_element_ns

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/17 13:37:40 $
