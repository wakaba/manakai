use strict;
use vars qw($MYNAME $MYVERSION $VERSION);
$MYNAME = 'send.pl';
$VERSION=do{my @r=(q$Revision: 1.3 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
$MYVERSION = qq{2.5.$VERSION};
use lib qw(/home/wakaba/temp/msg/);
use Message::Entity;
use Message::Field::Date;
use Message::MIME::Charset::Jcode 'Jcode.pm';
use Message::MIME::Charset::Jcode 'jcode.pl';
use Socket;
binmode STDOUT; $| = 1;  binmode STDERR;
my %server;
$server{smtp} ||= 'suika.fam.cx';
$server{nntp} ||= 'suika.fam.cx';
my $debug_msg_log = 0;

open LOG, '>> send.slog';  binmode LOG;
my $date = Message::Field::Date->new (zone => [+1, 9, 0]);
$date->unix_time (time);
pmsg ("\x0C",
      'User-Agent: '.$MYNAME.'/'.$VERSION,
      'Date: '.$date);

opendir DIR, '.';
  my @files = sort(grep(/^[^_][\x00-\xFF]*?\.822$/, readdir(DIR)));
close DIR;
if ($#files < 0) {
  pmsg("These are no files to send!"); close LOG; die;
}
$Send::SMTP::connected = 0;
$Send::NNTP::connected = 0;

my $crlf = "\x0D\x0A";


for my $file (@files) {
  pmsg('Open message file for sending: '.$file);
  my $m;
  {
    open M, $file or &error ($!);
      local $/ = undef;
      $m = <M>;
    close M;
  }
  $m =~ s/\x0D(?!\x0A)/\x0D\x0A/gs;
  $m =~ s/(?<!\x0D)\x0A/\x0D\x0A/gs;
  my $msg = Message::Entity->parse ($m , -parse_all => 1,
    -fill_date => 0, -fill_msgid => 0,
  );
  
  ## mail/post to...
  my $header = $msg->header;
  
    ## Envelope From, To
    my $eFrom = $header->field ('x-envelope-from')->addr_spec;
    my $resent = $header->field ('resent-from')->addr_spec;
    if ($resent) {
      $eFrom ||= $resent;
    } else {
      $eFrom ||= $header->field ('from')->addr_spec;
    }
    my @eTo = $header->field ('x-envelope-to')->addr_spec;
    my ($send_mail,$post_news) = (0, 0);
    if ($resent) {
      @eTo =($header->field ('resent-to')->addr_spec,
             $header->field ('resent-cc')->addr_spec,
             $header->field ('resent-bcc')->addr_spec) if $#eTo < 0;
    } else {
      @eTo =($header->field ('to')->addr_spec,
             $header->field ('cc')->addr_spec,
             $header->field ('bcc')->addr_spec) if $#eTo < 0;
      $post_news = 1 if $header->field_exist ('newsgroups');
    }
    $send_mail = 1 if @eTo > 0;
    &error ('No envelope from') if $send_mail && !$eFrom;
    if ($eFrom && $header->field ('from')->item (0, -by => 'index')->display_name =~ /</) {
      my $buggy = 0;
      for (@eTo) {
        $buggy = 1 if /\@jp-[a-z]\.ne\.jp$/i;
      }
      $header->field ('from')->item (0, -by => 'index')->option (output_display_name => 0) if $buggy;
    }
    
    if ($send_mail && $post_news) {
      $header->replace ('Posted-And-Mailed' => 'yes');
    } elsif (!$send_mail && !$post_news) {
      &error('Not for mail nor news!');
    }
  
  my $a = '';
  $a = 'resent-' if ($resent);
  unless ($header->field_exist ($a.'message-id')) {
    my $msgid;
    if ($resent) {
      $msgid = $header->field ('resent-message-id', -prepend => 1);
    } else {
      $msgid = $header->field ('message-id');
    }
    $msgid->generate (addr_spec => $eFrom);
    pmsg ($a.'Message-id: '.$msgid);
  }
  
  unless ($header->field_exist ($a.'date')) {
    my $date;
    if ($resent) {
      $date = $header->field ('resent-date', -prepend => 1);
    } else {
      $date = $header->field ('date');
    }
    $date->unix_time ((stat ($file))[9]);
    pmsg($a.'Date: '.$date);
  }
  my $ua;
  if ($resent) {
    $ua = $header->add ('resent-user-agent' => '', -prepend => 1);
    $msg->option (fill_ua_name => 'resent-user-agent');
  } else {
    $ua = $header->field ('user-agent');
  }
  if ($Jcode::VERSION) {
    $ua->add ('Jcode.pm' => $Jcode::VERSION);
  }
  #my $jv=do{my @r=($jcode::rcsid=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
  $ua->add ('jcode.pl' => ['',$jcode::rcsid]);
  $ua->add ($MYNAME => $MYVERSION);
  
  $header->delete (qw(date-received relay-version status x-envelope-from x-envelope-to xref));
  $header->option (field_sort => 'good-practice') unless $resent;
  
  my %sopt = (
    -fill_date	=> 0,	-fill_msgid	=> 0,
    -ua_field_name	=> $a.'user-agent',
  );
  my ($msg_mail, $msg_news);
  if ($send_mail) {
    $msg_mail =  $msg->stringify (-format => 'mail-rfc2822', %sopt);
    #$msg_mail =~ s/\x0D\x0A|\x0D|\x0A/\x0D\x0A/gs;
    $msg_mail =~ s/\x0D\x0A\./\x0D\x0A../gs;
    #$msg_mail =~ s/^(?:\x0D\x0A)+//;
    #$msg_mail =~ s/(?:\x0D\x0A)*$/\x0D\x0A/;
    $msg_mail .= "\x0D\x0A.\x0D\x0A";
  }
  if ($post_news) {
    my %rename;
    for (qw(cc complaints-to nntp-posting-date injector-info nntp-posting-host posting-version received to x-complaints-to x-trace)) {
      $rename{$_} = 'x-'.$_;
    }
    $header->rename (%rename);
    $msg_news =  $msg->stringify (-format => 'news-usefor', %sopt);
    #$msg_news =~ s/\x0D\x0A|\x0D|\x0A/\x0D\x0A/gs;
    $msg_news =~ s/\x0D\x0A\./\x0D\x0A../gs;
    #$msg_news =~ s/^(?:\x0D\x0A)+//;
    #$msg_news =~ s/(?:\x0D\x0A)*$/\x0D\x0A/;
    $msg_news .= "\x0D\x0A.\x0D\x0A";
  }
  
  Send::SMTP::Connect () if $send_mail && !$Send::SMTP::connected;
  if ($send_mail) {
    pmsg('send a mail message...');
    printS("MAIL FROM:<${eFrom}>\x0D\x0A");
      my $r = <SMTP>;
      error25($r) unless $r =~ /^250/;
      Send::Log::Server25($r);
    for my $rcptto (@eTo) {
      next unless $rcptto;
      printS("RCPT TO:<$rcptto>\x0D\x0A");
        my $r = <SMTP>;
        error25($r) unless $r =~ /^25/;
        Send::Log::Server25($r);
    }
    printS("DATA\x0D\x0A");
      my $r = <SMTP>;
      error25($r) unless $r =~ /^354/;
      Send::Log::Server25($r);
    print SMTP $msg_mail;
      cmsg25 ('(message)');
      cmsg25 ($msg_mail) if $debug_msg_log;
      my $r = <SMTP>;
      error25($r) unless $r =~ /^250/;
      Send::Log::Server25($r);
  }
  Send::NNTP::Connect() if $post_news && !$Send::NNTP::connected;
  if ($post_news) {
    pmsg('post a news article...');
    printN("POST\x0D\x0A");
      my $r = <NNTP>;
      error119($r) unless $r =~ /^340/;
      Send::Log::Server119($r);
    print NNTP $msg_news;
      cmsg119('(article)');
      cmsg119($msg_news) if $debug_msg_log;
      my $r = <NNTP>;
      error119($r) unless $r =~ /^240/;
      Send::Log::Server119($r);
  }
  
  my $t = time;
  pmsg("\$ mv \"$file\" \"sent/$t.822\"");
  pmsg(`mv "$file" "sent/$t.822"`);
}
    Send::SMTP::Close() if $Send::SMTP::connected;
    Send::NNTP::Close() if $Send::NNTP::connected;
    close LOG;

sub pmsg {
  print STDOUT "$0: ". join("\n$0: ",@_)."\n";
  print LOG join("\n",@_)."\n";
}

sub cmsg {pmsg('C: '.shift,@_)}
sub smsg {pmsg('S: '.shift,@_)}
sub cmsg25 {pmsg('C25: '.shift,@_)}
sub smsg25 {pmsg('S25: '.shift,@_)}
sub cmsg119 {pmsg('C119: '.shift,@_)}
sub smsg119 {pmsg('S119: '.shift,@_)}

  sub Send::SMTP::Close {
    printS("QUIT\x0D\x0A");
      my $r = <SMTP>;
      smsg25($r);
    close SMTP;
    $Send::SMTP::connected = 0;
  }
  sub Send::NNTP::Close {
    printN("QUIT\x0D\x0A");
      my $r = <NNTP>;
      smsg119($r);
    close NNTP;
    $Send::NNTP::connected = 0;
  }
    
    sub printS {
      print SMTP $_[0];
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      cmsg25($s);
    }
    sub printN {
      print NNTP $_[0];
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      cmsg119($s);
    }
    
    
    sub wm::smtp::addstatus {
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      smsg($s);
    }
    sub Send::Log::Server25 {
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      smsg25($s);
    }
    sub Send::Log::Server119 {
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      smsg119($s);
    }
    
    sub error {
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      pmsg($s);
      Send::SMTP::Close() if $Send::SMTP::connected;
      Send::NNTP::Close() if $Send::NNTP::connected;
      close LOG;
      use Carp;
      croak ($s);
    }
    sub error25 {
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      smsg25($s);
      Send::SMTP::Close() if $Send::SMTP::connected;
      Send::NNTP::Close() if $Send::NNTP::connected;
      close LOG;
      die;
    }
    sub error119 {
      my $s = $_[0];
      $s =~ s/\x0D\x0A$//s;
      $s =~ s/\x0D\x0A/\x0D\x0A   /gs;
      smsg119($s);
      Send::SMTP::Close() if $Send::SMTP::connected;
      Send::NNTP::Close() if $Send::NNTP::connected;
      close LOG;
      die;
    }
    

sub Send::SMTP::Connect (;%) {
  my %o = @_;
  my $myname = $o{myname} || &Message::Util::get_host_fqdn || 'send.pl.'.$server{smtp};
  pmsg('connecting to '.$server{smtp}.':25...');
    socket (SMTP, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]);
    my $aton = inet_aton($server{smtp});
    pmsg ('IPv4 address: ' . sprintf '%vd', $aton);
    connect(SMTP, sockaddr_in(25, $aton))
                   || error("Can't connect to $server{smtp}:25");
    select(SMTP), $| =1;  binmode SMTP;
      my $r = <SMTP>;
      error25($r) unless $r =~ /^220/;
      Send::Log::Server25($r);
    printS('HELO '.$myname."\x0D\x0A");
      my $r = <SMTP>;
      error25() unless $r =~ /^250/;
      Send::Log::Server25($r);
  $Send::SMTP::connected = 1;
}

sub Send::NNTP::Connect {
  pmsg('conecting to '.$server{nntp}.':119...');
    socket (NNTP, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]);
    connect(NNTP, sockaddr_in(119, inet_aton($server{nntp})))
                   || error("Can't connect to $server{nntp}:119");
    select(NNTP), $| =1;   binmode NNTP;
      my $r = <NNTP>;
      error119($r) unless $r =~ /^200/;
      Send::Log::Server119($r);
    #printN('AUTHINFO USER foo'."\x0D\x0A");
    #  $r = <NNTP>;
    #  error119($r) unless $r =~ /^381/;
    #  Send::Log::Server119($r);
    #print NNTP ('AUTHINFO PASS bar'."\x0D\x0A");
    #  cmsg119('AUTHINFO PASS (password)');
    #  $r = <NNTP>;
    #  error119($r) unless $r =~ /^281/;
    #  Send::Log::Server119($r);
  $Send::NNTP::connected = 1;
}

