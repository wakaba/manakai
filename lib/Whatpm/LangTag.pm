package Whatpm::LangTag;
use strict;
use warnings;
our $VERSION = '2.0';

my $default_error_levels = {
  langtag_fact => 'm',
  must => 'm',
  should => 's',
  good => 'w',

  warn => 'w',
  info => 'i',
};

## Versioning flags
our $RFC5646;

my $Grandfathered5646 = {map { $_ => 1 } qw(
  en-gb-oed i-ami i-bnn i-default i-enochian i-hak i-klingon i-lux
  i-mingo i-navajo i-pwn i-tao i-tay i-tsu sgn-be-fr sgn-be-nl sgn-ch-de
  art-lojban cel-gaulish no-bok no-nyn zh-guoyu zh-hakka zh-min
  zh-min-nan zh-xiang
)};

## Note: RFC 5646 2.1., 2.2.6.
sub normalize_rfc5646_langtag ($$) {
  my @tag = map { tr/A-Z/a-z/; $_ } split /-/, $_[1], -1;
  my $in_extension;
  for my $i (1..$#tag) {
    if (1 == length $tag[$i - 1]) {
      if ($tag[$i - 1] ne 'x' and $tag[$i - 1] ne 'i') {
        last;
      }
    } elsif ($tag[$i] =~ /\A(..)\z/s) {
      $tag[$i] =~ tr/a-z/A-Z/;
    } elsif ($tag[$i] =~ /\A([a-z])(.{3})\z/s) {
      $tag[$i] = (uc $1) . $2;
    }
  }
  return join '-', @tag;
} # normalize_rfc5646_langtag

