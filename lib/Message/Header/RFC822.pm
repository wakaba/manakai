
=head1 NAME

Message::Header::RFC822 --- Internet Messages -- Definition
for RFC822 Namespaces of Header Fields

=cut

package Message::Header::RFC822;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.14 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Header::Default;

our %OPTION = %Message::Header::Default::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail:rfc822';
$OPTION{namespace_phname} = 'x-rfc822';
$OPTION{namespace_phname_goodcase} = 'X-RFC822';

$OPTION{case_sensible} = 0;

$OPTION{field_sort} = {qw/alphabetic 1 good-practice 1/};
$OPTION{field_sort_good_practice_order} = {};
{
  my $i = 1;
  for (
    qw/mail-from x-envelope-from x-envelope-to resent- path/,
    qw/return-path received date from subject sender to cc bcc/,	## Recommended by RFC 822
    qw/message-id in-reply-to references keywords comments encrypted/,	## RFC 822 BNF order
  ) {
      $OPTION{field_sort_good_practice_order}->{$_} = $i++;
  }
  ## default = 999
  $i = 1000;
  for (qw/list- mime-version content- status x-uidl xref/) {
      $OPTION{field_sort_good_practice_order}->{$_} = $i++;
  }
}

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
	'x-cc-sender'	=> 'X-CC-Sender',
	'x-dearfriend'	=> 'X-DearFriend',
	'x-jsmail-priority'	=> 'X-JsMail-Priority',
	'x-mime-autoconverted'	=> 'X-MIME-Autoconverted',
	'x-mimeole'	=> 'X-MimeOLE',
	'x-ml-count'	=> 'X-ML-Count',
	'x-ml-info'	=> 'X-ML-Info',
	'x-ml-name'	=> 'X-ML-Name',
	'x-mlserver'	=> 'X-MLServer',
	'x-msmail-priority'	=> 'X-MSMail-Priority',
	'x-nntp-posting-date'	=> 'X-NNTP-Posting-Date',
	'x-nntp-posting-host'	=> 'X-NNTP-Posting-Host',
	'x-uidl'	=> 'X-UIDL',
	'x-uri'	=> 'X-URI',
	'x-url'	=> 'X-URL',
};
$OPTION{to_be_goodcase} = \&_goodcase;

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	
	date	=> ['Message::Field::Date'],
	
	received	=> ['Message::Field::Received'],
	'x-received'	=> ['Message::Field::Received'],
	
	archive	=> ['Message::Field::ValueParams'],
	'auto-submitted'	=> ['Message::Field::ValueParams'],
	'injector-info'	=> ['Message::Field::ValueParams'],
	p3p	=> ['Message::Field::Params'],
	'posted-and-mailed'	=> ['Message::Field::ValueParams'],
	'x-face-type'	=> ['Message::Field::ValueParams'],
	'x-mozilla-draft-info'	=> ['Message::Field::ValueParams'],
	
	## A message id
	'message-id'	=> ['Message::Field::MsgID'],
	
	## Numeric value
	lines	=> ['Message::Field::Numval'],
	'max-forwards'	=> ['Message::Field::Numval'],
	'mime-version'	=> ['Message::Field::Numval'],
	'x-jsmail-priority'	=> ['Message::Field::Numval'],
	'x-mail-count'	=> ['Message::Field::Numval'],
	'x-ml-count'	=> ['Message::Field::Numval'],
	'x-priority'	=> ['Message::Field::Numval'],
	
	path	=> ['Message::Field::Path'],
	
	## product
	'user-agent'	=> ['Message::Field::UA'],
	'x-shimbun-agent'	=> ['Message::Field::UA'],
	
	## Subject
	subject	=> ['Message::Field::Subject'],
	'x-nsubject'	=> ['Message::Field::Subject'],
	
	## X-Face
	'x-face'	=> ['Message::Field::XFace'],
	'x-face-1'	=> ['Message::Field::XFace'],
	'x-face-2'	=> ['Message::Field::XFace'],
	'x-face-3'	=> ['Message::Field::XFace'],
	#...
	
	## A URI
	base	=> ['Message::Field::URI',{
		-output_comment	=> 0,
		-output_display_name	=> 0,
		-value_pattern	=> 'URL:%s',
	}],
};
for (qw(cancel-lock disposition-notification-options encoding 
  importance pics-label  precedence message-type 
  priority x-list-id sensitivity x-msmail-priority xref))
  {$OPTION{value_type}->{$_} = ['Message::Field::Structured']}
