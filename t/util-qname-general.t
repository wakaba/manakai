#!/usr/bin/perl -w 
use strict;
use Test;

use Message::Markup::XML::QName qw(DEFAULT_PFX EMPTY_PFX);
use Message::Util::QName::General
  [qw/ExpandedName ExpandedURI/],
  {
    xhtml1 => q<http://www.w3.org/1999/xhtml>,
    about  => q<about:>,
    (DEFAULT_PFX) => q<http://default.example/>,
    (EMPTY_PFX) => q<data:,>,
  };

plan tests => 5;

ok scalar ExpandedName q<about:blank>, q<about:blank>;

ok join ("\t", ExpandedName q<xhtml1:class>),
   join ("\t", q<http://www.w3.org/1999/xhtml>, q<class>);

ok scalar ExpandedName q<foo>, q<http://default.example/foo>;

ok ExpandedURI q<:foo>, q<data:,foo>;
ok ExpandedURI q<foo>, q<http://default.example/foo>;