sub parse_rfc5646_langtag ($$;$$) {
  local $RFC5646 = 1;
  return shift->parse_rfc4646_langtag (@_);
} # parse_rfc5646_langtag

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

  my $tag_l = $tag;
  $tag_l =~ tr/A-Z/a-z/;
  my $grandfathered =
      $RFC5646 
          ? $Grandfathered5646->{$tag_l}
          : $tag =~ /\A[A-Za-z]{1,3}(?>-[A-Za-z0-9]{2,8}){1,2}\z/;
  
  if ($r{language} and $r{language} =~ /\A[A-Za-z]+\z/) {
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
          ## NOTE: Well-formed processor MUST check whether a tag
          ## conforms to the ABNF (RFC 4646 2.2.9.), SHOULD be
          ## canonical and to be canonical, it has to be well-formed
          ## (RFC 4646 4.4. 1.), "Private ues subtags, like other
          ## subtags, MUST conform to the format and content
          ## cnstraints in the ABNF." (RFC 4646 4.5.)
         $onerror->(type => 'langtag:language:syntax',
                     value => $r{language},
                     level => $levels->{must});
        }
      }
    } elsif (length $r{language} <= 3) {
      while (@tag and $tag[0] =~ /\A[A-Za-z]{3}\z/ and @{$r{extlang}} < 3) {
        push @{$r{extlang}}, shift @tag;
      }
    } elsif (length $r{language} <= 8) {
      #
    } else {
      ## NOTE: Well-formed processor MUST check whether a tag conforms
      ## to the ABNF (RFC 4646 2.2.9.), SHOULD be canonical and to be
      ## canonical, it has to be well-formed (RFC 4646 4.4. 1.)
      ## "Private ues subtags, like other subtags, MUST conform to the
      ## format and content cnstraints in the ABNF." (RFC 4646 4.5.)
      $onerror->(type => 'langtag:language:syntax',
                 value => $r{language},
                 level => $levels->{must});
    }
  } else {
    ## NOTE: Well-formed processor MUST check whether a tag conforms
    ## to the ABNF (RFC 4646 2.2.9.), SHOULD be canonical and to be
    ## canonical, it has to be well-formed (RFC 4646 4.4. 1.),
    ## "Private ues subtags, like other subtags, MUST conform to the
    ## format and content cnstraints in the ABNF." (RFC 4646 4.5.)
    $onerror->(type => 'langtag:language:syntax',
               value => $r{language},
               level => $levels->{must});
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
        ## NOTE: Well-formed processor MUST check (RFC 4646 2.2.9.)
        ## and MUST and MUST NOT (RFC 4646 2.2.6. 4.), , SHOULD be
        ## canonical and to be canonical, it has to be well-formed
        ## (RFC 4646 4.4. 1.)
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
        ## NOTE: MUST (RFC 4646 2.2.7.), Well-formed processor MUST
        ## check whether a tag conforms to the ABNF (RFC 4646 2.2.9.),
        ## "Private ues subtags, like other subtags, MUST conform to
        ## the format and content cnstraints in the ABNF." (RFC 4646
        ## 4.5.)
        $onerror->(type => 'langtag:privateuse:syntax',
                   value => $_,
                   level => $levels->{must});
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
      ## NOTE: Violation to the syntax/prose (RFC 4646 2.1.,
      ## fact-level)

      ## NOTE: "Variants starting with a letter MUST be at least five
      ## character long" (RFC 4646 2.1., Note, RFC 4646 2.2.5.)

      ## NOTE: "Sequence of private use and extension subtags MUST
      ## occur at the end of the sequence of subtags and MUST NOT be
      ## interspersed with subtags" (RFC 4646 2.2.)

      ## NOTE: "An extension MUST follow at least a primary language
      ## subtag." (RFC 4646 2.2.6. 3.)

      ## NOTE: "Extension subtag MUST meet all of the requirements for
      ## the content and format of subtags" (RFC 4646 2.2.6. 5.) and
      ## "MUST be from two to eight characters long and consist solely
      ## of letters or digits, with each subtag separated by a signle
      ## '-'" (RFC 4646 2.2.6. 7.) and "singleton MUST be followed by
      ## at least one extension subtag" (RFC 4646 2.2.6. 8.)

      ## NOTE: "Private use subtags MUST conform to the format and
      ## content constraints" (RFC 4646 2.2.7. 2.)

      ## NOTE: There are other "MUST"s that would cover some of cases
      ## that fall into this error.  I'm not sure that those
      ## requirements as a whole covers all the cases that would fall
      ## into this error...  I wonder if the spec simply said that any
      ## language tag MUST conform to the ABNF syntax...

      ## NOTE: Well-formed processor MUST check whether a tag conforms
      ## to the ABNF (RFC 4646 2.2.9.), SHOULD be canonical and to be
      ## canonical, it has to be well-formed (RFC 4646 4.4. 1.)
      ## "Private ues subtags, like other subtags, MUST conform to the
      ## format and content cnstraints in the ABNF." (RFC 4646 4.5.)
      for (@tag) {
        $onerror->(type => 'langtag:illegal',
                   value => $_,
                   level => $levels->{must});
      }
      push @{$r{illegal}}, @tag;
    }
  }

  return \%r;
} # parse_rfc4646_langtag

