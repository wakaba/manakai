
=head1 NAME

Message::Field::URI --- A Perl Module for Internet Message
Header Field Bodies filled with a URI

=cut

package Message::Field::URI;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Header;
require Message::Field::AngleQuoted;
push @ISA, qw(Message::Field::AngleQuoted);

%REG = %Message::Util::REG;

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
    #comment_to_display_name	=> 0,
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #hook_encode_string
    #hook_decode_string
    #output_angle_bracket	=> 1,
    #output_comment	=> 1,
    #output_display_name	=> 1,
    #output_keyword	=> 0,
    #parse_all
    -value_pattern	=> '%s',
    #unsafe_rule_of_display_name	=> 'NON_http_attribute_char_wsp',
    #unsafe_rule_of_keyword
    #use_comment	=> 1,
    #use_display_name	=> 1,
    #use_keyword	=> 0,
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
  if ($fieldns eq $Message::Header::NS_phname2uri{list}) {	## List-*
    $self->{option}->{output_display_name} = 0;
    $self->{option}->{allow_empty} = 0;
  } elsif ($fieldns eq $Message::Header::NS_phname2uri{content}) {
    if ($field eq 'location') {	## Content-Location
      $self->{option}->{output_angle_bracket} = 0;
      $self->{option}->{output_display_name} = 0;
      $self->{option}->{output_comment} = 0;
      $self->{option}->{use_display_name} = 0;
      $self->{option}->{allow_fragment} = 0;
    } elsif ($field eq 'base') {	## Content-Base
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

## $self->_save_value ($value, $display_name, \@comment)
sub _save_value ($$\@%) {
  my $self = shift;
  my ($v, $dn, $comment, %misc) = @_;
  $v =~ tr/\x09\x0A\x0D\x20//d;
  $v =~ s/^[Uu][Rr][LlIi]://;
  $v = $self->_parse_value (uri => $v) if $self->{option}->{parse_all};
  $self->{value} = $v;
  $self->{display_name} = $dn;
  $self->{comment} = $comment;
  $self->{keyword} = $misc{keyword};
}

=head2 $URI = $uri->uri ([$newURI])

Set/gets C<URI>.  See also L<NOTE>.

=cut

sub uri ($;$%) { shift->value (@_) }

## display_name: Inherited

## stringify: Inherited

## $self->_stringify_value (\%option)
sub _stringify_value ($\%) {
  my $self = shift;
  my $option = shift;
  my %r;
  my $v = $self->{value};
  unless (ref $v) {
    $v =~ s/([\x00-\x20\x22\x3C\x3E\x5C\x7F-\xFF])/sprintf('%%%02X', ord $1)/ge;
  }
  $r{value} = sprintf $option->{value_pattern}, $v;
  $r{display_name} = $self->{display_name};
  $r{comment} = $self->{comment};
  $r{keyword} = $self->{keyword};
  %r;
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
$Date: 2002/08/03 04:57:59 $

=cut

1;
