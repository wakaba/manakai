package Whatpm::LangTag;
use strict;

my $default_error_levels = {
  langtag_fact => 'm',
  must => 'm',
  should => 's',
  good => 'w',
};

sub parse_rfc4646_langtag ($$;$$) {
  my $tag = $_[1];
  my $onerror = $_[2] || sub { };
  my $levels = $_[3] || $default_error_levels;

  my @tag = split /-/, $tag, -1;

  my %r = (
    language => shift @tag,
    extlang => [],
    variant => [],
    extension => [],
    privateuse => [],
    illegal => [],
  );

  my $grandfathered = $tag =~ /\A[A-Za-z]{1,3}(?>-[A-Za-z0-9]{2,8}){1,2}\z/;
  
  if ($r{language} =~ /\A[A-Za-z]+\z/) {
    if (length $r{language} == 1) {
      if ($r{language} =~ /\A[Xx]\z/) {
        unshift @tag, $r{language};
        delete $r{language};
      } else {
        if ($grandfathered) {
          $r{grandfathered} = $tag;
          delete $r{language};
          return \%r;
        } else {
          $onerror->(type => 'langtag:language:syntax',
                     value => $r{language},
                     level => $levels->{langtag_fact});
        }
      }
    } elsif (length $r{language} <= 3) {
      while (@tag and $tag[0] =~ /\A[A-Za-z]{3}\z/ and @{$r{extlang}} < 3) {
        push @{$r{extlang}}, shift @tag;
      }
    } elsif (length $r{language} <= 8) {
      #
    } else {
      $onerror->(type => 'langtag:language:syntax',
                 value => $r{language},
                 level => $levels->{langtag_fact});
    }
  } else {
    $onerror->(type => 'langtag:language:syntax',
               value => $r{language},
               level => $levels->{langtag_fact});
  }

  if (defined $r{language}) {
    if (@tag and $tag[0] =~ /\A[A-Za-z]{4}\z/) {
      $r{script} = shift @tag;
    }
    
    if (@tag and $tag[0] =~ /\A(?>[A-Za-z]{2}|[0-9]{3})\z/) {
      $r{region} = shift @tag;
    }
    
    while (@tag and
           $tag[0] =~
               /\A(?>[A-Za-z][A-Za-z0-9]{4,7}|[0-9][A-Za-z0-9]{3,7})\z/) {
      push @{$r{variant}}, shift @tag;
    }

    my %has_extension;
    while (@tag >= 2 and $tag[0] =~ /\A[A-WYZa-wyz0-9]\z/ and
           $tag[1] =~ /\A[A-Za-z0-9]{2,8}\z/) {
      if ($has_extension{$tag[0]}++) {
        $onerror->(type => 'langtag:extension:duplication',
                   value => $tag[0],
                   level => $levels->{must});
      }
      my $ext = [shift @tag => shift @tag];
      while (@tag and $tag[0] =~ /\A[A-Za-z0-9]{2,8}\z/) {
        push @$ext, shift @tag;
      }
      push @{$r{extension}}, $ext;
    }
  }

  if (@tag >= 2 and $tag[0] =~ /\A[Xx]\z/) {
    for (@tag) {
      unless (/\A[A-Za-z0-9]{1,8}\z/) {
        $onerror->(type => 'langtag:privateuse:syntax',
                   value => $_,
                   level => $levels->{must}); # RFC 4646 Section 2.2.7.
      }
    }
    @{$r{privateuse}} = @tag;
    @tag = ();
  }

  if (@tag) {
    if ($grandfathered) {
      return {
              extlang => [],
              variant => [],
              extension => [],
              privateuse => [],
              grandfathered => $tag,
              illegal => [],      
             };
    } else {
      for (@tag) {
        $onerror->(type => 'langtag:illegal',
                   value => $_,
                   level => $levels->{langtag_fact});
      }
      push @{$r{illegal}}, @tag;
    }
  }

  return \%r;
} # parse_rfc4646_langtag

sub check_rfc3066_language_tag ($$;$$) {
  my $tag = $_[1];
  my $onerror = $_[2] || sub { };
  my $levels = $_[3] || $default_error_levels;

  ## TODO: Should we raise a different type of error for empty language tags?

  ## TODO: If ISO 639 and 3166 have strong recommendation
  ## for case of codes, bad-case-error should be $should_level.
  ## NOTE: They are marked as $good_level for now, since
  ## RFC 3066 sais that there are "recommended" case for them
  ## and it itself does not "recommend" any case.
  ## NOTE: In RFC 1766 case convention is "recommended", but
  ## without RFC 2119 wording.

  my @tag = split /-/, $tag, -1;

  if ($tag[0] =~ /\A[0-9]+\z/) {
    $onerror->(type => 'langtag:illegal',
               value => $tag[0],
               level => $levels->{langtag_fact});
  }

  for (@tag) {
    unless (/\A[A-Za-z0-9]{1,8}\z/) {
      $onerror->(type => 'langtag:illegal',
                 value => $_,
                 level => $levels->{langtag_fact});
    }
  }

  if ($tag[0] =~ /\A[A-Za-z]{2}\z/) {
    ## TODO: ISO 639-1
    if ($tag[0] =~ /[A-Z]/) {
      $onerror->(type => 'langtag:language:case',
                 value => $tag[0],
                 level => $levels->{good});
    }
  } elsif ($tag[0] =~ /\A[A-Za-z]{3}\z/) {
    ## TODO: ISO 639-2
    ## TODO: Is there any recommendation on case?
    ## TODO: MUST use 2-letter code if any
    ## TODO: MUST use /T code, if any, rather than /B code.
    if ($tag[0] =~ /\A[Uu][Nn][Dd]\z/) {
      $onerror->(type => 'langtag:language:und',
                 level => $levels->{should});
      ## NOTE: SHOULD NOT, unless the protocol in use forces to give a value.
    } elsif ($tag[0] =~ /\A[Mm][Uu][Ll]\z/) {
      $onerror->(type => 'langtag:language:mul',
                 level => $levels->{should});
      ## NOTE: SHOULD NOT, if the protocol allows specifying multiple langs.
    }
  } elsif ($tag[0] =~ /\A[Ii]\z/) {
    #
  } elsif ($tag[0] =~ /\A[Xx]\z/) {
    $onerror->(type => 'langtag:private',
               value => $tag,
               level => $levels->{good});
  } else {
    $onerror->(type => 'langtag:language:nosemantics',
               value => $tag[0],
               level => $levels->{langtag_fact});
  }

  if (@tag >= 1) {
    if ($tag[1] =~ /\A[0-9A-Za-z]{2}\z/) {
      ## TODO: ISO 3166
      if ($tag[1] =~ /[a-z]/) {
        $onerror->(type => 'langtag:region:case',
                   value => $tag[1],
                   level => $levels->{good});
      }      
      if ($tag[1] =~ /\A(?>[Aa][Aa]|[Qq][M-Zm-z]|[Xx][A-Za-z]|[Zz][Zz])\z/) {
        $onerror->(type => 'langtag:region:private',
                   value => $tag[1],
                   level => $levels->{must});
      }
    } elsif (length $tag[1] == 1) {
      $onerror->(type => 'langtag:region:nosemantics', 
                 value => $tag[1],
                 level => $levels->{langtag_fact});
    }
  }

  ## TODO: MUST use ISO tag rather than i-* tag.
  ## TODO: some i-* tags are deprecated. (fact_level)

  ## TODO: Non-registered tags should be warned.
  ## $fact_level for i-*, $good_level for others.
} # check_rfc3066_language_tag
1;
