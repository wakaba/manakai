package test::Whatpm::CacheManifest;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Test::More;
use Test::Differences;

sub _use : Test(1) {
  use_ok 'Whatpm::CacheManifest';
} # _use

__PACKAGE__->runtests;

1;

## License: Public Domain.
