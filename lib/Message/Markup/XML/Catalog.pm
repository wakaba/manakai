
=head1 NAME

SuikaWiki::Markup::XML::Catalog --- SuikaWiki XML: XML Catalog implementation

=head1 DESCRIPTION

This module provides support for ths XML Catalog, defined by the OASIS Entity
Resolution Technical Committee.

This module is part of SuikaWiki XML support.

=cut

package SuikaWiki::Markup::XML::Catalog;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require SuikaWiki::Markup::XML;
require URI;
our %NS = (
	catalog	=> 'urn:oasis:names:tc:entity:xmlns:xml:catalog',
	xml	=> 'http://www.w3.org/XML/1998/namespace',
	xmlns	=> 'http://www.w3.org/2000/xmlns/',
);

our %Catalog;
# %Catalog	Hash of catalog entry file objects already read
# $catalog_processor
# ->{checked_catalogs}	Hash reference of URIs of catalog entry files already processed
# ->{current_catalogs}	Array reference of URIs of current catalog entry files list
# ->{error}	SuikaWiki::Markup::XML::Error object
# ->{parent}	Parent catalog processor if any

# $catalog_entry_file
# ->{document}	SuikaWiki::Markup::XML object for #document node of object
# ->

sub new ($) {
  my $self = bless {}, shift;
  require SuikaWiki::Markup::XML::Error;
  $self->{error} = SuikaWiki::Markup::XML::Error->new ({
    DTD_OF_XC_NOT_READ	=> {
    	description	=> q(DTD of XML Catalog 1.0 (PUBLIC "%s" SYSTEM "%s") is not read),
    	level	=> q(warn),
    },
    URI_HAVE_FRAGMENT	=> {
    	description	=> q(URI reference <%s> should not have fragment identifier),
    	level	=> q(skip),
    },
    URI_INVALD_CHAR	=> {
    	description	=> q(URI reference <%s> have at least one invalid character (%s)),
    	level	=> q(skip),
    },
    URN_PUBID_INVALD_CHAR	=> {
    	description	=> q(Public identifier URN <%s> have at least one invalid character (%s)),
    	level	=> q(skip),
    },
    XC_BASE_ATTR_NOT_ALLOWED	=> {
    	description	=> qq(xml:base attribute is not allowed here),
    	level	=> q(skip),
    },
    XC_CATALOG_REF_CIRCULAR	=> {
    	description	=> qq(Catalog entry file <%s> is circulary referred),
    	level	=> q(skip),
    },
    XC_ERR_PUBID_NE_SYSID_URN_PUBID	=> {
    	description	=> qq(Public identifier (%s) and one wrapped in the system identifier (%s) does not match),
    	level	=> q(skip),
    },
    XC_NO_REQUIRED_ATTR	=> {
    	description	=> qq(Required attribute "%s" not specified),
    	level	=> q(skip),
    },
    XC_UNKNOWN_ROOT_ELEMENT	=> {
    	description	=> qq(Root element of the catalog ("{%s}:%s") must be "{$NS{catalog}}:catalog"),
    	level	=> q(skip),
    },
    XC_UNKNOWN_CHILD_ELEMENT	=> {
    	description	=> qq(Entry type "{%s}:%s" is not supported),
    	level	=> q(skip),
    },
    XML_PARSE_FATAL_ERROR	=> {
    	description	=> q(XML parse fatal error: %s),
    	level	=> q(skip),
    },
    XML_PARSE_ERROR	=> {
    	description	=> q(XML parse warning: %s),
    	level	=> q(skip),
    },
    XML_PUBID_EMPTY	=> {
    	description	=> q(Public identifier is an empty string),
    	level	=> q(skip),
    },
    XML_PUBID_INVALD_CHAR	=> {
    	description	=> q(Public identifier "%s" have at least one invalid character (%s)),
    	level	=> q(skip),
    },
    XML_RETRIVE_ERROR	=> {
    	description	=> q(Catalog file <%s> cannot be retrived: %s),
    	level	=> q(skip),
    },
    XML_SYSID_HAS_FRAGMENT	=> {
    	description	=> q(System identifier "%s" have the fragment identifier (%s)),
    	level	=> q(skip),
    },
    XML_SYSID_INVALD_URI_CHAR	=> {
    	description	=> q(System identifier "%s" have at least one invalid URI character (%s)),
    	level	=> q(skip),
    },
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

sub add_catalog_entry_file ($$$) {
  my ($self, $uri, $root_node) = @_;
  $self->{catalogs}->{$uri} = $root_node;
}

## parent catalog entry files
## catalog 1-1
## catalog 1-2
## catalog 1-3
##          +---> delegated catalog entry files
##                catalog 2-1
##              x catalog 1-1
##              x catalog 1-3
## catalog 1-4
sub _is_catalog_entry_file_opened ($$) {
  my ($self, $catalog_uri) = @_;
  return 1 if $self->{checked_catalogs}->{$catalog_uri};
  #return 1 if $self->{current_catalogs}->[0] eq $catalog_uri;
  return $self->{parent}->_is_catalog_entry_file_opened ($catalog_uri) if ref $self->{parent};
  return 0;
}

sub _normalize_public_id ($$;%) {
  my ($self, $pubid, %opt) = @_;
  if (length ($pubid) == 0) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri}, type => 'XML_PUBID_EMPTY');
  }
  if ($pubid =~ m"([^\x0A\x0D\x20A-Za-z0-9'()+,./:=?;!*#\@\$_%-])"s) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri}, type => 'XML_PUBID_INVALD_CHAR',
                                 t => [$pubid, $1]);
  }
  $pubid =~ s/[\x0A\x0D\x20]+/\x20/gs;
  $pubid =~ s/^\x20//; $pubid =~ s/\x20$//;
  $pubid;
}

