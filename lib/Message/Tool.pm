
=head1 NAME

Message::Tool -- Tools used with Message::* Perl Modules

=head1 DESCRIPTION

Useful functions that are intended to be used with Message::* Perl Modules.

Note that there is Message::Util, very similar named module,
but its functions are used by Message::* Perl Modules internally.

=cut

package Message::Tool;
use strict;
use vars qw($VERSION);
$VERSION=do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

sub mail_downgrade ($%) {
  my $msg = shift;
  my %option = @_;
  my $hdr = $msg->header;
  ## "<" in display-name of From: field
    my $from = $hdr->field ('from', -new_item_unless_exist => 0);
    ## BUG: Non-ASCII 0x3A such as in JIS X 0208 are not supported.
    if (ref $from && $from->item (0, -by => 'index')->display_name =~ /</) {
      my $buggy = 0;
      my @to = @{ $option{destination} };
      ## TODO: Support Resent-* fields
      @to = ($hdr->field ('to')->addr_spec,
             $hdr->field ('cc')->addr_spec,
             $hdr->field ('bcc')->addr_spec) unless @to > 0;
      for (@to) {
        $buggy = 1 if /\@jp-[a-z]\.ne\.jp$/i;
      }
      $from->item (0, -by => 'index')->option (output_display_name => 0) if $buggy;
    }
}

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
$Date: 2002/07/26 12:42:00 $

=cut

1;
