use strict;
require Test::Simple;

require Message::Util::HostPermit;
sub ok ($;$);
sub new_checker () {
  new Message::Util::HostPermit;
}

my @test = (
            sub {
              my $checker = new_checker;
              ok $checker->match_host ('foo', 'foo');
              ok $checker->match_host ('bar', 'bar');
              ok !$checker->match_host ('foo', 'bar');
              ok $checker->match_host ('*', 'foo');
              ok $checker->match_host ('*.test', 'foo.test');
              ok !$checker->match_host ('*.test', 'foo.example');
              ok $checker->match_host ('*.test', 'www.foo.test');
              ok $checker->match_host ('*.foo.test', 'www.foo.test');
              ok !$checker->match_host ('foo.bar.foo.test', 'test');
              ok !$checker->match_host ('foo.bar.foo.test', 'foo.test');
              ok !$checker->match_host ('test', 'foo.bar.foo.test');
              ok !$checker->match_host ('*.foo.test', 'foo.test');
              ok $checker->match_host ('*.foo.test', 'foo.bar.foo.test');
              
              ok !$checker->match_host ('*', ''), 'invalid host';
              ok $checker->match_host ('*', 'foo..bar'), 'invalid host';
              ok $checker->match_host ('*.', 'foo'), 'invalid pattern';
              ok !$checker->match_host ('', 'foo'), 'invalid pattern';
              
              ok !$checker->match_host ('bar.*.test', 'foo.test'), 'unsupported pattern';
              ok $checker->match_host ('bar.*.test', 'foo.foo.test'), 'unsupported pattern';
              ok !$checker->match_host ('bar.*.test', 'foo.example'), 'unsupported pattern';
            },2..20,
            sub {
              my $checker = new_checker;
              ok $checker->match_ipv4 ('1.1.1.1', '1.1.1.1');
              ok $checker->match_ipv4 ('1.1.1.1', v1.1.1.1);
              ok $checker->match_ipv4 (v1.1.1.1, v1.1.1.1);
              
              ok $checker->match_ipv4 ('1.1.1.1/3', '1.1.1.1');
              ok !$checker->match_ipv4 ('1.1.1.1/3', '1.1.1.45');
              ok $checker->match_ipv4 ('1.1.1.1/3', '1.1.1.0');
              ok $checker->match_ipv4 ('1.1.1.1/3', '1.1.1.7');
              ok !$checker->match_ipv4 ('1.1.1.1/3', '1.1.1.8');
              ok !$checker->match_ipv4 ('1.1.1.1/3', '1.1.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/3', '1.43.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/3', '41.153.32.0');
              ok $checker->match_ipv4 ('1.1.1.1/8', '1.1.1.1');
              ok $checker->match_ipv4 ('1.1.1.1/8', '1.1.1.45');
              ok $checker->match_ipv4 ('1.1.1.1/8', '1.1.1.0');
              ok !$checker->match_ipv4 ('1.1.1.1/8', '1.1.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/8', '1.43.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/8', '41.153.32.0');
              ok $checker->match_ipv4 ('1.1.1.1/13', '1.1.1.1');
              ok $checker->match_ipv4 ('1.1.1.1/13', '1.1.1.45');
              ok $checker->match_ipv4 ('1.1.1.1/13', '1.1.1.0');
              ok $checker->match_ipv4 ('1.1.1.1/13', '1.1.13.0');
              ok $checker->match_ipv4 ('1.1.1.1/13', '1.1.21.0');
              ok $checker->match_ipv4 ('1.1.1.1/13', '1.1.31.0');
              ok !$checker->match_ipv4 ('1.1.1.1/13', '1.1.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/13', '1.43.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/13', '41.153.32.0'); 
              ok $checker->match_ipv4 ('1.1.1.1/16', '1.1.1.1');
              ok $checker->match_ipv4 ('1.1.1.1/16', '1.1.1.45');
              ok $checker->match_ipv4 ('1.1.1.1/16', '1.1.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/16', '1.43.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/16', '41.153.32.0');
              ok $checker->match_ipv4 ('1.1.1.1/24', '1.1.1.1');
              ok $checker->match_ipv4 ('1.1.1.1/24', '1.1.1.45');
              ok $checker->match_ipv4 ('1.1.1.1/24', '1.1.32.0');
              ok $checker->match_ipv4 ('1.1.1.1/24', '1.153.32.0');
              ok !$checker->match_ipv4 ('1.1.1.1/24', '41.153.32.0');
              ok $checker->match_ipv4 ('1.1.1.1/32', '1.1.1.1');
              ok $checker->match_ipv4 ('1.1.1.1/32', '1.1.1.0');
              ok $checker->match_ipv4 ('1.1.1.1/32', '123.43.56.23');
              
              ok !$checker->match_ipv4 (v1.1.1.1, v1.1.1455.1), 'invalid addr';
              ok !$checker->match_ipv4 (v1.1.1.1, '1.1.1455.1'), 'invalid addr';
              ok $checker->match_ipv4 (v1.1.1455.1, v1.1.1.1), 'invalid pattern';
              ok $checker->match_ipv4 ('1.1.1455.1', v1.1.1.1), 'invalid pattern';
              ok !$checker->match_ipv4 ('123', '44.44.3.2'), 'invalid pattern';
              ok !$checker->match_ipv4 ('*.12.3.1', '5.4.3.2'), 'invalid pattern';
              ok !$checker->match_ipv4 ('12.3/32', '5.4.3.2'), 'invalid pattern';
              ok $checker->match_ipv4 (v1.1.1.1, '12.3.3'), 'invalid addr';
              ok $checker->match_ipv4 (v1.1.1.1, '1.1.1.1/31'), 'invalid addr';
              ok $checker->match_ipv4 ('1.1.1.1/39', '1.1.1.0'), 'invalid pattern';
              
            },2..49,
            sub {
              my $checker = new_checker;
              ok !$checker->match_ipv6 ('something', 'something'), 'IPv6 : not implemented yet';
            },
            sub {
              my $checker = new_checker;
              $checker->add_rule ("Allow host=example.com
Deny host=example.org
Allow host=example.net
Allow ipv4=12.34.5.6
Deny host=*
Deny ipv4=0.0.0.0/32
Deny ipv6=0::0/128");
              ok $checker->check ('example.com');
              ok !$checker->check ('example.org');
              ok $checker->check ('example.net');
              ok !$checker->check ('example.edu');
              ok !$checker->check ('not.exist.invalid');
              ok !$checker->check ('localhost');
              ok !$checker->check (undef);
              ok !$checker->check ('in]va"li)d');
              ok $checker->check ('12.34.5.6');
              ok !$checker->check ('127.43.3.4');
              ok !$checker->check ('0::2');
              
              ok $checker->check ('example.com', 80);
              ok !$checker->check ('example.org', 80);
            },2,3,4,5,6,7,8,9,10,11,12,
           );

Test::Simple->import (tests => scalar @test);

for (@test) {
  &{$_} if ref $_;
}


=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/09/17 02:34:18 $


