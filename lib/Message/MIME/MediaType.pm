
=head1 NAME

Message::MIME::MediaType --- Media-type definitions

=cut

package Message::MIME::MediaType;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

our %type;

$type{text}->{plain} = {
	cte_7bit_preferred	=> 'quoted-printable',
	mime_charset	=> 1,	## have mime style charset parameter?
};
$type{text}->{'/default'} = $type{text}->{plain};

$type{application}->{'octet-stream'} = {
	cte_7bit_preferred	=> 'base64',
};
$type{application}->{'/default'} = $type{application}->{'octet-stream'};

$type{message}->{'/default'} = {
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{message}->{'external-body'} = {
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{message}->{partial} = {
	accept_cte	=> [qw/7bit/],
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{message}->{rfc822} = {
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
};

$type{multipart}->{mixed} = {
	accept_cte	=> [qw/7bit 8bit binary/],
	cte_7bit_preferred	=> 'quoted-printable',
};
$type{multipart}->{'/default'} = $type{multipart}->{mixed};

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
$Date: 2002/05/29 10:54:49 $

=cut

1;
