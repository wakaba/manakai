## NOTE: This module will be renamed as Element.pm.

package Message::DOM::Element;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Element';
require Message::DOM::Node;

sub ____new ($$$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{namespace_uri},
   $$self->{prefix},
   $$self->{local_name}) = @_;
  $$self->{attributes} = {};
  $$self->{child_nodes} = [];
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    namespace_uri => 1,
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
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          if (\${\$_[0]}->{manakai_read_only}) {
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

## The |Node| interface - attributes

sub attributes ($) {
  my $self = shift;
  my $r = []; ## TODO: NamedNodeMap
  ## Order MUST be stable
  for my $ns (sort {$a cmp $b} keys %{$$self->{attributes}}) {
    for my $ln (sort {$a cmp $b} keys %{$$self->{attributes}->{$ns}}) {
      push @$r, $$self->{attributes}->{$ns}->{$ln}
        if defined $$self->{attributes}->{$ns}->{$ln};
    }
  }
  return $r;
} # attributes

sub local_name ($) { # TODO: HTML5 case
  return ${$_[0]}->{local_name};
} # local_name

sub manakai_local_name ($) {
  return ${$_[0]}->{local_name};
} # manakai_local_name

sub namespace_uri ($);

## The tag name of the element [DOM1, DOM2].
## Same as |Element.tagName| [DOM3].

*node_name = \&tag_name;

sub node_type () { 1 } # ELEMENT_NODE


sub prefix ($;$) {
  ## NOTE: No check for new value as Firefox doesn't do.
  ## See <http://suika.fam.cx/gate/2005/sw/prefix>.

  ## NOTE: Same as trivial setter except "" -> undef

  ## NOTE: Same as |Attr|'s |prefix|.
  
  if (@_ > 1) {
    if (${$_[0]}->{manakai_read_only}) {
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

## The |Node| interface - method

sub clone_node ($$) {
  my ($self, $deep) = @_; ## NOTE: Deep cloning is not supported
## TODO: constructor
  my $clone = bless {
    namespace_uri => $$self->{namespace_uri},
    prefix => $$self->{prefix},
    local_name => $$self->{local_name},      
    child_nodes => [],
  }, ref $self;
  for my $ns (keys %{$$self->{attributes}}) {
    for my $ln (keys %{$$self->{attributes}->{$ns}}) {
      my $attr = $$self->{attributes}->{$ns}->{$ln};
## TODO: Attr constructor
      $$clone->{attributes}->{$ns}->{$ln} = bless {
        namespace_uri => $$attr->{namespace_uri},
        prefix => $$attr->{prefix},
        local_name => $$attr->{local_name},
        value => $$attr->{value},
      }, ref $$self->{attributes}->{$ns}->{$ln};
    }
  }
  return $clone;
} # clone_node

## The |Element| interface - attribute

## TODO: HTML5 capitalization
sub tag_name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # tag_name

## The |Element| interface - methods

sub manakai_element_type_match ($$$) {
  my ($self, $nsuri, $ln) = @_;
  if (defined $nsuri) {
    if (defined $$self->{namespace_uri} and $nsuri eq $$self->{namespace_uri}) {
      return ($ln eq $$self->{local_name});
    } else {
      return 0;
    }
  } else {
    if (not defined $$self->{namespace_uri}) {
      return ($ln eq $$self->{local_name});
    } else {
      return 0;
    }
  }
} # manakai_element_type_match

sub get_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return defined $$self->{attributes}->{$nsuri}->{$ln}
    ? $$self->{attributes}->{$nsuri}->{$ln}->value : undef;
} # get_attribute_ns

sub get_attribute_node_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return $$self->{attributes}->{$nsuri}->{$ln};
} # get_attribute_node_ns

sub has_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  $nsuri = '' unless defined $nsuri;
  return defined $$self->{attributes}->{$nsuri}->{$ln};
} # has_attribute_ns

## The second parameter only supports manakai extended way
## to specify qualified name - "[$prefix, $local_name]"
sub set_attribute_ns ($$$$) {
  my ($self, $nsuri, $qn, $value) = @_;
  require Message::DOM::Attr;
  my $attr = Message::DOM::Attr->____new
    ($$self->{owner_document}, $self, $nsuri, $qn->[0], $qn->[1]);
  $$self->{attributes}->{$nsuri}->{$qn->[1]} = $attr;
  $attr->value ($value);
} # set_attribute_ns

package Message::IF::Element;

package Message::DOM::Document;

sub create_element ($$) {
  ## TODO: HTML5
  return Message::DOM::Element->____new ($_[0], undef, undef, $_[1]);
} # create_element

sub create_element_ns ($$$) {
  my ($prefix, $lname);
  if (ref $_[2] eq 'ARRAY') {
    ($prefix, $lname) = @{$_[2]};
  } else {
    ($prefix, $lname) = split /:/, $_[2], 2;
    ($prefix, $lname) = (undef, $prefix) unless defined $lname;
  }
  return Message::DOM::Element->____new ($_[0], $_[1], $prefix, $lname);
} # create_element_ns

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/16 15:27:45 $
