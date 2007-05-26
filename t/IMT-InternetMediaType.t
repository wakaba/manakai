use strict;
use Test;
BEGIN { plan tests => 10 }
use Message::IMT::InternetMediaType;

my $dom = 'Message::DOM::DOMImplementation'; ## TODO: use formal way to do this

my $imt = $dom->create_internet_media_type ('text', 'plain');
my $imt2 = $dom->create_internet_media_type ('Text', 'PLAIN');

ok $imt->top_level_type, 'text';
ok $imt->subtype, 'plain';
ok $imt->type, 'text/plain';
ok $imt->imt_text, 'text/plain';
ok $imt.'', 'text/plain';

ok $imt2->top_level_type, 'text';
ok $imt2->subtype, 'plain';
ok $imt2->type, 'text/plain';
ok $imt2->imt_text, 'text/plain';
ok $imt2.'', 'text/plain';

ok (($imt) ? 1 : 0, 1);
ok (($imt eq undef) ? 1 : 0, 0);
ok (($imt eq 'text/plain') ? 1 : 0, 1);
ok (($imt eq 'TEXT/PLAIN') ? 1 : 0, 0);
ok (($imt eq $imt) ? 1 : 0, 1);
ok (($imt eq $imt2) ? 1 : 0, 1);

ok $imt->parameter_length, 0;
$imt->set_parameter (charseT => 'US-ascii');
ok $imt->parameter_length, 1;
ok $imt->get_attribute (0), 'charset';
ok $imt->get_value (0), 'US-ascii';
ok $imt->get_parameter ('charSet'), 'US-ascii';
ok $imt.'', 'text/plain; charset=US-ascii';
$imt->remove_parameter ('Charset');
ok $imt->parameter_length, 0;
$imt->set_parameter (format => 'flowed');
$imt->set_parameter (delsp => 1);
$imt->set_attribute (1 => 'format');
$imt->set_value (1 => 'fixed');
ok $imt.'', 'text/plain; format=flowed; format=fixed';
$imt->set_parameter (format => 'in\valid');
ok $imt.'', 'text/plain; format="in\\\\valid"';
$imt->remove_parameter ('format');
ok $imt.'', 'text/plain';

## License: Public Domain.
## $Date: 2007/05/26 06:34:46 $
