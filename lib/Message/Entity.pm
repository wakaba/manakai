
=head1 NAME

Message::Entity Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<message>.
MIME multipart will be also supported (but not implemented yet).

=cut

package Message::Entity;
use strict;
use vars qw(%DEFAULT $VERSION);
$VERSION=do{my @r=(q$Revision: 1.15 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Util;
require Message::Header;
require Message::MIME::MediaType;
require Message::MIME::Encoding;
use overload '""' => sub { $_[0]->stringify },
             fallback => 1;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_METHODS	=> [qw|header body content_type id|],
    -_MEMBERS	=> [qw|header body|],
    -accept_coderange	=> '7bit',	## 7bit / 8bit / binary
    -add_ua	=> 1,
    -body_default_charset	=> 'iso-2022-int-1',
    -body_default_media_type	=> 'text/plain',
    #fill_date	=> 1,
    -fill_date_name	=> 'date',
    #fill_msgid	=> 1,
    -fill_msgid_name	=> 'message-id',
    -format	=> 'mail-rfc2822',
    -linebreak_strict	=> 0,	## BUG: not work perfectly
    -parse_all	=> 0,
    #ua_field_name	=> 'user-agent',
    -ua_use_config	=> 1,
    -uri_mailto_safe_level	=> 4,
    -value_type	=> {
    	'*default'	=> ['Message::Body::TextPlain'],
    	'text/*'	=> ['Message::Body::TextPlain'],
    	#'*/*+xml'	=> ['Message::Body::TextPlain'],
    },
  );
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = {};
  my $o = Message::Util::make_clone (\%DEFAULT);
  for my $name (keys %$o) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $$o{$name};
    }
  }
  
  my @new_fields = ();
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } else {
      push @new_fields, (lc $name => $options{$name});
    }
  }
  my $format = $self->{option}->{format};
  if ($format =~ /http/) {
    $self->{option}->{fill_date_ns}       = $Message::Header::NS_phname2uri{http};
    $self->{option}->{fill_msgid_from_ns} = $Message::Header::NS_phname2uri{http};
    $self->{option}->{fill_ua_ns}         = $Message::Header::NS_phname2uri{http};
    $self->{option}->{accept_coderange} = 'binary';
  } else {
    $self->{option}->{fill_date_ns}       = $Message::Header::NS_phname2uri{rfc822};
    $self->{option}->{fill_msgid_from_ns} = $Message::Header::NS_phname2uri{rfc822};
    $self->{option}->{fill_ua_ns}         = $Message::Header::NS_phname2uri{rfc822};
    if ($format =~ /news-usefor|smtp-8bitmime/) {
      $self->{option}->{accept_coderange} = '8bit';
    } else {
      $self->{option}->{accept_coderange} = '7bit';
    }
  }
  $self->{option}->{fill_msgid_ns}   = $Message::Header::NS_phname2uri{rfc822};
  $self->{option}->{fill_mimever_ns} = $Message::Header::NS_phname2uri{rfc822};
  unless (defined $self->{option}->{fill_date}) {
    $self->{option}->{fill_date} = $format !~ /cgi|uri-url-mailto/;
  }
  unless (defined $self->{option}->{fill_msgid}) {
    $self->{option}->{fill_msgid} = $format !~ /http|uri-url-mailto/;
  }
  unless (defined $self->{option}->{fill_ct}) {
    $self->{option}->{fill_ct} = $format !~ /http/;
  }
  unless (defined $self->{option}->{fill_mimever}) {
    $self->{option}->{fill_mimever} = $format !~ /http/;
  }
  unless (length $self->{option}->{fill_ua_name}) {
    $self->{option}->{fill_ua_name} = $format =~ /response|cgi|uri-url-mailto/?
      'server': 'user-agent';
  }
  @new_fields;
}

=head1 CONSTRUCTORS

The following methods construct new C<Message::Entity> objects:

=over 4

=item Message::Entity->new ([%initial-fields/options])

Constructs a new C<Message::Entity> object.  You might pass some initial
C<field-name>-C<field-body> pairs and/or options as parameters to the constructor.

