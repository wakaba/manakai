
=head1 NAME

Message::Field::Params --- Perl module for Internet message
field body consist of parameters, such as C<Content-Type:> field

=cut

package Message::Field::Params;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

use overload '""' => sub { $_[0]->stringify },
             '0+' => sub { $_[0]->count },
             '.=' => sub { $_[0]->add ($_[1], ['', value => 1]); $_[0] },
             fallback => 1;

*REG = \%Message::Util::REG;
## Inherited: comment, quoted_string, domain_literal, angle_quoted
	## WSP, FWS, atext, atext_dot, token, attribute_char
	## S_encoded_word
	## M_quoted_string

$REG{param} = qr/(?:$REG{atext_dot}|$REG{quoted_string}|$REG{angle_quoted})(?:$REG{atext_dot}|$REG{quoted_string}|$REG{WSP}|,)*/;
$REG{param_nocomma} = qr/(?:$REG{atext_dot}|$REG{quoted_string}|$REG{angle_quoted})(?:$REG{atext_dot}|$REG{quoted_string}|$REG{WSP})*/;
	## more naive C<parameter>.  (Comma is allowed for RFC 1049)
$REG{param_free} = qr/(?:[^\x09\x20\x22\x3B\x3C]|$REG{quoted_string}|$REG{angle_quoted})(?:[^\x22\x3B\x3C]|$REG{quoted_string})*/;
$REG{parameter} = qr/$REG{token}=(?:$REG{token}|$REG{quoted_string})?/;
	## as defined by RFC 2045, not RFC 2231.

#$REG{M_parameter} = qr/($REG{token})=($REG{token}|$REG{quoted_string})?/;
$REG{M_parameter} = qr/($REG{token})=($REG{quoted_string}|[^\x22]*)/;
	## as defined by RFC 2045, not RFC 2231.
$REG{M_parameter_name} = qr/($REG{attribute_char}+)(?:\*([0-9]+)(\*)?|(\*))/;
	## as defined by RFC 2231.