for (qw(abuse-reports-to apparently-to approved approved-by bcc cc complaints-to
  delivered-to disposition-notification-to envelope-to
  errors-to  from mail-copies-to mail-followup-to mail-reply-to
  notice-requested-upon-delivery-to read-receipt-to register-mail-reply-requested-by 
  reply-to return-path
  return-receipt-to return-receipt-requested-to sender to x-abuse-reports-to 
  x-admin x-approved x-beenthere x-biglobe-sender x-cc-sender x-confirm-reading-to
  x-complaints-to x-envelope-from x-envelope-sender
  x-envelope-to x-from x-ml-address x-ml-command x-ml-to x-nfrom x-nto
  x-rcpt-to x-sender x-to x-x-sender))
  {$OPTION{value_type}->{$_} = ['Message::Field::Addresses']}
for (qw(client-date date date-received delivery-date expires
  expire-date nntp-posting-date posted posted-date received-date 
  reply-by resent-date x-originalarrivaltime x-original-date x-tcup-date))
  {$OPTION{value_type}->{$_} = ['Message::Field::Date']}
for (qw(article-updates in-reply-to
  obsoletes references replaces see-also supersedes))
  {$OPTION{value_type}->{$_} = ['Message::Field::MsgIDs']}
for (qw(encrypted followup-to keywords uri newsgroups posted-to))
  {$OPTION{value_type}->{$_} = ['Message::Field::CSV']}
for (qw(x-brother x-boss x-classmate x-daughter x-dearfriend x-favoritesong 
  x-friend x-me 
  x-moe x-respect 
  x-sublimate x-son x-sister x-wife))
  {$OPTION{value_type}->{$_} =[ 'Message::Field::CSV']}	## NOT M::F::XMOE!
for (qw(url x-home-page x-http_referer
  x-info x-pgp-key x-ml-url x-uri x-url x-web))
  {$OPTION{value_type}->{$_} = ['Message::Field::URI']}

$OPTION{uri_mailto_safe}	= {
  ## 1 all (no check)	2 no trace & bcc & from
  ## 3 no sender's info	4 (default) (currently not used)
  ## 5 only a few
  	':default'	=> 4,
  	'cc'	=> 5,
  	'bcc'	=> 1,
  	'body'	=> 1,	## Not entity body, but "body:" field.
  	'comments'	=> 5,
  	'date'	=> 1,
  	'from'	=> 1,
  	'keywords'	=> 5,
  	'list-id'	=> 1,
  	'mail-from'	=> 1,
  	'message-id'	=> 1,
  	'mime-version'	=> 1,
  	'received'	=> 1,
  	'return-path'	=> 1,
  	'sender'	=> 1,
  	'subject'	=> 5,
  	'summary'	=> 5,
  	'to'	=> 5,
  	'user-agent'	=> 3,
  	'x-face'	=> 2,
  	'x-mailer'	=> 3,
  	'x-nsubject'	=> 5,
  	'x-received'	=> 1,
  	'x400-received'	=> 1,
};

