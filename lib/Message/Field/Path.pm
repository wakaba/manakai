
=head1 NAME

Message::Field::Path -- Perl module for C<Path:> header 
field body of Usenet news format messages

=cut

package Message::Field::Path;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
use Carp;

use overload '@{}' => sub {shift->{path}},
             '""' => sub {shift->stringify};

*REG = \%Message::Util::REG;
$REG{delimiter} = qr/[^0-9A-Za-z.:_-]+/;
$REG{delimiter_char} = qr#[!%,/?]#;
$REG{path_identity} = qr/[0-9A-Za-z.:_-]+/;
$REG{NON_delimiter} = qr#[^!%,/?]#;
$REG{NON_path_identity} = qr/[^0-9A-Za-z.:_-]/;


=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    -check_path_identity	=> 1,
    -max_line_length	=> 50,
    -output_obs_delimiter	=>  -1,
  );
  $self->SUPER::_init (%DEFAULT, %options);
  my @a = ();
  for (grep {/^[^-]/} keys %options) {
    push @a, $_ => $options{$_};
  }
  $self->add (@a) if $#a > -1;
}

=item $p = Message::Field::Path->new ([%options])

Constructs a new object.  You might pass some 
options as parameters to the constructor.

=cut

## Inherited

=item $p = Message::Field::Path->parse ($field-body, [%options])

Constructs a new object with given field body.  
You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $fbody = shift;
  $self->_init (@_);
  my @p = ();
  $fbody =~ s{^$REG{FWS}($REG{path_identity})}{
    push @p, [$1, ''];
    '';
  }ex;
  $fbody =~ s{($REG{delimiter})($REG{path_identity})}{
    my ($delimiter, $path_identity) = ($1, $2);
    $delimiter =~ tr/\x09\x20//d;
    push @p, [$path_identity, $delimiter];
    '';
  }gex;
  $self->{path} = \@p;
  $self;
}

=back

=head1 METHODS

=over 4

=item $p->add ($path-identity, [$delimiter], [%options])

Adds new C<path-identity> and C<delimiter> (optional).
Only one option, C<check_path_identity> is available.

See also L<EXAMPLE>.

=cut

sub add ($%) {
  my $self = shift;
  my %p = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  for (grep {/^[^-]/} keys %p) {
    croak "add: $_: invalid path-identity"
      if $option{check_path_identity} && $_ =~ /$REG{NON_path_identity}/;
    unshift @{$self->{path}}, [$_, ''];
    $self->{path}->[1]->[1] = $p{$_} if $#{$self->{path}} > 0;
  }
}


=item $p->path_identity ($index)

Returns C<$index>'th C<path-identity>, if any.
You can't set value.  (Is it necessary?)  Use C<add> method
to add new C<path-identity>.

=cut

sub path_identity ($$) {
  my $self = shift;
  my $i = shift;
  $self->{path}->[$i]->[0] if ref $self->{path}->[$i];
}

=item $p->delimiter ($index)

Returns C<$index>'th C<delimiter>, if any.
You can't set new value.  (Is it necessary?)

Note that C<$self-E<gt>delimiter (0)> would return
no value in most situation.

=cut

sub delimiter ($$) {
  my $self = shift;
  my $i = shift;
  $self->{path}->[$i]->[1] if ref $self->{path}->[$i];
}

=item $p->stringify ([%options])

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = %{$self->{option}};  my %p = @_;
  for (grep {/^-/} keys %p) {$option{substr ($_, 1)} = $p{$_}}
  my ($r, $l) = ('', 0);
  for (@{$self->{path}}) {
    my ($path_identity, $delimiter) = (${$_}[0], ${$_}[1] || '!');
    next unless $path_identity;
    next if $option{check_path_identity}
            && $path_identity =~ /$REG{NON_path_identity}/;
    if ($l) {
      $delimiter = '!' if !$option{output_obs_delimiter}
                          && $delimiter !~ /^$REG{delimiter_char}$/;
      if ($option{max_line_length} && $l > $option{max_line_length}) {
        $delimiter .= ' ';  $l = 0;
      }
      $r .= $delimiter;  $l += length $delimiter;
    }
    $r .= $path_identity;  $l += length $path_identity;
  }
  $r;
}

=item $option-value = $p->option ($option-name)

Gets option value.

=item $p->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited

=item $clone = $p->clone ()

Returns a copy of the object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = $self->SUPER::clone;
  my @p;
  for (@{$self->{path}}) {
    my $id = ref $_->[0]? $_->[0]->clone: $_->[0];
    my $dl = ref $_->[1]? $_->[1]->clone: $_->[1];
    push @p, [$id, $dl];
  }
  $clone->{path} = \@p;
  $clone;
}

=head1 NOTE

C<stringify> of this module insert SPACE when C<Path-content>
is too long.  ("long" is determined by the value of option
C<max_line_length>.)  This is intended to be able to fold
C<Path:> field body.  But some of implementions does not support
folding this line though article format specifications 
(except son-of-RFC1036) allow to insert white-space character.

Implementor shold set value of C<max_line_length> as long as
possible.  (Default value C<50> can be too small...)
When C<max_line_length> is C<-1>, C<stringify> does not
insert any white-space characters.

=head1 EXAMPLE

  use Message::Field::Path;
  
  ## Parse Path: field-body and print path-identity list.
  my $path = 'foo.isp.example/foo-server/bar.isp.example?'
            .'10.123.12.2/old.site.example!barbaz/baz.isp.example'
            .'%dialup123.baz.isp.example!x';
  my $p = Message::Field::Path->parse ($path);
  
  for my $i (0..$#$p) {
    print $p->delimiter ($i), "\t", $p->path_identity ($i), "\n";
  }
  
  ## Compose new Path: header field content.  (You won't do
  ## such stupid operation usually.  This is only an example.)
  my $p = new Message::Field::Path;
  $p->add ('not-for-mail');
  $p->add ('spool.foo.example', '!');
  $p->add ('injecter.foo.example', '%');
  $p->add ('news.local.example' => '/' => 'news.bar.example' => '/');
  print "Path: ", fold ($p), "\n";	## fold() is assumed as a function to fold
  # Path: news.local.example/news.bar.example/injecter.foo.example%
  #   spool.foo.example!not-for-mail

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
$Date: 2002/04/13 01:33:54 $

=cut

1;
