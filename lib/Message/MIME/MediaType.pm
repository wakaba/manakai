
=head1 NAME

Message::MIME::MediaType --- Media-type definitions

=cut

package Message::MIME::MediaType;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.15 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
require Message::Header;
require Message::Header::Message;

our %type;

$type{text}->{plain} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,	## have mime style charset parameter?
	handler	=> sub {
	  my $self = shift;
	  my $ct = $self->header->field ('content-type', -new_item_unless_exist=>0);
	  if (ref $ct
	    && lc ($ct->item ('format', -new_item_unless_exist => 0))
	          eq 'flowed') {
	    ['Message::Body::TextPlainFlowed'];
	  } else {	## format="fixed"
	    ['Message::Body::TextPlain'];
	  }
	},
	parameter	=> {
		format	=> {case_sensible => 0},	# token
	},
	extension	=> [qw/txt text/],
	mac_type	=> [qw/TEXT/],
};
$type{text}->{'/default'} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	handler	=> ['Message::Body::Text'],
};

$type{text}->{calender} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		component	=> {},	# token
		method	=> {},	# 1*(ALPHA / DIGIT / "-")
		optinfo	=> {multiple => 1},	# token
	},
	extension	=> [qw/ics ifb/],
	mac_type	=> [qw/iCal iFBf/],
};

$type{text}->{css} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	extension	=> [qw/css/],
	mac_type	=> ['css '],
};

$type{text}->{'x-csv'} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	extension	=> [qw/csv/],
};

$type{text}->{directory} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		profile	=> {case_sensible => 0},	# token
	},
	extension	=> [qw/ics ifb/],
	mac_type	=> [qw/iCal iFBf/],
};

$type{text}->{ecmascript} = {	## Not yet registered in [IANAREG]
	mime_alternate	=> [qw/application ecmascript/],
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		version	=> {},
	},
	extension	=> [qw/es ecma/],
	mac_type	=> [qw/TEXT/],
};

$type{text}->{enriched} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	#handler	=> ['Message::Body::Enriched'],
};

$type{text}->{html} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		level	=> {
			handler	=> ['Message::Field::Numval',{
				-check_max	=> 1,
				-value_min	=> 1,
				-value_max	=> 3,
			}],
		},	## obsolete; HTML 2.0
		version	=> {
			handler	=> ['Message::Field::Numval',{
				-format_pattern	=> '%1.1f',
				-value_min	=> 1.0,
			}],
		},	## obsolete; HTML 3.0
	},
	extension	=> [qw/html htm/],
	mac_type	=> [qw/TEXT/],
};

$type{text}->{javascript} = {	## Not yet registered in [IANAREG]
	mime_alternate	=> [qw/application javascript/],
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		version	=> {},
	},
	extension	=> [qw/js/],
	mac_type	=> [qw/TEXT/],
};

$type{text}->{'x-message-pem'} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
};

$type{text}->{'x-message-rfc934'} = {
	mime_charset	=> 0,
	handler	=> ['Message::Body::TextMessageRFC934'],
};

$type{text}->{'x-message-rfc1153'} = {
	mime_charset	=> 0,
	handler	=> ['Message::Body::TextMessageRFC1153'],
};

$type{text}->{parityfec} = {
	mime_charset	=> 0,
};

$type{text}->{'x-pgp-cleartext-signed'} = {
	mime_alternate	=> [qw/application pgp/],
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	handler	=> ['Message::Body::TextPlain'],
};

$type{text}->{'prs.lines.tag'} = {
	mime_charset	=> 0,
	accept_cte	=> [qw/7bit/],
	extension	=> [qw/tag/],
};

$type{text}->{'rfc822-headers'} = {
	mime_charset	=> 0,
	handler	=> ['Message::Header',{
		-format => 'mail-rfc822',
	}],
};

$type{text}->{richtext} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	#handler	=> ['Message::Body::Enriched'],
};

$type{text}->{rtf} = {
	mime_alternate	=> [qw/application rtf/],
	mime_charset	=> 0,
	accept_cte	=> [qw/7bit/],
	extension	=> [qw/rtf/],
};

$type{text}->{sgml} = {
	#mime_alternate	=> [qw/application sgml/],
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		'sgml-bctf'	=> {},	# token
		'sgml-boot'	=> {
			handler	=> ['Message::Field::MsgID'],
		},	# content-id
	},
};

$type{text}->{t400} = {
	mime_charset	=> 0,
	default_charset	=> 'utf-8',
};

$type{text}->{'tab-separated-values'} = {
	mime_charset	=> 1,
	extension	=> [qw/tsv/],
};

$type{text}->{'uri-list'} = {
	mime_charset	=> 1,
	extension	=> [qw/uris uri/],
	mac_type	=> [qw/URIs/],
};

