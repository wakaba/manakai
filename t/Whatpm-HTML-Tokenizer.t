package test::Whatpm::HTML::Tokenizer;
use strict;
use warnings;
no warnings 'utf8';
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use Test::Manakai::Default;
use base qw(Test::Class);
use Test::MoreMore;
use Test::HTCT::Parser;
use Whatpm::HTML;
use Whatpm::HTML::Tokenizer qw(:token);

sub _abort : Test(10) {
  my $tokenizer = Whatpm::HTML->new;

  my $string = '';
  my $pos = 0;
  my $eof;

  $tokenizer->{line_prev} = 1;
  $tokenizer->{column_prev} = -1;
  $tokenizer->{token} = [];
  $tokenizer->{read_until} = sub { return 0 };
  $tokenizer->{set_nc} = sub {
    if ($pos < length $string) {
      $_[0]->{nc} = ord substr $string, $pos, 1;
      $pos++;
      $tokenizer->{column_prev}++;
    } else {
      if ($eof) {
        $_[0]->{nc} = -1; # EOF_CHAR
      } else {
        $_[0]->{nc} = -3; # ABORT_CHAR
      }
    }
  };
  $tokenizer->_initialize_tokenizer;

  my $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => ABORT_TOKEN};

  $string .= "<!DOC";
  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => ABORT_TOKEN};

  $string .= "TYPE html>";
  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => DOCTYPE_TOKEN, name => 'html',
                      line => 1, column => 1};

  $string .= "<";
  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => ABORT_TOKEN};

  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => ABORT_TOKEN};

  $string .= 'html';
  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => ABORT_TOKEN};

  $string .= '>';
  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => START_TAG_TOKEN, tag_name => 'html',
                      line => 1, column => 16, data => undef};

  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => ABORT_TOKEN};

  $eof = 1;
  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => END_OF_FILE_TOKEN,
                      line => undef, column => undef};

  $token = $tokenizer->_get_next_token;
  eq_or_diff $token, {type => END_OF_FILE_TOKEN,
                      line => undef, column => undef};
} # _abort

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