sub __fw2hw ($) {
  my $s = shift;
  jcode::tr(\$s, "\xa3\xb0-\xa3\xb9\xa3\xc1-\xa3\xda\xa3\xe1-\xa3\xfa\xa1\xf5".
                 "\xa1\xa4\xa1\xa5\xa1\xa7\xa1\xa8\xa1\xa9\xa1\xaa\xa1\xae".
                 "\xa1\xb0\xa1\xb2\xa1\xbf\xa1\xc3\xa1\xca\xa1\xcb\xa1\xce".
                 "\xa1\xcf\xa1\xd0\xa1\xd1\xa1\xdc\xa1\xf0\xa1\xf3\xa1\xf4".
                 "\xa1\xf6\xa1\xf7\xa1\xe1\xa2\xaf\xa2\xb0\xa2\xb2\xa2\xb1".
                 "\xa1\xe4\xa1\xe3\xA1\xC0\xA1\xA1" =>
            '0-9A-Za-z&,.:;?!`^_/|()[]{}+$%#*@=\'"~-><\\ ');
  $s;
}

END {
      Send::SMTP::Close() if $Send::SMTP::connected;
      Send::NNTP::Close() if $Send::NNTP::connected;
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
$Date: 2002/07/27 04:56:38 $

=cut

### send-msg.pl ends here
