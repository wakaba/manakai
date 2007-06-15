package Message::DOM::Comment;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::CharacterData', 'Message::IF::Comment';
require Message::DOM::DOMCharacterData; ## TODO: Change to new module name

## The |Node| interface - attribute

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-F68D095>
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-1950641247>

sub node_name ($) {
  return '#comment';
} # node_name

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-111237558>

sub node_type ($) { 3 } # COMMENT_NODE

package Message::IF::Comment;

package Message::DOM::Document;

sub create_comment ($$) {
  return Message::DOM::Comment->____new ($_[0], $_[1]);
} # create_comment

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/15 14:32:50 $