Example:

 $msg = new Message::Entity
        Date         => 'Thu, 03 Feb 1994 00:00:00 +0000',
        Content_Type => 'text/html',
        X_URI => '<http://www.foo.example/>',
        -format => 'mail-rfc2822'	## not to be header field
        ;

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my %new_field = $self->_init (@_);
  if (length $new_field{body}) {
    $self->{body} = $new_field{body};  $new_field{body} = undef;
    $self->{body} = $self->_parse_value ($self->content_type, $self->{body})
      if $self->{option}->{parse_all};
  }
  $self->{header} = new Message::Header
    -format => $self->{option}->{format},
    -parse_all => $self->{option}->{parse_all}, %new_field;
  $self;
}

=item Message::Entity->parse ($message, [%options])

Parses given C<message> (a message entity) and constructs a new C<Message::Entity>
object.  You might pass some additional C<field-name>-C<field-body> pairs 
or/and initial options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $message = shift;
  my $self = bless {}, $class;
  my %new_field = $self->_init (@_);
  my @header = ();	## BUG: This doesn't see linebreak_strict
  my @body = split /\x0D?\x0A/, $message;	## BUG: not binary-safe
  while (1) {
    my $line = shift @body;
    unless (length($line)) {
      last;
    } else {
      push @header, $line;
    }
  }
  $new_field{body} = undef if $new_field{body};
  $self->{header} = parse_array Message::Header \@header,
    -parse_all => $self->{option}->{parse_all},
    -format => $self->{option}->{format}, %new_field;
  $self->{body} = join "\x0D\x0A", @body;	## BUG: binary-unsafe
  $self->{body} = $self->_parse_value (scalar $self->content_type => $self->{body})
    if $self->{option}->{parse_all};
  $self;
}

=back

=head1 METHODS

=head2 $self->header ([$new_header])

Returns Message::Header unless $new_header.
Set $new_header instead of current C<header>.
If !ref $new_header, Message::Header->parse is automatically
called.

=cut

## TODO: to be compatible with HTTP::Message
sub header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  } elsif ($new_header) {
    $self->{header} = Message::Header->parse ($new_header,
      -parse_all => $self->{option}->{parse_all},
      -format => $self->{option}->{format});
  }
  unless (ref $self->{header} || length $self->{header}) {
    $self->{header} = new Message::Header (
      -parse_all => $self->{option}->{parse_all},
      -format => $self->{option}->{format});
  }
  $self->{header};
}

=head2 $self->body ([$new_body])

Returns C<body> as string unless $new_body.
Set $new_body instead of current C<body>.

=cut

sub body ($;$) {
  my $self = shift;
  my $new_body = shift;
  if ($new_body) {
    $self->{body} = $new_body;
  }
  $self->{body} = $self->_parse_value ($self->content_type => $self->{body})
    unless ref $self->{body};
  $self->{body};
}