sub _normalize_system_id ($$;%) {
  my ($self, $sysid, %opt) = @_;
  if ($sysid =~ m"([^0-9A-Za-z_.!~*'();/?:\@&=+\$,%\[\]#-])"s) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri},
                                 type => 'XML_SYSID_INVALD_URI_CHAR', t => [$sysid, $1]);
    if ($sysid =~ /[^\x00-\x7F]/) {
      require Encode;	## Turn off utf-8 flag
      $sysid = Encode::encode ('utf-8', $sysid);
    }
  }
  if ($sysid =~ s/(#[^#]*)$//g) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri},
                                 type => 'XML_SYSID_HAS_FRAGMENT', t => [$sysid, $1]);
  }
  ## Actal normalization is done by URI::*, in process to resolve relative URI reference.
  $sysid;
}

sub _check_uri ($$;%) {
  my ($self, $uri, %opt) = @_;
  if ($uri =~ m"([^0-9A-Za-z_.!~*'();/?:\@&=+\$,%\[\]#-])"s) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri},
                                 type => 'URI_INVALD_CHAR', t => [$uri, $1]);
    if ($uri =~ /[^\x00-\x7F]/) {
      require Encode;	## Turn off utf-8 flag
      $uri = Encode::encode ('utf-8', $uri);
    }
  }
  if ($opt{prohibit_fragment} && $uri =~ s/(#[^#]*)$//g) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri},
                                 type => 'URI_HAS_FRAGMENT', t => [$uri, $1]);
  }
  ## Actal normalization is done by URI::*, in process to resolve relative URI reference.
  $uri;
}

