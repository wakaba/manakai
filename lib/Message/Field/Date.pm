
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

%DEFAULT = (
  format	=> 'rfc2822',
  output_day_of_week	=> 1,
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
  CDT	=> [-1,  5,  0],	## 733, 822, 2822
  CST	=> [-1,  6,  0],	## 733, 822, 2822
  EDT	=> [-1,  4,  0],	## 733, 822, 2822
  EST	=> [-1,  5,  0],	## 733, 822, 2822
  ## GDT 724
  GMT	=> [+1,  0,  0],	## 733, 822, 2822
  HDT	=> [-1,  9,  0],	## 733
  HST	=> [-1, 10,  0],	## 733
  MDT	=> [-1,  6,  0],	## 733, 822, 2822
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

sub new ($;$) {
  my $class = shift;
  my $self = bless {option => {@_}, date_time => shift||time}, $class;
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
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } else {
    $self->{date_time} = 0;
  }
  $self;
}

=head2 $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($) {
  my $self = shift;
  #} else { #if ($self->{option}->{format} eq 'rfc2822') {
    $self->as_rfc2822_time ();
  #}
}

sub as_plain_string ($) {
  my $self = shift;
  $self->stringify (@_);
}

sub as_unix_time ($) {
  my $self = shift;
  $self->{date_time};
}

sub as_rfc2822_time ($;%) {
  my $self = shift;
  my %option = @_;
  my $time = $self->{date_time};
  my @zone = [+1, 0, 0];
  if (ref $option{zone}) {@zone = @{$option{zone}}}
  elsif ($option{zone}) {@zone = $self->_zone_string_to_array ($option{zone})}
  elsif (ref $self->{option}->{zone}) {@zone = @{$self->{option}->{zone}}}
  elsif ($self->{option}->{zone}) {@zone = $self->{option}->_zone_string_to_array ($self->{option}->{zone})}
  $option{output_day_of_week} ||= $DEFAULT{output_day_of_week};
  
  $time += $zone[0] * ($zone[1] * 60 + $zone[2]) * 60;
  my ($sec,$min,$hour,$day,$month,$year,$day_of_week) = gmtime ($time);
  $month = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$month];
  $year += 1900 if $year < 1900;
  $day_of_week = (qw(Sun Mon Tue Wed Thr Fri Sat))[$day_of_week] .', ';
  
  ($option{output_day_of_week}? $day_of_week: '').
  sprintf('%02d %s %s %02d:%02d:%02d %s%02d%02d',
   $day,$month,$year,$hour,$min,$sec,$zone[0]>0?'+':'-',@zone[1,2]);
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

  use Message::Field::Structured;
  
  my $field_body = '"This is an example of <\"> (quotation mark)."
                    (Comment within \q\u\o\t\e\d\-\p\a\i\r\(\s\))';
  my $field = Message::Field::Structured->parse ($field_body);
  
  print $field->as_plain_string;

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