$OPTION{field}->{bcc} = {
	empty_body	=> 1,
};
$OPTION{field}->{'incomplete-copy'} = {	## RFC 2156
	empty_body	=> 1,
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

## $self->_goodcase ($namespace_package_name, $field_name, \%option)
sub _goodcase ($$$\%) {
  no strict 'refs';
  my $self = shift;
  my ($nspack, $name, $option) = @_;
  return $name if $option->{format} =~ /uri-url-mailto/;
  if ($option->{format} =~ /mail-rfc822/) {
    if ($name eq 'cc' || $name eq 'bcc') {
      return $name;
    }
  }
  if (${$nspack.'::OPTION'}{goodcase}->{$name}) {
    return ${$nspack.'::OPTION'}{goodcase}->{$name};
  }
  $name =~ s/(?:^|-)[a-z]/uc $&/ge;
  $name;
}

package Message::Header::RFC822::Resent;
our %OPTION = %Message::Header::RFC822::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail:rfc822:resent';
$OPTION{namespace_phname} = 'x-rfc822-resent';
$OPTION{namespace_phname_goodcase} = 'X-RFC822-Resent';
$OPTION{namespace_phname_regex} = 'resent';

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::RFC822::Original;
our %OPTION = %Message::Header::RFC822::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail:rfc822:original';
$OPTION{namespace_phname} = 'x-rfc822-original';
$OPTION{namespace_phname_goodcase} = 'X-RFC822-Original';

$OPTION{value_type} = { %{ $OPTION{value_type} } };
$OPTION{value_type}->{recipient} = ['Message::Field::TypedText',{
	-separator	=> ';',
}];

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::RFC822::Content;
our %OPTION = %Message::Header::RFC822::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail:rfc822:content';
$OPTION{namespace_phname} = 'content';
$OPTION{namespace_phname_goodcase} = 'Content';
$OPTION{namespace_phname_regex} = 'content';

$OPTION{field_sort} = {qw/alphabetic 1 good-practice 1/};
$OPTION{field_sort_good_practice_order} = {};
{
  my $i = 1;
  for (
    qw/type transfer-encoding id description/,	## RFC 2045 BNF order
  ) {
      $OPTION{field_sort_good_practice_order}->{$_} = $i++;
  }
}

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
	duration	=> ['Message::Field::Numval'],
	encoding	=> ['Message::Field::CSV'],
	features	=> ['Message::Field::Structured'],
	id	=> ['Message::Field::MsgID'],
	language	=> ['Message::Field::CSV'],
	length	=> ['Message::Field::Numval'],
	location	=> ['Message::Field::URI'],
	md5	=> ['Message::Field::ValueParams',{
		-parameter_av_Mrule	=> 'M_parameter_avpair',
		-value_unsafe_rule	=> 'NON_base64alphabet',
	}],
	range	=> ['Message::Field::Structured'],
	'script-type'	=> ['Message::Field::ContentType'],
	'style-type'	=> ['Message::Field::ContentType'],
	'transfer-encoding'	=> ['Message::Field::ValueParams'],
	type	=> ['Message::Field::ContentType'],
	version	=> ['Message::Field::ValueParams'],
	'x-properties'	=> ['Message::Field::Params'],
};

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

$Message::Header::NS_phname2uri{$OPTION{namespace_phname}} = $OPTION{namespace_uri};
$Message::Header::NS_uri2phpackage{$OPTION{namespace_uri}} = __PACKAGE__;

package Message::Header::RFC822::List;
our %OPTION = %Message::Header::RFC822::OPTION;
$OPTION{namespace_uri} = 'urn:x-suika-fam-cx:msgpm:header:mail:rfc822:list';
$OPTION{namespace_phname} = 'x-rfc822-list';
$OPTION{namespace_phname_goodcase} = 'X-RFC822-List';

$OPTION{goodcase} = {
	'id'	=> 'ID',
};

$OPTION{value_type} = {
	':default'	=> ['Message::Field::Unstructured'],
	
	id	=> ['Message::Field::ListID'],
	software	=> ['Message::Field::UA'],
	
	archive	=> ['Message::Field::CSV'],
	digest	=> ['Message::Field::CSV'],
	help	=> ['Message::Field::CSV'],
	owner	=> ['Message::Field::CSV'],
	post	=> ['Message::Field::CSV'],
	subscribe	=> ['Message::Field::CSV'],
	unsubscribe	=> ['Message::Field::CSV'],
	url	=> ['Message::Field::CSV'],
};

$OPTION{uri_mailto_safe}	= {
  	':default'	=> 1,
};

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
$Date: 2002/11/13 08:08:52 $

=cut

1;
