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
    warn "$_.pl: Skipped - it is newer than source\n";
    next;
  }
  my @cmd = ('perl', map ({"-I$_"} @INC),
             $domtest2perl, $in_file,
             '--output-file' => $out_file);
  #print STDERR join " ", @cmd, "\n";
  print STDERR $in_file, "\n";
  print STDERR '-> ' . $out_file, "\n";
  system @cmd and die "$0: $domtest2perl: $@";
  system 'perl', map ({"-I$_"} @INC), '-c', $out_file
    and die "$0: $out_file: $@";
}

1;

__END__

=head1 NAME

domts2perl - Generates Perl Test Code from DOM Test Suite

=head1 SYNOPSIS

  perl path/to/domts2perl.pl --test-directory=path/to/source/xml/directory/ \
           --output-directory=path/to/result/pl/directory/ \
           --domtest2perl=path/to/domts2perl/pl

=head1 OPTIONS

=over 4

=item --domtest2perl=I<path>

Path to the F<domtest2perl.pl> to convert each XMl file to Perl code. 

=item --output-directory=I<path>

Path to result Perl code directory. 

=item --test-directory=I<path>

Path to source XML files in the package of the DOM Test Suite. 

=back

=head1 SEE ALSO

I<Document Object Model (DOM) Conformance Test Suites>,
<http://www.w3.org/DOM/Test/>.

F<domtest2perl.pl>

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

