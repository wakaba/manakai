#!/usr/bin/perl -w 
use strict;

use Getopt::Long;
use Pod::Usage;
my %Opt;
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'output-for' => \$Opt{output_for},
  'output-module' => \$Opt{output_module},
  'output-type' => \$Opt{output_type},
) or pod2usage (2);
if ($Opt{help}) {
  pod2usage (0);
  exit;
}

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}
sub n3_literal ($) {
  my $s = shift;
  qq<"$s">;
}
our $State;
our $result = new manakai::n3;

$Opt{file_name} = shift;

$State->{DefaultFor} = $Opt{For};
my $source = dis_load_module_file (module_file_name => $Opt{file_name},
                                   for => $Opt{For},
                                   use_default_for => 1);
$State->{for_def_required}->{$State->{DefaultFor}} ||= 1;

dis_check_undef_type_and_for ();

my $primary = $result->get_new_anon_id;
$result->add_triple ($primary =>ExpandedURI q<d:module>=> $State->{module})
                if $Opt{output_module};
$result->add_triple ($primary =>ExpandedURI q<d:DefaultFor> => $State->{DefaultFor})
                if $Opt{output_for};

if ($Opt{output_module}) {
for (keys %{$State->{Module}}) {
  my $mod = $State->{Module}->{$_};
  if ($_ eq $mod->{Namespace}) {
    $result->add_triple ($mod->{Namespace} =>ExpandedURI q<rdf:type>=> ExpandedURI q<d:Module>);
    $result->add_triple ($mod->{Namespace} =>ExpandedURI q<d:Name>=>
                         n3_literal $mod->{Name});
    $result->add_triple ($mod->{Namespace} =>ExpandedURI q<d:FileName>=>
                         n3_literal $mod->{FileName})
      if defined $mod->{FileName};
    for (@{$mod->{require_module}||[]}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<d:Require>=> $_);
    }
  } else {
    $result->add_triple ($_ =>ExpandedURI q<owl:sameAs>=> $mod->{Namespace});
  }
}}

if ($Opt{output_for}) {
for (keys %{$State->{For}}) {
  my $mod = $State->{For}->{$_};
  if ($_ eq $mod->{Namespace}) {
    for (@{$mod->{Type}}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<rdf:type>=> $_);
    }
    for (@{$mod->{ISA}}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<rdfs:subClassOf>=> $_);
    }
    for (@{$mod->{Implement}}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<d:Implement>=> $_);
    }
  } else {
    $result->add_triple ($_ =>ExpandedURI q<owl:sameAs>=> $mod->{Namespace});
  }
}}

if ($Opt{output_type}) {
for (keys %{$State->{Type}}) {
  my $mod = $State->{Type}->{$_};
  if ($_ eq $mod->{Namespace}) {
    for (@{$mod->{Type}}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<rdf:type>=> $_);
    }
    for (@{$mod->{ISA}}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<rdfs:subClassOf>=> $_);
    }
    for (@{$mod->{Implement}}) {
      $result->add_triple ($mod->{Namespace} =>ExpandedURI q<d:Implement>=> $_);
    }
  } else {
    $result->add_triple ($_ =>ExpandedURI q<owl:sameAs>=> $mod->{Namespace});
  }
}}

print $result->stringify_as_xml;

package manakai::n3;
sub new ($) {
  bless {triple => [], anon => 0}, shift;
}

sub get_new_anon_id ($) {
  my ($self) = @_;
  return sprintf '_:r%d', $self->{anon}++;
}

sub add_triple ($$$$) {
  my ($self, $s =>$p=> $o) = @_;
  push @{$self->{triple}}, [$s =>$p=> $o];
}

sub stringify ($) {
  my ($self) = @_;
  return join "\n", (map {"$_."} map {
    sprintf '%s %s %s', map {
      $_ =~ /^[_"]/ ? $_ : "<$_>"
    } @{$_}[0, 1, 2];
  } @{$self->{triple}}), '';
}

sub stringify_as_xml ($) {
  my ($self) = @_;
  use RDF::Notation3::XML;
  my $notation3 = RDF::Notation3::XML->new;
  $notation3->parse_string ($self->stringify);
  return $notation3->get_string;
}

1;

__END__

=head1 NAME

dis2rdf.pl - dis to RDF converter

=head1 SYNOPSIS

  $ perl dis2rdf.pl input.dis [options...] > output.rdf

=head1 DESCRIPTION

This script generates a RDF graph from a "dis" file.

=over 4

=item I<input.dis>

The "dis" file from which a RDF graph is generated.

=item I<output.rdf>

An RDF/XML entity is outputed.

=item C<--output-module>

Show the relationship of modules.

=item C<--output-type>

Show the relationship of types.

=item C<--output-for>

Show the relationship of "for"s.

=cut

=head1 LICENSE

Copyright 2004 Wakaba <w@suika.fam.cx>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Note that the copyright holder(s) of this script does not claim 
any rights for materials outputed by this script, although 
some of its part comes from this script.  The copyright 
holder(s) of source document should define their license terms.

=cut
