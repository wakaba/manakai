
=head1 NAME

Message::Field::UA -- Perl module for Internet message
header field body consist of C<product> tokens

=cut

package Message::Field::UA;
use strict;
use vars qw(@ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.9 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Util;
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
use overload '""'	=> sub { $_[0]->stringify },
             '@{}'	=> sub { $_[0]->product },
             '.='	=> sub { 
             	if (ref $_[1] eq 'HASH') {
             	  $_[0]->add (%{$_[1]});
             	} elsif (ref $_[1] eq 'ARRAY') {
             	  $_[0]->add (@{$_[1]});
             	} else {
             	  $_[0]->add ($_[1] => '', -prepend => 0);
             	}
             	$_[0];
             },
             fallback	=> 1;

%REG = %Message::Util::REG;
$REG{product} = qr#(?:$REG{http_token}|$REG{quoted_string})(?:$REG{FWS}/$REG{FWS}(?:$REG{http_token}|$REG{quoted_string}))?#;
$REG{M_product} = qr#($REG{http_token}|$REG{quoted_string})(?:$REG{FWS}/$REG{FWS}($REG{http_token}|$REG{quoted_string}))?#;

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  my %DEFAULT = (
    #encoding_after_encode	## Inherited
    #encoding_before_decode	## Inherited
    -field_name	=> 'user-agent',
    #format	## Inherited
    #hook_encode_string	## Inherited
    #hook_decode_string	## Inherited
    -prepend	=> 1,
    -use_Config	=> 1,
    -use_Win32	=> 1,
  );
  $self->SUPER::_init (%DEFAULT, %options);
  my @a = ();
  for (grep {/^[^-]/} keys %options) {
    push @a, $_ => $options{$_};
  }
  $self->add (@a) if $#a > -1;
}

=item $ua = Message::Field::UA->new ([%options])

Constructs a new C<Message::Field::UA> object.  You might pass some 
options as parameters to the constructor.

=cut

## Inherited

=item $ua = Message::Field::UA->parse ($field-body, [%options])

Constructs a new C<Message::Field::UA> object with
given field body.  You might pass some options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my $field_body = shift;  my @ua = ();
  $self->_init (@_);
  $field_body =~ s{^((?:$REG{FWS}$REG{comment})+)}{
    my $comments = $1;
    $comments =~ s{$REG{M_comment}}{
      my $comment = $self->Message::Util::decode_ccontent ($1);
      push @ua, {comment => [$comment]} if $comment;
    }goex;
    '';
  }goex;
  $field_body =~ s{$REG{M_product}((?:$REG{FWS}$REG{comment})*)}{
    my ($product, $product_version, $comments) = ($1, $2, $3);
    for ($product, $product_version) {
      my ($s,$q) = (Message::Util::unquote_if_quoted_string ($_), 0);
      my %s = &{$self->{option}->{hook_decode_string}} ($self, $s,
                type => ($q?'token/quoted':'token'));	## What token/quoted is? :-)
      $_ = $s{value};
    }
    my @comment = ();
    $comments =~ s{$REG{M_comment}}{
      my $comment = $self->Message::Util::decode_ccontent ($1);
      push @comment, $comment if $comment;
    }goex;
    push @ua, {name => $product, version => $product_version, 
               comment => \@comment};
  }goex;
  push @{$self->{product}}, @ua;
  $self;
}

=back

=head1 METHODS

=over 4

=item $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %option = @_;
  $option{format} ||= $self->{option}->{format};
  my @r = ();
  for my $p (@{$self->{product}}) {
    if ($p->{name}) {
      if ($option{format} eq 'http'
        && (  $p->{name} =~ /$REG{NON_http_token}/
           || $p->{version} =~ /$REG{NON_http_token}/)) {
        my $f = $p->{name};
        $f .= '/'.$p->{version} if $p->{version};
        push @r, '('. $self->encode_ccontent ($f) .')';
      } else {
        my %e = &{$self->{option}->{hook_encode_string}} ($self, 
           $p->{name}, type => 'token');
        my %f = &{$self->{option}->{hook_encode_string}} ($self, 
           $p->{version}, type => 'token');
        push @r, 
          Message::Util::quote_unsafe_string ($e{value}, unsafe => 'NON_http_token')
          .($f{value} ? '/'
          .Message::Util::quote_unsafe_string ($f{value}, unsafe => 'NON_http_token')
          :'');
      }
    } elsif ($p->{version}) {	## Error!
      push @r, '('. $self->Message::Util::encode_ccontent ($p->{version}) .')';
    }
    for (@{$p->{comment}}) {
      push @r, '('. $self->Message::Util::encode_ccontent ($_) .')' if $_;
    }
  }
  join ' ', @r;
}
*as_string = \&stringify;