## $self->_parse_value ($type, $value);
sub _parse_value ($$$) {
  my $self = shift;
  my $name = shift || '*default';
  my $value = shift;
  return $value if ref $value;
  
  ## decode
  $value = $self->_decode_body ($value);
  
  my $vtype = $self->{option}->{value_type}->{$name}->[0]
      || $self->{option}->{value_type}->{'*default'}->[0];
  my %vopt; %vopt = %{$self->{option}->{value_type}->{$name}->[1]} 
    if ref $self->{option}->{value_type}->{$name}->[1];
  if ($vtype eq ':none:') {
    return $value;
  } elsif (defined $value) {
    eval "require $vtype" or Carp::croak qq{<parse>: $vtype: Can't load package: $@};
    return $vtype->parse ($value,
      -format	=> $self->{option}->{format},
      -parent_type	=> $name,
      -parse_all	=> $self->{option}->{parse_all},
    %vopt);
  } else {
    eval "require $vtype" or Carp::croak qq{<parse>: $vtype: Can't load package: $@};
    return $vtype->new (
      -format	=> $self->{option}->{format},
      -parent_type	=> $name,
      -parse_all	=> $self->{option}->{parse_all},
    %vopt);
  }
}

sub _decode_body ($$) {
  my $self = shift;
  my $value = shift;
  ## MIME CTE
  	my $cte = $self->{_cte};
  	my $ctef = $self->header->field ('content-transfer-encoding',
  	                              -new_item_unless_exist => 0);
  	$cte = $ctef->value if ref $ctef;
  	my $f = $Message::MIME::Encoding::DECODER{$cte};
  	if (ref $f) {
  	  ($value, $cte) = &$f ($self, $value);
  	}
  	$self->{_cte} = $cte;
  $value;
}

sub _encode_body ($$\%) {
  my $self = shift;
  my $value = shift;
  my $option = shift;
  ## MIME CTE
  	my $current_cte = $self->{_cte};
  	my $ctef = $self->header->field ('content-transfer-encoding',
  	                              -new_item_unless_exist => 0);
  	my $cte = ''; $cte = lc $ctef->value if ref $ctef;
  	## Get media type of entity body and its accept CTE list
  	  my ($mt,$mst) = $self->content_type;
  	  my $mt_def = $Message::MIME::MediaType::type{$mt}->{$mst};
  	  $mt_def = $Message::MIME::MediaType::type{$mt}->{'/default'}
  	    ;#unless ref $mt_def;
  	  $mt_def = $Message::MIME::MediaType::type{'/default'}->{'/default'}
  	    unless ref $mt_def;
  	## If accept CTE list is defined,
  	if (ref $mt_def->{accept_cte} eq 'ARRAY') {
  	  my $f = 1; for (@{$mt_def->{accept_cte}}) {
  	    if ($cte eq $_) {$f = 0; last}
  	  }
  	  if ($f) {	## If CTE is not accepted,
  	    $cte = $mt_def->{accept_cte}->[0];
  	  }
  	}
  	if ($current_cte eq 'binary' || ($current_cte && $current_cte ne $cte)) {
  	  my $de = $Message::MIME::Encoding::DECODER{$current_cte};
  	  my $en = $Message::MIME::Encoding::ENCODER{$cte || 'binary'};
  	  if (ref $de && ref $en) {
  	    my ($e, $decoded);
  	    ($decoded, $e) = &$de ($self, $value);
  	    ## Check transparent coderange
  	      my $cr = $self->Message::MIME::Encoding::decide_coderange ($decoded);
  	      if ($option->{accept_coderange} eq '8bit') {
  	        if ($cr eq 'binary') {
  	          $cte = $mt_def->{cte_7bit_preferred} || 'base64';
  	          $en = $Message::MIME::Encoding::ENCODER{$cte};
  	        }
  	      } elsif ($option->{accept_coderange} eq '7bit') {
  	        if ($cr eq 'binary' || $cr eq '8bit') {
  	          $cte = $mt_def->{cte_7bit_preferred} || 'base64';
  	          $en = $Message::MIME::Encoding::ENCODER{$cte};
  	        }
  	      }
  	    if ($e eq 'binary') {
  	      ($value, $e) = &$en ($self, $decoded);
  	        $ctef = $self->header->field ('content-transfer-encoding')
  	           unless ref $ctef;
  	        $ctef->value ($e);
  	    } else {
  	      $ctef = $self->header->field ('content-transfer-encoding')
  	         unless ref $ctef;
  	      $ctef->value ($current_cte);
  	    }
  	  } else {	## Can't encode by given CTE
  	    $ctef = $self->header->field ('content-transfer-encoding')
  	       unless ref $ctef;
  	    $ctef->value ($current_cte);
  	  }
  	}
  $value;
}

=head2 $self->stringify ([%option])

Returns the C<message> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my ($header, $body);
  if (ref $self->{body}) {
    $body = $self->{body}->stringify (-format => $option{format},
      -linebreak_strict => $option{linebreak_strict});
  } else {
    $body = $self->{body};
  }
  $body = $self->_encode_body ($body, \%option);
  if (ref $self->{header}) {
    my %exist;
    for ($self->{header}->field_name_list) {$exist{$_} = 1}
    my $ns_content = $Message::Header::NS_phname2uri{content};
    if ($option{fill_date}
       && !$exist{$option{fill_date_name}.':'.$option{fill_date_ns}}) {
      #die  $option{fill_date_ns};
      $self->{header}->field
        ($option{fill_date_name}, -ns => $option{fill_date_ns})->unix_time (time);
    }
    if ($option{fill_msgid}
       && !$exist{$option{fill_msgid_name}.':'.$option{fill_msgid_ns}}) {
      my $from = $self->{header}->field
        ('from', -ns => $option{fill_msgid_from_ns}, -new_item_unless_exist => 0);
      $from = $from->addr_spec if ref $from;
      $self->{header}->field
        ($option{fill_msgid_name}, -ns => $option{fill_msgid_ns})
        ->generate (addr_spec => $from)
        if $from;
    }	# fill_msgid
    my $ismime = 0;
    for (keys %exist) {if (/:$ns_content$/) { $ismime = 1; last }}
    if ($ismime) {
      if ($option{fill_ct} && !$exist{'type:'.$ns_content}) {
          my $ct = $self->{header}->field ('type',
            -parse => 1, -ns => $ns_content);
          $ct->media_type ($option{body_default_media_type});
          $ct->replace (charset => $option{body_default_charset});
      }
      if ($option{fill_mimever}
          && !$exist{'mime-version:'.$option{fill_mimever_ns}}) {
        ## BUG: doesn't support rfc10]49, HTTP (ie. non-MIME) content-*: fields
        $self->{header}->add ('mime-version' => '1.0', 
          -parse => 0, -ns => $option{fill_mimever_ns});
      }
    }	# $ismime
    if ($option{format} =~ /uri-url-mailto/ && $exist{'type:$ns_content'}
     && $option{uri_mailto_safe_level} > 1) {
      $self->{header}->field ('content-type')->media_type ('text/plain');
    }
    $self->_add_ua_field;
    $header = $self->{header}->stringify (-format => $option{format},
      -linebreak_strict => $option{linebreak_strict},
      -uri_mailto_safe_level => $option{uri_mailto_safe_level});
  } else {
    $header = $self->{header};
    unless ($option{linebreak_strict}) {
      ## bare \x0D and bare \x0A are unsafe
      $header =~ s/\x0D(?=[^\x09\x0A\x20])/\x0D\x20/g;
      $header =~ s/\x0A(?=[^\x09\x20])/\x0A\x20/g;
    }
  }
  if ($option{format} =~ /uri-url-mailto/) {
    if ($option{format} =~ /rfc1738/) {
      my $to = $self->{header}->stringify (-format => $option{format},
        -uri_mailto_safe_level => $option{uri_mailto_safe_level});
      $to? 'mailto:'.$to: '';
    } else {
      my $f = $option{format};  $f =~ s/-mailto/-mailto-to/;
      my $to = $self->{header}->stringify (-format => $f,
        -uri_mailto_safe_level => $option{uri_mailto_safe_level});
      $body =~ s/([^:@+\$A-Za-z0-9\-_.!~*])/sprintf('%%%02X', ord $1)/ge;
      if (length $body) {
        $header .= '&' if $header;
        $header .= 'body='.$body;
      }
      $header = '?'.$header if $header;
      $to||$header? 'mailto:'.$to.$header: '';
    }
  } else {
    $header .= "\x0D\x0A" if $header && $header !~ /\x0D\x0A$/;
    $header."\x0D\x0A".$body;
  }
}
*as_string = \&stringify;


=head1 SHORTCUT METHOD FOR MESSAGE PROPERTIES

=over 4

=item $self->content_type ([%options])

Returns Internet media type of message body
(aka MIME type, content type).  Only media type
(type/subtype pair) is returned, i.e. no parameter
is returned, if any.  To get such value, or to set
new value, use C<field> method.

Default is C<text/plain>.

Example:

  $msg->field ('Content-Type')->media_type ('text/html');
  print $msg->content_type;	## text/html

=cut

sub content_type ($;%) {
  my $self = shift;
  my $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0);
  unless (ref $ct) {
    return wantarray? qw/text plain/: 'text/plain';
  }
  if (wantarray) {
    ($ct->media_type_major, $ct->media_type_minor);
  } else {
    $ct->media_type;
  }
}
*media_type = \&content_type;

