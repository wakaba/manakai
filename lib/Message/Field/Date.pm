
=head1 NAME

Message::Field::Date Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 date style C<field>s.

=cut

package Message::Field::Date;
require 5.6.0;
use strict;
use re 'eval';
use vars qw(%DEFAULT %MONTH %REG $VERSION %ZONE);
$VERSION = '1.00';

use Time::Local 'timegm_nocheck';
use overload '""' => sub {shift->stringify};

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;

$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_rfc2822_date_time} = qr/([0-9]+)$REG{FWS}([A-Za-z]+)$REG{FWS}([0-9]+)$REG{WSP}+([0-9]+)$REG{FWS}:$REG{FWS}([0-9]+)(?:$REG{FWS}:$REG{FWS}([0-9]+))?$REG{FWS}([A-Za-z]+|[+-]$REG{WSP}*[0-9]+)/;
$REG{M_rfc733_date_time} = qr/([0-9]{1,2})$REG{FWS}(?:-$REG{FWS})?([A-Za-z]+)$REG{FWS}(?:-$REG{FWS})?([0-9]+)$REG{WSP}+([0-9][0-9])$REG{FWS}(?::$REG{FWS})?([0-9][0-9])(?:$REG{FWS}(?::$REG{FWS})?([0-9][0-9]))?$REG{FWS}((?:-$REG{FWS})?[A-Za-z]+|[+-]$REG{WSP}*[0-9]+)/;
$REG{M_rfc724_slash_date} = qr#([0-9]+)$REG{FWS}/$REG{FWS}([0-9]+)$REG{FWS}/$REG{FWS}([0-9]+)$REG{WSP}+([0-9][0-9])$REG{FWS}(?::$REG{FWS})?([0-9][0-9])(?:$REG{FWS}(?::$REG{FWS})?([0-9][0-9]))?$REG{FWS}((?:-$REG{FWS})?[A-Za-z]+|[+-]$REG{WSP}*[0-9]+)#;
$REG{M_asctime} = qr/[A-Za-z]+$REG{FWS}([A-Za-z]+)$REG{FWS}([0-9]+)$REG{WSP}+([0-9]+)$REG{FWS}:$REG{FWS}([0-9]+)$REG{FWS}:$REG{FWS}([0-9]+)$REG{WSP}+([0-9]+)/;
$REG{M_iso8601_date_time} = qr/([0-9]+)-([0-9]+)-([0-9]+)[Tt]([0-9]+):([0-9]+):([0-9]+)(?:.([0-9]+))?(?:[Zz]|([+-])([0-9]+):([0-9]+))/;

%DEFAULT = (
  format	=> 'rfc2822',
  output_day_of_week	=> 1,
  output_zone_string	=> 0,
  zone	=> [+1, 0, 0],
  zone_letter	=> +1,
);

## format	rfc733	[RFC733]
##       	rfc2822	[RFC822] + [RFC1123], [RFC2822]

%MONTH = (
  JAN	=> 1,	JANUARY	=> 1,
  FEB	=> 2,	FEBRUARY	=> 2,
  MAR	=> 3,	MARCH	=> 3,
  APR	=> 4,	APRIL	=> 4,
  MAY	=> 5,
  JUN	=> 6,	JUNE	=> 6,
  JUL	=> 7,	JULY	=> 7,
  AUG	=> 8,	AUGUST	=> 8,
  SEP	=> 9,	SEPTEMBER	=> 9,
  OCT	=> 10,	OCTOBER	=> 10,
  NOV	=> 11,	NOVEMBER	=> 11,
  DEC	=> 12,	DECEMBER	=> 12,
);

