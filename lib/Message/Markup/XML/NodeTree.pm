
=head1 NAME

Message::Markup::XML::Node --- manakai XML : XML Node Implementation

=head1 DESCRIPTION

This module implements the XML Node object.

This module is part of manakai XML.

=cut

package Message::Markup::XML::NodeTree;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Message::Markup::XML::Node;
use Message::Markup::XML::QName qw/:prefix :special-uri/;
use Exporter;
push our @ISA, 'Exporter';

our @EXPORT_OK = qw/construct_xml_tree/;

=head1 METHODS

=over 4

=cut

sub construct_xml_tree (%) {
  my %opt = @_;
  my $parent = $opt{parent} || 'Message::Markup::XML::Node';
  my $method = ref $opt{parent} ? 'append_new_node' : 'new';
  my $node = $parent->$method (map {$_=>$opt{$_}} grep /^[^-]/, keys %opt);
  for (keys %{$opt{-attr}||{}}) {
    $node->set_attribute ($_ => $opt{-attr}->{$_});
  }
  for (@{$opt{-child}||[]}) {
    construct_xml_tree (%$_, parent => $node);
  }
  for (keys %{$opt{-ns}||{}}) {
    $node->{ns}->{   $_
                  || ($_ eq '0' ? '0' : DEFAULT_PFX) }
      = $opt{-ns}->{$_}
                  || ($opt{-ns}->{$_} eq '0' ? ZERO_URI
                                             : NULL_URI);
  }
  $node;
}


#------- Not (re-)Implemented Yet -------

my %NS;
sub merge_external_subset ($) {
  my $self = shift;
  unless ($self->{type} eq '#declaration'
       && $self->{namespace_uri} eq $NS{SGML}.'doctype') {
    return unless $self->{type} eq '#document' || $self->{type} eq '#fragment';
    for (@{$self->{node}}) {
      $_->merge_external_subset;
    }
    return;
  }
  my $xsub = $self->get_attribute ('external-subset');
  return unless ref $xsub;
  for (@{$xsub->{node}}) {
    $_->{parent} = $self;
  }
  push @{$self->{node}}, @{$xsub->{node}};
  $self->remove_child_node ($xsub);
  $self->remove_child_node ($self->get_attribute ('PUBLIC'));
  $self->remove_child_node ($self->get_attribute ('SYSTEM'));
  $self->remove_marked_section;
}

sub remove_marked_section ($) {
  my $self = shift;
  my @node;
  for (@{$self->{node}}) {
    if ({qw/#declaration 1 #element 1 #section 1 #reference 1 #attribute 1
            #document 1 #fragment 1/}->{$_->{type}}) {
      $_->remove_marked_section;
    }
  }
  for (@{$self->{node}}) {
    if ($_->{type} ne '#section') {
      push @node, $_;
    } else {
      my $status = $_->get_attribute ('status', make_new_node => 1)->inner_text;
      if ($status eq 'CDATA') {
        $_->{type} = '#text';
        $_->remove_attribute ('status');
        push @node, $_;
      } elsif ($status ne 'IGNORE') {	# INCLUDE
        for my $e (@{$_->{node}}) {
          if ($e->{type} ne '#attribute') {
            $e->{parent} = $self;
            push @node, $e;
          }
        }
      }
    }
  }
  $self->{node} = \@node;
}

## TODO: references in EntityValue
sub remove_references ($) {
  my $self = shift;
  my @node;
  for (@{$self->{node}}) {
    if ({qw/#declaration 1 #element 1 #section 1 #reference 1 #attribute 1
            #document 1 #fragment 1/}->{$_->{type}}) {
      $_->remove_references;
    }
  }
  for (@{$self->{node}}) {
    if ($_->{type} ne '#reference'
    || ($self->{type} eq '#declaration'
     && $_->{namespace_uri} eq $NS{SGML}.'entity')) {
      push @node, $_;
    } else {
      if (index ($_->{namespace_uri}, 'char') > -1) {
        my $e = ref ($_)->new (type => '#text', value => chr $_->{value});
        $e->{parent} = $self;
        push @node, $e;
      } elsif ($_->{flag}->{smxp__ref_expanded}) {
        for my $e (@{$_->{node}}) {
          if ($e->{type} ne '#attribute') {
            $e->{parent} = $self;
            push @node, $e;
          }
        }
      } else {	## reference is not expanded
        push @node, $_;
      }
    }
    $_->{flag}->{smxp__defined_with_param_ref} = 0
      if $_->{flag}->{smxp__defined_with_param_ref}
      && !$_->{flag}->{smxp__non_processed_declaration};
  }
  $self->{node} = \@node;
}

sub resolve_relative_uri ($;$%) {
  require URI;
  my ($self, $rel, %o) = @_;
  my $base = $self->get_attribute ('base', namespace_uri => $NS{xml});
  $base = ref ($base) ? $base->inner_text : $NS{default_base_uri};
  if ($base !~ /^[0-9A-Za-z.%+-]+:/) {	# $base is relative
    $base = $self->_resolve_relative_uri_by_parent ($base, \%o);
  }
  eval q{	## Catch error such as $base is 'data:,foo' (non hierarchic scheme,...)
    return URI->new ($rel)->abs ($base || '.');	## BUG (or spec) of URI: $base == false
  } or return $rel;
}
sub _resolve_relative_uri_by_parent ($$$) {
  my ($self, $rel, $o) = @_;
  if (ref $self->{parent}) {
    if (!$o->{use_references_base_uri} && $self->{parent}->{type} eq '#reference') {
      ## This case is necessary to work with
      ## <element>	<!-- element can have base URI -->
      ## text		<!-- text cannot have base URI -->
      ##   &ent;	<!-- ref's base URI is referred entity's one (in this module) -->
      ##     <!-- expantion of ent -->
      ##     entity's text	<!-- text cannot have base URI, so use <element>'s one -->
      ##     <entitys-element/>	<!-- element can have base URI, otherwise ENTITY's one -->
      ## </element>
      return $self->{parent}->_resolve_relative_uri_by_parent ($rel, $o);
    } else {
      return $self->{parent}->resolve_relative_uri ($rel, %$o);
    }
  } else {
    return $rel;
  }
}

sub root_node ($) {
  my $self = shift;
  if ($self->{type} eq '#document') {
    return $self;
  } elsif (ref $self->{parent}) {
    return $self->{parent}->root_node;
  } else {
    return $self;
  }
}

sub _get_entity_manager ($) {
  my $self = shift;
  if ($self->{type} eq '#document') {
    unless ($self->{flag}->{smx__entity_manager}) {
      require Message::Markup::XML::EntityManager;
      $self->{flag}->{smx__entity_manager} = Message::Markup::XML::EntityManager->new ($self);
    }
    return $self->{flag}->{smx__entity_manager};
  } elsif (ref $self->{parent}) {
    return $self->{parent}->_get_entity_manager;
  } else {
    unless ($self->{flag}->{smx__entity_manager}) {
      require Message::Markup::XML::EntityManager;
      $self->{flag}->{smx__entity_manager} = Message::Markup::XML::EntityManager->new ($self);
    }
    return $self->{flag}->{smx__entity_manager};
  }
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/12/05 08:25:08 $
