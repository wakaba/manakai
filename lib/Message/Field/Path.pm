
=head1 NAME

Message::Field::Path Perl module

=head1 DESCRIPTION

Perl module for C<Path:> header field.

=cut

package Message::Field::Path;
use strict;
use vars qw(%REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use overload '@{}' => sub {shift->{path}},
             '""' => sub {shift->stringify};
require Message::Util;
use Carp;
$REG{WSP} = qr/[\x20\x09]+/;
$REG{FWS} = qr/[\x20\x09]*/;

$REG{delimiter} = qr/[^0-9A-Za-z.:_-]+/;
$REG{delimiter_char} = qr#[!%,/?]#;
$REG{path_identity} = qr/[0-9A-Za-z.:_-]+/;
$REG{NON_delimiter} = qr#[^!%,/?]#;
$REG{NON_path_identity} = qr/[^0-9A-Za-z.:_-]/;

my %DEFAULT = (
  check_invalid_path_identity	=> 1,
  max_line_length	=> 50,
  output_obs_delimiter	=>  -1,
);

=head2 Message::Field::Path->new ()

Returns new instance for Message::Field::Path.

=cut

sub new ($;%) {
  my $self = bless {option => {@_}, path => []}, shift;
  for (%DEFAULT) {$self->{option}->{$_} ||= $DEFAULT{$_}}
  $self;
}

=head2 Message::Field::Path->parse ($unfolded-field-body)

Parses C<field-body> as C<Path> field.

=cut

sub parse ($$;%) {
  my $self = bless {}, shift;
  my $fbody = shift;
  my %option = @_;
  for (%DEFAULT) {$option{$_} ||= $DEFAULT{$_}}
  $self->{option} = \%option;
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

=head2 $self->add ($path-identity, [$delimiter], [%options])

Adds new C<path-identity> and C<delimiter> (optional).
Only one option, C<check_invalid_path_identity> is available.

See also L<EXAMPLE>.

=cut

sub add ($$;$%) {
  my $self = shift;
  my ($path_identity, $delimiter, %option) = (@_);
  $option{check_invalid_path_identity}
    ||= $self->{option}->{check_invalid_path_identity};
  croak "add: $path_identity: invalid path-identity"
    if $option{check_invalid_path_identity}>0 
       && $path_identity =~ /$REG{NON_path_identity}/;
  unshift @{$self->{path}}, [$path_identity, ''];
  $self->{path}->[1]->[1] = $delimiter if $#{$self->{path}} > 0;
  $self;
}

=head2 $self->path_identity ($index)

Returns C<$index>'th C<path-identity>, if any.
You can't set value.  (Is it necessary?)  Use C<add> method
to add new C<path-identity>.

=cut

sub path_identity ($$) {
  my $self = shift;
  my $i = shift;
  $self->{path}->[$i]->[0] if ref $self->{path}->[$i];
}

=head2 $self->delimiter ($index)

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

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{check_invalid_path_identity}
    ||= $self->{option}->{check_invalid_path_identity};
  $option{max_line_length} ||= $self->{option}->{max_line_length};
  $option{output_obs_delimiter} ||= $self->{option}->{output_obs_delimiter};
  my ($r, $l) = ('', 0);
  for (@{$self->{path}}) {
    my ($path_identity, $delimiter) = (${$_}[0], ${$_}[1] || '!');
    next unless $path_identity;
    next if $option{check_invalid_path_identity}>0 
            && $path_identity =~ /$REG{NON_path_identity}/;
    if ($l) {
      $delimiter = '!' if $option{output_obs_delimiter}<0 
                          && $delimiter !~ /^$REG{delimiter_char}$/;
      if ($option{max_line_length}>0 && $l > $option{max_line_length}) {
        $delimiter .= ' ';  $l = 0;
      }
      $r .= $delimiter;  $l += length $delimiter;
    }
    $r .= $path_identity;  $l += length $path_identity;
  }
  $r;
}

=head2 $self->option ($option_name, [$option_value])

Set/gets new value of the option.

=cut

sub option ($$;$) {
  my $self = shift;
  my ($name, $value) = @_;
  if (defined $value) {
    $self->{option}->{$name} = $value;
  }
  $self->{option}->{$name};
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
  $p->add ('news.bar.example', '/');
  $p->add ('news.local.example', '/');
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
$Date: 2002/04/02 11:52:12 $

=cut

1;
