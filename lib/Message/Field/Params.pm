
=head1 NAME

Message::Field::Params Perl module

=head1 DESCRIPTION

Perl module for parameters field body (such as C<Content-Type:>).

=cut

package Message::Field::Params;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

use Carp;
use overload '@{}' => sub {shift->_delete_empty()->{param}},
             '""' => sub {shift->stringify};

$REG{WSP} = qr/[\x09\x20]/;
$REG{FWS} = qr/[\x09\x20]*/;

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]+|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{domain_literal} = qr/\x5B(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x5A\x5E-\xFF])*\x5D/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{atext_dot} = qr/[\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]+/;
$REG{token} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;
$REG{attribute_char} = qr/[\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+/;

$REG{param} = qr/(?:$REG{atext_dot}|$REG{quoted_string})(?:$REG{atext_dot}|$REG{quoted_string}|$REG{WSP}|,)*/;
	## more naive C<parameter>.  (Comma is allowed for RFC 1049)
$REG{parameter} = qr/$REG{token}=(?:$REG{token}|$REG{quoted_string})?/;
	## as defined by RFC 2045, not RFC 2231.

$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_parameter} = qr/($REG{token})=($REG{token}|$REG{quoted_string})?/;
	## as defined by RFC 2045, not RFC 2231.
$REG{M_parameter_name} = qr/($REG{attribute_char}+)(?:\*([0-9]+)(\*)?|(\*))/;
	## as defined by RFC 2231.
