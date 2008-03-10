#!/usr/bin/perl 
use strict;

my $DEBUG = $ENV{DEBUG};

while (<>) {
  s/!!!emit\b/return /;
  s{!!!next-input-character;}{q{
      if (@{$self->{char}}) {
        $self->{next_char} = shift @{$self->{char}};
      } else {
        $self->{set_next_char}->($self);
      }
  }}ge;
  s{!!!back-next-input-character\b}{q{unshift @{$self->{char}}, }}ge;
  s{!!!parse-error;}{q{$self->{parse_error}->();}}ge;
  s{!!!parse-error\s*\(}{
    q{$self->{parse_error}->(level => $self->{must_level}, }
  }ge;
  s{!!!insert-element-t\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, $1];
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, $1];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, $1];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, $1];
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
  s{!!!cp\s*\(\s*(\S+)\s*\)\s*;}{
    $DEBUG ? qq{
      #print STDERR "$1, ";
      \$Whatpm::HTML::Debug::cp_pass->($1) if \$Whatpm::HTML::Debug::cp_pass;
      BEGIN {
        \$Whatpm::HTML::Debug::cp->{$1} = 1;
      }
    } : ''
  }ge;
  print;
}
