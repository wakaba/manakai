
=head1 NAME

Message::Field::MsgID::MsgID Perl module

=head1 DESCRIPTION

Perl module for C<msg-id> defined by RFC 2822.
Message-ID generating algorithm suggested by
draft-ietf-usefor-msg-id-alt-00 is supported.

=cut

package Message::Field::MsgID::MsgID;
use strict;
use vars qw(%REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Carp;
use overload '""' => sub {shift->stringify};
use autouse Digest::MD2 => qw(md2_hex md2_base64);
use autouse Digest::MD5 => qw(md5_hex md5_base64);
use autouse Digest::SHA1 => qw(sha1_hex sha1_base64);

$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{dot_atom} = qr/$REG{atext}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext})*/;
$REG{dot_word} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext}|$REG{quoted_string}))*/;
$REG{phrase} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{atext}|$REG{quoted_string}|\.|$REG{FWS})*/;
$REG{addr_spec} = qr/$REG{dot_word}$REG{FWS}\x40$REG{FWS}(?:$REG{dot_atom}|$REG{domain_literal})/;
$REG{msg_id} = qr/<$REG{FWS}$REG{addr_spec}$REG{FWS}>/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_domain_literal} = qr/\x5B((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*)\x5D/;
$REG{M_addr_spec} = qr/($REG{dot_word})$REG{FWS}\x40$REG{FWS}($REG{dot_atom}|$REG{domain_literal})/;

$REG{NON_atom} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E\x2E]/;

my %DEFAULT = (
  check	=> 1,
  hash_name	=> '_none',
  software_name	=> 'MFMMpm',
  software_name_hash	=> '_none',
);


sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  my $o = $self->{option};
  for (keys %DEFAULT) {$$o{$_} ||= $DEFAULT{$_}}
  $$o{addr_spec} = $self->_get_rid_of_fws ($$o{addr_spec});
  if ($$o{addr_spec} =~ /$REG{M_addr_spec}/) {
    $$o{login} = $1; $$o{fqdn} = $2;
  }
  if ($$o{check}>0 
   && $$o{fqdn} =~ 
     /[.@](example\.(?:com|org|net)|localdomain|localhost|example|invalid)$/) {
      croak "new: invalid TLD of FQDN: .$1";
  }
  if (!$$o{fqdn} && $$o{ip_address}) {
    if ($$o{check}>0 && $$o{ip_address}=~/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/){
      my ($c1, $c2, $c3, $c4) = ($1, $2, $3, $4);
      croak "new: invalid IPv4 address: $c1.$c2.$c3.$c4" if ($c1 == 10)
           || ($c1 == 172 && 16 <= $c2 && $c2 < 32) 
           || ($c1 == 192 && $c2 == 168) || ($c1 >= 224);
    }
    $$o{fqdn} ||= '['.$$o{ip_address}.']';
  }
  if (!$$o{fqdn} && $$o{uucp}) {
    $$o{uucp} .= '.uucp' if $$o{check}>0 && $$o{uucp} !~ /\.uucp/i;
    $$o{fqdn} = $$o{uucp};
  }
  croak "new: no FQDN" if $$o{check}>0 && !$$o{fqdn};
  
  $self->{id_right} = $$o{fqdn};
  
  croak "no 'login'" if $$o{check}>0 && !$$o{login};
  $$o{hash_name} ||= $DEFAULT{hash_name};
  $$o{login} = $self->_hash ($$o{login}, $$o{hash_name});
  
  $$o{software_name} ||= $DEFAULT{software_name};
  $$o{software_name_hash} ||= $DEFAULT{software_name_hash};
  my $unique = join ('.', $self->_base39 (time), $self->_base39 ($$), 
    $self->_hash ($$o{software_name}, $$o{software_name_hash}));
  
  $self->{id_left} = $unique
    .'%'.($$o{hash_name} ne '_none'? $self->_hash ($$o{hash_name}, '_none')
         .'%': '')
    .$$o{login};
  
  $self;
}

sub _hash ($$;$$) {
  my $self = shift;
  my ($str, $hash_name, $add_unsafe) = (shift, lc shift, shift);
  $add_unsafe ||= qr#[/.=\x09\x20]#;
  undef $hash_name if $hash_name eq '_none';
  if ($hash_name eq 'md5') {
    $str = md5_hex ($str);
  } elsif ($hash_name eq 'md5_64') {
    $str = md5_base64 ($str);
  } elsif ($hash_name eq 'sha1') {
    $str = sha1_hex ($str);
  } elsif ($hash_name eq 'sha1_64') {
    $str = sha1_base64 ($str);
  } elsif ($hash_name eq 'md2') {
    $str = md2_hex ($str);
  } elsif ($hash_name eq 'md2_base64') {
    $str = md2_base64 ($str);
  } elsif ($hash_name eq 'crypt') {
    my @s = ('0'..'9','A'..'Z','a'..'z');
    my $salt = crypt('foobar', '$1$ab$') eq '$1$ab$uAP8qWqcFs3q.Gfl5PkL2.'?
      '$1$'.join('', map($s[rand @s], 1..8)).'$': $s[rand @s].$s[rand @s];
    $str = crypt ($str, $salt);
  }
  $str =~ s#($add_unsafe)#sprintf('=%02X', ord($1))#ge;
  $str =~ s/($REG{NON_atom})/sprintf('=%02X', ord($1))/ge;
  $str;
}

