#!/usr/bin/perl -w 
use strict;

use Getopt::Long;
my $dir;
my $out_dir;
my $file_pattern;
GetOptions (
  'test-directory=s' => \$dir,
  'test-file-pattern=s' => \$file_pattern,
  'output-directory=s' => \$out_dir,
);
$dir or die "$0: test-directory must be specified";
$out_dir or die "$0: output-directory must be specified";
$file_pattern ||= qr/\.xml$/;

opendir my $dirh, $dir or die "$0: $dir: $!";
for (grep {$_ ne 'alltests.xml'} grep /$file_pattern/, readdir $dirh) {
  my $out_file = $out_dir.'/'.$_.'.pl';
  my @cmd = ('perl', map ({"-I$_"} @INC),
             'domtest2perl.pl', $dir.'/'.$_,
             '--output-file' => $out_file);
  print STDERR join " ", @cmd, "\n";
  system @cmd and die "$0: domtest2perl.pl: $@";
  system 'perl', map ({"-I$_"} @INC), '-c', $out_file
    and die "$0: $out_file: $@";
}
