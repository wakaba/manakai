#!/usr/bin/perl -w 
use strict;

use Getopt::Long;
my $dir;
my $out_dir;
my $file_pattern;
my $domtest2perl = 'domtest2perl.pl';
GetOptions (
  'domtest2perl-path=s' => \$domtest2perl,
  'test-directory=s' => \$dir,
  'test-file-pattern=s' => \$file_pattern,
  'output-directory=s' => \$out_dir,
) or die;
$dir or die "$0: test-directory must be specified";
$out_dir or die "$0: output-directory must be specified";
$file_pattern ||= qr/\.xml$/;

opendir my $dirh, $dir or die "$0: $dir: $!";
for (grep {$_ ne 'alltests.xml'} grep /$file_pattern/, readdir $dirh) {
  my $in_file = $dir.'/'.$_;
  my $out_file = $out_dir.'/'.$_.'.pl';
  if (-e $out_file and -C $in_file >= -C $out_file) {
    warn "$0: $_.pl: Skipped; it is newer than $_";
    next;
  }
  my @cmd = ('perl', map ({"-I$_"} @INC),
             $domtest2perl, $in_file,
             '--output-file' => $out_file);
  print STDERR join " ", @cmd, "\n";
  system @cmd and die "$0: $domtest2perl: $@";
  system 'perl', map ({"-I$_"} @INC), '-c', $out_file
    and die "$0: $out_file: $@";
}
