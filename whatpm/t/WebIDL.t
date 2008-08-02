#!/usr/bin/perl
use strict;

my $DEBUG = $ENV{DEBUG};

my $dir_name;
my $test_dir_name;
BEGIN {
  $test_dir_name = 't/';
  $dir_name = 't/webidl/';
}

use Test;
BEGIN { plan tests => 1920 }

require Whatpm::WebIDL;

for my $file_name (grep {$_} split /\s+/, qq[
                      ${dir_name}webidl-defs.dat
                      ${dir_name}webidl-interface.dat
                     ]) {
  open my $file, '<', $file_name
    or die "$0: $file_name: $!";
  print "# $file_name\n";

  my $test;
  my $mode = 'data';
  my $escaped;
  while (<$file>) {
    s/\x0D\x0A/\x0A/;
    if (/^#data$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
      undef $escaped;
    } elsif (/^#data escaped$/) {
      undef $test;
      $test->{data} = '';
      $mode = 'data';
      $escaped = 1;
    } elsif (/^#errors$/) {
      $test->{errors} = [];
      $mode = 'errors';
      $test->{data} =~ s/\x0D?\x0A\z//;       
      $test->{data} =~ s/\\u([0-9A-Fa-f]{4})/chr hex $1/ge if $escaped;
      $test->{data} =~ s/\\U([0-9A-Fa-f]{8})/chr hex $1/ge if $escaped;
      undef $escaped;
    } elsif (/^#document$/) {
      $test->{document} = '';
      $mode = 'document';
      undef $escaped;
    } elsif (/^#document escaped$/) {
      $test->{document} = '';
      $mode = 'document';
      $escaped = 1;
    } elsif (defined $test->{document} and /^$/) {
      $test->{document} =~ s/\\u([0-9A-Fa-f]{4})/chr hex $1/ge if $escaped;
      $test->{document} =~ s/\\U([0-9A-Fa-f]{8})/chr hex $1/ge if $escaped;
      test ($test);
      undef $test;
    } elsif (defined $test->{data} and /^$/) {
      test ($test);
      undef $test;
    } else {
      if ($mode eq 'data' or $mode eq 'document') {
        $test->{$mode} .= $_;
      } elsif ($mode eq 'errors') {
        tr/\x0D\x0A//d;
        push @{$test->{errors}}, $_;
      }
    }
  }
  test ($test);
}

sub test ($) {
  my $test = shift;

  $test->{document} =~ s/^\| //;
  $test->{document} =~ s/[\x0D\x0A]\| /\x0A/g;

  my @errors;

  my $onerror = sub {
    my %opt = @_;
    push @errors, join ';',
      ($opt{node} ? $opt{node}->get_user_data ('manakai_source_line') || $opt{line} : $opt{line} . '.' . $opt{column}),
      $opt{type}, $opt{level};
  };

  my $p = Whatpm::WebIDL::Parser->new;
  my $idl = $p->parse_char_string ($test->{data}, $onerror);

  if (defined $test->{errors}) {
    $idl->check ($onerror);

    ok join ("\n", sort {$a cmp $b} @errors),
        join ("\n", sort {$a cmp $b} @{$test->{errors}}), $test->{data};
  }

  if (defined $test->{document}) {
    ok $idl->idl_text, $test->{document}, $test->{data};
  }
} # test

## License: Public Domain.
## $Date: 2008/08/02 06:03:26 $
