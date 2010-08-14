package test::Whatpm::CSS::Colors;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Whatpm::CSS::Colors;
use Test::More;
use Test::Differences;
use base qw(Test::Class);

sub _x11_colors : Test(5) {
  eq_or_diff $Whatpm::CSS::Colors::X11Colors->{red}, [0xFF, 0, 0];
  eq_or_diff $Whatpm::CSS::Colors::X11Colors->{gray}, [0x80, 0x80, 0x80];
  eq_or_diff $Whatpm::CSS::Colors::X11Colors->{grey}, [0x80, 0x80, 0x80];
  is $Whatpm::CSS::Colors::X11Colors->{RED}, undef;
  is $Whatpm::CSS::Colors::X11Colors->{unknown}, undef;
}

sub _system_colors : Test(3) {
  ok $Whatpm::CSS::Colors::SystemColors->{activeborder};
  ok !$Whatpm::CSS::Colors::SystemColors->{ActiveBorder};
  ok !$Whatpm::CSS::Colors::SystemColors->{unknown};
}

__PACKAGE__->runtests;

1;
