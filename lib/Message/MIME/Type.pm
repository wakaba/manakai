package Message::MIME::Type;
use strict;
use warnings;

# ------ Instantiation ------

sub new_from_type_and_subtype ($$$) {
  my $self = bless {}, shift;
  $self->{type} = ''.$_[0];
  $self->{type} =~ tr/A-Z/a-z/;
  $self->{subtype} = ''.$_[1];
  $self->{subtype} =~ tr/A-Z/a-z/;
  return $self;
} # new_from_type_and_subtype

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

  for my $attr (sort {$a cmp $b} keys %{$self->{params} or {}}) {
    return undef if not length $attr or $attr =~ /$non_token/o;
    $ts .= '; ' . $attr . '=';

    my $value = $self->{params}->{$attr};
    return undef if $value =~ /[^\x00-\x7F]/;
    $value =~ s/\x0D\x0A?|\x0A/\x0D\x0A /g;

    if (not length $value or $value =~ /$non_token/o) {
      $value =~ s/([\x22\x5C])/\\$1/g;
      $ts .= '"' . $value . '"';
    } else {
      $ts .= $value;
    }
  } 

  return $ts;
} # as_valid_mime_type

1;