$REG{M_parameter_extended_value} = qr/([^']*)'([^']*)'($REG{token}*)/;
	## as defined by RFC 2231, but more naive.


=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -delete_fws	=> 1,## BUG: this option MUST be '1'.
    	## parameter parser cannot procede CFWS.
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #format
    #hook_encode_string
    #hook_decode_string
    -parameter_rule	=> 'param',
    -parameter_name_case_sensible	=> 0,
    -parameter_value_max_length	=> 78,
    -parameter_value_unsafe_rule	=> {'*default'	=> 'NON_http_attribute_char'},
    -parse_all	=> 0,
    -separator	=> '; ',
    -separator_regex	=> qr/$REG{FWS};$REG{FWS}/,
    -use_parameter_extension	=> 0,
    #value_type
  );
  $self->SUPER::_init (%DEFAULT, %options);
  $self->{param} = [];
  my $fname = $self->{option}->{field_name};
  if ($fname eq 'p3p') {
    $self->{option}->{parameter_rule} = 'param_nocomma';
    $self->{option}->{separator} = ', ';
    $self->{option}->{separator_regex} = qr/$REG{FWS},$REG{FWS}/;
  }
  if ($self->{option}->{format} =~ /^http-sip/) {
    $self->{option}->{encoding_before_decode} = 'utf-8';
    $self->{option}->{encoding_after_decode} = 'utf-8';
  } elsif ($self->{option}->{format} =~ /^http/) {
    $self->{option}->{encoding_before_decode} = 'iso-8859-1';
    $self->{option}->{encoding_after_decode} = 'iso-8859-1';
  }
}

## Initialization for new () method.
sub _initialize_new ($;%) {
  ## Nothing to do
}

## Initialization for parse () method.
sub _initialize_parse ($;%) {
  ## Nothing to do
}

=item $p = Message::Field::Params->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

sub new ($;%) {
  my $self = shift->SUPER::new (@_);
  $self->_initialize_new (@_);
  $self;
}

=item $p = Message::Field::Params->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  $self->_initialize_parse (@_);
  $body = Message::Util::delete_comment ($body);
  $body = $self->_delete_fws ($body) if $self->{option}->{delete_fws};
  my @b = ();
  $body =~ s{$REG{FWS}($REG{$self->{option}->{parameter_rule}})
             (?:$self->{option}->{separator_regex}|$)}{
    my $param = $1;
    push @b, $self->_parse_param ($param);
  }goex;
  @b = $self->_restore_param (@b);
  $self->_save_param (@b);
  $self;
}

sub _parse_param ($$) {
  my $self = shift;
  my $param = shift;
  if ($param =~ /^$REG{M_parameter}$/) {
    my ($name, $value) = ($self->_n11n_param_name ($1), $2);
    my ($seq, $isencoded, $charset, $lang) = (-1, 0, '', '');
    if ($name =~ /^$REG{M_parameter_name}$/) {
      ($name, $seq, $isencoded) = ($1, $4?-1:$2, ($3||$4)?1:0);
    }
    if ($isencoded && $value =~ /^$REG{M_parameter_extended_value}$/) {
      ($charset, $lang, $value) = ($1, $2, $3);
    }
    return [$name, {value => $value, seq => $seq, is_encoded => $isencoded,
                    charset => $charset, language => $lang, is_parameter => 1}];
  } else {
    return [$param, {is_parameter => 0}];
  }
}

sub _restore_param ($@) {
  my $self = shift;
  my @p = @_;
  my @ret;
  my %part;
  for my $i (@p) {
    if ($i->[1]->{is_parameter}) {
      my $p = $i->[1];
      if ($p->{seq}<0) {
        my $s = $p->{value};
        if ($p->{is_encoded}) {
          $s =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/chr(hex($1))/eg;
          my %s = &{$self->{option}->{hook_decode_string}} ($self, $s,
                language => $p->{language}, charset => $p->{charset},
                type => 'parameter/encoded');
          ($s, $p->{charset}, $p->{language}) = (@s{qw(value charset language)});
        } elsif ($p->{is_internal}) {
          $s = $p->{value};
        } else {
          my $q = 0;
          ($s,$q) = Message::Util::unquote_if_quoted_string ($p->{value});
          my %s = &{$self->{option}->{hook_decode_string}} ($self, $s,
                type => ($q?'parameter/quoted':'parameter'));
          ($s, $p->{charset}, $p->{language}) = (@s{qw(value charset language)});
        }
        push @ret, [$i->[0], {value => $s, language => $p->{language},
                              charset => $p->{charset}, is_parameter => 1}];
      } else {
        $part{$i->[0]}->[$p->{seq}] = {
        value => scalar Message::Util::unquote_if_quoted_string ($p->{value}),
        language => $p->{language}, charset => $p->{charset},
        is_encoded => $p->{is_encoded}};
      }
    } else {
      #my $q = 0;
      #($i->[0], $q) = Message::Util::unquote_if_quoted_string ($i->[0]);
      #my %s = &{$self->{option}->{hook_decode_string}} ($self, $i->[0],
      #          type => ($q?'phrase/quoted':'phrase'));
      push @ret, [Message::Util::decode_quoted_string ($self, $i->[0]), 
                  {is_parameter => 0}];
    }
  }
  for my $name (keys %part) {
    my $t = join '', map {
      my $v = $_;
      my $s = $v->{value};
      $s =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/chr(hex($1))/eg if $v->{is_encoded};
      $s;
    } @{$part{$name}};
    my %s = &{$self->{option}->{hook_decode_string}} ($self, $t,
                type => 'parameter/encoded');
    ($t,@part{$name}->[0]->{qw(charset language)})=(@s{qw(value charset language)});
    push @ret, [$name, {value => $t, charset => $part{$name}->[0]->{charset},
                        language => $part{$name}->[0]->{language}, 
                        is_parameter => 1}];
  }
  @ret;
}

## $self->_save_param (@parameters)
## --- Save parameter values to $self
sub _save_param ($@) {
  my $self = shift;
  my @p = @_;
  $self->_parse_param_value (\@p) if $self->{option}->{parse_all};
  $self->{param} = \@p;
  $self;
}
*__save_param = \&_save_param;	## SHOULD NOT BE OVERRIDDEN!

## $self->_parse_param_value (\@parameters)
## --- Parse each values of parameters
sub _parse_param_value ($\@) {
  my $self = shift;
  my $p = shift;
  @$p = map {
    if ($_->[1]->{is_parameter}) {
      $_->[1]->{value} = $self->_parse_value ($_->[0] => $_->[1]->{value});
    }
    $_;
  } @$p;
  #$p;
}

=back

=head1 METHODS

=over 4

=item $p->add ($name => [$value], [$name => $value,...])

Adds parameter name=value pair.

  Example:
    $p->add (title => 'foo of bar');	## title="foo of bar"
    $p->add (subject => 'hogehoge, foo');	## subject*=''hogehoge%2C%20foo
    $p->add (foo => ['bar', language => 'en'])	## foo*='en'bar
    $p->add ('text/plain', ['', value => 1])	## text/plain

This method returns array reference of (name, {value => value, attribute...}).

Available options: charset (charset name), language (language tag),
value (1/0, see example above).

=cut

sub add ($$;$%) {
  my $self = shift;
  my %gp = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %gp) {$option{substr ($_, 1)} = $gp{$_}}
  $option{parse} = 1 if defined wantarray;
  my $p;
  for (grep {/^[^-]/} keys %gp) {
    my ($name, $value, %po) = ($self->_n11n_param_name ($_));
    if (ref $gp{$_}) {($value, %po) = @{$gp{$_}}} else {$value = $gp{$_}}
    $p = [$name, {value => $value, charset => $po{charset},
                   is_parameter => 1, language => $po{language}}];
    $p->[1]->{is_parameter} = 0 if !$value && $po{value};
    Carp::croak "add: \$name contains of non-attribute-char: $name"
      if $p->[1]->{is_parameter} && $name =~ /$REG{NON_http_attribute_char}/;
    $p->[1]->{value} = $self->_parse_value ($name => $p->[1]->{value})
      if $option{parse};
    if ($option{prepend}) {
      unshift @{$self->{param}}, $p;
    } else {
      push @{$self->{param}}, $p;
    }
  }
  $p->[1]->{is_parameter}? $p->[1]->{value}: $p->[0];
}

