
=head1 NAME

Message::Header::Default --- Internet Messages -- Definition
for Default Namespace of Header Fields

=cut

package Message::Header::Default;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Header;

our %OPTION;

## Case sensibility of field name
$OPTION{case_sensible} = 1;
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

## 

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

## $self->_goodcase ($namespace_package_name, $field_name)
sub _goodcase ($$$) {
  no strict 'refs';
  my $self = shift;
  my $nspack = shift;
  my $name = shift;
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

package Message::Header::RFC822;
our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail-rfc822';
$OPTION{namespace_phname} = 'rfc822';
$OPTION{namespace_phname_goodcase} = 'RFC822';

$OPTION{case_sensible} = 0;

$OPTION{goodcase} = {
	fax	=> 'FAX',
	'pics-label'	=> 'PICS-Label',
	'list-url'	=> 'List-URL',
	'list-id'	=> 'List-ID',
	'message-id'	=> 'Message-ID',
	'mime-version'	=> 'MIME-Version',
	'nic'	=> 'NIC',
	'nntp-posting-date'	=> 'NNTP-Posting-Date',
	'nntp-posting-host'	=> 'NNTP-Posting-Host',
	url	=> 'URL',
	'x-dearfriend'	=> 'X-DearFriend',
	'x-jsmail-priority'	=> 'X-JsMail-Priority',
	'x-mime-autoconverted'	=> 'X-MIME-Autoconverted',
	'x-mimeole'	=> 'X-MimeOLE',
	'x-msmail-priority'	=> 'X-MSMail-Priority',
	'x-nntp-posting-date'	=> 'X-NNTP-Posting-Date',
	'x-nntp-posting-host'	=> 'X-NNTP-Posting-Host',
	'x-uidl'	=> 'X-UIDL',
	'x-uri'	=> 'X-URI',
	'x-url'	=> 'X-URL',
};
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	'date'	=> ['Message::Field::Date'],
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::Resent;
our %OPTION = %Message::Header::RFC822::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail-rfc822:resent';
$OPTION{namespace_phname} = 'resent';
$OPTION{namespace_phname_goodcase} = 'Resent';
$OPTION{namespace_phname_regex} = 'resent';

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::Content;
our %OPTION = %Message::Header::RFC822::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail-mime-entity';
$OPTION{namespace_phname} = 'content';
$OPTION{namespace_phname_goodcase} = 'Content';
$OPTION{namespace_phname_regex} = 'content';

$OPTION{goodcase} = {
	'id'	=> 'ID',
	'md5'	=> 'MD5',
	'sgml-entity'	=> 'SGML-Entity',
};

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	alias	=> ['Message::Field::URI'],
	base	=> ['Message::Field::URI'],
	disposition	=> ['Message::Field::ValueParams'],
	features	=> ['Message::Field::Structured'],
	id	=> ['Message::Field::MsgID'],
	length	=> ['Message::Field::Numval'],
	location	=> ['Message::Field::URI'],
	md5	=> ['Message::Field::Structured'],
	'transfer-encoding'	=> ['Message::Field::ValueParams'],
	type	=> ['Message::Field::ContentType'],
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::XCGI;
our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:http:cgi:x';
$OPTION{namespace_phname} = 'x-cgi';
$OPTION{namespace_phname_goodcase} = 'X-CGI';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

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
$Date: 2002/05/25 09:50:07 $

=cut

1;
