#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'manakai',
    DISTNAME     => 'manakai',      
    VERSION_FROM => 'lib/Message/Entity.pm',
    PREREQ_PM    => {
                     'Carp' => 0,
                     'Char::Class::XML' => 0,
                     'Time::Local' => 0,
#                     'Error' => 0,
#                     'Test' => 0,
#                     'Test::Simple' => 0,
# Exporter, Config
# Getopt::Long, Socket, Encode
# Jcode, Win32::Registry
                       'IO::String' => 0,
                     },
    dist         => {COMPRESS => 'gzip', SUFFIX => '.gz'},
    AUTHOR       => q(Wakaba <w@suika.fam.cx>),
);
