
=head1 NAME

Message::MIME::Charset::Encode --- Encode module plug-in for Message::* Perl Modules

=head1 DESCRIPTION

Message::* therselves don't convert coding systems of parts of
messages, but have mechanism to define to call external functions.
This module provides such macros for Encode modules.

=head1 USAGE

  use Message::MIME::Charset::Encode;

=cut

package Message::MIME::Charset::Encode;
use strict;
use vars qw(%CODE $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::MIME::Charset;
require Encode;

$CODE{internal} = 'utf-8';
$CODE{input} = '7bitjis';
$CODE{output} = '7bitjis';

sub import ($;%) {
  shift;
  Message::MIME::Charset::make_charset ('*undef' =>
    encoder	=> sub {
      my ($name, $s) = @_;
      $name = $CODE{output} if $name =~ /\*/;
      unless (Encode::find_encoding ($name)) {
        Message::MIME::Charset::_utf8_off ($s);
        return ($s, success => 0);
      }
      return (Encode::encode ($name, $s), success => 1);
    },
    decoder	=> sub {
      my ($name, $s) = @_;
      $name = $CODE{input} if $name =~ /\*/;
      #unless ($name) {
      #  use Encode::Guess qw/utf-8 iso-8859-1 iso-2022-jp/;
      #  $name = Encode::Guess->guess ($s);
      #  return ($name->decode ($s), success => 1) if ref $name;
      #}
      return ($s, success => 0) unless Encode::find_encoding ($name);
      return (Encode::decode ($name, $s), success => 1);
    }
  );
  Message::MIME::Charset::make_charset ('*default' => alias_of => '*undef');
}

=head1 EXAMPLE

  use Message::MIME::Charset::Encode;
  $Message::MIME::Charset::Encode::CODE{input} = 'euc-jp';
  $Message::MIME::Charset::Encode::CODE{output} = 'iso-2022-jp';
  require Message::Entity;
  #...

=head1 SEE ALSO

Message::MIME::Charset

Message::Entity

Encode

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
$Date: 2002/07/22 02:43:53 $

=cut

1;
