package test::Whatpm::CSS::Parser;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::More;
use Test::Differences;

require (file (__FILE__)->dir->file ('testfiles.pl')->stringify);

require Whatpm::CSS::Parser;
require Message::DOM::Window;

require Message::DOM::DOMImplementation;
my $dom = Message::DOM::DOMImplementation->new;

my $DefaultComputed;
my $DefaultComputedText;

sub apply_diff ($$$);

sub _parse : Tests {
  my $all_test = {document => {}, test => []};
  execute_test ($_, {
    data => {is_prefixed => 1},
    errors => {is_list => 1},
    cssom => {is_prefixed => 1},
    csstext => {is_prefixed => 1},
    computed => {is_prefixed => 1},
    computedtext => {is_prefixed => 1},
    html => {is_prefixed => 1},
    xml => {is_prefixed => 1},
  }, sub {
    my $data = shift;
    
    if ($data->{data}) {
      my $test = {
        data => $data->{data}->[0],
        csstext => $data->{csstext}->[0],
        cssom => $data->{cssom}->[0],
        errors => $data->{errors}->[0],
      };
      for (qw(cssom csstext)) {
        $test->{$_} .= "\n" if defined $test->{$_} and length $test->{$_};
      }
      for my $key (qw(computed computedtext)) {
        if ($data->{$key}) {
          my $id = $data->{$key}->[1]->[0];
          my $sel = join ' ', @{$data->{$key}->[1]}[1..$#{$data->{$key}->[1]}];
          $test->{$key}->{$id}->{$sel} = $data->{$key}->[0];
        }
      }
      if ($data->{option} and $data->{option}->[1]->[0] eq 'q') {
        $test->{option}->{parse_mode} = 'q';
      }
      push @{$all_test->{test}}, $test;
    } elsif ($data->{html}) {
      $all_test->{document}->{$data->{html}->[1]->[0]} = {
        data => $data->{html}->[0],
        format => 'html',
      };
    } elsif ($data->{xml}) {
      $all_test->{document}->{$data->{xml}->[1]->[0]} = {
        data => $data->{xml}->[0],
        format => 'xml',
      };
    }
  }) for map { file (__FILE__)->dir->file ($_)->stringify } qw[
    css-1.dat
    css-2.dat
    css-3.dat
    css-4.dat
    css-visual.dat
    css-generated.dat
    css-paged.dat
    css-text.dat
    css-font.dat
    css-table.dat
    css-interactive.dat
  ];
    
  for my $data (values %{$all_test->{document}}) {
    if ($data->{format} eq 'html') {
      my $doc = $dom->create_document;
      $doc->manakai_is_html (1);
      $doc->inner_html ($data->{data});
      $data->{document} = $doc;
    } elsif ($data->{format} eq 'xml') {
      my $doc = $dom->create_document;
      $doc->inner_html ($data->{data});
      $data->{document} = $doc;
    } else {
      die "Test data format $data->{format} is not supported";
    }
  }

  for my $test (@{$all_test->{test}}) {
    my ($p, $css_options) = get_parser ($test->{option}->{parse_mode});

    my @actual_error;
    $p->{onerror} = sub {
      my (%opt) = @_;
      my $uri = ${$opt{uri}};
      $uri =~ s[^thismessage:/][];
      push @actual_error, join ';',
          $uri, $opt{token}->{line}, $opt{token}->{column},
          $opt{level},
          $opt{type} .
          (defined $opt{text} ? ';'.$opt{text} : '');
    };

    my $ss = $p->parse_char_string ($test->{data});

    eq_or_diff
        ((join "\n", @actual_error), (join "\n", @{$test->{errors} or []}),
         "#result ($test->{data})");

    if (defined $test->{cssom}) {
      my $actual = serialize_cssom ($ss);
      eq_or_diff $actual, $test->{cssom}, "#cssom ($test->{data})";
    }

    if (defined $test->{csstext}) {
      my $actual = $ss->css_text;
      eq_or_diff $actual, $test->{csstext}, "#csstext ($test->{data})";
    }

    for my $doc_id (keys %{$test->{computed} or {}}) {
      for my $selectors (keys %{$test->{computed}->{$doc_id}}) {
        my ($window, $style) = get_computed_style
            ($all_test, $doc_id, $selectors, $dom, $css_options, $ss);
        ## NOTE: $window is the root object, so that we must keep it 
        ## referenced in this block.
        
        my $actual = serialize_style ($style, '');
        my $expected = $DefaultComputed;
        my $diff = $test->{computed}->{$doc_id}->{$selectors};
        ($actual, $expected) = apply_diff ($actual, $expected, $diff);
        eq_or_diff $actual, $expected,
            "#computed $doc_id $selectors ($test->{data})";
      }
    }

    for my $doc_id (keys %{$test->{computedtext} or {}}) {
      for my $selectors (keys %{$test->{computedtext}->{$doc_id}}) {
        my ($window, $style) = get_computed_style
            ($all_test, $doc_id, $selectors, $dom, $css_options, $ss);
        ## NOTE: $window is the root object, so that we must keep it 
        ## referenced in this block.
        
        my $actual = $style->css_text;
        my $expected = $DefaultComputedText;
        my $diff = $test->{computedtext}->{$doc_id}->{$selectors};
        ($actual, $expected) = apply_diff ($actual, $expected, $diff);
        eq_or_diff $actual, $expected,
            "#computedtext $doc_id $selectors ($test->{data})";
      }
    }
  }
} # _parse

my @longhand;
my @shorthand;
BEGIN {
  @longhand = qw/
    alignment-baseline
    background-attachment background-color background-image
    background-position-x background-position-y
    background-repeat border-bottom-color
    border-bottom-style border-bottom-width border-collapse
    border-left-color
    border-left-style border-left-width border-right-color
    border-right-style border-right-width
    -manakai-border-spacing-x -manakai-border-spacing-y
    border-top-color border-top-style border-top-width bottom
    caption-side clear clip color content counter-increment counter-reset
    cursor direction display dominant-baseline empty-cells float
    font-family font-size font-size-adjust font-stretch
    font-style font-variant font-weight height left
    letter-spacing line-height
    list-style-image list-style-position list-style-type
    margin-bottom margin-left margin-right margin-top marker-offset
    marks max-height max-width min-height min-width opacity -moz-opacity
    orphans outline-color outline-style outline-width overflow-x overflow-y
    padding-bottom padding-left padding-right padding-top
    page page-break-after page-break-before page-break-inside
    position quotes right size table-layout
    text-align text-anchor text-decoration text-indent text-transform
    top unicode-bidi vertical-align visibility white-space width widows
    word-spacing writing-mode z-index
  /;
  @shorthand = qw/
    background background-position
    border border-color border-style border-width border-spacing
    border-top border-right border-bottom border-left
    font list-style margin outline overflow padding
  /;
  $DefaultComputedText = q[  alignment-baseline: auto;
  border-spacing: 0px;
  background: transparent none repeat scroll 0% 0%;
  border: 0px none -manakai-default;
  border-collapse: separate;
  bottom: auto;
  caption-side: top;
  clear: none;
  clip: auto;
  color: -manakai-default;
  content: normal;
  counter-increment: none;
  counter-reset: none;
  cursor: auto;
  direction: ltr;
  display: inline;
  dominant-baseline: auto;
  empty-cells: show;
  float: none;
  font-family: -manakai-default;
  font-size: 16px;
  font-size-adjust: none;
  font-stretch: normal;
  font-style: normal;
  font-variant: normal;
  font-weight: 400;
  height: auto;
  left: auto;
  letter-spacing: normal;
  line-height: normal;
  list-style-image: none;
  list-style-position: outside;
  list-style-type: disc;
  margin: 0px;
  marker-offset: auto;
  marks: none;
  max-height: none;
  max-width: none;
  min-height: 0px;
  min-width: 0px;
  opacity: 1;
  orphans: 2;
  outline: 0px none invert;
  overflow: visible;
  padding: 0px;
  page: auto;
  page-break-after: auto;
  page-break-before: auto;
  page-break-inside: auto;
  position: static;
  quotes: -manakai-default;
  right: auto;
  size: auto;
  table-layout: auto;
  text-align: begin;
  text-anchor: start;
  text-decoration: none;
  text-indent: 0px;
  text-transform: none;
  top: auto;
  unicode-bidi: normal;
  vertical-align: baseline;
  visibility: visible;
  white-space: normal;
  widows: 2;
  width: auto;
  word-spacing: normal;
  writing-mode: lr-tb;
  z-index: auto;
];
  $DefaultComputed = $DefaultComputedText;
  $DefaultComputed =~ s/^  //gm;
  $DefaultComputed =~ s/;$//gm;
  $DefaultComputed .= q[-manakai-border-spacing-x: 0px
-manakai-border-spacing-y: 0px
-moz-opacity: 1
background-attachment: scroll
background-color: transparent
background-image: none
background-position: 0% 0%
background-position-x: 0%
background-position-y: 0%
background-repeat: repeat
border-top: 0px none -manakai-default
border-right: 0px none -manakai-default
border-bottom: 0px none -manakai-default
border-left: 0px none -manakai-default
border-bottom-color: -manakai-default
border-bottom-style: none
border-bottom-width: 0px
border-left-color: -manakai-default
border-left-style: none
border-left-width: 0px
border-right-color: -manakai-default
border-right-style: none
border-right-width: 0px
border-top-color: -manakai-default
border-top-style: none
border-top-width: 0px
border-color: -manakai-default
border-style: none
border-width: 0px
float: none
font: 400 16px -manakai-default
list-style: disc none outside
margin-top: 0px
margin-right: 0px
margin-bottom: 0px
margin-left: 0px
outline-color: invert
outline-style: none
outline-width: 0px
overflow-x: visible
overflow-y: visible
padding-bottom: 0px
padding-left: 0px
padding-right: 0px
padding-top: 0px];
}

sub get_parser ($) {
  my $parse_mode = shift;

  my $p = Whatpm::CSS::Parser->new;

  $p->{prop}->{$_} = 1 for (@longhand, @shorthand);
  $p->{prop_value}->{display}->{$_} = 1 for qw/
    block clip inline inline-block inline-table list-item none
    table table-caption table-cell table-column table-column-group
    table-header-group table-footer-group table-row table-row-group
    compact marker
  /;
  $p->{prop_value}->{position}->{$_} = 1 for qw/
    absolute fixed relative static
  /;
  for (qw/-moz-max-content -moz-min-content -moz-fit-content -moz-available/) {
    $p->{prop_value}->{width}->{$_} = 1;
    $p->{prop_value}->{'min-width'}->{$_} = 1;
    $p->{prop_value}->{'max-width'}->{$_} = 1;
  }
  $p->{prop_value}->{float}->{$_} = 1 for qw/
    left right none
  /;
  $p->{prop_value}->{clear}->{$_} = 1 for qw/
    left right none both
  /;
  $p->{prop_value}->{direction}->{ltr} = 1;
  $p->{prop_value}->{direction}->{rtl} = 1;
  $p->{prop_value}->{marks}->{crop} = 1;
  $p->{prop_value}->{marks}->{cross} = 1;
  $p->{prop_value}->{'unicode-bidi'}->{$_} = 1 for qw/
    normal bidi-override embed
  /;
  for my $prop_name (qw/overflow overflow-x overflow-y/) {
    $p->{prop_value}->{$prop_name}->{$_} = 1 for qw/
      visible hidden scroll auto -webkit-marquee -moz-hidden-unscrollable
    /;
  }
  $p->{prop_value}->{visibility}->{$_} = 1 for qw/
    visible hidden collapse
  /;
  $p->{prop_value}->{'list-style-type'}->{$_} = 1 for qw/
    disc circle square decimal decimal-leading-zero
    lower-roman upper-roman lower-greek lower-latin
    upper-latin armenian georgian lower-alpha upper-alpha none
    hebrew cjk-ideographic hiragana katakana hiragana-iroha
    katakana-iroha
  /;
  $p->{prop_value}->{'list-style-position'}->{outside} = 1;
  $p->{prop_value}->{'list-style-position'}->{inside} = 1;
  $p->{prop_value}->{'page-break-before'}->{$_} = 1 for qw/
    auto always avoid left right
  /;
  $p->{prop_value}->{'page-break-after'}->{$_} = 1 for qw/
    auto always avoid left right
  /;
  $p->{prop_value}->{'page-break-inside'}->{auto} = 1;
  $p->{prop_value}->{'page-break-inside'}->{avoid} = 1;
  $p->{prop_value}->{'background-repeat'}->{$_} = 1 for qw/
    repeat repeat-x repeat-y no-repeat
  /;
  $p->{prop_value}->{'background-attachment'}->{scroll} = 1;
  $p->{prop_value}->{'background-attachment'}->{fixed} = 1;
  $p->{prop_value}->{'font-size'}->{$_} = 1 for qw/
    xx-small x-small small medium large x-large xx-large
    -manakai-xxx-large -webkit-xxx-large
    larger smaller
  /;
  $p->{prop_value}->{'font-style'}->{normal} = 1;
  $p->{prop_value}->{'font-style'}->{italic} = 1;
  $p->{prop_value}->{'font-style'}->{oblique} = 1;
  $p->{prop_value}->{'font-variant'}->{normal} = 1;
  $p->{prop_value}->{'font-variant'}->{'small-caps'} = 1;
  $p->{prop_value}->{'font-stretch'}->{$_} = 1 for
      qw/normal wider narrower ultra-condensed extra-condensed
        condensed semi-condensed semi-expanded expanded
        extra-expanded ultra-expanded/;
  $p->{prop_value}->{'text-align'}->{$_} = 1 for qw/
    left right center justify begin end
  /;
  $p->{prop_value}->{'text-transform'}->{$_} = 1 for qw/
    capitalize uppercase lowercase none
  /;
  $p->{prop_value}->{'white-space'}->{$_} = 1 for qw/
    normal pre nowrap pre-line pre-wrap -moz-pre-wrap
  /;
  $p->{prop_value}->{'writing-mode'}->{$_} = 1 for qw/
    lr rl tb lr-tb rl-tb tb-rl
  /;
  $p->{prop_value}->{'text-anchor'}->{$_} = 1 for qw/
    start middle end
  /;
  $p->{prop_value}->{'dominant-baseline'}->{$_} = 1 for qw/
    auto use-script no-change reset-size ideographic alphabetic
    hanging mathematical central middle text-after-edge text-before-edge
  /;
  $p->{prop_value}->{'alignment-baseline'}->{$_} = 1 for qw/
    auto baseline before-edge text-before-edge middle central
    after-edge text-after-edge ideographic alphabetic hanging
    mathematical
  /;
  $p->{prop_value}->{'text-decoration'}->{$_} = 1 for qw/
    none blink underline overline line-through
  /;
  $p->{prop_value}->{'caption-side'}->{$_} = 1 for qw/
    top bottom left right
  /;
  $p->{prop_value}->{'table-layout'}->{auto} = 1;
  $p->{prop_value}->{'table-layout'}->{fixed} = 1;
  $p->{prop_value}->{'border-collapse'}->{collapse} = 1;
  $p->{prop_value}->{'border-collapse'}->{separate} = 1;
  $p->{prop_value}->{'empty-cells'}->{show} = 1;
  $p->{prop_value}->{'empty-cells'}->{hide} = 1;
  $p->{prop_value}->{cursor}->{$_} = 1 for qw/
    auto crosshair default pointer move e-resize ne-resize nw-resize n-resize
    se-resize sw-resize s-resize w-resize text wait help progress
  /;
  for my $prop (qw/border-top-style border-left-style
                   border-bottom-style border-right-style outline-style/) {
    $p->{prop_value}->{$prop}->{$_} = 1 for qw/
      none hidden dotted dashed solid double groove ridge inset outset
    /;
  }
  for my $prop (qw/color background-color
                   border-bottom-color border-left-color border-right-color
                   border-top-color border-color/) {
    $p->{prop_value}->{$prop}->{transparent} = 1;
    $p->{prop_value}->{$prop}->{flavor} = 1;
    $p->{prop_value}->{$prop}->{'-manakai-default'} = 1;
  }
  $p->{prop_value}->{'outline-color'}->{invert} = 1;
  $p->{prop_value}->{'outline-color'}->{'-manakai-invert-or-currentcolor'} = 1;
  $p->{pseudo_class}->{$_} = 1 for qw/
    active checked disabled empty enabled first-child first-of-type
    focus hover indeterminate last-child last-of-type link only-child
    only-of-type root target visited
    lang nth-child nth-last-child nth-of-type nth-last-of-type not
    -manakai-contains -manakai-current
  /;
  $p->{pseudo_element}->{$_} = 1 for qw/
    after before first-letter first-line
  /;

  my $css_options = {
    prop => $p->{prop},
    prop_value => $p->{prop_value},
    pseudo_class => $p->{pseudo_class},
    pseudo_element => $p->{pseudo_element},
  };

  $p->init;
  if ($parse_mode and $parse_mode eq 'q') {
    $p->{unitless_px} = 1;
    $p->{hashless_color} = 1;
  }
  $p->{href} = 'thismessage:/';

  return ($p, $css_options);
} # get_parser

sub serialize_rule ($$) {
  my ($rule, $indent) = @_;
  my $v = '';
  if ($rule->type == $rule->STYLE_RULE) {
    $v .= $indent . '<' . $rule->selector_text . ">\n";
    $v .= serialize_style ($rule->style, $indent . '  ');
  } elsif ($rule->type == $rule->MEDIA_RULE) {
    $v .= $indent . '@media ' . $rule->media . "\n";
    $v .= serialize_rule ($_, $indent . '  ') for @{$rule->css_rules};
  } elsif ($rule->type == $rule->NAMESPACE_RULE) {
    $v .= $indent . '@namespace ';
    my $prefix = $rule->prefix;
    $v .= $prefix . ': ' if length $prefix;
    $v .= '<' . $rule->namespace_uri . ">\n";
  } elsif ($rule->type == $rule->IMPORT_RULE) {
    $v .= $indent . '@import <' . $rule->href . '> ' . $rule->media;
    $v .= "\n";
  } elsif ($rule->type == $rule->CHARSET_RULE) {
    $v .= $indent . '@charset ' . $rule->encoding . "\n";
  } else {
    die "Rule type @{[$rule->type]} is not supported";
  }
  return $v;
} # serialize_rule

sub serialize_cssom ($) {
  my $ss = shift;

  if (defined $ss) {
    if ($ss->isa ('Message::IF::CSSStyleSheet')) {
      my $v = '';
      for my $rule (@{$ss->css_rules}) {
        my $indent = '';
        $v .= serialize_rule ($rule, $indent);
      }
      return $v;
    } else {
      return '(' . (ref $ss) . ')';
    }
  } else {
    return '(undef)';
  }
} # serialize_cssom

sub get_computed_style ($$$$$$) {
  my ($all_test, $doc_id, $selectors, $dom, $css_options, $ss) = @_;

  my $doc = $all_test->{document}->{$doc_id}->{document};
  unless ($doc) {
    die "Test document $doc_id is not defined";
  }

  my $element = $doc->query_selector ($selectors);
  unless ($element) {
    die "Element $selectors not found in document $doc_id";
  }
  
  my $window = Message::DOM::Window->___new ($dom);
  $window->___set_css_options ($css_options);
  $window->___set_user_style_sheets ([$ss]);
  $window->set_document ($doc);
  
  my $style = $element->manakai_computed_style;
  return ($window, $style);
} # get_computed_style

sub serialize_style ($$) {
  my ($style, $indent) = @_;

  ## TODO: check @$style

  my @v;
  for (map {get_dom_names ($_)} @shorthand, @longhand) {
    my $dom = $_->[1];
    push @v, [$_->[0], $dom, $style->$dom,
              $style->get_property_priority ($_->[0])];
    $v[-1]->[3] = ' !' . $v[-1]->[3]
        if defined $v[-1]->[3] and length $v[-1]->[3];
  }
  return join '',
      map {"$indent$_->[0]: @{[defined $_->[2] ? $_->[2] : '']}@{[defined $_->[3] ? $_->[3] : '']}\n"}
      sort {$a->[0] cmp $b->[0]}
      grep {defined $_->[2] and length $_->[2]} @v;
} # serialize_style

sub get_dom_names ($) {
  my $dom_name = $_[0];
  if ($_[0] eq 'float') {
    return ([$_[0] => 'css_float'], [$_[0] => 'style_float']);
  }

  $dom_name =~ tr/-/_/;
  return ([$_[0] => $dom_name]);
} # get_dom_names

sub apply_diff ($$$) {
  my ($actual, $expected, $diff) = @_;
  my @actual = split /[\x0D\x0A]+/, $actual;
  my @expected = split /[\x0D\x0A]+/, $expected;
  my @diff = split /[\x0D\x0A]+/, $diff;
  for (@diff) {
    if (s/^-(?:\| )?//) {
      push @actual, $_;
    } elsif (s/^\+(?:\| )?//) {
      push @expected, $_;
    } else {
      die "Invalid diff line: $_";
    }
  }
  $actual = join "\n", sort {$a cmp $b} @actual;
  $expected = join "\n", sort {$a cmp $b} @expected;
  ($actual, $expected);
} # apply_diff

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2008-2011 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

