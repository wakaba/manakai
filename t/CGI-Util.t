package test::Message::CGI::Util;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Message::CGI::Util qw(datetime_for_http);
use Test::More;

sub _d4http : Test(8) {
  for (
    [undef, '01 Jan 1970 00:00:00 +0000'],
    [0, '01 Jan 1970 00:00:00 +0000'],
    ['', '01 Jan 1970 00:00:00 +0000'],
    ['abc', '01 Jan 1970 00:00:00 +0000'],
    [-535253, '25 Dec 1969 19:19:07 +0000'], # when negative time_t is allowed
    [535253, '07 Jan 1970 04:40:53 +0000'],
    [1012535253, '01 Feb 2002 03:47:33 +0000'],
    [20010533515, '10 Feb 2604 09:31:55 +0000'], # 64bit env only
  ) {
    is datetime_for_http $_->[0], $_->[1];
  }
} # _d4http

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
