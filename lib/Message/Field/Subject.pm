
=head1 NAME

Message::Field::Subject Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<Subject> C<field>.

=cut

package Message::Field::Subject;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;

use overload '""' => sub {shift->stringify};
$REG{FWS} = qr/[\x09\x20]*/;
$REG{re} = qr/(?:[Rr][Ee]|[Ss][Vv])\^?\[?[0-9]*\]?:/;
$REG{fwd} = qr/[Ff][Ww][Dd]?:/;
$REG{ml} = qr/[(\[][A-Za-z0-9._-]+[\x20:-][0-9]+[)\]]/;
$REG{M_ml} = qr/[(\[]([A-Za-z0-9._-]+)[\x20:-]([0-9]+)[)\]]/;
$REG{prefix} = qr/(?:$REG{re}|$REG{fwd}|$REG{ml})(?:$REG{FWS}(?:$REG{re}|$REG{fwd}|$REG{ml}))*/;
$REG{M_control} = qr/^cmsg$REG{FWS}([\x00-\xFF]*)$/;
$REG{M_was} = qr/\([Ww][Aa][Ss]:? ([\x00-\xFF]+)\)$REG{FWS}$/;

%DEFAULT = (
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
  string_re	=> 'Re: ',
  string_was	=> ' (was: %s)',
);

=head2 Message::Field::Subject->new ()

Returns empty subject object.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Field::Subject->parse ($unfolded_field_body)

Parses subject C<field-body>.  Even C<Subject> is unstructured
field body, "Re: " prefix or mail-list name and number
are widely used.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $field_body = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  if ($field_body =~ /$REG{M_control}/) {
    $self->{control} = $1;
    return $self;
  }
  my %s = &{$self->{option}->{hook_decode_string}} ($self, $field_body,
            type => 'text');
  $field_body = $s{value};
  $field_body =~ s{^$REG{FWS}($REG{prefix})$REG{FWS}}{
    my $prefix = $1;
    $self->{is_reply} = 1 if $prefix =~ /$REG{re}/;
    $self->{is_foward} = 1 if $prefix =~ /$REG{fwd}/;
    if ($prefix =~ /$REG{M_ml}/) {
      ($self->{ml_name}, $self->{ml_count}) = ($1, $2);
    }
    ''
  }ex;
  $field_body =~ s{$REG{FWS}$REG{M_was}}{
    $self->{was} = Message::Field::Subject->parse ($1);
    ''
  }ex;
  $self->{field_body} = $field_body;
  $self;
}

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{string_re} ||= $self->{option}->{string_re};
  $option{string_was} ||= $self->{option}->{string_was};
  my (%e) = &{$self->{option}->{hook_encode_string}} ($self, 
          $self->{field_body}, type => 'text');
  ($self->{is_reply}>0? $option{string_re}: '').$e{value}
  .(length $self->{was}? sprintf ($option{string_was}, $self->{was}): '');
}
sub as_string ($;%) {shift->stringify (@_)}

sub as_plain_string ($;%) {
  my $self = shift;
  my %option = @_;
  $option{string_re} ||= $self->{option}->{string_re};
  $option{string_was} ||= $self->{option}->{string_was};
  ($self->{is_reply}>0? $option{string_re}: '').$self->{field_body}
  .(length $self->{was}? 
    sprintf ($option{string_was}, $self->{was}->as_plain_string): '');
}

sub is ($$;$) {
  my $self = shift;
  my $valname = shift;
  my $newval = shift;
  if (defined $newval) {
    $self->{'is_'.$valname} = $newval;
  }
  $self->{'is_'.$valname};
}

sub option ($$;$) {
  my $self = shift;
  my $valname = shift;
  my $newval = shift;
  if (defined $newval) {
    $self->{option}->{$valname} = $newval;
  }
  $self->{option}->{$valname};
}

sub was ($) {
  my $self = shift;
  if (ref $self->{was}) {
    #
  } elsif ($self->{was}) {
    $self->{was} = Message::Field::Subject->parse ($self->{was});
  } else {
    $self->{was} = new Message::Field::Subject;
  }
  $self->{was};
}

sub set ($$) {
  my $self = shift;
  my $new_string = shift;
  $self->{field_body} = $new_string;
  $self;
}

sub set_new ($$) {
  my $self = shift;
  my $new_string = shift;
  $self->was->{field_body} = $self->{field_body};
  $self->{was}->{is_reply} = $self->{is_reply};
  $self->{was}->{option}   = {%{$self->{option}}};
  $self->{field_body} = $new_string;
  $self->{is_reply} = -1;
  $self;
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

=cut

1;
