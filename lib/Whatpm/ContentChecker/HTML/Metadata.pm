package Whatpm::ContentChecker::HTML::Metadata;
use strict;
use warnings;
our $VERSION = '1.0';

use constant STATUS_NOT_REGISTERED => 0;
use constant STATUS_PROPOSED => 1;
use constant STATUS_RATIFIED => 2;
use constant STATUS_DISCONTINUED => 3;
use constant STATUS_STANDARD => 4;

our $Defs;

$Defs->{'application-name'} = {
  unique => 1,
  status => STATUS_STANDARD,
};

$Defs->{author} = {
  unique => 0,
  status => STATUS_STANDARD,
};

$Defs->{description} = {
  unique => 1,
  status => STATUS_STANDARD,
};

$Defs->{generator} = {
  unique => 0,
  status => STATUS_STANDARD,
};

$Defs->{keywords} = {
  unique => 0,
  status => STATUS_PROPOSED,
};

$Defs->{cache} = {
  unique => 0,
  status => STATUS_DISCONTINUED,
};

# XXX Implement all values listed in WHATWG Wiki
# <http://wiki.whatwg.org/wiki/MetaExtensions>

our $DefaultDef = {
  unique => 0,
  status => STATUS_NOT_REGISTERED,
};

sub check ($@) {
  my ($class, %args) = @_;
  
  my $def = $Defs->{$args{name}} || $DefaultDef;

  ## XXX name pattern match (e.g. /^dc\..+/)

  ## --- Name conformance ---

  ## XXX synonyms (necessary to support some of wiki-documented
  ## metadata names

  if ($def->{status} == STATUS_STANDARD or $def->{status} == STATUS_RATIFIED) {
    #
  } elsif ($def->{status} == STATUS_PROPOSED) {
    $args{checker}->{onerror}->(type => 'metadata:proposed', # XXX TODOC
                                text => $args{name},
                                node => $args{name_attr},
                                level => $args{checker}->{level}->{warn});
  } elsif ($def->{status} == STATUS_DISCONTINUED) {
    $args{checker}->{onerror}->(type => 'metadata:discontinued', # XXX TODOC
                                text => $args{name},
                                node => $args{name_attr},
                                level => $args{checker}->{level}->{should});
  } else {
    $args{checker}->{onerror}->(type => 'metadata:not registered', # XXX TODOC
                                text => $args{name},
                                node => $args{name_attr},
                                level => $args{checker}->{level}->{must});
  }

  ## --- Metadata uniqueness ---

  if ($def->{unique}) {
    unless ($args{checker}->{flag}->{html_metadata}->{$args{name}}) {
      $args{checker}->{flag}->{html_metadata}->{$args{name}} = 1;
    } else {
      $args{checker}->{onerror}->(type => 'metadata:duplicate', # XXX TODOC
                                  text => $args{name},
                                  node => $args{name_attr},
                                  level => $args{checker}->{level}->{must});
    }
  }

  ## --- Value conformance ---

  ## XXX implement value conformance checking (not necessary for
  ## standard metadata names)

} # check

1;
