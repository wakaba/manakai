#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  DIS => q<http://suika.fam.cx/~wakaba/archive/2005/manakai/Util/DIS#>,
  dis => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
};

use Getopt::Long;
use Pod::Usage;
use Storable qw/nstore retrieve/;
my %Opt;
GetOptions (
  'db-base-directory-path=s' => \$Opt{db_base_path},
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

use Message::DOM::DOMMetaImpl;
use Message::Util::DIS;
my $impl = $Message::DOM::DOMImplementationRegistry
                 ->get_dom_implementation
                           ({ExpandedURI q<ManakaiDOM:Minimum> => '3.0',
                             '+' . ExpandedURI q<DIS:Core> => '1.0'})
                 ->get_feature (ExpandedURI q<DIS:Core> => '1.0');
my $parser = $impl->create_dis_parser;

my $db;

if (defined $Opt{input_file_name}) {
  $db = retrieve ($Opt{input_file_name})
     or die "$0: $Opt{input_file_name}: Cannot load";
} else {  ## New database
  $db = $impl->create_dis_database;
}

require Cwd;
my $file_name = Cwd::abs_path ($Opt{file_name});
my $base_path = Cwd::abs_path ($Opt{db_base_path}) if length $Opt{db_base_path};
my $doc = dac_load_module_file ($db, $parser, $file_name, $base_path);
$doc->dis_database ($db);

my $for = $Opt{for};
$for = $doc->module_element->default_for_uri unless length $for;

$db->load_module ($doc, sub ($$$$$$) {
  my ($self, $db, $uri, $ns, $ln, $for) = @_;
  my $doc = $db->get_source_file ($ns.$ln);
  return $doc if $doc; ## Already in database
  
}, for_arg => $for);

use Data::Dumper;
print Dumper $db;

#my $source = dis_load_module_file 
#                 (module_file_name => $Opt{file_name},
#                  For => $Opt{For},
#                  use_default_for => 1,
#                  module_file_search_path => $Opt{module_file_search_path});
#$State->{def_required}->{For}->{$State->{DefaultFor}} ||= 1;
#dis_check_undef_type_and_for () unless $Opt{no_undef_check};
#if (dis_uri_for_match (ExpandedURI q<ManakaiDOM:Perl>, $State->{DefaultFor})) {
#  dis_perl_init ($source, For => $State->{DefaultFor});
#}

nstore $db, $Opt{output_file_name};
exit;

## (db, parser, abs file path, abs base path) -> dis doc obj
sub dac_load_module_file ($$$;$) {
  my ($db, $parser, $file_name, $base_path) = @_;
  require URI::file;
  my $base_uri = length $base_path ? URI::file->new ($base_path.'/')
                                   : 'http://dummy.invalid/';
  my $file_uri = URI::file->new ($file_name)->rel ($base_uri);
  my $dis = $db->get_source_file ($file_uri);
  unless ($dis) {
    open my $file, '<', $file_name or die "$0: $file_name: $!";
    $dis = $parser->parse ({character_stream => $file});
    $db->set_source_file ($file_uri => $dis);
  }
  $dis;
}

__END__

=head1 NAME

...

=head1 OPTIONS

...