sub replace ($%) {
  my $self = shift;
  my %gp = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %gp) {$option{substr ($_, 1)} = $gp{$_}}
  $option{parse} = 1 if defined wantarray;
  my $p;
  for (grep {/^[^-]/} keys %gp) {
    my ($name, $value, %po) = ($self->_n11n_param_name ($_));
    if (ref $gp{$_}) {($value, %po) = @{$gp{$_}}} else {$value = $gp{$_}}
    $p = [$name, {value => $value, charset => $po{charset},
                  is_parameter => 1, language => $po{language}}];
    $p->[1]->{is_parameter} = 0 if !defined ($value) && $po{value};
    Carp::croak "replace: \$name contains of non-attribute-char: $name"
      if $p->[1]->{is_parameter} && $name =~ /$REG{NON_http_attribute_char}/;
    $p->[1]->{value} = $self->_parse_value ($name => $p->[1]->{value})
      if $option{parse};
    my $f = 0;
    for my $param (@{$self->{param}}) {
      if ($param->[0] eq $name) {$param = $p; $f = 1}
    }
    push @{$self->{param}}, $p unless $f == 1;
  }
  $p->[1]->{is_parameter}? $p->[1]->{value}: $p->[0];
}

## TODO: multiple parameters support
sub delete ($$;%) {
  my $self = shift;
  my ($name, $index) = ($self->_n11n_param_name (shift), shift);
  my $i = 0;
  for my $param (@{$self->{param}}) {
    if ($param->[0] eq $name) {
      $i++;
      if ($index == 0 || $i == $index) {
        undef $param;
        return $self if $i == $index;
      }
    }
  }
  $self;
}

