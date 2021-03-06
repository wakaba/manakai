package Message::DOM::CSSStyleSheet;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.8 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CSSStyleSheet';
require Message::DOM::DOMException;
require Scalar::Util;

sub ____new ($;%) {
  my $class = shift;
  my $self = bless \{@_}, $class;
  for (@{$$self->{css_rules}}) {
    ${$_}->{parent_style_sheet} = $self;
    Scalar::Util::weaken (${$_}->{parent_style_sheet});
  }
  # $self->{_parser} : Whatpm::CSS::Parser
  # $self->{_nsmap} : $nsmap (see Whatpm::CSS::Parser)
  return $self;
} # ____new

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

## TODO: documentation
sub manakai_base_uri ($) {
  if (defined ${$_[0]}->{manakai_base_uri}) {
    return ${$_[0]}->{manakai_base_uri};
  } else {
    return ${$_[0]}->{href}; ## NOTE: Might be |undef|.
  }
} # manakai_base_uri

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

sub media ($;$) {
  if (@_ > 1) {
    local $Error::Depth = $Error::Depth + 1;
    ${+shift}->{media}->media_text (@_);
  }
  return ${$_[0]}->{media};
} # media

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

## NOTE: This is a manakai extension.
sub css_text ($;$) {
  ## TODO: setter

  my $r = '';
  local $Error::Depth = $Error::Depth + 1;
  for my $rule (@{$_[0]->css_rules}) {
    $r .= $rule->css_text . "\n"; ## TODO: \x0D\x0A? \x0A?
  }
  return $r;
} # css_text

## TODO: documentation
sub manakai_input_encoding ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      ${$_[0]}->{input_encoding} = ''.$_[1];
    } else {
      delete ${$_[0]}->{input_encoding};
    }
  }
  return ${$_[0]}->{input_encoding};
} # manakai_input_encoding

sub owner_rule ($);

## |CSSStyleSheet| methods

sub delete_rule ($$) {
  if ($_[1] < 0 or $_[1] > @{${$_[0]}->{css_rules}}) {
    report Message::DOM::DOMException
        -object => $_[0],
        -type => 'INDEX_SIZE_ERR',
        -subtype => 'INDEX_OUT_OF_BOUND_ERR';
  } else {
    my $rule = ${$_[0]}->{css_rules}->[$_[1]];
    delete $rule->{parent_rule};
    delete ${$_[0]}->{css_rules}->[$_[1]];
  }
} # delete_rule

## TODO: insert_rule

## TODO: Documentation
sub manakai_is_default_namespace ($$) {
  my $uri = $_[1];
  for my $rule (@{$_[0]->css_rules}) {
    next if $rule->type == 2 or $rule->type == 3; # CHARSET_RULE or IMPORT_RULE
    return 0 if $rule->type != 7; # NAMESPACE_RULE

    ## TODO: Can we insert NAMESPACE_RULE after other kinds of rules
    ## by insert_rule?

    if ($uri eq $rule->namespace_uri) {
      return 1 if $rule->prefix eq '';
    }
  }

  return 0;
} # manakai_is_default_namespace

## TODO: Documentation
sub manakai_lookup_namespace_prefix ($$) {
  my $uri = $_[1];
  for my $rule (@{$_[0]->css_rules}) {
    next if $rule->type == 2 or $rule->type == 3; # CHARSET_RULE or IMPORT_RULE
    return undef if $rule->type != 7; # NAMESPACE_RULE

    ## TODO: Can we insert NAMESPACE_RULE after other kinds of rules
    ## by insert_rule?

    if ($uri eq $rule->namespace_uri) {
      my $prefix = $rule->prefix;
      return $prefix if $prefix ne '';
    }
  }

  return undef;
} # manakai_lookup_namespace_prefix

package Message::IF::StyleSheet;
package Message::IF::CSSStyleSheet;

1;
## $Date: 2008/02/10 04:10:36 $
