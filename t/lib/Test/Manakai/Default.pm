package Test::Manakai::Default;
use strict;
use warnings;
BEGIN {
  require File::Basename;
  my $file_name = File::Basename::dirname (__FILE__) . '/../../../../config/perl/libs.txt';
  if (-f $file_name) {
    open my $file, '<', $file_name or die "$0: $file_name: $!";
    unshift @INC, split /:/, <$file>;
  }
}
use Path::Class;
use lib file (__FILE__)->dir->parent->parent->parent->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->parent->parent->parent->subdir ('modules', '*', 'lib')->stringify;
use Test::Manakai::Exceptions;
use Exporter::Lite;

push our @EXPORT, qw(dom_exception_ok);

1;
