#!/usr/bin/perl -w 
use strict;
use Test;

use Message::Util::QName::Filter
  {
    xhtml1 => q<http://www.w3.org/1999/xhtml>,
    About  => q<about:>,
    '#default' => q<http://default.example/>,
    '' => q<data:,>,
  };

plan tests => 5;

ok ExpandedURI q<About:blank>, q<about:blank>;

ok ExpandedURI q<xhtml1:class>,
   q<http://www.w3.org/1999/xhtmlclass>;

ok ExpandedURI q<foo>, q<foo>;
ok ExpandedURI q<:foo>, q<data:,foo>;
ok ExpandedURI q<About:>, q<about:>;

