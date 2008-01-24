package Message::DOM::Window;
use strict;
require Scalar::Util;
push our @ISA, 'Message::IF::AbstractView',
    'Message::IF::Window',
    'Message::IF::ViewCSS';

## NOTE: We don't support multiple views - all the views are
## the default views.

## NOTE: The current implementation does not support non-CSS views.

sub ___new ($$) {
  my $self = bless \{
    #___css
    #___css_options => {},
    ___user_style_sheets => [], ___ua_style_sheets => [],
  }, shift;
  $$self->{___implementation} = shift;

  my $doc = $$self->{document} = $$self->{___implementation}->create_document;
  $$doc->{default_view} = $self;
  Scalar::Util::weaken ($$doc->{default_view});
  
  $doc->manakai_is_html (1);
  $doc->inner_html (q[<!DOCTYPE HTML><title></title><body>]);
  $self->___reset_css;

  return $self;
} # ___new

## |AbstractView| attribute

sub document ($) { ${$_[0]}->{document} }

## |ViewCSS| methods

## TODO: implement other methods

## TODO: Documentation.
sub manakai_get_computed_style ($$;$) {
  my $css = ${$_[0]}->{___css};

  ## TODO: pseudo element
  ## TODO: element not part of this document or not part of document tree
  ## TODO: Sameness of return values of multiple invocations.

  require Message::DOM::CSSStyleDeclaration;
  return Message::DOM::CSSComputedStyleDeclaration->____new ($css, $_[1]);
} # manakai_get_computed_style

sub ___set_css_options ($$) {
  ${$_[0]}->{___css_options} = $_[1];
} # ___set_css_options

sub ___set_ua_style_sheets ($$) {
  ${$_[0]}->{___ua_style_sheets} = $_[1];
} # ___set_ua_style_sheets

sub ___set_user_style_sheets ($$) {
  ${$_[0]}->{___user_style_sheets} = $_[1];
} # ___set_user_style_sheets

sub ___reset_css ($) {
  my $self = shift;
  require Whatpm::CSS::Cascade;
  my $cas = Whatpm::CSS::Cascade->new ($$self->{document});
  $cas->{has_invert}
      = $$self->{___css_options}->{prop_value}->{'outline-color'}->{invert};

  ## TODO: ...
  $cas->add_style_sheets ([@{$$self->{___user_style_sheets}},
                           @{$$self->{___ua_style_sheets}}]);

  $cas->___associate_rules;
  $$self->{___css} = $cas;
} # ___reset_css

## |Window| methods

## NOTE: An Opera extension.
sub set_document ($$) {
  ## NOTE: See <http://suika.fam.cx/gate/2005/sw/setDocument>.

  my $self = shift;

  my $new_doc = shift;
  return if $new_doc->default_view;

  ## NOTE: When $new_doc eq $self->document, only re-rendering
  ## should be happen.

  my $old_doc = $$self->{document};
  if ($old_doc) {
    delete $$old_doc->{default_view};
  }
  
  $$self->{document} = $new_doc;
  $$new_doc->{default_view} = $self;
  Scalar::Util::weaken ($$new_doc->{default_view});

  $self->___reset_css;
} # set_document

package Message::IF::AbstractView;
package Message::IF::ViewCSS;
package Message::IF::Window;

1;
## $Date: 2008/01/24 11:25:19 $
