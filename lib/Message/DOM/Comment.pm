package Message::DOM::Comment;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::CharacterData', 'Message::IF::Comment';
require Message::DOM::DOMCharacterData; ## TODO: Change to new module name

## |Node| attributes

sub node_name () { '#comment' }

sub node_type () { 8 } # COMMENT_NODE

package Message::IF::Comment;

package Message::DOM::Document;

sub create_comment ($$) {
  return Message::DOM::Comment->____new ($_[0], $_[1]);
} # create_comment

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/08 13:04:36 $