%ZONE = (
  ADT	=> [-1,  3,  0],	## 733
  AST	=> [-1,  4,  0],	## 733
  BDT	=> [-1, 10,  0],	## 733
  BST	=> [-1, 11,  0],	## 733
  #BST	=> [+1,  1,  0],
  CDT	=> [-1,  5,  0],	## 733, 822, 2822
  CET	=> [+1,  1,  0],
  CST	=> [-1,  6,  0],	## 733, 822, 2822
  EDT	=> [-1,  4,  0],	## 733, 822, 2822
  EET	=> [+1,  2,  0],	## 1947
  EST	=> [-1,  5,  0],	## 733, 822, 2822
  GDT	=> [+1,  1,  0],	## 724
  GMT	=> [+1,  0,  0],	## 733, 822, 2822
  HDT	=> [-1,  9,  0],	## 733
  HKT	=> [+1,  8,  0],
  HST	=> [-1, 10,  0],	## 733
  IDT	=> [+1,  3,  0],
  IST	=> [+1,  2,  0],	## Israel standard time
  #IST	=> [+1,  5, 30],	## Indian standard time
  JST	=> [+1,  9,  0],
  MDT	=> [-1,  6,  0],	## 733, 822, 2822
  MET	=> [+1,  0,  0],
  METDST	=> [+2,  0,  0],
  MST	=> [-1,  7,  0],	## 733, 822, 2822
  NST	=> [-1,  3, 30],	## 733
  PDT	=> [-1,  7,  0],	## 733, 822, 2822
  PST	=> [-1,  8,  0],	## 733, 822, 2822
  YDT	=> [-1,  8,  0],	## 733
  YST	=> [-1,  9,  0],	## 733
  UT	=> [+1,  0,  0],	## 822, 2822
);

=head2 $self->_option_zone_letter (-1/0/+1)

Set convertion rule between one letter zone name
(military format) and time.

C<+1> set it as standard value.  (For exmaple, 'A' means
'+0100'.)  C<-1> reverses their sign, for example, 'A'
means '-0100'.  BNF comment of RFC 733 and 822 has typo
so quite a few implemention takes these values incorrectly.
As a result, these zone names carry no worthful information.
RFC 2822 recommends these names be taken as '-0000' (i.e.
unknown zone).  C<-2> means it.

=cut

sub _option_zone_letter ($$) {
  my $self = shift;
  my $mode = shift;
  my $i = 0;
  if ($mode == -2) {
    for my $letter ('A'..'Z') {$ZONE{$letter} = [-1, 0, 0]} return $self;
  }
  for my $letter ('Z', 'A'..'I', 'K'..'M') {
    $ZONE{$letter} = [+1*$mode, $i++, 0];
  }  $i = 1;
  for my $letter ('N'..'Y') {
    $ZONE{$letter} = [-1*$mode, $i++, 0];
  }
  $self;
}

=head2 Message::Field::Date->new ()

Return empty Message::Field::Date object.

=cut

