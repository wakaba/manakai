
=head1 NAME

SuikaWiki::Markup::XML::EntityManager --- SuikaWiki XML: Entity manager

=head1 DESCRIPTION

The entity manager is part of XML system to retrive internal/external entity in
this implementation.  In addition to it, this module provides some procedures
to validate public identifier or system identifier and to get one of/list of
markup declarations for element, attribute list or notation from the DTD.

This module have customizable interface to get external resource.
Defining the additional or replacing function for the "external identifier(s)
to entity value convertion", more flexible or secure entity resolving can be
implemented.  (For detail, see examples below.)

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::EntityManager;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.10 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
our %NS;
*NS = \%SuikaWiki::Markup::XML::NS;

# $class->new ($yourself)
sub new ($$) {
  my $self = bless {node => $_[1]}, $_[0];
  return $self unless ref $self->{node};
  for (@{$self->{node}->{node}}) {
    if ($_->{type} eq '#declaration' && $_->{namespace_uri} eq $NS{SGML}.'doctype') {
      $self->{doctype} = $_;
      last;
    }
  }
  $self;
}

sub set_root_node ($$) { $_[0]->{node} = $_[1] }
sub set_doctype_node ($$) { $_[0]->{doctype} = $_[1] }

sub is_declared_entity ($$;%) {
  my ($self, $name, %o) = @_;
  if (ref $name) {
    $o{namespace_uri} ||= $name->{namespace_uri};
    $name = $name->{local_name};
  } else {
    $o{namespace_uri} ||= $NS{SGML}.'entity';
  }
  $self->{cache}->{is_declared_entity}->{$o{namespace_uri}} = {} if $o{clear_cache};
  $self->{cache}->{is_declared_entity}->{$o{namespace_uri}}->{$name} = $o{set_value}
    if defined $o{set_value};
  unless (defined $self->{cache}->{is_declared_entity}->{$o{namespace_uri}}->{$name}) {
    if ($o{seek}) {
      $self->{cache}->{is_declared_entity}->{$o{namespace_uri}}->{$name}
        = $self->get_entity ($name, %o) ? 1 : 0;
    }
  }
  $self->{cache}->{is_declared_entity}->{$o{namespace_uri}}->{$name};
}

sub get_entity ($$;%) {
  my ($self, $name, %o) = @_;
  if (ref $name) {
    $o{namespace_uri} ||= $name->{namespace_uri};
    $name = $name->{local_name};
  } else {
    $o{namespace_uri} ||= $NS{SGML}.'entity';
  }
  if (!$o{dont_use_predefined_entities}
      && ($o{namespace_uri} eq $NS{SGML}.'entity')) {	## General entity
    my $predec = {
    	amp	=> '&#38;',
    	apos	=> '&#39;',
    	gt	=> '&#62;',
    	lt	=> '&#60;',
    	quot	=> '&#34;',
    }->{$name};
    if ($predec) {
      for (SuikaWiki::Markup::XML->new (type => '#declaration',
                                        namespace_uri => $NS{SGML}.'entity')) {
        $_->set_attribute ('value')->append_new_node (type => '#xml', value => $predec);
        return $_;
      }
    }
  }
  $self->{cache}->{entity_declaration}->{$o{namespace_uri}} = {} if $o{clear_cache};
  my $e = $self->{cache}->{entity_declaration}->{$o{namespace_uri}}->{$name};
  return $e if ref $e;
  return undef unless ref $self->{doctype};
  $e = $self->_get_entity ($name, $self->{doctype}->{node}, \%o);
  if (ref $e) {
    $self->{cache}->{entity_declaration}->{$o{namespace_uri}}->{$name} = $e;
    return $e;
  }
  my $xsub = $self->{doctype}->get_attribute ('external-subset');
  if (ref $xsub) {
    $e = $self->_get_entity ($name, $xsub->{node}, \%o);
    if (ref $e) {
      $self->{cache}->{entity_declaration}->{$o{namespace_uri}}->{$name} = $e;
      return $e;
    }
  }
  return undef;
}
sub _get_entity ($$$$) {
  my ($self, $name, $nodes, $o) = @_;
  return undef unless ref $nodes;
  for (@$nodes) {
    next if $_->{flag}->{smxp__non_processed_declaration};
    if ($_->{type} eq '#declaration' && $_->{namespace_uri} eq $o->{namespace_uri}
     && $_->{local_name} eq $name) {
      return $_;
    } elsif ($_->{type} eq '#reference') {
      my $e = $self->_get_entity ($name, $_->{node}, $o);
      return $e if ref $e;
    } elsif ($_->{type} eq '#section'
          && ($_->get_attribute ('status', make_new_node => 1)->inner_text||'INCLUDE')
              eq 'INCLUDE') {
      my $e = $self->_get_entity ($name, $_->{node}, $o);
      return $e if ref $e;
    }
  }
  return undef;
}

