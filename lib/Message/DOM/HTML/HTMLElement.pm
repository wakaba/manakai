package Message::DOM::HTML::HTMLElement;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Element';
require Message::DOM::Element;

## TODO: interface

sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  return if $method_name =~ /::DESTROY$/;

  my $ln;
  if ($ln = {  ## Reflecting |DOMString| attribute
    'Message::DOM::HTML::HTMLAreaElement::alt' => 'alt',
    'Message::DOM::HTML::HTMLImageElement::alt' => 'alt',
    'Message::DOM::HTML::HTMLElement::class_name' => 'class',
    'Message::DOM::HTML::HTMLMetaElement::content' => 'content',
    'Message::DOM::HTML::HTMLAreaElement::coords' => 'coords',
    'Message::DOM::HTML::HTMLTimeElement::datetime' => 'datetime',
    'Message::DOM::HTML::HTMLModElement::datetime' => 'datetime',
    'Message::DOM::HTML::HTMLAnchorElement::hreflang' => 'hreflang',
    'Message::DOM::HTML::HTMLAreaElement::hreflang' => 'hreflang',
    'Message::DOM::HTML::HTMLLinkElement::hreflang' => 'hreflang',
    'Message::DOM::HTML::HTMLElement::id' => 'id',
    'Message::DOM::HTML::HTMLCommandElement::label' => 'label',
    'Message::DOM::HTML::HTMLMenuElement::label' => 'label',
    'Message::DOM::HTML::HTMLElement::lang' => 'lang',
    'Message::DOM::HTML::HTMLAnchorElement::media' => 'media',
    'Message::DOM::HTML::HTMLAreaElement::media' => 'media',
    'Message::DOM::HTML::HTMLLinkElement::media' => 'media',
    'Message::DOM::HTML::HTMLSourceElement::media' => 'media',
    'Message::DOM::HTML::HTMLStyleElement::media' => 'media',
    'Message::DOM::HTML::HTMLParamElement::name' => 'name',
    'Message::DOM::HTML::HTMLAnchorElement::ping' => 'ping',
    'Message::DOM::HTML::HTMLAreaElement::ping' => 'ping',
    'Message::DOM::HTML::HTMLCommandElement::radiogroup' => 'radiogroup',
    'Message::DOM::HTML::HTMLAnchorElement::rel' => 'rel',
    'Message::DOM::HTML::HTMLAreaElement::rel' => 'rel',
    'Message::DOM::HTML::HTMLLinkElement::rel' => 'rel',
    'Message::DOM::HTML::HTMLAnchorElement::target' => 'target',
    'Message::DOM::HTML::HTMLAreaElement::target' => 'target',
    'Message::DOM::HTML::HTMLBaseElement::target' => 'target',
    'Message::DOM::HTML::HTMLElement::title' => 'title',
    'Message::DOM::HTML::HTMLAnchorElement::type' => 'type',
    'Message::DOM::HTML::HTMLAreaElement::type' => 'type',
    'Message::DOM::HTML::HTMLCommandElement::type' => 'type',
    'Message::DOM::HTML::HTMLEmbedElement::type' => 'type',
    'Message::DOM::HTML::HTMLLinkElement::type' => 'type',
    'Message::DOM::HTML::HTMLObjectElement::type' => 'type',
    'Message::DOM::HTML::HTMLScriptElement::type' => 'type',
    'Message::DOM::HTML::HTMLSourceElement::type' => 'type',
    'Message::DOM::HTML::HTMLStyleElement::type' => 'type',
    'Message::DOM::HTML::HTMLImageElement::usemap' => 'usemap',
    'Message::DOM::HTML::HTMLObjectElement::usemap' => 'usemap',
    'Message::DOM::HTML::HTMLParamElement::value' => 'value',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        local \$Error::Depth = \$Error::Depth + 1;

        if (\@_ > 1) {
          if (defined \$_[1]) {
            \$_[0]->set_attribute_ns (undef, '$ln', ''.\$_[1]);
          } else {
            ## ISSUE: Not in spec
            \$_[0]->set_attribute_ns (undef, '$ln', '');
          }
          return unless defined wantarray;
        }

        ## ISSUE: If missing?
        return \$_[0]->get_attribute_ns (undef, '$ln');
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Reflecting URI attribute
    'Message::DOM::HTML::HTMLAnchorElement::href' => 'href',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        local \$Error::Depth = \$Error::Depth + 1;

        ## TODO: Implement the spec...

        if (\@_ > 1) {
          if (defined \$_[1]) {
            \$_[0]->set_attribute_ns (undef, '$ln', ''.\$_[1]);
          } else {
            \$_[0]->set_attribute_ns (undef, '$ln', '');
          }
          return unless defined wantarray;
        }

        if (defined wantarray) {
          my \$uri = \$_[0]->get_attribute_ns (undef, '$ln');
          if (defined \$uri) {
            return \$_[0]->owner_document->implementation->create_uri_reference
                (\$uri)->get_absolute_reference (\$_[0]->base_uri)
                ->uri_reference;
            ## TODO: If base_uri is undef...
          } else {
            return undef;
          }
        }
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ($ln = {  ## Reflecting boolean attribute
    'Message::DOM::HTML::HTMLScriptElement::async' => 'async',
    'Message::DOM::HTML::HTMLMenuElement::autosubmit' => 'autosubmit',
    'Message::DOM::HTML::HTMLCommandElement::checked' => 'checked',
    'Message::DOM::HTML::HTMLMediaElement::controls' => 'controls',
    'Message::DOM::HTML::HTMLCommandElement::default' => 'default',
    'Message::DOM::HTML::HTMLScriptElement::defer' => 'defer',
    'Message::DOM::HTML::HTMLCommandElement::disabled' => 'disabled',
    'Message::DOM::HTML::HTMLDataGridElement::disabled' => 'disabled',
    'Message::DOM::HTML::HTMLCommandElement::hidden' => 'hidden',
    'Message::DOM::HTML::HTMLElement::irrelevant' => 'irrelevant',
    'Message::DOM::HTML::HTMLImageElement::ismap' => 'ismap',
    'Message::DOM::HTML::HTMLDataGridElement::multiple' => 'multiple',
    'Message::DOM::HTML::HTMLDetailsElement::open' => 'open',
    'Message::DOM::HTML::HTMLStyleElement::scoped' => 'scoped',
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$;\$) {
        local \$Error::Depth = \$Error::Depth + 1;

        if (\@_ > 1) {
          if (\$_[1]) {
            \$_[0]->set_attribute_ns (undef, '$ln', '$ln');
          } else {
            \$_[0]->remove_attribute_ns (undef, '$ln');
          }
          return unless defined wantarray;
        }

        return \$_[0]->has_attribute_ns (undef, '$ln');
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD

## TODO: class_list

sub class_name ($;$);

## TODO: dir

sub id ($;$);

## NOTE: inner_html is part of |Message::DOM::Element|.

sub lang ($;$);

## TODO: tab_index

sub title ($;$);

## TODO: Other DOM5 HTML members

package Message::DOM::HTML::HTMLAnchorElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: href

sub hreflang ($;$);

sub media ($;$);

sub ping ($;$);

sub rel ($;$);

## TODO: rel_list

sub target ($;$);

sub type ($;$);

## TODO: Command

package Message::DOM::HTML::HTMLAreaElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub alt ($;$);

sub coords ($;$);

## TODO: href

sub hreflang ($;$);

sub media ($;$);

sub ping ($;$);

sub rel ($;$);

## TODO: rel_list, shape

sub target ($;$);

sub type ($;$);

package Message::DOM::HTML::HTMLAudioElement;
push our @ISA, 'Message::DOM::HTML::HTMLMediaElement';

package Message::DOM::HTML::HTMLBaseElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub target ($;$);

## TODO: href

package Message::DOM::HTML::HTMLBodyElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: DOM2

package Message::DOM::HTML::HTMLCanvasElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLCommandElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub checked ($;$);

sub default ($;$);

sub disabled ($;$);

sub hidden ($;$);

## TODO: icon

sub label ($;$);

sub radiogroup ($;$);

sub type ($;$); ## NOTE: This is not an enumerated attribute.

## TODO: Command

package Message::DOM::HTML::HTMLDataGridElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

sub disabled ($;$);

sub multiple ($;$);

package Message::DOM::HTML::HTMLDetailsElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub open ($;$);

package Message::DOM::HTML::HTMLEmbedElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: height, src

sub type ($;$);

## TODO: width

package Message::DOM::HTML::HTMLEventSourceElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: src

package Message::DOM::HTML::HTMLFontElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLHeadElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: DOM2

package Message::DOM::HTML::HTMLHtmlElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: DOM2

package Message::DOM::HTML::HTMLIFrameElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: src, EmbeddingElement

package Message::DOM::HTML::HTMLImageElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub alt ($;$);

## TODO: complete

sub ismap ($;$);

## TODO: height, src

sub usemap ($;$);

## TODO: width

package Message::DOM::HTML::HTMLLIElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: value

package Message::DOM::HTML::HTMLLinkElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: disabled, href

sub hreflang ($;$);

sub media ($;$);

sub rel ($;$);

## TODO: rel_list

sub type ($;$);

## TODO: LinkStyle

package Message::DOM::HTML::HTMLMapElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLMediaElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO...

sub controls ($;$);

package Message::DOM::HTML::HTMLMenuElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub autosubmit ($;$);

sub label ($;$);

## TODO: type

package Message::DOM::HTML::HTMLMetaElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub content ($;$);

## TODO: name, http_equiv

package Message::DOM::HTML::HTMLMeterElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: value, min, max, low, high, optimum

package Message::DOM::HTML::HTMLModElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: cite

sub datetime ($;$);

package Message::DOM::HTML::HTMLObjectElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: data, height

sub type ($;$);

sub usemap ($;$);

## TODO: width, EmbeddingElement

package Message::DOM::HTML::HTMLOListElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: start

package Message::DOM::HTML::HTMLParamElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub name ($;$);

sub value ($;$);

package Message::DOM::HTML::HTMLProgressElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: value, max, position

package Message::DOM::HTML::HTMLQuoteElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: cite

package Message::DOM::HTML::HTMLScriptElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub async ($;$);

sub defer ($;$);

## TODO: src, text

sub type ($;$);

package Message::DOM::HTML::HTMLSourceElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

sub media ($;$);

## TODO: src

sub type ($;$);

package Message::DOM::HTML::HTMLStyleElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: disabled

sub media ($;$);

sub scoped ($;$);

sub type ($;$);

package Message::DOM::HTML::HTMLTableElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLTableCellElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLTableColElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: span

package Message::DOM::HTML::HTMLTableHeaderCellElement;
push our @ISA, 'Message::DOM::HTML::HTMLTableCellElement';

## TODO

package Message::DOM::HTML::HTMLTableRowElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLTableSectionElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO

package Message::DOM::HTML::HTMLTimeElement;
push our @ISA, 'Message::DOM::HTML::HTMLElement';

## TODO: date

sub datetime ($;$);

## TODO: time, timezone

package Message::DOM::HTML::HTMLVideoElement;
push our @ISA, 'Message::DOM::HTML::HTMLMediaElement';

## TODO: video_width, video_height

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2008/01/14 13:56:35 $

