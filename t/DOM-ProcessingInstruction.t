#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 6 } 

require Message::DOM::DOMImplementation;
use Message::Util::Error;

my $dom = Message::DOM::DOMImplementation->____new;
my $doc = $dom->create_document;

my $el = $doc->create_processing_instruction ('pi');

for my $prop (qw/manakai_base_uri/) {
  ok $el->can ($prop) ? 1 : 0, 1, 'can ' . $prop;
  
  for ('http://absuri.test/', 'reluri', 0, '') {
    $el->$prop ($_);
    ok $el->$prop, $_, $prop . $_;
  }

  $el->$prop (undef);
  ok $el->$prop, undef, $prop . ' undef';
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/06/17 13:37:42 $
