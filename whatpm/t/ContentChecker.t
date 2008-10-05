#!/usr/bin/perl
use strict;

BEGIN {
  require 't/content-checker.pl';
  plan (tests => 3201);
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
  t/dom-conformance/html-global-1.dat
  t/dom-conformance/html-metadata-1.dat
  t/dom-conformance/html-flows-1.dat
  t/dom-conformance/html-texts-1.dat
  t/dom-conformance/html-tables-1.dat
  t/dom-conformance/html-forms-1.dat
  t/dom-conformance/html-form-input-1.dat
  t/dom-conformance/html-form-label.dat
  t/dom-conformance/html-repetitions.dat
  t/dom-conformance/html-datatemplate.dat
]);

## License: Public Domain.
## $Date: 2008/10/05 11:51:14 $
