#!/usr/bin/perl 
use strict;

while (<>) {
  s/!!!emit\b/return /;
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
  s{!!!insert-element-t\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2);
      \$insert->(\$el);
      push \@\$open_elements, [\$el, $1];
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1);
      \$insert->(\$el);
      push \@\$open_elements, [\$el, $1];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2);
      \$open_elements->[-1]->[0]->append_child (\$el);
      push \@\$open_elements, [\$el, $1];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1);
      \$open_elements->[-1]->[0]->append_child (\$el);
      push \@\$open_elements, [\$el, $1];
    }
  }}ge;
  s{!!!create-element\s*\(([^(),]+),([^(),]+)(?:,([^(),]+))?\)\s*;}{
    my $r = qq{
      $1 = \$self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef, $2]);
    };
    if (defined $3) {
      $r .= qq{
        for my \$attr_name (keys %{$3}) {
          $1->set_attribute_ns (undef, [undef, \$attr_name],
                                $3 ->{\$attr_name}->{value});
        }
      };
    }
    $r;
  }ge; # MUST
  s{!!!next-token;}{q{$token = $self->_get_next_token;}}ge;
  s{!!!back-token;}{q{unshift @{$self->{token}}, $token;}}ge;
  s{!!!back-token\s*\(}{q{unshift @{$self->{token}}, (}}ge;
  print;
}
