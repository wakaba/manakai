
=head1 NAME

Message::Partial --- Perl module for partial message defined by MIME
(message/partial)

=cut

package Message::Partial;
use strict;
use vars qw(%OPTION $VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Entity;
require Message::Header;
require Message::Field::MsgID;

%OPTION = (
  -part_length	=> 1024,
  -subject_format_pattern	=> '%s (%d/%d)',
);

sub fragmentate ($;%) {
  my $msg = shift;
  my %params = @_;
  my %option = %OPTION;
  for (grep {/^-/} keys %params) {$option{$_} = $params{$_}}
  
  if (ref $msg) {
    $msg = $msg->clone;
  } else {
    $msg = parse Message::Entity $msg;
  }
  my @copy_field;
  my %cf = (subject => 1, encrypted => 1, 'mime-version' => 1, 'message-id' => 1);
  $msg->option (force_mime_entity => 1);
  $msg->stringify;	## Make fill_* work
  $msg->header->scan (sub {
    my $i = $_[1];
    my $rfc822 = $Message::Header::NS_phname2uri{rfc822};
    if ($_[1]->{ns} eq $Message::Header::NS_phname2uri{content}) {
      push @copy_field, {%{$_[1]}};
      $_[1]->{name} = undef;
    } elsif ($_[1]->{ns} eq $rfc822 && $cf{$_[1]->{name}}) {
      #push @copy_field, Message::Util::make_clone ($_[1]);
      ##$_[1]->{name} = undef;	## Don't remove to keep compatible w/ RFC 1341/1521
      push @copy_field, {%{$_[1]}};
      $_[1]->{name} = undef;
    }
  });
  my $outer_header = $msg->header;
  my $inner_header = new Message::Header;
  $inner_header->{value} = \@copy_field;	## Warning: direct access to internal structure!
  $msg->header ($inner_header);
  my @msg = split /\x0D\x0A/, $msg->stringify (-accept_cte => '7bit');
  my @pbody = ('');
  for (@msg) {
    if (length $pbody[$#pbody] > $option{-part_length}) {
      push @pbody, '';
    }
    $pbody[$#pbody] .= $_."\x0D\x0A";
  }
  my @pmsg;
  my $subject = $inner_header->field ('subject', -new_item_unless_exist => 0);
  my $ct = $outer_header->field ('content-type');
    $ct->media_type ('message/partial');
    my $as = $outer_header->field ('resent-from', -new_item_unless_exist => 0)
          || $outer_header->field ('from', -new_item_unless_exist => 0);
    $as = $as->addr_spec if ref $as;
    $as ||= 'part@partial.message.pm.invalid';
    my $pid = Message::Field::MsgID->new (addr_spec => $as);
    $ct->parameter (id => $pid->content);
  my $first_mid;
  for my $i (0..$#pbody) {
    $pmsg[$i] = new Message::Entity;
    $pmsg[$i]->header ($outer_header->clone);
    my $hdr = $pmsg[$i]->header;
    $hdr->replace (subject
      => sprintf ($option{-subject_format_pattern}, $subject, $i+1, $#pbody+1));
    my $ct = $hdr->field ('content-type');
    $ct->parameter (number => $i +1);
    $ct->parameter (total => $#pbody +1);
    $pmsg[$i]->body ($pbody[$i]);
    if ($i == 0) {
      $pmsg[$i]->stringify;
      $first_mid = $hdr->field ('message-id');
    } else {
      $hdr->field ('references')->add ($first_mid);
    }
  }
  @pmsg;
}

=head1 SEE ALSO

L<Message::Entity>

RFC 1341 E<lt>urn:ietf:rfc:1341E<gt>,
RFC 1521 E<lt>urn:ietf:rfc:1521E<gt>,
RFC 2046 E<lt>urn:ietf:rfc:2046E<gt>

RFC 822 E<lt>urn:ietf:rfc:822E<gt>,
RFC 2822 E<lt>urn:ietf:rfc:2822E<gt>

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
$Date: 2002/06/11 13:01:21 $

=cut

1;
