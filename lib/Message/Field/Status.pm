
=head1 NAME

Message::Field::Status --- "Status:" CGI header field

=cut

package Message::Field::Status;
use strict;
use vars qw(%DEFAULT @ISA $REASON %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

*REG = \%Message::Util::REG;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_MEMBERS	=> [qw|reason_phrase _charset|],
    -_METHODS	=> [qw|reason_phrase status_code value|],
    -encoding_after_encode	=> 'iso-8859-1',
    -encoding_before_decode	=> 'iso-8859-1',
    #field_param_name
    #field_name
    #field_ns
    #format
    #hook_encode_string
    #hook_decode_string
    #parse_all
    -reason_default_set	=> 'http_1_1_rfc2616',
    -reason_unsafe_rule	=> qr/[^\x20-\x7E]/,
    -value_pattern	=> '%03d %s',
  );

%{ $REASON->{common} } = grep {length} split /[\t\x0D\x0A]+/, q(
	200	OK
	201	Created
	202	Accepted
	204	No Content
	301	Moved Permanently
	304	Not Modified
	400	Bad Request
	401	Unauthorized
	403	Forbidden
	404	Not Found
	500	Internal Server Error
	501	Not Implemented
	502	Bad Gateway
	503	Service Unavailable
	
	100	Continue
	101	Switching Protocols
	203	Non-Authoritative Information
	205	Reset Content
	206	Partial Content
	300	Multiple Choices
	303	See Other
	305	Use Proxy
	307	Temporary Redirect
	402	Payment Required
	405	Method Not Allowed
	406	Not Acceptable
	407	Proxy Authentication Required
	408	Request Time-out
	409	Conflict
	410	Gone
	411	Length Required
	412	Precondition Failed
	413	Request Entity Too Large
	414	Request-URI Too Large
	415	Unsupported Media Type
	416	Requested range not satisfiable
	417	Expectation Failed
	504	Gateway Time-out
	505	HTTP Version not supported
);

$REASON->{http_1_0} = {%{ $REASON->{common} }, grep {length} split /[\t\x0D\x0A]+/, q(
	302	Moved Temporarily
)};
$REASON->{http_1_1_rfc2068} = {%{ $REASON->{common} }, grep {length} split /[\t\x0D\x0A]+/, q(
	302	Moved Temporarily
)};
$REASON->{http_1_1_rfc2616} = {%{ $REASON->{common} }, grep {length} split /[\t\x0D\x0A]+/, q(
	302	Found
)};

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

sub _init ($;%) {
  my $self = shift;  my %opt = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %opt);
  
  my $format = $self->{option}->{format};
  unless (defined $opt{-reason_unsafe_regex}) {
    if ($format =~ /sip/) {
      $self->{option}->{reason_unsafe_regex} = qr/[^\x09\x20-\x7E$REG{R_utf8_xtra}]/;
    } elsif ($format =~ /cgi/) {
      ## default
    } else {	## HTTP
      $self->{option}->{reason_unsafe_regex} = qr/[^\x09\x20-\x7E\x80-\xFF]/;
    }
  }
  if ($format =~ /http-1\.0/) {
    $self->{option}->{reason_default_set} = 'http_1_0'
      unless defined $opt{-reason_default_set};
  } elsif ($format =~ /rfc2068/) {
    $self->{option}->{reason_default_set} = 'http_1_1_rfc2068'
      unless defined $opt{-reason_default_set};
  } elsif ($format =~ /sip/) {
    $self->{option}->{encoding_after_encode} = 'utf-8'
      unless defined $opt{-encoding_after_encode};
    $self->{option}->{encoding_before_decode} = 'utf-8'
      unless defined $opt{-encoding_before_decode};
    ## reason_default_set = sip_2_0
  }
}

=item $addr = Message::Field::Domain->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $addr = Message::Field::Domain->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  if ($body =~ /^([0-9]+)$REG{FWS}(.*)$/x) {
    $self->{value} = $1;
    my $r = $2;  $r =~ s/^$REG{WSP}+//;  $r =~ s/$REG{WSP}+$//;
    my %s = &{$self->{option}->{hook_decode_string}} ($self,
      $r, type => 'text',
      charset	=> $self->{option}->{encoding_before_decode},
    );
    if ($s{charset}) {	## Convertion failed
      $self->{_charset} = $s{charset};
      $self->{value} = $s{value};
      return $self;
    } elsif (!$s{success}) {
      $self->{_charset} = $self->{option}->{header_default_charset_input};
      $self->{value} = $s{value};
      return $self;
    }
    $self->{reason_phrase} = $s{value};
  };
  $self;
}

sub value ($;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    $self->{value} = $newvalue;
  }
  $self->{value};
}
*status_code = \&value;

sub reason_phrase ($;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    $self->{reason_phrase} = $newvalue;
  }
  $self->{reason_phrase};
}

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $reason;
  if ($self->{_charset}) {
    $reason = $self->{reason_phrase};
  } else {
    my (%e) = &{$option{hook_encode_string}} ($self,
      $self->{reason_phrase},  type => 'text',
      charset => $option{encoding_after_encode},
      current_charset => $option{internal_charset},
    );
    $reason = $e{value};
  }
  my $status = $self->{value};
  if (!$reason || $reason =~ /$option{reason_unsafe_regex}/) {
    $reason = $REASON->{ $option{reason_default_set} }{ $status };
  }
  sprintf $option{value_pattern}, $status, $reason;
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
$Date: 2002/08/03 04:57:59 $

=cut

1;
