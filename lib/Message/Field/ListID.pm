
=head1 NAME

Message::Field::ListID --- List-ID header field of
Internet Messages

=cut

package Message::Field::ListID;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::AngleQuoted;
push @ISA, qw(Message::Field::AngleQuoted);

%REG = %Message::Util::REG;

%DEFAULT = (
    -_MEMBERS	=> [qw|display_name|],
    -_METHODS	=> [qw|display_name uri
                       comment_add comment_delete comment_item
                       comment_count|],
    -allow_empty	=> 0,
    -comment_to_display_name	=> 0,
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #field_ns
    #hook_encode_string
    #hook_decode_string
    #output_angle_bracket	=> 1,
    #output_comment	=> 1,
    #output_display_name	=> 1,
    #parse_all
    #unsafe_rule_of_display_name	=> 'NON_http_attribute_char_wsp',
    #use_comment	=> 1,
    #use_comment_in_angle	=> 0,
    #use_display_name	=> 1,
    -value_type	=> {listid	=> ['Message::Field::Domain',{
    	-format_ipv4	=> '%vd',
    	-format_ipv6	=> '[%s]',
    	-use_comment	=> 0,
    	-use_domain_literal	=> 1,
    		## Although RFC 2919 doesn't allow domain-literal,
    		## using it is better than output bare unsafe id.
    }]},
);

sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, %options);
}

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=item $uri = Message::Field::URI->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $uri = Message::Field::URI->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

## Inherited

## $self->_save_value ($value, $display_name, \@comment)
sub _save_value ($$\@%) {
  my $self = shift;
  my ($v, $dn, $comment, %misc) = @_;
  $v =~ tr/\x09\x0A\x0D\x20//d;
  $v = $self->_parse_value (listid => $v) if $self->{option}->{parse_all};
  $self->{value} = $v;
  $self->{display_name} = $dn;
  $self->{comment} = $comment;
  $self->{keyword} = $misc{keyword};
}

## display_name: Inherited

## value: Inherited

## stringify: Inherited

## $self->_stringify_value (\%option)
sub _stringify_value ($\%) {
  my $self = shift;
  my $option = shift;
  my %r;
  $r{value} = ''.$self->{value};
  $r{display_name} = $self->{display_name};
  $r{comment} = $self->{comment};
  $r{keyword} = $self->{keyword};
  %r;
}

=head1 SEE ALSO

RFC 2919 E<lt>urn:ietf:rfc:2919>

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
$Date: 2002/06/16 11:02:46 $

=cut

1;
