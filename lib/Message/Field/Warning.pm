
=head1 NAME

Message::Field::Warning --- A element of "Warning:" HTTP general header field

=cut

package Message::Field::Warning;
use strict;
use vars qw(%DEFAULT @ISA $REASON %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

*REG = \%Message::Util::REG;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_MEMBERS	=> [qw|warn_agent warn_text warn_date|],
    -_METHODS	=> [qw|value warn_code warn_agent warn_text warn_date|],
    -encoding_after_encode	=> 'iso-8859-1',
    -encoding_before_decode	=> 'iso-8859-1',
    #field_param_name
    #field_name
    #field_ns
    -fill_warn_date	=> 0,
    #format
    #hook_encode_string
    #hook_decode_string
    -output_two_digit	=> 0,
    #parse_all
    -reason_default_set	=> 'http_1_1_rfc2616',
    -use_warn_date	=> 1,
    -value_pattern	=> '%03d %s %s%s',
  );

%{ $REASON->{common} } = grep {length} split /[\t\x0D\x0A]+/, q(
	10	Response is stale
	11	Revalidation failed
	12	Disconnected operation
	13	Heuristic expiration
	14	Transformation applied
	99	Miscellaneous warning
	
	110	Response is stale
	111	Revalidation failed
	112	Disconnected operation
	113	Heuristic expiration
	199	Miscellaneous warning
	214	Transformation applied
	299	Miscellaneous persistent warning
	
	300	Incompatible network protocol
	301	Incompatible network address formats
	302	Incompatible transport protocol
	303	Incompatible bandwidth units
	304	Media type not available
	305	Incompatible media format
	306	Attribute not understood
	307	Session description parameter not understood
	330	Multicast not available
	331	Unicast not available
	370	Insufficient bandwidth
	399	Miscellaneous warning
);

#%{ $REASON->{http_1_0} } = (%{ $REASON->{common} }, grep {length} split /[\t\x0D\x0A]#+/, q(
#));
$REASON->{http_1_0} = $REASON->{common};	## Warning is not defined by RFC 1945
$REASON->{http_1_1_rfc2068} = $REASON->{common};
$REASON->{http_1_1_rfc2616} = $REASON->{common};
$REASON->{sip_2_0} = $REASON->{common};

my %_two_to_three = qw(10 110 11 111 12 112 13 113 14 214 99 199);
my %_three_to_two = reverse %_two_to_three;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

sub _init ($;%) {
  my $self = shift;  my %opt = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %opt);
  
  my $format = $self->{option}->{format};
  if ($format =~ /http-1\.0/) {
    $self->{option}->{reason_default_set} = 'http_1_0'
      unless defined $opt{-reason_default_set};
  } elsif ($format =~ /rfc2068/) {
    $self->{option}->{reason_default_set} = 'http_1_1_rfc2068'
      unless defined $opt{-reason_default_set};
    $self->{option}->{value_pattern} = '%02d %s %s'
      unless defined $opt{-value_pattern};
    $self->{option}->{output_two_digit} = 1 unless defined $opt{-output_two_digit};
  } elsif ($format =~ /sip/) {
    $self->{option}->{encoding_after_encode} = 'utf-8'
      unless defined $opt{-encoding_after_encode};
    $self->{option}->{encoding_before_decode} = 'utf-8'
      unless defined $opt{-encoding_before_decode};
    $self->{option}->{reason_default_set} = 'sip_2_0'
      unless defined $opt{-reason_default_set};
    $self->{option}->{value_pattern} = '%03d %s %s'
      unless defined $opt{-value_pattern};
  }
  
  $self->{option}->{value_type}->{warn_agent} = ['Message::Field::Domain',{
  	-fill_default_value	=> 1,
  	-fill_default_name	=> 1,
  	-fill_default_port	=> 0,
  	-format_ipv4	=> '%vd',
  	-format_ipv6	=> '%s',
  	-output_comment	=> 0,
  	-output_port	=> 1,
  	-use_port	=> 1,
  }];
  $self->{option}->{value_type}->{warn_date} = ['Message::Field::Date',{
  	-output_comment	=> 0,
  }];
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
  if ($body =~ /^([0-9]+)$REG{FWS}($REG{token}(?::[0-9]+)?)$REG{FWS}$REG{M_quoted_string}(?:$REG{FWS}$REG{M_quoted_string})?/x) {
    $self->{value} = 0+$1;
    $self->{value} = $_two_to_three{ $self->{value} } || $self->{value};
    $self->{warn_agent} = $2;
    $self->{warn_date} = $4;
    my %s = &{$self->{option}->{hook_decode_string}} ($self,
      $3, type => 'text',
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
    $self->{warn_agent} = $self->_parse_value (warn_agent => $self->{warn_agent})
      if $self->{option}->{parse_all};
    $self->{warn_date} = $self->_parse_value (warn_date => $self->{warn_date})
      if $self->{option}->{parse_all};
    $self->{warn_text} = $s{value};
  } else {
    $self->{value} = 0;
    $self->{warn_text} = '';
    $self->{warn_agent} = '';
    $self->{warn_date} = '';
  }
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
*warn_code = \&value;

sub warn_agent ($;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    $self->{warn_agent} = $newvalue;
  }
  $self->{warn_agent} = $self->_parse_value (warn_agent => $self->{warn_agent})
    if $self->{option}->{parse_all};
  $self->{warn_agent};
}

sub warn_text ($;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    $self->{warn_text} = $newvalue;
  }
  $self->{warn_text};
}

sub warn_date ($;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    $self->{warn_date} = $newvalue;
  }
  $self->{warn_date} = $self->_parse_value (warn_date => $self->{warn_date})
    if $self->{option}->{parse_all};
  $self->{warn_date};
}

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $status = $self->{value};
  return '' unless $status;
  $status = $_three_to_two{$status} || $status if $option{output_two_digit};
  $status += 0;
  my ($host, $reason, $date);
  $host = $self->warn_agent;
  $date = $self->warn_date;
  if ($date == 0 && $option{fill_warn_date}) {
    $self->{warn_date}->unix_time (time);
  }
  if ($date == 0 || !$option{use_warn_date}) {
    $date = '';
  } else {
    $date = ' '.Message::Util::quote_unsafe_string ($date, unsafe => 'MATCH_ALL');
  }
  if ($self->{_charset}) {
    $reason = $self->{warn_text};
  } else {
    my (%e) = &{$option{hook_encode_string}} ($self,
      $self->{warn_text},  type => 'text',
      charset => $option{encoding_after_encode},
      current_charset => $option{internal_charset},
    );
    $reason = $e{value};
  }
  if (!$reason) {
    $reason = $REASON->{ $option{reason_default_set} }{ $status };
  }
  $reason = Message::Util::quote_unsafe_string ($reason, unsafe => 'MATCH_ALL') || '""';
  sprintf $option{value_pattern}, $status, $host, $reason, $date;
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
$Date: 2002/08/03 23:32:04 $

=cut

1;
