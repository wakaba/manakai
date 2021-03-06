
=head1 NAME

Message::Field::Date --- Perl module for various styles of 
date-time used in Internet messages and so on

=cut

## This file is written in UTF-8

package Message::Field::Date;
use strict;
use vars qw(%DEFAULT %FMT2STR @ISA %MONTH %REG $VERSION %ZONE);
$VERSION=do{my @r=(q$Revision: 1.20 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
use Time::Local 'timegm_nocheck';
use overload '==' => sub { $_[0]->{date_time} == $_[1] },
             '<=' => sub { $_[0]->{date_time} <= $_[1] },
             '>=' => sub { $_[0]->{date_time} >= $_[1] },
             '0+' => sub { $_[0]->{date_time} },
             fallback => 1;

{
%REG = %Message::Util::REG;
	my $_ALPHA = q{[A-Za-z]};
	$_ALPHA = q{[A-Za-z\x{0080}-\x{7FFFFFFF}]} if defined $^V && $^V gt v5.7;
	## RFC 822/2822 Internet Message Format
	$REG{M_dt_rfc822} = qr!(?:[A-Za-z]+	## Day of week
		[\x09\x20,]*)?	([0-9]+)	## Day
		[\x09\x20/-]*	($_ALPHA+)	## Month
		[\x09\x20/-]*	([0-9]+)	## Year
		[\x09\x20:Tt-]+	([0-9]+)	## Hour
		[\x09\x20:]+	([0-9]+)	## Minute
		[\x09\x20:]*	([0-9]+)?	## Second
		([\x09\x20 0-9A-Za-z+-]+)!x;	## Zone
	## RFC 3339 Internet Date/Time Format (A profile of ISO 8601)
	$REG{M_dt_rfc3339} = qr!	([0-9]{4,})	## Year
		   [\x09\x20.:/-]+	([0-9]+)	## Month
		   [\x09\x20.:/-]+	([0-9]+)	## Day
		(?:[\x09\x20.:Tt-]+	([0-9]+)	## Hour
		   [\x09\x20.:]+	([0-9]+)	## Minute
		(?:[\x09\x20.:]+	([0-9]+)	## Second
		(?:[\x09\x20.:]+	([0-9]+))?)?)?	## frac.
		([\x09\x20 0-9A-Za-z:.+-]*)	!x;	## Zone.
	## RFC 733 ARPA Internet Message Format
	$REG{M_dt_rfc733} = qr!(?:[A-Za-z]+	## Day of week
		[\x09\x20,]*)?	([0-9]+)	## Day
		[\x09\x20/-]*	([A-Za-z]+)	## Month
		[\x09\x20/-]*	([0-9]+)	## Year
		[\x09\x20:Tt-]+	([0-9][0-9])	## Hour
		[\x09\x20:]*	([0-9][0-9])	## Minute
		[\x09\x20:]*	([0-9][0-9])?	## Second
		([\x09\x20 0-9A-Za-z+-]+)!x;	## Zone
	## RFC 724 ARPA Internet Message Format (slash-date)
	$REG{M_dt_rfc724} = qr!(?:[A-Za-z]+	## Day of week
		[\x09\x20,]*)?	([0-9][0-9]?)	## Month
		[\x09\x20/]+	([0-9][0-9]?)	## Day
		[\x09\x20/]+	([0-9]{2,})	## Year
		[\x09\x20:Tt-]+	([0-9][0-9])	## Hour
		[\x09\x20:]*	([0-9][0-9])	## Minute
		[\x09\x20:]*	([0-9][0-9])?	## Second
		([\x09\x20 0-9A-Za-z+-]+)!x;	## Zone
}

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
%DEFAULT = (
    -_MEMBERS	=> [qw|date_time secfrac|],
    -_METHODS	=> [qw|unix_time second_fraction
                       comment_add comment_count comment_item comment_delete|],
    -date_format	=> 'string',	## 'unix' / 1*ALPHA
    #field_param_name
    #field_name
    #format
    #hook_encode_string
    #hook_decode_string
    -output_comment	=> 1,
    -use_comment	=> 1,
    -use_military_zone	=> +1,	## +1 / -1 / 0
    #zone	=> [+1, 0, 0],
    -zone_default_string	=> '-0000',
);

%MONTH = (
  JAN	=> 1,	JANUARY	=> 1,
  FEB	=> 2,	FEBRUARY	=> 2,
  MAR	=> 3,	MARCH	=> 3,
  APR	=> 4,	APRIL	=> 4,	ARL	=> 4,
  MAY	=> 5,
  JUN	=> 6,	JUNE	=> 6,
  JUL	=> 7,	JULY	=> 7,
  AUG	=> 8,	AUGUST	=> 8,
  SEP	=> 9,	SEPTEMBER	=> 9,	SEPT	=> 9,
  OCT	=> 10,	OCTOBER	=> 10,
  NOV	=> 11,	NOVEMBER	=> 11,
  DEC	=> 12,	DECEMBER	=> 12,
);

{
my $_p2f = sub { my ($s, $n) = @_; $s eq 'none'? q(%d): $s eq 'SP'? qq(%${n}d): qq(%0${n}d) };
my $_tm = sub { $_[0]->{local}?'tm_local':'tm' };
## &$function ({format's parameters}, {caller's parameters})
%FMT2STR = (
	CC	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),	## BUG: Support AD only
	  	         (($_[1]->{ &$_tm ($_[0]) }->[5] + 1899) / 100) + 1 },
	YYYY	=> sub { sprintf &$_p2f ($_[0]->{pad}, 4),
	                 $_[1]->{ &$_tm ($_[0]) }->[5] + 1900 },
	YY	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),
	                 $_[1]->{ &$_tm ($_[0]) }->[5] % 100 },
	MM	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),
	                 $_[1]->{ &$_tm ($_[0]) }->[4] + 1 },
	Mon	=> sub { qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
	   	           [ $_[1]->{ &$_tm ($_[0]) }->[4] ] },
	Month	=> sub { qw(January February March April May June
	   	            July August September October November December)
	   	           [ $_[1]->{ &$_tm ($_[0]) }->[4] ] },
	DD	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),
	                 $_[1]->{ &$_tm ($_[0]) }->[3] },
	Wdy	=> sub { qw(Sun Mon Tue Wed Thu Fri Sat)
	   	           [ $_[1]->{ &$_tm ($_[0]) }->[6] ] },
	Weekday	=> sub {
	  (split /:/, $_[0]->{name}
	    || q(Sunday:Monday:Tuesday:Wednesday:Thursday:Friday:Saturday))
	   	           [ $_[1]->{ &$_tm ($_[0]) }->[6] ] },
	shun	=> sub {
	  my @alphabet = split /:/, $_[0]->{alphabet} || 'a:b:c:c';
	  my $day = $_[1]->{ &$_tm ($_[0]) }->[3];
	  $day < 10? $alphabet[0]:	##  1 -  9 joujun
	  $day < 20? $alphabet[1]:	## 10 - 19 chuujun
	  $day < 30? $alphabet[2]:	## 20 - 29 gejun
	  defined $alphabet[3] ?
	  $alphabet[3]: $alphabet[2];	## 30 - 31 gejun
	},
	HH	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),
	                 $_[1]->{ &$_tm ($_[0]) }->[2] },
	TT	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),
	                 $_[1]->{ &$_tm ($_[0]) }->[1] },
	SS	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2),
	                 $_[1]->{ &$_tm ($_[0]) }->[0] },
	unix	=> sub { sprintf &$_p2f ($_[0]->{pad}, 10),
	                 $_[1]->{ $_[0]->{local}?'time_local':'time' } },
	frac	=> sub { $_[1]->{ $_[0]->{local}?'secfrac_local':'secfrac' } },
	zsign	=> sub { $_[1]->{option}->{zone}->[0] > 0 ? '+' : '-' },
	zHH	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2), $_[1]->{option}->{zone}->[1] },
	zTT	=> sub { sprintf &$_p2f ($_[0]->{pad}, 2), $_[1]->{option}->{zone}->[2] },
	comment	=> sub { $_[1]->{comment} },
);
}

