
=head1 NAME

Message::Field::UA -- Perl module for Internet message
header field body consist of C<product> tokens

=cut

require 5.6.0;
package Message::Field::UA;
use strict;
use re 'eval';
use vars qw(%DEFAULT @ISA %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.12 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Field::Structured;
push @ISA, qw(Message::Field::Structured);
use overload '.='	=> sub { 
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

*REG = \%Message::Util::REG;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_HASH_NAME	=> 'product',
    -_METHODS	=> [qw|add count delete item|],
    -_MEMBERS	=> [qw|product|],
    -by	=> 'product-name',	## Default key for item, delete,...
    #encoding_after_encode
    #encoding_before_decode
    #field_param_name
    #field_name
    #format
    #hook_encode_string
    #hook_decode_string
    -prepend	=> 1,	## For add, replace
    -use_Config	=> 1,
    -use_comment	=> 1,
    #-use_quoted_string	=> 1,
    -use_Win32	=> 1,
);

=head1 CONSTRUCTORS

The following methods construct new objects:

=over 4

=cut

## Initialize of this class -- called by constructors
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->SUPER::_init (%DEFAULT, %options);
  
  unless (defined $self->{option}->{use_quoted_string}) {
    if ($self->{option}->{format} =~ /http/) {
      $self->{option}->{use_quoted_string} = 0;
    } else {
      $self->{option}->{use_quoted_string} = 1;
    }
  }
  
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
  $field_body =~ s{
  	($REG{quoted_string}|[^\x09\x20\x22\x28\x2F]+)	## product-name
  	(?:
  	  ((?:$REG{FWS}$REG{comment})*)$REG{FWS}
  	  /
  	  ((?:$REG{FWS}$REG{comment})*)$REG{FWS}
  	  ($REG{quoted_string}|[^\x09\x20\x22\x28]+)	## product-version
  	)?
  	((?:$REG{FWS}$REG{comment})*)	## comment
  }{
    my ($product, $product_version, $comments) = ($1, $4, $2.$3.$5);
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

=cut


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

sub _add_hash_check ($$$\%) {
  my $self = shift;
  my ($name, $version, $option) = @_;
  my @comment;
  if (ref $version eq 'ARRAY') {
    ($version, @comment) = @$version;
  }
  
  ## Convert vX.Y.Z value to string (But there is no way to be sure that 
  ## the value is a version value.)
  #$^V gt v5.6.0 && 	## <- This check itself doesn't work before v5.6.0:)
  if ($version =~ /[\x00-\x1F]/) {
    $version = sprintf '%vd', $version;
  }
  
  (1, $name => {
    name	=> $name,
    version	=> $version,
    comment	=> \@comment,
  });
}

*_add_return_value = \&_replace_return_value;

## (1/0, $name => $value) = $self->_replace_hash_check ($name => $value, \%option)
## -- Checks given value and prepares saving value (hash version)
*_replace_hash_check = \&_add_hash_check;


## $value = $self->_replace_hash_shift (\%values, $name, $option)
## -- Returns a value (from %values) and deletes it from %values
##    (like CORE::shift for array).
sub _replace_hash_shift ($\%$\%) {
  shift; my $r = shift;  my $n = $_[0]->{name};
  if ($$r{$n}) {
    my $d = $$r{$n};
    $$r{$n} = undef;
    return $d;
  }
  undef;
}

## $value = $self->_replace_return_value (\$item, \%option)
## -- Returns returning value of replace method
sub _replace_return_value ($\$\%) {
  my $self = shift;
  my ($item, $value) = @_;
  $$item;
}

## 1/0 = $self->_delete_match ($by, \$item, \%delete_list, \%option)
## -- Checks and returns whether given item is matched with
##    deleting item list
sub _delete_match ($$\$\%\%) {
  my $self = shift;
  my ($by, $item, $list, $option) = @_;
  return 0 unless ref $$item;	## Already removed
  if ($by eq 'name') {
    return 1 if $$list{ $$item->{name} };
  } elsif ($by eq 'version') {
    return 1 if $$list{ $$item->{version} };
  }
  0;
}

## Delete empty items
sub _delete_empty ($) {
  my $self = shift;
  my $array = $self->{option}->{_HASH_NAME};
  $self->{ $array } = [grep { ref $_ } @{$self->{ $array }}] if $array;
}

*_item_match = \&_delete_match;
*_item_return_value = \&_replace_return_value;

## $item = $self->_item_new_value ($name, \%option)
## -- Returns new item with key of $name (called when
##    no returned value is found and -new_value_unless_exist
##    option is true)
sub _item_new_value ($$\%) {
  my $self = shift;
  my ($key, $option) = @_;
  if ($option->{by} eq 'name') {
    return {name => $key, version => '', comment => []};
  } elsif ($option->{by} eq 'version') {
    return {name => '', version => $key, comment => []};
  }
  undef;
}

## TODO: Implement count,item_exist method

=item $self->stringify ()

Returns C<field-body> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %o = @_; my %option = %{$self->{option}};
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  my @r = ();
  for my $p (@{$self->{product}}) {
    if (length $p->{name}) {
      my %name = &{$self->{option}->{hook_encode_string}} ($self, 
         $p->{name}, type => 'token');
      my %version = &{$self->{option}->{hook_encode_string}} ($self, 
         $p->{version}, type => 'token');
      if (!$option{use_quoted_string}
        && (  $name{value} =~ /$REG{NON_http_token}/
           || $version{value} =~ /$REG{NON_http_token}/)) {
        if ($name{value} =~ /$REG{NON_http_token}/) {
        ## Both of name & version are unsafe
          push @r, '(' . Message::Util::quote_ccontent (
            $name{value} .
            (length $version{value}? '/' . $version{value} : '')
          ) . ')';
        } else {
        ## Only version is unsafe
          push @r, $name{value}
            .' (' . Message::Util::quote_ccontent ($version{value}) . ')';
        }
      } else {
        push @r, 
          Message::Util::quote_unsafe_string
            ($name{value}, unsafe => 'NON_http_token')
          .(length $version{value} ?
          '/' . Message::Util::quote_unsafe_string
            ($version{value}, unsafe => 'NON_http_token') : '');
      }
    } elsif ($p->{version}) {
    ## There is no product-name but the product-version.  It's error!
      push @r, '('. $self->Message::Util::encode_ccontent ($p->{version}) .')';
    }
    ## If there are some additional information,
    for (@{$p->{comment}}) {
      push @r, '('. $self->Message::Util::encode_ccontent ($_) .')' if $_;
    }
  }
  join ' ', @r;
}
*as_string = \&stringify;

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

## Inherited

sub add_our_name ($;%) {
  my $ua = shift;
  my %o = @_;  my %option = %{ $ua->{option} };
  for (grep {/^-/} keys %o) {$option{substr ($_, 1)} = $o{$_}}
  
  if ($Message::Entity::VERSION) {
    $ua->replace_rcs ($option{date}, name => 'Message-pm', 
                      version => $Message::Entity::VERSION, 
                      -prepend => 0);
  }
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
      undef $@;
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

sub add_rcs ($$;%) {
  my $self = shift;
  my ($rcsid, %option) = @_;
  my ($name, $version, $date) = ($option{name}, $option{version}, $option{date});
  for (grep {/^[^-]/} keys %option) { delete $option{$_} }
  if ($rcsid =~ m!(?:Id|Header): (?:.+?/)?([^/]+?),v ([\d.]+) (\d+/\d+/\d+ \d+:\d+:\d+)!) {
    $name ||= $1;
    $version ||= $2;
    $date ||= $3;
  } elsif ($rcsid =~ m!^Date: (\d+/\d+/\d+ \d+:\d+:\d+)!) {
    $date ||= $1;
  } elsif ($rcsid =~ m!^Revision: ([\d.]+)!) {
    $version ||= $1;
  } elsif ($rcsid =~ m!(?:Source|RCSfile): (?:.+?/)?([^/]+?),v!) {
    $name ||= $1;
  }
  if ($option{is_replace}) {
    $self->replace ($name => [$version, $date], %option);
  } else {
    $self->add ($name => [$version, $date], %option);
  }
}
sub replace_rcs ($$;%) {
  shift->add_rcs (@_, is_replace => 1);
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
$Date: 2002/07/30 08:50:36 $

=cut

1;
