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
  'debug' => \$Opt{debug},
  'dis-file-suffix=s' => \$Opt{dis_suffix},
  'daem-file-suffix=s' => \$Opt{daem_suffix},
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
  'verbose!' => \$Opt{verbose},
) or pod2usage (2);
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{output_file_name};
$Opt{no_undef_check} = defined $Opt{no_undef_check}
                         ? $Opt{no_undef_check} ? 0 : 1 : 0;
$Opt{dis_suffix} = '.dis' unless defined $Opt{dis_suffix};
$Opt{daem_suffix} = '.daem' unless defined $Opt{daem_suffix};
$Message::DOM::DOMFeature::DEBUG = 1 if $Opt{debug};
require Error;
$Error::Debug = 1 if $Opt{debug};
$Message::Util::Error::VERBOSE = 1 if $Opt{verbose};

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

my $start_time;
BEGIN { $start_time = time }

use Message::Util::DIS::DNLite;

my $limpl = $Message::DOM::ImplementationRegistry->get_implementation
                           ({ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                             '+' . ExpandedURI q<DIS:DNLite> => '1.0'});
my $impl = $limpl->get_feature (ExpandedURI q<DIS:Core> => '1.0');
my $parser = $impl->create_dis_parser;
our $DNi = $impl->get_feature (ExpandedURI q<DIS:DNLite> => '1.0');

my $db;

if (defined $Opt{input_file_name}) {
  status_msg_ qq<Loading database "$Opt{input_file_name}"...>;
  $db = $impl->pl_load_dis_database ($Opt{input_file_name}, sub ($$) {
    my ($db, $mod) = @_;
    my $ns = $mod->namespace_uri;
    my $ln = $mod->local_name;
    verbose_msg qq<Database module <$ns$ln> is requested>;
    my $name = dac_search_file_path_stem ($ns, $ln, $Opt{daem_suffix});
    if (defined $name) {
      return $name.$Opt{daem_suffix};
    } else {
      return undef;
    }
  });
  status_msg qq<done>;
} else {  ## New database
  $db = $impl->create_dis_database;
}

require Cwd;
my $file_name = Cwd::abs_path ($Opt{file_name});
$Opt{db_base_path} = Cwd::abs_path ($Opt{db_base_path})
  if length $Opt{db_base_path};
my $doc = dac_load_module_file ($db, $parser, $file_name, $Opt{db_base_path});

my $for = $Opt{For};
$for = $doc->module_element->default_for_uri unless length $for;
$db->get_for ($for)->is_referred ($doc);
status_msg qq<Loading module in file "$file_name" for <$for>...>;

my $ResourceCount = 0;
$db->load_module ($doc, sub ($$$$$$) {
  my ($self, $db, $uri, $ns, $ln, $for) = @_;
  status_msg '';
  status_msg qq<Loading module "$ln" for <$for>...>;
  $ResourceCount = 0;

  ## -- Already in database
  my $doc = $db->get_source_file ($ns.$ln);
  return $doc if $doc;
  
  ## -- Finds the source file
  my $name = dac_search_file_path_stem ($ns, $ln, $Opt{dis_suffix});
  if (defined $name) {
    return dac_load_module_file
             ($db, $parser, $name.$Opt{dis_suffix}, $Opt{db_base_path});
  }

  ## -- Not found
  return undef;
}, for_arg => $for, on_resource_read => sub ($$) {
  if ((++$ResourceCount % 10) == 0) {
    status_msg_ "*";
    status_msg_ " " if ($ResourceCount % (10 * 10)) == 0;
    status_msg '' if ($ResourceCount % (10 * 50)) == 0;
  }
});


## Removes reference from document to database
our @Document;
for my $dis (@Document) {
  $dis->unlink_from_document;
  $dis->dis_database (undef);
}

status_msg '';

status_msg qq<Reading properties...>;
$ResourceCount = 0;
$db->read_properties (on_resource_read => sub ($$) {
  if ((++$ResourceCount % 10) == 0) {
    status_msg_ "*";
    status_msg_ " " if ($ResourceCount % (10 * 10)) == 0;
    status_msg '' if ($ResourceCount % (10 * 50)) == 0;
  }
});
status_msg '';
status_msg "done";

