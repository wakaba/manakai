#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->parent->subdir ('modules', '*', 'lib')->stringify;
use CGI::Carp qw[fatalsToBrowser];

use Message::CGI::HTTP;
my $http = Message::CGI::HTTP->new;

## TODO: _charset_

my $mode = $http->get_meta_variable ('PATH_INFO');
## TODO: decode unreserved characters

if ($mode eq '/csstext') {
  require Encode;
  require Whatpm::CSS::Parser;
  require Whatpm::CSS::SelectorsParser;

  my $s = $http->get_parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  print STDOUT "#errors\n";

  my $p = Whatpm::CSS::Parser->new;
  $p->{onerror} = sub {
    my (%opt) = @_;
    print STDOUT "@{[$opt{uri}?${$opt{uri}}:'']},$opt{token}->{line}:$opt{token}->{column},@{[Whatpm::CSS::Tokenizer->serialize_token ($opt{token})]},$opt{level},$opt{type},$opt{value}\n";
  };

  $p->{prop}->{$_} = 1 for qw/
    alignment-baseline
    background background-attachment background-color background-image
    background-position background-position-x background-position-y
    background-repeat border border-bottom border-bottom-color
    border-bottom-style border-bottom-width border-collapse border-color
    border-left border-left-color
    border-left-style border-left-width border-right border-right-color
    border-right-style border-right-width
    border-spacing -manakai-border-spacing-x -manakai-border-spacing-y
    border-style border-top border-top-color border-top-style border-top-width
    border-width bottom
    caption-side clear clip color content counter-increment counter-reset
    cursor direction display dominant-baseline empty-cells float font
    font-family font-size font-size-adjust font-stretch
    font-style font-variant font-weight height left
    letter-spacing line-height
    list-style list-style-image list-style-position list-style-type
    margin margin-bottom margin-left margin-right margin-top marker-offset
    marks max-height max-width min-height min-width opacity -moz-opacity
    orphans outline outline-color outline-style outline-width overflow
    overflow-x overflow-y
    padding padding-bottom padding-left padding-right padding-top
    page page-break-after page-break-before page-break-inside
    position quotes right size table-layout
    text-align text-anchor text-decoration text-indent text-transform
    top unicode-bidi vertical-align visibility white-space width widows
    word-spacing writing-mode z-index
  /;
  $p->{prop_value}->{display}->{$_} = 1 for qw/
    block inline inline-block inline-table list-item none
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
    lang nth-child nth-last-child nth-of-type nth-last-of-type not
    -manakai-contains
  /, keys %$Whatpm::CSS::SelectorsParser::IdentOnlyPseudoClasses;
  $p->{pseudo_element}->{$_} = 1 for qw/
    
  /, keys %$Whatpm::CSS::SelectorsParser::IdentOnlyPseudoElements;

  my $css_options = {
    prop => $p->{prop},
    prop_value => $p->{prop_value},
    pseudo_class => $p->{pseudo_class},
    pseudo_element => $p->{pseudo_element},
  };

  $p->init;
  $p->{href} = 'thismessage:/';

  my $ss = $p->parse_char_string ($s);

  print "#csstext\n";
  my $out = $ss->css_text;
  print STDOUT Encode::encode ('utf-8', $out);

  ## NOTE: Codes below are for debugging of Cascade module.
  require Message::DOM::DOMImplementation;
  my $dom = Message::DOM::DOMImplementation->new;

  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  $doc->inner_html (q[<p>xxxx</p><div>yyyy</div>]);

  require Message::DOM::Window;
  my $window = Message::DOM::Window->___new ($dom);
  $window->___set_css_options ($css_options);
  $window->___set_user_style_sheets ([$ss]);
  $window->set_document ($doc);

  my $p = $doc->get_elements_by_tag_name ('p')->[0];

  print "#computed\n";
  my $cd = $p->manakai_computed_style;
  print $cd->css_text;
} elsif ($mode eq '/tokens') {
  require Encode;
  require Whatpm::CSS::Tokenizer;

  my $s = $http->get_parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  print STDOUT "#errors\n";

  my $onerror = sub {
    my (%opt) = @_;
    print STDOUT "$opt{line},$opt{column},$opt{level},$opt{type}\n";
  };

  my $pos = 0;
  my $length = length $s;
  my $t = Whatpm::CSS::Tokenizer->new;
  $t->{get_char} = sub {
    if ($pos < $length) {
      return ord substr $s, $pos++, 1;
    } else {
      return -1;
    }
  };
  $t->init;
  my @token;
  while (1) {
    my $token = $t->get_next_token;
    push @token, $token;
    last if $token->{type} == Whatpm::CSS::Tokenizer::EOF_TOKEN ();
  }

  print "#tokens\n";

  my $out = '';
  for my $token (@token) {
    $out .= ($Whatpm::CSS::Tokenizer::TokenName[$token->{type}] or
             $token->{type}) . qq[\t"] . $token->{value} . qq["\t"] .
        $token->{number} . qq["\n];
  }
  print STDOUT Encode::encode ('utf-8', $out);
  print STDOUT "\n";
} elsif ($mode eq '/selectors') {
  require Encode;
  require Whatpm::CSS::SelectorsParser;

  my $s = $http->get_parameter ('s');
  if (length $s > 1000_000) {
    print STDOUT "Status: 400 Document Too Long\nContent-Type: text/plain; charset=us-ascii\n\nToo long";
    exit;
  }

  $s = Encode::decode ('utf-8', $s);
  
  print STDOUT "Content-Type: text/plain; charset=utf-8\n\n";

  my $p = Whatpm::CSS::SelectorsParser->new;

  print STDOUT "#errors\n";

  $p->{onerror} = sub {
    my (%opt) = @_;
    print STDOUT "$opt{line},$opt{column},$opt{level},$opt{type}\n";
  };

  $p->{pseudo_class}->{$_} = 1 for qw/
    lang nth-child nth-last-child nth-of-type nth-last-of-type not
    -manakai-contains
  /, keys %$Whatpm::CSS::SelectorsParser::IdentOnlyPseudoClasses;
  $p->{pseudo_element}->{$_} = 1 for qw/
    
  /, keys %$Whatpm::CSS::SelectorsParser::IdentOnlyPseudoElements;

  my $selectors = $p->parse_string ($s);
  
  require Whatpm::CSS::SelectorsSerializer;
  my ($sel, $ns) = Whatpm::CSS::SelectorsSerializer->serialize_test
      ($selectors);
  my ($sel2, $ns2) = Whatpm::CSS::SelectorsSerializer->serialize_selector_text
      ($selectors);
  my $out = "\n#namespaces\n" . $ns . "\n#selectors\n" . $sel;
  $out .= "\n#selector_text\n" . $sel2;

  print STDOUT Encode::encode ('utf-8', $out);
  print STDOUT "\n";
} else {
  print STDOUT "Status: 404 Not Found\nContent-Type: text/plain; charset=us-ascii\n\n404";
}

exit;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2007-2012 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
