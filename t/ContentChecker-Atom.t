#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->stringify;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;

BEGIN {
  require 'content-checker.pl';
  plan (tests => 103);
}

test_files (map { file (__FILE__)->dir->parent->file($_)->stringify } qw[
  t/content-model-atom-1.dat
  t/content-model-atom-2.dat
  t/content-model-atom-threading-1.dat
]);

## License: Public Domain.
