
=head1 NAME

Message::Markup::XML::QName - manakai: QName support

=head1 DESCRIPTION

C<Message::Markup::XML::QName> module implements QName related functions,
such as QName to expanded name convertion.

This module is part of manakai XML.

=cut

package Message::Markup::XML::QName;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.12.2.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Char::Class::XML qw!InXML_NCNameStartChar InXMLNCNameChar!;
use Exporter;
our @ISA = qw/Exporter/;
require Carp;

our @EXPORT_OK = qw/DEFAULT_PFX ZERO_PFX EMPTY_PFX
                    NULL_URI UNDEF_URI NS_xml_URI NS_xmlns_URI
                    ZERO_URI EMPTY_URI/;
our %EXPORT_TAGS = (
  prefix => [qw/DEFAULT_PFX ZERO_PFX EMPTY_PFX/],
  'special-uri' => [qw/NULL_URI UNDEF_URI ZERO_URI EMPTY_URI/],
  xml => [qw/NS_xml_URI NS_xmlns_URI/],
);

sub DEFAULT_PFX () { q:#default: }
sub EMPTY_PFX   () { q:#empty: }
sub ZERO_PFX    () { q:#zero: }
sub NULL_URI    () { q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/null> }
sub UNDEF_URI   () { q<http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef> }
sub ZERO_URI    () { q<http://suika.fam.cx/~wakaba/-temp/2003/12/05/zero> }
sub EMPTY_URI   () { q<http://suika.fam.cx/~wakaba/-temp/2003/12/05/empty> }
sub NS_xml_URI  () { q<http://www.w3.org/XML/1998/namespace> }
sub NS_xmlns_URI() { q<http://www.w3.org/2000/xmlns/> }
#sub NS_INVALID_URI(){q<http://suika.fam.cx/~wakaba/-temp/2003/05/17/unknown-namespace#> }

=head1 CONSTANTS

C<Message::Markup::XML::QName> provides some constant functions
represent special URI references or namespace prefix.
These functions can be imported by C<use>'ing as:

  use Message::Markup::XML::QName qw(DEFAULT_PFX NULL_URI);

=over 4

=item DEFAULT_PFX = "#default"

Default namespace prefix, i.e. no prefix.

Note that some applications (eg. XSLT) interprets C<#default>
as no prefix, so that this constant function can be specified instead
of such literal value.

=item EMPTY_URI

Empty URI reference.  Manakai XML modules use this constant function
internally, since Perl considers empty (zero-length) string as false.

Empty URI reference is not allowed by XML Namespace specification
but can be used with other specification, suchs as DOM 2.

=item NS_xml_URI

Namespace name URI for C<xml>.  Namespace prefix C<xml> and namespace name
corresponding to it is reserved by XML and XML Namespace specifications
and took special treatement.

=item NS_xmlns_URI

Namespace name URI for C<xmlns>.  Namespace prefix C<xmlns> and 
namespace name corresponding to it is reserved by XML and XML Namespace
specifications and took special treatement.

=item NULL_URI

Null namespace name.  In XML, namespace declaration C<xmlns="">
makes namespace name binded to default namespace (ie. C<DEFAULT_PFX> namespace)
null.  Manakai XML modules use constant function C<NULL_URI> for
null namespace.

=item UNDEF_URI

Namespace name is undefined.  In other word, namespace prefix is 
binded to no namespace name.  In XML 1.1, this is represented by
namespace declaration C<xmlns:I<prefix>="">.

=item ZERO_URI

Namespace name that is exact C<0>.  Manakai XML modules use this constant
function for internal procedures, since C<0> is considered as false in Perl.

Note that using relative URI reference as namespace name is deprecated.

=back

Don't try to use these constant functions to place left hand of C<< => >>
operator, which make Perl interprets left hand bare value as a string.

  x  something (DEFAULT_PFX => NULL_URI);
  o  something (DEFAULT_PFX () => NULL_URI);
  o  something ((DEFAULT_PFX) => NULL_URI);
  o  something (+DEFAULT_PFX => NULL_URI);
  o  something (DEFAUT_PFX, NULL_URI);

=cut

our %Namespace_URI_to_prefix 
  = (
     q<DAV:>	=> [qw:DAV dav webdav:],
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

=head1 FUNCTIONS

@@

=cut

sub register_prefix_to_name ($$$;%) {
  my ($decls, $prefix => $name, %opt) = @_;
  if ($opt{check_prefix}) {
    my $chk = __check_prefix ($decls, $prefix, \%opt);
    return $chk unless $chk->{success};
    $prefix = $chk->{prefix};
  } else {
    $prefix = $opt{use_prefix_empty} ? EMPTY_PFX : DEFAULT_PFX if $prefix eq '';
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
      if ($prefix eq 'xml' && $name ne NS_xml_URI)
      || ($name eq NS_xml_URI && $prefix ne 'xml');
  }
  if ($opt{check_xmlns}) {
    return {success => 0, name => $name, prefix => $prefix, reason => 'XMLNS'}
      if ($prefix eq 'xmlns' && $name ne NS_xmlns_URI)
      || ($name eq NS_xmlns_URI && $prefix ne 'xmlns');
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
  } elsif ($opt->{use_prefix_empty} and $prefix eq EMPTY_PFX) {
    #
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
      require Message::Markup::XML::NodeTree,
      $name = $decls->Message::Markup::XML::NodeTree::resolve_relative_uri 
                ($name) unless $name =~ /^[0-9A-Za-z.%+-]+:/;
    } elsif ($opt->{check_name_uri_relative}) {
      return {success => 0, reason => 'NAME_URI_RELATIVE'}
        unless $name =~ /^[0-9A-Za-z.%+-]+:/;
    }
    return {success => 0, name => $name, reason => 'NAME_XML'}
      if $opt->{check_name_xml} && ($name eq NS_xml_URI);
    return {success => 0, name => $name, reason => 'NAME_XMLNS'}
      if $opt->{check_name_xmlns} && ($name eq NS_xmlns_URI);
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
  if ($opt{use_xml} and $prefix eq 'xml') {
    return {success => 1, prefix => $prefix, name => NS_xml_URI};
  } elsif ($opt{use_xmlns} and $prefix eq 'xmlns') {
    return {success => 1, prefix => $prefix, name => NS_xmlns_URI};
  } elsif ($opt{check_prefix}) {
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
      my $parent_decls = $decls->{parent}->_get_ns_decls_node (default => "n/a");
      return prefix_to_name ($parent_decls, $prefix, %opt,
                             check_prefix => 0) if ref $parent_decls;
    }
    if ($opt{use_name_null} and
        not $opt{ignore_implicit_null} and
        $prefix eq DEFAULT_PFX) {
      return {success => 1, prefix => $prefix, name => NULL_URI};
    } else {
      return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
    }
  }
}

sub name_to_prefix ($$;%);
sub name_to_prefix ($$;%) {
  my ($decls, $name, %opt) = @_;
  Carp::croak 'Use NULL_URI instead of empty string or undef'
      unless defined $name;
  if ($opt{use_xml} and $name eq NS_xml_URI) {
    return {success => 1, prefix => 'xml', name => $name};
  } elsif ($opt{use_xmlns} and $name eq NS_xmlns_URI) {
    return {success => 1, prefix => 'xmlns', name => $name};
  } elsif ($opt{check_name}) {
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
      my $p = name_to_prefix ($decls->{parent}->_get_ns_decls_node, $name, %opt,
                              check_name => 0, make_new_prefix => 0,
                              preserve_prefix_default => 1);
      return $p if $p->{success};
    }
  }

    if (($opt{use_prefix_default} or $opt{use_prefix_default_null})
        and $name eq NULL_URI
        and not $opt{preserve_prefix_default}) {
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
      unless (prefix_to_name ($decls, $pfx, %opt, check_prefix => 0,
                              ignore_implicit_null => 1)
              ->{success}) {
        return $pfx;
      }
    }
  }
    my ($uri, $pfx) = ($name);
    $uri =~ s/[^0-9A-Za-z._-]+/ /g;
    my @uri = split / /, $uri;
    for (reverse @uri) {
      if (s/([A-Za-z][0-9A-Za-z._-]*)//) {
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
    if ($opt{use_prefix_empty}) {
      return {success => 0, reason => 'QNAME__INVALID_COLON'}
        if substr ($qname, -1) eq $opt{qname_separator};
    } elsif (
        (substr ($qname, 0,  1) eq $opt{qname_separator})
     || (substr ($qname, -1) eq $opt{qname_separator})) {
      return {success => 0, reason => 'QNAME__INVALID_COLON'};
    }
  }
  
  if (defined $ln) {
    if ($opt{check_qname} || $opt{check_prefix}) {
      return {success => 0, reason => 'PREFIX__INVALID'}
        unless $pfx =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/ or
              ($opt{use_prefix_empty} and $pfx eq '');
    }
    if ($opt{check_qname} || $opt{check_local_name}) {
      return {success => 1, prefix => $pfx, local_name_star => 1}
        if $ln eq '*';
      return {success => 0, reason => 'LOCAL_NAME__INVALID'}
        unless $ln =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
    }
    if ($pfx eq '') {
      $pfx = EMPTY_PFX;
    } elsif ($pfx eq '0') {
      $pfx = ZERO_PFX;
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
  $pfx = DEFAULT_PFX unless defined $pfx;
  $opt{qname_separator} ||= ':';
  if ($opt{check_qname} || $opt{check_prefix}) {
    if ($pfx ne DEFAULT_PFX and
        not ($pfx eq EMPTY_PFX and $opt{use_prefix_empty})) {
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
                                  $pfx eq EMPTY_PFX ? $opt{qname_separator}.$ln:
                                  $pfx eq ZERO_PFX?'0'.$opt{qname_separator}.$ln:
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

Copyright 2003-2004 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2004/02/24 07:27:12 $
