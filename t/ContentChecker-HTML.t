#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->stringify;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;

BEGIN {
  require 'content-checker.pl';
}

test_files (map { file (__FILE__)->dir->parent->file($_)->stringify } qw[
  t/content-model-1.dat
  t/content-model-7.dat
  t/dom-conformance/html-1.dat
  t/dom-conformance/html-global-1.dat
  t/dom-conformance/html-dataset.dat
  t/dom-conformance/html-metadata-1.dat
  t/dom-conformance/html-metadata-2.dat
  t/dom-conformance/html-flows-1.dat
  t/dom-conformance/html-texts-1.dat
  t/dom-conformance/html-links-1.dat
  t/dom-conformance/html-links-2.dat
  t/dom-conformance/html-objects-1.dat
  t/dom-conformance/html-tables-1.dat
  t/dom-conformance/html-tables-2.dat
  t/dom-conformance/html-forms-1.dat
  t/dom-conformance/html-form-label.dat
  t/dom-conformance/html-form-input-1.dat
  t/dom-conformance/html-form-button.dat
  t/dom-conformance/html-form-select.dat
  t/dom-conformance/html-form-datalist.dat
  t/dom-conformance/html-form-textarea.dat
  t/dom-conformance/html-form-keygen.dat
  t/dom-conformance/html-interactive-1.dat
  t/dom-conformance/html-scripting-1.dat
  t/dom-conformance/html-scripting-2.dat
  t/dom-conformance/html-repetitions.dat
  t/dom-conformance/html-datatemplate.dat
  t/dom-conformance/html-frames.dat
]);

done_testing;

## License: Public Domain.
