#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  infoset => q<http://www.w3.org/2001/04/infoset#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  MDOM_EXCEPTION => q<http://suika.fam.cx/~wakaba/archive/2004/8/4/manakai-dom-exception#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
  xml => q<http://www.w3.org/XML/1998/namespace>,
  xmlns => q<http://www.w3.org/2000/xmlns/>,
  xsd => q<http://www.w3.org/2001/XMLSchema#>,
};

use Getopt::Long;
use Pod::Usage;
my %Opt;
GetOptions (
  'for=s' => \$Opt{For},
  'help' => \$Opt{help},
  'undef-check!' => \$Opt{no_undef_check},
  'output-anon-resource!' => \$Opt{output_anon_resource},
  'output-as-n3' => \$Opt{output_as_n3},
  'output-as-xml' => \$Opt{output_as_xml},
  'output-for!' => \$Opt{output_for},
  'output-local-resource!' => \$Opt{output_local_resource},
  'output-module!' => \$Opt{output_module},
  'output-only-in-module=s' => \$Opt{output_resource_pattern},
  'output-perl!' => \$Opt{output_prop_perl},
  'output-perl-member-pattern=s' => \$Opt{output_perl_member_pattern},
  'output-resource!' => \$Opt{output_resource},
  'output-resource-uri-pattern=s' => \$Opt{output_resource_uri_pattern},
  'output-root-anon-resource!' => $Opt{output_root_anon_resource},
) or pod2usage (2);
if ($Opt{help}) {
  pod2usage (0);
  exit;
}
if ($Opt{output_as_n3} and $Opt{output_as_xml}) {
  pod2usage (2);
  exit;
}
$Opt{file_name} = shift;
$Opt{output_resource_pattern} ||= qr/./;
$Opt{output_resource_uri_pattern} ||= qr/./;
$Opt{output_root_anon_resource} = $Opt{output_anon_resource}
  unless defined $Opt{output_anon_resource};
$Opt{output_as_xml} = 1 unless $Opt{output_as_n3};
$Opt{output_anon_resource} = 1 unless defined $Opt{output_anon_resource};
$Opt{output_local_resource} = 1 unless defined $Opt{output_local_resource};
$Opt{no_undef_check} = defined $Opt{no_undef_check}
                         ? $Opt{no_undef_check} ? 0 : 1 : 0;
$Opt{output_perl_member_pattern} ||= qr/./;

BEGIN {
require 'manakai/genlib.pl';
require 'manakai/dis.pl';
}
sub n3_literal ($) {
  my $s = shift;
  impl_err ("Literal value not defined") unless defined $s;
  qq<"$s">;
}
our $State;
our $result = new manakai::n3;


$State->{DefaultFor} = $Opt{For};

my $source = dis_load_module_file (module_file_name => $Opt{file_name},
                                   For => $Opt{For},
                                   use_default_for => 1);
$State->{for_def_required}->{$State->{DefaultFor}} ||= 1;

dis_check_undef_type_and_for ()
  unless $Opt{no_undef_check};

if (dis_uri_for_match (ExpandedURI q<ManakaiDOM:Perl>, $State->{DefaultFor})) {
  dis_perl_init ($source, For => $State->{DefaultFor});
}

my $primary = $result->get_new_anon_id (Name => 'boot');
$result->add_triple ($primary =>ExpandedURI q<d:module>=> $State->{module})
                if $Opt{output_module};
$result->add_triple
           ($primary =>ExpandedURI q<d:DefaultFor> => $State->{DefaultFor})
                if $Opt{output_for};

if ($Opt{output_module}) {
for (keys %{$State->{Module}}) {
  my $mod = $State->{Module}->{$_};
  if ($_ eq $mod->{URI}) {
    $result->add_triple ($mod->{URI} =>ExpandedURI q<rdf:type>=>
                         ExpandedURI q<d:Module>);
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:Name>=>
                         n3_literal $mod->{Name});
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:NameURI>=>
                         $mod->{NameURI});
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:ModuleGroup>=>
                         $mod->{ModuleGroup});
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:FileName>=>
                         n3_literal $mod->{FileName})
      if defined $mod->{FileName};
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:Namespace>=>
                         $mod->{Namespace});
    for (@{$mod->{require_module}||[]}) {
      $result->add_triple ($mod->{URI} =>ExpandedURI q<d:Require>=> $_);
    }
    for (keys %{$mod->{For}}) {
      $result->add_triple ($mod->{URI} =>ExpandedURI q<d:For>=> $_);
    }
    for (@{$mod->{ISA}}) {
      $result->add_triple ($mod->{URI} =>ExpandedURI q<rdfs:subClassOf>=> $_);
    }
    if ($Opt{output_prop_perl}) {
      $result->add_triple ($mod->{URI} =>ExpandedURI q<dis2pm:packageName>=>
                           n3_literal $mod->{ExpandedURI q<dis2pm:packageName>})
        if defined $mod->{ExpandedURI q<dis2pm:packageName>};
      if ($Opt{output_resource}) {
        for (values %{$mod->{ExpandedURI q<dis2pm:package>}}) {
          my $uri = defined $_->{URI}
                       ? $_->{URI}
                       : ($_->{ExpandedURI q<d:anonID>}
                            ||= $result->get_new_anon_id (Name => $_->{Name}));
          $result->add_triple ($mod->{URI} =>ExpandedURI q<dis2pm:package>=>
                               $uri);
        }
      }
    }
  } else {
    $result->add_triple ($_ =>ExpandedURI q<owl:sameAs>=> $mod->{URI});
  }
}}