# DOM's get*By*
sub get_entities ($$%) {
  my ($self, $l, %o) = @_;
  $o{namespace_uri} = $NS{SGML}.'entity' unless defined $o{namespace_uri};
  $o{type} ||= '#declaration';
  $o{parent_node} ||= $self->{doctype};
  $self->_get_entities ($l, $o{parent_node}->{node}, \%o);
}
sub _get_entities ($$$$) {
  my ($self, $l, $nodes, $o) = @_;
  return undef unless ref $nodes;
  for (@$nodes) {
    next if $_->{flag}->{smxp__non_processed_declaration};
    if (($_->{type} eq $o->{type}) && ($_->{namespace_uri} eq $o->{namespace_uri})) {
      push @$l, $_;
    } elsif ($_->{type} eq '#reference' || $_->{type} eq '#element') {
      $self->_get_entities ($l, $_->{node}, $o);
    } elsif (($_->{type} eq '#section'
              && ($_->get_attribute ('status', make_new_node => 1)->inner_text||'INCLUDE')
              eq 'INCLUDE')
         || ($_->{type} eq '#declaration' && $_->{namespace_uri} eq $NS{SGML}.'doctype')) {
      $self->_get_entities ($l, $_->{node}, $o);
    } elsif ($_->{type} eq '#attribute' && $_->{local_name} eq 'external-subset') {
      $self->_get_entities ($l, $_->{node}, $o);
    }
  }
}

sub get_attr_definitions ($%) {
  my ($self, %o) = @_;
  return $self->{cache}->{attr_defs}->{$o{qname}}
    if $self->{cache}->{attr_defs}->{$o{qname}};
  my %r;
  $o{namespace_uri} = $NS{SGML}.'attlist';
  $o{type} = '#declaration';
  $o{parent_node} ||= $self->{doctype};
  my $l = [];
  $self->_get_entities ($l, $o{parent_node}->{node}, \%o);
  $r{declaration} = [];
  for (@$l) {
    if ($_->get_attribute ('qname', make_new_node => 1)->inner_text eq $o{qname}) {
      push @{$r{declaration}}, $_;
    }
  }
  for my $decl (@{$r{declaration}}) {
    for (@{$decl->{node}}) {
      if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{XML}.'attlist',
          $_->{local_name} eq 'AttDef') {
        my $aname = $_->get_attribute ('qname', make_new_node => 1)->inner_text;
        if ($r{attr}->{$aname}) {
          # 
        } else {
          $r{attr}->{$aname} = $_;
          $r{attr_may_not_be_read}->{$aname} = $decl->{flag}->{smxp__declaration_may_not_be_read};
          for (@{$_->{node}}) {
            if ($_->{type} eq '#element' && $_->{namespace_uri} eq $NS{XML}.'attlist'
             && $_->{local_name} eq 'enum') {
              $r{enum}->{$aname}->{$_->inner_text} = 1;
            }
          }
        }
      }
    }
  }
  $self->{cache}->{attr_defs}->{$o{qname}} = \%r;
  \%r;
}

