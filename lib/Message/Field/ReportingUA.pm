
=head1 NAME

Message::Field::ReportingUA --- A perl module for
MDN Reporting-UA: field body [RFC2298]

=cut

package Message::Field::ReportingUA;
use strict;
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);

%REG = %Message::Util::REG;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_MEMBERS	=> [qw|ua_product|],
    -_METHODS	=> [qw||],
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #field_ns
    #format
    #hook_encode_string
    #hook_decode_string
    -output_comment	=> 1,
    #parse_all
    -use_comment	=> 1,
  );


=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  $self->SUPER::_init (%$DEFAULT, @_);
  
  $self->{option}->{value_type}->{ua_product} = ['Message::Field::UA'];
}

=item $addr = Message::Field::Domain->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $addr = Message::Field::Domain->parse ($field-body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  if ($body =~ /
    ((?:$REG{comment}|$REG{quoted_string}|[^\x22\x28;])*)
    (?:
    ;
    ([\x00-\xFF]*)
    )?
  /x) {
    my ($ua_name, $ua_product) = ($1, $2);
    ($ua_name, @{$self->{comment}})
      = $self->Message::Util::delete_comment_to_array ($ua_name)
      if $self->{option}->{use_comment};
    $ua_name = Message::Util::unquote_if_quoted_string ($ua_name);
    $ua_name =~ s/^$REG{WSP}+//;  $ua_name =~ s/$REG{WSP}+$//;
    $self->{value} = $ua_name;
    $self->{ua_product} = $ua_product;
    $self->{ua_product} = $self->_parse_value (ua_product => $self->{ua_product})
      if $self->{option}->{parse_all};
  };
  $self;
}

sub ua_name ($;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    $self->{value} = $newvalue;
  }
  $self->{value};
}
*value = \&ua_name;

sub ua_product ($$;$) {
  my $self = shift;
  my ($newvalue) = @_;
  if ($newvalue) {
    if ($self->{option}->{parse_all}) {
      $self->{ua_product} = $self->_parse_value
        (ua_product => $newvalue);
    } else {
      $self->{ua_product} = $newvalue;
    }
  }
  if (defined wantarray) {
    $self->{ua_product} = $self->_parse_value
        (ua_product => $self->{ua_product});
    $self->{ua_product};
  }
}

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $s;
  $s = Message::Util::quote_unsafe_string ($self->{value});
  if ($option{use_comment} && $option{output_comment}) {
    my $c = $self->_comment_stringify;
    $s .= ' ' . $c if $c;
  }
  my $ua = ''.$self->{ua_product};
  $s = sprintf '%s; %s', $s, $ua if length $ua;
  $s;
}

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
$Date: 2002/07/13 09:27:35 $

=cut

1;