$REG{M_parameter_extended_value} = qr/([^']*)'([^']*)'($REG{token}*)/;
	## as defined by RFC 2231, but more naive.

$REG{NON_atext} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{NON_atext_dot} = qr/[^\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{NON_token} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/;
$REG{NON_attribute_char} = qr/[^\x21\x23-\x24\x26\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]/;


%DEFAULT = (
  delete_fws	=> 1,
  parameter_value_max	=> 78,
  use_parameter_extension	=> -1,
);

=head2 Message::Field::Params->new ([%option])

Returns new Message::Field::Params.  Some options can be given as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {option => {@_}}, $class;
  $self->_initialize_new ();
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

## Initialization for new () method.
sub _initialize_new ($;%) {
  my $self = shift;
  #for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
}

=head2 Message::Field::Params->parse ($nantara, [%option])

Parse Message::Field::Params and new ContentType instance.  
Some options can be given as hash.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $body = shift;
  my $self = bless {option => {@_}}, $class;
  $self->_initialize_parse ();
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $body = $self->_delete_comment ($body);
  $body = $self->_delete_fws ($body) if $self->{option}->{delete_fws}>0;
  my @b = ();
  $body =~ s{$REG{FWS}($REG{param})$REG{FWS}(?:;$REG{FWS}|$)}{
    my $param = $1;
    push @b, $self->_parse_param ($param);
  }goex;
  @b = $self->_restore_param (@b);
  $self->_save_param (@b);
  $self;
}

## Initialization for parse () method.
sub _initialize_parse ($;%) {
  my $self = shift;
  #for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
}

sub _parse_param ($$) {
  my $self = shift;
  my $param = shift;
  if ($param =~ /^$REG{M_parameter}$/) {
    my ($name, $value) = (lc $1, $2);
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
        } else {
          $s = $self->_unquote_if_quoted_string ($p->{value});
        }
        push @ret, [$i->[0], {value => $s, language => $p->{language},
                              charset => $p->{charset}, is_parameter => 1}];
      } else {
        $part{$i->[0]}->[$p->{seq}] = {
        value => $self->_unquote_if_quoted_string ($p->{value}),
        language => $p->{language}, charset => $p->{charset},
        is_encoded => $p->{is_encoded}};
      }
    } else {push @ret, $i}
  }
  for my $name (keys %part) {
    my $t = join '', map {
      my $v = $_;
      my $s = $v->{value};
      $s =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/chr(hex($1))/eg if $v->{is_encoded};
      $s;
    } @{$part{$name}};
    push @ret, [$name, {value => $t, charset => $part{$name}->[0]->{charset},
                        language => $part{$name}->[0]->{language}, 
                        is_parameter => 1}];
  }
  @ret;
}

sub _save_param ($@) {
  my $self = shift;
  my @p = @_;
  $self->{param} = \@p;
  $self;
}

=head2 $self->add ($name, [$value]. [%option]

Adds parameter name=value pair.

  Example:
    $self->add (title => 'foo of bar');	## title="foo of bar"
    $self->add (subject => 'hogehoge, foo');	## subject*=''hogehoge%2C%20foo
    $self->add (foo => 'bar', language => 'en')	## foo*='en'bar
    $self->add ('text/plain', '', value => 1)	## text/plain

This method returns array reference of (name, {value => value, attribute...}).

Available options: charset (charset name), language (language tag),
value (1/0, see example above).

=cut

sub add ($$;$%) {
  my $self = shift;
  my ($name, $value, %option) = (lc shift, shift, @_);
  my $p = [$name, {value => $value, charset => $option{charset},
                   is_parameter => 1, language => $option{language}}];
  $p->[1]->{is_parameter} = 0 if !$value && $option{value}>0;
  croak "add: \$name contains of non-attribute-char: $name"
     if $p->[1]->{is_parameter} && $name =~ /$REG{NON_attribute_char}/;
  $p->[1]->{value} = $self->_param_value ($name => $p->[1]->{value});
  if ($option{prepend}) {
    unshift @{$self->{param}}, $p;
  } else {
    push @{$self->{param}}, $p;
  }
  $p;
}
sub replace ($$;$%) {
  my $self = shift;
  my ($name, $value, %option) = (lc shift, shift, @_);
  for my $param (@{$self->{param}}) {
    if ($param->[0] eq $name) {
      $param->[1] = {value => $value, charset => $option{charset},
                     is_parameter => 1, language => $option{language}};
      $param->[1]->{is_parameter} = 0 if !$value && $option{value}>0;
      $param->[1]->{value} = $self->_param_value ($name => $param->[1]->{value});
      return $param;
    }
  }
  my $p = [$name, {value => $value, charset => $option{charset},
                   is_parameter => 1, language => $option{language}}];
  $p->[1]->{is_parameter} = 0 if !$value && $option{value}>0;
  croak "replace: \$name contains of non-attribute-char: $name"
    if $p->[1]->{is_parameter} && $name =~ /$REG{NON_attribute_char}/;
  $p->[1]->{value} = $self->_param_value ($name => $p->[1]->{value});
  push @{$self->{param}}, $p;
  $p;
}

sub delete ($$;%) {
  my $self = shift;
  my ($name, $index) = (lc shift, shift);
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
  my ($name) = (lc shift);
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


sub parameter ($$;$) {
  my $self = shift;
  my $name = lc shift;
  my $newvalue = shift;
  return $self->replace ($name => $newvalue,@_)->[1]->{value} if defined $newvalue;
  my @ret;
  for my $param (@{$self->{param}}) {
    if ($param->[0] eq $name) {
      unless (wantarray) {
        $self->{param}->[1]->{value} 
          = $self->_param_value ($name => $self->{param}->[1]->{value});
        return $param->[1]->{value};
      } else {
        $self->{param}->[1]->{value} 
          = $self->_param_value ($name => $self->{param}->[1]->{value});
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
    return 0 if $newname =~ /$REG{NON_attribute_char}/;
    $self->{param}->[$i]->[0] = $newname;
  }
  $self->{param}->[$i]->[0];
}
sub parameter_value ($$;$) {
  my $self = shift;
  my $i = shift;
  my $newvalue = shift;
  if ($newvalue) {
    $newvalue = $self->_param_value ($self->{param}->[$i]->[0] => $newvalue);
    $self->{param}->[$i]->[1]->{value} = $newvalue;
  }
  $self->{param}->[$i]->[1]->{value} 
    = $self->_param_value 
      ($self->{param}->[$i]->[0] => $self->{param}->[$i]->[1]->{value});
  $self->{param}->[$i]->[1]->{value};
}

## Hook called before returning C<value>.
## $self->_param_value ($name, $value);
sub _param_value ($$$) {$_[2]}

sub _delete_empty ($) {
  my $self = shift;
  my @ret;
  for my $param (@{$self->{param}}) {
    push @ret, $param if $param->[0];
  }
  $self->{param} = \@ret;
  $self;
}


=head2 $self->stringify ([%option])

Returns Message::Field::Params as a string.

=head2 $self->as_string ([%option])

An alias of C<stringify>.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  my $use_xparam = $option{use_parameter_extension} 
            || $self->{option}->{use_parameter_extension};
  $option{parameter_value_max} 
            ||= $self->{option}->{parameter_value_max};
  $self->_delete_empty ();
  join '; ',
    map {
      my $v = $_->[1];
      my $new = '';
      if ($v->{is_parameter}) {
        my ($encoded, @value) = (0, '');
        if ($use_xparam>0 && ($v->{charset} || $v->{language} 
                           || $v->{value} =~ /[\x00\x0D\x0A\x80-\xFF]/)) {
          my ($charset, $lang);
          $encoded = 1;
          ($charset, $lang) = ($v->{charset}, $v->{language});
          ## Note: %-quoting for charset and for language is not allowed.
          ## But charset name can be included non-sttribute-char such as "'".
          ## How can we treat this?
          $charset =~ s/($REG{NON_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          $lang =~ s/($REG{NON_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          if (length $v->{value} > $option{parameter_value_max}) {
            for my $i (0..length ($v->{value})/$option{parameter_value_max}) {
              $value[$i] = substr ($v->{value}, $i*$option{parameter_value_max},
                                                   $option{parameter_value_max});
            }
          } else {$value[0] = $v->{value}}
          for my $i (0..$#value) {
            $value[$i] =~ s/($REG{NON_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          }
          $value[0] = "${charset}'${lang}'".$value[0];
        } elsif (length $v->{value} == 0) {
          $value[0] = '""';
        } else {
          if ($use_xparam>0 && length $v->{value} > $option{parameter_value_max}) {
            for my $i (0..length ($v->{value})/$option{parameter_value_max}) {
              $value[$i] = $self->_quote_unsafe_string 
                (substr ($v->{value}, $i*$option{parameter_value_max},
                    $option{parameter_value_max}), unsafe => 'NON_attribute_char');
            }
          } else {
            $value[0] = $self->_quote_unsafe_string 
              ($v->{value}, unsafe => 'NON_attribute_char');
          }
        }
        ## Note: quoted-string for parameter name is not allowed.
        ## But it is better than output bare non-atext.
        if ($#value == 0) {
          $new = 
            $self->_quote_unsafe_string ($_->[0], unsafe => 'NON_attribute_char')
            .($encoded?'*':'').'='.$value[0];
        } else {
          my @new;
          my $name = $self->_quote_unsafe_string 
            ($_->[0], unsafe => 'NON_attribute_char');
          for my $i (0..$#value) {
            push @new, $name.'*'.$i.($encoded?'*':'').'='.$value[$i];
          }
          $new = join '; ', @new;
        }
      } else {
        $new = $self->_quote_unsafe_string ($_->[0], unsafe => 'NON_token');
      }
      $new;
    } @{$self->{param}}
  ;
}
sub as_string ($;%) {shift->stringify (@_)}

=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $newval) = @_;
  if ($newval) {
    $self->{option}->{$name} = $newval;
  }
  $self->{option}->{$name};
}

sub _quote_unsafe_string ($$;%) {
  my $self = shift;
  my $string = shift;
  my %option = @_;
  $option{unsafe} ||= 'NON_atext_dot';
  if ($string =~ /$REG{$option{unsafe}}/ || $string =~ /$REG{WSP}$REG{WSP}+/) {
    $string =~ s/([\x22\x5C])/\x5C$1/g;
    $string = '"'.$string.'"';
  }
  $string;
}

=head2 $self->_unquote_quoted_string ($string)

Unquote C<quoted-string>.  Get rid of C<DQUOTE>s and
C<REVERSED SOLIDUS> included in C<quoted-pair>.
This method is intended for internal use.

=cut

sub _unquote_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

sub _unquote_if_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{^$REG{M_quoted_string}$}{
    my $qtext = $1;
    $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
    $qtext;
  }goex;
  $quoted_string;
}

=head2 $self->_delete_comment ($field_body)

Remove all C<comment> in given strictured C<field-body>.
This method is intended for internal use.

=cut

sub _delete_comment ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal})|$REG{comment}}{
    my $o = $1;  $o? $o : ' ';
  }gex;
  $body;
}

sub _delete_fws ($$) {
  my $self = shift;
  my $body = shift;
  $body =~ s{($REG{quoted_string}|$REG{domain_literal}|$REG{attribute_char}$REG{WSP}+$REG{attribute_char})|$REG{WSP}+}{
    my $o = $1;  $o? $o : '';
  }gex;
  $body;
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
$Date: 2002/03/23 11:41:36 $

=cut

1;