sub check_rfc5646_langtag ($$$;$) {
  local $RFC5646 = 1;
  return shift->check_rfc4646_langtag (@_);
} # check_rfc5646_langtag

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
  my $tag_s_orig = $tag_s;
  $tag_s =~ tr/A-Z/a-z/;

  my $check_case = sub ($$$) {
    my ($type, $actual, $expected) = @_;
    
    $expected ||= '_lowercase';
    if ($expected eq '_lowercase' and $actual !~ /[A-Z]/) {
      #
    } elsif ($expected eq '_uppercase' and $actual !~ /[a-z]/) {
      #
    } elsif ($expected eq '_titlecase' and
             substr ($actual, 0, 1) !~ /[a-z]/ and
             substr ($actual, 1) !~ /[A-Z]/) {
      #
    } elsif ($expected eq $actual and
             $expected !~ /^_/) {
      #
    } else {
      ## NOTE: RECOMMENDED (RFC 4646 2.1.)
      $onerror->(type => 'langtag:'.$type.':case',
                 value => $actual,
                 level => $levels->{should});
    }
  }; # $check_case

  my $check_deprecated = sub ($$$) {
    my ($type, $actual, $def) = @_;

    ## NOTE: Record of 'Preferred-Value' MUST have 'Deprecated' field.
    ## (RFC 4646 3.1.)

    ## NOTE: Transitive relationships are resolved in the
    ## "mklangreg.pl".

    if ($def->{_deprecated}) {
      ## NOTE: Validating processors SHOULD NOT generate (RFC 4646
      ## 3.1., RFC 4646 4.4. Note; Why only validating processors?)
      ## and the value in the 'Preferred-Value', if any, is STRONGLY
      ## RECOMMENDED (RFC 4646 3.1.), 'Preferred-Value' SHOULD be used
      ## (RFC 4646 4.1. 3.), A tag SHOULD be canonical, to be
      ## canonical a region subtag SHOULD use Preferred-Value (RFC
      ## 4646 4.4. 2.), and to be canonical a redundant or
      ## grandfathered tag MUST use Preferred-Value (RFC 4646
      ## 4.4. 3.), and to be canonical other subtags MUST be canonical
      ## (RFC 4646 4.4. 4.).
      $onerror->(type => 'langtag:'.$type.':deprecated',
                 text => $def->{_preferred}, # might be undef
                 value => $actual,
                 level => $levels->{should});
    } elsif ($RFC5646 and $def->{_preferred}) {
      ## RFC 5646 2.2.2.
      $onerror->(type => 'langtag:'.$type.':preferred',
                 text => $def->{_preferred},
                 value => $actual,
                 level => $levels->{should});
    }
  }; # $check_deprecated
                        
  if ($Registry->{grandfathered}->{$tag_s}) {
    ## NOTE: This is a registered grandfathered tag.

    ## NOTE: Some grandfathered tags conform to the new syntax (so
    ## that $tag_o->{grandfathered} is undef) but still not
    ## grandfathered, since extended langauge is currently not
    ## registered at all.

    $check_case->('grandfathered', $tag_s_orig,
                  $Registry->{grandfathered}->{$tag_s}->{_canon});
    $check_deprecated->('grandfathered', $tag_s_orig,
                        $Registry->{grandfathered}->{$tag_s});

    if ($RFC5646 and $tag_s eq 'i-default') {
      ## RFC 5646 4.1.
      $onerror->(type => 'langtag:grandfathered:i-default',
                 value => $tag_o->{grandfathered},
                 level => $levels->{should});
    }
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
      
      $check_case->('redundant', $tag_s_orig,
                    $Registry->{redundant}->{$tag_s}->{_canon});      
      $check_deprecated->('redundant', $tag_s_orig,
                          $Registry->{redundant}->{$tag_s});      
    }

    {
      ## NOTE: We don't raise non-recommended-case error for invalid
      ## tags (with no strong preference; we might change the behavior
      ## if it seems better).

      my $lang = $tag_o->{language};
      if (defined $tag_o->{language}) {
        $lang =~ tr/A-Z/a-z/;
        if ($Registry->{language}->{$lang}) {
          ## NOTE: This is a registered language subtag.
          
          $check_case->('language', $tag_o->{language},
                        $Registry->{language}->{$lang}->{_canon});
          $check_deprecated->('language', $tag_o->{language},
                              $Registry->{language}->{$lang});

          if ($lang =~ /\Aq[a-t][a-z]\z/) {
            $onerror->(type => 'langtag:language:private',
                       value => $tag_o->{language},
                       level => $levels->{warn});
          } elsif ($lang eq 'und') {
            ## NOTE: SHOULD NOT (RFC 4646 4.1. 4.)
            $onerror->(type => 'langtag:language:und',
                       level => $levels->{should});
          } elsif ($lang eq 'mul') {
            ## NOTE: SHOULD NOT (RFC 4646 4.1. 5.)
            $onerror->(type => 'langtag:language:mul',
                       level => $levels->{should});
          } elsif ($lang eq 'mis') {
            ## NOTE: SHOULD NOT (RFC 5646 4.1.)
            $onerror->(type => 'langtag:language:mis',
                       level => $levels->{should})
                if $RFC5646;
          }
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          ## NOTE: Strictly speaking, RFC 4646 2.9. speaks for "language
          ## subtag[s]" and what is that is unclear.  From the context,
          ## we assume that it referes to primary and extended language
          ## subtags.
          $onerror->(type => 'langtag:language:invalid',
                     value => $tag_o->{language},
                     level => $RFC5646 ? $levels->{must} : $levels->{langtag_fact});
        }
      } else {
        ## NOTE: If $tag_o is an output of the method
        ## |parse_rfc4646_langtag|, then @{$tag_o->{privateuse}} is true
        ## in this case.  If $tag_o is not an output of that method,
        ## then it might not be true, but we don't support such a case.
        
        $lang = ''; # for later use.
      }
      
      my $i_extlang = 0;
      for my $extlang_orig (@{$tag_o->{extlang}}) {
        if ($RFC5646 and $i_extlang) {
          ## RFC 5646 2.2.2.
          $onerror->(type => 'langtag:extlang:invalid',
                     value => $extlang_orig,
                     level => $levels->{must});
          next;
        }

        my $extlang = $extlang_orig;
        $extlang =~ tr/A-Z/a-z/;
        if ($Registry->{extlang}->{$extlang}) {
          ## NOTE: This is a registered extended language subtag.
          
          my $prefixes = $Registry->{extlang}->{$extlang}->{Prefix};
          if ($prefixes and defined $prefixes->[0]) {
            ## NOTE: There is exactly one prefix (RFC 4646 2.2.2.).
            if ($tag_s =~ /^\Q$prefixes->[0]\E-/) {
              #
            } else {
              ## NOTE: RFC 4646 2.2.2. (MUST), RFC 4646
              ## 2.9. ("validating" processor MUST check), RFC 4646
              ## 4.1. (SHOULD)
              $onerror->(type => 'langtag:extlang:prefix',
                         value => $extlang,
                         level => $levels->{must});
            }
          }

          $check_case->('extlang', $extlang_orig,
                        $Registry->{extlang}->{$extlang}->{_canon});
          $check_deprecated->('extlang', $extlang_orig,
                              $Registry->{extlang}->{$extlang});
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          ## NOTE: Strictly speaking, RFC 4646 2.9. speaks for "language
          ## subtag[s]" and what is that is unclear.  From the context,
          ## we assume that it referes to primary and extended language
          ## subtags.
          $onerror->(type => 'langtag:extlang:invalid',
                     value => $extlang_orig,
                     level => $RFC5646 ? $levels->{must} : $levels->{langtag_fact});
          
        }
        $i_extlang++;
      } # extlang
      
      if (defined $tag_o->{script}) {
        my $script = $tag_o->{script};
        $script =~ tr/A-Z/a-z/;
        if ($Registry->{script}->{$script}) {
          ## NOTE: This is a registered script subtag.
          
          $check_case->('script', $tag_o->{script},
                        $Registry->{script}->{$script}->{_canon});
          $check_deprecated->('script', $tag_o->{script},
                              $Registry->{script}->{$script});

          ## NOTE: RFC 4646 2.2.3. "SHOULD be omitted (1) when it adds
          ## no distinguishing value to the tag or (2) when
          ## ... Suppress-Script".  (1) is semantic requirement that
          ## we cannot check against.  SHOULD NOT (RFC 4646 3.1.),
          ## SHOULD (RFC 4646 4.1.) "SHOULD NOT be used to form
          ## language tags unless the script adds some distinguishing
          ## information to the tag" (RFC 4646 4.1. 2.)
          if ($Registry->{language}->{$lang} and
              defined $Registry->{language}->{$lang}->{_suppress} and
              $Registry->{language}->{$lang}->{_suppress} eq $script) {
            $onerror->(type => 'langtag:script:suppress',
                       text => $lang,
                       value => $tag_o->{script},
                       level => $levels->{should});
          }

          if ($script =~ /\Aqa(?>a[a-z]|b[a-x])\z/) {
            $onerror->(type => 'langtag:script:private',
                       value => $tag_o->{script},
                       level => $levels->{warn});
          }
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          $onerror->(type => 'langtag:script:invalid',
                     value => $tag_o->{script},
                     level => $RFC5646 ? $levels->{must} : $levels->{langtag_fact});
        }
      }
      
      if (defined $tag_o->{region}) {
        my $region = $tag_o->{region};
        $region =~ tr/A-Z/a-z/;
        if ($Registry->{region}->{$region}) {
          ## NOTE: This is a registered region subtag.
          
          $check_case->('region', $tag_o->{region},
                        $Registry->{region}->{$region}->{_canon});
          $check_deprecated->('region', $tag_o->{region},
                              $Registry->{region}->{$region});

          if ($region =~ /\A(?>aa|q[m-z]|x[a-z]|zz)\z/) {
            $onerror->(type => 'langtag:region:private',
                       value => $tag_o->{region},
                       level => $levels->{warn});
          }
        } else {
          ## NOTE: RFC 4646 2.2.4. 3. B. "UN numeric codes for
          ## 'economic groupings' or 'other groupings' ... MUST NOT be
          ## used", RFC 4646 2.2.4. 3. D. "UN numeric codes for
          ## countries or areas for which ... ISO 3166 alpha-2 code
          ## ... MUST NOT be used", RFC 4646 2.2.4. 3. F. "All other
          ## UN numeric codes for countries or areas that do not
          ## ... ISO 3166 alpha-2 code ... MUST NOT be used", RFC 4646
          ## 2.2.4. 4. Note "Alphanumeric codes in Appendix X ... MUST
          ## NOT be used", RFC 4646 2.9. ("validating" processor MUST
          ## check)
          $onerror->(type => 'langtag:region:invalid',
                     value => $tag_o->{region},
                     level => $RFC5646 ? $levels->{must} : $levels->{langtag_fact});
        }
      }

      my @prev_variant;
      my %prev_variant;
      my $last_unprefixed_variant;
      for my $variant_orig (@{$tag_o->{variant}}) {
        my $variant = $variant_orig;
        $variant =~ tr/A-Z/a-z/;
        if ($Registry->{variant}->{$variant}) {
          ## NOTE: This is a registered variant language subtag.

          my $prefixes = $Registry->{variant}->{$variant}->{Prefix} || [];
          my @longer_prefix;
          if (@$prefixes) {
            if ($RFC5646 and defined $last_unprefixed_variant) {
              $onerror->(type => 'langtag:variant:order',
                         text => $variant,
                         value => $last_unprefixed_variant,
                         level => $levels->{should});
            }

            HAS_PREFIX: {
              ## NOTE: @$prefixes is sorted by reverse order of
              ## lengths.
              
              my $tag = join '-', grep { defined $_ }
                  $tag_o->{language},
                  @{$tag_o->{extlang} or []},
                  $tag_o->{script},
                  $tag_o->{region},
                  @prev_variant;
              for my $prefix_s (@$prefixes) {
                if (Whatpm::LangTag->extended_filtering_range_rfc4647
                        ($prefix_s, $tag)) {
                  last HAS_PREFIX;
                } else {
                  push @longer_prefix, $prefix_s;
                }
              }
              
              ## NOTE: RFC 4646 2.9. ("validating" processor MUST
              ## check) and RFC 4646 4.1. (SHOULD)
              $onerror->(type => 'langtag:variant:prefix',
                         text => (join '|', @$prefixes),
                         value => $variant,
                         level => $levels->{should});
            } # HAS_PREFIX
            if ($RFC5646 and @longer_prefix and @longer_prefix != @$prefixes) {
              my $tag = join '-', grep { defined $_ }
                    $tag_o->{language},
                    @{$tag_o->{extlang} or []},
                    $tag_o->{script},
                    $tag_o->{region},
                    @{$tag_o->{variant} or []};
              for my $prefix_s (@longer_prefix) {
                ## RFC 5646 4.1. Variant subtag ordering requirement
                if (Whatpm::LangTag->extended_filtering_range_rfc4647
                        ($prefix_s, $tag)) {
                  $onerror->(type => 'langtag:variant:order',
                             text => $prefix_s,
                             value => $variant,
                             level => $levels->{should});
                }
              }
            }
          } else { # @$prefixes
            ## RFC 5646 4.1. Variant subtag ordering requirement
            if ($RFC5646 and defined $last_unprefixed_variant) {
              if (($variant cmp $last_unprefixed_variant) < 0) {
                $onerror->(type => 'langtag:variant:order',
                           text => $variant,
                           value => $last_unprefixed_variant,
                           level => $levels->{should});
              }
            }
            $last_unprefixed_variant = $variant;
          } # @$prefixes

          $check_case->('variant', $variant_orig,
                        $Registry->{variant}->{$variant}->{_canon});
          $check_deprecated->('variant', $variant_orig,
                              $Registry->{variant}->{$variant});

          if ($prev_variant{$variant}) {
            ## A variant subtag SHOULD only be used at most once in a
            ## tag (RFC 4646 4.1. 6.)
            $onerror->(type => 'langtag:variant:duplication',
                       value => $variant_orig,
                       level => $levels->{should});
          } elsif (($variant eq '1996' and $prev_variant{1901}) or
                   ($variant eq '1901' and $prev_variant{1996})) {
            ## RFC 4646 2.2.5. shows '1996' and '1901' as a bad
            ## example and says that they SHOULD NOT be used together.
            $onerror->(type => 'langtag:variant:combination',
                       text => $variant_orig,
                       value => $variant eq '1901' ? '1996' : '1901',
                       level => $levels->{should});
          }
        } else {
          ## NOTE: RFC 4646 2.9. ("validating" processor MUST check)
          $onerror->(type => 'langtag:variant:invalid',
                     value => $variant_orig,
                     level => $RFC5646
                                  ? $levels->{must}
                                  : $levels->{langtag_fact});
        }
        push @prev_variant, $variant_orig;
        $prev_variant{$variant} = 1;
      }

      my $max_ext = 0x00;
      for my $ext (@{$tag_o->{extension}}) {
        ## NOTE: Extension subtag.  At the time of writing of this
        ## code, there is no defined extension subtag.
        $onerror->(type => 'langtag:extension:unknown',
                   value => (join '-', @{$ext}),
                   level => $levels->{langtag_fact});

        ## NOTE: Whether a language tag with unsupported extension is
        ## valid or not is unclear from the reading of RFC 4646.
        
        ## NOTE: We don't check whether the case is lowercase or not
        ## (see note above on the case of invalid subtags).

        ## NOTE: "When a language tag is to be used in a specific,
        ## known, protocol, it is RECOMMENDED that the language tag
        ## not contain extensions not supported by that protocol."
        ## (RFC 4646 3.7.) - We don't check this, since there is no
        ## extension defined.

        my $ext_type = $ext->[0];
        $ext_type =~ tr/A-Z/a-z/;
        if ($max_ext > ord $ext_type) {
          ## NOTE: "=" is excluded, since duplicate extension subtags
          ## are checked at the parse time.

          ## NOTE: SHOULD be canonicalized (RFC 4646 2.2.6. 11.).  A
          ## language tag SHOULD be canonicalized, and to be canonical
          ## extension tags SHOULD be ordered in ASCII order (RFC 4646
          ## 4.4. 5.).
          $onerror->(type => 'langtag:extension:order',
                     text => chr $max_ext, # $max_ext != 0x00
                     value => $ext->[0],
                     level => $levels->{should});
        } else {
          $max_ext = ord $ext_type;
        }
      }

      if (@{$tag_o->{privateuse}}) {
        ## NOTE: "NOT RECOMMENDED where alternative exist or for
        ## general interchange" (RFC 4646 2.2.7. 6. (RECOMMENDED),
        ## 4.5. (SHOULD NOT)).  Whether alternative exist or not
        ## cannot be detected by the checker (unless providing some
        ## "well-known" private use tag list).  However, the latter
        ## condition should in most case be met (except for internal
        ## uses).
        $onerror->(type => 'langtag:privateuse',
                   value => (join '-', @{$tag_o->{privateuse}}),
                   level => $levels->{should});

        for (@{$tag_o->{privateuse}}) {
          if (/\A[^A-Z]\z/ or
              /\A[^a-z]{2}\z/ or
              /\A[^A-Z]{3}\z/ or
              /\A[^a-z][^A-Z]{3}\z/ or
              /\A[^A-Z]{5,}\z/) {
            #
          } else {
            ## NOTE: RECOMMENDED (RFC 4646 2.1.)
            $onerror->(type => 'langtag:privateuse:case',
                       value => $_,
                       level => $levels->{should});
          }
        }
      }

      ## NOTE: Case of illegal subtags are not checked (see note above
      ## on the case of invalid subtags).
    }
  }
} # check_rfc4646_langtag

