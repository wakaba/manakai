#!/usr/bin/perl
use strict;

my $dir_name;
my $test_dir_name;
BEGIN {
  $test_dir_name = 't/';
  $dir_name = 't/tokenizer/';
  my $skip = "You don't have JSON module";
  eval q{
         use JSON 1.07;
         $skip = "You don't have make command";
         system ("cd $test_dir_name; make tokenizer-files") == 0 or die
           unless -f $dir_name.'test1.test';
         $skip = '';
        };
  if ($skip) {
    print "1..1\n";
    print "ok 1 # $skip\n";
    exit;
  }
  $JSON::UnMapping = 1;
  $JSON::UTF8 = 1;
}

use Test;
BEGIN { plan tests => 182 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

use Whatpm::HTML;

for my $file_name (grep {$_} split /\s+/, qq[
                      ${dir_name}test1.test
                      ${dir_name}test2.test
                      ${dir_name}test3.test
                      ${dir_name}test4.test
                      ${dir_name}contentModelFlags.test
                      ${dir_name}escapeFlag.test
                      ${test_dir_name}tokenizer-test-1.test
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
    
    my $j = 1;
    while ($j < @{$test->{output}}) {
      if (ref $test->{output}->[$j - 1] and
          $test->{output}->[$j - 1]->[0] eq 'Character' and
          ref $test->{output}->[$j] and 
          $test->{output}->[$j]->[0] eq 'Character') {
        $test->{output}->[$j - 1]->[1]
          .= $test->{output}->[$j]->[1];
        splice @{$test->{output}}, $j, 1;
      }
      $j++;
    }

    my @cm = @{$test->{contentModelFlags} || ['PCDATA']};
    my $last_start_tag = $test->{lastStartTag};
    for my $cm (@cm) {
      my $p = Whatpm::HTML->new;
      my $i = 0;
      my @token;
      $p->{set_next_input_character} = sub {
        my $self = shift;

        pop @{$self->{prev_input_character}};
        unshift @{$self->{prev_input_character}}, $self->{next_input_character};

        $self->{next_input_character} = -1 and return if $i >= length $s;
        $self->{next_input_character} = ord substr $s, $i++, 1;

        if ($self->{next_input_character} == 0x000D) { # CR
          $i++ if substr ($s, $i, 1) eq "\x0A";
          $self->{next_input_character} = 0x000A; # LF # MUST
        } elsif ($self->{next_input_character} > 0x10FFFF) {
          $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
          push @token, 'ParseError';
        } elsif ($self->{next_input_character} == 0x0000) { # NULL
          $self->{next_input_character} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
          push @token, 'ParseError';
        }
      };
      $p->{prev_input_character} = [-1, -1, -1];
      $p->{next_input_character} = -1;
      
      $p->{parse_error} = sub {
        push @token, 'ParseError';
      };
      
      $p->_initialize_tokenizer;
      $p->{content_model_flag} = $cm;
      $p->{last_emitted_start_tag_name} = $last_start_tag;

      while (1) {
        my $token = $p->_get_next_token;
        last if $token->{type} eq 'end-of-file';
        
        my $test_token = [
         {
          DOCTYPE => 'DOCTYPE',
          'start tag' => 'StartTag',
          'end tag' => 'EndTag',
          comment => 'Comment',
          character => 'Character',
         }->{$token->{type}} || $token->{type},
        ];
        $test_token->[1] = $token->{tag_name} if defined $token->{tag_name};
        $test_token->[1] = $token->{data} if defined $token->{data};
        if ($token->{type} eq 'start tag') {
          $test_token->[2] = {map {$_->{name} => $_->{value}} values %{$token->{attributes}}};
        } elsif ($token->{type} eq 'DOCTYPE') {
          $test_token->[1] = $token->{name};
          $test_token->[2] = $token->{public_identifier};
          $test_token->[3] = $token->{system_identifier};
          $test_token->[4] = $token->{correct} ? 1 : 0;
        }

        if (@token and ref $token[-1] and $token[-1]->[0] eq 'Character' and
            $test_token->[0] eq 'Character') {
          $token[-1]->[1] .= $test_token->[1];
        } else {
          push @token, $test_token;
        }
      }
      
      my $expected_dump = Dumper ($test->{output});
      my $parser_dump = Dumper (\@token);
      ok $parser_dump, $expected_dump,
        $test->{description} . ': ' . $test->{input};
    }
  }
}

## $Date: 2007/07/16 07:03:09 $
