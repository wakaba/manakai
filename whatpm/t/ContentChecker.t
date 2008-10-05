#!/usr/bin/perl
use strict;

BEGIN {
  require 't/content-checker.pl';
  plan (tests => 2646);
}

test_files (qw[
  t/content-model-1.dat
  t/content-model-2.dat
  t/content-model-3.dat
  t/content-model-4.dat
  t/content-model-5.dat
  t/content-model-6.dat
  t/content-model-7.dat
  t/table-1.dat
  t/dom-conformance/html-form-label.dat
]);

## License: Public Domain.
## $Date: 2008/10/05 05:59:37 $
