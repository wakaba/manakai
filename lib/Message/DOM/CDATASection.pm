package Message::DOM::CDATASection;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Text', 'Message::IF::CDATASection';
require Message::DOM::Text;

## |Node| attributes

sub node_name () { '#cdata-section' }

sub node_type () { 4 } # CDATA_SECTION_NODE

## |Text| attribute

sub is_element_content_whitespace () { 0 }

package Message::IF::CDATASection;

package Message::DOM::Document;

sub create_cdata_section ($$) {
  ## NOTE: |NOT_SUPPORTED_ERR| if HTML document [DOM3]
  return Message::DOM::CDATASection->____new (@_[0, 1]);
} # create_cdata_section

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 13:04:36 $
