#!/usr/bin/perl
use strict;

my $DEBUG = $ENV{DEBUG};

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
BEGIN { plan tests => 1127 }

use Data::Dumper;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Sortkeys = 1;
sub Data::Dumper::qquote {
  my $s = shift;
  $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
  return q<qq'> . $s . q<'>;
} # Data::Dumper::qquote

if ($DEBUG) {
  my $not_found = {%{$Whatpm::HTML::Debug::cp or {}}};

  $Whatpm::HTML::Debug::cp_pass = sub {
    my $id = shift;
    delete $not_found->{$id};
  };

  END {
    for my $id (sort {$a <=> $b || $a cmp $b} grep {!/^[ti]/}
                keys %$not_found) {
      print "# checkpoint $id is not reached\n";
    }
  }
}

use Whatpm::HTML;

for my $file_name (grep {$_} split /\s+/, qq[
                      ${dir_name}test1.test
                      ${dir_name}test2.test
                      ${dir_name}test3.test
                      ${dir_name}test4.test
                      ${dir_name}contentModelFlags.test
                      ${dir_name}escapeFlag.test
                      ${dir_name}entities.test
                      ${dir_name}xmlViolation.test
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
  my $json = jsonToObj ($js);
  my $tests = $json->{tests} || $json->{xmlViolationTests};
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
      $p->{set_nc} = sub {
        my $self = shift;

#        pop @{$self->{prev_char}};
#        unshift @{$self->{prev_char}}, $self->{nc};

        $self->{nc} = -1 and return if $i >= length $s;
        $self->{nc} = ord substr $s, $i++, 1;

        if ($self->{nc} == 0x000D) { # CR
          $i++ if substr ($s, $i, 1) eq "\x0A";
          $self->{nc} = 0x000A; # LF # MUST
        } elsif ($self->{nc} > 0x10FFFF) {
          $self->{nc} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
          push @token, 'ParseError';
        } elsif ($self->{nc} == 0x0000) { # NULL
          $self->{nc} = 0xFFFD; # REPLACEMENT CHARACTER # MUST
          push @token, 'ParseError';
        } elsif ($self->{nc} <= 0x0008 or
                 (0x000E <= $self->{nc} and
                  $self->{nc} <= 0x001F) or
                 (0x007F <= $self->{nc} and
                  $self->{nc} <= 0x009F) or
                 (0xD800 <= $self->{nc} and
                  $self->{nc} <= 0xDFFF) or
                 (0xFDD0 <= $self->{nc} and
                  $self->{nc} <= 0xFDDF) or
                 {
                   0xFFFE => 1, 0xFFFF => 1, 0x1FFFE => 1, 0x1FFFF => 1,
                   0x2FFFE => 1, 0x2FFFF => 1, 0x3FFFE => 1, 0x3FFFF => 1,
                   0x4FFFE => 1, 0x4FFFF => 1, 0x5FFFE => 1, 0x5FFFF => 1,
                   0x6FFFE => 1, 0x6FFFF => 1, 0x7FFFE => 1, 0x7FFFF => 1,
                   0x8FFFE => 1, 0x8FFFF => 1, 0x9FFFE => 1, 0x9FFFF => 1,
                   0xAFFFE => 1, 0xAFFFF => 1, 0xBFFFE => 1, 0xBFFFF => 1,
                   0xCFFFE => 1, 0xCFFFF => 1, 0xDFFFE => 1, 0xDFFFF => 1,
                   0xEFFFE => 1, 0xEFFFF => 1, 0xFFFFE => 1, 0xFFFFF => 1,
                   0x10FFFE => 1, 0x10FFFF => 1,
                  }->{$self->{nc}}) {
          push @token, 'ParseError';
        }
      };



      $p->{read_until} = sub { return 0 };
      
      $p->{parse_error} = sub {
        push @token, 'ParseError';
      };
      
      $p->_initialize_tokenizer;
      $p->{content_model} = {
        CDATA => Whatpm::HTML::CDATA_CONTENT_MODEL (),
        RCDATA => Whatpm::HTML::RCDATA_CONTENT_MODEL (),
        PCDATA => Whatpm::HTML::PCDATA_CONTENT_MODEL (),
        PLAINTEXT => Whatpm::HTML::PLAINTEXT_CONTENT_MODEL (),
      }->{$cm};
      $p->{last_stag_name} = $last_start_tag;

      while (1) {
        my $token = $p->_get_next_token;
        last if $token->{type} == Whatpm::HTML::END_OF_FILE_TOKEN ();
        
        my $test_token = [
         {
          Whatpm::HTML::DOCTYPE_TOKEN () => 'DOCTYPE',
          Whatpm::HTML::START_TAG_TOKEN () => 'StartTag',
          Whatpm::HTML::END_TAG_TOKEN () => 'EndTag',
          Whatpm::HTML::COMMENT_TOKEN () => 'Comment',
          Whatpm::HTML::CHARACTER_TOKEN () => 'Character',
         }->{$token->{type}} || $token->{type},
        ];
        $test_token->[1] = $token->{tag_name} if defined $token->{tag_name};
        $test_token->[1] = $token->{data} if defined $token->{data};
        if ($token->{type} == Whatpm::HTML::START_TAG_TOKEN ()) {
          $test_token->[2] = {map {$_->{name} => $_->{value}} values %{$token->{attributes}}};
          $test_token->[3] = 1 if $p->{self_closing};
          delete $p->{self_closing};
        } elsif ($token->{type} == Whatpm::HTML::DOCTYPE_TOKEN ()) {
          $test_token->[1] = $token->{name};
          $test_token->[2] = $token->{pubid};
          $test_token->[3] = $token->{sysid};
          $test_token->[4] = $token->{quirks} ? 0 : 1;
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
        $test->{description} . ': ' . Data::Dumper::qquote ($test->{input});
    }
  }
}

## License: Public Domain.
## $Date: 2008/09/22 06:04:29 $
