package Message::DOM::DOMConfiguration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMConfiguration';
require Message::DOM::DOMException;

use overload
    eq => sub {
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::DOM::DOMConfiguration');
      return $${$_[0]} eq $${$_[1]};
    },
    ne => sub {
      return not ($_[0] eq $_[1]);
    },
    fallback => 1;

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

## |DOMConfiguration| methods

sub set_parameter ($$;$) {
  ${$${$_[0]}}->{$_[1]} = $_[2];
} # set_parameter

package Message::IF::DOMConfiguration;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/16 15:27:45 $