$type{text}->{'x-url-shortcut'} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	extension	=> [qw/url/],
};

$type{text}->{xsl} = {	## Not in [IANAREG]
	#mime_alternate	=> [qw/application xml/],
	mime_charset	=> 1,
	extension	=> [qw/xsl/],
};

$type{text}->{xml} = {
	mime_alternate	=> [qw/application xml/],
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',
	extension	=> [qw/xml/],
	mac_type	=> [qw/TEXT/],
};

$type{text}->{'xml-external-parsed-entity'} = {
	mime_alternate	=> [qw/application xml-external-parsed-entity/],
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',
	extension	=> [qw/ent xml/],
	mac_type	=> [qw/TEXT/],
};

$type{application}->{'octet-stream'} = {
	cte_7bit_preferred	=> 'base64',
	handler	=> ['Message::Body::ApplicationOctetStream'],
	parameter	=> {
		conversions	=> {
			handler	=> ['Message::Field::CSV'],
		},	## obsolete
		'x-conversions'	=> {
			handler	=> ['Message::Field::CSV'],
		},
		name	=> {},
		padding	=> {
			handler	=> ['Message::Field::Numval',{
				-check_max	=> 1,
				-value_min	=> 0,
				-value_max	=> 7,
			}],
		},
		type	=> {},
	},
};
$type{application}->{'/default'} = $type{application}->{'octet-stream'};

$type{application}->{'x-batch-smtp'} = {	## RFC 976 BSMTP
	cte_7bit_preferred	=> 'quoted-printable',
	text_content	=> 1,
};

$type{application}->{ecmascript} = {	## Not yet registered in [IANAREG]
	cte_7bit_preferred	=> 'quoted-printable',
	text_content	=> 1,
	mime_charset	=> 1,
	parameter	=> {
		version	=> {},
	},
	extension	=> [qw/es ecma/],
	mac_type	=> [qw/TEXT/],
};

$type{application}->{http} = {
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Entity', {
		-add_ua	=> 0,
		-format	=> 'http',
		-fill_missing_fields	=> 0,
	}],
	parameter	=> {
		msgtype	=> {case_sensible => 0},	# "request" / "response"
		version	=> {
			handler	=> ['Message::Field::Numval',{
				-format_pattern	=> '%1.1f',
			}],
		},
	},
};

$type{application}->{javascript} = {	## Not yet registered in [IANAREG]
	preferred_name	=> ['application', 'javascript'],
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	parameter	=> {
		version	=> {},
	},
	extension	=> [qw/js/],
	mac_type	=> [qw/TEXT/],
};
$type{application}->{'x-javascript'} = $type{application}->{javascript};

$type{application}->{'mathml+xml'} = {	## Not in [IANAREG]
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',	# See RFC 3023
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/mml/],
};

$type{application}->{msword} = {
	parameter	=> {
		version	=> {},	# "4" / "5" / "2w" / "6"
	},
	extension	=> [qw/doc/],
	mac_type	=> [qw/WDBN/],
	mac_creator	=> [qw/MSWD/],
};

$type{application}->{'news-transmission'} = {
	cte_7bit_preferred	=> 'base64',
	handler	=> ['Message::Entity', {
		-fill_missing_fields	=> 0,
		#-format	=> 'news-son-of-rfc1036',
		-format	=> 'news-usefor',
	}],
	parameter	=> {
		conversions	=> {
			handler	=> ['Message::Field::CSV'],
		},	## obsolete
		usage	=> {case_sensible => 0},	# token
	},
};

$type{application}->{pgp} = {	## Not in [IANAREG].  Obsoleted
	text_content	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
	handler	=> ['Message::Body::TextPlain'],
};

$type{application}->{'pgp-signature'} = {
	text_content	=> 1,
	default_charset	=> 'us-ascii',
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{application}->{'rdf+xml'} = {	## Not in [IANAREG]
	text_content	=> 1,
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',	# See RFC 3023
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/rdf/],
};

$type{application}->{rtf} = {
	accept_cte	=> [qw/7bit/],
	extension	=> [qw/rtf/],
};

$type{application}->{sgml} = {
	cte_7bit_preferred	=> 'quoted-printable',
	parameter	=> {
		'sgml-bctf'	=> {},	# token
		'sgml-boot'	=> {
			handler	=> ['Message::Field::MsgID'],
		},	# content-id
	},
};

$type{application}->{'sgml-open-catalog'} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,
};

$type{application}->{'x-perl'} = {
	mime_charset	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/pl pm pod ph/],
};

$type{application}->{'x-tex'} = {
	mime_charset	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/tex/],
};

$type{application}->{'x-text'} = {
	## Dummy sub type for text/* sub types with non-MIME-text-suitable
	## charset (on MIME entity)
	mime_charset	=> 1,
	text_content	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{application}->{'x-lirs+csv'} = {
	mime_charset	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/lirs/],
};