=item $self->id

Returns ID of message entity.  If there are C<Message-ID:>
field, its value is returned.  Unless, but there are
C<Content-ID:> field, it is returned.  Without both of
fields, C<""> is returned.

=cut

sub id ($) {
  my $self = shift;
  return scalar $self->{header}->field ('message-id')->id
    if $self->{header}->field_exist ('message-id');
  return scalar $self->{header}->field ('content-id')->id
    if $self->{header}->field_exist ('content-id');
  '';
}

## Internal function to add of User-Agent: C<product>.
sub _add_ua_field ($) {
  my $self = shift;
  if ($self->{option}->{add_ua}) {
    my $ua = $self->{header}->field ($self->{option}->{fill_ua_name},
      -ns => $self->{option}->{fill_ua_ns});
    $ua->replace ('Message-pm' => $VERSION, -prepend => 0);
    my (@os, @os_comment);
    my @perl_comment;
    if ($self->{option}->{ua_use_config}) {
      @os_comment = ('');
      @os = ($^O => \@os_comment);
      eval q{use Config;
        @os_comment = ($Config{osvers});
        push @perl_comment, $Config{archname};
      };
      eval q{use Win32;
        my $build = Win32::BuildNumber;
        push @perl_comment, "ActivePerl build $build" if $build;
        my @osv = Win32::GetOSVersion;
        @os = (
            $osv[4] == 0? 'Win32s':
            $osv[4] == 1? 'Windows':
            $osv[4] == 2? 'WindowsNT':
                          'Win32',       \@os_comment);
        @os_comment = (sprintf ('%d.%02d.%d', @osv[1,2], $osv[3] & 0xFFFF));
        push @os_comment, $osv[0] if $osv[0] =~ /[^\x09\x20]/;
        if ($osv[4] == 1) {
          if ($osv[1] == 4) {
            if ($osv[2] == 0) {
              if    ($osv[0] =~ /[Aa]/) { push @os_comment, 'Windows 95 OSR1' }
              elsif ($osv[0] =~ /[Bb]/) { push @os_comment, 'Windows 95 OSR2' }
              elsif ($osv[0] =~ /[Cc]/) { push @os_comment, 'Windows 95 OSR2.5' }
              else                      { push @os_comment, 'Windows 95' }
            } elsif ($osv[2] == 10) {
              if    ($osv[0] =~ /[Aa]/) { push @os_comment, 'Windows 98 SE' }
              else                      { push @os_comment, 'Windows 98' }
            } elsif ($osv[2] == 90) {
              push @os_comment, 'Windows Me';
            }
          }
        } elsif ($osv[4] == 2) {
          push @os_comment, 'Windows 2000' if $osv[1] == 5 && $osv[2] == 0;
          push @os_comment, 'Windows XP' if $osv[1] == 5 && $osv[2] == 1;
        }
        push @os_comment, Win32::GetChipName;
      };
    } else {
      push @perl_comment, $^O;
    }
    if ($^V) {	## 5.6 or later
      $ua->replace (Perl => [sprintf ('%vd', $^V), @perl_comment], -prepend => 0);
    } elsif ($]) {	## Before 5.005
      $ua->replace (Perl => [ $], @perl_comment], -prepend => 0);
    }
    $ua->replace (@os, -prepend => 0) if $self->{option}->{ua_use_config};
  }
  $self;
}

