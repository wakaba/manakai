package Message::DOM::CSSStyleSheet;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSStyleSheet';

sub new ($) {
  return bless \{css_rules => []}, shift;
} # new

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    href => 1,
    owner_node => 1,
    owner_rule => 1,
    parent_style_sheet => 1,
    type => 1,
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

## |StyleSheet| attributes

sub disabled ($;$) {
  if (@_ > 1) {
    if ($_[1]) {
      ${$_[0]}->{disabled} = 1;
    } else {
      delete ${$_[0]}->{disabled};
    }
  }
  return ${$_[0]}->{disabled};
} # disabled

sub href ($);

## TODO: media

sub owner_node ($);

sub parent_style_sheet ($);

sub title ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      ${$_[0]}->{title} = ''.$_[1];
    } else {
      delete ${$_[0]}->{title};
    }
  }
  return ${$_[0]}->{title};
} # title

sub type ($);

## |CSSStyleSheet| attributes

sub css_rules ($) {
  require Message::DOM::CSSRuleList;
  return bless \\($_[0]), 'Message::DOM::CSSRuleList';
} # css_rules

sub owner_rule ($);

## |CSSStyleSheet| methods

## TODO: delete_rule

## TODO: insert_rule

package Message::IF::StyleSheet;
package Message::IF::CSSStyleSheet;

1;
## $Date: 2007/12/22 06:29:32 $
