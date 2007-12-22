package Message::DOM::CSSRule;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSRule';

## |CSSRule| constants

sub STYLE_RULE () { 1 }
sub CHARSET_RULE () { 2 }
sub IMPORT_RULE () { 3 }
sub MEDIA_RULE () { 4 }
sub FONT_FACE_RULE () { 5 }
sub PAGE_RULE () { 6 }
sub NAMESPACE_RULE () { 7 }

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    parent_rule => 1,
    parent_style_sheet => 1,
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

## |CSSRule| attributes

sub css_text ($) {
  die "$0: ".(ref $self)."->css_text: Not implemented";
} # css_text

sub parent_rule ($);

sub parent_style_sheet ($);

sub type ($) {
  die "$0: ".(ref $self)."->type: Not implemented";
} # type

package Message::DOM::CSSStyleRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSStyleRule';

sub ____new ($$$) {
  my $self = bless \{_selector => $_[1], style => $_[2]}, $_[0];
  ## TODO: style -> owner
  return $self;
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::STYLE_RULE }

## |CSSStyleRule| attributes

## TODO: |selector_text|

sub style ($) {
  return ${$_[0]}->{style};
} # style

package Message::DOM::CSSCharsetRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSCharsetRule';

sub ____new ($$) {
  return bless \{encoding => $_[1]}, $_[0];
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::CHARSET_RULE }

## |CSSCharsetRule| attribute

sub encoding ($) {
  return ${$_[0]}->{encoding};
} # encoding

package Message::DOM::CSSImportRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSImportRule';

sub ____new ($$$$) {
  my $self = bless \{href => $_[1], media => $_[2], style_sheet => $_[3]}, $_[0];
  ## TODO: $_[3] owner_style_sheet
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
    ## TODO: owner_rule
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
  my $self = bless \{_selector => $_[1], style => $_[2]}, $_[0];
  ## TODO: style -> owner
  return $self;
} # ____new

## |CSSRule| attributes

## TODO: |css_text|

sub type ($) { Message::DOM::CSSRule::PAGE_RULE }

## |CSSPageRule| attributes

## TODO: |selector_text|

sub style ($) {
  return ${$_[0]}->{style};
} # style

package Message::DOM::CSSNamespaceRule;
push our @ISA, 'Message::DOM::CSSRule', 'Message::IF::CSSNamespaceRule';

sub ____new ($$$) {
  return bless \{namespace_uri => $_[2], prefix => $_[1]}, $_[0];
} # ___new

## |CSSRule| attributes

## TODO: |css_text|

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
## $Date: 2007/12/22 06:29:32 $
