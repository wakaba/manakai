
=head1 NAME

Message::Body::Multipart --- Perl module
for "multipart/*" Internet Media Types

=cut

package Message::Body::Multipart;
use strict;
use vars qw(%DEFAULT @ISA $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Body::Text;
push @ISA, qw(Message::Body::Text);

my @BCHARS = ('0'..'9', 'A'..'Z', 'a'..'z', qw#+ _ , - . / : =#);
#my @BCHARS = ('0'..'9', 'A'..'Z', 'a'..'z', qw#' ( ) + _ , - . / : = ?#, ' ');	## RFC 2046
my %REG;
$REG{NON_bchars} = qr#[^0-9A-Za-z'()+_,-./:=?\x20]#;

%DEFAULT = (
	## "#i" : only inherited from parent Entity and inherits to child Entity
  -_ARRAY_NAME	=> 'value',
  -_METHODS	=> [qw|entity_header add delete count item preamble epilogue|],
  -_MEMBERS	=> [qw|boundary preamble epilogue|],
  #i accept_cte
  #i body_default_charset
  #i body_default_charset_input
  #i cte_default
  -default_media_type	=> 'text',
  -default_media_subtype	=> 'plain',
  -media_type	=> 'multipart',
  -media_subtype	=> 'mixed',
  #output_epilogue
  -parse_all	=> 0,
  #i text_coderange
  #use_normalization	=> 0,
  #use_param_charset	=> 0,
  -value_type	=> {},
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my $DEFAULT = Message::Util::make_clone (\%DEFAULT);
  my %option = @_;
  $self->SUPER::_init (%$DEFAULT, %option);
  
  unless (defined $self->{option}->{output_epilogue}) {
    $self->{option}->{output_epilogue} = $self->{option}->{format} !~ /http/;
  }
  $self->{option}->{value_type}->{body_part}->[1]->{-format}
    = 
  my @ilist = qw/accept_coderange body_default_charset body_default_charset_input cte_default text_coderange/;
  $self->{option}->{value_type}->{preamble} = ['Message::Body::TextPlain',
    {-media_type => 'text', -media_subtype => '/multipart-preamble'},
    \@ilist];
  $self->{option}->{value_type}->{body_part} = sub {['Message::Entity',
    {-format => $_[0]->{option}->{format} . '/' . 'mime-entity',
    -body_default_media_type => $_[0]->{option}->{default_media_type},
    -body_default_media_subtype => $_[0]->{option}->{default_media_subtype}},
    \@ilist]};
  $self->{option}->{value_type}->{epilogue} = ['Message::Body::TextPlain',
    {-media_type => 'text', -media_subtype => '/multipart-epilogue'},
    \@ilist];
  
  $self->{boundary} = $option{boundary};
  if (!length $self->{boundary} && ref $self->{header}) {
    my $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0);
    $self->{boundary} = $ct->parameter ('boundary') if ref $ct;
  }
}

=item $body = Message::Body::Multipart->new ([%options])

Constructs a new object.  You might pass some options as parameters 
to the constructor.

=cut

## Inherited

=item $body = Message::Body::Multipart->parse ($body, [%options])

Constructs a new object with given field body.  You might pass 
some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $body = shift;
  $self->_init (@_);
  my $b = $self->{boundary};
  if (length $b) {
    $self->{value} = [ split /\x0D\x0A--\Q$b\E[\x09\x20]*\x0D\x0A/, $body ];
    if (length $self->{value}->[0]) {
      my @p = split /(?:\x0D\x0A)?--\Q$b\E[\x09\x20]*\x0D\x0A/, $self->{value}->[0], 2;
      $self->{preamble} = $p[0];
      if (length $p[1]) {
        $self->{value}->[0] = $p[1];
      } else { shift (@{$self->{value}}) }
    }
    if (length $self->{value}->[-1]) {
      my @p = split /\x0D\x0A--\Q$b\E--[\x09\x20]*(?:\x0D\x0A)?/, $self->{value}->[-1], 2;
      $self->{value}->[-1] = $p[0];
      $self->{epilogue} = $p[1];
    }
  } else {
    $self->{preamble} = [ $body ];
  }
  if ($self->{option}->{parse_all}) {
    $self->{value} = [map {
      $self->_parse_value (body_part => $_);
    } @{$self->{value}}];
    $self->{preamble} = $self->_parse_value (preamble => $self->{preamble});
    $self->{epilogue} = $self->_parse_value (epilogue => $self->{epilogue});
  }
  $self;
}

