package Message::DOM::TypeInfo;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::TypeInfo';

use overload
    eq => sub {
      ## TODO: Document in Perl binding spec.
      return 0 unless UNIVERSAL::isa ($_[1], 'Message::IF::TypeInfo');
      for (qw/type_name type_namespace/) {
        my $v1 = $_[0]->$_;
        my $v2 = $_[1]->$_;
        return 0 if defined $v1 and not defined $v2;
        return 0 if defined $v2 and not defined $v1;
        if (defined $v1 and defined $v2) {
          return 0 if $v1 ne $v2;
        }
      }
      return 1;
    },
    ne => sub {
      return not ($_[0] eq $_[1]);
    },
    fallback => 1;

## DerivationMethods
sub DERIVATION_RESTRICTION () { 0x00000001 }
sub DERIVATION_EXTENSION () { 0x00000002 }
sub DERIVATION_UNION () { 0x00000004 }
sub DERIVATION_LIST () { 0x00000008 }

## NOTE: Currently, manakai only supports XML DTD types.

## |TypeInfo| attributes

sub type_name ($) {
  return [undef, qw/CDATA ID IDREF IDREFS ENTITY ENTITIES
          NMTOKEN NMTOKENS NOTATION ENUMERATION/, undef]->[${$_[0]}];
} # type_name

sub type_namespace ($) {
  return [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]->[${$_[0]}]
      ? q<http://www.w3.org/TR/REC-xml> : undef;
} # type_namespace

## |TypeInfo| methods

sub is_derived_from () { 0 }

package Message::IF::TypeInfo;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/29 03:49:00 $
