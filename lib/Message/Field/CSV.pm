
=head1 NAME

Message::Field::CSV Perl module

=head1 DESCRIPTION

Perl module for comma separated C<field>.

This module supports a number of fields that contains
(or does not contain:-)) of comma separated values,
such as C<Keywords:>, C<Newsgroups:> and so on.

=cut

package Message::Field::CSV;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%OPTION %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload '@{}' => sub {shift->value},
             '""' => sub {shift->stringify};
require Message::Util;
$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]+|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;
$REG{uri_literal} = qr/\x3C[\x09\x20\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]*\x3E/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{dot_atom} = qr/$REG{atext}(?:$REG{FWS}\x2E$REG{FWS}$REG{atext})*/;
$REG{dot_word} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{FWS}\x2E$REG{FWS}(?:$REG{atext}|$REG{quoted_string}))*/;
$REG{phrase} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{atext}|$REG{quoted_string}|\.|$REG{FWS})*/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{NON_atom} = qr/[^\x09\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E\x2E]/;
$REG{NON_atext} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{NON_atext_dot} = qr/[^\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{NON_atext_dot_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{NON_http_token_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
$REG{NON_component} = qr/[^\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5F\x61-\x7A\x80-\xFF\x2F\x3D\x3F]/;
$REG{NON_distribution} = qr/[^\x21\x2B\x2D\x30-\x39\x41-\x5A\x5F\x61-\x7A]/;
$REG{S_encoded_word} = qr/=\x3F$REG{atext_dot}\x3F=/;

## Keywords: foo, bar, "and so on"
## Newsgroups: local.test,local.foo,local.bar
## Accept: text/html; q=1.0, text/plain; q=0.03; *; q=0.01

%OPTION = (
  field_name	=> 'keywords',
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
  is_quoted_string	=> 1,	## Can itself quoted-string?
  long_count	=> 10,
  remove_comment	=> 1,
  separator	=> ', ',
  separator_long	=> ', ',
  max	=> -1,
  value_type	=> [':none:'],
  value_unsafe_rule	=> 'NON_http_token_wsp',
);

sub _init_option ($) {
  my $self = shift;
  my %field_type = qw(accept-charset accept accept-encoding accept 
     accept-language accept
     content-language keywords
     followup-to newsgroups
     list-archive list- list-digest list- list-help list- 
     list-owner list- list-post list- list-subscribe list- 
     list-unsubscribe list- list-url list- uri list-
     x-brother x-moe x-daughter x-moe
     x-respect x-moe x-syster x-moe x-wife x-moe);
  my $field_name = lc $self->{option}->{field_name};
  $field_name = $field_type{$field_name} || $field_name;
  if ($field_name eq 'newsgroups') {
    $self->{option}->{separator} = ',';
    $self->{option}->{separator_long} = ', ';
    $self->{option}->{long_count} = 5;
    $self->{option}->{value_unsafe_rule} = 'NON_component';
    $self->{option}->{encoding_after_encode} = 'utf-8';
  } elsif ($field_name eq 'distribution') {
    $self->{option}->{separator} = ',';
    $self->{option}->{separator_long} = ', ';
    $self->{option}->{long_count} = 15;
    $self->{option}->{value_unsafe_rule} = 'NON_distribution';
  } elsif ($field_name eq 'x-moe') {
    $self->{option}->{is_quoted_string} = -1;
    $self->{option}->{value_type} = ['Message::Field::ValueParams', 
      {format => $self->{option}->{format}}];
  } elsif ($field_name eq 'accept') {
    $self->{option}->{is_quoted_string} = -1;
    $self->{option}->{value_type} = ['Message::Field::ValueParams', 
      {format => $self->{option}->{format}}];
  } elsif ($field_name eq 'list-') {
    $self->{option}->{is_quoted_string} = -1;
    $self->{option}->{remove_comment} = -1;
    $self->{option}->{value_type} = ['Message::Field::URI', 
      {field_name => $self->{option}->{field_name},
      format => $self->{option}->{format}}];
  } elsif ($field_name eq 'encrypted') {
    $self->{option}->{max} = 2;
  }
  $self;
}

=head2 Message::Field::CSV->new ()

Returns new CSV field body.

=cut

sub new ($;%) {
  my $self = bless {}, shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{option} = \%option;
  $self->_init_option ();
  $self;
}

=head2 Message::Field::CSV->parse ($unfolded_field_body)

Parses C<field-body>.

=cut

sub parse ($$;%) {
  my $self = bless {}, shift;
  my $field_body = shift;
  my %option = @_;
  for (%OPTION) {$option{$_} ||= $OPTION{$_}}
  $self->{option} = \%option;
  $self->_init_option ();
  $field_body = $self->_delete_comment ($field_body)
    unless $option{remove_comment}<0;
  @{$self->{value}} = $self->_parse_list ($field_body);
  $self;
}

sub _parse_list ($$) {
  my $self = shift;
  my $fb = shift;
  my @ids;
  $fb =~ s{((?:$REG{quoted_string}|$REG{uri_literal}|$REG{domain_literal}|$REG{comment}|[^\x22\x28\x2C\x3C\x5B])+)}{
    my $s = $1;  $s =~ s/^$REG{WSP}+//;  $s =~ s/$REG{WSP}+$//;
    if ($self->{option}->{is_quoted_string}>0) {
      push @ids, $self->_value ($self->_decode_quoted_string ($s));
    } else {
      push @ids, $self->_value ($s);
    }
  }goex;
  @ids;
}

=head2 $self->value ()

Returns array reference to value list.

=cut

sub value ($) {shift->{value}}

=head2 $self->add ($value, [%option])

Adds new value.

=cut

sub add ($;$%) {
  my $self = shift;
  my ($value, %option) = @_;
  push @{$self->{value}}, $self->_value ($value);
  $value;
}

## Hook called before returning C<value>.
## $self->_param_value ($name, $value);
sub _value ($$) {
  my $self = shift;
  my $value = shift;
  my $vtype = $self->{option}->{value_type}->[0];
  my %vopt; %vopt = %{$self->{option}->{value_type}->[1]} 
    if ref $self->{option}->{value_type}->[1];
  if (ref $value) {
    return $value;
  } elsif ($vtype eq ':none:') {
    return $value;
  } elsif ($value) {
    eval "require $vtype";
    return $vtype->parse ($value, %vopt);
  } else {
    eval "require $vtype";
    return $vtype->new (%vopt);
  }
}

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{separator} ||= $self->{option}->{separator};
  $option{separator_long} ||= $self->{option}->{separator_long};
  $option{long_count} ||= $self->{option}->{long_count};
  $option{max} ||= $self->{option}->{max};
  $option{is_quoted_string} ||= $self->{option}->{is_quoted_string};
  $option{value_unsafe_rule} ||= $self->{option}->{value_unsafe_rule};
  $self->_delete_empty ();
  $option{max}--;
  $option{max} = $#{$self->{value}} if $option{max}<0;
  $option{max} = $#{$self->{value}} if $#{$self->{value}}<$option{max};
  $option{separator} = $option{separator_long}
    if $option{max} >= $option{long_count};
  join $option{separator}, 
    map {
      if ($option{is_quoted_string}>0) {
        my %s = &{$self->{option}->{hook_encode_string}} ($self, 
          $_, type => 'phrase');
        $self->_quote_unsafe_string ($s{value}, 
          unsafe => $option{value_unsafe_rule});
      } else {
        $_;
      }
    } @{$self->{value}}[0..$option{max}];
}

=head2 $self->option ($option_name, [$option_value])

Set/gets new value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
}

sub value_type ($;$%) {
  my $self = shift;
  my $new_value_type = shift;
  if ($new_value_type) {
    $self->{option}->{value_type}->[0] = $new_value_type;
  }
  $self->{option}->{value_type}->[0] || ':none:';
}

sub _delete_empty ($) {
  my $self = shift;
  my @nid;
  for my $id (@{$self->{value}}) {push @nid, $id if length $id}
  $self->{value} = \@nid;
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


=head2 $self->_unquote_quoted_string ($string)

Unquote C<quoted-string>.  Get rid of C<DQUOTE>s and
C<REVERSED SOLIDUS> included in C<quoted-pair>.
This method is intended for internal use.

=cut

sub _unquote_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

sub _decode_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}|([^\x22]+)}{
    my ($qtext,$t) = ($1, $2);
    if ($t) {
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $t,
                type => 'phrase');
      $s{value};
    } else {
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $qtext,
                type => 'phrase/quoted');
      $s{value};
    }
  }goex;
  $quoted_string;
}

=head2 $self->_delete_comment ($field_body)

Remove all C<comment> in given strictured C<field-body>.
This method is intended to be used for internal process.

=cut

sub _delete_comment ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{uri_literal}|$REG{domain_literal})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

=head1 EXAMPLE


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
$Date: 2002/04/01 05:32:15 $

=cut

1;
