
=head1 NAME

Message::Field::ContentType --- Perl module for
Internet message C<Content-Type:> field body

=cut

package Message::Field::ContentType;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.11 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::ValueParams;
push @ISA, qw(Message::Field::ValueParams);
require Message::MIME::MediaType;

%REG = %Message::Field::Params::REG;
## Inherited: comment, quoted_string, domain_literal, angle_quoted
	## WSP, FWS, atext, atext_dot, token, attribute_char
	## S_encoded_word
	## M_quoted_string
	## param, parameter
	## M_parameter, M_parameter_name, M_parameter_extended_value

%DEFAULT = (
	#_HASH_NAME
	#_MEMBERS
	#_METHODS
	#accept_coderange
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
	-media_type_default	=> 'text',
	-media_subtype_default	=> 'plain',
	#output_comment
	-output_parameter_extension	=> 1,
	#parameter_rule
	#parameter_attribute_case_sensible
	#parameter_attribute_unsafe_rule
	#parameter_av_Mrule
	#parameter_no_value_attribute_unsafe_rule
	#parameter_value_max_length
	#parameter_value_split_length
	#parameter_value_unsafe_rule
	#parse_all
    -rfc1049_vs_mime =>
    	{postscript	=> 'application/postscript',
    	scribe	=> 'application/x-scribe',
    	sgml	=> 'application/sgml',	## text/sgml
    	troff	=> 'application/x-troff',
    	dvi	=> 'application/x-dvi',
    	text	=> 'text/plain',
    },
	#separator
	#separator_rule
	#use_comment
	-use_mime_text_alternate	=> 1,
	#use_parameter_extension
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
  push @{$self->{option}->{_MEMBERS}}, qw/media_type media_subtype not_mime_text/;
  $self->SUPER::_init (%DEFAULT, %options);
  
  if ($self->{option}->{format} =~ /http/) {
    $self->{option}->{use_mime_text_alternate} = 0;
    $self->{option}->{output_parameter_extension} = 0;
  }
  $self->{media_type} = $self->{option}->{media_type_default};
  $self->{media_subtype} = $self->{option}->{media_subtype_default};
}

=item $ct = Message::Field::ContentType->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $ct = Message::Field::ContentType->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## Inherited

## $self->_save_parameters (\@parameter, \%option)
## -- Save parameters in $self
sub _save_parameters ($\@\%) {
  my $self = shift;
  my ($param, $option) = @_;
  if ($param->[0]->{no_value}) {
    my $type = shift (@$param)->{attribute};
    if ($type =~ m#^application$REG{FWS}/$REG{FWS}x-(text|message)#) {
      my $mt = $1;
      for (@$param) {
        if ($_->{attribute} eq 'media-subtype') {
          $self->{media_type} = $mt;
          $self->{media_subtype} = $_->{value};
          $self->{not_mime_text} = 1;
          undef $_; last;
        }
      }
    } elsif ($type =~ m#^($REG{token})$REG{FWS}/$REG{FWS}($REG{token})$#) {
      $self->{media_type} = lc $1;
      $self->{media_subtype} = lc $2;
    } elsif ($self->{option}->{rfc1049_vs_mime}->{ lc $type }
      =~ m#^($REG{token})/($REG{token})$#) {
      ($self->{media_type}, $self->{media_subtype}) = ($1, $2);
      push @$param, {attribute => 'x-rfc1049-type', value => $type};
      if ($param->[0]->{no_value}) {
        push @$param, {attribute => 'x-rfc1049-ver-num',
                       value => shift (@$param)->{attribute}};
        if ($param->[0]->{no_value}) {
          push @$param, {attribute => 'x-rfc1049-resource-ref',
                    value => shift (@$param)->{attribute}};
        }
      }
    } else {
      push @$param, {attribute => 'x-invalid-media-type', value => $type};
      $self->{media_type} = 'application';
      $self->{media_subtype} = 'octet-stream';
    }
  } else {
    $self->{media_type} = 'application';
    $self->{media_subtype} = 'octet-stream';
  }
  $self->SUPER::_save_parameters ($param, $option);
}

