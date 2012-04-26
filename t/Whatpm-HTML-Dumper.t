package test::Whatpm::HTML::Dumper;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->subdir ('modules', '*', 'lib')->stringify;
use base qw(Test::Class);
use Test::More;
use Message::DOM::DOMImplementation;
use Whatpm::HTML::Dumper;

sub _dump : Test(1) {
  my $dom = Message::DOM::DOMImplementation->new;
  my $doc = $dom->create_document;
  $doc->manakai_is_html (1);
  $doc->inner_html (q{<!DOCTYPE html><html><body>ff<p clasS=Abc>xx<img/>});
  
  is dumptree $doc, q{<!DOCTYPE html>
<html>
  <head>
  <body>
    "ff"
    <p>
      class="Abc"
      "xx"
      <img>
};
} # _dump

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