sub new ($;%) {
  my $class = shift;
  my %option = @_;
  $option{date_time} ||= time; $option{date_time} = 0 if $option{unknown};
  my $self = bless {option => {@_}, date_time => $option{date_time}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->_option_zone_letter ($self->{option}->{zone_letter});
  $self;
}

=head2 Message::Field::Date->parse ($unfolded_field_body)

Parse date style C<field-body>.

=cut

sub parse ($$;%) {
  my $class = shift;  my $field_body = shift;
  my $self = bless {option => {@_}}, $class;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->_option_zone_letter ($self->{option}->{zone_letter});
  $field_body = $self->delete_comment ($field_body);
  if ($field_body =~ /$REG{M_rfc2822_date_time}/) {
    my ($day, $month, $year, $hour, $minute, $second, $zone)
     = ($1, uc $2, $3, $4, $5, $6, uc $7);
    $month = $MONTH{$month} || 1;
    if    ( 0 < $year && $year <   49) {$year += 2000}
    elsif (50 < $year && $year < 1000) {$year += 1900}
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } elsif ($field_body =~ /$REG{M_iso8601_date_time}/) {
    my ($year,$month,$day,$hour,$minute,$second,$secfrac,
        $zone_sign,$zone_hour,$zone_minute)
     = ($1, $2, $3, $4, $5, $6, $7, "${8}1", $9, $10);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = $secfrac;
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } elsif ($field_body =~ /$REG{M_rfc733_date_time}/) {
    my ($day, $month, $year, $hour, $minute, $second, $zone)
     = ($1, uc $2, $3, $4, $5, $6, uc $7);
    $month = $MONTH{$month} || 1;
    if    ( 0 < $year && $year <   49) {$year += 2000}
    elsif (50 < $year && $year < 1000) {$year += 1900}
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } elsif ($field_body =~ /$REG{M_asctime}/) {
    my ($month, $day, $hour, $minute, $second, $year) = (uc $1, $2, $3, $4, $5, $6);
    $month = $MONTH{$month} || 1;
    if    ( 0 < $year && $year <   49) {$year += 2000}
    elsif (50 < $year && $year < 1000) {$year += 1900}
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute, $hour, $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [-1, 0, 0];
  } elsif ($field_body =~ /$REG{M_rfc724_slash_date}/) {
    my ($month, $day, $year, $hour, $minute, $second, $zone)
     = ($1, $2, $3, $4, $5, $6, uc $7);
    if    ( 0 < $year && $year <   49) {$year += 2000}
    elsif (50 < $year && $year < 1000) {$year += 1900}
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } else {
    $self->{date_time} = 0;
    $self->{secfrac} = '';
  }
  $self;
}

=head2 $self->unix_time ([$new_time])

Returns or set the unix-time (seconds from the Epoch).

=cut

sub unix_time ($;$) {
  my $self = shift;
  my $new_time = shift;
  if (defined $new_time) {
    $self->{date_time} = $new_time + 0;
  }
  $self->{date_time};
}

=head2 $self->second_fraction ([$new_fraction])

Returns or set the decimal fraction of a second.
Value is a string containing of only [0-9]
or empty string.

=cut

sub second_fraction ($;$) {
  my $self = shift;
  my $new_fraction = shift;
  if (defined $new_fraction) {
    $self->{secfrac} = $new_fraction unless $new_fraction =~ /[^0-9]/;
  }
  $self->{secfrac};
}

=head2 $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{format} ||= $self->{option}->{format} || $DEFAULT{format};
  if ($option{format} eq 'iso8601') {
    $self->as_iso8601_time (%option);
  } elsif ($option{format} eq 'http') {
    $self->as_http_time (%option);
  } elsif ($option{format} eq 'unix') {
    $self->as_unix_time (%option);
  } else { #if ($option{format} eq 'rfc2822') {
    $self->as_rfc2822_time (%option);
  }
}

sub as_plain_string ($;%) {
  my $self = shift;
  $self->stringify (@_);
}

=head2 $self->as_unix_time ([%options])

Returns date-time value as the unixtime format
(seconds counted from the Epoch, 1970-01-01 00:00:00).

=cut

sub as_unix_time ($;%) {
  my $self = shift;
  $self->{date_time};
}

=head2 $self->as_rfc2822_time ([%options])

Returns C<date-time> value as RFC 2822 format.
(It is also known as RFC 822 format modified by RFC 1123)

Option C<output_day_of_week> enables to output
C<day-of-week> string.  (Default C<+1>)

If option C<output_zone_string> > 0, use timezone
name C<GMT> instead of numeric representation.
This option is intended to be used for C<HTTP-date>
with option C<zone>.  (Default C<-1>)

Option C<zone> specifies output time zone with
RFC 2822 numeric representation such as C<+0000>.
Unless this option, time zone of input data 
(when C<parsed> method is used) or default value
C<+0000> is used.

=cut

sub as_rfc2822_time ($;%) {
  my $self = shift;
  my %option = @_;
  my $time = $self->{date_time};
  my @zone = [+1, 0, 0];
  if (ref $option{zone}) {@zone = @{$option{zone}}}
  elsif ($option{zone}) {@zone = $self->_zone_string_to_array ($option{zone})}
  elsif (ref $self->{option}->{zone}) {@zone = @{$self->{option}->{zone}}}
  elsif ($self->{option}->{zone}) 
    {@zone = $self->{option}->_zone_string_to_array ($self->{option}->{zone})}
  $option{output_day_of_week} ||= $self->{option}->{output_day_of_week} 
                              || $DEFAULT{output_day_of_week};
  $option{output_zone_string} ||= $self->{option}->{output_zone_string} 
                              || $DEFAULT{output_zone_string};
  
  $time += $zone[0] * ($zone[1] * 60 + $zone[2]) * 60;
  my ($sec,$min,$hour,$day,$month,$year,$day_of_week) = gmtime ($time);
  $month = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$month];
  $year += 1900 if $year < 1900;
  $day_of_week = (qw(Sun Mon Tue Wed Thu Fri Sat))[$day_of_week] .', ';
  
  ($option{output_day_of_week}>0? $day_of_week: '').
  sprintf('%02d %s %s %02d:%02d:%02d %s',
   $day,$month,$year,$hour,$min,$sec,
   ($option{output_zone_string}>0 && $zone[0]>0 && $zone[1]+$zone[2]==0? 
    'GMT': sprintf('%s%02d%02d',$zone[0]>0?'+':'-',@zone[1,2]))
  );
}

