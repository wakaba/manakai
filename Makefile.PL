#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'manakai',
    DISTNAME     => 'manakai',      
    VERSION_FROM => 'Message/Entity.pm',
    PREREQ_PM    => {
                     'Carp' => 0,
                    },
    dist         => {COMPRESS => 'gzip', SUFFIX => '.gz'},
);
