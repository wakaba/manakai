package Message::DOM::CSSRule;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSRule';
require Scalar::Util;

## |CSSRule| constants

sub STYLE_RULE () { 1 }
sub CHARSET_RULE () { 2 }
sub IMPORT_RULE () { 3 }
sub MEDIA_RULE () { 4 }
sub FONT_FACE_RULE () { 5 }
sub PAGE_RULE () { 6 }
sub NAMESPACE_RULE () { 7 }

## |CSSRule| attributes

sub css_text ($) {
  die "$0: ".(ref $_[0])."->css_text: Not implemented";
} # css_text

sub parent_rule ($) {
  return ${$_[0]}->{parent_rule};
} # parent_rule

sub parent_style_sheet ($) {
  if (${$_[0]}->{parent_style_sheet}) {
    return ${$_[0]}->{parent_style_sheet};
  } elsif (${$_[0]}->{parent_rule}) {
    local $Error::Depth = $Error::Depth + 1;
    return ${$_[0]}->{parent_rule}->parent_style_sheet;
  } else {
    ## NOTE: Not in the CSSOM ED: If the |CSSRule| object is not 
    ## yet associated to any CSS style sheet.  Such object should not be
    ## returned to applications - that is, the intention is that only
    ## modules belonging to manakai may get |undef| from the
    ## |parent_style_sheet| attribute during the construction of CSSOM.
    ## Therefore, this is not counted as a manakai extension to CSSOM spec.
    return undef;
  }
} # parent_style_sheet

sub type ($) {
  die "$0: ".(ref $_[0])."->type: Not implemented";
} # type

package Message::DOM::CSSStyleRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSStyleRule';

sub ____new ($$$) {
  my $self = bless \{_selectors => $_[1], style => $_[2]}, $_[0];
  ${$_[2]}->{parent_rule} = $self;
  Scalar::Util::weaken (${$_[2]}->{parent_rule});
  return $self;
} # ____new

## |CSSRule| attributes

sub css_text ($;$) {
  ## TODO: setter

  ## NOTE: Where and how white space characters are inserted are 
  ## intentionally changed from those in browsers so that properties are
  ## more prettily printed.
  ## See <http://suika.fam.cx/gate/2005/sw/cssText> for what browsers do.
  local $Error::Depth = $Error::Depth + 1;
  return $_[0]->selector_text . " {\n" . $_[0]->style->css_text . '}';
} # css_text

sub type ($) { Message::DOM::CSSRule::STYLE_RULE }

## |CSSStyleRule| attributes

sub selector_text ($;$) {
  ## TODO: setter

  ## TODO: Browser-compatible serializer
  ## TODO: This code does not work for cases where default namespace
  ## has no namespace prefix declared.
  my $self = $_[0];
  require Whatpm::CSS::SelectorsSerializer;
  return Whatpm::CSS::SelectorsSerializer->serialize_selector_text
      ($$self->{_selectors}, ${$self->parent_style_sheet}->{_nsmap});
} # selector_text

sub style ($) {
  return ${$_[0]}->{style};
} # style

package Message::DOM::CSSCharsetRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSCharsetRule';

sub ____new ($$) {
  return bless \{encoding => $_[1]}, $_[0];
} # ____new

## |CSSRule| attributes

sub css_text ($;$) {
  ## TODO: setter

  ## NOTE: It will be broken if |encoding| contains |"| or |\|, but this
  ## is what browsers do.
  return '@charset "'.${$_[0]}->{encoding}.'";';
} # css_text

sub type ($) { Message::DOM::CSSRule::CHARSET_RULE }

## |CSSCharsetRule| attribute

sub encoding ($) {
  return ${$_[0]}->{encoding};
} # encoding

package Message::DOM::CSSImportRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSImportRule';

sub ____new ($$$$) {
  my $self = bless \{href => $_[1], media => $_[2], style_sheet => $_[3]}, $_[0];
  ${$_[3]}->{owner_rule} = $self;
  Scalar::Util::weaken (${$_[3]}->{owner_rule});
  return $self;
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::IMPORT_RULE }

## |CSSImportRule| attributes

sub href ($) {
  return ${$_[0]}->{href};
} # href

sub media ($) {
  return ${$_[0]}->{media};
} # media

sub style_sheet ($) {
  return ${$_[0]}->{style_sheet};
} # style_sheet

package Message::DOM::CSSMediaRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSMediaRule';

sub ____new ($$$) {
  my $self = bless \{media => $_[1], css_rules => $_[2]}, $_[0];
  for (@{$_[2]}) {
    ${$_}->{parent_rule} = $self;
    Scalar::Util::weaken (${$_}->{parent_rule});
  }
  return $self;
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::MEDIA_RULE }

## |CSSMediaRule| attributes

sub css_rules ($) {
  require Message::DOM::CSSRuleList;
  return bless \\($_[0]), 'Message::DOM::CSSRuleList';
} # css_rules

sub media ($) {
  return ${$_[0]}->{media};
} # media

package Message::DOM::CSSFontFaceRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSFontFaceRule';

sub ____new ($$) {
  my $self = bless \{style => $_[1]}, $_[0];
  ${$_[2]}->{parent_rule} = $self;
  Scalar::Util::weaken (${$_[2]}->{parent_rule});
  return $self;
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::FONT_FACE_RULE }

## |CSSFontFaceRule| attribute

sub style ($) {
  return ${$_[0]}->{style};
} # style

package Message::DOM::CSSPageRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSPageRule';

sub ____new ($$$) {
  my $self = bless \{_selectors => $_[1], style => $_[2]}, $_[0];
  ${$_[2]}->{parent_rule} = $self;
  Scalar::Util::weaken (${$_[2]}->{parent_rule});
  return $self;
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::PAGE_RULE }

## |CSSPageRule| attributes

sub selector_text ($;$) {
  ## TODO: setter

  ## TODO: Browser-compatible serializer
  require Whatpm::CSS::SelectorsSerializer;
  return Whatpm::CSS::SelectorsSerializer->serialize_test (${$_[0]}->{_selectors});
} # selector_text

sub style ($) {
  return ${$_[0]}->{style};
} # style

package Message::DOM::CSSNamespaceRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSNamespaceRule';

sub ____new ($$$) {
  return bless \{namespace_uri => $_[2], prefix => $_[1]}, $_[0];
} # ___new

## |CSSRule| attributes

sub css_text ($;$) {
  ## TODO: Setter

  ## NOTE: Sometimes ugly, but this is what Firefox does.
  my $prefix = ${$_[0]}->{prefix};
  return '@namespace '.($prefix ne '' ? $prefix.' ' : '').
      'url('.${$_[0]}->{namespace_uri}.');';
} # css_text

sub type ($) { Message::DOM::CSSRule::NAMESPACE_RULE }

## |CSSNamespaceRule| attributes

sub namespace_uri ($) {
  return ${$_[0]}->{namespace_uri};
} # namespace_uri

sub prefix ($) {
  return ${$_[0]}->{prefix};
} # prefix

package Message::IF::CSSRule;
package Message::IF::CSSStyleRule;
package Message::IF::CSSCharsetRule;
package Message::IF::CSSImportRule;
package Message::IF::CSSMediaRule;
package Message::IF::CSSFontFaceRule;
package Message::IF::CSSPageRule;

1;
## $Date: 2008/01/14 05:53:44 $
