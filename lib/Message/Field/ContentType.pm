
=head1 NAME

Message::Field::ContentType Perl module

=head1 DESCRIPTION

Perl module for C<Content-Type:> field body.

=cut

package Message::Field::ContentType;
use strict;
BEGIN {
  no strict;
  use base Message::Field::Params;
  use vars qw(%DEFAULT %REG $VERSION);
}
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

%REG = %Message::Field::Params::REG;

%DEFAULT = (
  rfc1049_vs_mime => {postscript	=> 'application/postscript',
                      scribe	=> 'application/x-scribe',
                      sgml	=> 'application/sgml',	## text/sgml
                      troff	=> 'application/x-troff',
                      dvi	=> 'application/x-dvi',
                      text	=> 'text/plain',
                     },
  use_parameter_extension	=> 1,
);

=head2 Message::Field::ContentType->new ([%option])

Returns new Message::Field::ContentType.  Some options can be given as hash.

=cut

## Inherited

## Initialization for new () method.
sub _initialize_new ($;%) {
  my $self = shift;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self->{media_type} = 'text';
  $self->{media_subtype} = 'plain';
}

## Initialization for parse () method.
sub _initialize_parse ($;%) {
  my $self = shift;
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
}

=head2 Message::Field::ContentType->parse ($nantara, [%option])

Parse Message::Field::ContentType and new ContentType instance.  
Some options can be given as hash.

=cut

## Inherited

sub _save_param ($@) {
  my $self = shift;
  my @p = @_;
  my $media_type = 'text/plain';
  if ($p[0]->[1]->{is_parameter} == 0) {
    $media_type = shift (@p)->[0];
    if ($media_type =~ m#^($REG{token})/($REG{token})$#) {
      $self->{media_type} = $1;
      $self->{media_subtype} = $2;
    } elsif ($self->{option}->{rfc1049_vs_mime}->{lc $media_type}) {
      ($self->{media_type},$self->{media_subtype}) = ($1,$2)
        if $self->{option}->{rfc1049_vs_mime}->{lc $media_type}
           =~ m#^($REG{token})/($REG{token})$#;
      push @p, ['x-rfc1049-type', {value => $media_type,
        is_parameter => 1}] if $media_type;
      push @p, ['x-rfc1049-ver-num', {value => shift (@p)->[0],
        is_parameter => 1}] if $p[0]->[1]->{is_parameter} == 0;
      push @p, ['x-rfc1049-resource-ref', {value => shift (@p)->[0],
        is_parameter => 1}] if $p[0]->[1]->{is_parameter} == 0;
    } else {
      push @p, ['x-unparsable-media-type', {value => $media_type,
        is_parameter => 1}] if $media_type;
      $self->{media_type} = 'application';
      $self->{media_subtype} = 'octet-stream';
    }
  }
  $self->{param} = \@p;
  $self;
}

=head2 $self->replace ($name, $value, [%option]

Sets new parameter C<value> of $name.

  Example:
    $self->add (title => 'foo of bar');	## title="foo of bar"
    $self->add (subject => 'hogehoge, foo');	## subject*=''hogehoge%2C%20foo
    $self->add (foo => 'bar', language => 'en')	## foo*='en'bar

This method returns array reference of (name, {value => value, attribute...}).

Available options: charset (charset name), language (language tag),
value (1/0, see example above).

=head2 $self->add ($name, $value)

Adds new parameter name=value pair.  Even if C<$name> parameter
is already exist, new C<parameter> is inserted.  This method
should not be used.

=head2 $self->count ()

Returns the number of C<parameter>.

=head2 $self->parameter ($name, [$new_value])

Returns given C<name>'ed C<parameter>'s C<value>.

=head2 $self->parameter_name ($index, [$new_name])

Returns (and set) C<$index>'th C<parameter>'s name.

=head2 $self->parameter_value ($index, [$new_value])

Returns (and set) C<$index>'th C<parameter>'s value.

=cut

## replace, add, count, parameter, parameter_name, parameter_value: Inherited.

=head2 $self->stringify ([%option])

Returns Content-Type C<field-body> as a string.

=head2 $self->as_string ([%option])

An alias of C<stringify>.

=cut

sub stringify ($;%) {
  my $self = shift;
  my $param = $self->SUPER::stringify (@_);
  $self->media_type ().($param? '; '.$param: '');
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
  my $new_value = shift;
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
sub media_subtype ($;$) {shift->media_type_minor (@_)}
sub value ($;$) {shift->media_type}

=head2 $self->option ($option_name)

Returns/set (new) value of the option.

=cut

## Inherited.

=head1 STANDARDS

This module supports historical syntax (RFC 1049; parse only), 
MIME (RFC 1341, RFC 1521 and RFC 2045, ammended by RFC 2184, RFC 2231),
USENET article format (son-of-RFC1036, draft-usefor-article-05),
HTTP (HTTP/1.0, HTTP/1.1) and CGI (CGI/1.1, draft CGI/1.2).

On C<Content-Type:> header field of non-MIME specifications
(and that of MIME before RFC 2184), extended parameter
syntax (character set and language specification, encoded
parameter value and continuation) is not allowed.
To use such environment, specify use_extended_parameter = -1.
(Even this value is -1, decode of those parameter values
is still enabled.)

  ## Examples
  my $ct = new Message::Field::ContentType (use_extended_parameter => -1);
  ## or
  my $ct = new Message::Field::ContentType;
  $ct->option (use_extended_parameter => -1);

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
  $ct->option (parameter_value_max => 30);
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
$Date: 2002/04/05 14:55:28 $

=cut

1;
