
=head1 NAME

Message::Body::TextPlain --- Perl Module for Internet Media Type "text/plain"

=cut

package Message::Body::TextPlain;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
require Message::Header;
require Message::MIME::Charset;
use overload '""' => sub { $_[0]->stringify },
             fallback => 1;

  %DEFAULT = (
    -_METHODS	=> [qw|value|],
    -_MEDIA_TYPE	=> 'text/plain',
    -_MEMBERS	=> [qw|_charset|],
    -body_default_charset	=> 'us-ascii',
    -body_default_charset_input	=> 'iso-2022-int-1',
    #encoding_after_encode
    #encoding_before_decode
    -hook_encode_string	=> \&Message::Util::encode_body_string,
    -hook_decode_string	=> \&Message::Util::decode_body_string,
    -parse_all	=> 0,
    -use_normalization	=> 1,
    -use_param_charset	=> 1,
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
  
  if (ref $option{header}) {
    $self->{header} = $option{header};
  }
  if ($self->{option}->{format} =~ /http/) {
    $self->{option}->{use_normalization} = 0;
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
  my $charset;
  my $ct; $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0) 
    if ref $self->{header};
  $charset = $ct->parameter ('charset') if ref $ct;
  $charset ||= $self->{option}->{encoding_before_decode};
  my %s = &{$self->{option}->{hook_decode_string}} ($self, $body,
    type => 'body', charset => $charset);
  $self->{value} = $s{value};
  $self->{_charset} = $s{charset};	## When convertion failed
  $self;
}

=back

=cut

=item $body->header ([$new_header])


=cut

sub header ($;$) {
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
  my $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0)
    if ref $self->{header};
  my %e;
  unless ($self->{_charset}) {
    my $charset; $charset = $ct->parameter ('charset') if ref $ct;
    $charset ||= $self->{option}->{encoding_after_encode};
    (%e) = &{$self->{option}->{hook_encode_string}} ($self, 
          $self->{value}, type => 'body',
          charset => $charset);
    #$e{charset} ||= $self->{option}->{body_default_charset}
    #  if $self->{option}->{body_default_charset_input}
    #     ne $self->{option}->{body_default_charset};
    ## Normalize
    if ($option{use_normalization}) {
      if ($Message::MIME::Charset::CHARSET{$charset || '*default'}->{mime_text}) {
        $e{value} =~ s/\x0D(?!\x0A)/\x0D\x0A/gs;
        $e{value} =~ s/(?<!\x0D)\x0A/\x0D\x0A/gs;
        $e{value} .= "\x0D\x0A" unless $e{value} =~ /\x0D\x0A$/s;
      }
    }
  } else {
    %e = (value => $self->{value}, charset => $self->{_charset});
  }
  if (ref $self->{header}) {
    if ($e{charset}) {
      unless (ref $ct) {
        $ct = $self->{header}->field ('content-type');
        $ct->value ($option{_MEDIA_TYPE});
      }
      $ct->replace (charset => $e{charset});
    } elsif (ref $ct) {
      $ct->replace (charset => $self->{option}->{body_default_charset});
    }
  }
  $e{value};
}
*as_string = \&stringify;

=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

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
$Date: 2002/06/01 05:30:59 $

=cut

1;