sub _pubid_to_urn ($$) {
  my ($self, $pubid) = @_;
  $pubid =~ s/([^A-Za-z0-9(),.=!*\@\$_-])/sprintf '%%%02X', ord $1/ge;
  	## Note: if $pubid contains [\x80-\x{inf}], this can make broken result,
  	##       but pubid cannot have non-ascii char.
  $pubid =~ s/%20/+/g;
  $pubid =~ s/%3A%3A/;/g;
  $pubid =~ s!%2F%2F!:!g;
  'urn:publicid:'.$pubid;
}
sub _urn_to_pubid ($$;%) {
  my ($self, $urn, %opt) = @_;
  $urn =~ s/^urn:publicid://i or return undef;
  if ($urn =~ m"([^A-Za-z0-9()+,.:=;!*\@\$_-])"s) {
    $self->{error}->raise_error ($opt{node}, uri => $opt{uri},
                                 type => 'URN_PUBID_INVALD_CHAR', t => [$urn, $1]);
  }
  $urn =~ s!:!//!g;
  $urn =~ s/;/::/g;
  $urn =~ s/\+/ /g;
  $urn =~ s/%([0-9A-Fa-f]{2})/chr hex $1/g;
  $self->_normalize_public_id ($urn, $opt{node});
}

# $xid->{public, system, uri} must be normalized one
sub resolve_external_id ($$%) {
  my ($self, $xid, %opt) = @_;
  my ($pubid, $sysid, $uri) = ($xid->{public}, $xid->{system}, $xid->{uri});
  ## [XCatalog 7.1.1] "urn:publicid:*" -> unwrapped public identifier
  if (lc (substr ($pubid, 0, 13) eq 'urn:publicid:')) {
    $pubid = $self->_urn_to_pubid ($pubid, node => undef, uri => undef);
  }
  if (lc (substr ($sysid, 0, 13) eq 'urn:publicid:')) {
    $sysid = $self->_urn_to_pubid ($sysid, node => undef, uri => undef);
    if (!defined $pubid) {
      $pubid = $sysid;
    } elsif ($pubid ne $sysid) {
      $self->{error}->raise_error (undef, type => 'XC_ERR_PUBID_NE_SYSID_URN_PUBID',
                                   uri => undef, t => [$pubid, $sysid]);
    }
    undef $sysid;
  }
  ## [XCatalog 7.2.1] <urn:publicid:*> -> unwrapped public identifier
  if (lc (substr ($uri, 0, 13) eq 'urn:publicid:')) {
    $pubid = $self->_urn_to_pubid ($pubid, node => undef, uri => undef);
    undef $uri;
  }
  
  $self->{current_catalogs} = [@{$opt{catalogs}}];
  ## Step 1/8 or Step 1/6
  while (my $c = shift @{$self->{current_catalogs}}) {
    $self->{checked_catalogs}->{$c} = 1+keys %{$self->{checked_catalogs}};
    my $uri = $self->_resolve_ext_id_w_catalog_file ({pubid => $pubid, sysid => $sysid,
                                                      uri => $uri}, $c);
    return $uri if defined $uri;
  }
  ## Step 9 or Step 6
  return (defined $xid->{system} ? $xid->{system}
        : defined $xid->{uri}    ? $xid->{uri}
        : $self->_pubid_to_urn ($xid->{public})) if $opt{return_default};
  return undef;
}

