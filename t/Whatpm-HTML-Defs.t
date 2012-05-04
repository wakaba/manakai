package test::Whatpm::HTML::Defs;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Whatpm::HTML::Defs;

sub _chars : Test(3) {
  ok EOF_CHAR;
  ok ABORT_CHAR;
  ok NEVER_CHAR;
} # _chars

sub _tokens : Test(4) {
  ok DOCTYPE_TOKEN;
  ok START_TAG_TOKEN;
  ok ABORT_TOKEN;
  ok END_OF_FILE_TOKEN;
} # _tokens

sub _elements : Test(1) {
  ok FOREIGN_EL;
} # _elements

sub _error : Test(1) {
  is ref $Whatpm::HTML::Defs::DefaultErrorHandler, 'CODE';
} # _error

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