=back

=head1 METHODS

=over 4

=item $ct->replace ($name => [$value], [$name => $value,...])

Sets new parameter C<value> of $name.

  Example:
    $self->add (title => 'foo of bar');	## title="foo of bar"
    $self->add (subject => 'hogehoge, foo');	## subject*=''hogehoge%2C%20foo
    $self->add (foo => 'bar', language => 'en')	## foo*='en'bar

This method returns array reference of (name, {value => value, attribute...}).

Available options: charset (charset name), language (language tag),
value (1/0, see example above).

=item $count = $ct->count ()

Returns the number of C<parameter>s.

=item $param-value = $ct->parameter ($name, [$new_value])

Returns given C<name>'ed C<parameter>'s C<value>.

=item $param-name = $ct->parameter_name ($index, [$new_name])

Returns (and set) C<$index>'th C<parameter>'s name.

=item $param-value = $ct->parameter_value ($index, [$new_value])

Returns (and set) C<$index>'th C<parameter>'s value.

=cut

## replace, add, count, parameter, parameter_name, parameter_value: Inherited.
## (add should not be used for CT: field)

=item $field-body = $ct->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify_value ($) {
  my $self = shift;
  my $media_type = $self->media_type;
  ## See also Message::Entity::_encode_body
  if ($self->{option}->{use_mime_text_alternate}
   && $self->{not_mime_text}) {
    if ($media_type =~ m#^text/($REG{token})#) {
      my $st = $1;
      my $at = $Message::MIME::MediaType::type{text}->{$st}->{mime_alternate};
      return sprintf ('%s/%s', @$at) if ref $at eq 'ARRAY';
      return 'application/x-text; media-subtype='.$st;
    } elsif ($media_type =~ m#^message/($REG{token})#) {
      my $st = $1;
      my $at = $Message::MIME::MediaType::type{message}->{$st}->{mime_alternate};
      return sprintf ('%s/%s', @$at) if ref $at eq 'ARRAY';
      #return 'application/x-message; media-subtype='.$st;
    }
  }
  $media_type;
}

## $self->_stringify_param_check (\%item, \%option)
sub _stringify_param_check ($\%\%) {
  my $self = shift;
  my ($item, $option) = @_;
  return (0) if $item->{attribute} =~ /^\*/;	## Internal use
  (1, $item);
}

=head2 $self->media_type ([$new_value])

Returns or set Internet media type.

=head2 $self->media_type_major ([$new_value])

Returns or set left part of Internet media type.

=head2 $self->media_type_minor ([$new_value])

Returns or set right part of Internet media type.

=cut

sub media_type ($;$) {
  my $self = shift;
  my $new_value = shift || '';
  if ($new_value =~ m#^($REG{token})/($REG{token})$#) {
    $self->{media_type} = $1;
    $self->{media_subtype} = $2;
  }
  $self->{media_type}.'/'.$self->{media_subtype};
}

sub media_type_major ($;$) {
  my $self = shift;
  my $new_value = shift;
  if ($new_value && $new_value !~ m#$REG{NON_http_token}#) {
    $self->{media_type} = $new_value;
  }
  $self->{media_type};
}

sub media_type_minor ($;$) {
  my $self = shift;
  my $new_value = shift;
  if ($new_value && $new_value !~ m#$REG{NON_http_token}#) {
    $self->{media_subtype} = $new_value;
  }
  $self->{media_subtype};
}
*media_subtype = \&media_type_minor;
*value = \&media_type;

sub not_mime_text ($;$) {
  my $self = shift;
  my $new_value = shift;
  if (defined $new_value) {
    $self->{not_mime_text} = $new_value;
  }
  $self->{not_mime_text};
}

=item $option-value = $ct->option ($option-name)

Gets option value.

=item $ct->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited.

=item $clone = $ua->clone ()

Returns a copy of the object.

