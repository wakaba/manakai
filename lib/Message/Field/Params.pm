
=head1 NAME

Message::Field::Params --- Perl module for Internet message
field body consist of parameters, such as C<Content-Type:> field

=cut

package Message::Field::Params;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.16 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::MIME::Charset;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

use overload '""' => sub { $_[0]->stringify },
             '0+' => sub { $_[0]->count },
             '.=' => sub { $_[0]->add ($_[1], ['', value => 1]); $_[0] },
             fallback => 1;

%REG = %Message::Util::REG;

$REG{S_parameter} = qr/(?:[^\x22\x28\x3B\x3C]|$REG{comment}|$REG{quoted_string}|$REG{angle_quoted})+/;
$REG{S_parameter_separator} = qr/;/;
$REG{S_comma_parameter} = qr/(?:[^\x22\x28\x2C\x3C]|$REG{comment}|$REG{quoted_string}|$REG{angle_quoted})+/;
$REG{S_comma_parameter_separator} = qr/,/;
$REG{MS_parameter_avpair} = qr/([^\x22\x3C\x3D]+)=([\x00-\xFF]*)/;

%DEFAULT = (
	-_HASH_NAME	=> 'params',
	-_MEMBERS	=> [qw/params/],
	-_METHODS	=> [qw/add replace delete item parameter scan/],
		## count item_exist <- not implemented yet
	-accept_coderange	=> '7bit',
	-by	=> 'attribute',
	#encoding_after_encode
	#encoding_before_decode
	#field_param_name
	#field_name
	#field_ns
	#format
	#header_default_charset
	#header_default_charset_input
	#hook_encode_string
	#hook_decode_string
	-output_comment	=> 1,
	-output_parameter_extension	=> 0,
	-parameter_rule	=> 'S_parameter',	## regex name of parameter
	-parameter_attribute_case_sensible	=> 0,
	-parameter_attribute_unsafe_rule	=> 'NON_http_attribute_char',
	-parameter_av_Mrule	=> 'MS_parameter_avpair',
	-parameter_no_value_attribute_unsafe_rule	=> 'NON_http_attribute_char',
	-parameter_value_max_length	=> 60,
	-parameter_value_split_length	=> 35,
	-parameter_value_unsafe_rule	=> 'NON_http_attribute_char',
	#parse_all
	-separator	=> '; ',
	-separator_rule	=> 'parameter_separator',
	-use_comment	=> 1,
	-use_parameter_extension	=> 1,
	#value_type
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->SUPER::_init (%DEFAULT, %options);
  $self->{param} = [];
  my $field = $self->{option}->{field_name};
  if ($field eq 'p3p') {
    $self->{option}->{parameter_rule} = 'S_comma_parameter';
    $self->{option}->{separator_rule} = 'S_comma_parameter_separator';
    $self->{option}->{separator} = ', ';
  }
  if ($self->{option}->{format} =~ /news-usefor/) {
    $self->{option}->{accept_coderange} = '8bit';
  } elsif ($self->{option}->{format} =~ /http/) {
    $self->{option}->{accept_coderange} = 'binary';
  }
}

=item $p = Message::Field::Params->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $p = Message::Field::Params->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my @param;
  $body =~ s{
    ($REG{ $self->{option}->{parameter_rule} })
    (?: $REG{ $self->{option}->{separator_rule} } | $ )
  }{
    push @param, $self->_parse_parameter_item ($1, $self->{option});
    '';
  }gesx;
  $self->_decode_parameters (\@param, $self->{option});
  $self->_save_parameters (\@param, $self->{option});
  $self;
}

