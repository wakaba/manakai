#!/usr/bin/perl

=head1 NAME

sign.pl --- Sample script of Message::* Perl Modules
        --- Signing a (new) message with GnuPG

=cut

## This file is written in EUC-japan.

use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
use Message::MIME::Charset::Jcode 'jcode.pl';
$Message::MIME::Charset::Jcode::CODE{input} = 'euc';
use Getopt::Long;
my $gpg_path = 'gpg';
my $tmp_path = './';
GetOptions (
	'--gpg-path=s'	=> \$gpg_path,
	'--temp-dir=s'	=> \$tmp_path,
) or die;

my $msgbody = <<'EOH';
GnuPG を使って電子署名、とか言ってみるテスト。
EOH

require Message::Entity;
my $msg = new Message::Entity;
  $msg->header->field ('user-agent')->add ($0 => $VERSION);
  my $ct = $msg->header->field ('content-type');
    $ct->media_type ('multipart/signed');
    $ct->parameter (micalg => 'pgp-sha1');
  my $body = $msg->body->data_part;
    $body->body ($msgbody);
  my $signature = $msg->body->control_part;
    my $sct = $signature->header->field ('content-type');
    $sct->media_type ('application/pgp-signature');

open MSG, "> $tmp_path.signmsg.tmp";
  binmode MSG;
  print MSG $body;
close MSG;

{
`$gpg_path --detach-sign --armor --digest-algo sha1 $tmp_path.signmsg.tmp`;
open GPG, "$tmp_path.signmsg.tmp.asc";
  binmode GPG;
  local $/ = undef;
  $signature->body (<GPG>);
close GPG;
unlink "$tmp_path.signmsg.tmp";
unlink "$tmp_path.signmsg.tmp.asc";
}

binmode STDOUT;
print $msg;

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

### sign.pl ends here
