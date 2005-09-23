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
  perl path/to/dac2pm.pl input.dac \
            --create-perl-module="module-uri ModuleName.pm [for-uri]" \
            [--create-perl-module="..." ...]
  perl path/to/dac2pm.pl --help

=head1 DESCRIPTION

The C<dac2pm.pl> script generates Perl modules from a "dac" database file
created by C<dac.pl>.

This script is part of manakai. 

=cut

use strict;
use Message::Util::QName::Filter {
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  Markup => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Markup#>,
  Util => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/>,
};

=head1 OPTIONS

=over 4

=item --enable-assertion / --noenable-assertion (default)

Whether assertion codes should be outputed or not. 

=item --create-perl-module="I<module-uri> I<ModuleName.pm> [I<for-uri>]" (Zero or more)

The C<--create-perl-module> option can be used to specify
I<--module-uri>, I<--output-file-path>, and I<--for> options
once.  Its value is a space-separated triplet of "dis" module name URI,
Perl module file path (environment dependent), and optional
"dis" module "for" URI.

This option can be specified more than once; it would
make multiple Perl module files to be created.  If 
both I<--module-uri> and this options are specified,
I<--module-uri>, I<--output-file-path>, and I<--for>
options are treated as if there is another I<--create-perl-module>
option specified.

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
my %Opt = (
  create_module => [],
);
GetOptions (
  'create-perl-module=s' => sub {
    shift;
    push @{$Opt{create_module}}, [split /\s+/, shift, 3];
  },
  'debug' => \$Opt{debug},
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
$Message::DOM::DOMFeature::DEBUG = 1 if $Opt{debug};

if ($Opt{module_uri}) {
  push @{$Opt{create_module}},
       [$Opt{module_uri}, $Opt{output_file_name}, $Opt{For}];
}

pod2usage (2) unless @{$Opt{create_module}};

sub status_msg ($) {
  my $s = shift;
  $s .= "\n" unless $s =~ /\n$/;
  print STDERR $s;
}

sub status_msg_ ($) {
  my $s = shift;
  print STDERR $s;
}

sub verbose_msg ($) {
  my $s = shift;
  $s .= "\n" unless $s =~ /\n$/;
  print STDERR $s if $Opt{verbose};
}

sub verbose_msg_ ($) {
  my $s = shift;
  print STDERR $s if $Opt{verbose};
}

## TODO: Assertion control

use Message::Util::DIS::DNLite;

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
               ({
                 ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                 '+' . ExpandedURI q<DIS:Core> => '1.0',
                 '+' . ExpandedURI q<Util:PerlCode> => '1.0',
                });
my $pc = $impl->get_feature (ExpandedURI q<Util:PerlCode> => '1.0');
my $di = $impl->get_feature (ExpandedURI q<DIS:Core> => '1.0');

status_msg_ qq<Loading the database "$Opt{file_name}"...>;
my $db = $di->pl_load_dis_database ($Opt{file_name});
status_msg q<done>;

for (@{$Opt{create_module}}) {
  my ($mod_uri, $out_file_path, $mod_for) = @$_;
  
  my $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
  unless ($mod_for) {
    $mod_for = $mod->get_property_text (ExpandedURI q<dis:DefaultFor>, undef);
    if (defined $mod_for) {
      $mod = $db->get_module ($mod_uri, for_arg => $mod_for);
    }
  }
  unless ($mod->is_defined) {
    die qq<$0: Module <$mod_uri> for <$mod_for> is not defined>;
  }

  status_msg_ qq<Generating Perl module from <$mod_uri> for <$mod_for>...>;
  my $pl = $mod->pl_generate_perl_module_file;
  status_msg qq<done>;
  
  my $output;
  defined $out_file_path
      ? (open $output, '>', $out_file_path or die "$0: $out_file_path: $!")
      : ($output = \*STDOUT);
  
  status_msg_ sprintf qq<Writing Perl module %s...>,
                      defined $out_file_path
                        ? q<">.$out_file_path.q<">
                        : 'to stdout';
  print $output $pl->stringify;
  close $output;
  status_msg q<done>;
} # create_module

status_msg_ "Checking undefined resources...";
$db->check_undefined_resource;
status_msg q<done>;

status_msg_ "Closing the database...";
$db->free;
undef $db;
status_msg q<done>;

=head1 SEE ALSO

L<lib/Message/Util/DIS.dis> - The <QUOTE::dis> object implementation.

L<lib/Message/Util/DIS/Perl.dis> - The <QUOTE::dis> object implementation,
submodule for Perl modules.

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

1; # $Date: 2005/09/23 18:24:52 $