## TODO: uri based recursion
sub get_external_entity ($$$$) {
  my ($self, $parser, $decl, $o) = @_;
  my $declns = $decl->namespace_uri;
  my $name = $declns eq $NS{SGML}.'doctype' ?
             $decl->get_attribute ('qname', make_new_node => 1)->inner_text :
             $decl->local_name;
  my $p = $self->{external_entity_cache}->{$declns}->{$name};
  if ($name && !$p) {
    $p = {name => $name};  $self->{external_entity_cache}->{$declns}->{$name} = $p;
    for (qw/PUBLIC SYSTEM NDATA/) {
      $p->{$_} = $decl->get_attribute ($_);
      $p->{$_} = ref $p->{$_} ? $p->{$_}->inner_text : undef;
    }
    $p->{uri} = $decl->resolve_relative_uri ($p->{SYSTEM}, use_references_base_uri => 1);
  }
    for ($o) {
      $_->{entity_type} ||= 'external_parsed_entity';
      $_->{uri} = $p->{uri};  $_->{line} = 0;  $_->{pos} = 0;
    }
  if ($name && !$p->{__flag}) {
    my $resolver = $parser->option ('uri_resolver');
    if (ref $resolver) {
      $resolver = &$resolver ($self, $parser, $decl, $p, $o);	## If returned false,
      $self->default_uri_resolver ($parser, $decl, $p, $o) if $resolver;	## don't call this.
    } else {
      $self->default_uri_resolver ($parser, $decl, $p, $o);
    }
    ## Line-break normalization
    $p->{text} =~ s/\x0D\x0A/\x0A/gs;
    $p->{text} =~ tr/\x0D/\x0A/;
    $p->{__flag} = 1;
  }
  $p;
}

=pod example

 my $parser = SuikaWiki::Markup::XML::Parser->new (flag => {smxe__uri_resolver => sub {
 	my ($self, $decl, $p) = @_;
 	@@ $p->{SYSTEM} =~ s///g @@
 	return 1;
 }});

=cut

sub default_uri_resolver ($$$$$;%) {
  my ($self, $parser, $decl, $p, $o, %opt) = @_;
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  $ua->agent ('"SuikaWiki::Markup::XML::EntityManager"/'.$VERSION);
  	## TODO: use Message::Field::UA
  my $req = HTTP::Request->new (GET => $p->{uri});
  my $res = $ua->request ($req);
  if ($res->is_success || $opt{accept_error_page}) {
    ## TODO: use Message::Entity for more intelligent/strict parsing:-)
    $p->{base_uri} = $res->base;	## See Content-Base: and Content-Location: (and HTML:BASE)
    $p->{uri} = $res->request->uri;  $o->{uri} = $p->{uri};	## Redirect support
    ## Check media type
    my $CT = $res->header ('Content-Type');
    my $ct = lc $res->content_type;
    $self->_check_media_type ($o, $ct);
    $p->{text} = $res->content;
    #$p->{text} .= "<!--$p->{uri}-->";	## DEBUG: base URI
    ## Charset/encoding convertion
    my $encoding;
    if ($CT =~ /charset\s*=\s*"?([^",;\s]+)"?/i) {	## BUG: This check is not strict
      $encoding = lc $1;
    } else {	## No charset parameter
      if ($p->{uri}->scheme eq 'file') {
        ## Protocol does not provide charset information
      } elsif (lc (substr ($ct, 0, 5)) eq 'text/') {	## BUG: This check is not strict
        $encoding = 'us-ascii';	## See RFC 3023
        $self->_raise_error ($o, type => 'WARN_NO_CHARSET_PARAM_FOR_TEXT', t => $ct);
      } else {
        ## BUG: Warn even if the media type does not have the charset parameter
        $self->_raise_error ($o, type => 'WARN_NO_CHARSET_PARAM', t => $ct);
      }
    }
    unless ($encoding) {
      $encoding = $self->_guess_entity_encoding ($p->{text}, $o) || 'utf-8';
    }
    #print "<$p->{uri}>: encode is {$encoding}\n";	## DEBUG: Detected encoding
    if ($encoding) {
      require Encode;
      eval q{$p->{text} = Encode::decode ($encoding, $p->{text}); 1}
        or $self->_raise_error ($o, type => 'FATAL_ERR_DECODE_IMPL_ERR', t => $@);
    } else {
      #$self->_raise_error ($o, type => 'WARN_NO_EXPLICIT_ENCODING_INFO');
    }
    ## parse and remove xml declaration
    unless ($opt{dont_parse_text_declaration}) {
      $p->{text_declaration} = (ref ($decl)||$decl)->new (type => '#pi', local_name => 'xml');
      $parser->_parse_xml_or_text_declaration ($p->{text_declaration}, \$p->{text}, $o);
    }
  } else {
    $p->{error}->{no_data} = 1;
    $p->{error}->{reason_text} = $res->status_line;
    $p->{uri} = $res->request->uri;  $o->{uri} = $p->{uri};	## Redirect support
  }
}

