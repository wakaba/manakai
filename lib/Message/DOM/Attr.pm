package Message::DOM::Attr;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::Attr';
require Message::DOM::Node;

sub ____new ($$$$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{owner_element},
   $$self->{namespace_uri},
   $$self->{prefix},
   $$self->{local_name}) = @_;
  Scalar::Util::weaken ($$self->{owner_element});
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    owner_element => 1,
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
      sub $method_name (\$) {
        if (\@_ > 1) {
          \${\$_[0]}->{$method_name} = ''.$_[1];
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
sub owner_element ($);

## The |Node| interface - attribute

sub node_type { 2 } # ATTRIBUTE_NODE

## The |Attr| interface - attribute

## TODO: HTML5 case stuff?
sub name ($) {
  my $self = shift;
  if (defined $$self->{prefix}) {
    return $$self->{prefix} . ':' . $$self->{local_name};
  } else {
    return $$self->{local_name};
  }
} # name

sub value ($;$) {
  if (@_ > 1) {
    ${$_[0]}->{value} = $_[1];
  }
  return ${$_[0]}->{value};
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
## $Date: 2007/06/13 12:05:35 $
