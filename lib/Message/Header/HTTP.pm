
=head1 NAME

Message::Header::RFC822 --- Internet Messages -- Definition
for RFC822 Namespaces of Header Fields

=cut

require Message::Header::Default;
package Message::Header::HTTP;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:http';
$OPTION{namespace_phname} = 'x-http';
$OPTION{namespace_phname_goodcase} = 'X-HTTP';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$OPTION{goodcase} = {
	'pics-label'	=> 'PICS-Label',
	'message-id'	=> 'Message-ID',
	'mime-version'	=> 'MIME-Version',
	uri	=> 'URI',
};

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	
	date	=> ['Message::Field::Date'],
	expires	=> ['Message::Field::Date'],
	'if-modified-since'	=> ['Message::Field::Date'],
	'last-modified'	=> ['Message::Field::Date'],
	
	man	=> ['Message::Field::CSV'],
	opt	=> ['Message::Field::CSV'],
	p3p	=> ['Message::Field::Params'],
	
	## Numeric value
	'mime-version'	=> ['Message::Field::Numval'],
	
	server	=> ['Message::Field::UA'],
	'user-agent'	=> ['Message::Field::UA'],
	'from'	=> ['Message::Field::Addresses'],
	
	link	=> ['Message::Field::CSV'],
	uri	=> ['Message::Field::CSV'],
	
	location	=> ['Message::Field::URI'],
	referer	=> ['Message::Field::URI'],
	referrer	=> ['Message::Field::URI'],
};

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

$OPTION{field}->{ext} = {	## RFC 2774
	empty_body	=> 1,
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::HTTP::C;
our %OPTION = %Message::Header::HTTP::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:http:c';
$OPTION{namespace_phname} = 'x-http-c';
$OPTION{namespace_phname_goodcase} = 'X-HTTP-C';

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
$Date: 2002/07/06 10:29:31 $

=cut

1;
