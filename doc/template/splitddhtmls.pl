#!/usr/bin/perl 
use strict;

my $out = \*STDOUT;

my $lang2suffix = {
};
my $type2suffix = {
  'text/html' => '.html',
  'application/xhtml+xml' => '.xhtml',
};

sub fs ($) {
  my $s = shift;
  $s =~ s/([^\w.])/_/g;
  $s;
}

sub pdir ($) {
  my @dir = split m#/#, shift;
  pop @dir;
  use File::Path;
  mkpath ([join '/', @dir], 1, 0711);
}

while (<>) {
  if (/^<!\[\[<!\[\[<><\?\?>--<\?\?><>\]\]>\]\]>$/) {
    my %data;
    I: while (<>) {
      if (s/^<>([^:]+):\s*//) {
        $data{$1} = $_;
        $data{$1} =~ s/\s+$//;
      } else {
        last I;
      }
    }
    my $filename = $data{Name};
    my $lang = fs ($lang2suffix->{$data{Lang}} or $data{Lang} ? '.' . $data{Lang} : '');
    $filename .= $lang unless $filename =~ /\b\Q$lang\E\b/;
    my $type = fs ($type2suffix->{$data{Type}} or $data{Type} ? '.' . $data{Type} : '');
    $filename .= $type unless $filename =~ /\b\Q$type\E\b/;
    pdir ($filename);
    open $out, '>', $filename or die "$0: $ARGV Line $.: $filename: $!";
  } else {
    print $out $_;
  }
}

__END__

=head1 AUTHOR

Wakaba <w@suika.fam.cx>

=head1 LICENSE

Public domain.

=cut
