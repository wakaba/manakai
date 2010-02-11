package Message::MIME::Type;
use strict;
use warnings;
our $VERSION = '1.0';

## ------ Instantiation ------

## NOTE: RFC 2046 sucks, it is a poorly written specification such that
## what we should do is not entirely clear and it does define almost nothing
## from the today's viewpoint...  Suprisingly, it's even worse than
## RFC 1521, the previous version of that specification, which does
## contain BNF rules for parameter values at least.

my $default_error_levels = {
  must => 'm',
  warn => 'w',
  info => 'i',
  uncertain => 'u',

  mime_must => 'm', # lowercase "must"
  mime_fact => 'm',
  mime_strongly_discouraged => 'w',
  mime_discouraged => 'w',

  http_fact => 'm',
};

sub new_from_type_and_subtype ($$$) {
  my $self = bless {}, shift;
  $self->{type} = ''.$_[0];
  $self->{type} =~ tr/A-Z/a-z/;
  $self->{subtype} = ''.$_[1];
  $self->{subtype} =~ tr/A-Z/a-z/;
  $self->{level} = $default_error_levels;
  return $self;
} # new_from_type_and_subtype

my $HTTPToken = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]+/;
my $lws0 = qr/(?>(?>\x0D\x0A)?[\x09\x20])*/;
my $HTTP11QS = qr/"(?>[\x20\x21\x23-\x5B\x5D-\x7E]|\x0D\x0A[\x09\x20]|\x5C[\x00-\x7F])*"/;

## Web Applications 1.0 "valid MIME type"'s "MUST".
sub parse_web_mime_type ($$;$$) {
  my ($class, $value, $onerror, $levels) = @_;
  $onerror ||= sub {
    my %args = @_;
    warn sprintf "$args{type} at position $args{index}\n";
  };
  $levels ||= $default_error_levels;

  $value =~ /\G$lws0/ogc;

  my $type;
  if ($value =~ /\G($HTTPToken)/ogc) {
    $type = $1;
  } else {
    $onerror->(type => 'MIME:no type', # XXXdocumentation
               level => $levels->{http_fact},
               index => pos $value);
    return undef;
  }

  unless ($value =~ m[\G/]gc) {
    $onerror->(type => 'MIME:no /', # XXXdocumentation
               level => $levels->{http_fact},
               index => pos $value);
    return undef;
  }

  my $subtype;
  if ($value =~ /\G($HTTPToken)/ogc) {
    $subtype = $1;
  } else {
    $onerror->(type => 'MIME:no subtype', # XXXdocumentation
               level => $levels->{http_fact},
               index => pos $value); 
    return undef;
  }

  $value =~ /\G$lws0/ogc;

  my $self = $class->new_from_type_and_subtype ($type, $subtype);

  while ($value =~ /\G;/gc) {
    $value =~ /\G$lws0/ogc;
    
    my $attr;
    if ($value =~ /\G($HTTPToken)/ogc) {
      $attr = $1;
    } else {
      $onerror->(type => 'params:no attr', # XXXdocumentation
                 level => $levels->{http_fact},
                 index => pos $value);
      return $self;
    }

    unless ($value =~ /\G=/gc) {
      $onerror->(type => 'params:no =', # XXXdocumentation
                 level => $levels->{http_fact},
                 index => pos $value);
      return $self;
    }

    my $v;
    if ($value =~ /\G($HTTPToken)/ogc) {
      $v = $1;
    } elsif ($value =~ /\G($HTTP11QS)/ogc) {
      $v = substr $1, 1, length ($1) - 2;
      $v =~ s/\\(.)/$1/gs;
    } else {
      $onerror->(type => 'params:no value', # XXXdocumentation
                 level => $levels->{http_fact},
                 index => pos $value);
      return $self;
    }

    $value =~ /\G$lws0/ogc;

    my $current = $self->param ($attr);
    if (defined $current) {
      ## Surprisingly this is not a violation to the MIME or HTTP spec!
      $onerror->(type => 'params:duplicate attr', # XXXdocumentation
                 level => $levels->{warn},
                 value => $attr,
                 index => pos $value);
      next;
    } else {
      $self->param ($attr => $v);
    }
  }

  if (pos $value < length $value) {
    $onerror->(type => 'params:garbage', # XXXdocumentation
               level => $levels->{http_fact},
               index => pos $value);
  }

  $self->{level} = $levels;
  return $self;
} # parse_web_mime_type

## ------ Accessors ------

sub type ($;$) {
  my $self = shift;
  if (@_) {
    $self->{type} = ''.$_[0];
    $self->{type} =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
  }

  return $self->{type};
} # top_level_type

