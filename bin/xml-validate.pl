#!/usr/bin/perl
use strict;
require Getopt::Long;
require Message::Markup::XML::EntityManager;
require Message::Markup::XML::Parser;
my %src = (
	catalog	=> 'entities.xcat',
	catalog_dtd	=> 'dtd/xcatalog.dtd',
	output_parsed_document => 1,
	remove_reference => 1,
);
$src{output_charset} = $1 if $main::ENV{LANG} =~ /\.(\w+)/;
Getopt::Long::GetOptions (
	q(base=s)	=> \$src{base},
	q(catalog=s)	=> \$src{catalog},
	q(catalog-dtd=s)	=> \$src{catalog_dtd},
	q(check-error-page!)	=> \$src{check_error_page},
	## TODO: help
	q(output-charset=s)	=> \$src{output_charset},
	q(output-parsed-document!)	=> \$src{output_parsed_document},
	q(remove-reference!)	=> \$src{remove_reference},
	q(stop-with-fatal!)	=> \$src{stop_with_fatal},
);
$src{uri} = shift or die "$0: No URI specified";
binmode STDOUT;
binmode STDERR;
binmode STDOUT, ':encoding('.$src{output_charset}.')' if $src{output_charset};

require Cwd;
require URI::file;
my $cwd = URI::file->new (Cwd::getcwd ().'/');
$src{uri} = URI->new ($src{uri})->abs ($cwd);
$src{catalog} = URI->new ($src{catalog})->abs ($cwd) if $src{catalog};
$src{catalog_dtd} = URI->new ($src{catalog_dtd})->abs ($cwd) if $src{catalog_dtd};

my $catalog;
my $parser = Message::Markup::XML::Parser->new (option => {
	uri_resolver => sub {
		my ($self, $parser, $decl, $p) = @_;
		unless (defined $catalog) {
		  require Message::Markup::XML::Catalog;
		  $catalog = Message::Markup::XML::Catalog->new;
		  $catalog->option (uri_resolver => sub {
		    my ($self, $parser, $decl, $p) = @_;
		    print STDERR "Retriving catalog entity <$p->{uri}>...\n";
		    return 1;
		  });
		  $catalog->option (dtd_of_xml_catalog_1_0 => $src{catalog_dtd});
		}
		$p->{uri} = $catalog->resolve_external_id ({public => $p->{PUBLIC},
		                                            system => $p->{uri}},
		                                           catalogs => [$src{catalog}],
		                                           return_default => 1);
		print STDERR "Retriving external entity <$p->{uri}>...\n";
		return 1;
	},
	error_handler => sub {
		my ($caller, $o, $error_type, $error_msg) = @_;
		require Carp;
		if ($src{stop_with_fatal}
		 && {qw/fatal 1 wfc 1/}->{$error_type->{level}}) {
		  $Carp::CarpLevel = 1;
		  Carp::croak ('{'.$error_type->{level}.'} '.$error_msg);
		} else {
		  $Carp::CarpLevel = 1;
		  Carp::carp ('{'.$error_type->{level}.'} '.$error_msg);
		}
		return 0;
	},
});

my $p = {uri => $src{uri}, base_uri => $src{base_uri}};
my $o = {uri => $src{uri}, entity_type => 'document_entity'};
my $em = Message::Markup::XML::EntityManager->new;
$em->option (uri_resolver => $parser->option ('uri_resolver'));
$em->option (error_handler => $parser->option ('error_handler'));
$em->default_uri_resolver ($parser, 'Message::Markup::XML', $p, $o,
                           accept_error_page => $src{check_error_page},
                           dont_parse_text_declaration => 1);

if ($p->{error}->{no_data}) {
  Message::Markup::XML::Error::raise ($parser, $o, type => 'ERR_EXT_ENTITY_NOT_FOUND',
                       t => ['#document', $p->{uri}, $p->{error}->{reason_text}]);
} else {
  $parser->option (document_entity_base_uri => $p->{base_uri});
  my $doc = $parser->parse_text ($p->{text}, $o, entMan => $em);
  if ($src{output_parsed_document}) {
    if ($src{remove_reference}) {
      $doc->remove_references;
      $doc->merge_external_subset;
    }
    print $doc;
  }
}
