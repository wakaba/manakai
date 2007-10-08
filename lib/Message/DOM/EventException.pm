package Message::DOM::EventException;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::Util::Error', 'Message::IF::EventException';
require Message::Util::Error;

sub ___error_def () {+{
  UNSPECIFIED_EVENT_TYPE_ERR => {
    -code => 0,
    -description => q(Event type is not specified),
  },
  DISPATCH_REQUEST_ERR => {
    -code => 1,
    -description => q(The event is already dispatched),
  },
}} # ___error_def

package Message::IF::EventException;
push our @ISA, 'Message::Util::Error';

sub UNSPECIFIED_EVENT_TYPE_ERR () { 0 }
sub DISPATCH_REQUEST_ERR () { 1 }

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/10/08 07:17:18 $