sub subtype ($;$) {
  my $self = shift;
  if (@_) {
    $self->{subtype} = ''.$_[0];
    $self->{subtype} =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
  }

  return $self->{subtype};
} # subtype

sub param ($$;$) {
  my $self = shift;
  my $n = ''.$_[0];
  $n =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
  if (@_ > 1) {
    $self->{params}->{$n} = ''.$_[1];
  } else {
    return $self->{params}->{$n};
  }
}

sub attrs ($) {
  my $self = shift;
  return [sort {$a cmp $b} keys %{$self->{params}}];
} # attrs

## ------ Serialization ------

my $non_token = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;

sub as_valid_mime_type_with_no_params ($) {
  my $self = shift;

  my $type = $self->type;
  my $subtype = $self->subtype;
  if (not length $type or not length $subtype or
      $type =~ /$non_token/o or $subtype =~ /$non_token/o) {
    return undef;
  }

  return $type . '/' . $subtype;
} # as_valid_mime_type_with_no_params

sub as_valid_mime_type ($) {
  my $self = shift;
  
  my $ts = $self->as_valid_mime_type_with_no_params;
  return undef unless defined $ts;

  for my $attr (@{$self->attrs}) {
    return undef if not length $attr or $attr =~ /$non_token/o;
    $ts .= '; ' . $attr . '=';

    my $value = $self->{params}->{$attr};
    return undef if $value =~ /[^\x00-\x7F]/;
    $value =~ s/\x0D\x0A?|\x0A/\x0D\x0A /g;

    if (not length $value or $value =~ /$non_token/o) {
      $value =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F\x22\x5C\x7F])/\\$1/g;
      $ts .= '"' . $value . '"';
    } else {
      $ts .= $value;
    }
  } 

  return $ts;
} # as_valid_mime_type

## ------ Conformance checking ------

