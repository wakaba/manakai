
=head1 NAME

Message::Entity Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<message>.
MIME multipart will be also supported (but not implemented yet).

=cut

package Message::Entity;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.12 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Header;
require Message::Util;
use overload '""' => sub { $_[0]->stringify },
             fallback => 1;

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = {
    add_ua	=> 1,
    body_class	=> {'/DEFAULT' => 'Message::Body::TextPlain'},
    #fill_date	=> 1,
    #fill_msgid	=> 1,
    format	=> 'mail-rfc2822',
    linebreak_strict	=> 0,	## BUG: not work perfectly
    parse_all	=> 0,
    #ua_field_name	=> 'user-agent',
    ua_use_config	=> 1,
    uri_mailto_safe_level	=> 4,
  };
  my @new_fields = ();
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } else {
      push @new_fields, (lc $name => $options{$name});
    }
  }
  my $format = $self->{option}->{format};
  unless (defined $self->{option}->{fill_date}) {
    $self->{option}->{fill_date} = $format !~ /cgi|uri-url-mailto/;
  }
  unless (defined $self->{option}->{fill_msgid}) {
    $self->{option}->{fill_msgid} = $format !~ /http|uri-url-mailto/;
  }
  unless (defined $self->{option}->{fill_mimever}) {
    $self->{option}->{fill_mimever} = $format !~ /http/;
  }
  unless (length $self->{option}->{ua_field_name}) {
    $self->{option}->{ua_field_name} = $format =~ /response|cgi|uri-url-mailto/?
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
    $self->{body} = $self->_body ($self->{body}, $self->content_type)
      if $self->{option}->{parse_all};
  }
  $self->{header} = new Message::Header -format => $self->{option}->{format},
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
  my @header = ();	## BUG: don't check linebreak_strict
  my @body = split /\x0D?\x0A/, $message;	## BUG: not binary-clean...
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
  $self->{body} = join "\n", @body;	## BUG: binary-unsafe
  $self->{body} = $self->_body ($self->{body}, $self->content_type)
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
  unless ($self->{header}) {
    $self->{header} = new Message::Header (-format => $self->{option}->{format});
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
  $self->{body} = $self->_body ($self->{body}, $self->content_type)
    unless ref $self->{body};
  $self->{body};
}

sub _body ($;$$) {
  my $self = shift;
  my $body = shift;
  my $ct = shift;
  $ct = $self->{option}->{body_class}->{$ct}
     || $self->{option}->{body_class}->{'/DEFAULT'};
  eval "require $ct";
  if (ref $body) {
    return $body;
  } elsif ($body) {
    return $ct->parse ($body,
      -parse_all => $self->{option}->{parse_all});
  } else {
    return $ct->new ($body);
  }
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
  if (ref $self->{header}) {
    my %exist;
    for ($self->{header}->field_name_list) {$exist{$_} = 1}
    if ($option{fill_date} && !$exist{'date'}) {
      $self->{header}->field ('date')->unix_time (time);
    }
    if ($option{fill_msgid} && !$exist{'message-id'}) {
      my $from = $self->{header}->field ('from')->addr_spec (1);
      $self->{header}->field ('message-id')->generate (addr_spec => $from)
        if $from;
    }
    if ($option{fill_mimever} && !$exist{'mime-version'}) {
      ## BUG: rfc1049...
      my $ismime = 0;
      for (keys %exist) {if (/^content-/) {$ismime = 1; last}}
      if ($ismime) {
        $self->{header}->add ('mime-version' => '1.0', -parse => 0);
      }
    }
    if ($option{format} =~ /uri-url-mailto/ && $exist{'content-type'}
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
  if (ref $self->{body}) {
    $body = $self->{body}->stringify (-format => $option{format},
      -linebreak_strict => $option{linebreak_strict});
  } else {
    $body = $self->{body};
  }
  if ($option{format} =~ /uri-url-mailto/) {
    my $f = $option{format};  $f =~ s/-mailto/-mailto-to/;
    my $to = $self->{header}->stringify (-format => $f,
      -uri_mailto_safe_level => $option{uri_mailto_safe_level});
    $body =~ s/([^:@+\$A-Za-z0-9\-_.!~*])/sprintf('%%%02X', ord $1)/ge;
    if (length $body) {
      $header .= '&' if $header;
      $header .= 'body='.$body;
    }
    $header = '?'.$header if $header;
    'mailto:'.$to.$header;
  } else {
    $header .= "\n" if $header && $header !~ /\n$/;
    $header."\n".$body;
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
  return scalar $self->{header}->field ('content-type')->media_type
    if $self->{header}->field_exist ('content-type');
  'text/plain';
}

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

## Internal function for addition of User-Agent: C<product>.
sub _add_ua_field ($) {
  my $self = shift;
  if ($self->{option}->{add_ua}) {
    my $ua = $self->{header}->field ($self->{option}->{ua_field_name});
    $ua->replace ('Message-pm' => $VERSION, -prepend => 0);
    my @os;
    my @perl_comment;
    if ($self->{option}->{ua_use_config}) {
      eval q{use Config;
        @os = ($^O => $Config{osvers}, -prepend => 0);
        push @perl_comment, $Config{archname};
      };
    } else {
      push @perl_comment, $^O;
    }
    if ($^V) {	## 5.6 or later
      $ua->replace (Perl => [sprintf ('%vd', $^V), @perl_comment], -prepend => 0);
    } elsif ($]) {	## Before 5.005
      $ua->replace (Perl => [ $], @perl_comment], -prepend => 0);
    }
    $ua->replace (@os) if $self->{option}->{ua_use_config};
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

  $msg->option (-format => 'mail-rfc822',
                -capitalize => 0);
  print $msg->option ('-format');	## mail-rfc822

Note that introduction character, i.e. C<-> (HYPHEN-MINUS)
is optional.  You can also write as this:

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
    $name =~ s/^-//;
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
  for my $name (%{$self->{option}}) {
    if (ref $self->{option}->{$name} eq 'HASH') {
      $clone->{option}->{$name} = {%{$self->{option}->{$name}}};
    } elsif (ref $self->{option}->{$name} eq 'ARRAY') {
      $clone->{option}->{$name} = [@{$self->{option}->{$name}}];
    } else {
      $clone->{option}->{$name} = $self->{option}->{$name};
    }
  }
  $clone->{header} = ref $self->{header}? $self->{header}->clone: $self->{header};
  $clone->{body} = ref $self->{body}? $self->{body}->clone: $self->{body};
  $clone;
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
$Date: 2002/05/14 13:50:11 $

=cut

1;
