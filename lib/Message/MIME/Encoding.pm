
=head1 NAME

Message::MIME::Encoding --- Encoding (MIME CTE, HTTP encodings, etc) definitions

=cut

package Message::MIME::Encoding;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

our %ENCODER = (
	'7bit'	=> sub { ($_[1], decide_coderange (@_[0,1,2])) },
	'8bit'	=> sub { ($_[1], decide_coderange (@_[0,1,2])) },
	binary	=> sub { ($_[1], decide_coderange (@_[0,1,2])) },
	base64	=> sub {
		require MIME::Base64;
		my $s = MIME::Base64::encode ($_[1]);
		$s =~ s/\x0D(?!\x0A)/\x0D\x0A/gs;
		$s =~ s/(?<!\x0D)\x0A/\x0D\x0A/gs;
		($s, 'base64');
	},
	'quoted-printable'	=> \&encode_qp,
	#	=> sub { require MIME::QuotedPrint; 
	#	         (MIME::QuotedPrint::encode ($_[1]), 'quoted-printable') },
	'x-gzip64' => sub {
		if (eval {require Compress::Zlib}) {
		  require MIME::Base64;
		  my $s = Compress::Zlib::memGzip ($_[1]);
		  $s = MIME::Base64::encode ($s);
		  $s =~ s/\x0D(?!\x0A)/\x0D\x0A/gs;
		  $s =~ s/(?<!\x0D)\x0A/\x0D\x0A/gs;
		  ($s, 'x-gzip64');
		} else {
		  Carp::carp "gzip64 encode: $@";
		  ($_[1], 'binary');
		}
	},
	'x-uu'	=> \&uuencode,
	'x-uue'	=> \&uuencode,
	'x-uuencode'	=> \&uuencode,
	'x-uuencoded'	=> \&uuencode,
);
our %DECODER = (
	'7bit'	=> sub { ($_[1], 'binary') },
	'8bit'	=> sub { ($_[1], 'binary') },
	binary	=> sub { ($_[1], 'binary') },
	base64	=> sub { require MIME::Base64; 
		         (MIME::Base64::decode ($_[1]), 'binary') },
	'quoted-printable'	=> \&decode_qp,
	#	=> sub { require MIME::QuotedPrint; 
	#	         (MIME::QuotedPrint::decode ($_[1]), 'binary') },
	'x-gzip64'	=> sub {
		require MIME::Base64;
		my $s = MIME::Base64::decode ($_[1]);
		my ($t, $e) = uncompress_gzip ($_[0], $s);
		if ($e eq 'identity') { return ($t, 'binary') }
		else { return ($_[1], 'x-gzip64') }
	},
	'x-uu'	=> \&uudecode,
	'x-uue'	=> \&uudecode,
	'x-uuencode'	=> \&uudecode,
	'x-uuencoded'	=> \&uudecode,
);

sub decide_coderange ($$\%) {
  my $yourself = shift;
  my $s = shift;
  my $option = shift;
  if (!defined $option->{mt_is_text}) {
    my $mt; $mt = ($yourself->content_type)[0] if ref $yourself;
    $option->{mt_is_text} = 1
      if $mt eq 'text' || $mt eq 'multipart' || $mt eq 'message';
  }
  return 'binary' if $s =~ /\x00/;
  if ($option->{mt_is_text}) {
    return 'binary' if $s =~ /\x0D(?!\x0A)/s;
    return 'binary' if $s =~ /(?<!\x0D)\x0A/s;
  } else {
    return 'binary' if $s =~ /\x0D|\x0A/s;
  }
  return 'binary' if $s =~ /[^\x0D\x0A]{999}/;
  return '8bit'   if $s =~ /[\x80-\xFF]/;
  '7bit';
}

## Original: MIME::QuotedPrint Revision: 2.3 1997/12/02 10:24:27
##           by Gisle Aas
sub encode_qp ($$) {
  my $yourself = shift;
  my $s = shift;
  my $nl = "\x0D\x0A";
  my $mt_is_text = 0;
  my $mt; $mt = ($yourself->content_type)[0] if ref $yourself;
  $mt_is_text = 1 if $mt eq 'text' || $mt eq 'multipart' || $mt eq 'message';
  ## RFC 2045 [^\x09\x20\x21-\x3C\x3E-\x7E]
  ## - RFC 2049 "mail-safe"	[^\x09\x20\x25-\x3C\x3E\x3F\x41-\x5A\x5F\x61-\x7A]
  $s =~ s/([^\x09\x20\x25-\x3C\x3E\x3F\x41-\x5A\x5F\x61-\x7A])/sprintf('=%02X', ord($1))/eg;  # rule #2,#3
  if ($mt_is_text) {
    $s =~ s/([\x09\x20])(?==0D=0A|$)/
      sprintf '=%02X', ord($1)
      #join('', map { sprintf('=%02X', ord($_)) } split('', $1) )
    /egm;                        # rule #3 (encode whitespace at eol)
    $s =~ s/=0D=0AFrom/\x0D\x0A=46rom/g;
    $s =~ s/=0D=0A/\x0D\x0A/g;
  } else {
    $s =~ s/([\x09\x20])$/
      sprintf '=%02X', ord($1)
      #join('', map { sprintf('=%02X', ord($_)) } split('', $1) )
    /egm;                        # rule #3 (encode whitespace at eol)
  }
  
  # rule #5 (lines must be shorter than 76 chars, but we are not allowed
  # to break =XX escapes.  This makes things complicated :-( )
  my $brokenlines = "";
  $brokenlines .= $1.'='.$nl
    while $s =~ s/(.*?^[^$nl]{73} (?:
    	 [^=$nl]{2} (?! [^=$nl]{0,1} $) # 75 not followed by .?\n
    	|[^=$nl]    (?! [^=$nl]{0,2} $) # 74 not followed by .?.?\n
    	|           (?! [^=$nl]{0,3} $) # 73 not followed by .?.?.?\n
    ))//xsm;
  ($brokenlines.$s, 'quoted-printable');
}