%ZONE = (	## NA = Northern America
  ADT	=> [-1,  3,  0],	## (NA)Atlantic Daylight	733
  AHST	=> [-1, 10,  0],	## Alaska-Hawaii Standard
  AST	=> [-1,  4,  0],	## (NA)Atlantic Standard	733
  AT	=> [-1,  2,  0],	## Azores
  BDT	=> [-1, 10,  0],	## 	733
  BST	=> [-1, 11,  0],	## 	733
  #BST	=> [+1,  1,  0],	## British Summer
  #BST	=> [-1,  3,  0],	## Brazil Standard
  BT	=> [+1,  3,  0],	## Baghdad
  CADT	=> [+1, 10, 30],	## Central Australian Daylight
  CAST	=> [+1,  9, 30],	## Central Australian Standard
  CAT	=> [-1, 10,  0],	## Central Alaska
  CCT	=> [+1,  8,  0],	## China Coast
  CDT	=> [-1,  5,  0],	## (NA)Central Daylight	733, 822
  CET	=> [+1,  1,  0],	## Central European
  CEST	=> [+1,  2,  0],	## Central European Daylight
  CST	=> [-1,  6,  0],	## (NA)Central Standard	733, 822
  EADT	=> [+1, 11,  0],	## Eastern Australian Daylight
  EADT	=> [+1, 10,  0],	## Eastern Australian Standard
  #EASTERN
  ECT	=> [+1,  1,  0],	## Central European (French)
  EDT	=> [-1,  4,  0],	## (NA)Eastern Daylight	733, 822
  EEST	=> [+1,  3,  0],	## Eastern European Summer
  EET	=> [+1,  2,  0],	## Eastern Europe	1947
  EST	=> [-1,  5,  0],	## (NA)Eastern Standard	733, 822
  EWT	=> [-1,  4,  0],	## U.S. Eastern War Time
  FST	=> [+1,  2,  0],	## French Summer
  FWT	=> [+1,  1,  0],	## French Winter
  GDT	=> [+1,  1,  0],	## 	724
  #GDT	=> [+1,  2,  0],	## German Daylight
  #GM
  GMT	=> [+1,  0,  0],	## Greenwich Mean	733, 822
  #GST	=> [-1,  3,  0],	## Greenland Standard
  GST	=> [+1,  1,  0],	## German Standard
  #GST	=> [+1, 10,  0],	## Guam Standard
  HDT	=> [-1,  9,  0],	## Hawaii Daylight	733
  HKT	=> [+1,  8,  0],	## Hong Kong
  HST	=> [-1, 10,  0],	## Hawaii Standard	733
  IDLE	=> [+1, 12,  0],	## International Date Line East
  IDLW	=> [-1, 12,  0],	## International Date Line West
  IDT	=> [+1,  3,  0],
  IST	=> [+1,  2,  0],	## Israel standard
  #IST	=> [+1,  5, 30],	## Indian standard
  IT	=> [+1,  3, 30],	## Iran
  JST	=> [+1,  9,  0],	## Japan Central Standard
  #JT	=> [+1,  9,  0],	## Japan Central Standard
  JT	=> [+1,  7, 30],	## Java
  KDT	=> [+1, 10,  0],	## Korean Daylight
  KST	=> [+1,  9,  0],	## Korean Standard
  LCL	=> [-1,  0,  0],	## (unknown zone used by LSMTP)
  LOCAL	=> [-1,  0,  0],	## local time zone
  #LON
  LT	=> [-1,  0,  0],	## Luna Time [RFC 1607]
  MDT	=> [-1,  6,  0],	## (NA)Mountain Daylight	733, 822
  MET	=> [+1,  0,  0],	## Middle European
  METDST	=> [+1,  2,  0],
  MEST	=> [+1,  2,  0],	## Middle European Summer
  MEWT	=> [+1,  0,  0],	## Middle European Winter
  MEZ	=> [+1,  0,  0],	## Central European (German)
  MST	=> [-1,  7,  0],	## (NA)Mountain Standard	733, 822
  MOUNTAIN	=> [-1,  7,  0],	## (maybe) (NA)Mountain Standard	733, 822
  MT	=> [-1,  0,  0],	## Mars Time [RFC 1607]
  NDT	=> [-1,  2, 30],	## Newfoundland Daylight
  NFT	=> [-1,  3, 30],	## Newfoundland Standard
  NST	=> [-1,  3, 30],	## Newfoundland Standard	733
  #NST	=> [-1,  6, 30],	## North Sumatra
  NT	=> [-1, 11,  0],	## Nome
  NZD	=> [+1, 13,  0],	## New Zealand Daylight
  NZT	=> [+1, 12,  0],	## New Zealand
  NZDT	=> [+1, 13,  0],	## New Zealand Daylight
  NZS	=> [+1, 12,  0],	## (maybe) New Zealand Standard
  NZST	=> [+1, 12,  0],	## New Zealand Standard
  PDT	=> [-1,  7,  0],	## (NA)Pacific Daylight	733, 822
  #PM
  PST	=> [-1,  8,  0],	## (NA)Pacific Standard	733, 822
  #SAMST
  SET	=> [+1,  1,  0],	## Seychelles
  SST	=> [+1,  2,  0],	## Swedish Summer
  #SST	=> [+1,  7,  0],	## South Sumatra
  SWT	=> [+1,  1,  0],	## Swedish Winter
  UKR	=> [+1,  2,  0],	## Ukraine
  UNDEFINED	=> [-1,  0,  0],	## undefined
  UT	=> [+1,  0,  0],	## Universal Time	822
  UTC	=> [+1,  0,  0],	## Coordinated Universal Time
  WADT	=> [+1,  8,  0],	## West Australian Daylight
  WAT	=> [-1,  0,  0],	## West Africa
  WET	=> [+1,  0,  0],	## Western European
  WST	=> [+1,  8,  0],	## West Australian Standard
  YDT	=> [-1,  8,  0],	## Yukon Daylight	733
  YST	=> [-1,  9,  0],	## Yukon Standard	733
  Z	=> [+1,  0,  0],	## 	822, ISO 8601
  ZP4	=> [+1,  4,  0],	## Z+4
  ZP5	=> [+1,  5,  0],	## Z+5
  ZP6	=> [+1,  6,  0],	## Z+6
);