## TODO: Should we return values that indicate whether a tag is
## well-formed, valid, or canonical?

## XXX RFC 5646 full canonicalization

## XXX RFC 5646 extlang form

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

## XXX document error types
## XXX document RFC5646 methods
## XXX RFC 1766 support

*match_range_rfc3066 = \&basic_filtering_range_rfc4647;

sub basic_filtering_range_rfc4647 ($$$) {
  my (undef, $range, $tag) = @_;
  $range = '' unless defined $range;
  $tag = '' unless defined $tag;

  return 1 if $range eq '*';
  
  $range =~ tr/A-Z/a-z/;
  $tag =~ tr/A-Z/a-z/;
  
  return $range eq $tag || $tag =~ /^\Q$range\E-/;
} # basic_filtering_range_rfc4647

sub extended_filtering_range_rfc4647 ($$$) {
  my (undef, $range, $tag) = @_;
  $range = '' unless defined $range;
  $tag = '' unless defined $tag;

  $range =~ tr/A-Z/a-z/;
  $tag =~ tr/A-Z/a-z/;
  
  ## 1.
  my @range = split /-/, $range, -1;
  my @tag = split /-/, $tag, -1;

  push @range, '' unless @range;
  push @tag, '' unless @tag;
  
  ## 2.
  unless ($range[0] eq '*' or $range[0] eq $tag[0]) {
    return 0;
  } else {
    shift @range;
    shift @tag;
  }
  
  ## 3.
  while (@range) {
    if ($range[0] eq '*') {
      ## A.
      shift @range;
      next;
    } elsif (not @tag) {
      ## B.
      return 0;
    } elsif ($range[0] eq $tag[0]) {
      ## C.
      shift @range;
      shift @tag;
      next;
    } elsif (1 == length $tag[0]) {
      ## D.
      return 0;
    } else {
      ## E.
      shift @tag;
      next;
    }
  } # @range

  return !@range;
} # extended_filtering_range_rfc4647

=head1 LICENSE

Copyright 2007-2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
