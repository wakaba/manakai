package Message::IMT::InternetMediaType;
use strict;
use warnings;
our $VERSION = '1.4';

## OBSOLETE

package Message::DOM::DOMImplementation;

sub create_internet_media_type ($$$) {
  my ($self, $type, $subtype) = @_;
  my $r = bless {parameter => []}, 'Message::IMT::InternetMediaType';
  $r->top_level_type ($type);
  $r->subtype ($subtype);
  return $r;
} # create_internet_media_type

package Message::IF::InternetMediaType;
package Message::IMT::InternetMediaType;
push our @ISA, 'Message::IF::InternetMediaType';

use overload
  '""' => sub { return $_[0]->imt_text },
  eq => sub {
    return defined $_[1] ? $_[0] . '' eq $_[1] : 0;
  },
  bool => sub { 1 },
  fallback => 1;

sub __token_or_qs ($) {
  my $s = shift;
  if ($s =~ s/([^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E])/\\$1/g) {
    return '"' . $s . '"';
  } elsif ($s eq '') {
    return '""';
  } else {
    return $s;
  }
} # __token_or_qs

sub imt_text ($) {
  my $self = shift;
  my $r = __token_or_qs ($self->top_level_type) . '/' .
    __token_or_qs ($self->subtype);
  for (0 .. ($self->parameter_length - 1)) {
    $r .= '; ' . __token_or_qs ($self->get_attribute ($_)) . '=' .
      __token_or_qs ($self->get_value ($_));
  }
  return $r;
} # imt_text

sub type ($) {
  my $self = shift;
  return __token_or_qs ($self->top_level_type) . '/' .
    __token_or_qs ($self->subtype);
} # type

sub top_level_type ($;$) {
  my $self = shift;
  if (@_) {
    $self->{type} = shift;
    $self->{type} =~ tr/A-Z/a-z/;
    ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
  }
  return $self->{type};
} # top_level_type

sub subtype ($;$) {
  my $self = shift;
  if (@_) {
    $self->{subtype} = shift;
    $self->{subtype} =~ tr/A-Z/a-z/;
    ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
  }
  return $self->{subtype};
} # subtype

sub parameter_length ($) {
  return scalar @{shift->{parameter}};
} # parameter_length

sub get_attribute ($$) {
  my ($self, $index) = @_;
  return defined $self->{parameter}->[$index]
    ? $self->{parameter}->[$index]->[0]
    : undef;
  ## ISSUE: INDEX_SIZE_ERR?
} # get_attribute

sub set_attribute ($$$) {
  my ($self, $index, $attr) = @_;
  if (defined $self->{parameter}->[$index]) {
    $attr =~ tr/A-Z/a-z/;
    $self->{parameter}->[$index]->[0] = $attr;
  }
  ## ISSUE: INDEX_SIZE_ERR?
  ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
} # set_attribute

sub get_value ($$) {
  my ($self, $index) = @_;
  return defined $self->{parameter}->[$index]
    ? $self->{parameter}->[$index]->[1]
    : undef;
  ## ISSUE: INDEX_SIZE_ERR?
} # get_value

sub set_value ($$$) {
  my ($self, $index, $value) = @_;
  if (defined $self->{parameter}->[$index]) {
    $self->{parameter}->[$index]->[1] = $value . '';
  }
  ## ISSUE: INDEX_SIZE_ERR?
  ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
} # set_value

sub get_parameter ($$) {
  my ($self, $attr) = @_;
  $attr =~ tr/A-Z/a-z/;
  for (@{$self->{parameter}}) {
    if ($_->[0] eq $attr) {
      return $_->[1];
    }
  }
  return undef;
} # get_parameter

sub set_parameter ($$$) {
  my ($self, $attr, $value) = @_;
  $attr =~ tr/A-Z/a-z/;
  $value .= '';
  my $i;
  for (reverse 0..$#{$self->{parameter}}) {
    if ($self->{parameter}->[$_]->[0] eq $attr) {
      $self->{parameter}->[$_]->[1] = $value;
      if (defined $i) {
        splice @{$self->{parameter}}, $i, 1, ();
      }
      $i = $_;
    }
  }
  return if defined $i;
  push @{$self->{parameter}}, [$attr => $value];
  ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
} # set_parameter

sub add_parameter ($$$) {
  my ($self, $attr, $value) = @_;
  $attr =~ tr/A-Z/a-z/;
  push @{$self->{parameter}}, [$attr => $value];
  ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
} # add_parameter

sub remove_parameter ($$) {
  my ($self, $attr) = @_;
  $attr =~ tr/A-Z/a-z/;
  for (reverse 0..$#{$self->{parameter}}) {
    if ($self->{parameter}->[$_]->[0] eq $attr) {
      splice @{$self->{parameter}}, $_, 1, ();
    }
  }
  ## NOTE: MAY throw a NO_MODIFICATION_ALLOWED_ERR
} # remove_parameter

sub ___report_error ($$) {
  $_[1]->throw;
} # ___report_error

1;
## $Date: 2007/09/21 08:09:16 $
