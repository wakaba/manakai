
=head1 NAME

Message::Util::HostPermit --- manakai: Simple host permission checker

=head1 DESCRIPTION

This module is part of manakai.

=cut

package Message::Util::HostPermit;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 METHODS

=over 4

=item $err = Message::Util::HostPermit->new ()

Constructs new instance

=cut

sub new ($) {
  my $class = shift;
  my $self = bless {rule => []}, $class;
  $self;
}

sub add_rule ($$) {
  my ($self, $s) = @_;
  for (split /[\x0D\x0A]+/, $s) {
    s/\#.*$//g;
    if (/^(Allow|Deny) (.+)$/) {
      my $rule = {type => $1};
      for (split /\s+/, $2) {
        my ($name, $val) = split /=/, $_, 2;
        $rule->{'-'.$name} = $val;
      }
      push @{$self->{rule}}, $rule;
    }
  }
}

sub check ($$;$) {
  my ($self, $name, $port) = @_;
  my ($name, undef, undef, undef, $addr) = gethostbyname ($name);
  return 0 if !$name && !$addr;
  for my $rule (@{$self->{rule}}) {
    if ($rule->{-host}) {
      if ($self->match_host ($rule->{-host}, $name)) {
        if (!$rule->{-port} || ($rule->{-port} == $port)) {
          return ($rule->{type} eq 'Allow') ? 1 : 0;
        }
      }
    } elsif ($rule->{-ipv4}) {
       if ($self->match_ipv4 ($rule->{-ipv4}, $addr)) {
        if (!$rule->{-port} || ($rule->{-port} == $port)) {
          return ($rule->{type} eq 'Allow') ? 1 : 0;
        }
      }
    } elsif ($rule->{-ipv6}) {
       if ($self->match_ipv6 ($rule->{-ipv6}, $addr)) {
        if (!$rule->{-port} || ($rule->{-port} == $port)) {
          return ($rule->{type} eq 'Allow') ? 1 : 0;
        }
      }
    }
  }
  return 1;
}

sub match_host ($$$) {
  my ($self, $pattern, $host) = @_;
  if (index ($pattern, '*') > -1) {
    my @host = reverse split /\./, $host;
    my @pattern = reverse split /\./, $pattern;
    return 0 if $#host < $#pattern;
    for (0..$#pattern) {
      if ($pattern[$_] eq '*') {
        return 1;
      } elsif ($host[$_] ne $pattern[$_]) {
        return 0;
      }
    }
    return 0;
  } else {
    return $pattern eq $host ? 1 : 0;
  }
}

sub match_ipv4 ($$$) {
  my ($self, $pattern, $addr) = @_;
  if (length ($addr) != 4) {
    $addr =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/;
    $addr = pack 'C4', $1, $2, $3, $4;
  }
  if (length ($pattern) != 4) {
    $pattern =~ m!([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)(?:/([0-9]+))?!;
    $pattern = pack 'C4', $1, $2, $3, $4;
    my $m = $5; $m %= 33;
    my $mask = pack 'C4', (($m > 24) ? (2**($m-24)-1, 255, 255, 255) :
                           ($m > 16) ? (0, 2**($m-16)-1, 255, 255) :
                           ($m >  8) ? (0, 0, 2**($m-8)-1, 255) :
                                       (0, 0, 0, 2**$m));
    $pattern |= $mask;
  }
  return (($addr & $pattern) eq $addr) ? 1 : 0;
}

## TODO: IPv6 support
sub match_ipv6 {
  return 0;
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/09/17 02:34:32 $
