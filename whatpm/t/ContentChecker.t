#!/usr/bin/perl
use strict;

BEGIN {
  require 't/content-checker.pl';
  plan (tests => 4464);
}

test_files (qw[
  t/content-model-1.dat
  t/content-model-7.dat
  t/table-1.dat
  t/dom-conformance/html-1.dat
  t/dom-conformance/html-global-1.dat
  t/dom-conformance/html-dataset.dat
  t/dom-conformance/html-metadata-1.dat
  t/dom-conformance/html-flows-1.dat
  t/dom-conformance/html-texts-1.dat
  t/dom-conformance/html-links-1.dat
  t/dom-conformance/html-objects-1.dat
  t/dom-conformance/html-tables-1.dat
  t/dom-conformance/html-forms-1.dat
  t/dom-conformance/html-form-label.dat
  t/dom-conformance/html-form-input-1.dat
  t/dom-conformance/html-form-button.dat
  t/dom-conformance/html-form-select.dat
  t/dom-conformance/html-form-datalist.dat
  t/dom-conformance/html-form-textarea.dat
  t/dom-conformance/html-interactive-1.dat
  t/dom-conformance/html-scripting-1.dat
  t/dom-conformance/html-repetitions.dat
  t/dom-conformance/html-datatemplate.dat
]);

## License: Public Domain.
## $Date: 2009/06/28 10:48:30 $