sub _resolve_ext_id_w_catalog_file ($$$) {
  my ($self, $xid, $file) = @_;
  ## Step 1
  my $cat = $self->_open_catalog_file ($file);
  return undef unless $cat;
  
  if (defined $xid->{sysid} || defined $xid->{uri}) {
    my $src_uri = defined $xid->{sysid} ? $xid->{sysid} : $xid->{uri};
    my $sys_or_uri = defined $xid->{sysid} ? 'system' : 'uri';
    ## Step 2
    for (@{$Catalog{$file}->{$sys_or_uri}}) {
      if ($_->{id} eq $src_uri) {
        return $_->{uri};
      }
    }
    
    ## Step 3
    for (@{$Catalog{$file}->{'rewrite_'.$sys_or_uri}}) {
      if ($_->{original_pfx}
       eq substr ($src_uri, 0, length ($_->{original_pfx}))) {
        return URI->new ($_->{result_pfx}.substr ($src_uri, length ($_->{original_pfx})));
      }
    }
    
    ## Step 4
    my @new_catalog;
    for (@{$Catalog{$file}->{'delegate_'.$sys_or_uri}}) {
      if ($_->{original_pfx}
       eq substr ($src_uri, 0, length ($_->{original_pfx}))) {
        my $new_catalog = $_->{catalog};
        if ($self->_is_catalog_entry_file_opened ($new_catalog)) {
          $self->{error}->raise_error (undef, type => 'XC_CATALOG_REF_CIRCULAR',
                                       t => $new_catalog, uri => $file);
        } else {
          push @new_catalog, $new_catalog;
        }
      }
    }
    if (scalar @new_catalog) {
      my $cat = ref ($self)->new;
      $cat->{parent} = $self;
      my $x = $cat->resolve_external_id ({$sys_or_uri => $src_uri}, catalogs => \@new_catalog);
      return $x if $x;
    }
  }	# sysid or uri
  if (defined $xid->{pubid}) {
    ## Step 5
    for (@{$Catalog{$file}->{public}}) {
      if (defined $xid->{sysid} && $_->{prefer} ne 'public') {
        # next;
      } elsif ($_->{id} eq $xid->{pubid}) {
        return $_->{uri};
      }
    }
    
    ## Step 6
    my @new_catalog;
    for (@{$Catalog{$file}->{delegate_public}}) {
      if ($_->{original_pfx}
       eq substr ($xid->{pubid}, 0, length ($_->{original_pfx}))) {
        my $new_catalog = $_->{catalog};
        if ($self->_is_catalog_entry_file_opened ($new_catalog)) {
          $self->{error}->raise_error (undef, type => 'XC_CATALOG_REF_CIRCULAR',
                                       t => $new_catalog, uri => $file);
        } else {
          push @new_catalog, $new_catalog;
        }
      }
    }
    if (scalar @new_catalog) {
      my $cat = ref ($self)->new;
      $cat->{parent} = $self;
      my $x = $cat->resolve_external_id ({public => $xid->{pubid}}, catalogs => \@new_catalog);
      return $x if $x;
    }
  }	# pubid
  
  ## Step 7 or Step 5
  push @{$self->{current_catalogs}}, map {$_->{catalog}} @{$Catalog{$file}->{additional_catalog}};
  
  return undef;
}