=cut

## Inherited

## $self->_parse_value ($type, $value);
sub _parse_value ($$$) {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  return $value if ref $value;
  my ($mt,$mst) = ($self->{media_type}, $self->{media_subtype});
  my $mt_def = $Message::MIME::MediaType::type{$mt}->{$mst};
  $mt_def = $Message::MIME::MediaType::type{$mt}->{'/default'} unless ref $mt_def;
  $mt_def = $Message::MIME::MediaType::type{'/default'}->{'/default'}
    unless ref $mt_def;
  my $handler = $mt_def->{parameter}->{$name}->{handler}
    || $mt_def->{parameter}->{'*default'}->{handler} || [':none:'];
  if (ref $handler eq 'CODE') {
    $handler = &$handler ($self, $mt, $mst);
  }
  my $vtype = $handler->[0];
  my %vopt = (
    -format	=> $self->{option}->{format},
    -field_name	=> $self->{option}->{field_name},
    -field_media_type	=> $mt,
    -field_media_subtype	=> $mst,
    -field_param_name	=> $name,
    -internal_charset_name	=> $self->{option}->{internal_charset_name},
    -parse_all	=> $self->{option}->{parse_all},
  );
  ## Media type specified option/parameters
  if (ref $handler->[1] eq 'HASH') {
    for (keys %{$handler->[1]}) {
      $vopt{$_} = ${$handler->[1]}{$_};
    }
  }
  ## Inherited options
  if (ref $handler->[2] eq 'ARRAY') {
    for (@{$handler->[2]}) {
      $vopt{'-'.$_} = $self->{option}->{$_};
    }
  }
  
  if ($vtype eq ':none:') {
    return $value;
  } elsif (defined $value) {
    eval "require $vtype" or Carp::croak qq{<parse>: $vtype: Can't load package: $@};
    return $vtype->parse ($value, %vopt);
  } else {
    eval "require $vtype" or Carp::croak qq{<parse>: $vtype: Can't load package: $@};
    return $vtype->new (%vopt);
  }
}

=head1 STANDARDS

This module supports historical syntax (RFC 1049; parse only), 
MIME (RFC 1341, RFC 1521 and RFC 2045, ammended by RFC 2184, RFC 2231),
USENET article format (son-of-RFC1036, draft-usefor-article-05),
HTTP (HTTP/1.0, HTTP/1.1) and CGI (CGI/1.1, draft CGI/1.2).

On C<Content-Type:> header field of non-MIME specifications
(and that of MIME before RFC 2184), extended parameter
syntax (character set and language specification, encoded
parameter value and continuation) is not allowed.
To use such environment, specify use_extended_parameter = 0.
(Even this value is 0, decode of those parameter values
is still enabled.)

  ## Examples
  my $ct = new Message::Field::ContentType (-use_extended_parameter => 0);
  ## or
  my $ct = new Message::Field::ContentType;
  $ct->option (-use_extended_parameter => 0);

=head1 EXAMPLE

  use Message::Field::ContentType;
  my $ct = new Message::Field::ContentType;
  $ct->media_type ('text/html');
  $ct->parameter ('charset' => 'iso-2022-jp');
  print $ct;	## text/html; charset=iso-2022-jp

  use Message::Field::ContentType;
  my $ct = new Message::Field::ContentType;
  $ct->media_type_major ('message');
  $ct->media_type_minor ('external-body');
  $ct->parameter ('access-type' => 'URL');
  $ct->parameter (url => 'ftp://ftp.bar.foo.example.org/'.
    'pub/a/very/very/very/long/long/uri/of/an/external-object.gz');
  $ct->option (-parameter_value_max => 30);
  print $ct;
  	## message/external-body; access-type=URL; 
  	## url*0="ftp://ftp.bar.foo.example.org/"; 
  	## url*1="pub/a/very/very/very/long/long"; 
  	## url*2="/uri/of/an/external-object.gz"

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
$Date: 2002/07/21 03:25:00 $

=cut

1;
