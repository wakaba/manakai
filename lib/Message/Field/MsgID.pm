
=head1 NAME

Message::Field::MsgID --- Perl module for Message-ID
of Internet messages

=head1 DESCRIPTION

This module supports C<msg-id> defined by RFC 2822.
Message-ID generating algorithm suggested by
draft-ietf-usefor-msg-id-alt-00 is also supported.

=cut

package Message::Field::MsgID;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

use overload '""' => sub { $_[0]->stringify },
             fallback => 1;

*REG = \%Message::Util::REG;
## Inherited: comment, quoted_string, domain_literal
	## WSP, FWS, phrase, NON_atom
	## msg_id
	## M_quoted_string

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -encoding_after_encode	=> 'unknown-8bit',
    -encoding_before_decode	=> 'unknown-8bit',
    #field_param_name
    #field_name
    #format
    -hash_name	=> '%none',
    #hook_encode_string
    #hook_decode_string
    -software_name	=> 'MFMpm',
    -software_name_hash	=> '%none',
    -validate	=> 0,
  );
  $self->SUPER::_init (%DEFAULT, %options);
}

=item $m = Message::Field::MsgID->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

sub new ($;%) {
  my $self = shift->SUPER::new (@_);
  my %option = @_;
  if ($option{id_left} && $option{id_right}) {
    $self->{id_left} = $option{id_left};
    $self->{id_right} = $option{id_right};
  } elsif ($option{addr_spec}
    || (($option{fqdn} || $option{ip_address} || $option{uucp})
        && ($option{login}))) {
    $self->_newid (\%option);
  }
  $self;
}

sub parse ($;$%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;  my @c;
  $self->_init (@_);
  ($body, @c) = $self->Message::Util::delete_comment_to_array ($body);
  
  $body = Message::Util::remove_wsp ($body);
  if ($body =~ /$REG{M_addr_spec}/) {
  ## BUG: <foo . bar@foo.example> is treated as <"foo . bar"@foo.example>
    my %s = &{$self->{option}->{hook_decode_string}} ($self,
              Message::Util::unquote_quoted_string ($1), type => 'quoted-string');
    $self->{id_left} = $s{value};
  ## Should we use Message::Field::Domain?
  ## BUG: <foo@foo . example> will broken... (M_addr_spec should be fixed)
    $self->{id_right} = $2;
  }
  
  $self;
}

sub _newid ($\%) {
  my $self = shift;
  my $o = shift;
  $$o{addr_spec} = Message::Util::remove_wsp ($$o{addr_spec});
  if ($$o{addr_spec} =~ /$REG{M_addr_spec}/) {
    $$o{login} = $1; $$o{fqdn} = $2;
  }
  if ($self->{option}->{validate} && $$o{fqdn} =~ 
     /[.@](example\.(?:com|org|net)|localdomain|localhost|example|invalid|test|arpa)$/) {
      Carp::croak "Msg-ID generation: invalid TLD of FQDN: .$1";
  }
  if (!$$o{fqdn} && $$o{ip_address}) {
    if ($self->{option}->{validate}
      && $$o{ip_address}=~/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/){
      my ($c1, $c2, $c3, $c4) = ($1, $2, $3, $4);
      Carp::croak "Msg-ID generation: invalid IPv4 address: $c1.$c2.$c3.$c4"
        ## See [IANAREG] and draft-iana-special-ipv4
           if ($c1 == 0)	## "this" network
           || ($c1 == 10)	## private [RFC1918]
           || ($c1 == 127)	## loopback
           || ($c1 == 169 && $c2 == 254)	## "link local"
           || ($c1 == 172 && 16 <= $c2 && $c2 < 32)	## private [RFC1918]
           || ($c1 == 192 && (($c2 == 0 && $c3 == 2)	## "TEST-NET"
           || ($c2 == 88 && $c3 == 99)	## 6to4 anycast [RFC3068]
           || ($c2 == 168)))	## private [RFC1918]
           || ($c1 == 198 && ($c2 == 18 || $c2 == 19))	## benchmark [RFC2544]
           || ($c1 >= 224);	## class D,E [RFC3171]
    }
    $$o{fqdn} ||= '['.$$o{ip_address}.']';
  }
  if (!$$o{fqdn} && $$o{uucp}) {
    $$o{uucp} .= '.uucp' if $self->{option}->{validate} && $$o{uucp} !~ /\.uucp/i;
    $$o{fqdn} = $$o{uucp};
  }
  Carp::croak "Msg-ID generation: no FQDN"
    if $self->{option}->{validate} && !$$o{fqdn};
  
  $self->{id_right} = $$o{fqdn};
  
  Carp::croak "Msg-ID generation: no 'login'"
    if $self->{option}->{validate} && !$$o{login};
  $$o{login} = $self->_hash ($$o{login}, $self->{option}->{hash_name});
  
  my @s = ('0'..'9','a'..'z','-','=','_');
  my @t = ('0'..'9','a'..'z');
  my $unique = $t[rand @t].$s[rand @s].$s[rand @s].$s[rand @s].'.';
  $unique .= join ('.', $self->_base39 (time), $self->_base39 ($$), 
    $self->_hash ($self->{option}->{software_name},
                  $self->{option}->{software_name_hash}));
  $self->{id_left} = $unique
    .'%'.($self->{option}->{hash_name} ne '%none'? 
            $self->_hash ($self->{option}->{hash_name}, '%none') .'%': '')
    .$$o{login}
    .($$o{subject_changed}? '-_-': '');
  
  $self;
}