if ($Opt{output_for}) {
for (keys %{$State->{For}}) {
  my $mod = $State->{For}->{$_};
  if ($_ eq $mod->{URI}) {
    $result->add_triple ($mod->{URI} =>ExpandedURI q<rdf:type>=>
                         ExpandedURI q<d:For>);
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:NameURI>=> $mod->{URI});
    $result->add_triple ($mod->{URI} =>ExpandedURI q<d:FullName>=>
                         n3_literal $mod->{FullName})
      if defined $mod->{FullName};
    for (@{$mod->{ISA}}) {
      $result->add_triple ($mod->{URI} =>ExpandedURI q<rdfs:subClassOf>=> $_);
    }
    for (@{$mod->{Implement}}) {
      $result->add_triple ($mod->{URI} =>ExpandedURI q<d:Implement>=> $_);
    }
  } else {
    $result->add_triple ($_ =>ExpandedURI q<owl:sameAs>=> $mod->{URI});
  }
}}

if ($Opt{output_resource}) {
  sub class_to_rdf ($;%);
  sub class_to_rdf ($;%) {
    my ($mod, %opt) = @_;
    return unless defined $mod->{Name};
    return unless $mod->{parentModule} =~ /$Opt{output_resource_pattern}/;
    return if $Opt{output_prop_perl} and
              $mod->{ExpandedURI q<dis2pm:type>} and
              {
                ExpandedURI q<ManakaiDOM:DOMAttribute> => 1,
                ExpandedURI q<ManakaiDOM:DOMMethod> => 1,
              }->{$mod->{ExpandedURI q<dis2pm:type>}} and
              $mod->{Name} and
              $mod->{Name} !~ /$Opt{output_perl_member_pattern}/;
    if ((defined $mod->{URI} and $opt{key} eq $mod->{URI}) or
        not defined $mod->{URI}) {
      return if defined $mod->{URI} and
                $mod->{URI} !~ /$Opt{output_resource_uri_pattern}/;
      return if not defined $mod->{URI} and not $Opt{output_anon_resource};
      my $uri = defined $mod->{URI}
                       ? $mod->{URI}
                       : ($mod->{ExpandedURI q<d:anonID>}
                            ||= $result->get_new_anon_id (Name => $mod->{Name}));
      $result->add_triple ($uri =>ExpandedURI q<d:Name>=>
                           n3_literal $mod->{Name}) if length $mod->{Name};
      $result->add_triple ($uri =>ExpandedURI q<d:NameURI>=> $mod->{NameURI})
        if defined $mod->{NameURI};
      $result->add_triple ($uri =>ExpandedURI q<d:parentResource>=>
                           $opt{parent_class_uri})
        if defined $opt{parent_class_uri};
      if ($Opt{output_module}) {
        $result->add_triple ($uri =>ExpandedURI q<d:parentModule>=>
                             $mod->{parentModule});
      }
      for (keys %{$mod->{Type}}) {
        $result->add_triple ($uri =>ExpandedURI q<rdf:type>=> $_);
      }
      for (@{$mod->{ISA}}) {
        $result->add_triple ($uri =>ExpandedURI q<rdfs:subClassOf>=> $_);
      }
      for (@{$mod->{Implement}}) {
        $result->add_triple ($uri =>ExpandedURI q<d:Implement>=> $_);
      }
      if ($Opt{output_for}) {
        for (keys %{$mod->{For}}) {
          $result->add_triple ($uri =>ExpandedURI q<d:For>=> $_);
        }
      }
      for (@{$mod->{hasResource}||[]}) {
        my $ruri = defined $_->{URI}
                      ? $_->{URI}
                      : ($_->{ExpandedURI q<d:anonID>}
                              ||= $result->get_new_anon_id (Name => $_->{Name}));
        $result->add_triple ($uri =>ExpandedURI q<d:hasResource>=> $ruri);
      }
      if ($Opt{output_prop_perl}) {
        for my $prop ([ExpandedURI q<dis2pm:packageName>],
                      [ExpandedURI q<dis2pm:ifPackagePrefix>],
                      [ExpandedURI q<dis2pm:methodName>],
                      [ExpandedURI q<dis2pm:paramName>],
                      [ExpandedURI q<ManakaiDOM:isRedefining>,
                        ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<ManakaiDOM:isForInternal>,
                        ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<d:Read>, ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<d:Write>,
                        ExpandedURI q<DOMMain:boolean>]) {
          $result->add_triple ($uri =>$prop->[0]=>
                               n3_literal $mod->{$prop->[0]})
            if defined $mod->{$prop->[0]};
        }
        for my $prop ([ExpandedURI q<d:Type>],
                      [ExpandedURI q<d:actualType>]) {
          $result->add_triple ($uri =>$prop->[0]=> $mod->{$prop->[0]})
            if defined $mod->{$prop->[0]};
        }
        for my $prop ([ExpandedURI q<dis2pm:getter>],
                      [ExpandedURI q<dis2pm:setter>],
                      [ExpandedURI q<dis2pm:return>]) {
          my $oo = $mod->{$prop->[0]};
          if ($oo and defined $oo->{Name}) {
            my $o = defined $oo->{URI}
                      ? $oo->{URI}
                      : ($oo->{ExpandedURI q<d:anonID>}
                            ||= $result->get_new_anon_id (Name => $oo->{Name}));
            $result->add_triple ($uri =>$prop->[0]=> $o)
          }
        }
        for (values %{$mod->{ExpandedURI q<dis2pm:method>}||{}}) {
          my $ruri = defined $_->{URI}
                      ? $_->{URI}
                      : ($_->{ExpandedURI q<d:anonID>}
                              ||= $result->get_new_anon_id (Name => $_->{Name}));
          $result->add_triple ($uri =>ExpandedURI q<dis2pm:method>=> $ruri);
        }
        if ($mod->{ExpandedURI q<dis2pm:type>} eq
              ExpandedURI q<ManakaiDOM:DOMMethod>) {
          $result->add_triple
                      ($uri =>ExpandedURI q<dis2pm:param>=>
                       my $p = $result->get_new_anon_id (Name => 'param'));
          $result->add_triple ($uri =>ExpandedURI q<rdf:type>=>
                               ExpandedURI q<rdf:Seq>);
          my $i = 0;
          for (@{$mod->{ExpandedURI q<dis2pm:param>}||[]}) {
            my $ruri = defined $_->{URI}
                          ? $_->{URI}
                          : ($_->{ExpandedURI q<d:anonID>}
                              ||= $result->get_new_anon_id (Name => $_->{Name}));
            $result->add_triple ($p =>(ExpandedURI q<rdf:_>).++$i=> $ruri);
          }
        }
      }
      if ($Opt{output_local_resource}) {
        for (keys %{$mod->{Resource}}) {
          class_to_rdf ($mod->{Resource}->{$_}, %opt, parent_class => $mod,
                        parent_class_uri => $uri,
                        key => $_);
        }
      }
    } else { ## Alias URI
      return unless $opt{key} =~ /$Opt{output_resource_uri_pattern}/ or
                    $mod->{URI} =~ /$Opt{output_resource_uri_pattern}/;
      $result->add_triple ($opt{key} =>ExpandedURI q<owl:sameAs>=> $mod->{URI});
    }
  }
  for (sort keys %{$State->{Type}}) {
    next if not $Opt{output_root_anon_resource} and
            not defined $State->{Type}->{$_}->{URI};
    class_to_rdf ($State->{Type}->{$_}, key => $_);
  }
}

