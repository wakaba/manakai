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
  s{!!!insert-element-t\s*\(([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2, $3);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+),\s*,([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1,, $2);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element-t\s*\(([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1);
      \$insert->(\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),\s*,([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1,, $2);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2, $3);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+),([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1, $2);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!insert-element\s*\(([^(),]+)\)\s*;}{qq{
    {
      my \$el;
      !!!create-element (\$el, $1);
      \$self->{open_elements}->[-1]->[0]->append_child (\$el);
      push \@{\$self->{open_elements}}, [\$el, \$el_category->{$1} || 0];
    }
  }}ge;
  s{!!!create-element\s*\(([^(),]+),([^(),]+)(?:,([^(),]*)(?>,([^(),]+))?)?\)\s*;}{
    my $l_var = $1;
    my $r = qq{
      $l_var = \$self->{document}->create_element_ns
        (q<http://www.w3.org/1999/xhtml>, [undef, $2]);
    };
    if (defined $3 and length $3) {
      $r .= qq{
        for my \$attr_name (keys %{$3}) {
          my \$attr_t = $3\->{\$attr_name};
          my \$attr = \$self->{document}->create_attribute_ns
              (undef, [undef, \$attr_name]);
          \$attr->value (\$attr_t->{value});
          \$attr->set_user_data (manakai_source_line => \$attr_t->{line});
          \$attr->set_user_data (manakai_source_column => \$attr_t->{column});
          $l_var->set_attribute_node_ns (\$attr);
        }
      };
    }
    if (defined $4) {
      my $token_var = $4;
      $token_var =~ s/^\s+//;
      $token_var =~ s/\s+$//;
      $r .= qq{
        $l_var->set_user_data (manakai_source_line => $token_var\->{line})
            if defined $token_var\->{line};
        $l_var->set_user_data (manakai_source_column => $token_var\->{column})
            if defined $token_var\->{column};
      };
      ## TODO: In future version, it should be allowed for an application
      ## developer to choose whether these information should be kept
      ## for tracking or not for performance by some means.
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
