use strict;
use warnings;
use Path::Class;
BEGIN {
  require File::Basename;
  my $file_name = File::Basename::dirname (__FILE__) . '/../config/perl/libs.txt';
  if (-f $file_name) {
    open my $file, '<', $file_name or die "$0: $file_name: $!";
    unshift @INC, split /:/, <$file>;
  }
}
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->subdir ('modules', '*', 'lib')->stringify;

use AnyEvent;
use AnyEvent::HTTP;
use Encode;
use Time::HiRes qw(gettimeofday tv_interval);

my $url = shift;
my $cv = AnyEvent->condvar;

use Message::DOM::DOMImplementation;
my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

use Whatpm::HTML::Parser;
my $parser = Whatpm::HTML::Parser->new;

my $start_time = [gettimeofday];
my $prev_elapsed = 0;

sub msg ($;%) {
  my ($msg, %args) = @_;
  my $elapsed = tv_interval $start_time;
  $msg .= sprintf ' (%d ms, %0.2f us/B)',
      ($elapsed - $prev_elapsed) * 1000,
      ($elapsed - $prev_elapsed) * 1000 * 1000 / $args{length}
      if $args{show_diff};
  $prev_elapsed = $elapsed;
  warn sprintf "%d ms | %s\n", $elapsed * 1000, join ' ', $msg;
} # msg

my $timer;
my $inited;
sub init_parser () {
  return if $inited;

  msg "Received headers";
  $parser->parse_bytes_start (undef, $doc);
  
  $timer = AnyEvent->timer (after => 0.500, cb => sub {
    msg "500ms from headers";
    $parser->parse_bytes_feed ('', start_parsing => 1);
    undef $timer;
  });

  $inited = 1;
} # init_parser

http_get $url,
  on_header => sub {
    init_parser;
    return 1;
  },
  on_body   => sub {
    my ($data, $hdr) = @_;
    init_parser;

    msg "Received " . (length $data) . " bytes";
    $parser->parse_bytes_feed ($data);
    msg "Parsed", show_diff => 1, length => length $data;
    
    return 1;
  },
  sub {
    my (undef, $hdr) = @_;
    init_parser;
    
    msg "Loaded all";
    $parser->parse_bytes_end;
    msg "Parsed all";
    
    #warn $doc->inner_html;
    warn $doc->input_encoding;
    
    $cv->send;
  },
;

$cv->recv;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
