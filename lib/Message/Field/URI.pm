
=head1 NAME

Message::Field::URI --- A Perl Module for Internet Message
Header Field Bodies filled with a URI

=cut

package Message::Field::URI;
use strict;
require 5.6.0;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;
	$REG{SCM_angle_quoted} = qr/<([^\x3E]*)>/;

	## Simple version of URI regex  See RFC 2396, RFC 2732, RFC 2324.
	#$REG{escaped} = qr/%[0-9A-Fa-f][0-9A-Fa-f]/;
	#$REG{scheme} = qr/(?:[A-Za-z]|$REG{escaped})(?:[0-9A-Za-z+.-]|$REG{escaped})*/;
		## RFC 2324 defines escaped UTF-8 scheme names:-)
	#$REG{fragment} = qr/\x23(?:[\x21\x24\x26-\x3B\x3D\x3F-\x5A\x5F\x61-\x7A\x7E]|$REG{escaped})*/;
	#$REG{S_uri_body} = qr/(?:[\x21\x24\x26-\x3B\x3D\x3F-\x5A\x5B\x5D\x5F\x61-\x7A\x7E]|$REG{escaped})+/;
	#$REG{S_absoluteURI} = qr/$REG{scheme}:$REG{S_uri_body}/;
	#$REG{S_relativeURI} = qr/$REG{S_uri_body}/;
	#$REG{S_URI_reference} = qr/(?:$REG{S_absoluteURI}|$REG{S_relativeURI})(?:$REG{fragment})?|(?:$REG{fragment})/;
		## RFC 2396 allows <> (empty URI), but this regex doesn't.
	
	#$REG{uri_phrase} = qr/[\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]+(?:$REG{WSP}+[\x21\x23-\x27\x29-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E][\x21\x23-\x3B\x3D\x3F-\x5B\x5D\x5F\x61-\x7A\x7E]*)*/;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

%DEFAULT = (
    -_MEMBERS	=> [qw|display_name|],
    -_METHODS	=> [qw|display_name uri
                       comment_add comment_delete comment_item
                       comment_count|],
    -allow_absolute	=> 1,	## TODO: not implemented
    -allow_empty	=> 1,
    -allow_fragment	=> 1,	## TODO: not implemented
    -allow_relative	=> 1,	## TODO: not implemented
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #hook_encode_string
    #hook_decode_string
    -output_angle_bracket	=> 1,
    -output_comment	=> 1,
    -output_display_name	=> 1,
    #parse_all
    -unsafe_rule_display_name	=> 'NON_http_attribute_char_wsp',
    -use_comment	=> 1,
    -use_display_name	=> 1,
);

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
  #$self->{option}->{value_type}->{uri} = ['URI::'];
  
  my $format = $self->{option}->{format};
  my $field = $self->{option}->{field_name};
  my $fieldns = $self->{option}->{field_ns};
  $format = 'mhtml' if $format =~ /mail|news/;
  if ($fieldns eq $Message::Header::NS_phname2uri{list}) {
    $self->{option}->{output_display_name} = 0;
    $self->{option}->{allow_empty} = 0;
  } elsif ($fieldns eq $Message::Header::NS_phname2uri{content}) {
    if ($field eq 'location') {
      $self->{option}->{output_angle_bracket} = 0;
      $self->{option}->{output_display_name} = 0;
      $self->{option}->{output_comment} = 0;
      $self->{option}->{use_display_name} = 0;
      $self->{option}->{allow_fragment} = 0;
    } elsif ($field eq 'content-base') {
      $self->{option}->{output_angle_bracket} = 0;
      $self->{option}->{output_comment} = 0;
      $self->{option}->{use_display_name} = 0;
      $self->{option}->{allow_relative} = 0;
      $self->{option}->{allow_fragment} = 0;
    }
  } elsif ($field eq 'link') {	## HTTP
    $self->{option}->{output_display_name} = 0;
    $self->{option}->{output_comment} = 0;
    $self->{option}->{allow_fragment} = 0;
  } elsif ($field eq 'location') {	## HTTP / HTTP-CGI
    $self->{option}->{output_angle_bracket} = 0;
    $self->{option}->{use_comment} = 0;
    $self->{option}->{use_display_name} = 0;
    if ($format =~ /cgi/) {
      $self->{option}->{allow_relative} = 0;
      $self->{option}->{allow_fragment} = 0;
    }
  } elsif ($field eq 'referer') {	## HTTP
    $self->{option}->{output_angle_bracket} = 0;
    $self->{option}->{use_comment} = 0;
    $self->{option}->{use_display_name} = 0;
    $self->{option}->{allow_fragment} = 0;
  } elsif ($field eq 'uri') {	## HTTP
    $self->{option}->{output_comment} = 0;
    $self->{option}->{output_display_name} = 0;
  }
}

=item $uri = Message::Field::URI->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $uri = Message::Field::URI->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  ($body, @{$self->{comment}})
    = $self->Message::Util::delete_comment_to_array ($body, -use_angle_quoted)
    if $self->{option}->{use_comment};
  if ($body =~ /([^\x3C]*)$REG{SCM_angle_quoted}/) {
    my ($dn, $as) = ($1, $2);
    $dn =~ s/^$REG{WSP}+//;  $dn =~ s/$REG{WSP}+$//;
    $self->{display_name} = $self->Message::Util::decode_quoted_string ($dn);
    #$as =~ s/^$REG{WSP}+//;  $as =~ s/$REG{WSP}+$//;
    $as =~ tr/\x09\x20//d;
    $self->{value} = $as;
  } else {
    #$body =~ s/^$REG{WSP}+//;  $body =~ s/$REG{WSP}+$//;
    $body =~ tr/\x09\x20//d;
    $self->{value} = $body;
  }
  $self->{value} = $self->_parse_value (uri => $self->{value})
    if $self->{option}->{parse_all};
  $self;
}


=head2 $URI = $uri->uri ([$newURI])

Set/gets C<URI>.  See also L<NOTE>.

=cut

sub uri ($;$%) {
  my $self = shift;
  my $dname = shift;
  if (defined $dname) {
    $self->{value} = $dname;
  }
  $self->{value};
}


sub display_name ($;$%) {
  my $self = shift;
  my $dname = shift;
  if (defined $dname) {
    $self->{display_name} = $dname;
  }
  $self->{display_name};
}


sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $uri = ''.$self->{value};
  if ((!$option{allow_relative} || !$option{allow_empty})
    && length $uri == 0) {
    return '';
  }
  my ($dn, $as, $cm) = ('', '', '');
  if (length $self->{display_name}) {
    if ($option{use_display_name} && $option{output_display_name}) {
        my %s = &{$option{hook_encode_string}} ($self, 
            $self->{display_name}, type => 'phrase');
        $dn = Message::Util::quote_unsafe_string
            ($s{value}, unsafe => $option{unsafe_rule_display_name}) . ' ';
    } elsif ($option{use_comment} && $option{output_comment}) {
      $dn = ' ('. $self->Message::Util::encode_ccontent ($self->{display_name}) .')';
    }
  }
  
  if ($option{output_angle_bracket}) {
    $as = '<'.$uri.'>';
  } else {
    $as = $uri;
  }
  
  if ($option{use_comment} && $option{output_comment}) {
    $cm = $self->_comment_stringify (\%option);
    $cm = ' ' . $cm if $cm;
    if ($dn && !($option{use_display_name} && $option{output_display_name})) {
      $cm = $dn . $cm;  $dn = '';
    }
  }
  $dn . $as . $cm;
}
*as_string = \&stringify;


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
$Date: 2002/06/09 11:08:28 $

=cut

1;
