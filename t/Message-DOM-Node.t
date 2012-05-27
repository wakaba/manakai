package test::Message::DOM::TextTrackCue;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Message::DOM::Node;

sub _constants : Test(4) {
  ok ELEMENT_NODE;
  ok ATTRIBUTE_NODE;
  ok DOCUMENT_TYPE_NODE;
  ok ATTRIBUTE_DEFINITION_NODE;
} # _constants

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
