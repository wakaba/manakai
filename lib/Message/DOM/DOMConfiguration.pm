package Message::DOM::DOMConfiguration;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

sub get_parameter ($$) {
  return ${$${$_[0]}}->{$_[1]};
} # get_parameter

sub set_parameter ($$;$) {
  if (defined $_[2]) {
    ${$${$_[0]}}->{$_[1]} = $_[2];
  } else {
    if ($_[1] eq 'http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree' or
        $_[1] eq 'http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute' or
        $_[1] eq 'http://suika.fam.cx/www/2006/dom-config/strict-document-children') {
      ${$${$_[0]}}->{$_[1]} = 1;
    } elsif ($_[1] eq 'error-handler') {
      ${$${$_[0]}}->{$_[1]} = sub { };
    } else {
      delete ${$${$_[0]}}->{$_[1]};
    }
  }
  ## http://suika.fam.cx/www/2006/dom-config/clone-entity-reference-subtree
  ## http://suika.fam.cx/www/2006/dom-config/dtd-default-attribute
  ## http://suika.fam.cx/www/2006/dom-config/xml-id
  ## error-handler
  ## xml-dtd
  ## http://suika.fam.cx/www/2006/dom-config/strict-document-children
} # set_parameter

package Message::IF::DOMConfiguration;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/06/21 14:57:53 $
