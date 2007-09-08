#!/usr/bin/perl
use strict;

my $test_dir_name = 't/';
my $dir_name = 't/tokenizer/';

use JSON 1.07;
$JSON::UnMapping = 1;
$JSON::UTF8 = 1;

use Test;
BEGIN { plan tests => 347 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

use Whatpm::CSS::Tokenizer;

for my $file_name (grep {$_} split /\s+/, qq[
                      ${test_dir_name}css-token-1.test
                     ]) {
  open my $file, '<', $file_name
    or die "$0: $file_name: $!";
  local $/ = undef;
  my $js = <$file>;
  close $file;

  print "# $file_name\n";
  $js =~ s{\\u[Dd]([89A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
      \\u[Dd]([89A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])}{
    ## NOTE: JSON::Parser does not decode surrogate pair escapes
    ## NOTE: In older version of JSON::Parser, utf8 string will be broken
    ## by parsing.  Use latest version!
    ## NOTE: Encode.pm is broken; it converts e.g. U+10FFFF to U+FFFD.
    my $c = 0x10000;
    $c += ((((hex $1) & 0b1111111111) << 10) | ((hex $2) & 0b1111111111));
    chr $c;
  }gex;
  my $tests = jsonToObj ($js)->{tests};
  TEST: for my $test (@$tests) {
    my $s = $test->{input};

    my $p = Whatpm::CSS::Tokenizer->new;
    
    my $pos = 0;
    my $length = length $s;
    $p->{get_char} = sub {
      if ($pos < $length) {
        return ord substr $s, $pos++, 1;
      } else {
        return -1;
      }
    };
    $p->init;

    my @token;
    while (1) {
      my $token = $p->get_next_token;
      last if $token->{type} == Whatpm::CSS::Tokenizer::EOF_TOKEN ();

      my $test_token;
      $test_token->[0] = $Whatpm::CSS::Tokenizer::TokenName[$token->{type}] ||
          $token->{type};
      push @$test_token, $token->{number} if defined $token->{number};
      push @$test_token, $token->{value}
          if defined $token->{value} and
              (not $test_token->[0] eq 'NUMBER' or length $token->{value});
      push @token, $test_token;
    }
     
    my $expected_dump = Dumper ($test->{output});
    my $parser_dump = Dumper (\@token);
    ok $parser_dump, $expected_dump,
        $test->{description} . ': ' . Data::Dumper::qquote ($test->{input});
  }
}

## License: Public Domain.
## $Date: 2007/09/08 10:21:04 $