## -use_military_zone => +1 / -1 / 0
##   Whether military zone names are understood or not.
##   +1  Admits them and treats as standard value.  (eg. "A" = +0100)
##   -1  Admits them but treats as negative value.  (eg. "A" = -0100)
##    0  They are ignored and zone is set as -0000. (eg. "A" = -0000)
##   Because of typo in BNF comment of RFCs 733 and 822,
##   quite a few implemention use these values incorrectly.
##   As a result, these zone names carry no worthful information.
##   RFC 2822 recommends these names be taken as '-0000' (i.e.
##   unknown zone).

sub _set_military_zone_name ($) {
  my $self = shift;
  my $mode = $self->{option}->{use_military_zone};
  my $i = 0;
  if ($mode == 0) {
    for my $letter ('A'..'Y') {$ZONE{$letter} = [-1, 0, 0]} return;
  }
  for my $letter ('Z', 'A'..'I', 'K'..'M') {
    $ZONE{$letter} = [+1*$mode, $i++, 0];
  }  $i = 1;
  for my $letter ('N'..'Y') {
    $ZONE{$letter} = [-1*$mode, $i++, 0];
  }
}

sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  my %option = @_;
  $self->SUPER::_init (%$DEFAULT, %option);
  $self->{date_time} = 0;
  $self->{date_time} = $option{unix} if defined $option{unix};
  $self->{secfrac} = $option{frac} if defined $option{frac};
  unless (ref $self->{option}->{zone}) {
    my $zone = $self->{option}->{zone} || ''; #$main::ENV{TZ} || '';
    	## Since _zone_string_to_array does not provide full support
    	## of parsing TZ format (eg. daytime), not seeing it might be
    	## better way.
    if (length $zone) {
      $self->{option}->{zone} = [ $self->_zone_string_to_array ($zone) ];
    } else {
      my $time = time;
      my $ltime = timegm_nocheck (localtime ($time));
      my $o = int ( ($ltime - $time) / 60);
      my @zone;
      $zone[2] = $o % 60;  $o = int ( $o / 60 );
      $zone[1] = $o % 24;
      $zone[0] = $o >= 0 ? +1 : -1;
      $self->{option}->{zone} = \@zone;
    }
  }
  
  my $format = $self->{option}->{format};
  if ($format =~ /mail-rfc2822/) {
    $self->{option}->{use_military_zone} = 0;
  }
  
  $self->_set_military_zone_name;
}

