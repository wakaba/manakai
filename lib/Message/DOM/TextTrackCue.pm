package Message::DOM::TextTrackCue;
use strict;
use warnings;
our $VERSION = '1.0';
use Message::DOM::DOMException;

## Spec:
## <http://www.whatwg.org/specs/web-apps/current-work/#texttrackcue>
## and
## <http://suika.fam.cx/~wakaba/wiki/sw/n/manakai%20DOM%20Extensions#anchor-56>.

## XXX constructor

sub ____new_from_hashref ($$) {
  return bless $_[1], $_[0];
} # ____new_from_hashref

sub track ($) {
  # |track| must be a weakref.
  return $_[0]->{track}; # or undef
} # track

sub manakai_line ($) {
  return defined $_[0]->{line} ? $_[0]->{line} : -1;
} # manakai_line

sub manakai_column ($) {
  return defined $_[0]->{column} ? $_[0]->{column} : -1;
} # manakai_column

sub id ($;$) {
  if (@_ > 1) {
    $_[0]->{id} = $_[1] . '';
  }
  return $_[0]->{id}; # default = empty string
} # id

sub start_time ($;$) {
  if (@_ > 1) {
    $_[0]->{start_time} = 0+$_[1];
  }
  return $_[0]->{start_time};
} # start_time

sub end_time ($;$) {
  if (@_ > 1) {
    $_[0]->{end_time} = 0+$_[1];
  }
  return $_[0]->{end_time};
} # end_time

sub pause_on_exit ($;$) {
  if (@_ > 1) {
    $_[0]->{pause_on_exit} = !!$_[1];
  }
  return $_[0]->{pause_on_exit};
} # pause_on_exit

sub manakai_clone_cue ($) {
  my $self = shift;
  my $clone = (ref $self)->____new_from_hashref ({%{$self}});
  delete $clone->{track};
  return $clone;
} # manakai_clone_cue

1;

=head1 LICENSE

Copyright 2012-2013 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
