
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
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
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

## TODO: auto register

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
  
  if ($opt{check_registered}) {
    if ($decls->{ns}->{$prefix} eq $name) {
      return {success => 1, name => $name, prefix => $prefix,
              reason => 'REGISTERED'};
    } elsif ($decls->{ns}->{$prefix} eq UNDEF_URI) {
      ## 
    } elsif (defined $decls->{ns}->{$prefix}) {
      return {success => 0, name => $name, prefix => $prefix,
              reason => 'REGISTERED'};
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
    return {success => 0, prefix => DEFAULT_PFX, reason => 'DEFAULT_NAMESPACE'}
      unless $opt->{use_default_namespace};
    $prefix = DEFAULT_PFX;
  } else {
    return {success => 0, prefix => $prefix, reason => 'PREFIX_XML'}
      if $opt->{check_prefix_xml} && ($prefix eq 'xml');
    return {success => 0, prefix => $prefix, reason => 'PREFIX_XMLNS'}
      if ($opt->{check_prefix_xmlns} && ($prefix eq 'xmlns'));
    return {success => 0, reason => 'PREFIX__NON_NCNAME'} 
      if $prefix !~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
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
      if $opt->{check_name_xml} && $name eq $NS{xml};
    return {success => 0, name => $name, reason => 'NAME_XMLNS'}
      if $opt->{check_name_xmlns} && $name eq $NS{xmlns};
  }
  
  if ($opt->{check_name_registered}) {
    for (keys %{$decls->{ns}||{}}) {
      return {success => 0, name => $name, reason => 'NAME_REGISTERED'}
        if defined $decls->{ns}->{$_} eq $name;
    }
  }
  
  return {success => 1, name => $name};
}

sub prefix_to_name ($$;%) {
  my ($decls, $prefix, %opt) = @_;
  if ($opt{check_prefix}) {
    my $chk = __check_prefix ($decls, $prefix, \%opt);
    return $chk unless $chk->{success};
    $prefix = $chk->{prefix};
  } else {
    $prefix = DEFAULT_PFX if $prefix eq '';
  }
  
  if ($decls->{ns}->{$prefix} eq NULL_URI) {
    if ($opt{use_name_null} && ($prefix eq DEFAULT_PFX)) {
      return {success => 1, prefix => $prefix, name => NULL_URI};
    } else {
      return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
    }
  } elsif (length $decls->{ns}->{$prefix}) {
    if ($decls->{ns}->{$prefix} eq UNDEF_URI) {
      return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
    } else {
      return {success => 1, prefix => $prefix,
              name => $decls->{ns}->{$prefix}};
    }
  } elsif ($opt{use_name_null} && ($prefix eq DEFAULT_PFX)) {
    return {success => 1, prefix => $prefix, name => NULL_URI};
  } else {
    return {success => 0, prefix => $prefix, reason => '__NOT_FOUND'};
  }
}

sub name_to_prefix ($$;%) {
  my ($decls, $name, %opt) = @_;
  if ($opt{check_name}) {
    my $chk = __check_name ($decls, $name, \%opt);
    return $chk unless $chk->{success};
    $name = $chk->{name};
  } else {
    $name = NULL_URI if $name eq '';
  }
  for my $prefix (%{$decls->{ns}||{}}) {
    if ($decls->{ns}->{$prefix} eq $name) {
      if (!$opt{use_prefix_default} && ($prefix eq DEFAULT_PFX)) {
        return {success => 0, name => $name, reason => '__NOT_FOUND'};
      } else {
        return {success => 1, prefix => $prefix, name => $name};
      }
    }
  }
  if ($opt{use_prefix_default} && ($name eq NULL_URI)) {
    return {success => 1, name => $name, prefix => DEFAULT_PFX};
  } else {
    return {success => 0, name => $name, reason => '__NOT_FOUND'};
  }
}

sub qname_to_expanded_name ($$;%) {
  my ($decls, $qname, %opt) = @_;
  my $chk = split_qname ($qname, %opt);
  return $chk unless $chk->{success};
  my $chk2 = prefix_to_name ($decls, $chk->{prefix});
  return $chk2 unless $chk2->{success};
  $chk->{name} = $chk2->{name};
  return $chk;
}

## TODO: exp.name to qname
## TODO: exp.uri

sub split_qname ($;%) {
  my ($qname, %opt) = @_;
  my ($pfx, $ln) = split /:/, $qname, 2;
  
  if ($opt{check_qname}) {
    if ((substr ($qname, 0,  1) eq ':')
     || (substr ($qname, 0, -1) eq ':')) {
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
  $pfx = DEFAULT_PFX unless defined $pfx;
  if ($opt{check_qname} || $opt{check_prefix}) {
    if ($pfx ne DEFAULT_PFX) {
      return {success => 0, reason => 'PREFIX__INVALID'}
        unless $pfx =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
    }
  }
  if ($opt{check_qname} || $opt{check_local_name}) {
    return {success => 1, qname => ($pfx eq DEFAULT_PFX ? '*' : $pfx.':*')}
      if $opt{use_local_name_star} && ($ln eq '*');
    return {success => 0, reason => 'LOCAL_NAME__INVALID'}
      unless $ln =~ /^\p{InXML_NCNameStartChar}\p{InXMLNCNameChar}*$/;
  }
  return {success => 1, qname => ($pfx eq DEFAULT_PFX ? $ln : $pfx.':'.$ln)};
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/09/27 07:59:11 $