=head2 $self->as_http_time ([%options])

Returns C<date-time> value as HTTP preferred format.
This method is same as 
C<$self->as_rfc2822_time (output_zone_string => 1, zone => '+0000')>.

=cut

sub as_http_time ($;%) {
  my $self = shift;
  my %option = @_;
  $option{output_zone_string} = 1;
  $option{zone} = [+1, 0, 0];
  $self->as_rfc2822_time (%option);
}

=head2 $self->as_iso8601_time ([%options])

Returns C<date-time> value as ISO 8601 format.

If option C<output_zone_string> > 0, use timezone
name C<Z> instead of numeric representation.
This option is intended to be used for C<HTTP-date>
with option C<zone>.  (Default C<-1>)

Option C<zone> specifies output time zone with
RFC 2822 numeric representation such as C<+0000>.
Unless this option, time zone of input data 
(when C<parsed> method is used) or default value
C<+0000> is used.

=cut

sub as_iso8601_time ($;%) {
  my $self = shift;
  my %option = @_;
  my $time = $self->{date_time};
  $option{output_zone_string} ||= $self->{option}->{output_zone_string} 
                              || $DEFAULT{output_zone_string};
  my @zone = [+1, 0, 0];
  if (ref $option{zone}) {@zone = @{$option{zone}}}
  elsif ($option{zone}) {@zone = $self->_zone_string_to_array ($option{zone})}
  elsif (ref $self->{option}->{zone}) {@zone = @{$self->{option}->{zone}}}
  elsif ($self->{option}->{zone}) {@zone = $self->{option}->_zone_string_to_array ($self->{option}->{zone})}
  
  $time += $zone[0] * ($zone[1] * 60 + $zone[2]) * 60;
  my ($sec,$min,$hour,$day,$month,$year,$day_of_week) = gmtime ($time);
  $year += 1900 if $year < 1900;
  
  sprintf('%04d-%02d-%02dT%02d:%02d:%02d%s%s',
   $year,$month,$day,$hour,$min,$sec,
   ($self->{secfrac}? '.'.$self->{secfrac}: ''),
   ($option{output_zone_string}>0 && $zone[0]>0 && $zone[1]+$zone[2]==0? 
    'Z': sprintf('%s%02d:%02d',$zone[0]>0?'+':'-',@zone[1,2]))
  );
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

=head2 $self->delete_comment ($field_body)

Remove all C<comment> in given strictured C<field-body>.
This method is intended for internal use.

=cut

sub delete_comment ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

sub _zone_string_to_array ($$;$) {
  my $self = shift;
  my $zone = shift;
  my $format = shift;
  my @azone = [+1, 0, 0];
  ## if $format eq rfc2822
    if ($zone =~ /([+-])$REG{FWS}([0-9][0-9])([0-9][0-9])/) {
      @azone = ("${1}1", $2, $3);
    } else { $zone =~ tr/-//d;
      if (ref $ZONE{$zone}) {@azone = @{$ZONE{$zone}}}
      elsif ($zone) {@azone = (-1, 0, 0)}
    }
  # }
  @azone;
}

=head1 EXAMPLE

  use Message::Field::Date;
  
  my $field_body = '04 Feb 2002 00:12:33 CST';
  my $field = Message::Field::Date->parse ($field_body);
  
  print "Un*xtime:\t", $field->as_unix_time, "\n";
  print "RFC 2822:\t", $field->as_rfc2822_time, "\n";
  print "HTTP preferred:\t", $field->as_http_time, "\n";
  print "ISO 8601:\t", $field->as_iso8601_time, "\n";

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