sub is_standalone_document ($) {
  my $self = shift;
  return $self->{node}->{flag}->{smxe__standalone}
      if defined $self->{node}->{flag}->{smxe__standalone};
  for (@{$self->{node}->{node}}) {
    if ($_->{type} eq '#pi' && $_->{local_name} eq 'xml') {
      my $a = $_->get_attribute ('standalone');
      if (ref $a) {
        $self->{node}->{flag}->{smxe__standalone} = $a->inner_text eq 'yes' ? 1 : 0;
        return $self->{node}->{flag}->{smxe__standalone};
      }
    } elsif ($_->{type} eq '#attribute') {
      ## Check next node too
    } else {
      last;	## No xml declaration
    }
  }
  $self->{node}->{flag}->{smxe__standalone} = 0;
  return $self->{node}->{flag}->{smxe__standalone};
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
    }
    last;
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

sub check_public_id ($$$) {
  my ($self, $o, $pubid) = @_;
  if (length ($pubid) == 0) {
    $self->_raise_error ($o, type => 'WARN_PID_EMPTY');
  }
  if ($pubid =~ m"([^\x0A\x0D\x20A-Za-z0-9'()+,./:=?;!*#\@\$_%-])"s) {
    $self->_raise_error ($o, type => 'SYNTAX_INVALID_PUBID', t => $1);
  }
  $pubid =~ s/[\x0A\x0D\x20]+/\x20/gs;
  if (length ($pubid) > 240) {	## this check is not strict
    $self->_raise_error ($o, type => 'WARN_PID_IS_TOO_LONG', t => $pubid);
  }
  $pubid =~ s/^\x20//; $pubid =~ s/\x20$//;
  if ($pubid =~ /^[Uu][Rr][Nn]:/) {
    if ($pubid !~ m"^[Uu][Rr][Nn]:[0-9A-Za-z][0-9A-Za-z-]{0,31}:(?:[0-9A-Za-z()+,.:=\@;\$_!*'/?-]|%[0-9A-Fa-f]{2})+$") {
      $self->_raise_error ($o, type => 'WARN_PID_IS_INVALID_URN', t => $pubid);
    } elsif ($pubid =~ m![/?]!) {
      $self->_raise_error ($o, type => 'WARN_PID_IS_URN_WITH_RESERVED_CHAR', t => $pubid);
    }
  } elsif ($pubid !~ m<^(?:[+-]//|ISO)(?:(?!//).)+//[A-Z]+ (?:(?!//).)+//(?:(?!//).)+(?://(?:(?!//).)+)?$>) {
    $self->_raise_error ($o, type => 'WARN_PID_IS_NOT_FPI_NOR_URN', t => $pubid);
  }
  $pubid;
}

sub check_system_id ($$$) {
  my ($self, $o, $sysid) = @_;
  if ($sysid =~ m"([^0-9A-Za-z_.!~*'();/?:\@&=+\$,%\[\]#-])"s) {
    $self->_raise_error ($o, type => 'WARN_INVALID_URI_CHAR_IN_SYSID', t => $1);
  }
  if ($sysid =~ s/(#[^#]*)$//g) {
    $self->_raise_error ($o, type => 'ERR_XML_SYSID_HAS_FRAGMENT', t => $1);
  }
  if (length ($sysid) == 0) {
    $self->_raise_error ($o, type => 'WARN_SYSID_EMPTY');
  }
  $sysid;
}

sub check_ns_uri ($$$$) {	## TODO: check predefined NS
  my ($self, $o, $ns_pfx => $ns_name) = @_;
  if ($ns_name =~ m"([^0-9A-Za-z_.!~*'();/?:\@&=+\$,%\[\]#-])"s) {
    $self->_raise_error ($o, type => 'WARN_INVALID_URI_CHAR_IN_NS_NAME', t => $1);
  }
  if ($ns_name !~ /^[0-9A-Za-z.+-]+:/) {
    $self->_raise_error ($o, type => 'WARN_XML_NS_URI_IS_RELATIVE', t => $ns_name);
  }
}

## Guess encoding of the entity by BOM and '<?' and Encode::Guess --- Used by default resolver
sub _guess_entity_encoding ($$) {
  my ($self, $entity, $o) = @_;
  my $encoding;
  my $f2 = substr ($entity, 0, 2);
  my $s2 = substr ($entity, 2, 2);
  if ($f2 eq "<?") {
    $encoding = '*ascii';
  } elsif ($f2 eq "\xEF\xBB" && substr ($s2, 0, 1) eq "\xBF") {
    $encoding = '*utf-8';
  } elsif ($f2 eq "\xFE\xFF" || $f2 eq "\x00\x3C") {
    if ($s2 eq "\x00\x00") {
      $encoding = '*ucs-4-3412';
    } else {
      $encoding = '*ucs-2be';
    }
  } elsif ($f2 eq "\xFF\xFE" || $f2 eq "\x3C\x00") {
    if ($s2 eq "\x00\x00") {
      $encoding = '*ucs-4le';
    } else {
      $encoding = '*ucs-2le';
    }
  } elsif ($f2 eq "\x00\x00") {
    if ($s2 eq "\xFE\xFF" || $s2 eq "\x00\x3C") {
      $encoding = '*ucs-4be';
    } elsif ($s2 eq "\xFF\xFE" || $s2 eq "\x3C\x00") {
      $encoding = '*ucs-4-2143';
    }
  } elsif ($f2 eq "\x4C\x6F") {
    $encoding = '*ebcdic';
  }
  
  ## TODO: Charset list need more consideration
  my @guess_list;
  if ($encoding eq '*ascii' || $encoding eq '*utf-8') {
    if ($entity =~ /<\?xml.+?encoding=["']([0-9A-Za-z._-]+)["']/) {
      $encoding = lc $1;
    } else {
      if ($encoding eq '*utf-8') {
        $encoding = undef;
        @guess_list = qw/utf-8 cesu-8 unicode-1-1-utf-8/;
      } else {
        $encoding = undef;
        @guess_list = qw/us-ascii iso-8859-1 iso-8859-2 iso-8859-8 iso-8859-15
                         iso-2022-jp euc-jp shift_jis euc-kr
                         gbk gb18030 big5-eten big5-hkscs windows-1252 koi8-r koi8-u/;
      }
    }
  } elsif ($encoding =~ /ucs/) {
    my $ent = $entity; $ent =~ tr/\x00//d;
    if ($ent =~ /<\?xml.+?encoding=["']([0-9A-Za-z._-]+)["']/) {
      $encoding = lc $1;
    } else {
      if ($encoding eq '*ucs-2be') {
        $encoding = 'utf-16be';
      } elsif ($encoding eq '*ucs-2le') {
        $encoding = 'utf-16le';
      } elsif ($encoding =~ /(ucs-4.+)/) {
        $encoding = $1;
      }
    }
  } elsif ($encoding eq '*ebcdic') {
    @guess_list = qw/cp037 cp500 cp875 cp1026 cp1047 posix-bc/;	## All Encode::EBCDIC supporteds
  }
  
  unless ($encoding) {
    $self->_raise_error ($o, type => 'WARN_NO_EXPLICIT_ENCODING_INFO');
    require Encode::Guess;
    unless (@guess_list) {
      @guess_list = qw/utf-8 utf-16 utf-16be utf-16le
                       7bit-jis euc-jp shift_jis gbk gb18030 euc-kr big5-eten big5-hkscs
                       iso-8859-1 iso-8859-8 koi8-r koi8-u tis-620
                       windows-1252/;
    }
    my @gl;
    for (@guess_list) {
      push @gl, $_ if Encode::find_encoding ($_);
    }
    my $enc;
    eval q{$enc = Encode::Guess::guess_encoding ($entity, @gl); 1}
      or $self->_raise_error ($o, type => 'WARN_GUESS_ENCODING_IMPL_ERR', t => $@);
    $encoding = $enc->name if ref $enc;
  }
  $encoding;
}

## Check whether the media type specified is better one for that type of entity
## and raise error if not --- See RFC 3023
## 
## Known error: Warn even when source is local file doesn't have meta type information
##              (but LWP give inappropreate value such as 'text/plain').  This is an error but spec.
sub _check_media_type ($$$) {
  my ($self, $o, $ct) = @_;
  if ($ct eq 'application/xml' || $ct eq 'text/xml') {
      if ($o->{entity_type} eq 'external_parsed_entity'
       || $o->{entity_type} eq 'external_general_parsed_entity') {
        $self->_raise_error ($o, type => 'WARN_MT_XML_FOR_EXT_GENERAL_ENTITY', t => $ct);
      } elsif ($o->{entity_type} ne 'document_entity') {
        $self->_raise_error ($o, type => 'ERR_MT_XML_FOR_EXT_ENTITY', t => $ct);
      }
      if ($ct eq 'text/xml') {
        $self->_raise_error ($o, type => 'WARN_MT_TEXT_XML');
      }
  } elsif ($o->{entity_type} eq 'external_general_parsed_entity') {
        if ($ct eq 'text/xml-external-parsed-entity') {
          $self->_raise_error ($o, type => 'WARN_MT_TEXT_XML_EXTERNAL_PARSED_ENTITY');
        } elsif ($ct ne 'application/xml-external-parsed-entity') {
          $self->_raise_error ($o, type => 'WARN_MT_EXTERNAL_GENERAL_PARSED_ENTITY', t => $ct);
        }
  } elsif ($o->{entity_type} eq 'dtd_external_subset'
        || $o->{entity_type} eq 'external_parameter_entity') {
    if ($ct ne 'application/xml-dtd') {
      $self->_raise_error ($o, type => 'WARN_MT_DTD_EXTERNAL_SUBSET', t => $ct);
    }
  }
}

sub option ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
}

sub flag ($$;$) {
  my ($self, $name, $value) = @_;
  if (defined $value) {
    $self->{flag}->{$name} = $value;
  }
  $self->{flag}->{$name};
}

## $self->_raise_error: Raising error or warn
require SuikaWiki::Markup::XML::Error;
*_raise_error = \&SuikaWiki::Markup::XML::Error::raise;

=head1 DEVELOPER'S NOTE

This module "knows" how SuikaWiki::Markup::XML works, i.e. this module accesses
internal structure of that module directly.

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/07/16 12:10:22 $