if ($Opt{output_as_xml}) {
  print $result->stringify_as_xml;
} else {
  print $result->stringify;
}

package manakai::n3;
sub new ($) {
  bless {triple => [], anon => 0}, shift;
}

sub get_new_anon_id ($;%) {
  my ($self, %opt) = @_;
  my $s = $opt{Name} ? $opt{Name} : '';
  return sprintf '_:r%d%s', $self->{anon}++, $s;
}

sub add_triple ($$$$) {
  my ($self, $s =>$p=> $o) = @_;
  main::impl_err ("Subject undefined") unless defined $s;
  main::impl_err ("Property undefined") unless defined $p;
  main::impl_err ("Object undefined") unless defined $o;
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
  my $n3 = $self->stringify;
  my $rdf_ = ExpandedURI q<rdf:_>;
  $n3 =~ s{$rdf_}{ExpandedURI q<rdf:XXXX__dummy__XXXX>}ge;
  $notation3->parse_string ($n3);
  my $xml = $notation3->get_string;
  $xml =~ s/\brdf:nodeID="_:/rdf:nodeID="/g;
  $xml =~ s/XXXX__dummy__XXXX/_/g;
#  $xml =~ s/^<\?xml version="1.0" encoding="utf-8"\?>\s*//;
  $xml;
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
