package test::Message::CGI::HTTP;
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Message::CGI::HTTP;
use Test::More;

{
  package test::CGI;
  use base qw(Message::CGI::HTTP);
  
  sub get_meta_variable {
    return $_[0]->{env}->{$_[1]};
  } # get_meta_variable
}

sub _request_uri : Test(6) {
  for (
    [{
      HTTP_HOST => q<myhost>,
      REQUEST_URI => q</foo>,
    } => q<http://myhost/foo>],
    [{
      HTTP_HOST => q<myhost,yourhost>,
      REQUEST_URI => q</foo>,
    } => q<http://yourhost/foo>],
    [{
      HTTP_HOST => q<myhost, yourhost>,
      REQUEST_URI => q</foo>,
    } => q<http://yourhost/foo>],
    [{
      HTTP_HOST => q<myhost>,
      HTTP_X_FORWARDED_HOST => q<yourhost>,
      REQUEST_URI => q</foo>,
    } => q<http://yourhost/foo>],
    [{
      HTTP_HOST => q<myhost>,
      HTTP_X_FORWARDED_HOST => q<yourhost:123>,
      REQUEST_URI => q</foo>,
    } => q<http://yourhost:123/foo>],
    [{
      HTTP_HOST => q<myhost>,
      HTTP_X_FORWARDED_HOST => q<myhost, yourhost>,
      REQUEST_URI => q</foo>,
    } => q<http://yourhost/foo>],
  ) {
    my $cgi = test::CGI->new;
    $cgi->{env} = $_->[0];
    is $cgi->request_uri, $_->[1];
  }
} # _requrest_uri

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
