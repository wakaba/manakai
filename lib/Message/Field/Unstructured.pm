
=head1 NAME

Message::Field::Structured -- Perl module for
unstructured header field bodies of the Internet message

=cut

package Message::Field::Unstructured;
use strict;
use vars qw(%DEFAULT $VERSION);
$VERSION=do{my @r=(q$Revision: 1.7 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
use overload '""' => sub { $_[0]->stringify },
             '.=' => sub { $_[0]->value_append ($_[1]) },
             #'eq' => sub { $_[0]->{field_body} eq $_[1] },
             #'ne' => sub { $_[0]->{field_body} ne $_[1] },
             fallback => 1;


## Initialize of this class -- called by constructors
  %DEFAULT = (
    _METHODS	=> [qw|value value_append|],
    _MEMBERS	=> [qw|_charset|],
    encoding_after_encode	=> '*default',
    encoding_before_decode	=> '*default',
    field_param_name	=> '',
    field_name	=> 'x-structured',
    #field_ns	=> '',
    format	=> 'mail-rfc2822',
    ## MIME charset name of '*default' charset
      header_default_charset	=> 'iso-2022-int-1',
      header_default_charset_input	=> 'iso-2022-int-1',
    hook_encode_string	=> #sub {shift; (value => shift, @_)},
    	\&Message::Util::encode_header_string,
    hook_decode_string	=> #sub {shift; (value => shift, @_)},
    	\&Message::Util::decode_header_string,
    internal_charset_name	=> 'utf-8',
  );
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = Message::Util::make_clone (\%DEFAULT);
  $self->{value} = '';
  
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } elsif ($name eq 'body') {
      $self->{value} = $options{$name};
    }
  }
}

=head1 CONSTRUCTORS

The following methods construct new C<Message::Field::Unstructured> objects:

=over 4

=item Message::Field::Unstructured->new ([%options])

Constructs a new C<Message::Field::Unstructured> object.  You might pass some 
options as parameters to the constructor.

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  $self;
}

=item Message::Field::Unstructured->parse ($field-body, [%options])

Constructs a new C<Message::Field::Unstructured> object with
given field body.  You might pass some options as parameters to the constructor.

Although name, this method doesn't parse C<$field-body> (first
argument) since there is no need to parse unstructured field body:-)

=cut

sub parse ($$;%) {
  my $class = shift;
  my $field_body = shift;
  my $self = bless {}, $class;
  $self->_init (@_);
  my %s = &{$self->{option}->{hook_decode_string}} ($self,
    $field_body,
    type => 'text',
    charset	=> $option->{encoding_before_decode},
  );
  if ($s{charset}) {	## Convertion failed
    $self->{_charset} = $s{charset};
  } elsif (!$s{success}) {
    $self->{_charset} = $self->{option}->{header_default_charset_input};
  }
  $self->{value} = $s{value};
  $self;
}

=back

=head1 METHODS

=over 4

=item $self->stringify ([%options])

Returns field body as a string.  Returned string is encoded
if necessary (by C<hook_encode_string>).

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  if ($self->{_charset}) {
    $self->{value};
  } else {
    my (%e) = &{$option{hook_encode_string}} ($self,
      $self->{value},
      charset => $option{encoding_after_encode},
      current_charset => $option{internal_charset},
      type => 'text',
    );
    $e{value};
  }
}
*as_string = \&stringify;

=item $self->value ([$new-value])

Set/gets current value of this field.  Returned/given value
should not be encoded (i.e. in internal code).

=cut

sub value ($;$) {
  my $self = shift;
  my $v = shift;
  if (defined $v) {
    $self->{value} = $v;
  }
  $self->{value};
}
*as_plain_string = \&value;

sub value_append ($$) {
  $_[0]->{field_body} .= $_[1];
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
  my %option = @_;
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $self->{option}->{$name} = $value;
  }
  if ($option{-recursive}) {
    $self->_option_recursive (\%option);
  }
  $self;
}

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {}

=item $self->clone ()

Returns a copy of Message::Field::Unstructured object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = ref ($self)->new;
  $clone->{option} = Message::Util::make_clone ($self->{option});
  $clone->{value} = Message::Util::make_clone ($self->{value});
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

=head1 SEE ALSO

=over 4

=item L<Message::Entity>, L<Message::Header>

=item L<Message::Field::Structured>

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
$Date: 2002/08/01 06:42:38 $

=cut

1;