## $self->_parse_parameter_item ($item, \%option)
## -- parses a parameter item (into attribute/value pair or no-value-attribute)
sub _parse_parameter_item ($$\%) {
  my $self = shift;
  my ($item, $option) = @_;
  my @comment;
  ($item, @comment) = $self->Message::Util::delete_comment_to_array
    ($item, -use_angle_quoted);
  $item =~ s/^$REG{WSP}+//g;
  $item =~ s/$REG{WSP}+$//g;
  my %item;
  if ($item =~ /^$REG{ $option->{parameter_av_Mrule} }$/) {
    my $encoded = 0;
    ($item{attribute}, $item{value}) = ($1, $2);
    $item{attribute} =~ tr/\x09\x0A\x0D\x20//d;
    $item{value} =~ s/^$REG{WSP}+//g;
    if ($option->{use_parameter_extension}
     && $item{attribute} =~ /^([^*]+)(?:\*([0-9]+)(\*)?|(\*))\z/) {
      $item{attribute} = $1;
      $item{section_no} = $2;
      $encoded = $3 || $4;
      $item{section_no} = -1 if $4;
      if ($item{section_no} <= 0 && $encoded
       && $item{value} =~ /^([^']*)'([^']*)'([\x00-\xFF]*)$/) {
        $item{charset} = $1;  $item{charset} =~ tr/\x09\x0A\x0D\x20//d;
        $item{language} = $2; $item{language} =~ tr/\x09\x0A\x0D\x20//d;
        $item{value} = $3;    $item{value} =~ s/^$REG{WSP}+//g;
      }
      if ($encoded) {
        $item{value} =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/chr(hex($1))/ge;
      }
    } else {
      $item{section_no} = -1;
    }
    ($item{value}, $encoded) = Message::Util::unquote_if_quoted_string ($item{value}) unless $encoded;
    ($item{value}, $encoded) = Message::Util::unquote_if_angle_quoted ($item{value}) unless $encoded;
    $item{charset} = '*bare' if !$encoded && !$item{charset};
    $item{attribute} = lc $item{attribute}
      unless $option->{parameter_attribute_case_sensible};
  } else {
    my $encoded = 0;
    ($item, $encoded) = Message::Util::unquote_if_quoted_string ($item) unless $encoded;
    ($item, $encoded) = Message::Util::unquote_if_angle_quoted ($item) unless $encoded;
    $item{attribute} = $item;
    $item{charset} = '*bare' if !$encoded;
    $item{no_value} = 1;
  }
  $item{comment} = \@comment;
  \%item;
}

## $self->_decode_parameters (\@parameter, \%option)
## -- join RFC 2231 splited fragments and decode each parameter
sub _decode_parameters ($\@\%) {
  my $self = shift;
  my ($param, $option) = @_;
  my %fragment;
  my @fparameter;
  for my $parameter (@$param) {
    if ($parameter->{no_value}) {
      my %item;
      $item{no_value} = 1;
      $item{comment} = $parameter->{comment};
      if ($parameter->{charset} ne '*bare') {
        my %s = &{$self->{option}->{hook_decode_string}}
          ($self, $parameter->{attribute},
           charset	=> $option->{encoding_before_decode},
           type => 'parameter/no-value-attribute');
        if ($s{charset}) {	## Convertion failed
          $item{charset} = $s{charset};
        }
        $item{attribute} = $s{value};
      } else {
        $item{attribute} = $parameter->{attribute};
      }
      $parameter = \%item;
    } elsif ($parameter->{section_no} < 0) {
      my %item;
      $item{attribute} = $parameter->{attribute};
      $item{language} = $parameter->{language} if $parameter->{language};
      $item{comment} = $parameter->{comment};
      if ($parameter->{charset} ne '*bare') {
        my %s = &{$self->{option}->{hook_decode_string}}
          ($self, $parameter->{value},
           charset	=> $parameter->{charset} || $option->{encoding_before_decode},
           type => 'parameter/value/quoted-string');
        if ($s{charset}) {	## Convertion failed
          $item{charset} = $s{charset};
        } elsif ($parameter->{charset}) {
          $item{output_charset} = $parameter->{charset};
        }
        $item{value} = $s{value};
      } else {
        $item{value} = $parameter->{value};
      }
      $parameter = \%item;
    } else {	## fragment
      $fragment{ $parameter->{attribute} }->[ $parameter->{section_no} ]
        = $parameter->{value};
      if ($parameter->{section_no} == 0) {
        $fragment{'*property'}->{ $parameter->{attribute} }
          ->{language} = $parameter->{language};
        $fragment{'*property'}->{ $parameter->{attribute} }
          ->{charset} = $parameter->{charset};
      }
      if (ref $parameter->{comment} && @{$parameter->{comment}} > 0) {
        push @{ $fragment{'*property'}->{ $parameter->{attribute} }
          ->{comment} }, @{$parameter->{comment}};
      }
      $parameter = undef;
    }
  }
  for (keys %fragment) {
    next if $_ eq '*property';
    my %item;
    $item{attribute} = $_;
    $item{comment} = $fragment{'*property'}->{ $item{attribute} }->{comment};
    $item{language} = $fragment{'*property'}->{ $item{attribute} }->{language};
    delete $item{language} unless $item{language};
    my $charset = $fragment{'*property'}->{ $item{attribute} }->{charset};
    my %s = &{$self->{option}->{hook_decode_string}}
      ($self, join ('', @{ $fragment{ $item{attribute} } }),
       charset	=> $charset || $option->{encoding_before_decode},
       type => 'parameter/extended-value/encoded');
    if ($s{charset}) {	## Convertion failed
      $item{charset} = $s{charset};
    } elsif ($charset) {
      $item{output_charset} = $charset;
    }
    $item{value} = $s{value};
    push @fparameter, \%item;
  }
  @$param = (grep { ref $_ eq 'HASH' } @$param, @fparameter);
}

## $self->_parse_values_of_paramters (\@parameter, \%option)
## --- Parse each values of parameters
sub _parse_values_of_parameters ($\@\%) {
  my $self = shift;
  my ($param, $option) = @_;
  @$param = map {
    if (!$_->{no_value}) {
      $_->{value} = $self->_parse_value ($_->{attribute} => $_->{value});
    } else {
      $_->{value} = $self->_parse_value ('*no_value_attribute' => $_->{value});
    }
    $_;
  } @$param;
}

## $self->_save_parameters (\@parameter, \%option)
## -- Save parameters in $self
sub _save_parameters ($\@\%) {
  my $self = shift;
  my ($param, $option) = @_;
  $self->_parse_values_of_parameters ($param, $option) if $option->{parse_all};
  $self->{ $option->{_HASH_NAME} } = $param;
}
*__save_parameters = \&_save_parameters;


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

sub _add_hash_check ($$$\%) {
  my $self = shift;
  my ($name, $value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  ## -- attribute only (no value) parameter
  if ($value_option->{no_value}) {
    $name = $self->_parse_value ('*no_value_attribute' => $name) if $$option{parse};
    return (1, $name => {
      attribute => $name, no_value => 1,
      language	=> $value_option->{language},
      comment	=> $value_option->{comment},
    });
  }
  ## -- attribute=value pair
  if ($$option{validate} && $name =~ /^$REG{NON_http_attribute_char}$/) {
    if ($$option{dont_croak}) {
      return (0);
    } else {
      Carp::croak qq{add: $name: Invalid parameter name};
    }
  }
  $value = $self->_parse_value ($name => $value) if $$option{parse};
  (1, $name => {
    attribute	=> $name, value => $value,
    output_charset	=> $value_option->{charset},
    charset	=> $value_option->{current_charset},
    language	=> $value_option->{language},
    comment	=> $value_option->{comment},
  });
}

*_add_return_value = \&_replace_return_value;

## (1/0, $name => $value) = $self->_replace_hash_check ($name => $value, \%option)
## -- Checks given value and prepares saving value (hash version)
*_replace_hash_check = \&_add_hash_check;

## $value = $self->_replace_hash_shift (\%values, $name, $option)
## -- Returns a value (from %values) and deletes it from %values
##    (like CORE::shift for array).
sub _replace_hash_shift ($\%$\%) {
  shift; my $r = shift;  my $n = $_[0]->{attribute};
  if ($$r{$n}) {
    my $d = $$r{$n};
    $$r{$n} = undef;
    return $d;
  }
  undef;
}

## $value = $self->_replace_return_value (\$item, \%option)
## -- Returns returning value of replace method
sub _replace_return_value ($\$\%) {
  my $self = shift;
  my ($item, $value) = @_;
  if ($$item->{no_value}) {
    $$item->{attribute};
  } else {
    $$item->{value};
  }
}

## 1/0 = $self->_delete_match ($by, \$item, \%delete_list, \%option)
## -- Checks and returns whether given item is matched with
##    deleting item list
sub _delete_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $item, $list, $option) = @_;
  return 0 unless ref $$item;	## Already removed
  if ($by eq 'attribute' || $by eq 'name') {
    return 1 if $$list{ $$item->{attribute} };
  } elsif ($by eq 'value') {
    return 1 if $$list{ $$item->{value} };
  } elsif ($by eq 'charset') {
    return 1 if $$list{ $$item->{output_charset} } || $$list{ $$item->{charset} };
  } elsif ($by eq 'language') {
    return 1 if $$list{ $$item->{language} };
  } elsif ($by eq 'type') {
    if ($$item->{no_value}) {
      return 1 if $$list{no_value_attribute};
    } else {
      return 1 if $$list{attribute_value_pair};
    }
  }
  0;
}

## Delete empty items
sub _delete_empty ($) {
  my $self = shift;
  my $array = $self->{option}->{_HASH_NAME};
  $self->{ $array } = [grep { ref $_ } @{$self->{ $array }}] if $array;
}

=item @param = $p->parameter ($name => ($new_value), (%option))


=cut

sub parameter ($;@) {
  my $self = shift;
  if (@_ == 2) {	## $p->parameter (hoge => 'foo')
    $self->replace (@_);
  } else {	## $p->parameter ('foo')
    $self->item (@_);
  }
}

*_item_match = \&_delete_match;
*_item_return_value = \&_replace_return_value;

## $item = $self->_item_new_value ($name, \%option)
## -- Returns new item with key of $name (called when
##    no returned value is found and -new_value_unless_exist
##    option is true)
sub _item_new_value ($$\%) {
  my $self = shift;
  my ($key, $option) = @_;
  if ($option->{by} eq 'attribute' || $option->{by} eq 'name') {
    return {attribute => $key};
  }
  undef;
}

## TODO: Implement count,item_exist method

=item $field-body = $p->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $option{output_parameter_extension} = 0
    unless $option{use_parameter_extension};
  $option{output_comment} = 0 unless $option{use_comment};
  $self->_delete_empty;
  my @param;
  $self->scan( sub {shift;
    my ($item, $option) = @_;
    my $r = 1;
    ($r, $item) = $self->_stringify_param_check ($item, $option);
    return unless $r;
    my $comment = '';
    if ($option->{output_comment} && ref $item->{comment}
      && @{$item->{comment}} > 0) {
      my @c;
      for (@{$item->{comment}}) {
        push @c, '('. $self->Message::Util::encode_ccontent ($_) .')';
      }
      $comment = ' '. join ' ', @c;
    }
    if ($item->{no_value}) {
      push @param, Message::Util::quote_unsafe_string ($item->{attribute},
        unsafe => $option->{parameter_no_value_attribute_unsafe_rule}).$comment;
    } else {
      my $xparam = 0;
      my $attribute = $item->{attribute};
      return unless length $attribute;
      my $value = ''.$item->{value};
      if ($attribute =~ /$REG{ $option->{parameter_attribute_unsafe_rule} }/) {
        #return 0;
        $attribute =~ s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
      }
      my %e;
      if ($option->{output_parameter_extension}) {
        if ($item->{charset}) {
          %e = %$item;
        } else {
          %e = &{$self->{option}->{hook_encode_string}}
            ($self, $value,
             charset => $item->{output_charset} || $option->{encoding_after_encode},
             current_charset => $option->{header_default_charset}, 
             language => $item->{language},
             type => 'parameter/value');
        }
        $xparam = 1 if (length $e{value} > $option->{parameter_value_max_length})
                    || $e{charset}
                    || $e{language}
                    || $e{value} =~ /\x0D|\x0A/s
                    || $e{value} =~ /$REG{WSP}$REG{WSP}+/s
                    || ($option->{accept_coderange} eq '7bit'
                        && $e{value} =~ /[\x80-\xFF]/)
                    || ($option->{accept_coderange} ne 'binary'
                        && $e{value} =~ /\x00/)
                    ;
      } else {	## Don't use paramext
        if ($item->{charset}) {	## But parameter value is undecodable charset value
          %e = %$item;
          $xparam = 1;
        } else {
          %e = &{$self->{option}->{hook_encode_string}}
            ($self, $value,
             charset => $option->{encoding_after_encode},
             current_charset => $option->{header_default_charset}, 
             language => $item->{language},
             type => 'parameter/value');
        }
      }
      if ($xparam) {
        if (length $e{value} > $option->{parameter_value_max_length}) {
          for my $i (0..(length ($e{value})
                         /$option->{parameter_value_split_length})) {
            my $v = substr ($e{value},
              $i * $option->{parameter_value_split_length},
              $option->{parameter_value_split_length});
            if ($i == 0) {
              $v
                =~ s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
              my $charset = Message::MIME::Charset::name_minimumize
                ($e{charset} || $option->{header_default_charset}, $value);
              push @param, sprintf q{%s*0*=%s'%s'%s%s}, $attribute,
                $charset, $e{language}, $v, $comment;
            } else {	# $i > 0
              if ($e{charset} || $v =~ /\x0A|\x0D/s
               || ($option->{accept_coderange} ne 'binary' && $v =~ /\x00/)
               || ($option->{accept_coderange} eq '7bit' && $v =~ /[\x80-\xFF]/)) {
                $v =~ s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
                push @param, sprintf q{%s*%d*=%s}, $attribute, $i, $v;
              } else {
                $v = Message::Util::quote_unsafe_string ($v,
                  unsafe => $option->{parameter_value_unsafe_rule});
                $v = q{""} if length $v == 0;
                push @param, sprintf q{%s*%d=%s}, $attribute, $i, $v;
              }
            }
          }
        } else {
          $e{value}
            =~ s/($REG{NON_http_attribute_char})/sprintf('%%%02X', ord $1)/ge;
          unless ($e{charset}) {
            $e{charset} = Message::MIME::Charset::name_minimumize
              ($option->{header_default_charset}, $e{value});
          }
          push @param, sprintf q{%s*=%s'%s'%s%s}, $attribute,
            $e{charset}, $e{language}, $e{value}, $comment;
        }
      } else {
        $e{value} = Message::Util::quote_unsafe_string ($e{value},
          unsafe => $option->{parameter_value_unsafe_rule});
        $e{value} = q{""} if length $e{value} == 0;
        push @param, sprintf '%s=%s%s', $attribute, $e{value}, $comment;
      }
    }
  }, options => \%option );
  join $option{separator}, @param;
}
*as_string = \&stringify;

## $self->_stringify_param_check (\%item, \%option)
## -- Checks parameter (and modify if necessary).
##    Returns either 1 (ok) or 0 (don't output)
sub _stringify_param_check ($\%\%) {
  my $self = shift;
  my ($item, $option) = @_;
  (1, $item);
}

## scan: Inherited

## TODO: ...
sub _scan_sort ($\@) {
  #my $self = shift;
  @{$_[1]};
}

=item $option-value = $p->option ($option-name)

Gets option value.

=item $p->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  for (@{$self->{ $self->{option}->{_HASH_NAME} }}) {
    $_->{value}->option (%$o) if ref $_ && ref $_->{value};
  }
}

## value_type: Inherited

=item $clone = $p->clone ()

Returns a copy of the object.

=cut

## Inherited

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
$Date: 2002/07/06 10:30:43 $

=cut

1;