=back

=head1 MISC. METHODS

=over 4

=item $self->option ( $option-name / $option-name, $option-value, ...)

If @_ == 1, returns option value.  Else...

Set option value.  You can pass multiple option name-value pair
as parameter.  Example:

  $msg->option (format => 'mail-rfc822',
                capitalize => 0);
  print $msg->option ('format');	## mail-rfc822

=cut

sub option ($@) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{option}->{ $_[0] };
  }
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $self->{option}->{$name} = $value;
    if ($name eq 'format') {
      $self->header->option (-format => $value);
    }
  }
}

=item $self->clone ()

Returns a copy of Message::Entity object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = new Message::Entity;
  $clone->{option} = Message::Util::make_clone ($self->{option});
  for (@{$self->{option}->{_MEMBERS}}) {
    $clone->{$_} = Message::Util::make_clone ($self->{$_});
  }
  $clone;
}

my %_method_default_list = qw(new 1 parse 1 stringify 1 option 1 clone 1 method_available 1);
sub method_available ($$) {
  my $self = shift;
  my $name = shift;
  return 1 if $_method_default_list{$name};
  for (@{$self->{option}->{_METHODS}}) {
    return 1 if $_ eq $name;
  }
  0;
}

=back

=head1 C<format>

=over 2

=item mail-rfc650

Internet mail message, defined by IETF RFC 650

