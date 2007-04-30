#!/usr/bin/perl
use strict;

BEGIN {
  my $skip = "You don't have JSON module";
  eval q{
         use JSON 1.00;
         $skip = "You don't have make command";
         system ('make', 'tokenizer-files') == 0 or die
           unless -f 'tokenizer/test1.test';
         $skip = '';
        };
  if ($skip) {
    print "1..1\n";
    print "ok 1 # $skip\n";
    exit;
  }
  $JSON::UnMapping = 1;
}

use Test;
use Data::Dumper;
BEGIN { plan tests => 38 }

use What::HTML;

for my $file_name (qw[
                      tokenizer/test1.test
                      tokenizer/test2.test
                      tokenizer/contentModelFlags.test
                     ]) {
  open my $file, '<:utf8', $file_name or die "$0: $file_name: $!";
  local $/ = undef;
  my $js = <$file>;
  close $file;
  
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

    my @cm = @{$test->{content_model_flags} || ['PCDATA']};
    for my $cm (@cm) {
      my $p = What::HTML->new;
      my $i = 0;
      $p->{set_next_input_character} = sub {
        my $self = shift;
        $self->{next_input_character} = -1 and return if $i >= length $s;
        $self->{next_input_character} = ord substr $s, $i++, 1;
      };
      
      my @token;
      $p->{parse_error} = sub {
        push @token, 'ParseError';
      };
      
      $p->_initialize_tokenizer;
      $p->{content_model_flag} = $cm;

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
        $test_token->[1] = $token->{name} if defined $token->{name};
        $test_token->[1] = $token->{tag_name} if defined $token->{tag_name};
        $test_token->[1] = $token->{data} if defined $token->{data};
        $test_token->[2] = $token->{error} ? 1 : 0 if $token->{type} eq 'DOCTYPE';
        $test_token->[2] = {map {$_->{name} => $_->{value}} values %{$token->{attributes}}}
          if $token->{type} eq 'start tag';
        
        if (@token and ref $token[-1] and $token[-1]->[0] eq 'Character' and
            $test_token->[0] eq 'Character') {
          $token[-1]->[1] .= $test_token->[1];
        } else {
          push @token, $test_token;
        }
      }
      
      my $expected_dump = Dumper ($test->{output});
      my $parser_dump = Dumper (\@token);
      ok $parser_dump, $expected_dump, $test->{description};
    }
  }
}