=item $array = $self->product

Returns array reference of C<product>s.  Each of array elements
are hash reference, and it has three key: C<name>, C<version>,
and C<comment>.  C<comment> is array reference.

Example:

  my $p = $ua->product->[0];
  printf "%s\t%s\t%s\n", $p->{name}, $p->{version}, join ('; ', @{$p->{comment}});

=cut

sub product ($;%) {
  my $self = shift;
  $self->_delete_empty;
  $self->{product};
}

=item $name = $ua->product_name ($index)

=item $version = $ua->product_version ($index)

Returns product-name/-version of C<$index>'th C<product>.

=cut

sub product_name ($;$%) {
  my $self = shift;
  my $index = shift;
  $self->{product}->[$index]->{product} if ref $self->{product}->[$index];
}

sub product_version ($;$%) {
  my $self = shift;
  my $index = shift;
  $self->{product}->[$index]->{product_version} if ref $self->{product}->[$index];
}

=item $comment_ref = $ua->product_comment ($index)

Returns array reference of C<comment> of C<$index>'th C<product>.
(You can edit this array.)

=cut

sub product_comment ($;$%) {
  my $self = shift;
  my $index = shift;
  $self->{product}->[$index]->{comment} if ref $self->{product}->[$index];
}

=item $hdr->add ($name, $version, [$name, $version, ...])

Adds some field name/version pairs.  Even if there are
one or more C<product>s whose name is same as C<$name>
(case sensible), given name/body pairs are ADDed.  Use C<replace>
to remove C<old> one.

Instead of C<$version>, you can pass array reference.
[0] is used for C<version>, the others are saved as elements
of C<comment>.

C<-prepend> options is available.  C<1> is default.

Example:

  $ua->add (Perl => [$^V, $^O], 'foo.pl' => $VERSION, -prepend => 0);
  print $ua;	# foo.pl/1.00 Perl/5.6.1 (MSWin32)

=cut

sub add ($%) {
  my $self = shift;
  my %products = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %products) {$option{substr ($_, 1)} = $products{$_}}
  for (grep {/^[^-]/} keys %products) {
    my $name = $_;
    my ($ver, $comment);
    if (ref $products{$_} eq 'ARRAY') {
      $ver = shift @{$products{$_}};
      $comment = $products{$_};
    } else {
      $ver = $products{$_};
      $comment = [];
    }
    ## BUG: binary unsafe:-) (ISO-2022-KR, UCS-2,... also can't treat)
    if ($ver =~ /[\x00-\x08\x0B\x0E-\x1A\x1C-\x1F\x7F]/) {
      $ver = sprintf '%vd', $ver;
    }
    if ($option{prepend}) {
      unshift @{$self->{product}}, {name => $name, version => $ver,
                                    comment => $comment};
    } else {
      push @{$self->{product}}, {name => $name, version => $ver,
                                 comment => $comment};
    }
  }
}

=item $hdr->replace ($field-name, $field-body, [$name, $body, ...])

Adds some field name/body pairs.  If there are already
one or more field with name of C<$field-name>, it is replaced 
by new one.

Instead of C<$version>, you can pass array reference.
[0] is used for C<version>, the others are saved as elements
of C<comment>.

C<-prepend> options is available.  C<1> is default.

=cut

sub replace ($%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my (%new_product);
  for (grep {/^[^-]/} keys %params) {
    my $name = $_;
    my ($ver, $comment);
    if (ref $params{$_} eq 'ARRAY') {
      $ver = shift @{$params{$_}};
      $comment = $params{$_};
    } else {
      $ver = $params{$_};
      $comment = [];
    }
    ## BUG: binary unsafe:-) (ISO-2022-KR, UCS-2,... also can't treat)
    if ($ver =~ /[\x00-\x08\x0B\x0E-\x1A\x1C-\x1F\x7F]/) {
      $ver = sprintf '%vd', $ver;
    }
    $new_product{$name} = {name => $name, version => $ver, comment => $comment};
  }
  for my $product (@{$self->{product}}) {
    if ($product->{name} && defined $new_product{$product->{name}}) {
      $product = $new_product {$product->{name}};
      $new_product{$product->{name}} = undef;
    }
  }
  for (keys %new_product) {
    push @{$self->{product}}, $new_product{$_};
  }
}

