#!/usr/bin/perl -w 
use strict;

=head1 NAME

dac2pm - Generating Perl Module from "dac" File

=head1 SYNOPSIS

  perl path/to/dac2pm.pl input.dac \
            --module-uri=module-uri [--for=for-uri] [options] > ModuleName.pm
  perl path/to/dac2pm.pl input.dac \
            --module-uri=module-uri [--for=for-uri] [options] \
            --output-file-path=ModuleName.pm
  perl path/to/dac2pm.pl --help

=head1 DESCRIPTION

The C<dac2pm> script generates a Perl module from a "dac" file.

This script is part of manakai. 

=cut

use strict;
use Message::Util::DIS;
use Message::Util::QName::Filter {
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DISCore => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Core#>,
  DISLang => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Lang#>,
  DISPerl => q<http://suika.fam.cx/~wakaba/archive/2004/dis/Perl#>,
  disPerl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis--Perl-->,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMEvents => q<http://suika.fam.cx/~wakaba/archive/2004/dom/events#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  DOMXML => q<http://suika.fam.cx/~wakaba/archive/2004/dom/xml#>,
  DX => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/Error/DOMException#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Markup => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup#>,
  MDOMX => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  pc => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/PerlCode#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
  swcfg21 => q<http://suika.fam.cx/~wakaba/archive/2005/swcfg21#>,
  TreeCore => q<>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

=head1 OPTIONS

=over 4

=item --enable-assertion / --noenable-assertion (default)

Whether assertion codes should be outputed or not. 

=item --for=I<for-uri> (Optional)

Specifies the "For" URI reference for which the outputed module is. 
If this parameter is ommitted, the default "For" URI reference 
for the module specified by the C<dis:DefaultFor> attribute
of the C<dis:Module> element, if any, or C<ManakaiDOM:all> is assumed. 

=item --help

Shows the help message. 

=item --module-uri=I<module-uri>

A URI reference that identifies a module from which a Perl
module file is generated.  This argument is I<required>.

=item --output-file-path=I<perl-module-file-path> (default: the standard output)

A platform-dependent file path to which the Perl module
is written down.

=item --verbose / --noverbose (default)

Whether a verbose message mode should be selected or not. 

=back

=cut

use Getopt::Long;
use Pod::Usage;
my %Opt;
GetOptions (
  'enable-assertion!' => \$Opt{outputAssertion},
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'module-uri=s' => \$Opt{module_uri},
  'output-file-path=s' => \$Opt{output_file_name},
  'verbose!' => $Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage (2) unless $Opt{module_uri};

## TODO: Assertion control

## TODO: Verbose mode

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
               ({
                 ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                 '+' . ExpandedURI q<DIS:Core> => '1.0',
                 '+' . ExpandedURI q<Util:PerlCode> => '1.0',
                });
my $pc = $impl->get_feature (ExpandedURI q<Util:PerlCode> => '1.0');
my $di = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0');

print STDERR qq<Loading the database "$Opt{file_name}"...>;
my $db = $di->pl_load_dis_database ($Opt{file_name});
print STDERR "done\n";

my $mod = $db->get_module ($Opt{module_uri}, for_arg => $Opt{For});
unless ($Opt{For}) {
  $Opt{For} = $mod->get_property_text (ExpandedURI q<dis:DefaultFor>, undef);
  if (defined $Opt{For}) {
    $mod = $db->get_module ($Opt{module_uri}, for_arg => $Opt{For});
  } else {
    my $el = $mod->source_element;
    if ($el) {
      $Opt{For} = $el->default_for_uri;
      $mod = $db->get_module ($Opt{module_uri}, for_arg => $Opt{For});
    }
  }
}
unless ($mod->is_defined) {
  die qq<$0: Module <$Opt{module_uri}> for <$Opt{For}> is not defined>;
}

my $pl = $mod->pl_generate_perl_module_file;

my $output;
defined $Opt{output_file_name} 
      ? (open $output, '>', $Opt{output_file_name}
           or die "$0: $Opt{output_file_name}: $!")
      : ($output = \*STDOUT);

printf STDERR qq<Writing file "%s"...>,
  defined $Opt{output_file_name} ? $Opt{output_file_name} : '';
print $output $pl->stringify;
close $output;
print STDERR "done\n";

print STDERR "Checking undefined resources...";
$db->check_undefined_resource;
print STDERR "done\n";

print STDERR "Closing the database...";
$db->free;
undef $db;
print STDERR "done\n";

=head1 SEE ALSO

L<lib/Message/Util/DIS.dis> - The <QUOTE::dis> object implementation.

L<lib/Message/Util/PerlCode.dis> - The Perl code generator.

L<lib/manakai/DISCore.dis> - The definition for the "dis" format. 

L<lib/manakai/DISPerl.dis> - The definition for the "dis" Perl-specific 
vocabulary. 

L<bin/dac.pl> - The "dac" database generator.

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2005/09/19 16:17:50 $
