use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->parent->stringify;
use Message::DOM::DOMImplementation;

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;

local $/ = undef;
$doc->inner_html (scalar <>);

our $List = {};

my $rows = $doc->query_selector_all ('table tr:-manakai-contains("HTTP")');
for (@$rows) {
  my $cells = $_->query_selector_all ('td, th');
  next unless @$cells;
  my $method_name = ($cells->[0]->query_selector ('code') ||
                     $cells->[0]->query_selector ('anchor') ||
                     $cells->[0])->text_content;
  next if $method_name =~ /\*/;
  $List->{$method_name} = {};
}

## <http://dvcs.w3.org/hg/xhr/raw-file/tip/Overview.html#dom-xmlhttprequest-open>.
$List->{$_}->{case_insensitive} = 1
    for qw(CONNECT DELETE GET HEAD OPTIONS POST PUT TRACE TRACK);
$List->{$_}->{xhr_unsafe} = 1 for qw(CONNECT TRACE TRACK);

$List->{$_}->{safe} = 1 for qw(GET HEAD);
$List->{$_}->{idempotent} = 1 for qw(GET HEAD PUT DELETE TRACE OPTIONS);

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
my $text = Dumper $List;
$text =~ s/^\$VAR1/\$Whatpm::HTTP::Methods/;

my $now = [gmtime];
printf qq{\$Whatpm::HTTP::_Methods::VERSION = %04d%02d%02d;\n},
    $now->[5] + 1900, $now->[4] + 1, $now->[3];
print $text;

__END__

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
