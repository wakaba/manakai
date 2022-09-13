
=head1 NAME

SuikaWiki::Output::CGICarp --- SuikaWiki : CGI::Carp modification to
return 500 status code

=head1 DESCRIPTION

At the time of writing, latest version of CGI::Carp (1.27)
does not output error dying message with 500 (Internal Server Error)
HTTP status code unless it is working on mod_perl.

This module overrides some of CGI::Carp functions to return 500 status
code.  Users of this module should take attention whether later revision
of CGI::Carp provides improved version of CGI outputing methods.

This module is part of SuikaWiki.

=cut

package SuikaWiki::Output::CGICarp;
require CGI::Carp; # 1.27
use strict;
our $VERSION = do{my @r=(q$Revision: 1.1 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
our $CUSTOM_REASON_TEXT = 'Internal CGI Script Error';
our $CUSTOM_STATUS_CODE = 500;

=head1 OPTIONS

=over 4

=item $SuikaWiki::Output::CGICarp::CUSTOM_REASON_TEXT (Default : Internal CGI Script Error)

Short description of error status.  This string should contains only
printable ASCII characters (including SPACE) for interoperability
and line break characters (CR and LF) MUST NOT be used.

=item $SuikaWiki::Output::CGICarp::CUSTOM_STATUS_CODE (Default : 500)

Three digit status code defined by HTTP specifications.

=back

=cut

package CGI::Carp;
our $CUSTOM_MSG;
sub fatalsToBrowser {
  my($msg) = @_;
  $msg=~s/&/&amp;/g;
  $msg=~s/>/&gt;/g;
  $msg=~s/</&lt;/g;
  $msg=~s/\"/&quot;/g;
  my($wm) = $main::ENV{SERVER_ADMIN} ? 
    qq[the webmaster &lt;<a href="mailto:$main::ENV{SERVER_ADMIN}">$main::ENV{SERVER_ADMIN}</a>&gt;] :
      "this site's webmaster";
  my ($outer_message) = <<END;
For help, please send mail to $wm, giving this error message 
and the time and date of the error.
END
  ;
  my $mod_perl = exists $main::ENV{MOD_PERL};

  warningsToBrowser(1);    # emit warnings before dying

  if ($CUSTOM_MSG) {
    if (ref($CUSTOM_MSG) eq 'CODE') {
      my $bytes_written = eval{tell STDOUT};
      unless (defined $bytes_written && $bytes_written > 0) {
        print STDOUT "Status: @{[$SuikaWiki::Output::CGICarp::CUSTOM_STATUS_CODE+0]} $SuikaWiki::Output::CGICarp::CUSTOM_REASON_TEXT\n";
        print STDOUT "Content-type: text/html; charset=iso-8859-1\n\n";
      }
      &$CUSTOM_MSG($msg); # nicer to perl 5.003 users
      return;
    } else {
      $outer_message = $CUSTOM_MSG;
    }
  }

  my $mess = <<END;
<h1>Software error:</h1>
<pre>$msg</pre>
<p>
$outer_message
</p>
END
  ;

  if ($mod_perl) {
    require mod_perl;
    if ($mod_perl::VERSION >= 1.99) {
      $mod_perl = 2;
      require Apache::RequestRec;
      require Apache::RequestIO;
      require Apache::RequestUtil;
      require APR::Pool;
      require ModPerl::Util;
      require Apache::Response;
    }
    my $r = Apache->request;
    # If bytes have already been sent, then
    # we print the message out directly.
    # Otherwise we make a custom error
    # handler to produce the doc for us.
    if ($r->bytes_sent) {
      $r->print($mess);
      $mod_perl == 2 ? ModPerl::Util::exit(0) : $r->exit;
    } else {
      # MSIE won't display a custom 500 response unless it is >512 bytes!
      if ($main::ENV{HTTP_USER_AGENT} =~ /MSIE/) {
        $mess = "<!-- " . (' ' x 513) . " -->\n$mess";
      }
      $r->custom_response($SuikaWiki::Output::CGICarp::CUSTOM_STATUS_CODE+0,$mess);
    }
  } else {
    my $bytes_written = eval{tell STDOUT};
    if (defined $bytes_written && $bytes_written > 0) {
      print STDOUT $mess;
    } else {
      print STDOUT "Status: @{[$SuikaWiki::Output::CGICarp::CUSTOM_STATUS_CODE+0]} $SuikaWiki::Output::CGICarp::CUSTOM_REASON_TEXT\n";
      print STDOUT "Content-type: text/html; charset=iso-8859-1\n\n";
      print STDOUT $mess;
    }
  }
}

=head1 EXAMPLE

  use CGI::Carp qw/fatalsToBrowser/;
  require SuikaWiki::Output::CGICarp;
  
  die 'Something wrong';

=head1 LICENSE

Copyright 2003-2004 Wakaba <wakaba@suikawiki.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2007/09/23 07:57:00 $
