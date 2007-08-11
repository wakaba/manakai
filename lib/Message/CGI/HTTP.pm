
=head1 NAME

SuikaWiki::Input::HTTP - SuikaWiki: HTTP or HTTP CGI input support

=head1 DESCRIPTION

This module provides HTTP or HTTP CGI input support,
although current version of this module supports HTTP CGI only.

This module is part of SuikaWiki.

=cut

package SuikaWiki::Input::HTTP;
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

=head1 METHODS

=over 4

=item $http = SuikaWiki::Input::HTTP->new

Constructs new instance of HTTP input implementation

=cut

sub new ($;%) {
  my $self = bless {
                    decoder => {
                                '#default' => sub {$_[1]},
                               },
                   }, shift;
  my %opt = @_;
  $self->{wiki} = $opt{wiki};
  $self->{-in_handle} = $opt{input_handle} || *STDIN;
  $self;
}

=item $value = $http->meta_variable ($name)

Returns variable value.  $name should be a meta-variable name
defined by CGI specification, eg. CONTENT_TYPE, HTTP_USER_AGENT and so on.

=cut

sub meta_variable ($$) {
  $main::ENV{ $_[1] };
}

=item @list = $http->meta_variable_list

Returns list of meta variables.  Note that this list might contain
other environmental variables than CGI meta variables, since
they cannot distinglish unless we know what is CGI meta variable
and what is not.  Unfortunately, there is no complete list of CGI
meta variables, whilst list of standarized meta variables is available.

Future version of this module, which implements non-CGI HTTP request,
will not return non-CGI environmental variable names in non-CGI mode.

NOTE: Some application might use an environmental variable named
'HTTP_HOME', which might make some confusion with CGI meta variable
for HTTP 'Home:' header field.  Fortunately, such name of HTTP
header field is not intoroduced as far as I know.

=cut

sub meta_variable_list ($) {
  keys %main::ENV;
}

=item $value = $http->parameter ($name)

Returns parameter value if any.
Parameter value is set by query-string of Request-URI
and/or entity-body value.

When multiple values with same parameter name is specified,
the first one is returned in scalar context or
an array reference of all values is returned in array context.
(Note that query-string is "earlier" than entity-body.)

=item @keys = $http->parameter_names

Returnes a list of parameter names provided.

=cut

sub parameter ($$) {
  my ($self, $name) = @_;
  $self->__get_parameter unless $self->{param};
  wantarray ? ( @{$self->{param}->{$name}||[]} ) :
              ${$self->{param}->{$name}||[]}[0];
}

sub parameter_names ($) {
  my $self = shift;
  $self->__get_parameter unless $self->{param};
  return keys %{$self->{param}};
}

sub __get_parameter ($) {
  my $self = shift;
  my @src;
  
  ## Query-string of Request-URI
  my $qs = $self->meta_variable ('QUERY_STRING');
  push @src, $qs if (index ($qs, '=') > -1);
  
  ## Entity-body
  if ($self->meta_variable ('REQUEST_METHOD') eq 'POST') {
    my $mt = $self->meta_variable ('CONTENT_TYPE');
    if ($mt =~ m<^application/(?:x-www|sgml)-form-urlencoded\b>) {
      push @src, $self->body_text;
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
}

=item $body = $http->body

Returns entity-body content if any.

It is expected that in future version of this module,
this method returns an object instantiated with body content
rather than body text itself.

=item $body = $http->body_text

Returnes entity-body context as a string.

=cut

sub body ($) {
  my $self = shift;
  $self->__get_entity_body unless defined $self->{body};
  $self->{body};
}

sub body_text ($) {
  $_[0]->body;
}
         
sub __get_entity_body ($) {
  my $self = shift;
  binmode $self->{-in_handle};
  read $self->{-in_handle}, $self->{body}, 
                            $self->meta_variable ('CONTENT_LENGTH');
}
## TODO: Entity too large

=item $uri = $http->request_uri

Returns Request-URI as a URI object.

Note that stringified value of returned value might not be same as the
URI specified as the Request-URI of HTTP request or (possibly pseudo-)
URI entered by the user, since no standarized way to get it is
defined by HTTP and CGI/1.1 specifications.

=cut

sub request_uri ($;%) {
  my ($self, %opt) = @_;
  require URI;
  my $uri = $opt{no_path_info} ? undef
          : $self->meta_variable ('REQUEST_URI'); # non-standard
  if ($uri) {
    $uri =~ s/\#[^#]*$//;  ## Fragment identifier not allowed here
    $uri =~ s/\?[^?]*$// if $opt{no_query};
    if ($uri =~ /^[0-9A-Za-z.%+-]+:/) {    ## REQUEST_URI is an absolute URI
      return URI->new ($uri);
    }
  } else {  ## REQUEST_URI is not provided
    my $pi = $opt{no_path_info} ? q<>
           : $self->meta_variable ('PATH_INFO');
    $uri = $self->__uri_encode ($self->meta_variable ('SCRIPT_NAME').$pi,
                                qr([^0-9A-Za-z_.!~*'();/:\@&=\$,-]));
    my $qs = $self->meta_variable ('QUERY_STRING');
    $uri .= '?' . $qs if not $opt{no_query} and defined $qs;
  }
  
  ## REQUEST_URI is a relative URI or
  ## REQUEST_URI is not provided
  my $scheme = 'http';
  my $port = ':' . $self->meta_variable ('SERVER_PORT');
  ## TODO: HTTPS=off
  if (   $self->meta_variable ('HTTPS')
      || $self->meta_variable ('CERT_SUBJECT')
      || $self->meta_variable ('SSL_VERSION')) {
    $scheme = 'https';
    $port = '' if $port eq ':443';
  } else {
    $port = '' if $port eq ':80';
  }
  
  my $host_and_port = $self->meta_variable ('HTTP_HOST');
  if ($host_and_port) {
    $uri = $scheme . '://'
         . $self->__uri_encode ($host_and_port, qr/[^0-9A-Za-z.:-]/)
         . $uri;  ## ISSUE: Should we allow "[" / "]" for IPv6 here?
  } else {
    $uri = $scheme . '://'
         . $self->__uri_encode ($self->meta_variable ('SERVER_NAME'),
                                qr/[^0-9A-Za-z.-]/)
         . $port . $uri;
  }
  return URI->new ($uri);
}


sub __uri_encode ($$;$) {
  my ($self, $s, $char) = @_;
  $char ||= qr([^0-9A-Za-z_.!~*'();/?:\@&=+\$,-]);
  require Encode;
  $s = Encode::decode ('utf8', $s);
  $s =~ s/($char)/sprintf '%%%02X', ord $1/ge;
  $s;
}

=item $http->exit

Declares that user no longer thinks the instance ($http) is interesting.
Usually, this method is automatically called.

=cut

sub exit ($) {
  my $self = shift;
  delete $self->{wiki};
  $self->{exited} = 1;
  1;
}

sub DESTORY ($) {
  my $self = shift;
  $self->exit unless $self->{exited};
}

=head1 TODO

=over 4

=item Use manakai

=item multipart/form-data support

=item HTTP (non-CGI) support

=cut

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2007/08/11 13:06:39 $
