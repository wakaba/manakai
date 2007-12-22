package Message::DOM::MediaList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::MediaList';

sub ____new {
  return bless \[], $_[0];
} # ____new

use overload
    '""' => 'media_text', fallback => 1;

sub media_text ($;$) {
  ## TODO: implement!
  return '';
} # media_text

## TODO: Implement!

package Message::IF::MediaList;

1;
## $Date: 2007/12/22 06:57:46 $