=item mail-rfc724

Internet mail message, defined by IETF RFC 724

=item mail-rfc733

Internet mail message, defined by IETF RFC 733

=item mail-rfc822

Internet mail message, defined by IETF RFC 822

=item mail-rfc2822

Internet mail message, defined by IETF RFC 2822

=item mime-1.0

MIME entity

=item mime-1.0-rfc1341

MIME entity, defined by RFC 1341 (and RFC 1342)

=item mime-1.0-rfc1521

MIME entity, defined by RFC 1521 and 1522

=item mime-1.0-rfc2045

MIME entity, defined by RFC 2045,..., 2049

=item news-bnews

Usenet Bnews format

=item news-rfc850

Usenet news format, defined by IETF RFC 850

=item news-rfc1036

Usenet news format, defined by IETF RFC 1036

=item news-son-of-rfc1036

Usenet news format, defined by son-of-RFC1036

=item news-usefor

Usenet news format, defined by usefor-article (IETF Internet Draft)

=item http-1.0-rfc1945

HTTP/1.0 message, defined by IETF RFC 1945

=item http-1.0-rfc1945-request

HTTP/1.0 request message, defined by IETF RFC 1945

=item http-1.0-rfc1945-response

HTTP/1.0 response message, defined by IETF RFC 1945

=item http-1.1-rfc2068

HTTP/1.1 message, defined by IETF RFC 2068

=item http-1.1-rfc2068-request

HTTP/1.1 request message, defined by IETF RFC 2068

=item http-1.1-rfc2068-response

HTTP/1.1 response message, defined by IETF RFC 2068

=item http-1.1-rfc2616

HTTP/1.1 message, defined by IETF RFC 2616

=item http-1.1-rfc2616-request

HTTP/1.1 request message, defined by IETF RFC 2616

=item http-1.1-rfc2616-response

HTTP/1.1 response message, defined by IETF RFC 2616

=item http-cgi-1.1

CGI/1.1 output (for HTTP), defined by coar-cgi-v11 (IETF Internet Draft)

=item http-1.0-cgi-1.1

CGI/1.1 output (for HTTP/1.0), defined by coar-cgi-v11 (IETF Internet Draft)

=item http-1.1-cgi-1.1

CGI/1.1 output (for HTTP/1.1), defined by coar-cgi-v11 (IETF Internet Draft)

=item http-cgi-1.2

CGI/1.2 output, defined by coar-cgi-v12 (to be IETF Internet Draft)

=item http-1.0-cgi-1.2

CGI/1.2 output (for HTTP/1.0), defined by coar-cgi-v11 (IETF Internet Draft)

=item http-1.1-cgi-1.2

CGI/1.2 output (for HTTP/1.1), defined by coar-cgi-v11 (IETF Internet Draft)

=item http-sip-2.0

SIP/2.0 message, defined by IETF RFC 2543

=item http-sip-2.0-request

SIP/2.0 request message, defined by IETF RFC 2543

=item http-sip-2.0-response

SIP/2.0 response message, defined by IETF RFC 2543

=item http-sip-cgi

SIP/2.0 CGI (IETF Internet Draft)

=item cpim-1.0

CPIM/1.0 (IETF Internet Draft)

=item uri-url-mailto-mail-rfc822, uri-url-mailto-mail-rfc2822

mailto: URL scheme

=item uri-url-mailto-rfc1738

mailto: URL scheme (defined by RFC 1738)

=item uri-url-mailto-rfc2368, uri-url-mailto-rfc2822

mailto: URL scheme (defined by RFC 2368)

=item uri-url-mailto-to-mail-rfc822, uri-url-mailto-to-mail-rfc2822

C<to> part of mailto: URL scheme (for internal use only)

=back

=head1 EXAMPLE

  use Message::Entity;
  my $msg = new Message::Entity From	=> 'foo@example.org',
                                Subject	=> 'Example message',
                                To	=> 'bar@example.net',
                                -format	=> 'mail-rfc2822',
                                body	=> $body;
  $msg->header ($header);
  $msg->body ($body);
  print $msg;

=head1 SEE ALSO

Message::* Perl modules
<http://suika.fam.cx/~wakaba/Message-pm/>

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
$Date: 2002/05/29 11:05:53 $

=cut

1;