## Original: MIME::QuotedPrint Revision: 2.3 1997/12/02 10:24:27
##           by Gisle Aas
sub decode_qp ($$) {
  my $yourself = shift;
  my $s = shift;
  $s =~ s/[\x09\x20]+(\x0D?\x0A)/$1/g;  # rule #3 (trailing space must be deleted)
  $s =~ s/[\x09\x20]+$//g;
  $s =~ s/=\x0D?\x0A//g;            # rule #5 (soft line breaks)
  $s =~ s/=([0-9A-Fa-f][0-9A-Fa-f])/pack('C', hex($1))/ge;
  	## Strictly, smallcases are not allowed
  ($s, 'binary');
}


sub uuencode ($$;%) {
  my $yourself = shift;
  my $s = shift;  my %p = @_;
  my %option = (mode => 644,	## mode as (if:-)) decimal number
                filename => '', preamble => '', postamble => '',
                newline => "\x0D\x0A");
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  
  my $r = '';
  if (length $option{preamble}) {
    $option{preamble} .= $option{newline}
      unless $option{preamble} =~ /$option{newline}$/s;
    $r .= $option{preamble} . $option{newline};
  }
  $option{filename} = 'encoded-data' unless length $option{filename};
  $r .= sprintf 'begin %03d %s%s', @option{'mode', 'filename', 'newline'};
  my $u = pack 'u', $s;
  $u =~ s/\x0D?\x0A/$option{newline}/g;
  $r .= $u;
  $r .= 'end' . $option{newline};
  if (length $option{postamble}) {
    $option{postamble} .= $option{newline}
      unless $option{postamble} =~ /$option{newline}$/s;
    $r .= $option{newline} . $option{postamble};
  }
  ($r, 'x-uuencode');
}

sub uudecode ($$) {
  my $yourself = shift;
  my $s = shift;
  my @s = split /\x0D?\x0A/, $s;
  
  ## Taken from MIME::Decoder::UU by Eryq (<eryq@zeegee.com>), 
  ## Revision: 5.403 / Date: 2000/11/04 19:54:49
  my ($mode, $filename, @preamble) = (0, '');
  while (defined ($_ = shift (@s))) {
    if (/^begin(.*)/) {        ### found it: now decode it...
      my $modefile = $1;
      if ($modefile =~ /^(?:\s+(\d+))?(?:\s+(.*?\S))?\s*\Z/) {
        ($mode, $filename) = ($1, $2);
      }
      last;                  ### decoded or not, we're done
    }
    push @preamble, $_;
  }
  if (!defined ($_)) {      # hit eof!
    Carp::carp "uu decode: No begin found";
    return ($s, 'x-uuencode');
  }
  
  ### Decode:
  my $r = '';
  while (defined ($_ = shift (@s))) {
    last if /^end/;
    next if /[a-z]/;
    next unless int((((ord() - 32) & 077) + 2) / 3) == int(length() / 4);
    $r .= (unpack('u', $_));
  }
  return ($r, 'binary', -filename => $filename, -mode => $mode,
                        -preamble => join ("\x0D\x0A", @preamble),
                        -postamble => join ("\x0D\x0A", @s));
}

sub uncompress_gzip ($$) {
  my $yourself = shift;
  my ($s) = @_;
  if (eval {require Compress::Zlib}) {
    ## Taken from Namazu <http://www.namazu.org/>, filter/gzip.pl
    my $flags = unpack('C', substr($s, 3, 1));
    $s = substr($s, 10);
    $s = substr($s, 2)  if ($flags & 0x04);
    $s =~ s/^[^\0]*\0// if ($flags & 0x08);
    $s =~ s/^[^\0]*\0// if ($flags & 0x10);
    $s = substr($s, 2)  if ($flags & 0x02);
    
    my $zl = Compress::Zlib::inflateInit
      (-WindowBits => - Compress::Zlib::MAX_WBITS());
    my ($inf, $stat) = $zl->inflate ($s);
    if ($stat == Compress::Zlib::Z_OK() || $stat == Compress::Zlib::Z_STREAM_END()) {
      return ($inf, 'identity');
    } else {
      Carp::carp 'uncompress_gzip: Bad compressed data';
    }
  } else {
    Carp::carp "gzip64 decode: $@";
  }
  ($_[1], 'gzip');	## failue
}

=head1 SEE ALSO

For charset ENCODINGs, see Message::MIME::Charset.

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
$Date: 2002/07/02 06:36:26 $

=cut

1;