=back

=cut

## add, item, delete, count

## item-by?, \$checked-item, {item-key => 1}, \%option
sub _item_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $i, $list, $option) = @_;
  return 0 unless ref $$i;  ## Already removed
  if ($by eq 'content-type') {
    $$i = $self->_parse_value (body_part => $$i);
    return 1 if ref $$i && $$list{$$i->content_type};
  } elsif ($by eq 'content-id') {
    $$i = $self->_parse_value (body_part => $$i);
    return 1 if ref $$i && ( $$list{$$i->id} || $$list{'<'.$$i->id.'>'} );
  }
  0;
}
*_delete_match = \&_item_match;

## Returns returned item value    \$item-value, \%option
sub _item_return_value ($\$\%) {
  unless (ref ${$_[1]}) {
    ${$_[1]} = $_[0]->_parse_value (body_part => ${$_[1]});
  }
  ${$_[1]};
}
*_add_return_value = \&_item_return_value;

## Returns returned (new created) item value    $name, \%option
sub _item_new_value ($$\%) {
  my $v = shift->_parse_value (body_part => '');
  my ($key, $option) = @_;
  if ($option->{by} eq 'content-type') {
    $v->header->field ('content-type')->media_type ($key);
  } elsif ($option->{by} eq 'content-id') {
    $v->header->add ('content-id' => $key);
  }
  $v;
}

sub _add_array_check ($$\%) {
  my $self = shift;
  my ($value, $option) = @_;
  my $value_option = {};
  if (ref $value eq 'ARRAY') {
    ($value, %$value_option) = @$value;
  }
  $value = $self->_parse_value (body_part => $value) if $$option{parse};
  $$option{parse} = 0;
  (1, value => $value);
}

## entity_header: Inherited

sub preamble ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $np = $self->_parse_value (preamble => $np) if $self->{option}->{parse_all};
    $self->{preamble} = $np;
  }
  $self->{preamble};
}
sub epilogue ($;$) {
  my $self = shift;
  my $np = shift;
  if (defined $np) {
    $np = $self->_parse_value (epilogue => $np) if $self->{option}->{parse_all};
    $self->{epilogue} = $np;
  }
  $self->{epilogue};
}

=head2 $self->stringify ([%option])

Returns the C<body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_;  my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my $max = $option{max} || $#{$self->{value}}+1;  $max--;
  $max = $#{$self->{value}} if $max > $#{$self->{value}};
  my @parts = map { ''. $_ } @{$self->{value}}[0..$max];
  my $b = $self->{boundary};
  if ($b =~ $REG{NON_bchars} || length ($b) > 70) {
    undef $b;
  } elsif (substr ($b, -1, 1) eq "\x20") {
    $b .= 'B';
  }
  my $blength = 45;
  $b ||= $self->_generate_boundary ($blength);
  my $i = 1; while ($i++) {
    my @t = grep {/\Q--$b\E/} @parts;
    last if @t == 0;
    $b = $self->_generate_boundary ($blength);
    if ($i > @BCHARS ** $blength) {
      $blength++; $i = 1;
    }
  }
  if (ref $self->{header}) {
    $self->{header}->field ('content-type')->parameter (boundary => $b);
  }
  $self->{preamble}."\x0D\x0A--".$b."\x0D\x0A".
  join ("\x0D\x0A--".$b."\x0D\x0A", @parts)
  ."\x0D\x0A--$b--\x0D\x0A".
  ($option{output_epilogue}? $self->{epilogue}: '');
}
*as_string = \&stringify;

## Inherited: option, clone

## $self->_option_recursive (\%argv)
sub _option_recursive ($\%) {
  my $self = shift;
  my $o = shift;
  for (@{$self->{value}}) {
    $_->option (%$o) if ref $_;
  }
  $self->{preamble}->option (%$o) if ref $self->{preamble};
  $self->{epilogue}->option (%$o) if ref $self->{epilogue};
}

sub _generate_boundary ($$) {
  my $self = shift;
  my $blength = shift || 45;	## Length of boundary
  join('', map($BCHARS[rand @BCHARS], 1..$blength));
}

=head1 SEE ALSO

RFC 2046 <urn:ietf:rfc:2046>

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
$Date: 2002/06/11 12:58:06 $

=cut

1;
