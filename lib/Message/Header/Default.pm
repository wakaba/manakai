
=head1 NAME

Message::Header::Default --- Internet Messages -- Definition
for Default Namespace of Header Fields

=cut

package Message::Header::Default;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Header;

our %OPTION;

## Case sensibility of field name
$OPTION{case_sensible} = 1;
#$OPTION{to_be_goodcase} = \&...;
$OPTION{n11n_name} = \&_name_n11n;
$OPTION{n11n_prefix} = \&_name_n11n;

## Namespace URI of this namespace
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:default';

## Force & hyphened prefix name of this namespace (ex. "prefix-name")
$OPTION{namespace_phname} = 'default';
$OPTION{namespace_phname_goodcase} = 'default';

## `Good' & dotted prefix name of this namespace (ex. "prefix.name", "prefix2.name")
$OPTION{namespace_good_prefix} = 'DEFAULT';

## Field body data type (specified by package name)
$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
};

## mailto: URL safe level
$OPTION{uri_mailto_safe}	= {
  ## 1 all (no check)	2 no trace & bcc & from
  ## 3 no sender's info	4 (default) (currently not used)
  ## 5 only a few
	':default'	=> 1,
};

## 

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

## $self->_goodcase ($namespace_package_name, $field_name, \%option)
sub _goodcase ($$$\%) {
  no strict 'refs';
  my $self = shift;
  my ($nspack, $name, $option) = @_;
  if (${$nspack.'::OPTION'}{goodcase}->{$name}) {
    return ${$nspack.'::OPTION'}{goodcase}->{$name};
  }
  $name =~ s/(?:^|-)[a-z]/uc $&/ge;
  $name;
}

sub _name_n11n ($$$) {
  no strict 'refs';
  my $self = shift;
  my $nspack = shift;
  my $name = shift;
  unless (${$nspack.'::OPTION'}{case_sensible}) {
    lc $name;
  } else {
    $name;
  }
}

package Message::Header::XCGI;
our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:http:cgi:x';
$OPTION{namespace_phname} = 'x-cgi';
$OPTION{namespace_phname_goodcase} = 'X-CGI';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;


## 

require Message::Header::RFC822;
require Message::Header::HTTP;

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
$Date: 2002/07/06 10:29:31 $

=cut

1;
