package Whatpm::ContentChecker::HTML::Metadata;
use strict;
use warnings;

use constant STATUS_NOT_REGISTERED => 0;
use constant STATUS_PROPOSED => 1;
use constant STATUS_RATIFIED => 2;
use constant STATUS_DISCONTINUED => 3;
use constant STATUS_STANDARD => 4;

our $Defs;

$Defs->{'application-name'} = {
  value_method => 'check_application_name',
  unique => 1,
  status => STATUS_STANDARD,
};

$Defs->{author} = {
  value_method => 'check_text',
  unique => 0,
  status => STATUS_STANDARD,
};

$Defs->{description} = {
  value_method => 'check_text',
  unique => 1,
  status => STATUS_STANDARD,
};

$Defs->{generator} = {
  value_method => 'check_text',
  unique => 0,
  status => STATUS_STANDARD,
};

$Defs->{keywords} = {
  value_method => 'check_text', # XXX
  unique => 0,
  status => STATUS_PROPOSED,
};

$Defs->{cache} = {
  value_method => 'check_text', # XXX
  unique => 0,
  status => STATUS_DISCONTINUED,
};

our $DefaultDef = {
  value_method => 'check_text',
  unique => 0,
  status => STATUS_NOT_REGISTERED,
};

sub check ($@) {
  my ($class, %args) = @_;
  
  my $def = $Defs->{$args{name}} || $DefaultDef;

  # XXX synonyms

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
  
} # check

1;
