package Whatpm::LangTag;
use strict;
use warnings;
our $VERSION = '3.0';

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
our $RFC1766;

my $Grandfathered5646 = {map { $_ => 1 } qw(
  en-gb-oed i-ami i-bnn i-default i-enochian i-hak i-klingon i-lux
  i-mingo i-navajo i-pwn i-tao i-tay i-tsu sgn-be-fr sgn-be-nl sgn-ch-de
  art-lojban cel-gaulish no-bok no-nyn zh-guoyu zh-hakka zh-min
  zh-min-nan zh-xiang
)};

# ------ Parsing ------

sub parse_rfc5646_tag ($$;$$) {
  local $RFC5646 = 1;
  return shift->parse_rfc4646_tag (@_);
} # parse_rfc5646_tag

# Compat
*parse_rfc4646_langtag = \&parse_rfc4646_tag;

## NOTE: This method, with appropriate $onerror handler, is a
## "well-formed" processor [RFC 4646].
sub parse_rfc4646_tag ($$;$$) {
  my $tag = $_[1];
  my $onerror = $_[2] || sub { };
  my $levels = $_[3] || $default_error_levels;

  my @tag = split /-/, $tag, -1;

  my %r = (
    language => (@tag ? shift @tag : ''),
    extlang => [],
    variant => [],
    extension => [],
    privateuse => [],
    illegal => [],
  );

  my $tag_l = $tag;
  $tag_l =~ tr/A-Z/a-z/;

  if ($RFC5646 and $Grandfathered5646->{$tag_l}) {
    return {
      extlang => [],
      variant => [],
      extension => [],
      privateuse => [],
      grandfathered => $tag,
      illegal => [],      
    };
  }

  my $grandfathered = !$RFC5646 && $tag =~ /\A[A-Za-z]{1,3}(?>-[A-Za-z0-9]{2,8}){1,2}\z/;

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
      my $exttag = $tag[0];
      $exttag =~ tr/A-Z/a-z/;
      if ($has_extension{$exttag}++) {
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

      ## RFC 6067 / UTS #35
      if ($exttag eq 'u' and $has_extension{$exttag} == 1) {
        $r{u} = [[]];
        my $key = undef;
        my %has_attribute;
        my %has_key;
        for my $i (1..$#$ext) {
          if (2 == length $ext->[$i]) {
            $key = $ext->[$i];
            $key =~ tr/A-Z/a-z/;
            if ($has_key{$key}) {
              $onerror->(type => 'langtag:extension:u:key:duplication',
                         value => $key,
                         level => $levels->{must}); ## RFC 6067
            }
            $has_key{$key}++;
            push @{$r{u}}, [$ext->[$i]];
          } else {
            if (not defined $key) {
              my $attr = $ext->[$i];
              $attr =~ tr/A-Z/a-z/;
              if ($has_attribute{$attr}) {
                $onerror->(type => 'langtag:extension:u:attr:duplication',
                           value => $attr,
                           level => $levels->{langtag_fact}); ## RFC 6067
              }
              $has_attribute{$attr}++;
            }
            push @{$r{u}->[-1]}, $ext->[$i];
          }
        }
      }
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
} # parse_rfc4646_tag

sub serialize_parsed_tag ($$) {
  my $tag_o = $_[1];
  if (defined $tag_o->{grandfathered}) {
    return $tag_o->{grandfathered};
  } else {
    return join '-',
        (defined $tag_o->{language} ? ($tag_o->{language}) : ()),
        @{$tag_o->{extlang}},
        (defined $tag_o->{script} ? ($tag_o->{script}) : ()),
        (defined $tag_o->{region} ? ($tag_o->{region}) : ()),
        @{$tag_o->{variant}},
        (map { @$_ } @{$tag_o->{extension}}),
        @{$tag_o->{privateuse}},
        @{$tag_o->{illegal}};
  }
} # serialize_parsed_tag

# ------ Conformance checking ------

sub check_rfc5646_parsed_tag ($$$;$%) {
  local $RFC5646 = 1;
  return shift->check_rfc4646_parsed_tag (@_);
} # check_rfc5646_parsed_tag

# Compat
*check_rfc4646_langtag = \&check_rfc4646_parsed_tag;

## NOTE: This method, with appropriate $onerror handler, is intended
## to be a "validating" processor of language tags, as defined in RFC
## 4646, if an output of the |parse_rfc4646_tag| method is inputed.
sub check_rfc4646_parsed_tag ($$$;$) {
  my (undef, $tag_o, $onerror, $levels) = @_;
  $levels ||= $default_error_levels;

  my $result = {well_formed => !@{$tag_o->{illegal}}, valid => 1};
  if (defined $tag_o->{language}) {
    delete $result->{well_formed}
        unless $tag_o->{language} =~ /\A[A-Za-z]{2,8}\z/;
  }
  delete $result->{well_formed}
      if grep { not /\A[A-Za-z0-9]{1,8}\z/ } @{$tag_o->{privateuse}};
  delete $result->{valid} unless $result->{well_formed};

  require Whatpm::_LangTagReg;
  our $Registry;

  my $tag_s = $tag_o->{grandfathered};
  unless (defined $tag_s) {
    $tag_s = Whatpm::LangTag->serialize_parsed_tag ($tag_o);
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
    delete $result->{valid};
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
          delete $result->{valid};
        }
      } else {
        ## NOTE: If $tag_o is an output of the method
        ## |parse_rfc4646_tag|, then @{$tag_o->{privateuse}} is true
        ## in this case.  If $tag_o is not an output of that method,
        ## then it might not be true, but we don't support such a
        ## case.
        
        $lang = ''; # for later use.
      }
      
      my $i_extlang = 0;
      for my $extlang_orig (@{$tag_o->{extlang}}) {
        if ($RFC5646 and $i_extlang) {
          ## RFC 5646 2.2.2.
          $onerror->(type => 'langtag:extlang:invalid',
                     value => $extlang_orig,
                     level => $levels->{must});
          delete $result->{valid};
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
              delete $result->{valid} unless $RFC5646;
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
                     level => $RFC5646
                         ? $levels->{must} : $levels->{langtag_fact});
          delete $result->{valid};
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
          delete $result->{valid};
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
          delete $result->{valid};
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
                if (Whatpm::LangTag->extended_filtering_rfc4647_range
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
              delete $result->{valid} unless $RFC5646;
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
                if (Whatpm::LangTag->extended_filtering_rfc4647_range
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
            delete $result->{valid};
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
          delete $result->{valid};
        }
        push @prev_variant, $variant_orig;
        $prev_variant{$variant} = 1;
      }

      my $max_ext = 0x00;
      my %has_ext;
      for my $ext (@{$tag_o->{extension}}) {
        my $ext_type = $ext->[0];
        $ext_type =~ tr/A-Z/a-z/;
        $onerror->(type => 'langtag:extension:unknown',
                   value => (join '-', @{$ext}),
                   level => $levels->{langtag_fact})
            unless $ext_type eq 'u';
        
        ## NOTE: "When a language tag is to be used in a specific,
        ## known, protocol, it is RECOMMENDED that the language tag
        ## not contain extensions not supported by that protocol."
        ## (RFC 4646 3.7.) - We don't check this as we don't know
        ## where the language tag is used.  (In fact we don't want to
        ## implement this kind of meaningless requirement.  Any tag
        ## not supported by a particular system (not restricted to
        ## extensions) should not be used for the document or protocol
        ## specifically targetted for the system cannot be used, but
        ## making it a conformance requirement does not contribute to
        ## interoperability.)

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
          if ($has_ext{$ext_type}) {
            delete $result->{well_formed} unless $RFC5646;
            delete $result->{valid};
          }
          $max_ext = ord $ext_type;
          $has_ext{$ext_type} = 1;
        }

        ## NOTE: We don't check whether the case is lowercase or not
        ## for unknown extensions (see note above on the case of
        ## invalid subtags).
        if ($ext_type eq 'u') {
          ## The "u" extension (UTS #35 and RFC 6067)
          for (@{$ext}[1..$#$ext]) {
            if (/[A-Z]/) {
              $onerror->(type => 'langtag:extension:u:case',
                         value => $_,
                         level => $levels->{warn}); # Canonical form
            }
          }
        }
      }

      ## The "u" extension (UTS #35 and RFC 6067)
      if ($tag_o->{u}) {
        my $prev = '';
        for (0..$#{$tag_o->{u}->[0]}) {
          my $attr = $tag_o->{u}->[0]->[$_];
          $attr =~ tr/A-Z/a-z/;
          if (($prev cmp $attr) > 0) {
            $onerror->(type => 'langtag:extension:u:attr:order',
                       text => $prev,
                       value => $attr,
                       level => $levels->{warn}); # Canonical form
          }
          $prev = $attr;

          ## At the moment attribute is not used at all.
          $onerror->(type => 'langtag:extension:u:attr:invalid',
                     value => $attr,
                     level => $levels->{langtag_fact});
          delete $result->{valid} unless $RFC5646;
        }

        $prev = '';
        for (1..$#{$tag_o->{u}}) {
          my $keyword = $tag_o->{u}->[$_];
          my $key = $keyword->[0];
          $key =~ tr/A-Z/a-z/;
          if (($prev cmp $key) > 0) {
            $onerror->(type => 'langtag:extension:u:key:order',
                       text => $prev,
                       value => $key,
                       level => $levels->{warn}); # Canonical form
          }
          $prev = $key;

          if ($key eq 'vt') {
            ## UTS #35 Appendix Q.
            if (not defined $keyword->[1]) {
              $onerror->(type => 'langtag:extension:u:type:missing',
                         text => 'vt',
                         level => $levels->{langtag_fact});
              delete $result->{valid} unless $RFC5646;
            }

            for (@$keyword[1, 2]) {
              next unless defined;
              if (not /\A[0-9A-Fa-f]{4,6}\z/ or
                  0x10FFFF < hex) {
                $onerror->(type => 'langtag:extension:u:type:invalid',
                           text => 'vt',
                           value => $_,
                           level => $levels->{langtag_fact}); # may
                delete $result->{valid} unless $RFC5646;
              }
            }

            for (@$keyword[3..$#$keyword]) {
              $onerror->(type => 'langtag:extension:u:type:nosemantics',
                         text => 'vt',
                         value => $_,
                         level => $levels->{langtag_fact});
              delete $result->{valid} unless $RFC5646;
            }
          } elsif ($Registry->{u_key}->{$key}) {
            my $type = $keyword->[1];
            $type =~ tr/A-Z/a-z/ if defined $type;
            if (not defined $type) {
              if ($Registry->{'u_' . $key}->{true}) {
                #
              } else {
                ## Semantics is not defined anywhere
                $onerror->(type => 'langtag:extension:u:type:missing',
                           text => $key,
                           level => $levels->{langtag_fact});
                delete $result->{valid} unless $RFC5646;
              }
            } elsif ($Registry->{'u_' . $key}->{$type}) {
              for (@{$keyword}[2..$#$keyword]) {
                ## Semantics is not defined anywhere
                $onerror->(type => 'langtag:extension:u:type:nosemantics',
                           text => $key,
                           value => $_,
                           level => $levels->{langtag_fact});
                delete $result->{valid} unless $RFC5646;
              }
            } else {
              $onerror->(type => 'langtag:extension:u:type:invalid',
                         text => $key,
                         value => $type,
                         level => $levels->{langtag_fact});
              delete $result->{valid} unless $RFC5646;
            }
          } else {
            $onerror->(type => 'langtag:extension:u:key:invalid',
                       value => $key,
                       level => $levels->{langtag_fact});
            delete $result->{valid} unless $RFC5646;
          }
        }

        ## According to RFC 4646 (but not in RFC 5646), if a language
        ## tag contains an extension which is not valid, the entire
        ## language tag is invalid.  However, for the "u" extension
        ## validity is not clearly defined.
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

  return $result;
} # check_rfc4646_parsed_tag

# Compat
*check_rfc3066_language_tag = \&check_rfc3066_tag;

sub check_rfc3066_tag ($$;$$) {
  my $tag = $_[1];
  my $onerror = $_[2] || sub { };
  my $levels = $_[3] || $default_error_levels;
  
  my @tag = split /-/, $tag, -1;

  require Whatpm::_LangTagReg;
  our $Registry;

  if (not $RFC1766 and $tag[0] =~ /\A[0-9]+\z/) {
    $onerror->(type => 'langtag:illegal',
               value => $tag[0],
               level => $levels->{langtag_fact});
  }

  for (@tag) {
    unless (/\A[A-Za-z0-9]{1,8}\z/) {
      $onerror->(type => 'langtag:illegal',
                 value => $_,
                 level => $levels->{langtag_fact});
    } elsif ($RFC1766 and /[0-9]/) {
      $onerror->(type => 'langtag:illegal',
                 value => $_,
                 level => $levels->{langtag_fact});
    }
  }

  if ($tag[0] =~ /\A[A-Za-z]{2}\z/) {
    if ($tag[0] =~ /[A-Z]/) {
      $onerror->(type => 'langtag:language:case',
                 value => $tag[0],
                 level => $levels->{good});
    }

    my $lang = $tag[0];
    $lang =~ tr/A-Z/a-z/;
    unless ($Registry->{language}->{$lang}) {
      ## ISO 639-1 language tag
      $onerror->(type => 'langtag:language:invalid',
                 value => $tag[0],
                 level => $levels->{langtag_fact});
    }
  } elsif (not $RFC1766 and $tag[0] =~ /\A[A-Za-z]{3}\z/) {
    if ($tag[0] =~ /[A-Z]/) {
      $onerror->(type => 'langtag:language:case',
                 value => $tag[0],
                 level => $levels->{good}); # Recommendation of source stds
    }

    my $lang = $tag[0];
    $lang =~ tr/A-Z/a-z/;
    unless ($Registry->{language}->{$lang}) {
      ## - ISO 639-2 language tag (fact)
      ## - Prefer 2-letter code, if any (MUST)
      ## - Prefer /T code to /B code, if any (MUST)
      $onerror->(type => 'langtag:lang:invalid',
                 value => $tag[0],
                 level => $levels->{langtag_fact});
    } elsif ($lang eq 'und') {
      $onerror->(type => 'langtag:language:und',
                 level => $levels->{should});
    } elsif ($lang eq 'mul') {
      $onerror->(type => 'langtag:language:mul',
                 level => $levels->{should});
    } elsif ($lang =~ /\Aq[a-t][a-z]\z/) {
      $onerror->(type => 'langtag:language:private',
                 value => $tag[0],
                 level => $levels->{warn});
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

  if (@tag >= 2 and
      ## This is a willful violation to RFC 1766/3066 - This
      ## interpretation is maybe the real intention of these specs.
      $tag[0] !~ /\A[IiXx]\z/) {
    if ($tag[1] =~ /\A[0-9A-Za-z]{2}\z/) {
      if ($tag[1] =~ /[a-z]/) {
        $onerror->(type => 'langtag:region:case',
                   value => $tag[1],
                   level => $levels->{good}); # Recommendation of source stds
      }
      if ($tag[1] =~ /\A(?>[Aa][Aa]|[Qq][M-Zm-z]|[Xx][A-Za-z]|[Zz][Zz])\z/) {
        $onerror->(type => 'langtag:region:private',
                   value => $tag[1],
                   level => $RFC1766
                       ? $levels->{warn} : $levels->{must}); # RFC 3066 2.2.
      } elsif ($tag[1] =~ /\A([A-Za-z]{2})\z/) {
        my $region = $1;
        $region =~ tr/A-Z/a-z/;
        unless ($Registry->{region}->{$region}) {
          ## ISO 3166 country code (fact)
          $onerror->(type => 'langtag:region:invalid',
                     value => $tag[1],
                     level => $levels->{langtag_fact});
        }
      }
    } elsif (length $tag[1] == 1) {
      $onerror->(type => 'langtag:region:nosemantics', 
                 value => $tag[1],
                 level => $levels->{langtag_fact});
    }
  }

  if (($tag[0] eq 'i' or $tag[0] eq 'I' or
       @tag >= 3 or
       (@tag == 2 and 3 <= length $tag[1])) and
      not $tag[0] eq 'x' and
      not $tag[0] eq 'X') {
    my $tag_l = $tag;
    $tag_l =~ tr/A-Z/a-z/;
    my $def = $Registry->{grandfathered}->{$tag_l} ||
        $Registry->{redundant}->{$tag_l};
    if ($def) {
      if ($def->{_deprecated}) {
        my $level = $levels->{warn};
        ## MUST use ISO tag rather than i-* tag (RFC 3066 2.3)
        $level = $levels->{must}
            if not $RFC1766 and
               $tag_l =~ /^i-/ and
               $def->{_preferred} and
               $def->{_preferred} =~ /^[A-Za-z]{2,3}$/;
        $onerror->(type => 'langtag:deprecated',
                   text => $def->{_preferred}, # or undef
                   value => $tag,
                   level => $level);
      }
    } else {
      $onerror->(type => 'langtag:notregistered',
                 value => $tag,
                 level => $tag_l =~ /^i-/
                     ? $levels->{langtag_fact} : $levels->{warn});
    }
  }
} # check_rfc3066_tag

sub check_rfc1766_tag ($$;$$) {
  local $RFC1766 = 1;
  return shift->check_rfc3066_tag (@_);
} # check_rfc1766_tag

# ------ Normalization ------

## Note: RFC 5646 2.1., 2.2.6.
sub normalize_rfc5646_tag ($$) {
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
} # normalize_rfc5646_tag

sub canonicalize_rfc5646_tag ($$) {
  my $class = shift;
  my $tag = shift;
  $tag = '' unless defined $tag;

  my $tag_l = $tag;
  $tag_l =~ tr/A-Z/a-z/;

  require Whatpm::_LangTagReg;
  our $Registry;

  my $def = $Registry->{grandfathered}->{$tag_l}
      || $Registry->{redundant}->{$tag_l};
  if ($def) {
    if (defined $def->{_preferred}) {
      return $def->{_preferred};
    } else {
      return $tag;
    }
  }

  my $parsed_tag = $class->parse_rfc5646_tag ($tag);
  return $tag unless defined $parsed_tag->{language};

  ## If there are more than one extlang subtags (non-conforming), the
  ## spec does not define how to canonicalize the tag.
  if (@{$parsed_tag->{extlang}} == 1) {
    my $subtag = $parsed_tag->{extlang}->[0];
    $subtag =~ tr/A-Z/a-z/;
    my $def = $Registry->{extlang}->{$subtag};
    if ($def and defined $def->{_preferred}) {
      $parsed_tag->{language} = $def->{_preferred};
      @{$parsed_tag->{extlang}} = ();
    }
  }

  for (qw(language script region)) {
    my $subtag = $parsed_tag->{$_};
    if (defined $subtag) {
      $subtag =~ tr/A-Z/a-z/;
      my $def = $Registry->{$_}->{$subtag};
      if ($def and defined $def->{_preferred}) {
        $parsed_tag->{$_} = $def->{_preferred};
      }
    }
  }

  for (0..$#{$parsed_tag->{variant}}) {
    my $subtag = $parsed_tag->{variant}->[$_];
    $subtag =~ tr/A-Z/a-z/;
    my $def = $Registry->{variant}->{$subtag};
    if ($def and defined $def->{_preferred}) {
      $parsed_tag->{variant}->[$_] = $def->{_preferred};
    }
  }

  $parsed_tag->{extension} = [sort { (ord lc $a->[0]) <=> (ord lc $b->[0]) } @{$parsed_tag->{extension}}];

  return Whatpm::LangTag->serialize_parsed_tag ($parsed_tag);
} # canonicalize_rfc5646_tag

sub to_extlang_form_rfc5646_tag ($$) {
  my $tag = $_[0]->canonicalize_rfc5646_tag ($_[1]);
  if ($tag =~ /^([A-Za-z]{3})(?=-|$)(?!-[A-Za-z]{3}(?=-|$))/) {
    my $subtag = $1;
    $subtag =~ tr/A-Z/a-z/;
    
    require Whatpm::_LangTagReg;
    our $Registry;
    
    my $def = $Registry->{extlang}->{$subtag};
    if ($def and @{$def->{Prefix} or []}) {
      return $def->{Prefix}->[0] . '-' . $tag;
    }
  }
  return $tag;
} # to_extlang_form_rfc5646_tag

# ------ Comparison ------

*match_rfc3066_range = \&basic_filtering_rfc4647_range;

sub basic_filtering_rfc4647_range ($$$) {
  my (undef, $range, $tag) = @_;
  $range = '' unless defined $range;
  $tag = '' unless defined $tag;

  return 1 if $range eq '*';
  
  $range =~ tr/A-Z/a-z/;
  $tag =~ tr/A-Z/a-z/;
  
  return $range eq $tag || $tag =~ /^\Q$range\E-/;
} # basic_filtering_rfc4647_range

sub extended_filtering_rfc4647_range ($$$) {
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
} # extended_filtering_rfc4647_range

# ------ Tag registry data ------

*tag_registry_data_rfc5646 = \&tag_registry_data_rfc4646;

sub tag_registry_data_rfc4646 ($$$) {
  my ($class, $type, $tag) = @_;
  $type =~ tr/A-Z/a-z/;
  $tag =~ tr/A-Z/a-z/;

  require Whatpm::_LangTagReg_Full;
  our $RegistryFull;

  return $RegistryFull->{$type} ? $RegistryFull->{$type}->{$tag} : undef;
} # tag_registry_data_rfc4646

=head1 LICENSE

Copyright 2007-2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
