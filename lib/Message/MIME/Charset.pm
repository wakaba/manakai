
=head1 NAME

Message::MIME::Charset Perl module

=head1 DESCRIPTION

Perl module for MIME charset.

=cut

package Message::MIME::Charset;
use strict;
use vars qw(%ENCODER %DECODER %N11NTABLE %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

our %CHARSET;

$CHARSET{'*DEFAULT'} = {
	preferred_name	=> '',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 1,	## Suitability in use as MIME text/* charset
	#accept_cte	=> [qw/7bit .../],
	cte_7bit_preferred	=> 'quoted-printable',
};
$CHARSET{'*default'} = $CHARSET{'*DEFAULT'};

$CHARSET{'us-ascii'} = {
	preferred_name	=> 'us-ascii',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 1,
};

$CHARSET{'iso-2022-int-1'} = {
	preferred_name	=> 'iso-2022-int-1',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	name_minimumizer	=> sub {
	  shift; my $s = shift;
	  return (charset => 'us-ascii') unless $s =~ /[\x1B\x0E\x0F]/;
	  return (charset => 'iso-2022-jp') unless $s =~ /\x1B[^\x24\x28]|\x1B\x24[^\x40B]|\x1B\x28[^BJ]|\x0E|\x0F/;
	  return (charset => 'iso-2022-jp-1') unless $s =~ /\x1B[^\x24\x28]|\x1B\x24[^\x40B\x28]|\x1B\x28[^BJ]|\x1B\x24\x28[^D]|\x0E|\x0F/;
	  return (charset => 'iso-2022-jp-3-plane1') unless $s =~ /\x1B[^\x24\x28]|\x1B\x24[^B\x28]|\x1B\x28[^B]|\x1B\x24\x28[^O]|\x0E|\x0F/;
	  return (charset => 'iso-2022-jp-3') unless $s =~ /\x1B[^\x24\x28]|\x1B\x24[^B\x28]|\x1B\x28[^B]|\x1B\x24\x28[^OP]|\x0E|\x0F/;
	  return (charset => 'iso-2022-kr') unless $s =~ /\x1B[^\x24]|\x1B\x24[^\x29]|\x1B\x24\x29C/;
	  return (charset => 'iso-2022-cn') unless $s =~ /\x1B[^\x24\x28]|\x1B\x24[^B]|\x1B\x28[^A]|\x1B\x24\x28[^GH]|\x0E|\x0F/;
	  (charset => 'iso-2022-int-1');
	},
	
	mime_text	=> 1,
};

$CHARSET{'unknown-8bit'} = {
	preferred_name	=> 'unknown-8bit',
	
	encoder	=> sub { $_[1] },
	decoder	=> sub { $_[1] },
	
	mime_text	=> 0,
	cte_7bit_preferred	=> 'base64',
};
$CHARSET{'x-unknown'} = $CHARSET{'unknown-8bit'};

sub make_charset ($%) {
  my $name = shift;
  return unless $name;	## Note: charset "0" is not supported.
  my %definition = @_;
  
  $definition{preferred_name} ||= $name;
  if ($definition{preferred_name} ne $name
      && ref $CHARSET{$definition{preferred_name}}) {
  ## New charset is an alias of defined charset,
    $CHARSET{$name} = $CHARSET{$definition{preferred_name}};
    return;
  } elsif ($definition{alias_of} && ref $CHARSET{$definition{alias_of}}) {
  ## New charset is an alias of defined charset,
    $CHARSET{$name} = $CHARSET{$definition{alias_of}};
    return;
  }
  $CHARSET{$name} = \%definition;
  
  ## Set default values
  #$definition{encoder} ||= sub { $_[1] };
  #$definition{decoder} ||= sub { $_[1] };

  $definition{mime_text} = 0 unless defined $definition{mime_text};
  $definition{cte_7bit_preferred} = 'base64'
    unless defined $definition{cte_7bit_preferred};
}

sub encode ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $CHARSET{$charset}->{encoder}) {
    return (&{$CHARSET{$charset}->{encoder}} ($charset, $s), success => 1);
  }
  ($s, success => 0);
}

sub decode ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $CHARSET{$charset}->{decoder}) {
    return (&{$CHARSET{$charset}->{decoder}} ($charset, $s), 1);
  }
  ($s, 0);
}

sub name_normalize ($) {
  my $name = lc shift;
  $CHARSET{$name}->{preferred_name} || $name;
}

sub name_minimumize ($$) {
  my ($charset, $s) = (lc shift, shift);
  if (ref $CHARSET{$charset}->{name_minimumizer}) {
    return &{$CHARSET{$charset}->{name_minimumizer}} ($charset, $s);
  }
  $charset;
}

=head1 LICENSE

Copyright 2002 wakaba E<lt>w@suika.fam.cxE<gt>.

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

=head1 CHANGE

See F<ChangeLog>.
$Date: 2002/06/09 11:13:14 $

=cut

1;
