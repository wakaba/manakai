package Message::DOM::Comment;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::CharacterData', 'Message::IF::Comment';
require Message::DOM::DOMCharacterData; ## TODO: Change to new module name

## The |Node| interface - attribute

sub node_type () { 3 } # COMMENT_NODE

package Message::IF::Comment;

package Message::DOM::Document;

sub create_comment ($$) {
  return Message::DOM::Comment->____new ($_[0], $_[1]);
} # create_comment

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/13 12:04:50 $
