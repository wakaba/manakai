package test::Message::Date;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::More;
use Message::Date;

sub _parse_global_date_and_time_string : Test(8) {
  my $date = Message::Date->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 1;
  is $date->utc_minute, 2;
  is $date->utc_second, 3;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T01:02:03Z';
} # _parse_global_date_and_time_string

sub _to_datetime : Test(3) {
  my $date = Message::Date->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  my $dt = $date->to_datetime;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'UTC';
} # _to_datetime

sub _parse_week_string : Test(14) {
  my $date = Message::Date->parse_week_string ('2010-W01');
  is $date->to_week_string, '2010-W01';
  is $date->utc_year, 2010;
  is $date->utc_month, 1;
  is $date->utc_day, 4;

  $date = Message::Date->parse_week_string ('2010-W51');
  is $date->to_week_string, '2010-W51';
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 20;

  $date = Message::Date->parse_week_string ('2010-W52');
  is $date->to_week_string, '2010-W52';
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 27;

  $date = Message::Date->parse_week_string ('2010-W00');
  is $date, undef;

  $date = Message::Date->parse_week_string ('2010-W53');
  is $date, undef;
} # _parse_week_string

__PACKAGE__->runtests;

1;
