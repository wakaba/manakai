
=head1 NAME

Message::Body::Text --- Perl Module for Internet Media Types "text/*"

=cut

package Message::Body::Text;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
require Message::Header;
require Message::MIME::Charset;
use overload '""' => sub { $_[0]->stringify },
             fallback => 1;
%REG = %Message::Util::REG;

%DEFAULT = (
  -_METHODS	=> [qw|value|],
  -_MEMBERS	=> [qw|_charset|],
  	## header -- Don't clone
  -default_charset	=> 'us-ascii',
  -hook_encode_string	=> \&Message::Util::encode_body_string,
  -hook_decode_string	=> \&Message::Util::decode_body_string,
  -media_type	=> 'text',
  -media_subtype	=> 'plain',
  -parse_all	=> 0,
  -use_normalization	=> 0,
  -use_param_charset	=> 0,
);

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Structured> objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  my %option = @_;
  $self->SUPER::_init (%$DEFAULT, %option);
  
  if (ref $option{entity_header}) {
    $self->{header} = $option{entity_header};
  }
  my $mt = $self->{option}->{media_type};
  my $mst = $self->{option}->{media_subtype};
  my $mt_def = $Message::MIME::MediaType::type{$mt}->{$mst};
  $mt_def = $Message::MIME::MediaType::type{$mt}->{'/default'} unless ref $mt_def;
  $mt_def = $Message::MIME::MediaType::type{'/default'}->{'/default'}
    unless ref $mt_def;
    if ($self->{option}->{format} =~ /http/) {
      $self->{option}->{use_normalization} = 0;
    } else {
      $self->{option}->{use_normalization} = 1;
    }
  if ($mt_def->{mime_charset}) {
    $self->{option}->{use_param_charset} = 1;
    if ($self->{option}->{format} =~ /http/) {
      $self->{option}->{default_charset} = 'iso-8859-1';
    } else {
      $self->{option}->{default_charset} = 'us-ascii';
    }
  }
  if ($mt_def->{default_charset}) {
    $self->{option}->{default_charset} = $mt_def->{default_charset};
  }
}

=item $body = Message::Body::TextPlain->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $body = Message::Body::TextPlain->parse ($body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  $self->_parse ($body);
  $self;
}

sub _parse ($$) {
  my $self = shift;
  my $body = shift;
  my $charset;
  my $ct; $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0) 
    if ref $self->{header};
  $charset = $ct->parameter ('charset') if ref $ct;
  $charset ||= $self->{option}->{default_charset};
  my %s = &{$self->{option}->{hook_decode_string}} ($self, $body,
    type => 'body', charset => $charset);
  $self->{value} = $s{value};
  $self->{_charset} = $s{charset};	## When convertion failed
}

=back

=cut

=item $body->header ([$new_header])


=cut

sub entity_header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  #} elsif ($new_header) {
  #  $self->{header} = Message::Header->parse ($new_header);
  }
  #unless ($self->{header}) {
  #  $self->{header} = new Message::Header;
  #}
  $self->{header};
}

=item $body->value ([$new_body])

Returns C<body> as string unless $new_body.
Set $new_body instead of current C<body>.

=cut

sub value ($;$) {
  my $self = shift;
  my $new_body = shift;
  if ($new_body) {
    $self->{value} = $new_body;
  }
  $self->{value};
}

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $v = $self->_prep_stringify ($self->{value}, \%option);
  my $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0)
    if ref $self->{header};
  unless ($option{use_param_charset}) {
    if ($option{use_normalization}) {
        $v =~ s/\x0D(?!\x0A)/\x0D\x0A/gs;
        $v =~ s/(?<!\x0D)\x0A/\x0D\x0A/gs;
        #$v .= "\x0D\x0A" unless $v =~ /\x0D\x0A$/s;
    }
    return $v;
  }
  my %e;
  unless ($self->{_charset}) {
    my $charset; $charset = $ct->parameter ('charset') if ref $ct;
    $charset ||= $option{default_charset};
    (%e) = &{$option{hook_encode_string}} ($self, $v,
      type => 'body', charset => $charset);
    ## Normalize
    if ($option{use_normalization}) {
      if ($Message::MIME::Charset::CHARSET{$charset || '*default'}->{mime_text}) {
        $e{value} =~ s/\x0D(?!\x0A)/\x0D\x0A/gs;
        $e{value} =~ s/(?<!\x0D)\x0A/\x0D\x0A/gs;
        #$e{value} .= "\x0D\x0A" unless $e{value} =~ /\x0D\x0A$/s;
      }
    }
  } else {	## if $self->{_charset},
    %e = (value => $v, charset => $self->{_charset});
  }
  if (ref $self->{header}) {
    unless (ref $ct) {
      $ct = $self->{header}->field ('content-type');
      $ct->value ($option{parent_type});
    }
    $ct->replace (charset => ($e{charset} || $option{default_charset}));
  }
  $e{value};
}
*as_string = \&stringify;

## $self->_prep_stringify ($value, \%option)
sub _prep_stringify ($$\%) {
  my $self = shift;
  shift;
}

## Inherited: option, clone

=head1 SEE ALSO

RFC 822 <urn:ietf:rfc:822>,
RFC 2046 <urn:ietf:rfc:2046>, RFC 2646 <urn:ietf:rfc:2646>.

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
$Date: 2002/06/16 10:44:08 $

=cut

1;
