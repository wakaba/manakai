package Test::Manakai::Exceptions;
use strict;
use warnings;
use Exporter::Lite;
use Test::More;

our @EXPORT = qw(dom_exception_ok);

sub dom_exception_ok (&$;$) {
  my ($code, $exception_type, $name) = @_;

  my $actual;
  local $@;
  eval {
    $code->();
    $actual = '(no exception)';
  } or do {
    if ($@ and
        ref $@ and
        UNIVERSAL::isa ($@, 'Message::DOM::DOMException')) {
      my $type = ucfirst lc $@->{-type};
      $type =~ s/_(.)/uc $1/ge;
      $type =~ s/Err$/Error/;
      $actual = $type;
    } else {
      $actual = $@;
    }
  };
  is $actual, $exception_type, $name || $exception_type;
} # dom_exception_ok

1;
