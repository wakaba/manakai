package Message::MIME::Type;
use strict;
use warnings;
our $VERSION = '1.0';

# ------ Instantiation ------

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

  return $self;
} # parse_web_mime_type

# ------ Accessors ------

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

# ------ Serialization ------

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

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
