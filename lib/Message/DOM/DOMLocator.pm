package Message::DOM::DOMLocator;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMLocator';

## |DOMLocator| attributes

for (qw/byte_offset column_number line_number utf16_offset utf32_offset/) {
  eval qq{
    sub $_ (\$) {
      return defined \$_[0]->{$_} ? \$_[0]->{$_} : -1;
    } # $_
  };
}

sub related_node ($) {
  return $_[0]->{related_node};
} # related_node

sub uri ($) {
  return $_[0]->{uri};
} # uri

## NOTE: |utf32Offset| is a manakai extension.

## ISSUE: Document the reason not utf_32 or utf_16 in Perl binding doc.

package Message::IF::DOMLocator;
push our @ISA, 'Message::Util::Error';

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/21 11:59:36 $