$type{application}->{'x-mail-message'} = {
	cte_7bit_preferred	=> 'quoted-printable',
	text_content	=> 1,
	mime_charset	=> 0,
	handler	=> sub {
	  my $self = shift;
	  my $ct = $self->header->field ('content-type', -new_item_unless_exist=>0);
	  my %p;
	  if (ref $ct) {
	    $p{format} = lc $ct->item ('format', -new_item_unless_exist => 0);
	    $p{hc} = lc $ct->item ('header-charset', -new_item_unless_exist => 0);
	    $p{bc} = lc $ct->item ('body-charset', -new_item_unless_exist => 0);
	  }
	  $p{format} = 'mail-' . ($p{format} || 'rfc2822');
	  
	  my %o;
	  $o{-header_charset} = $p{hc} if $p{hc};
	  $o{-body_charset} = $p{bc} if $p{bc};
	  ['Message::Entity', {
	  	-fill_missing_fields	=> 0,
	  	-format	=> $p{format},
	  	%o,
	  }]
	},
};

$type{application}->{xml} = {
	text_content	=> 1,
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',	# See RFC 3023
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/xml/],
	mac_type	=> [qw/TEXT/],
};

$type{application}->{'xhtml+xml'} = {
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',	# See RFC 3023
	cte_7bit_preferred	=> 'quoted-printable',
	parameter	=> {
		profile	=> {
			#handler	=> ['URI'],
		},
	},
	extension	=> [qw/xhtml xht html xml/],
	mac_type	=> [qw/TEXT/],
};

$type{application}->{'xml-external-parsed-entity'} = {
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',	# See RFC 3023
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/ent xml/],
	mac_type	=> [qw/TEXT/],
};

$type{application}->{'xml-dtd'} = {
	mime_charset	=> 1,
	default_charset	=> 'us-ascii',	# See RFC 3023
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/mod dtd/],
	mac_type	=> [qw/TEXT/],
};

## --- Image types

$type{image}->{naplps} = {
	text_content	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	parameter	=> {
		version	=> {
			handler	=> ['Message::Field::Numval'],
			## 4*DIGIT optional
		},
	},
};

$type{image}->{'svg+xml'} = {	## Not in [IANAREG]
	preferred_name	=> ['image', 'svg+xml'],
	mime_charset	=> 1,
	text_content	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/svg/],
	mac_type	=> [qw/svg /],
		## NOTE: .svgz / svgz -> gzipped SVG
};
$type{image}->{'svg-xml'} = $type{image}->{'svg+xml'};
$type{image}->{'vnd.adobe.svg+xml'} = $type{image}->{'svg+xml'};

$type{image}->{'x-windows-bitmap'} = {
	preferred_name	=> ['image', 'x-windows-bitmap'],
	extension	=> [qw/bmp dib/],
};
$type{image}->{'x-bmp'} = $type{image}->{'x-windows-bitmap'};

$type{image}->{'x-windows-icon'} = {
	extension	=> [qw/ico/],
};

$type{image}->{'x-xbitmap'} = {
	preferred_name	=> ['image', 'x-xbitmap'],
	mime_charset	=> 1,
	cte_7bit_preferred	=> 'quoted-printable',
	extension	=> [qw/xbm/],
};
$type{image}->{'x-xbm'} = $type{image}->{'x-xbitmap'};

## --- Model types

$type{model}->{'/default'} = {	## See RFC 2077
	cte_7bit_preferred	=> 'base64',
	parameter	=> {
		dimension	=> {
			handler	=> ['Message::Field::Numval'],
		},
		state	=> {case_sensible => 0},	## "static" / "dynamic"
	},
};

## --- Message types

$type{message}->{'/default'} = {
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{message}->{'delivery-status'} = {
	mime_alternate	=> [qw/message delivery-status/],
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Body::MessageDeliveryStatus'],
};

$type{message}->{'disposition-notification'} = {
	mime_alternate	=> [qw/message disposition-notification/],
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Header',{
		-format => 'message-disposition-notification',
		-ns_default_phuri	=> $Message::Header::Message::DispositionNotification::OPTION{namespace_uri},
		-hook_init_fill_options	=> sub {
		  my ($hdr, $option) = @_;
		  for (qw/disposition final_recipient reporting_ua/) {
		    unless (defined $option->{ 'fill_' . $_ }) {
		      $option->{ 'fill_' . $_ } = 1;
		    }
		  }
		},
		-hook_stringify_fill_fields	=> sub {
		  my ($hdr, $exist, $option) = @_;
		  my $ns = ':'.$option->{ns_default_phuri};
		  if ($option->{fill_disposition}
		    && !$exist->{ 'disposition'.$ns  }) {
		    #my $d = $hdr->replace (disposition
		    #  => 'manual-action/MDN-sent-manually; displayed');
		    $hdr->field ('disposition');
		  }
		  if ($option->{fill_final_recipient}
		    && !$exist->{ 'final-recipient'.$ns  }) {
		    my $fr = $hdr->field ('final-recipient');
		    $fr->type ('rfc822');
		    $fr->value ('foo@' . (&Message::Util::get_host_fqdn || 'bar.invalid'));
		  }
		  if ($option->{fill_reporting_ua}
		    && !$exist->{ 'reporting-ua'.$ns  }) {
		    my $rua = $hdr->field ('reporting-ua');
		    $rua->ua_name (&Message::Util::get_host_fqdn || 'bar.invalid');
		    $rua->ua_product->add_our_name;
		  }
		},
	}],
};