status_msg_ qq<Writing file "$Opt{output_file_name}"...>;
$db->pl_store ($Opt{output_file_name}, sub ($$) {
  my ($db, $mod) = @_;
  my $ns = $mod->namespace_uri;
  my $ln = $mod->local_name;
  my $name = dac_search_file_path_stem ($ns, $ln, $Opt{daem_suffix});
  if (defined $name) {
    $name .= $Opt{daem_suffix};
  } elsif (defined ($name = dac_search_file_path_stem
                              ($ns, $ln, $Opt{dis_suffix}))) {
    $name .= $Opt{daem_suffix};
  } else {
    $name = Cwd::abs_path
              (File::Spec->canonpath
                 (File::Spec->catfile
                    (defined $Opt{input_search_path}->{$ns}->[0]
                       ? $Opt{input_search_path}->{$ns}->[0] : '.',
                     $ln.$Opt{daem_suffix})));
  }
  verbose_msg qq<Database module <$ns$ln> is written to "$name">;
  return $name;
});
status_msg "done";

unless ($Opt{no_undef_check}) {
  status_msg_ "Checking undefined resources...";
  $db->check_undefined_resource;
  print STDERR "done\n";
}

status_msg_ "Closing the database...";
$db->free;
undef $db;
status_msg "done";

undef $DNi;

{
  use integer;
  my $time = time - $start_time;
  status_msg sprintf qq<%d'%02d''>, $time / 60, $time % 60;
}
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
    status_msg_ qq<Opening source file <$file_uri>...>;
    open my $file, '<', $file_name or die "$0: $file_name: $!";
    $dis = $parser->parse ({character_stream => $file});
    $dis->flag (ExpandedURI q<swcfg21:fileName> => $file_uri);
    $dis->dis_database ($db);

    my $mod = $dis->module_element;
    if ($mod) {
      my $qn = $mod->get_attribute_ns (ExpandedURI q<dis:>, 'QName');
      if ($qn) {
        my $prefix = $qn->value;
        $prefix =~ s/^[^:|]*[:|]\s*//;
        $prefix =~ s/\s+$//;
        unless (defined $dis->lookup_namespace_uri ($prefix)) {
          $dis->add_namespace_binding ($prefix => $mod->defining_namespace_uri);
        }
      }
    }

    my $old_dis = $dis;
    status_msg_ qq<...>;
    $dis = $DNi->convert_dis_document_to_dnl_document
      ($old_dis, database_arg => $db);
    push @Document, $dis;
    $old_dis->free;

    $db->set_source_file ($file_uri => $dis);
    status_msg qq<done>;
  }
  $dis;
}

sub dac_search_file_path_stem ($$$) {
  my ($ns, $ln, $suffix) = @_;
  require File::Spec;
  for my $dir ('.', @{$Opt{input_search_path}->{$ns}||[]}) {
    my $name = Cwd::abs_path
        (File::Spec->canonpath
         (File::Spec->catfile ($dir, $ln)));
    if (-f $name.$suffix) {
      return $name;
    }
  }
  return undef;
} # dac_search_file_path_stem;

__END__

=head1 NAME

dac.pl - Creating "dac" Database File from "dis" Source Files

=head1 SYNOPSIS

  perl path/to/dac.pl [--input-db-file-name=input.dac] \
                      --output-file-name=out.dac [options...] \
                      input.dis
  perl path/to/dac.pl --help

=head1 DESCRIPTION

This script, C<dac.pl>, compiles "dis" source files into "dac"
database file.  The generated database file can be used
in turn to generate Perl module file, for example, by another
script C<dac2pm.pl> or can be used to create larger database
by specifying its file name as the C<--input-db-file-name>
argument of another C<dac.pl> execution.

This script is part of manakai.

=head1 OPTIONS

=over 4

=item I<input.dis> (Required)

The unnamed option specifies a file name path of the source "dis" file
from which a database is created.  This option is required.

=item C<--input-db-file-name=I<file-name>> (Default: none)

A file path of the base database.  This option is optional; if this
option is specified, the database file is loaded first
and then I<input.dis> file is loaded in the context of it.
Otherwise, a new database is created.

=item C<--output-file-name=I<file-name>> (Required)

The 

=back

=head1 SEE ALSO

L<bin/dac2pm.pl> - Generating Perl module from "dac" file.

L<lib/Message/Util/DIS.dis> - The actual implementation
of the "dis" interpretation.

=head1 LICENSE

Copyright 2004-2005 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