sub count ($;$%) {
  my $self = shift;
  my $name = $self->_n11n_param_name (shift);
  unless ($name) {
    $self->_delete_empty ();
    return $#{$self->{param}}+1;
  }
  my $count = 0;
  for my $param (@{$self->{param}}) {
    if ($param->[0] eq $name) {
      $count++;
    }
  }
  $count;
}


sub parameter ($$;$%) {
  my $self = shift;
  my $name = $self->_n11n_param_name (shift);
  my $newvalue = shift;
  return $self->replace ($name => $newvalue,@_) if defined $newvalue;
  my @ret;
  for my $param (@{$self->{param}}) {
    if ($param->[0] eq $name) {
      unless (wantarray) {
        $param->[1]->{value} 
          = $self->_parse_value ($name => $param->[1]->{value});
        return $param->[1]->{value};
      } else {
        $param->[1]->{value} 
          = $self->_parse_value ($name => $param->[1]->{value});
        push @ret, $param->[1]->{value};
      }
    }
  }
  @ret;
}

sub parameter_name ($$;$) {
  my $self = shift;
  my $i = shift;
  my $newname = shift;
  if ($newname) {
    return 0 if $newname =~ /$REG{NON_http_attribute_char}/;
    $self->{param}->[$i]->[0] = $newname;
  }
  $self->{param}->[$i]->[0];
}
sub parameter_value ($$;$) {
  my $self = shift;
  my $i = shift;
  my $newvalue = shift;
  if ($newvalue) {
    $newvalue = $self->_parse_value ($self->{param}->[$i]->[0] => $newvalue);
    $self->{param}->[$i]->[1]->{value} = $newvalue;
  }
  $self->{param}->[$i]->[1]->{value} 
    = $self->_parse_value 
      ($self->{param}->[$i]->[0] => $self->{param}->[$i]->[1]->{value});
  $self->{param}->[$i]->[1]->{value};
}


sub _delete_empty ($) {
  my $self = shift;
  $self->{param} = [grep {ref $_} @{$self->{param}}];
}


=item $field-body = $p->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $self->_delete_empty;
  my @ret = ();
  $self->scan (sub {
    my $self = shift;
      my ($n => $v) = @_[0 => 2]; #$_->[1];
      return unless $self->_stringify_params_check (@_[0 => 2]);
      my $new = '';
      if ($v->{is_parameter}) {
        my ($encoded, @value) = (0, '');
        my (%e) = &{$self->{option}->{hook_encode_string}} ($self, 
          $v->{value}, current_charset => $v->{charset}, language => $v->{language},
          type => 'parameter');
        if (!defined $e{value}) {
          $value[0] = undef;
        } elsif ($option{use_parameter_extension} && ($e{charset} || $e{language} 
                           || $e{value} =~ /[\x00\x0D\x0A\x80-\xFF]/)) {
          my ($charset, $lang);
          $encoded = 1;
          ($charset, $lang) = ($e{charset}, $e{language});
          ## Note: %-quoting for charset and for language is not allowed.
          ## But charset name can be included non-sttribute-char such as "'".
          ## How can we treat this?
          $charset =~ s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          $lang =~ s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          if (length $e{value} > $option{parameter_value_max_length}) {
            for my $i (0..length ($e{value})/$option{parameter_value_max_length}) {
              $value[$i] = substr ($e{value}, $i*$option{parameter_value_max_length},
                                     $option{parameter_value_max_length});
            }
          } else {$value[0] = $e{value}}
          for my $i (0..$#value) {
            $value[$i] =~ 
              s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          }
          $value[0] = "${charset}'${lang}'".$value[0];
        } elsif (length $e{value} == 0) {
          $value[0] = '""';
        } else {
          if ($option{use_parameter_extension} 
              && length $e{value} > $option{parameter_value_max_length}) {
            for my $i (0..length ($e{value})/$option{parameter_value_max_length}) {
              $value[$i] = Message::Util::quote_unsafe_string 
                (substr ($e{value}, $i*$option{parameter_value_max_length},
                    $option{parameter_value_max_length}), 
                    unsafe => 'NON_http_attribute_char');
            }
          } else {
            my $unsafe = $self->{option}->{parameter_value_unsafe_rule}->{$n}
                     || $self->{option}->{parameter_value_unsafe_rule}->{'*default'};
            $value[0] = Message::Util::quote_unsafe_string 
              ($e{value}, unsafe => $unsafe);
          }
        }
        ## Note: quoted-string for parameter name is not allowed.
        ## But it is better than output bare non-atext.
        if ($#value == 0) {
          $new = 
            Message::Util::quote_unsafe_string ($n, 
              unsafe => 'NON_attribute_char')
            .($encoded?'*':'').'='.$value[0]
              if defined $value[0];
        } else {
          my @new;
          my $name = Message::Util::quote_unsafe_string 
            ($n, unsafe => 'NON_http_attribute_char');
          for my $i (0..$#value) {
            push @new, $name.'*'.$i.($encoded?'*':'').'='.$value[$i];
          }
          $new = join $self->{option}->{separator}, @new;
        }
      } else {
        my %e = &{$self->{option}->{hook_encode_string}} ($self, 
          $n, type => 'phrase');
        $new = Message::Util::quote_unsafe_string ($e{value}, 
          unsafe => 'NON_http_token_wsp');
      }
      push @ret, $new if length $new;
  });
  join $self->{option}->{separator}, @ret;
}
*as_string = \&stringify;