sub _open_catalog_file ($$) {
  my ($self, $file) = @_;
  return $Catalog{$file} if defined $Catalog{$file};
  
  my $p = {uri => $file};
  my $o = {uri => $file, entity_type => 'document_entity'};
  require SuikaWiki::Markup::XML::Parser;
  require SuikaWiki::Markup::XML::EntityManager;
  my $eh = sub {
  		my ($caller, $o, $error_type, $error_msg) = @_;
  		require Carp;
  		if ({qw/fatal 1 wfc 1/}->{$error_type->{level}}) {
  		  $self->{error}->raise_error (undef, uri => $file, type => 'XML_PARSE_FATAL_ERROR',
  		                               t => '{'.$error_type->{level}.'} '.$error_msg);
  		  die q(--SMXC::FATAL_ERROR--);
  		} else {
  		  $self->{error}->raise_error (undef, uri => $file, type => 'XML_PARSE_ERROR',
  		                               t => '{'.$error_type->{level}.'} '.$error_msg);
  		}
  		return 0;
  	};
  my $parser = SuikaWiki::Markup::XML::Parser->new (option => {error_handler => $eh,
  	uri_resolver => sub {
  		my ($himself, $parser, $decl, $p) = @_;
  		my $ures = $self->option ('uri_resolver', undef, -see_parent => 1);
  		&$ures (@_) if $ures;
  		if ($p->{PUBLIC} eq '-//OASIS//DTD Entity Resolution XML Catalog V1.0//EN'
  		 || $p->{uri}
  		 eq 'http://www.oasis-open.org/committees/entity/release/1.0/catalog.dtd') {
  		  my $curi = $self->option ('dtd_of_xml_catalog_1_0', undef, -see_parent => 1);
  		  if ($curi) {
  		    $p->{uri} = $curi;
  		  } else {
  		    $self->{error}->raise_error (undef, uri => undef, t => [$p->{PUBLIC}, $p->{uri}],
  		                                 type => 'DTD_OF_XC_NOT_READ');
  		    $p->{text} = '';
  		    return 0;
  		  }
  		}
  		return 1;
  	}});
  my $em = SuikaWiki::Markup::XML::EntityManager->new;
  $em->option (error_handler => $eh);
  $em->default_uri_resolver ($parser, 'SuikaWiki::Markup::XML', $p, $o,
                               dont_parse_text_declaration => 1);
  
  my $doc;
  if ($p->{error}->{no_data}) {
    $self->{error}->raise_error (undef, uri => $file, type => 'XML_RETRIVE_ERROR',
                                 t => [$p->{uri}, $p->{error}->{reason_text}]);
    $Catalog{$file} = undef;
    $Catalog{$p->{uri}} = undef;	## In case redirected
    return undef;
  } else {
    $parser->option (document_entity_base_uri => $p->{base_uri});
    eval q{
      $doc = $parser->parse_text ($p->{text}, $o, entMan => $em); 1;
    } or (index ($@, q(--SMXC::FATAL_ERROR--)) > -1 ? undef
         : $self->{error}->raise_error (undef, uri => $file, type => 'UNKNOWN', t => $@));
    $Catalog{$file} = {};
    $Catalog{$p->{uri}} = $Catalog{$file};	## In case redirected
  }
  return $Catalog{$file} unless $doc;
  
  my $root;
  $doc->remove_references;
  for (@{$doc->child_nodes}) {
    if ($_->node_type eq '#element') {
      if ($_->namespace_uri eq $NS{catalog} && $_->local_name eq 'catalog') {
        $root = $_;
      } else {
        $self->{error}->raise_error ($_, type => 'XC_UNKNOWN_ROOT_ELEMENT',
                                     t => [$_->namespace_uri, $_->local_name],
                                     uri => $file);
        last;
      }
    }
  }
  return $Catalog{$file} unless $root;
  
  my $prefer = $root->get_attribute ('prefer', make_new_node => 1)->inner_text
             || $self->{option}->{prefer}
             || 'public';
  my $s = sub {
    my ($entry, $lname, $prefer) = @_;
    if ($lname eq 'public' || $lname eq 'system' || $lname eq 'uri') {
        my $id_attr = $entry->get_attribute ($lname eq 'uri' ? 'name' : $lname.'Id');
        my $uri_attr = $entry->get_attribute ('uri');
        if (!$id_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR',
                                       t => ($lname eq 'uri' ? 'name' : $lname.'Id'),
                                       uri => $file);
        } elsif (!$uri_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR', t => 'uri');
        } else {
          $id_attr = $lname eq 'public'
                   ? $self->_normalize_public_id ($id_attr->inner_text, node => $id_attr,
                                                  uri => $file)
                   : $lname eq 'system'
                   ? $self->_normalize_system_id ($id_attr->inner_text, node => $id_attr,
                                                  uri => $file)
                   : $self->_check_uri ($id_attr->inner_text, node => $id_attr,
                                                  uri => $file);
          push @{$Catalog{$file}->{$lname}}, {
            id	=> $id_attr,
            uri	=> $entry->resolve_relative_uri ($self->_check_uri
                                                   ($uri_attr->inner_text, node => $uri_attr,
                                                    prohibit_fragment => 1, uri => $file)),
            prefer	=> $prefer,
          };
        }
    } elsif ($lname eq 'rewriteSystem' || $lname eq 'rewriteURI') {
        my $id_attr = $entry->get_attribute
                      (($lname eq 'rewriteSystem' ? 'systemId' : 'uri') .'StartString');
        my $pfx_attr = $entry->get_attribute ('rewritePrefix');
        if ($entry->get_attribute ('base', namespace_uri => $NS{xml})) {
          $self->{error}->raise_error ($entry, type => 'XC_BASE_ATTR_NOT_ALLOWED', uri => $file);
          $entry->remove_child_node ($entry->get_attribute ('base', namespace_uri => $NS{xml}));
        }
        if (!$id_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR', uri => $file,
                                       t => ($lname eq 'rewriteSystem' ? 'systemId' : 'uri')
                                            .'StartString');
        } elsif (!$pfx_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR', t => 'rewritePrefix',
                                       uri => $file);
        } else {
          push @{$Catalog{$file}->{'rewrite_'.($lname eq 'rewriteSystem' ? 'system' : 'uri')}}, {
            original_pfx	=> ($lname eq 'rewriteSystem'
                        	    ? $self->_normalize_system_id ($id_attr->inner_text,
                        	                                   node => $id_attr, uri => $file)
                        	    : $self->_check_uri ($id_attr->inner_text, node => $id_attr,
                        	                         uri => $file)),
            result_pfx	=> $entry->resolve_relative_uri
                      	           ($self->_check_uri ($pfx_attr->inner_text, node => $pfx_attr,
                      	                               uri => $file)),
          };
        }
    } elsif ($lname eq 'delegateSystem' || $lname eq 'delegatePublic' || $lname eq 'delegateURI') {
        my $lname = lc substr ($lname, 8);
        my $id_attr = $entry->get_attribute ($lname.($lname eq 'uri'?'':'Id').'StartString');
        my $uri_attr = $entry->get_attribute ('catalog');
        if (!$id_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR',
                                       t => $lname.($lname eq 'uri'?'':'Id').'StartString',
                                       uri => $file);
        } elsif (!$uri_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR', t => 'catalog',
                                       uri => $file);
        } else {
          push @{$Catalog{$file}->{'delegate_'.$lname}}, {
            original_pfx	=> $id_attr->inner_text,
            catalog	=> $entry->resolve_relative_uri
                   	           ($self->_check_uri ($uri_attr->inner_text, node => $uri_attr,
                   	                               uri => $file)),
          };
        }
    } elsif ($lname eq 'nextCatalog') {
        my $uri_attr = $entry->get_attribute ('catalog');
        if (!$uri_attr) {
          $self->{error}->raise_error ($entry, type => 'XC_NO_REQUIRED_ATTR', t => 'catalog',
                                       uri => $file);
        } else {
          push @{$Catalog{$file}->{additional_catalog}}, {
          	catalog	=> $entry->resolve_relative_uri
          	       	           ($self->_check_uri ($uri_attr->inner_text, node => $uri_attr,
          	       	                               uri => $file)),
          };
        }
    }	# type of entry
  };
  for my $entry (@{$root->child_nodes}) {
    if ($entry->node_type eq '#element' && $entry->namespace_uri eq $NS{catalog}) {
      my $lname = $entry->local_name;
      if ($lname eq 'group') {
        for my $ent (@{$entry->child_nodes}) {
          if ($ent->node_type eq '#element' && $ent->namespace_uri eq $NS{catalog}) {
            &$s ($ent, $ent->local_name,
                 ($entry->get_attribute ('prefer', make_new_node => 1)->inner_text || $prefer));
          }
        }
      } else {
        &$s ($entry, $lname, $prefer);
      }	# what element type?
    }	# root/catalog:* elements
  }
  $Catalog{$file};
}

sub _CLASS_NAME () { 'SuikaWiki::Markup::XML::Catalog' }

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

=head1 SEE ALSO

"XML Catalogs", Norman Walsh, OASIS Entity Resolution Technical Committee,
Committee Specification, 2001-08-06,
<http://www.oasis-open.org/committees/entity/spec.html>.

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/07/05 07:25:49 $
