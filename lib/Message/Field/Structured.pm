
=head1 NAME

Message::Field::Structured -- Perl module for
structured header field bodies of the Internet message

=cut

package Message::Field::Structured;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.5 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
use overload '""' => sub { $_[0]->stringify },
             '.=' => sub { $_[0]->value_append ($_[1]) },
             'eq' => sub { $_[0]->{field_body} eq $_[1] },
             'ne' => sub { $_[0]->{field_body} ne $_[1] },
             fallback => 1;

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Structured> objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = {
  encoding_after_encode	=> '*default',
  encoding_before_decode	=> '*default',
  hook_encode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::encode_header_string,
  hook_decode_string	=> #sub {shift; (value => shift, @_)},
  	\&Message::Util::decode_header_string,
  };
  $self->{field_body} = '';
  
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } elsif (lc $name eq 'body') {
      $self->{field_body} = $options{$name};
    }
  }
}

=item Message::Field::Structured->new ([%options])

Constructs a new C<Message::Field::Structured> object.  You might pass some 
options as parameters to the constructor.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  $self;
}

=item Message::Field::Structured->parse ($field-body, [%options])

Constructs a new C<Message::Field::Structured> object with
given field body.  You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  #my $field_body = $self->Message::Util::decode_qcontent (shift);
  $self->{field_body} = shift; #$field_body;
  $self;
}

=back

=head1 METHODS

=over 4

=item $self->stringify ([%options])

Returns field body as a string.  Returned string is encoded,
quoted if necessary (by C<hook_encode_string>).

=cut

sub stringify ($) {
  my $self = shift;
  #$self->Message::Util::encode_qcontent ($self->{field_body});
  $self->{field_body};
}
*as_string = \&stringify;

=item $self->as_plain_string

Returns field body as a string.  Returned string is not encoded
or quoted, i.e. internal/bare coded string.  This string
may be unable to use as field body content.  (Its I<structures>
such as C<comment> and C<quoted-string> are lost.)

=cut

sub as_plain_string ($) {
  my $self = shift;
  my $s = $self->Message::Util::decode_qcontent ($self->{field_body});
  Message::Util::unquote_quoted_string (Message::Util::unquote_ccontent ($s));
}

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
  }
}

=item $self->clone ()

Returns a copy of Message::Field::Structured object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = ref($self)->new;
  for my $name (%{$self->{option}}) {
    if (ref $self->{option}->{$name} eq 'HASH') {
      $clone->{option}->{$name} = {%{$self->{option}->{$name}}};
    } elsif (ref $self->{option}->{$name} eq 'ARRAY') {
      $clone->{option}->{$name} = [@{$self->{option}->{$name}}];
    } else {
      $clone->{option}->{$name} = $self->{option}->{$name};
    }
  }
  $clone->{field_body} = ref $self->{field_body}? 
                             $self->{field_body}->clone:
                             $self->{field_body};
  ## Common hash value (not used in this module)
  $clone->{value} = ref $self->{value}?
                        $self->{value}->clone:
                        $self->{value};
  for my $i (@{$self->{comment}}) {
    if (ref $self->{comment}->[$i] eq 'HASH') {
      $clone->{comment}->[$i] = {%{$self->{comment}->[$i]}};
    } elsif (ref $self->{comment}->[$i] eq 'ARRAY') {
      $clone->{comment}->[$i] = [@{$self->{comment}->[$i]}];
    } else {
      $clone->{comment}->[$i] = $self->{comment}->[$i];
    }
  }
  $clone;
}


=head1 EXAMPLE

  use Message::Field::Structured;
  
  my $field_body = '"This is an example of <\"> (quotation mark)."
                    (Comment within \q\u\o\t\e\d\-\p\a\i\r\(\s\))';
  my $field = Message::Field::Structured->parse ($field_body);
  
  print $field->as_plain_string;

=head1 SEE ALSO

=over 4

=item L<Message::Entity>, L<Message::Header>

=item L<Message::Field::Unstructured>

=item RFC 2822 E<lt>urn:ietf:rfc:2822E<gt>, usefor-article, HTTP/1.0, HTTP/1.1

=back

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
