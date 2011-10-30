#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'manakai',
    DISTNAME     => 'manakai',
    VERSION => '0.4.0',
    PREREQ_PM => {
      'Carp' => 0,
      #'Char::Class::XML' => 0,
      'Encode' => 0,
      'Time::Local' => 0,
      'Exporter' => 0,
      'Config' => 0,
      'Getopt::Long' => 0,
      'Inline::Python' => 0,
      'Socket' => 0,
      'Path::Class' => 0,
      'Tie::Array' => 0,
      #'Jcode' => 0,
      #'Win32::Registry' => 0,
    },
    BUILD_REQUIRES => {
      'Test' => 0,
      'Test::Simple' => 0,
      'Test::More' => 0,
      'Test::Class' => 0,
      'Test::Differences' => 0,
      'JSON' => 2,
    },
    dist         => {COMPRESS => 'gzip', SUFFIX => '.gz'},
    AUTHOR       => q(Wakaba <w@suika.fam.cx>),
);
