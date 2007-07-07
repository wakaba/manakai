package Message::DOM::DOMImplementationSource;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::DOMImplementationSource';

$Message::DOM::DOMImplementationRegistry::SourceClass->{''.__PACKAGE__} = 1;

## |DOMImplementationSource| methods

sub get_dom_implementation ($$) {
  require Message::DOM::DOMImplementation;
  my $r = Message::DOM::DOMImplementation->new;

  my $features = _parse_features ($_[1]);
  for my $feature (keys %$features) {
    my $fkey = $feature;
    my $plus = $feature =~ s/^\+// ? 1 : 0;
    for my $version (keys %{$features->{$fkey}}) {
      unless ($Message::DOM::DOMImplementation::HasFeature->{$feature}
              ->{$version}) {
        return undef;
      }
    }
  }

  return $r;
} # get_dom_implementation

sub get_dom_implementation_list ($$) {
  require Message::DOM::DOMImplementationList;
  my $list = bless [], 'Message::DOM::DOMImplementationList';
  my $dom = $_[0]->get_dom_implementation ($_[1]);
  push @$list, $dom if defined $dom;
  return $list;
} # get_dom_implementation_list

sub _parse_features ($) {
  if (defined $_[0]) {
    if (ref $_[0] eq 'HASH') {
      my $new = {};
      for my $fname (keys %{$_[0]}) {
        if (ref $_[0]->{$fname} eq 'HASH') {
          my $lfname = lc $fname;
          ## TODO: Feature names are case-insensitive, but
          ## what kind of case-insensitivity?
          for my $fver (keys %{$_[0]->{$fname}}) {
            $new->{$lfname}->{$fver} = 1 if $_[0]->{$fname}->{$fver};
          }
        } elsif (ref $_[0]->{$fname} eq 'ARRAY') {
          my $lfname = lc $fname;
          for my $fver (@{$_[0]->{$fname}}) {
            $new->{$lfname}->{$fver} = 1;
          }
        } elsif (defined $_[0]->{$fname}) {
          $new->{lc $fname} = {''.$_[0]->{$fname} => 1};
        }
      }
      return $new;
    } else {
      my @f = split /\s+/, $_[0];
      ## TODO: Definition of space ???
      ## TODO: How to parse features string into names and versions ???
      my $new = {};
      while (@f) {
        my $fname = lc shift @f;
        if (@f and $f[0] =~ /\A[\d\.]+\z/) {
          $new->{$fname}->{shift @f} = 1;
        } else {
          $new->{$fname}->{''} = 1;
        }
      }
      return $new;
    }
  } else {
    return {};
  }
} # _parse_features

package Message::IF::DOMImplementationSource;

=head1 LICENSE

Copyright 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
## $Date: 2007/07/07 09:11:05 $
