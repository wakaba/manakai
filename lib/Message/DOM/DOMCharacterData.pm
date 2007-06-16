## NOTE: This module will be renamed as CharacterData.pm

package Message::DOM::CharacterData;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::CharacterData';
require Message::DOM::Node;

sub ____new ($$$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{data} = $_[0];
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
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
    data => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        if (\@_ > 1) {
          \${\$_[0]}->{$method_name} = ''.\$_[1];
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
sub data ($;$);

## The |Node| interface - attribute

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

*text_content = \&node_value; # For |CDATASection|, |Comment|, and |Text|.

## The |Node| interface - method

## A manakai extension
sub manakai_append_text ($$) {
  my ($self, $s) = @_;
  $$self->{data} .= $s;
} # manakai_append_text

package Message::IF::CharacterData;

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/16 15:27:45 $