$type{message}->{'external-body'} = {
	mime_alternate	=> [qw/message external-body/],
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Body::MessageExternalBody',{},
		[qw/body_default_charset body_default_charset_input/],
	],
	parameter	=> {
		expiration	=> {
			handler	=> ['Message::Field::Date',{
				-format	=> 'mail-rfc822+rfc1123',
			}],
		},
		server	=> {
			handler	=> ['Message::Field::Mailbox',{
				-output_angle_bracket	=> 0,
				-output_display_name	=> 0,
			}],
		},
		site	=> {
			handler	=> ['Message::Field::Domain',{
				-format_ipv4	=> '%vd',
				-format_ipv6	=> '%s',
				-use_domain_literal	=> 0,
			}],
		},
		size	=> {
			handler	=> ['Message::Field::Numval'],
		},
		subject	=> {
			handler	=> ['Message::Field::Subject',{
				-remove_ml_prefix	=> 0,
			}],
		},
		url	=> {
			handler	=> ['Message::Field::URI',{
				-allow_relative	=> 0,
				-output_angle_bracket	=> 0,
				-use_comment	=> 0,
				-use_display_name	=> 0,
			}],
		},
	},
};

$type{message}->{http} = {
	mime_alternate	=> [qw/application http/],
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Entity', {
		-add_ua	=> 0,
		-format	=> 'http',
		-fill_missing_fields	=> 0,
	}],
	parameter	=> {
		msgtype	=> {case_sensible => 0},	# "request" / "response"
		version	=> {
			handler	=> ['Message::Field::Numval',{
				-format_pattern	=> '%1.1f',
			}],
		},
	},
};

$type{message}->{news} = {	## Obsoleted by usefor
	preferred_name	=> [qw/message news/],
	mime_alternate	=> [qw/application news-transmission/],
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Entity', {
		-fill_missing_fields	=> 0,
		-format	=> 'news-son-of-rfc1036',
	}],
};
$type{message}->{'x-netnews'} = $type{message}->{news};

$type{message}->{partial} = {
	mime_alternate	=> [qw/message partial/],
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{message}->{rfc822} = {
	mime_alternate	=> [qw/application x-mail-message/],
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Entity', {
		-fill_missing_fields	=> 0,
		-format	=> 'mail-rfc822+rfc1123',
	}],
};

$type{message}->{'s-http'} = {
	mime_alternate	=> [qw/application s-http/],
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Entity', {
		-add_ua	=> 0,
		-format	=> 'http-shttp-rfc2660',
		-fill_missing_fields	=> 0,
	}],
	parameter	=> {
		msgtype	=> {case_sensible => 0},	# "request" / "response"
		version	=> {
			handler	=> ['Message::Field::Numval',{
				-format_pattern	=> '%1.1f',
			}],
		},
	},
};

## --- Multipart/*
my @multipart_inherit = qw/accept_coderange body_default_charset body_default_charset_input cte_default text_coderange/;

$type{multipart}->{mixed} = {
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Body::Multipart',{},\@multipart_inherit],
};
$type{multipart}->{'/default'} = $type{multipart}->{mixed};

$type{multipart}->{alternative} = {
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler => ['Message::Body::Multipart', {}, \@multipart_inherit],
	parameter	=> {
		differences	=> {
			handler => ['Message::Field::CSV', {
				-separator	=> ',',
				-separator_long	=> ',',
				-use_comment	=> 0,
			}]
		},
	},
};

$type{multipart}->{appledouble} = {
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler	=> ['Message::Body::Multipart',{
		-max	=> 2,
	},\@multipart_inherit],
	parameter	=> {name => {}},
};

$type{multipart}->{digest} = {
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
	handler => ['Message::Body::Multipart', {
		-default_media_type => 'message',
		-default_media_subtype => 'rfc822',
	}, \@multipart_inherit],
};

$type{multipart}->{report} = {
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
	parameter	=> {
		'report-type'	=> {},
	},
};

## Unknown media-type
$type{'/default'}->{'/default'} = $type{application}->{'octet-stream'};

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
