
=head1 NAME

Message::Header::Message --- Internet Messages -- Definition
for RFC 822 like header fields of message/* media types

=cut

require Message::Header::Default;
package Message::Header::Message;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

package Message::Header::Message::DeliveryStatus;
our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:message:delivery-status';

$OPTION{use_ph_namespace} = 0;
$OPTION{namespace_phname} = '';
$OPTION{namespace_phname_goodcase} = '';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$OPTION{goodcase} = {
	'dsn-gateway'	=> 'DSN-Gateway',
	'final-log-id'	=> 'Final-Log-ID',
	#'original-envelope-id'	=> 'Original-Envelope-Id',
	'received-from-mta'	=> 'Received-From-MTA',
	'remote-mta'	=> 'Remote-MTA',
	'reporting-mta'	=> 'Reporting-MTA',
};

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured',{
		-use_encoded_word	=> 0,
	}],
	
	action	=> ['Message::Field::ValueParams'],
	'arival-date'	=> ['Message::Field::Date'],
	'diagnostic-code'	=> ['Message::Field::TypedText'],
	'dsn-gateway'	=> ['Message::Field::TypedText'],
	'final-recipient'	=> ['Message::Field::TypedText',{
		-separator	=> ';',
	}],
	'last-attempt-date'	=> ['Message::Field::Date'],
	'original-recipient'	=> ['Message::Field::TypedText',{
		-separator	=> ';',
	}],
	'received-from-mta'	=> ['Message::Field::TypedText'],
	'remote-mta'	=> ['Message::Field::TypedText'],
	'reporting-mta'	=> ['Message::Field::TypedText'],
	status	=> ['Message::Field::Domain',{
		-use_ipv4_address	=> 0,
		-use_ipv6_address	=> 0,
		-use_domain_literal	=> 0,
		-use_comment	=> 1,
		-output_comment	=> 1,
	}],
	'will-retry-until'	=> ['Message::Field::Date'],
	'x-actual-recipient'	=> ['Message::Field::TypedText',{
		-separator	=> ';',
	}],
};

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

$Message::Header::NS_uri2phpackage{ $OPTION{namespace_uri} } = __PACKAGE__;

package Message::Header::Message::DispositionNotification;
our %OPTION = %Message::Header::HTTP::OPTION;
our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:message:disposition-notification';

$OPTION{use_ph_namespace} = 0;
$OPTION{namespace_phname} = '';
$OPTION{namespace_phname_goodcase} = '';

$OPTION{case_sensible} = 0;
$OPTION{to_be_goodcase} = \&Message::Header::Default::_goodcase;

$OPTION{goodcase} = {
	'mdn-gateway'	=> 'MDN-Gateway',
	'original-message-id'	=> 'Original-Message-ID',
	'reporting-ua'	=> 'Reporting-UA',
};

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured',{
		-use_encoded_word	=> 0,
	}],
	
	disposition	=> ['Message::Field::MDNDisposition'],
	'final-recipient'	=> ['Message::Field::TypedText',{
		-separator	=> ';',
	}],
	'mdn-gateway'	=> ['Message::Field::TypedText'],
	'original-message-id'	=> ['Message::Field::MsgID'],
	'original-recipient'	=> ['Message::Field::TypedText',{
		-separator	=> ';',
	}],
	'reporting-ua'	=> ['Message::Field::ReportingUA'],
};

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

$Message::Header::NS_uri2phpackage{ $OPTION{namespace_uri} } = __PACKAGE__;

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
$Date: 2002/07/13 09:29:12 $

=cut

1;
