
=head1 NAME

Message::Field::URI Perl module

=head1 DESCRIPTION

Perl module for URI field body (such as C<List-*:>, C<Content-Location:>).

=cut

package Message::Field::URI;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::MIME::EncodedWord;
use Carp;
use overload '""' => sub {shift->stringify};

$REG{WSP} = qr/[\x09\x20]/;
$REG{FWS} = qr/[\x09\x20]*/;

$REG{comment} = qr/\x28(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*\x29/;
$REG{quoted_string} = qr/\x22(?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*\x22/;
$REG{uri_literal} = qr/\x3C[\x09\x20\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]*\x3E/;
$REG{atext} = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
#$REG{atext_dot} = qr/[\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{phrase} = qr/(?:$REG{atext}|$REG{quoted_string})(?:$REG{atext}|$REG{quoted_string}|\.|$REG{FWS})*/;
$REG{phrase_c} = qr/(?:$REG{atext}|$REG{quoted_string}|$REG{comment}|\.|$REG{FWS})*/;

## Simple version of URI regex  See RFC 2396, RFC 2732, RFC 2324.
$REG{escaped} = qr/%[0-9A-Fa-f][0-9A-Fa-f]/;
$REG{scheme} = qr/(?:[A-Za-z]|$REG{escaped})(?:[0-9A-Za-z+.-]|$REG{escaped})*/;
	## RFC 2324 defines escaped UTF-8 schemes:-)
$REG{fragment} = qr/\x23(?:[\x21\x24\x26-\x3B\x3D\x3F-\x5A\x5F\x61-\x7A\x7E]|$REG{escaped})*/;
$REG{S_uri_body} = qr/(?:[\x21\x24\x26-\x3B\x3D\x3F-\x5A\x5B\x5D\x5F\x61-\x7A\x7E]|$REG{escaped})+/;
$REG{S_absoluteURI} = qr/$REG{scheme}:$REG{S_uri_body}/;
$REG{S_relativeURI} = qr/$REG{S_uri_body}/;
$REG{S_URI_reference} = qr/(?:$REG{S_absoluteURI}|$REG{S_relativeURI})(?:$REG{fragment})?|(?:$REG{fragment})/;
	## RFC 2396 allows <> (empty URI), but this regex doesn't.

$REG{M_comment} = qr/\x28((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x27\x2A-\x5B\x5D-\xFF]|(??{$REG{comment}}))*)\x29/;
$REG{M_quoted_string} = qr/\x22((?:\x5C[\x00-\xFF]|[\x00-\x0C\x0E-\x21\x23-\x5B\x5D-\xFF])*)\x22/;
$REG{M_uri_literal} = qr/\x3C([\x09\x20\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]*)\x3E/;
$REG{M_S_phrase_uri} = qr/($REG{phrase_c})$REG{M_uri_literal}/;
$REG{uri_phrase} = qr/[\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]+(?:$REG{WSP}+[\x21\x23-\x27\x29-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E][\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]*)*/;
#$REG{M_phrase_uri} = qr/($REG{phrase_c})<$REG{FWS}($REG{S_URI_reference})$REG{FWS}>/;
#$REG{M_phrase_uri_a} = qr/($REG{phrase_c})<$REG{FWS}($REG{S_absoluteURI})$REG{FWS}>/;
#$REG{M_phrase_uri_af} = qr/($REG{phrase_c})<$REG{FWS}($REG{S_absoluteURI}(?:$REG{fragment})?)$REG{FWS}>/;
#$REG{M_uri_content} = qr/$REG{M_S_phrase_uri}((?:$REG{FWS}$REG{comment})*)|($REG{S_URI_reference})($REG{WSP}(?:$REG{FWS}$REG{comment})*)?/;
$REG{M_uri_content} = qr/$REG{M_S_phrase_uri}((?:$REG{FWS}$REG{comment})*)|($REG{uri_phrase})($REG{WSP}(?:$REG{FWS}$REG{comment})*)?/;

#$REG{NON_atext} = qr/[^\x21\x23-\x27\x2A\x2B\x2D\x2F\x30-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
#$REG{NON_atext_dot} = qr/[^\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;
$REG{NON_atext_dot_wsp} = qr/[^\x09\x20\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x3F\x41-\x5A\x5E-\x7E]/;


%DEFAULT = (
  allow_absolute	=> 1,	## TODO: not implemented
  allow_fragment	=> 1,	## TODO: not implemented
  allow_relative	=> 1,	## TODO: not implemented
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  field_name	=> 'x-uri',
  format	=> 'http',	## http, mhtml (= rfc2822, mime, news), cgi
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
  output_angle_bracket	=> 1,
  output_comment	=> 1,
  output_display_name	=> 1,
);

## Initialization for both C<new> and C<parse> methods.
sub _initialize ($;%) {
  my $self = shift;
  my $fname = lc $self->{option}->{field_name};
  my $format = $self->{option}->{format};
  $format = 'mhtml' if $format eq 'rfc2822' || $format eq 'news'
    || $format eq 'usefor' || $format eq 'mime';
  if ($fname =~ /^list-/) {
    $self->{option}->{output_display_name} = -1;
  } elsif ($fname eq 'content-location') {
    $self->{option}->{output_angle_bracket} = -1;
    $self->{option}->{output_display_name} = -1;
    ## Comments should not be used.  Allowing this makes it difficult
    ## to parse URI contains of "(" and ")".
    #if ($format ne 'mhtml') {	## http
      $self->{option}->{output_comment} = -1;
    #}
    $self->{option}->{allow_fragment} = -1;
  } elsif ($fname eq 'link') {
    $self->{option}->{output_display_name} = -1;
    $self->{option}->{output_comment} = -1;
    $self->{option}->{allow_fragment} = -1;
  } elsif ($fname eq 'location') {
    $self->{option}->{output_angle_bracket} = -1;
    $self->{option}->{output_display_name} = -1;
    $self->{option}->{output_comment} = -1;
    if ($format ne 'cgi') {	## http
      $self->{option}->{allow_relative} = -1;
      $self->{option}->{allow_fragment} = -1;
    }
  } elsif ($fname eq 'referer') {
    $self->{option}->{output_angle_bracket} = -1;
    $self->{option}->{output_display_name} = -1;
    $self->{option}->{output_comment} = -1;
    $self->{option}->{allow_fragment} = -1;
  } elsif ($fname eq 'uri') {
    $self->{option}->{output_display_name} = -1;
    $self->{option}->{output_comment} = -1;
  } elsif ($fname eq 'content-base') {
    $self->{option}->{output_angle_bracket} = -1;
    $self->{option}->{output_display_name} = -1;
    $self->{option}->{output_comment} = -1;
    $self->{option}->{allow_relative} = -1;
    $self->{option}->{allow_fragment} = -1;
  }
}

=head2 Message::Field::URI->new ([%option])

Returns new Message::Field::URI.  Some options can be given as hash.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {comment => [], option => {@_}}, $class;
  $self->_initialize_new ();
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

## Initialization for new () method.
sub _initialize_new ($;%) {
  my $self = shift;
  $self->_initialize ();
}

=head2 Message::Field::URI->parse ($field-body, [%option])

Parses URI-type C<field-body> and returns new instance.  
Some options can be given as hash.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $body = shift;
  my $self = bless {comment => [], option => {@_}}, $class;
  $self->_initialize_parse ();
  for (keys %DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  if ($body =~ /^$REG{M_uri_content}$/) {
    my ($uri, $phrase_c, $comments) = ($2||$4, $1, $3||$5);
    $uri =~ tr/\x09\x20//d;
    $self->{uri} = $uri;
    $phrase_c =~ s{$REG{M_comment}}{
      my $comment = $self->_decode_ccontent ($1);
      push @{$self->{comment}}, $comment if length $comment;
      '';
    }goex;
    $phrase_c =~ s/^$REG{WSP}+//; $phrase_c =~ s/$REG{WSP}+$//;
    $self->{display_name} = $self->_decode_quoted_string ($phrase_c);
    $comments =~ s{$REG{M_comment}}{
      my $comment = $self->_decode_ccontent ($1);
      push @{$self->{comment}}, $comment if length $comment;
    }goex;
  }
  $self;
}

## Initialization for parse () method.
sub _initialize_parse ($;%) {
  my $self = shift;
  $self->_initialize ();
}

=head2 $self->display_name ([$newname])

Set/gets C<display-name>.  Display name is prepend
to C<URI> as C<phrase> (C<atom>s or a C<quoted-string>).

Note that C<display-name> is outputted only if the class
option C<outout_display_name> is C<1>.  If its value
is C<-1> but C<output_comment> is C<1>, display name
value is outputted as C<comment>.  Neither of these
options takes C<1> value, display name is outputted
nowhere.

=cut

sub display_name ($;$%) {
  my $self = shift;
  my $dname = shift;
  if (defined $dname) {
    $self->{display_name} = $dname;
  }
  $self->{display_name};
}

=head2 $self->comment_add ($comment, [%option]

Adds a C<comment>.  Comments are outputed only when
the class option (not an option of this method!)
 C<output_comment> is enabled (value C<1>).

On this method, only one option, C<prepend> is available.
With this option, additional comment is prepend
to current comments.  (Default value is C<-1>, append.)

=cut

sub comment_add ($$;%) {
  my $self = shift;
  my ($value, %option) = (shift, @_);
  if ($option{prepend}) {
    unshift @{$self->{comment}}, $value;
  } else {
    push @{$self->{comment}}, $value;
  }
  $self;
}

=head2 $self->comment ()

Returns array reference of comments.  You can add/remove/change
array values.

=cut

sub comment ($) {
  my $self = shift;
  $self->_comment_delete_empty->{comment};
}

sub _comment_delete_empty ($) {
  my $self = shift;
  $self->{comment} = [grep {length} @{$self->{comment}}];
  $self;
}


=head2 $self->stringify ([%option])

Returns Message::Field::URI as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  for (qw (allow_relative output_angle_bracket output_comment output_display_name)) {
    $option{$_} ||= $self->{option}->{$_};
  }
  if ($option{allow_relative}<0 && length $self->{uri} == 0) {
    return '';
  }
  my $r = '';
  if (length $self->{display_name}) {
    if ($option{output_display_name}>0) {
      $r = $self->_quote_unsafe_string ($self->{display_name});
      $r .= ' ';
    } elsif ($option{output_comment}>0) {
      my %f = &{$self->{option}->{hook_encode_string}}
        ($self, $self->{display_name}, type => 'ccontent');
      $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/
        "\x5C$1".(defined $2?"\x5C$2":'')/ge;
      $r .= '('.$f{value}.') ';
    }
  }
  if ($option{output_angle_bracket}>0) {
    $r .= '<'.$self->{uri}.'>';
  } else {
    $r .= $self->{uri};
  }
  if ($option{output_comment}>0) {
    $self->_comment_delete_empty ();
    for (@{$self->{comment}}) {
      my %f = &{$self->{option}->{hook_encode_string}}
        ($self, $_, type => 'ccontent');
      $f{value} =~ s/([\x28\x29\x5C])([\x21-\x7E])?/
        "\x5C$1".(defined $2?"\x5C$2":'')/ge;
      $r .= ' ('.$f{value}.')' if length $f{value};
    }
  }
  $r;
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
  $option{unsafe} ||= 'NON_atext_dot_wsp';
  if ($string =~ /$REG{$option{unsafe}}/ || $string =~ /$REG{WSP}$REG{WSP}/) {
    $string =~ s/([\x22\x5C])([\x21-\x7E])?/"\x5C$1".(defined $2?"\x5C$2":'')/ge;
    $string = '"'.$string.'"';
  }
  $string;
}

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

sub _decode_quoted_string ($$) {
  my $self = shift;
  my $quoted_string = shift;
  $quoted_string =~ s{$REG{M_quoted_string}|([^\x22]+)}{
    my ($qtext,$t) = ($1, $2);
    if ($t) {
      $t =~ s/($REG{WSP})+/$1/g;
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $t,
                type => 'value');
      $s{value};
    } else {
      $qtext =~ s/\x5C([\x00-\xFF])/$1/g;
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $qtext,
                type => 'value/quoted');
      $s{value};
    }
  }goex;
  $quoted_string;
}

sub _decode_ccontent ($$) {
  &Message::MIME::EncodedWord::decode_ccontent (@_[1,0]);
}

=head1 NOTE

Current version of this module does not check whether
URI is correct or not.  In particullar, implementor
should be careful not to output URI that is syntactically
valid, but do not match to context.  For example,
C<Location:> field defined by HTTP/1.1 [RFC2616] doesn't
allow relative URIs.  (Interestingly, with CGI/1.1,
we can use relative URI as value of C<Location> field.

There is three options related with URI type.
C<allow_absolute>, C<allow_relative>, and C<allow_fragment>.
But this options don't work as you hope.
These options are only reserved for future implemention.

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
$Date: 2002/03/31 13:11:55 $

=cut

1;
