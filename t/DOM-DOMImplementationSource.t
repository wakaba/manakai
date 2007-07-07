#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 24 } 

require Message::DOM::DOMImplementationSource;

my $source = 'Message::DOM::DOMImplementationSource';

for (
  [undef, 1, 'undef'],
  ['', 1, 'empty'],
  [{core => '3.0'}, 1, '{core=>3.0}'],
  [{Core => '3.0'}, 1, '{Core=>3.0}'],
  [{Core => ''}, 1, '{Core=>}'],
  [{Core => undef}, 1, '{Core=>undef}'],
  [{Core => ['3.0']}, 1, '{Core=>[3.0]}'],
  ['Core 3.0', 1, 'Core 3.0'],
  [{Core => '3.0', xml => '3.0'}, 1, '{Core=>3.0,xml=>3.0}'],
  ['Core 3.0 XML 3.0', 1, 'Core 3.0 XML 3.0'],
  ['Core 3.0 XML', 1, 'Core 3.0 XML'],
  ['no-such-feature', 0, 'no-such-feature'],
) {
  my $dom = $source->get_dom_implementation ($_->[0]);
  ok defined $dom ? 1 : 0, $_->[1], 'get ' . $_->[2];
  my $list = $source->get_dom_implementation_list ($_->[0]);
  ok 0+@$list, $_->[1] ? 1 : 0, 'get list ' . $_->[2];
}

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

## $Date: 2007/07/07 05:58:11 $
