package test::Whatpm::HTML::Tokenizer::html_tokenizer;
use strict;
use warnings;
no warnings 'utf8';
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use base qw(Test::Class);
use Test::Differences;
use JSON 1.07;
$JSON::UnMapping = 1;
$JSON::UTF8 = 1;

my $DEBUG = $ENV{DEBUG};

my $test_dir_name = 't/';
my $dir_name = 't/tokenizer/';

use Data::Dumper;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Sortkeys = 1;
{
  no warnings 'redefine';
  sub Data::Dumper::qquote {
    my $s = shift;
    $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
    return q<qq'> . $s . q<'>;
  } # Data::Dumper::qquote
}

if ($DEBUG) {
  no warnings 'once';
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

sub _tests : Tests {
  my $self = shift;
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
    $self->_tokenize_test ($file_name);
  }                     
} # $file_name

sub _tokenize_test ($$) {
  my ($self, $file_name) = @_;
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

      $p->{line} = $p->{line_prev} = 0;
      $p->{column_prev} = -1;
      $p->{column} = 0;
      $p->{chars} = [split //, $s];
      $p->{chars_pos} = '';
      $p->{chars_pull_next} = sub { 0 };
      $p->{parse_error} = sub {
        my %args = @_;
        warn $args{type}, "\n" if $DEBUG;
        push @token, 'ParseError';
      };
      $p->{insertion_mode} = Whatpm::HTML::BEFORE_HEAD_IM (); # dummy
      
      $p->_initialize_tokenizer;
      $p->{state} = {
        CDATA => Whatpm::HTML::RAWTEXT_STATE (),
        RCDATA => Whatpm::HTML::RCDATA_STATE (),
        PCDATA => Whatpm::HTML::DATA_STATE (),
        SCRIPT => Whatpm::HTML::SCRIPT_DATA_STATE (),
        PLAINTEXT => Whatpm::HTML::PLAINTEXT_STATE (),
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
#line 1 "HTML-tokenizer.t ok"
      eq_or_diff $parser_dump, $expected_dump,
        $test->{description} . ': ' . Data::Dumper::qquote ($test->{input});
    }
  }
}

__PACKAGE__->runtests;

1;

## License: Public Domain.
