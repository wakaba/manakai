#!/usr/bin/perl

=head1 NAME

verify.pl --- Sample script of Message::* Perl Modules
              --- Verifying signed message with GnuPG

=cut

use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Message::Entity;
use Getopt::Long;
my $gpg_path = 'gpg';
my $tmp_path = './';
GetOptions (
	'--gpg-path=s'	=> \$gpg_path,
	'--temp-dir=s'	=> \$tmp_path,
) or die;

my $msg;
{
binmode STDIN;
local $/ = undef;
$msg = Message::Entity->parse (<STDIN>, -linebreak_strict => 0);
}
die "This message is not signed" unless $msg->media_type eq 'multipart/signed';
my $protocol = lc $msg->header->field ('content-type')->item ('protocol');
die "Protocol $protocol is not supported" unless $protocol eq 'application/pgp-signature';
my $body = $msg->body->data_part (-parse => 0);
my $signature = $msg->body->control_part;

die "Media type of signature (@{[scalar $signature->media_type]}) does not match with $protocol" unless $signature->media_type eq 'application/pgp-signature';

open MSG, ">$tmp_path.signedmsg.tmp";
  binmode MSG;
  print MSG $body;
close MSG;
open SIG, ">$tmp_path.signature.tmp";
  binmode SIG;
  print SIG $signature->body;
close SIG;

print `$gpg_path --verify --batch $tmp_path.signature.tmp $tmp_path.signedmsg.tmp`;
`rm $tmp_path.signature.tmp $tmp_path.signedmsg.tmp`;

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
$Date: 2002/07/20 08:42:56 $

=cut

### verify.pl ends here
