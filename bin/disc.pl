#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
};

use Getopt::Long;
use Pod::Usage;
use Storable qw/nstore retrieve/;
my %Opt;
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'input-cdis-file-name=s' => \$Opt{input_file_name},
  'output-file-name=s' => \$Opt{output_file_name},
  'search-path|I=s' => ($Opt{module_file_search_path} = []),
  'undef-check!' => \$Opt{no_undef_check},
  'verbose!' => $Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{output_file_name};
$Opt{no_undef_check} = defined $Opt{no_undef_check}
                         ? $Opt{no_undef_check} ? 0 : 1 : 0;
push @{$Opt{module_file_search_path}}, '.';

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}

eval q{
  sub impl_msg ($;%) {
    warn shift () . "\n";
  }
} unless $Opt{verbose};

our $State;
if (defined $Opt{input_file_name}) {
  $State = retrieve ($Opt{input_file_name})
     or die "$0: $Opt{input_file_name}: Cannot load";
}
$State->{DefaultFor} = $Opt{For} if defined $Opt{For};
my $source = dis_load_module_file 
                 (module_file_name => $Opt{file_name},
                  For => $Opt{For},
                  use_default_for => 1,
                  module_file_search_path => $Opt{module_file_search_path});
$State->{def_required}->{For}->{$State->{DefaultFor}} ||= 1;
dis_check_undef_type_and_for () unless $Opt{no_undef_check};
if (dis_uri_for_match (ExpandedURI q<ManakaiDOM:Perl>, $State->{DefaultFor})) {
  dis_perl_init ($source, For => $State->{DefaultFor});
}

nstore $State, $Opt{output_file_name};

__END__

=head1 NAME

disc - dis compiler

=head1 SYNOPSIS

  perl disc.pl Source.dis --output-file-name=s.tmp [options...]
  perl disc.pl --help

=head1 DESCRIPTION

C<disc> is a disc compiler that read "dis" files (a dis file specified 
as a command-line argument and other dis files, if any, referred from that file),
convert it to the internal object and write it down to a file. 
The compiled file can be used as an input for dis to some format converter 
such as L<dis2pm> or L<dis2rdf>. 

Note: Compiled dis files depend on the version of dis utilities.  

=head2 OPTIONS

=over 4

=item I<Source.dis>

A dis file that is first parsed.

=item --help

Show the help message.

=item --for=I<ForURI>

A "For" URI referenece that is first set.  This is optional; 
if missing, the C<Module/DefaultFor> attribute of I<Source.dis> 
is used.

=item --input-cdis-file-name=I<s.orig>

A compiled dis file that is loaded before the parse of I<Source.dis> 
as base of new compiled dis.  In other word, I<Source.dis> (and 
other included files) are merged to I<s.orig> data.

=item --output-file-name=I<s.tmp>

A file name the result compiled dis is written to.

=back

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

