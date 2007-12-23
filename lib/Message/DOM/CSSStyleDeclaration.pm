package Message::DOM::CSSStyleDeclaration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSStyleDeclaration';

sub ____new ($) {
  return bless \{}, $_[0];
} # ____new

## |CSSStyleDeclaration| attributes

sub css_text ($;$) {
  ## TODO: Implement ...
  return '';
} # css_text

sub parent_rule ($) {
  return ${$_[0]}->{parent_rule};
} # parent_rule

## TODO: Implement other methods and attributes

package Message::IF::CSSStyleDeclaration;

1;
## $Date: 2007/12/23 08:18:59 $
