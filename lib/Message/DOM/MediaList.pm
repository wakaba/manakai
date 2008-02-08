package Message::DOM::MediaList;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::MediaList';

sub ____new {
  return bless \[], $_[0];
} # ____new

use overload
    '""' => 'media_text', fallback => 1;

sub media_text ($;$) {
  ## TODO: implement setter!
  require Whatpm::CSS::MediaQuerySerializer;
  return Whatpm::CSS::MediaQuerySerializer->serialize_media_query (${$_[0]});
} # media_text

## TODO: Implement!

package Message::IF::MediaList;

1;
## $Date: 2008/02/08 15:08:04 $

