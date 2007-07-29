#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'manakai',
    DISTNAME     => 'manakai',
    VERSION => '0.4.0',
    PREREQ_PM => {
      'Carp' => 0,
      'Char::Class::XML' => 0,
      'Encode' => 0,
      'Test' => 0,
      'Time::Local' => 0,
    
# Exporter, Config, Test::Simple
# Getopt::Long, Socket
# Jcode, Win32::Registry
    },
    dist         => {COMPRESS => 'gzip', SUFFIX => '.gz'},
    AUTHOR       => q(Wakaba <w@suika.fam.cx>),
);
