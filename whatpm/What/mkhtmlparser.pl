#!/usr/bin/perl 
use strict;

my $consume_entity_file_name = 'HTML-consume-entity.src';

while (<>) {
  s/!!!emit\b/return /;
  s{!!!consume-entity\}}{
    open my $consume_entity_file, '<', $consume_entity_file_name
      or die "$0: $consume_entity_file_name: $!";
    my $r = '';
    while (defined (my $l = <$consume_entity_file>)) {
      $r .= $l unless $l =~ /<javascript:/;
    }
    $r;
  }e;
  s{!!!next-input-character;}{q{
      if (@{$self->{char}}) {
        $self->{next_input_character} = shift @{$self->{char}};
      } else {
        $self->{set_next_input_character}->($self);
      }
  }}ge;
  s{!!!back-next-input-character\b}{q{unshift @{$self->{char}}, }}ge;
  s{!!!parse-error;}{q{$self->{parse_error}->();}}ge;
  s{!!!parse-error\b}{q{$self->{parse_error}->}}ge;
  print;
}
