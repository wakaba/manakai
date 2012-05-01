package Message::DOM::TextTrackCueList;
use strict;
use warnings;
our $VERSION = '1.0';

## Spec:
## <http://www.whatwg.org/specs/web-apps/current-work/#texttrackcuelist>.

sub ____new_from_arrayref ($$) {
  return bless $_[1], $_[0];
} # ____new_from_arrayref

sub length ($) {
  return scalar @{$_[0]};
} # length

# $list->[$index]

# XXX DOM Perl Binding spec disallow modification of the array if the
# underlying list is read-only.

sub get_cue_by_id ($$) {
  my $name = $_[1] . '';
  return undef if not CORE::length $name;
  
  for (@{$_[0]}) {
    if ($_->id eq $name) {
      return $_;
    }
  }

  return undef;
} # get_cue_by_id

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
