#!/usr/bin/perl -w 
use strict;
use Message::Util::QName::Filter {
  d => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#dis-->,
  dis2pm => q<http://suika.fam.cx/~wakaba/archive/2004/11/8/dis2pm#>,
  DOMCore => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/dom-core#>,
  DOMMain => q<http://suika.fam.cx/~wakaba/archive/2004/dom/main#>,
  lang => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#>,
  Perl => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/lang#Perl-->,
  license => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/license#>,
  ManakaiDOM => q<http://suika.fam.cx/~wakaba/archive/2004/8/18/manakai-dom#>,
  owl => q<http://www.w3.org/2002/07/owl#>,
  rdf => q<http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
  rdfs => q<http://www.w3.org/2000/01/rdf-schema#>,
};

use Getopt::Long;
use Pod::Usage;
use Storable;
my %Opt;
GetOptions (
  'help' => \$Opt{help},
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
pod2usage ({-exitval => 0, -verbose => 1}) if $Opt{help};
pod2usage ({-exitval => 2, -verbose => 1})
  if $Opt{output_as_n3} and $Opt{output_as_xml};
$Opt{file_name} = shift;
pod2usage ({-exitval => 2, -verbose => 0}) unless $Opt{file_name};
$Opt{output_resource_pattern} ||= qr/./;
$Opt{output_resource_uri_pattern} ||= qr/./;
$Opt{output_root_anon_resource} = $Opt{output_anon_resource}
  unless defined $Opt{output_anon_resource};
$Opt{output_as_xml} = 1 unless $Opt{output_as_n3};
$Opt{output_anon_resource} = 1 unless defined $Opt{output_anon_resource};
$Opt{output_local_resource} = 1 unless defined $Opt{output_local_resource};
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
our $State = retrieve ($Opt{file_name})
     or die "$0: $Opt{file_name}: Cannot load";
our $result = new manakai::n3;

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

sub res_canon ($) {
  my $uri = shift;
  if (defined $State->{Type}->{$uri}->{Name} and
      defined $State->{Type}->{$uri}->{URI}) {
    return $State->{Type}->{$uri}->{URI};
  } else {
    return $uri;
  }
}

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
        $result->add_triple ($uri =>ExpandedURI q<rdf:type>=> res_canon $_);
      }
      for (@{$mod->{ISA}}) {
        $result->add_triple ($uri =>ExpandedURI q<rdfs:subClassOf>=>
                             res_canon $_);
      }
      for (grep {$mod->{subsetOf}->{$_}} keys %{$mod->{subsetOf}}) {
        $result->add_triple ($uri =>ExpandedURI q<d:subsetOf>=>
                             res_canon $_);
      }
      for (@{$mod->{Implement}}) {
        $result->add_triple ($uri =>ExpandedURI q<d:Implement>=> res_canon $_);
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
                      [ExpandedURI q<dis2pm:constGroupName>],
                      [ExpandedURI q<dis2pm:constName>],
                      [ExpandedURI q<ManakaiDOM:isRedefining>,
                        ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<ManakaiDOM:isForInternal>,
                        ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<d:Read>, ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<d:Write>,
                        ExpandedURI q<DOMMain:boolean>],
                      [ExpandedURI q<dis2pm:undefable>,
                        ExpandedURI q<DOMMain:boolean>]) {
          $result->add_triple ($uri =>$prop->[0]=>
                               n3_literal $mod->{$prop->[0]})
            if defined $mod->{$prop->[0]};
        }
        for my $prop ([ExpandedURI q<d:Type>],
                      [ExpandedURI q<d:actualType>],
                      [ExpandedURI q<dis2pm:type>]) {
          $result->add_triple ($uri =>$prop->[0]=> res_canon $mod->{$prop->[0]})
            if defined $mod->{$prop->[0]} and
               length $mod->{$prop->[0]};
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
        for my $p (ExpandedURI q<dis2pm:method>,
                   ExpandedURI q<dis2pm:constGroup>,
                   ExpandedURI q<dis2pm:const>) {
          for my $v (values %{$mod->{$p}||{}}) {
            my $ruri = defined $v->{URI}
                      ? $v->{URI}
                      : ($v->{ExpandedURI q<d:anonID>}
                              ||= $result->get_new_anon_id (Name => $v->{Name}));
            $result->add_triple ($uri =>$p=> $ruri);
          }
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
  return join "\n", @{main::array_uniq ([sort map {"$_."} map {
    sprintf '%s %s %s', map {
      $_ =~ /^[_"]/ ? $_ : "<$_>"
    } @{$_}[0, 1, 2];
  } @{$self->{triple}}])}, '';
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

__END__

=head1 NAME

cdis2rdf - cdis to RDF converter

=head1 SYNOPSIS

  perl cdis2rdf.pl input.cdis [options...] > output.rdf
  perl cdis2rdf.pl --help

=head1 DESCRIPTION

The C<cdis2rdf> utility generates a RDF graph from a compiled 
"dis" file.  The graph describes relationship of module, "For" or 
resource defined in the dis files.  The RDF data outputed are able 
to be used with other utilities that support RDF.

=head2 OPTIONS

=over 4

=item I<input.cdis>

A compiled "dis" file from which a RDF graph is generated.

=item I<output.rdf>

A file to which the RDF data generated is saved.

=item C<--output-anon-resource> (default) / C<--nooutput-anon-resource>

Set whether anonymous resources are outputed.

=item C<--output-as-n3>

Set to output the graph in RDF/Notation3 format.

=item C<--output-as-xml> (default)

Set to output the graph in RDF/XML format.  Note that the 
L<RDF::Notation3::XML> Perl module is used to generate the XML entity.

=item C<--help>

Show the help message.

=item C<--output-for> / C<--nooutput-for> (default)

Set whether relationships of "For" URI references are outputed.

=item C<--output-local-resource> (default) / C<--nooutput-local-resource>

Set whether local resources (resources that do have the locally-scoped 
name but do not have the global name) are outputed.

=item C<--output-only-in-module=I<pattern>> (default: C<.>)

A regex filter that is applied to URI references of module names. 
This filter is applied to defining-modules of resources (not modules themselves).

=item C<--output-module> / C<--nooutput-module> (default)

Set whehter relationships of modules are outputed.

=item C<--output-perl> / C<--nooutput-perl> (default)

Set whether "For"-Perl specific properties are outputed.

=item C<--output-perl-member-pattern=I<pattern>> (default: C<.>)

A regex filter that is applied to URI references of Perl 
package members such as methods and constant values.

=item C<--output-resource> / C<--nooutput-resource> (default)

Set whether relationships of resources are outputed.

=item C<--output-resource-uri-pattern=I<pattern>> (default: C<.>)

A regex filter that is applied to URI references of 
resources.

=item C<--output-root-anon-resource> / C<--nooutput-root-anon-resource> (default: same as C<--output-anon-resource> / C<--nooutput-anon-resource>)

Set whether anonymous resources that are direct children of modules.

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
