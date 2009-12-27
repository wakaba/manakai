package Whatpm::HTML::ScriptChecker;
use strict;
use warnings;
our $VERSION = '1.0';

use constant STATE_INITIAL => 0;
use constant STATE_COMMENT => 1;
use constant STATE_AFTER_LINE_COMMENT => 2;

my $level = {
    must => 'm',
};

sub check_inline_documentation ($$$) {
  my $class = shift;
  my $sref = ref $_[0] ? $_[0] : \( $_[0] );
  my $onerror = $_[1];

  pos $$sref = 0;
  my ($l, $c) = (1, 1);

  my $set_lc = sub {
    my $v = $_[0];
    ($l++, $c = 1) while $v =~ s/^[^\x0D\x0A]*(\x0A|\x0D\x0A?)//;
    $c += length $v;
  }; # $set_lc

  my $state = STATE_INITIAL;
  
  while (pos $$sref < length $$sref) {
    if ($state == STATE_INITIAL) {
      if ($$sref =~ /\G[\x20\x09]+/gc) {
        $c += $+[0] - $-[0];
      } elsif ($$sref =~ m[\G/\*]gc) {
        $state = STATE_COMMENT;
        $c += $+[0] - $-[0];
      } elsif ($$sref =~ m[\G//[^\x0A]*]gc) {
        $state = STATE_AFTER_LINE_COMMENT;
        $c += $+[0] - $-[0];
      } elsif ($$sref =~ /\G\x0A/gc) {
        $state = STATE_INITIAL;
        $l++;
        $c = 1;
      } else {
        $$sref =~ /\G(.)/sgc;
        $onerror->(type => 'script:doc:invalid char', ## XXX documentation
                   level => $level->{must},
                   line => $l, column => $c,
                   value => $1);
        return;
      }
    } elsif ($state == STATE_COMMENT) {
      if ($$sref =~ m[\G(?:[^\x0A]*?)\*/]gc) {
        $state = STATE_INITIAL;
        $c += $+[0] - $-[0];
      } elsif ($$sref =~ /\G[^\x0A]*\x0A/gc) {
        $l++;
        $c = 1;
      } else {
        $c += (length $$sref) - (pos $$sref);
        last;
      }
    } elsif ($state == STATE_AFTER_LINE_COMMENT) {
      if ($$sref =~ /\G\x0A/gc) {
        $state = STATE_INITIAL;
        $l++;
        $c = 1;
      } else {
        last;
      }
    } else {
      die "Unknown state: " . $state;
    }
  }
  
  if ($state == STATE_COMMENT) {
    $onerror->(type => 'script:doc:unclosed comment', ## XXX documentation
               level => $level->{must},
               line => $l, column => $c);
  } elsif ($state == STATE_AFTER_LINE_COMMENT) {
    $onerror->(type => 'script:doc:missing newline', ## XXX documentation
               level => $level->{must},
               line => $l, column => $c);
  }
} # check_inline_documentation

1;