sub _stringify_params_check ($$$) {
  my $self = shift;
  my ($name, $value) = @_;
  1;
}

sub scan ($&) {
  my ($self, $sub) = @_;
  #my $sort;
  #$sort = \&_header_cmp if $self->{option}->{sort} eq 'good-practice';
  #$sort = {$a cmp $b} if $self->{option}->{sort} eq 'alphabetic';
  my @param = @{$self->{param}};
  #if (ref $sort) {
  #  @field = sort $sort @{$self->{param}};
  #}
  for my $param (@param) {
    &$sub($self, $param->[0] => $param->[1]->{value}, $param->[1]);
  }
}

=item $option-value = $p->option ($option-name)

Gets option value.

=item $p->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

sub option ($;$%) {
  my $self = shift;
  my $format = $self->{option}->{format};
  $self->SUPER::option (@_);
  if ($format ne $self->{option}->{format}) {
    $self->scan (sub {
      if (ref $_[1]) {
        $_[1]->option (-format => $self->{option}->{format});
      }
    });
  }
}

## value_type: Inherited

sub value_unsafe_rule ($$;$%) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{option}->{parameter_value_unsafe_rule}->{ $_[0] };
  }
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $name = $self->_n11n_param_name ($name);
    $self->{option}->{parameter_value_unsafe_rule}->{$name} = $value;
  }
}

=item $clone = $p->clone ()

Returns a copy of the object.

=cut

sub clone ($) {
  my $self = shift;
  $self->_delete_empty;
  my $clone = $self->SUPER::clone;
  $clone->{param} = Message::Util::make_clone ($self->{param});
  $clone->{value_type} = Message::Util::make_clone ($self->{value_type});
  $clone;
}

sub _delete_fws ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|((?:$REG{token}|$REG{S_encoded_word})(?:$REG{WSP}+(?:$REG{token}|$REG{S_encoded_word}))+)|$REG{WSP}+}{
    my ($o,$p) = ($1,$2);
    if ($o) {$o}
    elsif ($p) {$p=~s/$REG{WSP}+/\x20/g;$p}
    else {''}
  }gex;
  $body;
}

sub _n11n_param_name ($$) {
  my $self = shift;
  my $s = shift;
  $s = lc $s unless $self->{option}->{parameter_name_case_sensible};
  $s;
}

=head1 LICENSE

Copyright 2002 wakaba E<lt>w@suika.fam.cxE<gt>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=head1 CHANGE

See F<ChangeLog>.
$Date: 2002/06/09 11:08:28 $

=cut

1;
