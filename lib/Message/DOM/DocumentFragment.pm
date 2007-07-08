package Message::DOM::DocumentFragment;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::DocumentFragment';
require Message::DOM::Node;

sub ____new ($$) {
  my $self = shift->SUPER::____new (shift);
  $$self->{child_nodes} = [];
  return $self;
} # ____new
             
## |Node| attributes

sub node_name () { '#document-fragment' }

sub node_type () { 11 } # DOCUMENT_FRAGMENT_NODE

package Message::IF::DocumentFragment;

package Message::DOM::Document;

sub create_document_fragment ($) {
  return Message::DOM::DocumentFragment->____new ($_[0]);
} # create_document_fragment

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 13:04:36 $
