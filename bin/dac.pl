#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  swcfg21 => q<http://suika.fam.cx/~wakaba/archive/2005/swcfg21#>,
};

use Getopt::Long;
use Pod::Usage;
my %Opt = ();
GetOptions (
  'db-base-directory-path=s' => \$Opt{db_base_path},
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'input-db-file-name=s' => \$Opt{input_file_name},
  'output-file-name=s' => \$Opt{output_file_name},
  'search-path|I=s' => sub {
    shift;
    my @value = split /\s+/, shift;
    while (my ($ns, $path) = splice @value, 0, 2, ()) {
      unless (defined $path) {
        die qq[$0: Search-path parameter without path: "$ns"];
      }
      push @{$Opt{input_search_path}->{$ns} ||= []}, $path;
    }
  },
  'search-path-catalog-file-name=s' => sub {
    shift;
    require File::Spec;
    my $path = my $path_base = shift;
    $path_base =~ s#[^/]+$##;
    $Opt{search_path_base} = $path_base;
    open my $file, '<', $path or die "$0: $path: $!";
    while (<$file>) {
      if (s/^\s*\@//) {     ## Processing instruction
        my ($target, $data) = split /\s+/;
        if ($target eq 'base') {
          $Opt{search_path_base} = File::Spec->rel2abs ($data, $path_base);
        } else {
          die "$0: $target: Unknown target";
        }
      } elsif (/^\s*\#/) {  ## Comment
        #
      } elsif (/\S/) {      ## Catalog entry
        s/^\s+//;
        my ($ns, $path) = split /\s+/;
        push @{$Opt{input_search_path}->{$ns} ||= []},
             File::Spec->rel2abs ($path, $Opt{search_path_base});
      }
    }
    ## NOTE: File paths with SPACEs are not supported
    ## NOTE: Future version might use file: URI instead of file path.
  },
  'undef-check!' => \$Opt{no_undef_check},
  'verbose!' => $Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{output_file_name};
$Opt{no_undef_check} = defined $Opt{no_undef_check}
                         ? $Opt{no_undef_check} ? 0 : 1 : 0;

use Message::Util::DIS;

my $impl = $Message::DOM::ImplementationRegistry->get_implementation
                           ({ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                             '+' . ExpandedURI q<DIS:Core> => '1.0'})
                 ->get_feature (ExpandedURI q<DIS:Core> => '1.0');
my $parser = $impl->create_dis_parser;

my $db;

if (defined $Opt{input_file_name}) {
  $db = $impl->pl_load_dis_database ($Opt{input_file_name});
} else {  ## New database
  $db = $impl->create_dis_database;
}

require Cwd;
my $file_name = Cwd::abs_path ($Opt{file_name});
my $base_path = Cwd::abs_path ($Opt{db_base_path}) if length $Opt{db_base_path};
my $doc = dac_load_module_file ($db, $parser, $file_name, $base_path);
$doc->dis_database ($db);

my $for = $Opt{For};
$for = $doc->module_element->default_for_uri unless length $for;
$db->get_for ($for)->is_referred ($doc);
print STDERR qq<Loading definition of "$file_name" for <$for>...\n>;

my $ResourceCount = 0;
$db->load_module ($doc, sub ($$$$$$) {
  my ($self, $db, $uri, $ns, $ln, $for) = @_;
  print STDERR qq<\n>;
  print STDERR qq<Loading definition of "$ln" for <$for>...\n>;
  $ResourceCount = 0;

  ## -- Already in database
  my $doc = $db->get_source_file ($ns.$ln);
  return $doc if $doc;
  
  ## -- Finds the source file
  require File::Spec;
  for my $dir ('.', @{$Opt{input_search_path}->{$ns}||[]}) {
    my $name = Cwd::abs_path
                  (File::Spec->canonpath
                       (File::Spec->catfile ($dir, $ln.'.dis')));
    if (-f $name) {
      my $doc = dac_load_module_file ($db, $parser, $name, $base_path);
      $doc->dis_database ($db);
      return $doc;
    }
  }

  ## -- Not found
  return undef;
}, for_arg => $for, on_resource_read => sub ($$) {
  if ((++$ResourceCount % 10) == 0) {
    print STDERR "*";
    print STDERR " " if ($ResourceCount % (10 * 10)) == 0;
    print STDERR "\n" if ($ResourceCount % (10 * 50)) == 0;
  }
});

print STDERR "\n";

## TODO:
if ($db->can('read_properties')) {

print STDERR qq<Reading properties...\n>;
$ResourceCount = 0;
$db->read_properties (on_resource_read => sub ($$) {
  if ((++$ResourceCount % 10) == 0) {
    print STDERR "*";
    print STDERR " " if ($ResourceCount % (10 * 10)) == 0;
    print STDERR "\n" if ($ResourceCount % (10 * 50)) == 0;
  }
});
print STDERR "\ndone\n";

}

print STDERR qq<Writing file "$Opt{output_file_name}"...>;
$db->pl_store ($Opt{output_file_name});
print STDERR "done\n";

unless ($Opt{no_undef_check}) {
  print STDERR "Checking undefined resources...";
  $db->check_undefined_resource;
  print STDERR "done\n";
}

print STDERR "Closing the database...";
$db->free;
undef $db;
print STDERR "done\n";

exit;

END {
  $db->free if $db;
}

## (db, parser, abs file path, abs base path) -> dis doc obj
sub dac_load_module_file ($$$;$) {
  my ($db, $parser, $file_name, $base_path) = @_;
  require URI::file;
  my $base_uri = length $base_path ? URI::file->new ($base_path.'/')
                                   : 'http://dummy.invalid/';
  my $file_uri = URI::file->new ($file_name)->rel ($base_uri);
  my $dis = $db->get_source_file ($file_uri);
  unless ($dis) {
    print STDERR qq<Opening file <$file_uri>...>;
    open my $file, '<', $file_name or die "$0: $file_name: $!";
    $dis = $parser->parse ({character_stream => $file});
    $db->set_source_file ($file_uri => $dis);
    $dis->flag (ExpandedURI q<swcfg21:fileName> => $file_uri);
    print STDERR qq<done\n>;
  }
  $dis;
}

__END__

=head1 NAME

dac - Creating "dac" Database File from "dis" Source Files

=head1 SYNOPSIS

  perl path/to/dac.pl ...
  perl path/to/dac.pl --help

=head1 DESCRIPTION

The C<dac.pl> script loads "dis" source files and
writes a "dac" database file.

This script is part of manakai.

=head1 OPTIONS

...

=head1 SEE ALSO

L<bin/dac2pm.pl> - Generating Perl module from "dac" file.

L<lib/Message/Util/DIS.dis> - The actual implementation
of the "dis" interpretation.

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
