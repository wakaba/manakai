
=head1 NAME

Message::Field::UA Perl module

=head1 DESCRIPTION

Perl module for C<User-Agent:> field-body.

=cut

package Message::Field::UA;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::MIME::EncodedWord;

use overload '""' => sub {shift->stringify},
             '@{}' => sub {shift->product};

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{http_token} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]+/;
$REG{product} = qr#(?:$REG{http_token}|$REG{quoted_string})(?:$REG{FWS}/$REG{FWS}(?:$REG{http_token}|$REG{quoted_string}))?#;
$REG{S_encoded_word_comment} = qr/=\x3F[\x21-\x27\x2A-\x5B\x5D-\x7E]+\x3F=/;

$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*)\x29/;
$REG{M_product} = qr#($REG{http_token}|$REG{quoted_string})(?:$REG{FWS}/$REG{FWS}($REG{http_token}|$REG{quoted_string}))?#;

$REG{NON_http_token} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
$REG{NON_http_token_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;

%DEFAULT = (
  add_prepend	=> 1,
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
);

=head2 Message::Field::UA->new ()

Return empty Message::Field::UA object.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Field::UA->parse ($unfolded_field_body)

Parse UA: styled C<field-body>.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  my $field_body = shift;  my @ua = ();
  $field_body =~ s{^((?:$REG{FWS}$REG{comment})+)}{
    my $comments = $1;
    $comments =~ s{$REG{M_comment}}{
      my $comment = $self->_decode_ccontent ($1);
      push @ua, {comment => [$comment]} if $comment;
    }goex;
    '';
  }goex;
  $field_body =~ s{$REG{M_product}((?:$REG{FWS}$REG{comment})*)}{
    my ($product, $product_version, $comments) = ($1, $2, $3);
    for ($product, $product_version) {
      my ($s,$q) = ($self->_unquote_if_quoted_string ($_), 0);
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $s,
                type => ($q?'token/quoted':'token'));	## What token/quoted is? :-)
      $_ = $s{value};
    }
    my @comment = ();
    $comments =~ s{$REG{M_comment}}{
      my $comment = $self->_decode_ccontent ($1);
      push @comment, $comment if $comment;
    }goex;
    push @ua, {product => $product, product_version => $product_version, 
               comment => \@comment};
  }goex;
  $self->{product} = \@ua;
  $self;
}

=head2 $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{format} ||= $self->{option}->{format};
  my @r = ();
  for my $p (@{$self->{product}}) {
    if ($p->{product}) {
      if ($option{format} eq 'http'
        && (  $p->{product} =~ /$REG{NON_http_token}/
           || $p->{product_version} =~ /$REG{NON_http_token}/)) {
        my %f = (value => $p->{product});
        $f{value} .= '/'.$p->{product_version} if $p->{product_version};
        %f = &{$self->{option}->{hook_encode_string}} ($self, 
          $f{value}, type => 'ccontent');
        $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
        push @r, '('.$f{value}.')';
      } else {
        my %e = &{$self->{option}->{hook_encode_string}} ($self, 
           $p->{product}, type => 'token');
        my %f = &{$self->{option}->{hook_encode_string}} ($self, 
           $p->{product_version}, type => 'token');
        push @r, $self->_quote_unsafe_string ($e{value}, unsafe => 'NON_http_token')
          .($f{value}?'/'
           .$self->_quote_unsafe_string ($f{value}, unsafe => 'NON_http_token')
           :'');
      }
    } elsif ($p->{product_version}) {	## Error!
      my %f = &{$self->{option}->{hook_encode_string}} ($self, 
         $p->{product_version}, type => 'ccontent');
      $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
      push @r, '('.$f{value}.')';
    }
    for (@{$p->{comment}}) {
      my %f = &{$self->{option}->{hook_encode_string}} ($self, 
         $_, type => 'ccontent');
      $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
      push @r, '('.$f{value}.')' if $f{value};
    }
  }
  join ' ', @r;
}

sub product ($;%) {
  my $self = shift;
  $self->_delete_empty;
  @{$self->{product}};
}

sub product_name ($;$%) {
  my $self = shift;
  my $index = shift;
  $self->{product}->[$index]->{product} if ref $self->{product}->[$index];
}

sub product_version ($;$%) {
  my $self = shift;
  my $index = shift;
  $self->{product}->[$index]->{product_version} if ref $self->{product}->[$index];
}

sub product_comment ($;$%) {
  my $self = shift;
  my $index = shift;
  if (ref $self->{product}->[$index]) {
    wantarray?
      @{$self->{product}->[$index]->{comment}}:
      $self->{product}->[$index]->{comment}->[0];
  }
}

sub add ($;%) {
  my $self = shift;
  my %option = @_;
  my %a = (product => $option{name}, product_version => $option{version},
           comment => $option{comment});
  if ($option{prepend}||$self->{option}->{add_prepend}>0) {
    unshift @{$self->{product}}, \%a;
  } else {
    push @{$self->{product}}, \%a;
  }
  \%a;
}

sub replace ($;%) {
  my $self = shift;
  my %option = @_;
  my %a = (product => $option{name}, product_version => $option{version},
           comment => $option{comment});
  if ($a{product}) {
    for my $p (@{$self->{product}}) {
      if ($p->{product} eq $a{product}) {
        $p = \%a;
        return $p;
      }
    }
  }
  if (($option{add_prepend}||$self->{option}->{add_prepend})>0) {
    unshift @{$self->{product}}, \%a;
  } else {
    push @{$self->{product}}, \%a;
  }
  \%a;
}

sub _delete_empty ($) {
  my $self = shift;
  my @nid;
  for my $id (@{$self->{product}}) {push @nid, $id if ref $id}
  $self->{product} = \@nid;
}

sub _quote_unsafe_string ($$;%) {
  my $self = shift;
  my $string = shift;
  my %option = @_;
  $option{unsafe} ||= 'NON_atext_dot';
  if ($string =~ /$REG{$option{unsafe}}/ || $string =~ /$REG{WSP}$REG{WSP}+/) {
    $string =~ s/([\x22\x5C])([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
    $string = '"'.$string.'"';
  }
  $string;
}

## Unquote C<DQOUTE> and C<quoted-pair> if it is itself a
## C<quoted-string>.  (Do nothing if it is MULTIPLE
## C<quoted-string>"S".)
sub _unquote_if_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;  my $isq = 0;
  $quoted_string =~ s{^$REG{M_quoted_string}$}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $isq = 1;
    $qtext;
  }goex;
  wantarray? ($quoted_string, $isq): $quoted_string;
}

sub _decode_ccontent ($$) {
  &Message::MIME::EncodedWord::decode_ccontent (@_[1,0]);
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

=cut

1;