=item $date = Message::Field::Date->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $date = Message::Field::Date->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  ($body, @{$self->{comment}})
    = $self->Message::Util::delete_comment_to_array ($body)
    if $self->{option}->{use_comment};
  $body =~ s/^$REG{WSP}+//;  $body =~ s/$REG{WSP}+$//;
  if ($self->{option}->{date_format} eq 'unix') {
    $self->{date_time} = int ($body);
  } elsif (!$body) {
    return $self;
  } elsif ($body =~ /^$REG{M_dt_rfc822}$/x) {
    my ($day, $month, $year, $hour, $minute, $second, $zone)
     = ($1, uc $2, $3, $4, $5, $6, uc $7);
    $month = $MONTH{$month} || 1;
    $year = $self->_obvious_year ($year) if length($year)<4;
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } elsif ($body =~ /^$REG{M_dt_rfc3339}$/x) {
    my ($year,$month,$day,$hour,$minute,$second,$secfrac,$zone)
     = ($1, $2, $3, $4, $5, $6, $7, $8);
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = $secfrac;
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } elsif ($body =~ /^$REG{M_dt_rfc733}$/x) {
    my ($day, $month, $year, $hour, $minute, $second, $zone)
     = ($1, uc $2, $3, $4, $5, $6, uc $7);
    $month = $MONTH{$month} || 1;
    $year = $self->_obvious_year ($year) if length($year)<4;
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  } elsif ($body =~ /^$REG{M_dt_rfc724}$/x) {
    my ($month, $day, $year, $hour, $minute, $second, $zone)
     = ($1, $2, $3, $4, $5, $6, uc $7);
    $year = $self->_obvious_year ($year) if length($year)<4;
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = '';
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  #} elsif ($body =~ /^[0-9]+$/) {
  #  $self->{date_time} = $&;
  } else {
    ## From HTTP::Date (revision 1.40) by Gisle Aas
    #$body =~ s/^\s+//;  # kill leading space
    $body =~ s/^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*,?\s*//i; # Useless weekday
    my ($day, $month, $year, $hour, $minute, $second);
    my ($secfrac, $zone, $ampm) = ('', $self->{option}->{zone_default_string});
    
    # Then we are able to check for most of the formats with this regexp
    (($day,$month,$year,$hour,$minute,$second,$zone) =
      $body =~ m"^
        (\d\d?)               # day
          (?:\s+|[-\/])
        (\w+)                 # month
          (?:\s+|[-\/])
        (\d+)                 # year
        (?:
            (?:\s+|:)       # separator before clock
          (\d\d?):(\d\d)     # hour:min
          (?::(\d\d))?       # optional seconds
        )?                    # optional clock
          \s*
        ([-+]?\d{2,4}|(?![APap][Mm]\b)[A-Za-z]+)? # timezone
      $"x)
    
    ||
    
    # Try the ctime and asctime format
    (($month, $day, $hour, $minute, $second, $zone, $year) =
    $body =~ m"^
      (\w{1,3})             # month
        \s+
      (\d\d?)               # day
        \s+
      (\d\d?):(\d\d)        # hour:min
      (?::(\d\d))?          # optional seconds
        \s+
      (?:([A-Za-z]+)\s+)?   # optional timezone
      (\d+)                 # year
    $"x)
    
    ||
    
    # Then the Unix 'ls -l' date format
    (($month, $day, $year, $hour, $minute, $second) =
    $body =~ m"^
      (\w{3})               # month
        \s+
      (\d\d?)               # day
        \s+
      (?:
        (\d\d\d\d) |       # year
        (\d{1,2}):(\d{2})  # hour:min
        (?::(\d\d))?       # optional seconds
      )
    $"x)
    
    ||
    
    # ISO 8601 format '1996-02-29 12:00:00 -0100' and variants
    (($year, $month, $day, $hour, $minute, $second, $secfrac, $zone) =
    $body =~ m"^
      (\d{4})              # year
        [-\/]?
      (\d\d?)              # numerical month
        [-\/]?
      (\d\d?)              # day
      (?:
          (?:\s+|[-:Tt])  # separator before clock
        (\d\d?):?(\d\d)    # hour:min
        (?:
          :?
          (\d\d)
          (?:\.?(\d+))?	## optional second frac.
        )?      # optional seconds
      )?                    # optional clock
        \s*
      ([-+]?\d\d?:?(:?\d\d)?
      |Z|z)?               # timezone  (Z is 'zero meridian', i.e. GMT)
      
    $"x)
    
    ||
    
    # ISO 8601 like format '96-02-29 2:0:0 -0100' and variants
    (($year, $month, $day, $hour, $minute, $second, $secfrac, $zone) =
    $body =~ m"^
      (\d+)              # year
        [-/]
      (\d\d?)              # numerical month
        [-/]
      (\d\d?)              # day
      (?:
          (?:\s+|[-:Tt])  # separator before clock
        (\d\d?):(\d+)    # hour:min
        (?:
          :
          (\d+)
          (?:\.(\d+))	## optional second frac.
        )?      # optional seconds
      )?                    # optional clock
        \s*
      ([-+]?\d+(:\d+)?
      |Z|z)?               # timezone  (Z is 'zero meridian', i.e. GMT)
      
    $"x)
    
    ||
    
    # Windows 'dir' 11-12-96  03:52PM
    (($month, $day, $year, $hour, $minute, $ampm) =
      $body =~ m"^
        (\d{2})                # numerical month
          -
        (\d{2})                # day
          -
        (\d{2})                # year
          \s+
        (\d\d?):(\d\d)([APap][Mm])  # hour:min AM or PM
      $"x)
    
    #||
    #return;  # unrecognized format
    ;
    
    $day ||= 1;
    # Translate month name to number
    $month ||= 1;
    $month = $MONTH{uc $month}
             || int ($month);
    
    # If the year is missing, we assume first date before the current,
    # because of the formats we support such dates are mostly present
    # on "ls -l" listings.
    unless (defined $year) {
      my $cur_mon;
      ($cur_mon, $year) = (localtime)[4, 5];
      $year += 1900;  $cur_mon++;
      $year-- if $month > $cur_mon;
    } elsif (length($year) < 3) {
      $year = $self->_obvious_year ($year);
    }
    
    # Make sure clock elements are defined
    $hour	= 0 unless defined($hour);
    $minute	= 0 unless defined($minute);
    $second	= 0 unless defined($second);
    
    # Compensate for AM/PM
    if ($ampm) {
      $ampm = uc $ampm;
      $hour = 0 if $hour == 12 && $ampm eq 'AM';
      $hour += 12 if $ampm eq 'PM' && $hour != 12;
    }
    
    my ($zone_sign, $zone_hour, $zone_minute) = $self->_zone_string_to_array ($zone);
    eval '$self->{date_time} = timegm_nocheck 
      ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
       $day, $month-1, $year);';
    $self->{secfrac} = $secfrac;
    $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
  }
  $self;
}

sub zone ($;$) {
  my $self = shift;
  my $newzone = shift;
  if (ref $newzone) {
    $self->{option}->{zone} = $newzone;
  } elsif (length $newzone) {
    $self->{option}->{zone} = [$self->_zone_string_to_array ($newzone)];
  }
  $self->{option}->{zone};
}

## Find "obvious" year
sub _obvious_year ($$) {
  my $self = shift;
  my $year = shift;
  if ($self->{option}->{format} =~ /mail|news/) {
    ## RFC 2822
    if    ( 0 <=$year && $year <   50) {$year += 2000}
    elsif (50 < $year && $year < 1000) {$year += 1900}
  } else {
    ## RFC 2616
      my $cur_yr = (localtime)[5] + 1900;
      my $m = $cur_yr % 100;
      my $tmp = $year;
      $year += $cur_yr - $m;
      $m -= $tmp;
      $year += ($m > 0) ? 100 : -100 if abs($m) > 50;
  }
  $year;
}

=back

=head1 METHODS

=over 4


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

sub set_datetime ($@) {
  my $self = shift;
  my ($year,$month,$day,$hour,$minute,$second,%misc) = @_;
  my ($zone_sign, $zone_hour, $zone_minute)
    = $self->_zone_string_to_array ($misc{zone});
  eval '$self->{date_time} = timegm_nocheck 
    ($second, $minute-($zone_sign*$zone_minute), $hour-($zone_sign*$zone_hour), 
     $day, $month-1, $year);';
  $self->{secfrac} = $misc{secfrac};
  $self->{option}->{zone} = [$zone_sign, $zone_hour, $zone_minute];
}

=head2 $self->second_fraction ([$new_fraction])

Returns or set the decimal fraction of a second.
Value is a string containing of only [0-9]
or empty string.

Note that this implemention is temporary and in the near future
it can be changed.

=cut

sub second_fraction ($;$) {
  my $self = shift;
  my $new_fraction = shift;
  if (defined $new_fraction) {
    $self->{secfrac} = $new_fraction unless $new_fraction =~ /[^0-9]/;
  }
  $self->{secfrac};
}

=item $field-body = $date->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;
  my %option = %{$self->{option}};
  $option{format_parameters} ||= {};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  unless ($option{format_template}) {
    if ($option{format} =~ /mail-rfc2822|news-usefor|mail-rfc822\+rfc1123|news-son-of-rfc1036|mime/) {
      $option{format_template} = '%Wdy(local);, %DD(local); %Mon(local); %YYYY(local); %HH(local);:%TT(local);:%SS(local); %zsign;%zHH;%zTT;%comment(prefix=>" ");';
    } elsif ($option{format} =~ /http/) {
      $option{format_template} = '%Wdy;, %DD; %Mon; %YYYY; %HH;:%TT;:%SS; GMT';
    } elsif ($option{format} =~ /mail-rfc822|news-rfc1036/) {
      $option{format_template} = '%Wdy(local);, %DD(local); %Mon(local); %YY(local); (%YYYY(local);) %HH(local);:%TT(local);:%SS(local); %zsign;%zHH;%zTT;%comment(prefix=>" ");';
    } elsif ($option{format} =~ /news-rfc850/) {
      $option{format_template} = '%Weekday;, %DD;-%Mon;-%YY; %HH;:%TT;:%SS; GMT';
    } elsif ($option{format} =~ /asctime/) {
      $option{format_template} = '%Wdy; %Mon; %DD(pad=>SP); %HH;:%MM;:%SS; %YYYY;';
    #} elsif ($option{format} =~ /date\(1\)/) {
    #  $option{format_template} = '%Wdy; %Mon; %DD(pad=>SP); %HH;:%MM;:%SS; GMT %YYYY;';
    } elsif ($option{format} =~ /un[i*]x/) {	## ;-)
      $option{format_template} = '%unix;';
    } else {	## RFC 3339 (IETF's ISO 8601)
      $option{format_template} = '%YYYY(local);-%MM(local);-%DD(local);T%HH(local);:%TT(local);:%SS(local);%frac(prefix=>.);%zsign;%zHH;:%zTT;%comment(prefix=>" ");';
    }
  }
  my $zone = $option{zone};
  $zone = [ $self->_zone_string_to_array ($zone) ] if not ref $zone && length $zone;
  $zone = [+0, 0, 0] unless ref $zone;
  my $l_time  = $self->{date_time} + $zone->[0] * ($zone->[1] * 60 + $zone->[2]) * 60;
  my $c = '';
  $c = $self->_comment_stringify
    if $option{output_comment} && @{ $self->{comment} } > 0;
  &Message::Util::sprintxf ($option{format_template}, {
  	comment	=> $c,
  	fmt2str	=> ($option{format_macros} || \%FMT2STR),
  	option	=> \%option,
  	time	=> $self->{date_time},
  	time_local	=> $l_time,
  	tm	=> [ gmtime $self->{date_time} ],
  	tm_local	=> [ gmtime $l_time ],
  	secfrac	=> $self->{secfrac},
  	secfrac_local	=> $self->{secfrac},	## Not supported yet
  	%{ $option{format_parameters} },
  });
}
*as_string = \&stringify;
*as_plain_string = \&stringify;
## You should use stringify instead of as_rfc2822_time
sub as_rfc2822_time ($@) {
  shift->stringify (-format => 'mail-rfc2822', @_);
}

sub _zone_string_to_array ($$;$) {
  my $self = shift;
  my $zone = shift;
  return (+1, 0, 0) unless defined $zone;
  my $format = shift;
  my @azone = [+1, 0, 0];
  $zone =~ tr/\x09\x20//d;
    if ($zone =~ /^[^0-9+-]+(?:([+-]?)([0-9]{1,2}))(?::([0-9]{1,2}))?/) {
    ## $ENV{TZ} format, but is not fully supported
      my ($s, $h, $m) = ($1, $2, $3);
      $s ||= '+';  $s =~ tr/+-/-+/;
      @azone = ("${s}1", 0+$h, 0+$m);
    } elsif ($zone =~ /^GMT([+-])([0-9][0-9]?)([0-9][0-9])?/i) {
      @azone = ("${1}1", 0+$2, 0+$3);
    } elsif ($zone =~ /([+-])([0-9][0-9])([0-9][0-9])/) {
      @azone = ("${1}1", $2, $3);
    } elsif ($zone =~ /([+-])([0-9])([0-9][0-9])/) {
      @azone = ("${1}1", $2, $3);
    } elsif ($zone =~ /([+-]?)([0-9]+)(?:[:.-]([0-9]+))?/) {
      @azone = ("${1}1", $2, 0+$3);
    } else { $zone =~ tr/-//d;
      if (ref $ZONE{$zone}) {@azone = @{$ZONE{$zone}}}
      elsif ($zone) {@azone = (-1, 0, 0)}
    }
  # }
  @azone;
}

=item $option-value = $date->option ($option-name)

Gets option value.

=item $date->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=item $clone = $date->clone ()

Returns a copy of the object.

=cut

## option, clone, method_available: Inherited

=head1 EXAMPLE

  use Message::Field::Date;
  
  print Message::Field::Date->new (unix => time, 
    -zone => '+0900'),"\n";	## Thu, 16 May 2002 17:53:44 +0900
  print Message::Field::Date->new (unix => time, 
    -format_template => 	## Century: 21, Year: 02, Month: 05
      'Century: %CC;, Year: %YY;, Month: %MM;'),"\n";
  
  my $field_body = '04 Feb 2002 00:12:33 CST';
  my $field = Message::Field::Date->parse ($field_body);
  
  print "RFC 2822:\t", $field->stringify (-format => 'mail-rfc2822'), "\n";
  print "HTTP preferred:\t", $field->stringify (-format => 'http-1.1'), "\n";
  print "ISO 8601:\t", $field->stringify (-format => 'mail-cpim'), "\n";
  ## RFC 2822:       Mon, 04 Feb 2002 00:12:33 -0600
  ## HTTP preferred: Mon, 04 Feb 2002 06:12:33 GMT
  ## ISO 8601:       2002-02-04T00:12:33-06:00

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
$Date: 2002/12/28 08:45:50 $

=cut

1;
