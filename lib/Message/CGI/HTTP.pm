=head1 NAME

Message::CGI::HTTP - An Object-Oriented HTTP CGI Interface

=head1 DESCRIPTION

The C<Message::CGI::HTTP> module provides an object-oriented
interface for inputs and outputs as defined by CGI specification.

This module is part of manakai.

=cut

package Message::CGI::HTTP;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::IF::CGIRequest', 'Message::IF::HTTPCGIRequest';

=head1 METHODS

=over 4

=item I<$cgi> = Message::CGI::HTTP->new;

Creates and returns a new instance of HTTP CGI interface object.

=cut

sub new ($;%) {
  my $self = bless {
                    decoder => {
                                '#default' => sub {$_[1]},
                               },
                   }, shift;
  my %opt = @_;
  $self->{-in_handle} = *main::STDIN;
  $self;
} # new

=item I<$value> = I<$cgi>->get_meta_variable (I<$name>)

Returns the value of the meta-variable I<$name>.  The name
specified by the I<$name> SHOULD be a meta-variable name
defined by a CGI specification, e.g. C<CONTENT_TYPE> or
C<HTTP_USER_AGENT>.  Otherwise, the result is implementation
dependent.  In an environment where meta-variables are supplied
as envirnoment variables, specifying an environment variable
that is not a meta-variable, such as C<PATH>, results in the
value of that environment variable.  However, CGI scripts
SHOULD NOT depend on such behavior.

This method might return C<undef> when the meta-variable
is not defined or is defined but its value is C<undef>.

=cut

sub get_meta_variable ($$) {
  return $main::ENV{ $_[1] };
} # get_meta_variable

=item I<$list> = I<$cgi>->meta_variable_names;

Returns list of meta variables.  Note that this list might contain
other environmental variables than CGI meta variables, since
they cannot distinglish unless we know what is CGI meta variable
and what is not.  Unfortunately, there is no complete list of CGI
meta variables, whilst list of standarized meta variables is available.

NOTE: Some application might use an environmental variable named
'HTTP_HOME', which might make some confusion with CGI meta variable
for HTTP 'Home:' header field.  Fortunately, such name of HTTP
header field is not intoroduced as far as I know.

This method returns a C<Message::DOM::DOMStringList>.

=cut

sub meta_variable_names ($) {
  require Message::DOM::DOMStringList;
  bless [keys %main::ENV], 'Message::DOM::DOMStringList::StaticList';
} # meta_variable_names

=item I<$value> = C<$cgi>->get_parameter ($name);

Returns parameter value if any.
Parameter value is set by query-string of Request-URI
and/or entity-body value.

When multiple values with same parameter name is specified,
the first one is returned in scalar context or
an array reference of all values is returned in array context.
(Note that query-string is "earlier" than entity-body.)

=cut

sub get_parameter ($$) {
  my ($self, $name) = @_;
  $self->__get_parameter unless $self->{param};

  if (wantarray) {
    return @{$self->{param}->{$name}||[]};
  } else {
    return ${$self->{param}->{$name}||[]}[0];
  }
} # get_parameter

=item I<$keys> = I<$cgi>->parameter_names;

Returnes a list of parameter names provided.

This method returns a C<Message::DOM::DOMStringList>.

=cut

sub parameter_names ($) {
  my $self = shift;
  $self->__get_parameter unless $self->{param};
  
  require Message::DOM::DOMStringList;
  return bless [keys %{$self->{param}}],
      'Message::DOM::DOMStringList::StaticList';
} # parameter_names

sub __get_parameter ($) {
  my $self = shift;
  my @src;
  
  ## Query-string of Request-URI
  my $qs = $self->get_meta_variable ('QUERY_STRING');
  push @src, $qs if (index ($qs, '=') > -1);
  
  ## Entity-body
  if ($self->get_meta_variable ('REQUEST_METHOD') eq 'POST') {
    my $mt = $self->get_meta_variable ('CONTENT_TYPE');
    if ($mt =~ m<^application/(?:x-www|sgml)-form-urlencoded\b>) {
      push @src, $self->entity_body;
    }
    ## TODO: support non-standard "charset" parameter
  }
  
  my %temp_params;
  for my $src (@src) {
    for (split /[;&]/, $src) {
      my ($name, $val) = split '=', $_, 2;
      for ($name, $val) {
        tr/+/ /;
        s/%([0-9A-Fa-f][0-9A-Fa-f])/pack 'C', hex $1/ge;
      }
      $temp_params{$name} ||= [];
      push @{$temp_params{$name}}, $val;
    }
  }
  for (keys %temp_params) {
    my $name = &{$self->{decoder}->{'#name'}
               ||$self->{decoder}->{'#default'}} ($self, $_, \%temp_params);
    for (@{$temp_params{$name}}) {
      push @{$self->{param}->{$name}}, 
           &{$self->{decoder}->{$name}
           ||$self->{decoder}->{'#default'}} ($self, $_, \%temp_params);
    }
  }
} # __get_parameter

