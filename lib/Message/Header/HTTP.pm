
=head1 NAME

Message::Header::RFC822 --- Internet Messages -- Definition
for RFC822 Namespaces of Header Fields

=cut

require Message::Header::Default;
package Message::Header::HTTP;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:http';
$OPTION{namespace_phname} = 'x-http';
$OPTION{namespace_phname_goodcase} = 'X-HTTP';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$OPTION{field_sort} = {qw/alphabetic 1 good-practice 1/};
$OPTION{field_sort_good_practice_order} = {};
{
  my $i = 1;
  for (
    qw/status/,	## CGI header
    qw/man c-man opt c-opt ext c-ext
       cache-control connection date pragma transfer-encoding upgrade trailer via
       keep-alive/,	## General-Headers
    qw/accept accept-charset accept-encoding accept-language
       authorization expect from host
       if-modified-since if-match if-none-match if-range if-unmodified-since
       max-forwards proxy-authorization range referer te user-agent/,	## Request-Headers
    qw/accept-ranges age location proxy-authenticate retry-after server vary
       warning www-authenticate alternates/,	## Response-Headers
    qw/allow etag expires last-modified link window-target
       mime-version derived-from base content-/,	## Entity-Headers
  ) {
      $OPTION{field_sort_good_practice_order}->{$_} = $i++;
  }
  ## default = 999
  $i = 1000;
  for (qw/list- mime-version content- xref/) {
      $OPTION{field_sort_good_practice_order}->{$_} = $i++;
  }
}

$OPTION{goodcase} = {
	'pics-label'	=> 'PICS-Label',
	'message-id'	=> 'Message-ID',
	'mime-version'	=> 'MIME-Version',
	uri	=> 'URI',
};

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	status	=> ['Message::Field::Status'],
	
	## HTTP-Date / delta-second
	date	=> ['Message::Field::Date'],
	expires	=> ['Message::Field::Date'],
	'if-modified-since'	=> ['Message::Field::Date'],
	'if-unmodified-since'	=> ['Message::Field::Date'],
	'last-modified'	=> ['Message::Field::Date'],
	
	p3p	=> ['Message::Field::Params'],
	'window-target'	=> ['Message::Field::ValueParams'],
	'mime-version'	=> ['Message::Field::Numval'],
	from	=> ['Message::Field::Addresses'],
	
	## product
	server	=> ['Message::Field::UA'],
	'user-agent'	=> ['Message::Field::UA'],
	
	## Comma Separated List
	link	=> ['Message::Field::CSV'],
	uri	=> ['Message::Field::CSV'],
	man	=> ['Message::Field::CSV'],
	opt	=> ['Message::Field::CSV'],
	warning	=> ['Message::Field::CSV',{
		-is_quoted_string	=> 0,
		-use_comment	=> 0,
		-value_type	=> {'*default' => ['Message::Field::Warning']},
	}],
	
	## A URI
	base	=> ['Message::Field::URI',{
		-output_comment	=> 0,
		-output_display_name	=> 0,
		-value_pattern	=> 'URL:%s',
	}],
	location	=> ['Message::Field::URI'],
	referer	=> ['Message::Field::URI',{
		-allow_fragment	=> 0,
		-output_angle_bracket	=> 0,
		-use_comment	=> 0,
		-use_display_name	=> 0,
	}],
	referrer	=> ['Message::Field::URI',{
		-allow_fragment	=> 0,
		-output_angle_bracket	=> 0,
		-use_comment	=> 0,
		-use_display_name	=> 0,
	}],
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

package Message::Header::HTTP::CCPP;
## CC/PP exchange protocol <http://www.w3.org/TR/NOTE-CCPPexchange>
our %OPTION = %Message::Header::HTTP::OPTION;
$OPTION{namespace_uri} = 'http://www.w3.org/1999/06/24-CCPPexchange';

$OPTION{use_ph_namespace} = 0;
$OPTION{namespace_phname} = '';
$OPTION{namespace_phname_goodcase} = '';

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
		## *-Profile-Diff-(1*DIGIT): field (field-body = application/XML)
	profile	=> ['Message::Field::CSV'],
	'profile-warning'	=> ['Message::Field::CSV',{
		-is_quoted_string	=> 0,
	}],
};

$Message::Header::NS_uri2package{ $OPTION{namespace_uri} } = __PACKAGE__;

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
$Date: 2002/08/04 00:16:32 $

=cut

1;