=item $ua->delete ($name, [$name, $name,...]);

Deletes C<product>s whose name is C<$name>.

=cut

sub delete ($@) {
  my $self = shift;
  my %delete;  for (@_) {$delete{$_} = 1}
  for my $product (@{$self->{product}}) {
    undef $product if $delete{$product->{name}};
  }
}

sub _delete_empty ($) {
  my $self = shift;
  my @nid;
  for my $id (@{$self->{product}}) {push @nid, $id if ref $id}
  $self->{product} = \@nid;
}

=item $option-value = $ua->option ($option-name)

Gets option value.

=item $ua->option ($option-name, $option-value, ...)

Set option value(s).  You can pass multiple option name-value pair
as parameter when setting.

=cut

## Inherited

=item $clone = $ua->clone ()

Returns a copy of the object.

=cut

sub clone ($) {
  my $self = shift;
  $self->_delete_empty;
  my $clone = $self->SUPER::clone;
  my @p;
  for (@{$self->{product}}) {
    my $name = ref $_->{name}? $_->{name}->clone: $_->{name};
    my $ver = ref $_->{version}? $_->{version}->clone: $_->{version};
    my @comment;
    for (@{$_->{comment}}) {
      push @comment, ref $_? $_->clone: $_;
    }
    push @p, {name => $name, version => $ver, comment => \@comment};
  }
  $clone->{product} = \@p;
  $clone;
}

sub add_our_name ($;%) {
  require Message::Entity;
  my $ua = shift;
  my %o = @_;  my %option = %{$ua->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  $option{date} =~ s/^Date:\x20//;  $option{date} =~ s/\x20$//;
  
    $ua->replace ('Message-pm' => [$Message::Entity::VERSION, $option{date}], -prepend => 0);
    my (@os, @os_comment);
    my @perl_comment;
    if ($option{use_Config}) {
      @os_comment = ('');
      @os = ($^O => \@os_comment);
      eval q{use Config;
        @os_comment = ($Config{osvers});
        push @perl_comment, $Config{archname};
      };
      eval q{use Win32;
        my $build = Win32::BuildNumber;
        push @perl_comment, "ActivePerl build $build" if $build;
        my @osv = Win32::GetOSVersion;
        @os = (
            $osv[4] == 0? 'Win32s':
            $osv[4] == 1? 'Windows':
            $osv[4] == 2? 'WindowsNT':
                          'Win32',       \@os_comment);
        @os_comment = (sprintf ('%d.%02d.%d', @osv[1,2], $osv[3] & 0xFFFF));
        push @os_comment, $osv[0] if $osv[0] =~ /[^\x09\x20]/;
        if ($osv[4] == 1) {
          if ($osv[1] == 4) {
            if ($osv[2] == 0) {
              if    ($osv[0] =~ /[Aa]/) { push @os_comment, 'Windows 95 OSR1' }
              elsif ($osv[0] =~ /[Bb]/) { push @os_comment, 'Windows 95 OSR2' }
              elsif ($osv[0] =~ /[Cc]/) { push @os_comment, 'Windows 95 OSR2.5' }
              else                      { push @os_comment, 'Windows 95' }
            } elsif ($osv[2] == 10) {
              if    ($osv[0] =~ /[Aa]/) { push @os_comment, 'Windows 98 SE' }
              else                      { push @os_comment, 'Windows 98' }
            } elsif ($osv[2] == 90) {
              push @os_comment, 'Windows Me';
            }
          }
        } elsif ($osv[4] == 2) {
          push @os_comment, 'Windows 2000' if $osv[1] == 5 && $osv[2] == 0;
          push @os_comment, 'Windows XP' if $osv[1] == 5 && $osv[2] == 1;
        }
        push @os_comment, Win32::GetChipName;
      } if $option{use_Win32};
    } else {
      push @perl_comment, $^O;
    }
    if ($^V) {	## 5.6 or later
      $ua->replace (Perl => [sprintf ('%vd', $^V), @perl_comment], -prepend => 0);
    } elsif ($]) {	## Before 5.005
      $ua->replace (Perl => [ $], @perl_comment], -prepend => 0);
    }
    $ua->replace (@os, -prepend => 0) if $option{use_Config};
  $ua;
}

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
$Date: 2002/07/13 09:27:35 $

=cut

1;
