
=head1 NAME

SuikaWiki::Markup::XML::Validate --- SuikaWiki XML: XML Validator

=head1 DESCRIPTION

This module provides validator facilities for XML document.
With SuikaWiki::Markup::XML::Parser, it is possible to validate
an XML document.

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::Validate;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require SuikaWiki::Markup::XML::Parser;
our (%NS);
*NS = \%SuikaWiki::Markup::XML::NS;
use Char::Class::XML qw!InXML_NameStartChar InXMLNameChar!;
my %xml_re = (
	Name	=> qr/\p{InXML_NameStartChar}\p{InXMLNameChar}*/,
);

sub new ($) {
  my $self = bless {}, shift;
  require SuikaWiki::Markup::XML::Error;
  $self->{error} = SuikaWiki::Markup::XML::Error->new ({
    ## Validity error
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAME	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a valid Name',
    	level	=> 'vc',
    },
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAMES	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a list of valid Names',
    	level	=> 'vc',
    },
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKEN	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a valid NMToken',
    	level	=> 'vc',
    },
    VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKENS	=> {
    	description	=> 'The declared default value "%s" must meet the lexical constraints of the declared attribute type (%s) : default value must be a list of valid NMTokens',
    	level	=> 'vc',
    },
    VC_NOTATION_DECLARED	=> {
    	description	=> 'Notation "%s" should (or must to be valid) be declared',
    	level	=> 'vc',
    },
    ## Namespace validity error
    VALID_NS_NAME_IS_NCNAME	=> {
    	description	=> 'Name with colon ("%s") cannot be used here in namespaced XML document',
    	level	=> 'nsvc',
    },
    ## Implementation-defined warning
    WARN__PI_TARGET_NOTATION	=> {
    	description	=> 'Target name of the process instruction ("%s") should be declared as a notation name to ensure interoperability',
    	level	=> 'warn',
    },
    ## Misc.
    UNKNOWN	=> {
    	description	=> q(Unknown error (%s)),
    	level	=> q(fatal),
    },
    -error_handler => sub {
      my ($self, $node, $error_type, $error_msg, $err) = @_;
      return 1;
    },
  });
  $self;
}

sub validate ($$;%) {
  my ($self, $node, %opt) = @_;
  unless ($opt{entMan}) {
    $opt{entMan} = $node->_get_entity_manager;
  }
  my $valid = 1;
  for ($self->_validate_notation_declared ($node, entMan => $opt{entMan}),
       $self->_validate_attlist_declaration ($node, entMan => $opt{entMan})) {
    $valid &= $_;
  }
  return $valid;
}

sub _validate_attlist_declaration ($$;%) {
  my ($self, $c, %opt) = @_;
  my $valid = 1;
  my $l = [];
  
  ## Default attribute value syntacally valid?
  $opt{entMan}->get_entities ($l, namespace_uri => $NS{SGML}.'attlist');
  for my $attlist (@$l) {
    for (@{$attlist->{node}}) {
      if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{XML}.'attlist',
          $_->{local_name} eq 'AttDef') {
        my $type = $_->get_attribute ('type', make_new_node => 1)->inner_text;
        if ({qw/ID 1 IDREF 1 IDREFS 1 NMTOKEN 1 NMTOKENS 1 NOTATION 1 NOTATIONS 1/}->{$type}) {
          my $dt = $_->get_attribute ('default_type', make_new_node => 1)->inner_text;
          if (!{qw/IMPLIED 1 REQUIRED 1/}->{$dt}) {
            my $dv = $_->get_attribute ('default_value')->inner_text;
            $dv =~ s/\x20\x20+/\x20/g;
            $dv =~ s/^\x20+//;  $dv =~ s/\x20+$//;
            if ({qw/ID 1 IDREF 1 NOTATION 1/}->{$type}) {
              if ($dv !~ /^$xml_re{Name}$/) {
                $self->{error}->raise_error ($attlist, type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAME',
                                             t => [$dv, $type]);
              } elsif (index ($dv, ':') > -1) {
                $self->{error}->raise_error ($attlist, type => 'VALID_NS_NAME_IS_NCNAME',
                                             t => $dv);
              }
            } elsif ($type eq 'NMTOKEN') {
              if ($dv =~ /\P{InXMLNameChar}/) {
                $self->{error}->raise_error ($attlist,
                                             type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKEN',
                                             t => [$dv, $type]);
              }
            } elsif ($type eq 'NMTOKENS') {
              if ($dv =~ /[^\p{InXMLNameChar}\x20]/) {
                $self->{error}->raise_error ($attlist,
                                             type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NMTOKENS',
                                             t => [$dv, $type]);
              }
            } else {	## IDREFS NOTATIONS
              if ($dv !~ /^$xml_re{Name}(\x20$xml_re{Name})*$/) {
                $self->{error}->raise_error ($attlist, type => 'VC_ATTR_DEFAULT_LEGAL_VAL_IS_NAMES',
                                             t => [$dv, $type]);
              } elsif (index ($dv, ':') > -1) {
                $self->{error}->raise_error ($attlist, type => 'VALID_NS_NAME_IS_NCNAME',
                                             t => $dv);
              }
            }
          }	# default attr exist
        }	# not CDATA
      }
    }
  }
}

sub _validate_notation_declared ($$;%) {
  my ($self, $c, %opt) = @_;
  my $valid = 1;
    my $l = [];
    my %defined;
    
    ## NDATA notation declared?
    $opt{entMan}->get_entities ($l, namespace_uri => $NS{SGML}.'entity');
    for my $ent (@$l) {
      for ($ent->get_attribute ('NDATA')) {
      if (ref $_) {
        my $nname = $_->inner_text;
        if ($defined{$nname} > 0
         || $opt{entMan}->get_entity ($nname, namespace_uri => $NS{SGML}.'notation')) {
          $defined{$nname} = 1;
        } else {
          $self->{error}->raise_error ($ent, type => 'VC_NOTATION_DECLARED',
                                       t => $nname);
          $defined{$nname} = -1;
          $valid = 0;
        }
      }}	# NDATA exist
    }
    
    ## PI target name notation declared?
    @$l = ();
    $opt{entMan}->get_entities ($l, parent_node => $c, type => '#pi', namespace_uri => '');
    for my $pi (@$l) {
      my $nname = $pi->local_name;
      if ($defined{$nname} > 0
       || $opt{entMan}->get_entity ($nname, namespace_uri => $NS{SGML}.'notation')) {
        $defined{$nname} = 1;
      } else {
        $self->{error}->raise_error ($pi, type => 'WARN__PI_TARGET_NOTATION',
                                     t => $nname)
          unless lc (substr ($nname, 0, 3)) eq 'xml';	## Target name xml* is maintained by W3C
        $defined{$nname} = -1;
      }
    }	# pi
  return $valid;
}

#sub _CLASS_NAME () { 'SuikaWiki::Markup::XML::Validate' }

sub option ($$;$%) {
  my ($self, $name, $value, %opt) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  if (!defined $self->{option}->{$name} && $opt{-see_parent} && $self->{parent}) {
    $self->{parent}->option ($name, $value, %opt);
  } else {
    $self->{option}->{$name};
  }
}

sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/07/14 07:36:55 $
