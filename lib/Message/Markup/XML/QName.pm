
=head1 NAME

Message::Markup::XML::XPath --- manakai XML : XML Path Language (XPath) support

=head1 DESCRIPTION

This module implements abstracted XPath object and its
serialization to the expression.

To parse XPath expression, use Message::Markup::XML::XPath::Parser.

This module is part of manakai XML.

=cut

package Message::Markup::XML::QName;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NCNameStartChar InXMLNCNameChar!;
use Exporter;
our @ISA = qw/Exporter/;

our %NS = (
           internal_ns_invalid	=> q<http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#>,
           xml	=> q<http://www.w3.org/XML/1998/namespace>,
           xmlns	=> q<http://www.w3.org/2000/xmlns/>,
           xpath => q<urn:x-suika-fam-cx:markup:xpath:>,
           xslt => q<urn:x-suika-fam-cx:markup:xslt:>,
);

our @EXPORT_OK = qw/DEFAULT_PFX NULL_URI UNDEF_URI/;
sub DEFAULT_PFX () { q:#default: }
sub NULL_URI    () { q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/null> }
sub UNDEF_URI   () { q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef> }

our %Namespace_URI_to_prefix 
  = (
     q<DAV:>	=> [qw:dav webdav:],
	'http://members.jcom.home.ne.jp/jintrick/2003/02/site-concept.xml#'	=> [DEFAULT_PFX, qw/sitemap/],
	'http://purl.org/dc/elements/1.1/'	=> [qw/dc dc11/],
	'http://purl.org/rss/1.0/'	=> [DEFAULT_PFX, qw/rss rss10/],
	'http://www.mozilla.org/xbl'	=> [DEFAULT_PFX, qw/xbl/],
	'http://www.w3.org/1999/02/22-rdf-syntax-ns#'	=> [qw/rdf/],
     q<http://www.w3.org/1999/xhtml>	=> [DEFAULT_PFX, qw:h h1 xhtml xhtml1:],
	'http://www.w3.org/1999/xlink'	=> [qw/l xlink/],
	'http://www.w3.org/1999/XSL/Format'	=> [qw/fo xslfo xsl-fo xsl/],
	'http://www.w3.org/1999/XSL/Transform'	=> [qw/t s xslt xsl/],
	'http://www.w3.org/1999/XSL/TransformAlias'	=> [qw/axslt axsl xslt xsl/],
	'http://www.w3.org/2000/01/rdf-schema#'	=> [qw/rdfs/],
	'http://www.w3.org/2000/svg'	=> [DEFAULT_PFX, qw/s svg/],
	'http://www.w3.org/2002/06/hlink'	=> [qw/h hlink/],
	'http://www.w3.org/2002/06/xhtml2'	=> [DEFAULT_PFX, qw/h h2 xhtml xhtml2/],
	'http://www.w3.org/2002/07/owl'	=> [qw/owl/],
	'http://www.w3.org/TR/REC-smil'	=> [DEFAULT_PFX, qw/smil smil1/],
	'http://www.wapforum.org/2001/wml'	=> [qw/wap/],
	'urn:schemas-microsoft-com:xslt'	=> [qw/ms msxsl msxslt/],
	'urn:x-suika-fam-cx:markup:ietf:html:3:draft:00:'	=> [DEFAULT_PFX, qw/H3 H HTML HTML3/],
	'urn:x-suika-fam-cx:markup:ietf:rfc:2629:'	=> [DEFAULT_PFX, qw/rfc rfc2629/],
);

sub register_prefix_to_name ($$$;%) {
  my ($decls, $prefix => $name, %opt) = @_;
  if ($opt{check_prefix}) {
    my $chk = __check_prefix ($decls, $prefix, \%opt);
    return $chk unless $chk->{success};
    $prefix = $chk->{prefix};
  } else {
    $prefix = DEFAULT_PFX if $prefix eq '';
  }
  return {success => 0, reason => 'NAME'} if $name eq UNDEF_URI;
  if ($opt{check_name}) {
    my $chk = __check_name ($decls, $name, \%opt);
    return $chk unless $chk->{success};
    $name = $chk->{name};
  } else {
    $name = NULL_URI if $name eq '';
  }
  if ($opt{check_xml}) {
    return {success => 0, name => $name, prefix => $prefix, reason => 'XML'}
      if ($prefix eq 'xml' && $name ne $NS{xml})
      || ($name eq $NS{xml} && $prefix ne 'xml');
  }
  if ($opt{check_xmlns}) {
    return {success => 0, name => $name, prefix => $prefix, reason => 'XMLNS'}
      if ($prefix eq 'xmlns' && $name ne $NS{xmlns})
      || ($name eq $NS{xmlns} && $prefix ne 'xmlns');
  }
  if ($name eq NULL_URI && $prefix ne DEFAULT_PFX) {
    return {success => 0, prefix => $prefix, reason => '__NON_DEFAULT_NULL_NS'};
  }
  
  if ($opt{check_registered_as_is}) {
    my $c = prefix_to_name ($decls, $prefix, %opt,
                            check_prefix => 0);
    if ($c->{success} && ($c->{name} eq $name)) {
      return {success => 1, name => $name, prefix => $prefix,
              reason => 'REGISTERED'};
    }
  } elsif ($opt{check_registered}) {
    my $c = prefix_to_name ($decls, $prefix, %opt,
                            check_prefix => 0);
    if ($c->{success}) {
      if ($c->{name} eq $name) {
        return {success => 1, name => $name, prefix => $prefix,
                reason => 'REGISTERED'};
      } elsif ($c->{name} eq UNDEF_URI) {
        ## 
      } elsif (defined $c->{name}) {
        return {success => 0, name => $name, prefix => $prefix,
                reason => 'REGISTERED'};
      }
    }
  }
  
  $decls->{ns}->{$prefix} = $name;
  
  return {success => 1, prefix => $prefix, name => $name};
}

## Check namespace prefix
sub __check_prefix ($$$) {
  my ($decls, $prefix, $opt) = @_;
  substr ($prefix, -1, 1) = '' if substr ($prefix, -1, 1) eq ':';
  if ($prefix eq '' || $prefix eq DEFAULT_PFX) {
    return {success => 0, prefix => DEFAULT_PFX, reason => 'PREFIX_DEFAULT'}
      unless $opt->{use_prefix_default};
    $prefix = DEFAULT_PFX;
  } else {
    return {success => 0, prefix => $prefix, reason => 'PREFIX_XML'}
      if $opt->{check_prefix_xml} && ($prefix eq 'xml');
    return {success => 0, prefix => $prefix, reason => 'PREFIX_XMLNS'}
      if ($opt->{check_prefix_xmlns} && ($prefix eq 'xmlns'));
    return {success => 0, prefix => $prefix, reason => 'PREFIX_XML_'}
      if $opt->{check_prefix_xml_} && (lc substr ($prefix, 0, 3) eq 'xml');
    return {success => 0, reason => 'PREFIX__NON_NCNAME'} 
      unless $prefix =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
  }
  
  if ($opt->{check_prefix_registered}) {
    return {success => 0, prefix => $prefix, reason => 'PREFIX_REGISTERED'}
      if (defined $decls->{ns}->{$prefix})
      && ($decls->{ns}->{$prefix} ne UNDEF_URI);
  }
  
  return {success => 1, prefix => $prefix};
}

## Check namespace name (namespace URI)
sub __check_name ($$$) {
  my ($decls, $name, $opt) = @_;
  if ($name eq '') {
    return {success => 0, name => NULL_URI, reason => 'NAME_NULL'}
      unless $opt->{use_name_null};
    $name = NULL_URI;
  } else {
    if ($opt->{check_name_uri}) {
      return {success => 0, reason => 'NAME_URI__NON_URI_CHAR'}
        if $name =~ m{[^0-9A-Za-z_.!~*'();/?:\@&=+\$,%\[\]#-]};
    }
    if ($opt->{resolve_name_uri_relative}) {
      $name = $decls->resolve_relative_uri ($name)
        unless $name =~ /^[0-9A-Za-z.%+-]+:/;
    } elsif ($opt->{check_name_uri_relative}) {
      return {success => 0, reason => 'NAME_URI_RELATIVE'}
        unless $name =~ /^[0-9A-Za-z.%+-]+:/;
    }
    return {success => 0, name => $name, reason => 'NAME_XML'}
      if $opt->{check_name_xml} && ($name eq $NS{xml});
    return {success => 0, name => $name, reason => 'NAME_XMLNS'}
      if $opt->{check_name_xmlns} && ($name eq $NS{xmlns});
  }
  
  if ($opt->{check_name_registered}) {
    for (keys %{$decls->{ns}||{}}) {
      return {success => 0, name => $name, reason => 'NAME_REGISTERED'}
        if defined $decls->{ns}->{$_} eq $name;
    }
  }
  
  return {success => 1, name => $name};
}

sub prefix_to_name ($$;%);
sub prefix_to_name ($$;%) {
  my ($decls, $prefix, %opt) = @_;
  if ($opt{check_prefix}) {
    my $chk = __check_prefix ($decls, $prefix, \%opt);
    return $chk unless $chk->{success};
    $prefix = $chk->{prefix};
  } else {
    $prefix = DEFAULT_PFX if $prefix eq '';
  }
  
  my $decls_name = $decls->{ns}->{$prefix};
  $decls_name = '' unless defined $decls_name;
  if ($decls_name eq NULL_URI) {
    if ($opt{use_name_null} && ($prefix eq DEFAULT_PFX)) {
      return {success => 1, prefix => $prefix, name => NULL_URI};
    } else {
      return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
    }
  } elsif (length $decls_name) {
    if ($decls_name eq UNDEF_URI) {
      return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
    } else {
      return {success => 1, prefix => $prefix, name => $decls_name};
    }
  } else {
    if ($opt{ask_parent_node} && ref $decls->{parent}) {    
      return prefix_to_name ($decls->{parent}->_get_ns_decls_node, $prefix, %opt,
                             check_prefix => 0);
    } else {
      if ($opt{use_name_null} && ($prefix eq DEFAULT_PFX)) {
        return {success => 1, prefix => $prefix, name => NULL_URI};
      } else {
        return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
      }
    }
  }
}

sub name_to_prefix ($$;%);
sub name_to_prefix ($$;%) {
  my ($decls, $name, %opt) = @_;
  if ($opt{check_name}) {
    my $chk = __check_name ($decls, $name, \%opt);
    return $chk unless $chk->{success};
    $name = $chk->{name};
  } else {
    $name = NULL_URI if not defined $name or $name eq '';
  }
  for my $prefix (%{$decls->{ns}||{}}) {
    if (defined $decls->{ns}->{$prefix}
    and $decls->{ns}->{$prefix} eq $name) {
      if (!$opt{use_prefix_default} && ($prefix eq DEFAULT_PFX)) {
        #return {success => 0, name => $name, reason => '__NOT_FOUND'};
      } else {
        return {success => 1, prefix => $prefix, name => $name};
      }
    }
  }
  if ($opt{ask_parent_node} and ref $decls->{parent}) {
    ## Document element node will not have parent decls node
    my $decl_node = $decls->{parent}->_get_ns_decls_node (default => 0);
    if (ref $decl_node) {  
      return name_to_prefix ($decls->{parent}->_get_ns_decls_node, $name, %opt,
                             check_name => 0);
    }
  }

    if ($opt{use_prefix_default} && ($name eq NULL_URI)) {
      $decls->{ns}->{(DEFAULT_PFX)} = NULL_URI
        if (not $decls->{ns}->{(DEFAULT_PFX)}
        or $decls->{ns}->{(DEFAULT_PFX)} ne NULL_URI);
      return {success => 1, name => $name, prefix => DEFAULT_PFX};
    } elsif ($opt{make_new_prefix}) {
      return register_prefix_to_name ($decls,
                                      generate_prefix ($decls, $name, %opt)
                                      => $name, 
                                      %opt);
    } else {
      return {success => 0, name => $name, reason => '__NOT_FOUND'};
    }
  
}

sub generate_prefix ($;$%) {
  my ($decls, $name, %opt) = @_;
  return DEFAULT_PFX #if $opt{use_prefix_default} && ($name eq NULL_URI);
    if $name eq NULL_URI;
  if ($Namespace_URI_to_prefix{$name}) {
    for (@{$Namespace_URI_to_prefix{$name}}) {
      my $pfx = $_;
      next if !$opt{use_prefix_default} && ($pfx eq DEFAULT_PFX);
      unless (prefix_to_name ($decls, $pfx, %opt, check_prefix => 0)
              ->{success}) {
        return $pfx;
      }
    }
  }
    my ($uri, $pfx) = ($name);
    $uri =~ s/[^0-9A-Za-z._-]+/ /g;
    my @uri = split / /, $uri;
    for (reverse @uri) {
      if (s/([A-Za-z][0-9A-Za-z._-]+)//) {
        next if lc (substr ($1, 0, 3)) eq 'xml';
        unless (prefix_to_name ($decls, $1, %opt, check_prefix => 0)
                ->{success}) {
          return $1;
        }
      }
    }
    my $i = 0;
    while (1) {
      $pfx = 'ns'.$i++;
      unless (prefix_to_name ($decls, $pfx, %opt, check_prefix => 0)
              ->{success}) {
        return $pfx;
      }
    }
}

sub qname_to_expanded_name ($$;%) {
  my ($decls, $qname, %opt) = @_;
  my $chk = split_qname ($qname, %opt);
  return $chk unless $chk->{success};
  my $chk2 = prefix_to_name ($decls, $chk->{prefix}, %opt);
  return $chk2 unless $chk2->{success};
  $chk->{name} = $chk2->{name};
  return $chk;
}

sub expanded_name_to_qname ($$$;%) {
  my ($decls, $name => $ln, %opt) = @_;
  my $chk = name_to_prefix ($decls, $name, %opt);
  return $chk unless $chk->{success};
  return join_qname ($chk->{prefix}, $ln, %opt);
}

sub split_qname ($;%) {
  my ($qname, %opt) = @_;
  $opt{qname_separator} ||= ':';
  my ($pfx, $ln) = split /\Q$opt{qname_separator}/, $qname, 2;
  
  if ($opt{check_qname}) {
    if ((substr ($qname, 0,  1) eq $opt{qname_separator})
     || (substr ($qname, 0, -1) eq $opt{qname_separator})) {
      return {success => 0, reason => 'QNAME__INVALID_COLON'};
    }
  }
  
  if (defined $ln) {
    if ($opt{check_qname} || $opt{check_prefix}) {
      return {success => 0, reason => 'PREFIX__INVALID'}
        unless $pfx =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
    }
    if ($opt{check_qname} || $opt{check_local_name}) {
      return {success => 1, prefix => $pfx, local_name_star => 1}
        if $ln eq '*';
      return {success => 0, reason => 'LOCAL_NAME__INVALID'}
        unless $ln =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
    }
    return {success => 1, prefix => $pfx, local_name => $ln};
  } else {
    if ($opt{check_qname} || $opt{check_local_name}) {
      return {success => 1, prefix => DEFAULT_PFX, local_name_star => 1}
        if $pfx eq '*';
      return {success => 0, reason => 'LOCAL_NAME__INVALID'}
        unless $pfx =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
    }
    return {success => 1, prefix => DEFAULT_PFX, local_name => $pfx};
  }
}

sub join_qname ($$;%) {
  my ($pfx, $ln, %opt) = @_;
  $pfx ||= DEFAULT_PFX unless defined $pfx and $pfx eq '0';
  $opt{qname_separator} ||= ':';
  if ($opt{check_qname} || $opt{check_prefix}) {
    if ($pfx ne DEFAULT_PFX) {
      return {success => 0, reason => 'PREFIX__INVALID'}
        unless $pfx =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
    }
  }
  if ($opt{check_qname} || $opt{check_local_name}) {
    return {success => 1, qname => ($pfx eq DEFAULT_PFX ? '*' :
                                    $pfx.$opt{qname_separator}.'*')}
      if $opt{use_local_name_star} && ($ln eq '*');
    return {success => 0, reason => 'LOCAL_NAME__INVALID'}
      unless $ln =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
  }
  return {success => 1, qname => ($pfx eq DEFAULT_PFX ? $ln :
                                  $pfx.$opt{qname_separator}.$ln)};
}

sub split_expanded_uri ($) {
  my $uri = shift;
  if ($uri =~ s<([A-Za-z_][A-Za-z0-9_.-]*)$><>) {
    return {success => 1, name => $uri, local_name => $1};
  } else {
    return {success => 0};
  }
}

sub split_expanded_iri ($) {
  my $iri = shift;
  if ($iri =~ s<(\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*)$><>) {
    return {success => 1, name => $iri, local_name => $1};
  } else {
    return {success => 0};
  }
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/10/31 08:41:35 $