=item I<$body> = I<$cgi>->entity_body;

Returns entity-body content if any.

=cut

sub entity_body ($) {
  my $self = shift;
  $self->__get_entity_body unless defined $self->{body};

  return $self->{body};
} # entity_body
         
sub __get_entity_body ($) {
  my $self = shift;
  binmode $self->{-in_handle};
  read $self->{-in_handle}, $self->{body}, 
                            $self->get_meta_variable ('CONTENT_LENGTH');
} # __get_entity_body
## TODO: Entity too large

=item I<$uri> = I<$cgi>->request_uri;

Returns Request-URI as a C<Message::URI::URIReference> object.

Note that stringified value of returned value might not be same as the
URI specified as the Request-URI of HTTP request or (possibly pseudo-)
URI entered by the user, since no standarized way to get it is
defined by HTTP and CGI/1.1 specifications.

=cut

sub request_uri ($;%) {
  my ($self, %opt) = @_;
  require Message::URI::URIReference;
  my $uri = $opt{no_path_info} ? undef
          : $self->get_meta_variable ('REQUEST_URI'); # non-standard
  if ($uri) {
    $uri =~ s/\#[^#]*$//;  ## Fragment identifier not allowed here
    $uri =~ s/\?[^?]*$// if $opt{no_query};
    if ($uri =~ /^[0-9A-Za-z.%+-]+:/) {    ## REQUEST_URI is an absolute URI
      return Message::DOM::DOMImplementation->create_uri_reference ($uri);
    }
  } else {  ## REQUEST_URI is not provided
    my $pi = $opt{no_path_info} ? q<>
           : $self->get_meta_variable ('PATH_INFO');
    $uri = $self->__uri_encode ($self->get_meta_variable ('SCRIPT_NAME').$pi,
                                qr([^0-9A-Za-z_.!~*'();/:\@&=\$,-]));
    my $qs = $self->get_meta_variable ('QUERY_STRING');
    $uri .= '?' . $qs if not $opt{no_query} and defined $qs;
  }
  
  ## REQUEST_URI is a relative URI or
  ## REQUEST_URI is not provided
  my $scheme = 'http';
  my $port = ':' . $self->get_meta_variable ('SERVER_PORT');
  ## TODO: HTTPS=off
  if (   $self->get_meta_variable ('HTTPS')
      || $self->get_meta_variable ('CERT_SUBJECT')
      || $self->get_meta_variable ('SSL_VERSION')) {
    $scheme = 'https';
    $port = '' if $port eq ':443';
  } else {
    $port = '' if $port eq ':80';
  }
  
  my $host_and_port = $self->get_meta_variable ('HTTP_HOST');
  if ($host_and_port) {
    $uri = $scheme . '://'
         . $self->__uri_encode ($host_and_port, qr/[^0-9A-Za-z.:-]/)
         . $uri;  ## ISSUE: Should we allow "[" / "]" for IPv6 here?
  } else {
    $uri = $scheme . '://'
         . $self->__uri_encode ($self->get_meta_variable ('SERVER_NAME'),
                                qr/[^0-9A-Za-z.-]/)
         . $port . $uri;
  }
  return Message::DOM::DOMImplementation->create_uri_reference ($uri);
} # request_uri

sub __uri_encode ($$;$) {
  my ($self, $s, $char) = @_;
  $char ||= qr([^0-9A-Za-z_.!~*'();/?:\@&=+\$,-]);
  require Encode;
  $s = Encode::decode ('utf8', $s);
  $s =~ s/($char)/sprintf '%%%02X', ord $1/ge;
  return $s;
} # __uri_encode

=item I<$value> = I<$cgi>->path_info ([I<$new_value>]);

This method reflects the meta-variable with the same name (in uppercase).

=cut

for (
  [path_info => 'PATH_INFO'],
  [query_string => 'QUERY_STRING'],
  [request_method => 'REQUEST_METHOD'],
  [script_name => 'SCRIPT_NAME'],
) {
  eval qq{
    sub $_->[0] (\$;\$) {
      if (\@_ > 1) {
        if (defined \$_[1]) {
          \$main::ENV{'$_->[1]'} = ''.\$_[1];
        } else {
          delete \$main::ENV{'$_->[1]'};
        }
      }
      return \$main::ENV{'$_->[1]'};
    }
  };
}

package Message::IF::CGIRequest;
package Message::IF::HTTPCGIRequest;

=back

=head1 TODO

=over 4

=item multipart/form-data support

=back

=head1 SEE ALSO

A draft specification for DOM CGI Module
<http://suika.fam.cx/gate/2005/sw/manakai/%E3%83%A1%E3%83%A2/2005-07-04>
(This module does not implement the interface defined in this
specification, however.)

=head1 AUTHOR

Wakaba <w@suika.fam.cx>

This module was originally developed as part of SuikaWiki.

=head1 LICENSE

Copyright 2003, 2007 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
# $Date: 2007/08/22 10:59:43 $
