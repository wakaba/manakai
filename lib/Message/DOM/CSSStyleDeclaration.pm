package Message::DOM::CSSStyleDeclaration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSStyleDeclaration';

sub ____new ($) {
  return bless \{}, $_[0];
} # ____new

## |CSSStyleDeclaration| attributes

sub parent_rule ($) {
  return ${$_[0]}->{parent_rule};
} # parent_rule

## TODO: Implement other methods and attributes

package Message::IF::CSSStyleDeclaration;

1;
## $Date: 2007/12/22 06:29:32 $
