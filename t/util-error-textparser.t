use strict;
use Message::Util::Error;

my $src = q{Some Parsed Text};

my $err = new Message::Util::Error::TextParser
            package => 'test_error';

report $err -type => 'ERROR_1', source => \$src;

$src =~ /Some/gc;

report $err -type => 'ERROR_1', source => \$src;

$src =~ /Any/gc;

report $err -type => 'ERROR_1', source => \$src;

$src =~ /Text/gc;

report $err -type => 'ERROR_1', source => \$src;

BEGIN {
package test_error;
require Message::Util::Error::TextParser;
push our @ISA, 'Message::Util::Error::TextParser::error';

use Test;
my @result = qw/1-1 1-5 1-5 1-17/;
my $i = 0;
plan tests => scalar @result;

sub ___report_error ($$) {
  Test::ok ($_[1]->text, $result[$i++]);
  warn $_[1]->stringify if $^W;
}

sub ___error_def () {+{
  ERROR_1 => {
    description => q(%err-line;-%err-char;),
  },
}}
}

=head1 LICENSE

Copyright 2003 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1; # $Date: 2003/12/26 07:09:42 $
