
=head1 NAME

SuikaWiki::Markup::XML::EntityManager --- SuikaWiki XML: Entity manager

=head1 DESCRIPTION

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::EntityManager;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

my %NS = (
	SGML	=> 'urn:x-suika-fam-cx:markup:sgml:',
);

sub new ($$) {
  my ($class, $yourself) = @_;
  my $self = bless {node => $yourself}, $class;
  for (@{$yourself->{node}}) {
    if ($_->{type} eq '#declaration' && $_->{namespace_uri} eq $NS{SGML}.'doctype') {
      $self->{doctype} = $_;
      last;
    }
  }
  $self;
}

## TODO: is this result cachable?
sub get_entity ($$%) {
  my ($self, $name, %o) = @_;
  if (ref $name) {
    $o{namespace_uri} ||= $name->{namespace_uri};
    $name = $name->{local_name};
  } else {
    $o{namespace_uri} ||= $NS{SGML}.'entity';
  }
  my $e = $self->_get_entity ($name, $self->{doctype}->{node}, \%o);
  return $e if ref $e;
  return undef unless $o{namespace_uri} eq $NS{SGML}.'entity';	## General entity
  return undef if $o{dont_use_predefined_entities};
  my $predec = {
  	amp	=> '&#38;',
  	apos	=> '&#39;',
  	gt	=> '&#62;',
  	lt	=> '&#60;',
  	quot	=> '&#34;',
  }->{$name};
  if ($predec) {
    for (SuikaWiki::Markup::XML->new (type => '#declaration', namespace_uri => $NS{SGML}.'entity')) {
      $_->set_attribute ('value')->append_new_node (type => '#xml', value => $predec);
      return $_;
    }
  } else {
    return undef;
  }
}
sub _get_entity ($$$$) {
  my ($self, $name, $nodes, $o) = @_;
  return undef unless ref $nodes;
  for (@$nodes) {
    if ($_->{type} eq '#declaration' && $_->{namespace_uri} eq $o->{namespace_uri}
     && $_->{local_name} eq $name) {
      return $_;
    } elsif ($_->{type} eq '#reference') {
      my $e = $self->_get_entity ($name, $_->{node}, $o);
      return $e if ref $e;
    }
  }
  return undef;
}

sub is_standalone_document_1 ($) {
  my $self = shift;
  return $self->{node}->{flag}->{smxe__standalone_1}
      if defined $self->{node}->{flag}->{smxe__standalone_1};
  for (@{$self->{node}->{node}}) {
    if ($_->{type} eq '#pi' && $_->{local_name} eq 'xml') {
      my $a = $_->get_attribute ('standalone');
      if (ref $a) {
        $self->{node}->{flag}->{smxe__standalone_1} = $a->inner_text eq 'yes' ? 1 : 0;
        return $self->{node}->{flag}->{smxe__standalone_1};
      }
      last;
    }
  }
  if ($self->{doctype}) {
    if ($self->{doctype}->external_id) {
      $self->{node}->{flag}->{smxe__standalone_1} = 0;
      return $self->{node}->{flag}->{smxe__standalone_1};
    }
    for (@{$self->{doctype}->{node}}) {
      if ($_->{type} eq '#declaration' && $_->{namespace_uri} eq $NS{SGML}.'entity:parameter') {
        $self->{node}->{flag}->{smxe__standalone_1} = 0;
        return $self->{node}->{flag}->{smxe__standalone_1};
      }
    }
  }
  $self->{node}->{flag}->{smxe__standalone_1} = 1;
  return $self->{node}->{flag}->{smxe__standalone_1};
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/06/16 09:58:26 $