sub validate ($$) {
  my ($self, $onerror) = @_;

  ## NOTE: Attribute duplication are not error, though its semantics
  ## is not defined.  See
  ## <http://suika.fam.cx/gate/2005/sw/%E5%AA%92%E4%BD%93%E5%9E%8B/%E5%BC%95%E6%95%B0>.
  ## However, a Message::MIME::Type object cannot represent duplicate
  ## attributes and is reported in the parsing phase.

  my $type = $self->type;
  my $subtype = $self->subtype;

  ## NOTE: RFC 2045 (MIME), RFC 2616 (HTTP/1.1), and RFC 4288 (IMT
  ## registration) have different requirements on type and subtype names.
  if ($type !~ /\A[A-Za-z0-9!#\$&.+^_-]{1,127}\z/) {
    $onerror->(type => 'IMT:type syntax error',
               level => $self->{level}->{must}, # RFC 4288 4.2.
               value => $type);
  }
  if ($subtype !~ /\A[A-Za-z0-9!#\$&.+^_-]{1,127}\z/) {
    $onerror->(type => 'IMT:subtype syntax error',
               level => $self->{level}->{must}, # RFC 4288 4.2.
               value => $subtype);
  }

  require Message::MIME::Type::Definitions;
  my $type_def = $Message::MIME::Type::Definitions::Type->{$type};
  my $has_param;

  if ($type =~ /^x-/) {
    $onerror->(type => 'IMT:private type',
               level => $self->{level}->{mime_strongly_discouraged},
               value => $type); # RFC 2046 6.
    ## NOTE: "discouraged" in RFC 4288 3.4.
  } elsif (not $type_def or not $type_def->{registered}) {
  #} elsif ($type_def and not $type_def->{registered}) {
    ## NOTE: Top-level type is seldom added.
    
    ## NOTE: RFC 2046 6. "Any format without a rigorous and public
    ## definition must be named with an "X-" prefix" (strictly
    ## speaking, this is not an author requirement, but a requirement
    ## for media type specfication author, and it does not restrict
    ## use of unregistered value).
    $onerror->(type => 'IMT:unregistered type',
               level => $self->{level}->{mime_must},
               value => $type);
  }

  if ($type_def) {
    my $subtype_def = $type_def->{subtype}->{$subtype};

    if ($subtype =~ /^x[-\.]/) {
      $onerror->(type => 'IMT:private subtype',
                 level => $self->{level}->{mime_discouraged},
                 value => $type . '/' . $subtype);
      ## NOTE: "x." and "x-" are discouraged in RFC 4288 3.4.
    } elsif ($subtype_def and not $subtype_def->{registered}) {
      ## NOTE: RFC 2046 6. "Any format without a rigorous and public
      ## definition must be named with an "X-" prefix" (strictly, this
      ## is not an author requirement, but a requirement for media
      ## type specfication author and it does not restrict use of
      ## unregistered value).
      $onerror->(type => 'IMT:unregistered subtype',
                 level => $self->{level}->{mime_must},
                 value => $type . '/' . $subtype);
    }
    
    if ($subtype_def) {
      ## NOTE: Semantics and relationship to conformance of the
      ## "intended usage" keywords in the IMT registration template is
      ## not defined anywhere.
      if ($subtype_def->{obsolete}) {
        $onerror->(type => 'IMT:obsolete subtype',
                   level => $self->{level}->{warn},
                   value => $type . '/' . $subtype);
      } elsif ($subtype_def->{limited_use}) {
        $onerror->(type => 'IMT:limited use subtype',
                   level => $self->{level}->{warn},
                   value => $type . '/' . $subtype);        
      }

      for my $attr (@{$self->attrs}) {
        my $value = $self->param ($attr);

        if ($attr !~ /\A[A-Za-z0-9!#\$&.+^_-]{1,127}\z/) {
          $onerror->(type => 'IMT:attribute syntax error',
                     level => $self->{level}->{mime_fact}, # RFC 4288 4.3.
                     value => $attr);
        }

        $has_param->{$attr} = 1;
        my $param_def = $subtype_def->{parameter}->{$attr}
            || $type_def->{parameter}->{$attr};
        if ($param_def) {
          if (defined $param_def->{syntax}) {
            if ($param_def->{syntax} eq 'mime-charset') { # RFC 2978
              ## XXX Should be checked against IANA charset registry.
              if ($value =~ /[^A-Za-z0-9!#\x23%&'+^_`{}~-]/) {
                $onerror->(type => 'value syntax error:'.$attr, level => 'm');
              }
            } elsif ($param_def->{syntax} eq 'token') { # RFC 2046
              ## NOTE: Though the definition of |token| differs in RFC
              ## 2046 and in RFC 2616, parameters are defined in terms
              ## of MIME RFCs such that this should be checked against
              ## MIME's definition.  Use of "{" and "}" in HTTP
              ## contexts is rejected anyway at the parsing phase.
              if ($value =~ /[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/) {
                $onerror->(type => 'value syntax error:'.$attr, level => 'm');
              }
            }
            ## XXX add support for syntax |MIME date-time|
          } elsif ($param_def->{checker}) {
            $param_def->{checker}->($self, $value, $onerror);
          }
           
          if ($param_def->{obsolete}) {
            $onerror->(type => 'IMT:obsolete parameter',
                       level => $self->{level}->{$param_def->{obsolete}},
                       value => $attr);
            ## NOTE: The value of |$param_def->{obsolete}|, if it has
            ## a true value, must be "mime_fact", which represents
            ## that the parameter is defined in a previous version of
            ## the MIME specification (or a related specification) and
            ## then removed or marked as obsolete such that it seems
            ## that use of that parameter is made non-conforming
            ## without using any explicit statement on that fact.
          }
        }
        if (not $param_def or not $param_def->{registered}) {
          if ($subtype =~ /\./ or $subtype =~ /^x-/ or $type =~ /^x-/) {
            ## NOTE: The parameter names "SHOULD" be fully specified
            ## for personal or vendor tree subtype [RFC 4288].
            ## Therefore, there might be unknown parameters and still
            ## conforming.
            $onerror->(type => 'IMT:unknown parameter',
                       level => $self->{level}->{uncertain},
                       value => $attr);
          } else {
            ## NOTE: The parameter names "MUST" be fully specified for
            ## standard tree.  Therefore, unknown parameter is
            ## non-conforming, unless it is standardized later.
            $onerror->(type => 'IMT:parameter not allowed',
                       level => $self->{level}->{mime_fact},
                       value => $attr);
          }
        }
      }

      for (keys %{$subtype_def->{parameter} or {}}) {
        if ($subtype_def->{parameter}->{$_}->{required} and
            not $has_param->{$_}) {
          $onerror->(type => 'IMT:parameter missing',
                     level => $self->{level}->{mime_fact},
                     text => $_,
                     value => $type . '/' . $subtype);
        }
      }
    } else {
      ## NOTE: Since subtypes are frequently added to the IANAREG and
      ## such that our database might be out-of-date, we don't raise
      ## an error for an unknown subtype, instead we report an
      ## "uncertain" status.
      $onerror->(type => 'IMT:unknown subtype',
                 level => $self->{level}->{uncertain},
                 value => $type . '/' . $subtype);
    }

    for (keys %{$type_def->{parameter} or {}}) {
      if ($type_def->{parameter}->{$_}->{required} and
          not $has_param->{$_}) {
        $onerror->(type => 'IMT:parameter missing',
                   level => $self->{level}->{mime_fact},
                   text => $_,
                   value => $type . '/' . $subtype);
      }
    }
  }
} # check_imt

1;

=head1 LICENSE

Copyright 2007-2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