sub _hash ($$;$$) {
  my $self = shift;
  my ($str, $hash_name, $add_unsafe) = (shift, lc shift, shift);
  $add_unsafe ||= qr#[/.=\x09\x20]#;
  undef $hash_name if $hash_name eq '%none';
  if ($hash_name eq 'md5') {
    eval {require Digest::MD5} or Carp::croak "Msg-ID generation: $@";
    $str = Digest::MD5::md5_base64 ($str);
  } elsif ($hash_name eq 'sha1') {
    eval {require Digest::SHA1} or Carp::croak "Msg-ID generation: $@";
    $str = Digest::SHA1::sha1_base64 ($str);
  } elsif ($hash_name eq 'md2') {
    eval {require Digest::MD2} or Carp::croak "Msg-ID generation: $@";
    $str = Digest::MD2::md2_base64 ($str);
  } elsif ($hash_name eq 'crypt') {
    my @s = ('0'..'9','A'..'Z','a'..'z');
    my $salt = crypt('foobar', '$1$ab$') eq '$1$ab$uAP8qWqcFs3q.Gfl5PkL2.'?
      '$1$'.join('', map($s[rand @s], 1..8)).'$': $s[rand @s].$s[rand @s];
    $str = crypt ($str, $salt);
  }
  $str =~ s#($add_unsafe)#sprintf('=%02X', ord($1))#ge;
  $str =~ s/($REG{NON_atext_dot})/sprintf('=%02X', ord($1))/ge;
  $str;
}

sub _base39 ($$) {
  my $self = shift;
  my $number = shift;
  my @digit = ('0'..'9','a'..'z','-','=','_');
  my $ret = '';
  
  my ($rem);
  while ($number > 0) {
    $rem = $number % @digit;
    $ret = $digit[ $rem ].$ret;
    $number = ($number - $rem) / @digit;
  }
  $ret;
}

sub generate ($%) {
  my $self = shift;
  my %parameter = @_;
  for (grep {/^-/} keys %parameter) {$parameter{substr ($_, 1)} = $parameter{$_}}
  $self->_newid (\%parameter);
}

sub id_left ($) {
  my $self = shift;
  my %e = &{$self->{option}->{hook_encode_string}} ($self,
    $self->{id_left}, type => 'local-part');
  Message::Util::quote_unsafe_string ($e{value}, 
    unsafe_regex => qr/$REG{NON_atext_dot}|^\.|\.$/);
}
sub id_right ($) {
  my $self = shift;
  #my %e = &{$self->{option}->{hook_encode_string}} ($self,
  #  $self->{id_right}, type => 'domain');
  #Message::Util::quote_unsafe_domain ($e{value});
  Message::Util::quote_unsafe_domain ($self->{id_right});
}
sub content ($) {
  my $self = shift;
  my ($l, $r) = ($self->id_left, $self->id_right);
  sprintf '%s@%s', $l, $r if $l && $r;
}
*id = \&content;

sub stringify ($;%) {
  my $self = shift;
  my ($l, $r) = ($self->id_left, $self->id_right);
  sprintf '<%s@%s>', $l, $r if $l && $r;
}
*as_string = \&stringify;

=head1 EXAMPLE

  use Message::Field::MsgID;
  my $from = 'foo@bar.example';
  my $login = 'my-login-name';
  my $domain = 'foo.bar.example';
  my $ipv4 = '192.168.0.1';
  my %mid;
  $mid{no_crypt} = new Message::Field::MsgID 
    addr_spec => $from, -validate => 0;
  $mid{md5} = new Message::Field::MsgID
    login => $login, ip_address => $ipv4,
    -hash_name => 'md5', -validate => 0;
  $mid{sha1} = new Message::Field::MsgID
    login => $login, fqdn => $domain, subject_changed => 1,
    -hash_name => 'sha1', -validate => 0;
  for (keys %mid) {
    print $_, ":\t", $mid{$_}, "\n";
  }
  # sha1:   <t-9.bbxkfu.xsem.MFMMpm%sha1%9pnH2R6iN8KSIMby+dPU0i3M8RU-_-@foo.bar.example>
  # md5:    <7fu.bbxkfu.xsem.MFMMpm%md5%eBpd+12mupwxZBc6kMWR9g@[192.168.0.1]>
  # no_crypt:       <3vy.bbxkfu.xsem.MFMMpm%foo@bar.example>
  
  ## IMPORTANT NOTE: This example uses -validate option with
  ## '0' (does not validate) value since it uses example (invalid)
  ## resource names, such as 'foo.bar.example'.  Usually, this option
  ## shall not be used (and default value = '1' = does validate
  ## should be used).

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
$Date: 2002/07/13 09:27:35 $

=cut

1;