sub _base39 ($$) {
  my $self = shift;
  my $number = shift;
  my @digit = ('0'..'9','a'..'z','-','=','_');
  my $ret = '';
  
  my ($rem);
  while ($number > 0) {
    $rem = $number % 36;
    $ret = $digit[$rem].$ret;
    $number = ($number - $rem) / 36;
  }
  $ret;
}

sub parse ($;$%) {
  my $class = shift;  my $msgid = shift;
  my $self = bless {option => {@_}}, $class;
  my $o = $self->{option};
  for (keys %DEFAULT) {$$o{$_} ||= $DEFAULT{$_}}
  
  $msgid = $self->_get_rid_of_fws ($msgid);
  if ($msgid =~ /$REG{M_addr_spec}/) {
    $self->{id_left} = $1; $self->{id_right} = $2;
    ## BUG: Can't preserve dot-word (RFC 2822 obs- syntax) 
    ## in id-left correctly.  (How can we do??)
    if ($self->{id_left} =~ /^$REG{M_quoted_string}$/) {
      $self->{id_left} = $1;
      $self->{id_left} =~ s/\\([\x00-\xFF])/$1/g;
    }
    if ($self->{id_right} =~ /^$REG{M_domain_literal}$/) {
      $self->{id_right} = $1;
      $self->{id_right} =~ s/\\([\x00-\xFF])/$1/g;
    }
  }
  
  $self;
}

sub id_left ($) {my $self = shift; $self->_quote_unsafe_string ($self->{id_left})}
sub id_right ($) {my $self=shift;$self->_enliteral_unsafe_string ($self->{id_right})}
sub content ($) {
  my $self = shift;
  sprintf '%s@%s', $self->_quote_unsafe_string ($self->{id_left}), 
                   $self->_enliteral_unsafe_string ($self->{id_right});
}

sub stringify ($;%) {
  my $self = shift;
  sprintf '<%s@%s>', $self->_quote_unsafe_string ($self->{id_left}), 
                     $self->_enliteral_unsafe_string ($self->{id_right});
}
sub as_string ($;%) {shift->stringify (@_)}

sub _quote_unsafe_string ($$) {
  my $self = shift;
  my $string = shift;
  if ($string =~ /$REG{NON_atom}/ || $string =~ /$REG{WSP}/) {
    $string =~ s/([\x22\x5C])/\x5C$1/g;
    $string = '"'.$string.'"';
  }
  $string;
}

sub _enliteral_unsafe_string ($$) {
  my $self = shift;
  my $string = shift;
  if ($string =~ /^\[[^\[\]]+\]$/) {
    #
  } elsif ($string =~ /$REG{NON_atom}/ || $string =~ /$REG{WSP}/) {
    $string =~ s/([\x5B-\x5D])/\x5C$1/g;
    $string = '['.$string.']';
  }
  $string;
}

sub _get_rid_of_fws ($$) {
  my $self = shift; my $s = shift;
  $s =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{WSP}+}{
    $1
  }goex;
  $s;
}

=head1 EXAMPLE

  ## This example DOES NOT work because of *.example pseudo TLD.
  use Message::Field::MsgID::MsgID;
  my $from = 'foo@bar.example';
  my %mid;
  $mid{no_crypt} = new Message::Field::MsgID::MsgID 
    (addr_spec => $from);
  $mid{md5_base64} = new Message::Field::MsgID::MsgID 
    (addr_spec => $from, hash_name => 'md5_base64');
  $mid{sha1_base64} = new Message::Field::MsgID::MsgID 
    (addr_spec => $from, hash_name => 'sha1_base64');

=head1 SEE ALSO

RFC 822 E<lt>urn:ietf:rfc:822E<gt>, RFC 2822 E<lt>urn:ietf:rfc:2822E<gt>

RFC 850 E<lt>urn:ietf:rfc:850E<gt>, RFC 1036 E<lt>urn:ietf:rfc:1036E<gt>,
son-of-RFC1036, draft-ietf-usefor-article-06.txt
E<lt>urn:ietf:id:draft-ietf-usefor-article-06E<gt>

draft-ietf-usefor-message-id-01.txt
E<lt>urn:ietf:id:draft-ietf-usefor-message-id-01E<gt>

draft-ietf-usefor-msg-id-alt-00.txt
E<lt>urn:ietf:id:draft-ietf-usefor-msg-id-alt-00E<gt>

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
$Date: 2002/03/21 04:18:38 $

=cut

1;
