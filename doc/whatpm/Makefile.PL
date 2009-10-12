#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;
WriteMakefile (
  NAME => 'Whatpm',
  DISTNAME => 'whatpm',
  VERSION => '0.1',
  dist => {COMPRESS => 'gzip', SUFFIX => '.gz'},
  AUTHOR => q(Wakaba <w@suika.fam.cx>),
);
