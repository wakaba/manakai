
=head1 NAME

Message::Util::Formatter --- General format text to composed text converter

=cut

package Message::Util::Formatter;
use strict;
use vars qw(%FMT2STR $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;

## Embeded formatting rules (default)
%FMT2STR = (
	char	=> sub {
	  my $p = $_[0];
	  if ($p->{ucs} =~ /^0[xob][0-9A-Fa-f]+$/) {
	    return pack 'U', oct $p->{ucs};
	  } elsif (defined $p->{ucs}) {
	    return pack 'U', $p->{ucs};
	  } else {
	    return "\x{FFFD}";
	  }
	},
	percent	=> '%',
);

sub new ($) {
  my $self = bless Message::Util::make_clone (\%FMT2STR), shift;
  $self;
}

sub replace ($$;\%) {
  my $self = shift;
  my $format = shift;
  my $gparam = shift;
  $format =~ s{%([A-Za-z0-9_]+)(?:\(([^\x29]*)\))?;}{
    my ($f, $a) = ($1, $2);
    my $function = $gparam->{fmt2str}->{$f} || $self->{$f};
    if (ref $function) {
      my %a;
      for (split /[\x09\x20]*,[\x09\x20]*/, $a) {
        if (/^([^=]*[^\x09\x20=])[\x09\x20]*=>[\x09\x20]*([^\x09\x20].*)$/) {
          $a{ Message::Util::Wide::unquote_if_quoted_string ($1) } = Message::Util::Wide::unquote_if_quoted_string ($2);
        } else {
          $a{ Message::Util::Wide::unquote_if_quoted_string ($_) } = 1;
        }
      }
      my $r = &$function (\%a, $gparam);
      length $r? $a{prefix}.$r.$a{suffix}: '';
    } elsif (length $function) {
      $function;
    } else {
      qq([$f: undef]);
    }
  }gex;
  $format;
}

=head1 LICENSE

Copyright 2002 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=cut

1;
# $Date: 2002/11/13 10:59:11 $
