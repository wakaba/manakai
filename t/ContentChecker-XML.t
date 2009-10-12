#!/usr/bin/perl
use strict;

BEGIN {
  require 't/content-checker.pl';
  plan (tests => 29);
}

test_files (qw[
  t/dom-conformance/xml-1.dat
  t/dom-conformance/xml-global.dat
]);

## License: Public Domain.
## $Date: 2008/10/07 12:18:39 $
