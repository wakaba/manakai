package Whatpm::LangTag;
use strict;

my $default_error_levels = {
  langtag_fact => 'm',
  must => 'm',
  should => 's',
  good => 'w',

  warn => 'w',
  info => 'i',
};

## NOTE: This method, with appropriate $onerror handler, is a
## "well-formed" processor [RFC 4646].
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

## NOTE: This method, with appropriate $onerror handler, is intended
## to be a "validating" processor of language tags, as defined in RFC
## 4646, if an output of the |parse_rfc4646_langtag| method is
## inputed.
sub check_rfc4646_langtag ($$$;$) {
  my (undef, $tag_o, $onerror, $levels) = @_;
  $levels ||= $default_error_levels;

  require Whatpm::_LangTagReg;
  our $Registry;

  my $tag_s = $tag_o->{grandfathered};
  unless (defined $tag_s) {
    $tag_s = join '-',
        (defined $tag_o->{language} ? ($tag_o->{language}) : ()),
        @{$tag_o->{extlang}},
        (defined $tag_o->{script} ? ($tag_o->{script}) : ()),
        (defined $tag_o->{region} ? ($tag_o->{region}) : ()),
        @{$tag_o->{variant}},
        @{$tag_o->{extension}},
        @{$tag_o->{privateuse}},
        @{$tag_o->{illegal}};
  }
  $tag_s =~ tr/A-Z/a-z/;

  if ($Registry->{grandfathered}->{$tag_s}) {
    ## NOTE: This is a registered grandfathered tag.
    
  } elsif (defined $tag_o->{grandfathered}) {
    ## NOTE: The language tag does conform to the |grandfathered|
    ## syntax, but it is not a registered tag.  Though it might be
    ## valid under the RFC 3066's rule, it is not valid according to
    ## RFC 4646.

    ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
    $onerror->(type => 'langtag:grandfathered:invalid',
               value => $tag_o->{grandfathered},
               level => $levels->{langtag_fact});
  } else {
    ## NOTE: We ignore illegal subtags for the purpose of validation
    ## in this case.

    if ($Registry->{redundant}->{$tag_s}) {
      ## NOTE: This is a registered redundant tag.

      ## NOTE: We assume that the consistency of the registry is kept,
      ## such that any subtag of a registered redundant tag is valid,
      ## and therefore we don't have to check the validness of subtags
      ## and 'Preferred-Value' and 'Deprecated' field values and casing
      ## in the 'Tag' field are synced with those of the subtags.
      
      
    } else {
      if (defined $tag_o->{language}) {
        my $lang = $tag_o->{language};
        $lang =~ tr/A-Z/a-z/;
        if ($Registry->{language}->{$lang}) {
          ## NOTE: This is a registered language subtag.
          
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          ## NOTE: Strictly speaking, RFC 4646 2.9. speaks for "language
          ## subtag[s]" and what is that is unclear.  From the context,
          ## we assume that it referes to primary and extended language
          ## subtags.
          $onerror->(type => 'langtag:language:invalid',
                     value => $tag_o->{language},
                     level => $levels->{fact});
        }
      } else {
        ## NOTE: If $tag_o is an output of the method
        ## |parse_rfc4646_langtag|, then @{$tag_o->{privateuse}} is true
        ## in this case.  If $tag_o is not an output of that method,
        ## then it might not be true, but we don't support such a case.
      }
      
      for my $extlang_orig (@{$tag_o->{extlang}}) {
        my $extlang = $extlang_orig;
        $extlang =~ tr/A-Z/a-z/;
        if ($Registry->{extlang}->{$extlang}) {
          ## NOTE: This is a registered extended language subtag.
          
          my $prefixes = $Registry->{extlang}->{$extlang}->{Prefix} || {};
          HAS_PREFIX: {
            ## NOTE: In the first pass, it checks for literal matches.
            for my $prefix (@$prefixes) {
              if ($tag_s =~ /^\Q$prefix\E-/) {
                last HAS_PREFIX;
              }
            }

            ## NOTE: In the second pass, it checks for each subtag.
            my $lang = $tag_o->{language}; # is not undef unless $tag_o broken
            $lang =~ tr/A-Z/a-z/;
            P: for my $prefix_s (@$prefixes) {
              my $prefix_o = Whatpm::LangTag->parse_rfc4646_langtag
                  ($prefix_s);
              ## NOTE: We assumes that $prefix_s is a well-formed,
              ## non-grandfathered tag.
              next P unless $prefix_o->{language} eq $lang;
              XL: for my $p_extlang (@{$prefix_o->{extlang}}) {
                for (@{$tag_o->{extlang}}) {
                  my $extlang = $_;
                  $extlang =~ tr/A-Z/a-z/;
                  if ($p_extlang eq $extlang) {
                    next XL;
                  }
                }
                next P;
              }
              my $p_script = $prefix_o->{script};
              if ($p_script) {
                my $script = $tag_o->{script};
                next P unless defined $script;
                $script =~ tr/A-Z/a-z/;
                next P unless $p_script eq $script;
              }
              my $p_region = $prefix_o->{region};
              if ($p_region) {
                my $region = $tag_o->{region};
                next P unless defined $region;
                $region =~ tr/A-Z/a-z/;
                next P unless $p_region eq $region;
              }
              XL: for my $p_variant (@{$prefix_o->{variant}}) {
                for (@{$tag_o->{variant}}) {
                  my $variant = $_;
                  $variant =~ tr/A-Z/a-z/;
                  if ($p_variant eq $variant) {
                    next XL;
                  }
                }
                next P;
              }
              ## NOTE: We assume that no Prefix contains extension and
              ## privateuse subtags.

              ## NOTE: Whethter |...-variant1-variant2| should match
              ## with |...-variant2-variant1| or not is unclear.  (We do.)

              last HAS_PREFIX;
            }

            ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
            $onerror->(type => 'langtag:extlang:no prefix',
                       value => $extlang,
                       level => $levels->{fact});
          } # HAS_PREFIX
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          ## NOTE: Strictly speaking, RFC 4646 2.9. speaks for "language
          ## subtag[s]" and what is that is unclear.  From the context,
          ## we assume that it referes to primary and extended language
          ## subtags.
          $onerror->(type => 'langtag:extlang:invalid',
                     value => $extlang_orig,
                     level => $levels->{fact});
          
        }
      }
      
      if (defined $tag_o->{script}) {
        my $script = $tag_o->{script};
        $script =~ tr/A-Z/a-z/;
        if ($Registry->{script}->{$script}) {
          ## NOTE: This is a registered script subtag.
          
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          $onerror->(type => 'langtag:script:invalid',
                     value => $tag_o->{script},
                     level => $levels->{fact});
        }
      }
      
      if (defined $tag_o->{region}) {
        my $region = $tag_o->{region};
        $region =~ tr/A-Z/a-z/;
        if ($Registry->{region}->{$region}) {
          ## NOTE: This is a registered region subtag.
          
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          $onerror->(type => 'langtag:region:invalid',
                     value => $tag_o->{region},
                     level => $levels->{fact});
        }
      }

      for my $variant_orig (@{$tag_o->{variant}}) {
        my $variant = $variant_orig;
        $variant =~ tr/A-Z/a-z/;
        if ($Registry->{variant}->{$variant}) {
          ## NOTE: This is a registered variant language subtag.

          ## NOTE: Almost same as extlang's checking code.

          my $prefixes = $Registry->{variant}->{$variant}->{Prefix} || {};
          HAS_PREFIX: {
            ## NOTE: In the first pass, it checks for literal matches.
            for my $prefix (@$prefixes) {
              if ($tag_s =~ /^\Q$prefix\E-/) {
                last HAS_PREFIX;
              }
            }

            ## NOTE: In the second pass, it checks for each subtag.
            my $lang = $tag_o->{language}; # is not undef unless $tag_o broken
            $lang =~ tr/A-Z/a-z/;
            P: for my $prefix_s (@$prefixes) {
              my $prefix_o = Whatpm::LangTag->parse_rfc4646_langtag
                  ($prefix_s);
              ## NOTE: We assumes that $prefix_s is a well-formed,
              ## non-grandfathered tag.
              next P unless $prefix_o->{language} eq $lang;
              XL: for my $p_extlang (@{$prefix_o->{extlang}}) {
                for (@{$tag_o->{extlang}}) {
                  my $extlang = $_;
                  $extlang =~ tr/A-Z/a-z/;
                  if ($p_extlang eq $extlang) {
                    next XL;
                  }
                }
                next P;
              }
              my $p_script = $prefix_o->{script};
              if ($p_script) {
                my $script = $tag_o->{script};
                next P unless defined $script;
                $script =~ tr/A-Z/a-z/;
                next P unless $p_script eq $script;
              }
              my $p_region = $prefix_o->{region};
              if ($p_region) {
                my $region = $tag_o->{region};
                next P unless defined $region;
                $region =~ tr/A-Z/a-z/;
                next P unless $p_region eq $region;
              }
              XL: for my $p_variant (@{$prefix_o->{variant}}) {
                for (@{$tag_o->{variant}}) {
                  my $variant = $_;
                  $variant =~ tr/A-Z/a-z/;
                  if ($p_variant eq $variant) {
                    next XL;
                  }
                }
                next P;
              }
              ## NOTE: We assume that no Prefix contains extension and
              ## privateuse subtags.

              ## NOTE: Whethter |...-variant1-variant2| should match
              ## with |...-variant2-variant1| or not is unclear.  (We do.)

              last HAS_PREFIX;
            }

            ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
            $onerror->(type => 'langtag:variant:no prefix',
                       value => $variant,
                       level => $levels->{fact});
          } # HAS_PREFIX
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          $onerror->(type => 'langtag:variant:invalid',
                     value => $variant_orig,
                     level => $levels->{fact});
        }
      }

      for my $ext (@{$tag_o->{extension}}) {
        ## NOTE: Extension subtag.  At the time of writing of this
        ## code, there is no defined extension subtag.
        $onerror->(type => 'langtag:extension:unknown',
                   value => (join '-', @{$ext}),
                   level => $levels->{fact});

        ## NOTE: Whether a language tag with unsupported extension is
        ## valid or not is unclear from the reading of RFC 4646.
      }

      if (@{$tag_o->{privateuse}}) {
        $onerror->(type => 'langtag:privateuse',
                   value => (join '-', @{$tag_o->{privateuse}}),
                   level => $levels->{warn});
      }
    }
  }
} # check_rfc4646_langtag

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
